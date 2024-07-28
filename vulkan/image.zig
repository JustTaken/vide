const c = @import("bind.zig").c;
const check = @import("result.zig").check;
const util = @import("util");

const Device = @import("device.zig").Device;
const GraphicsPipeline = @import("graphics_pipeline.zig").GraphicsPipeline;
const DescriptorSet = @import("graphics_pipeline.zig").DescriptorSet;
const CommandPool = @import("command_pool.zig").CommandPool;
const Buffer = @import("buffer.zig").Buffer;

const Size = util.math.Vec2D;

pub const Texture = struct {
    image: c.VkImage,
    memory: c.VkDeviceMemory,
    view: c.VkImageView,
    sampler: c.VkSampler,
    set: DescriptorSet,
    size: Size,

    pub fn init(
        data: []const u8,
        format: u32,
        size: Size,
        device: *const Device,
        command_pool: *const CommandPool,
        graphics_pipeline: *const GraphicsPipeline,
    ) !Texture {
        var texture: Texture = undefined;

        const info = c.VkImageCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
            .imageType = c.VK_IMAGE_TYPE_2D,
            .mipLevels = 1,
            .arrayLayers = 1,
            .tiling = c.VK_IMAGE_TILING_OPTIMAL,
            .initialLayout = c.VK_IMAGE_LAYOUT_UNDEFINED,
            .sharingMode = c.VK_SHARING_MODE_EXCLUSIVE,
            .samples = c.VK_SAMPLE_COUNT_1_BIT,
            .usage = c.VK_IMAGE_USAGE_TRANSFER_DST_BIT |
                c.VK_IMAGE_USAGE_SAMPLED_BIT,
            .format = format,
            .extent = c.VkExtent3D{
                .width = size.x,
                .height = size.y,
                .depth = 1,
            },
        };

        try check(device.dispatch.vkCreateImage(
            device.handle,
            &info,
            null,
            &texture.image,
        ));

        var memory_requirements: c.VkMemoryRequirements = undefined;
        device.dispatch.vkGetImageMemoryRequirements(
            device.handle,
            texture.image,
            &memory_requirements,
        );

        texture.memory = try device.allocate_memory(
            c.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
            &memory_requirements,
        );
        try check(device.dispatch.vkBindImageMemory(
            device.handle,
            texture.image,
            texture.memory,
            0,
        ));
        texture.view = try view_init(texture.image, format, device);

        try copy_data_to_image(
            texture.image,
            data,
            size,
            device,
            command_pool,
        );

        texture.sampler = try sampler_init(
            c.VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER,
            device,
        );
        texture.set = try graphics_pipeline.descriptors[1].get_set(device);
        texture.set.update_image(texture.view, texture.sampler, 0, device);
        texture.size = size;

        return texture;
    }

    fn sampler_init(mode: u32, device: *const Device) !c.VkSampler {
        const info = c.VkSamplerCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO,
            .magFilter = c.VK_FILTER_LINEAR,
            .minFilter = c.VK_FILTER_LINEAR,
            .addressModeU = mode,
            .addressModeV = mode,
            .addressModeW = mode,
            .anisotropyEnable = c.VK_FALSE,
            .maxAnisotropy = 1.0,
            .borderColor = c.VK_BORDER_COLOR_INT_OPAQUE_BLACK,
            .unnormalizedCoordinates = c.VK_FALSE,
            .compareEnable = c.VK_FALSE,
            .compareOp = c.VK_COMPARE_OP_ALWAYS,
            .mipmapMode = c.VK_SAMPLER_MIPMAP_MODE_LINEAR,
            .mipLodBias = 0.0,
            .minLod = 0.0,
            .maxLod = 0.0,
        };

        var handle: c.VkSampler = undefined;
        try check(device.dispatch.vkCreateSampler(
            device.handle,
            &info,
            null,
            &handle,
        ));

        return handle;
    }

    pub fn view_init(
        image: c.VkImage,
        format: u32,
        device: *const Device,
    ) !c.VkImageView {
        const sub = c.VkImageSubresourceRange{
            .aspectMask = c.VK_IMAGE_ASPECT_COLOR_BIT,
            .baseMipLevel = 0,
            .levelCount = 1,
            .baseArrayLayer = 0,
            .layerCount = 1,
        };

        const comp = c.VkComponentMapping{
            .r = c.VK_COMPONENT_SWIZZLE_IDENTITY,
            .g = c.VK_COMPONENT_SWIZZLE_IDENTITY,
            .b = c.VK_COMPONENT_SWIZZLE_IDENTITY,
            .a = c.VK_COMPONENT_SWIZZLE_IDENTITY,
        };

        const info = c.VkImageViewCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
            .viewType = c.VK_IMAGE_VIEW_TYPE_2D,
            .subresourceRange = sub,
            .components = comp,

            .image = image,
            .format = format,
        };

        var image_view: c.VkImageView = undefined;
        try check(device.dispatch.vkCreateImageView(
            device.handle,
            &info,
            null,
            &image_view,
        ));

        return image_view;
    }

    pub fn copy_data_to_image(
        image: c.VkImage,
        data: []const u8,
        size: Size,
        device: *const Device,
        command_pool: *const CommandPool,
    ) !void {
        var dst: []u8 = undefined;
        const len: u32 = @intCast(data.len);

        const buffer = try Buffer.init(
            u8,
            len,
            c.VK_BUFFER_USAGE_TRANSFER_SRC_BIT,
            c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT |
                c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
            device,
        );
        try check(device.dispatch.vkMapMemory(
            device.handle,
            buffer.memory,
            0,
            len * @sizeOf(u8),
            0,
            @ptrCast(&dst),
        ));

        util.copy(u8, data, dst);

        const sub = c.VkImageSubresourceRange{
            .aspectMask = c.VK_IMAGE_ASPECT_COLOR_BIT,
            .baseMipLevel = 0,
            .levelCount = 1,
            .layerCount = 1,
            .baseArrayLayer = 0,
        };

        const barrier = c.VkImageMemoryBarrier{
            .sType = c.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
            .oldLayout = c.VK_IMAGE_LAYOUT_UNDEFINED,
            .newLayout = c.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
            .srcQueueFamilyIndex = c.VK_QUEUE_FAMILY_IGNORED,
            .dstQueueFamilyIndex = c.VK_QUEUE_FAMILY_IGNORED,
            .image = image,
            .subresourceRange = sub,
            .srcAccessMask = 0,
            .dstAccessMask = c.VK_ACCESS_TRANSFER_WRITE_BIT,
        };

        const image_sub = c.VkImageSubresourceLayers{
            .aspectMask = c.VK_IMAGE_ASPECT_COLOR_BIT,
            .mipLevel = 0,
            .baseArrayLayer = 0,
            .layerCount = 1,
        };

        const offset = c.VkOffset3D{
            .x = 0,
            .y = 0,
            .z = 0,
        };

        const extent = c.VkExtent3D{
            .width = size.x,
            .height = size.y,
            .depth = 1,
        };

        const region = c.VkBufferImageCopy{
            .bufferOffset = 0,
            .bufferRowLength = 0,
            .bufferImageHeight = 0,
            .imageSubresource = image_sub,
            .imageOffset = offset,
            .imageExtent = extent,
        };

        const second_barrier = c.VkImageMemoryBarrier{
            .sType = c.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
            .oldLayout = c.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
            .newLayout = c.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
            .srcQueueFamilyIndex = c.VK_QUEUE_FAMILY_IGNORED,
            .dstQueueFamilyIndex = c.VK_QUEUE_FAMILY_IGNORED,
            .image = image,
            .subresourceRange = sub,
            .srcAccessMask = c.VK_ACCESS_TRANSFER_WRITE_BIT,
            .dstAccessMask = c.VK_ACCESS_SHADER_READ_BIT,
        };

        const command_buffer = try command_pool.allocate_buffer(device);

        device.dispatch.vkCmdPipelineBarrier(
            command_buffer.handle,
            c.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT,
            c.VK_PIPELINE_STAGE_TRANSFER_BIT,
            0,
            0,
            null,
            0,
            null,
            1,
            &barrier,
        );

        device.dispatch.vkCmdCopyBufferToImage(
            command_buffer.handle,
            buffer.handle,
            image,
            c.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
            1,
            &region,
        );

        device.dispatch.vkCmdPipelineBarrier(
            command_buffer.handle,
            c.VK_PIPELINE_STAGE_TRANSFER_BIT,
            c.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
            0,
            0,
            null,
            0,
            null,
            1,
            &second_barrier,
        );

        try command_buffer.end(device);
        device.dispatch.vkUnmapMemory(device.handle, buffer.memory);
        buffer.deinit(device);
    }

    pub fn deinit(self: *const Texture, device: *const Device) void {
        device.dispatch.vkDestroySampler(device.handle, self.sampler, null);
        device.dispatch.vkFreeMemory(device.handle, self.memory, null);
        device.dispatch.vkDestroyImage(device.handle, self.image, null);
        device.dispatch.vkDestroyImageView(device.handle, self.view, null);
    }
};
