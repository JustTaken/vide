const c = @import("../bind.zig").c;
const std = @import("std");

const check = @import("result.zig").check;

const Allocator = std.mem.Allocator;

const Instance = @import("instance.zig").Instance;
const Device = @import("device.zig").Device;
const GraphicsPipeline = @import("graphics_pipeline.zig").GraphicsPipeline;
const Image = @import("image.zig").Texture;

const Size = @import("../math.zig").Vec2D;

pub const Swapchain = struct {
    handle: c.VkSwapchainKHR,
    images: []c.VkImage,
    image_views: []c.VkImageView,
    framebuffers: []c.VkFramebuffer,

    render_finished: c.VkSemaphore,
    image_available: c.VkSemaphore,
    in_flight: c.VkFence,

    capabilities: c.VkSurfaceCapabilitiesKHR,
    extent: c.VkExtent2D,
    image_count: u32,

    allocator: Allocator,

    pub fn init(
        instance: *const Instance,
        device: *const Device,
        graphics_pipeline: *const GraphicsPipeline,
        size: Size,
        allocator: Allocator,
    ) !Swapchain {
        var swapchain: Swapchain = undefined;
        swapchain.handle = null;

        const semaphore_info = c.VkSemaphoreCreateInfo {
            .sType = c.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
        };

        const fence_info = c.VkFenceCreateInfo {
            .sType = c.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
            .flags = c.VK_FENCE_CREATE_SIGNALED_BIT,
        };

        try check(device.dispatch.vkCreateSemaphore(device.handle, &semaphore_info, null, &swapchain.render_finished));
        try check(device.dispatch.vkCreateFence(device.handle, &fence_info, null, &swapchain.in_flight));
        try check(instance.dispatch.vkGetPhysicalDeviceSurfaceCapabilitiesKHR(device.physical_device.handle, instance.surface, &swapchain.capabilities));

        swapchain.image_count = if (swapchain.capabilities.maxImageCount > 0) @min(swapchain.capabilities.minImageCount + 1, swapchain.capabilities.maxImageCount)
        else swapchain.capabilities.minImageCount + 1;

        swapchain.images = try allocator.alloc(c.VkImage, swapchain.image_count);
        swapchain.image_views = try allocator.alloc(c.VkImageView, swapchain.image_count);
        swapchain.framebuffers = try allocator.alloc(c.VkFramebuffer, swapchain.image_count);
        swapchain.allocator = allocator;

        try swapchain.recreate(
            instance,
            device,
            graphics_pipeline,
            size,
        );

        return swapchain;
    }

    fn recreate(
        self: *Swapchain,
        instance: *const Instance,
        device: *const Device,
        graphics_pipeline: *const GraphicsPipeline,
        size: Size,
    ) !void {
        self.extent = c.VkExtent2D {
            .width = size.x,
            .height = size.y,
        };

        const present_mode = c.VK_PRESENT_MODE_FIFO_KHR;

        var unique_families: [4]u32 = undefined;
        var family_count: u32 = 0;
        {
            var last_value: u32 = 255;
            for (device.physical_device.families) |family| {
                if (family != last_value) {
                    unique_families[family_count] = family;
                    last_value = family;
                    family_count += 1;
                }
            }
        }

        const old_swapchain = self.handle;

        const info = c.VkSwapchainCreateInfoKHR {
            .sType = c.VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
            .surface = instance.surface,
            .minImageCount = self.image_count,
            .imageFormat = graphics_pipeline.format.format,
            .imageColorSpace = graphics_pipeline.format.colorSpace,
            .imageExtent = self.extent,
            .imageSharingMode = if (family_count > 1) c.VK_SHARING_MODE_CONCURRENT else c.VK_SHARING_MODE_EXCLUSIVE,
            .presentMode = present_mode,
            .preTransform = self.capabilities.currentTransform,
            .clipped = c.VK_TRUE,
            .imageArrayLayers = 1,
            .compositeAlpha = c.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
            .imageUsage = c.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
            .queueFamilyIndexCount = family_count,
            .pQueueFamilyIndices = &unique_families[0],
            .oldSwapchain = old_swapchain,
        };

        try check(device.dispatch.vkCreateSwapchainKHR(device.handle, &info, null, &self.handle));
        try check(device.dispatch.vkGetSwapchainImagesKHR(device.handle, self.handle, &self.image_count, self.images.ptr));

        if (old_swapchain) |_| {
            for (0..self.image_count) |i| {
                device.dispatch.vkDestroyImageView(device.handle, self.image_views[i], null);
                device.dispatch.vkDestroyFramebuffer(device.handle, self.framebuffers[i], null);
            }

            device.dispatch.vkDestroySemaphore(device.handle, self.image_available, null);
            device.dispatch.vkDestroySwapchainKHR(device.handle, old_swapchain, null);
        }

        for (0..self.image_count) |i| {
            self.image_views[i] = try Image.view_init(self.images[i], graphics_pipeline.format.format, device);

            const framebuffer_info = c.VkFramebufferCreateInfo {
                .sType = c.VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO,
                .renderPass = graphics_pipeline.render_pass,
                .attachmentCount = 1,
                .pAttachments = &self.image_views[i],
                .width = self.extent.width,
                .height = self.extent.height,
                .layers = 1,
            };

            try check(device.dispatch.vkCreateFramebuffer(device.handle, &framebuffer_info, null, &self.framebuffers[i]));
        }

        const semaphore_info = c.VkSemaphoreCreateInfo {
            .sType = c.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
        };

        try check(device.dispatch.vkCreateSemaphore(device.handle, &semaphore_info, null, &self.image_available));
    }

    pub fn deinit(self: *const Swapchain, device: *const Device) void {
        const count = self.framebuffers.len;

        for (0..count) |i| {
            device.dispatch.vkDestroyImageView(device.handle, self.image_views[i], null);
            device.dispatch.vkDestroyFramebuffer(device.handle, self.framebuffers[i], null);
        }

        self.allocator.free(self.framebuffers);
        self.allocator.free(self.image_views);

        device.dispatch.vkDestroySemaphore(device.handle, self.render_finished, null);
        device.dispatch.vkDestroySemaphore(device.handle, self.image_available, null);
        device.dispatch.vkDestroyFence(device.handle, self.in_flight, null);
        device.dispatch.vkDestroySwapchainKHR(device.handle, self.handle, null);
    }
};

