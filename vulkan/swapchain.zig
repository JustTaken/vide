const c = @import("bind.zig").c;
const std = @import("std");
const util = @import("util");

const check = @import("result.zig").check;
const Result = @import("result.zig").Result;

const Allocator = std.mem.Allocator;

const Instance = @import("instance.zig").Instance;
const Device = @import("device.zig").Device;
const GraphicsPipeline = @import("graphics_pipeline.zig").GraphicsPipeline;
const Image = @import("image.zig").Texture;

const Listener = util.Listener;
const Size = util.math.Vec2D;

pub const Swapchain = struct {
    device: *const Device,
    handle: c.VkSwapchainKHR,
    surface: c.VkSurfaceKHR,
    render_pass: c.VkRenderPass,
    images: []c.VkImage,
    image_views: []c.VkImageView,
    framebuffers: []c.VkFramebuffer,

    render_finished: c.VkSemaphore,
    image_available: c.VkSemaphore,
    in_flight: c.VkFence,

    size: Size,
    format: c.VkSurfaceFormatKHR,
    image_count: u32,
    valid: bool,

    allocator: Allocator,

    pub fn init(
        device: *const Device,
        surface: c.VkSurfaceKHR,
        format: c.VkSurfaceFormatKHR,
        render_pass: c.VkRenderPass,
        size: Size,
        allocator: Allocator,
    ) !Swapchain {
        var swapchain: Swapchain = undefined;
        swapchain.handle = null;

        const semaphore_info = c.VkSemaphoreCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
        };

        const fence_info = c.VkFenceCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
            .flags = c.VK_FENCE_CREATE_SIGNALED_BIT,
        };

        try check(device.dispatch.vkCreateSemaphore(
            device.handle,
            &semaphore_info,
            null,
            &swapchain.render_finished,
        ));

        try check(device.dispatch.vkCreateFence(
            device.handle,
            &fence_info,
            null,
            &swapchain.in_flight,
        ));

        swapchain.device = device;
        const capabilities = device.physical_device.capabilities;
        swapchain.image_count = if (capabilities.maxImageCount > 0)
            @min(capabilities.minImageCount + 1, capabilities.maxImageCount)
        else
            capabilities.minImageCount + 1;

        swapchain.render_pass = render_pass;
        swapchain.surface = surface;
        swapchain.size = size;
        swapchain.format = format;

        swapchain.images = try allocator.alloc(
            c.VkImage,
            swapchain.image_count,
        );

        swapchain.image_views = try allocator.alloc(
            c.VkImageView,
            swapchain.image_count,
        );

        swapchain.framebuffers = try allocator.alloc(
            c.VkFramebuffer,
            swapchain.image_count,
        );

        swapchain.allocator = allocator;

        try swapchain.recreate();

        return swapchain;
    }

    fn recreate(self: *Swapchain) !void {
        const device = self.device;
        const present_mode = c.VK_PRESENT_MODE_FIFO_KHR;
        const extent = c.VkExtent2D{
            .width = self.size.x,
            .height = self.size.y,
        };

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

        const info = c.VkSwapchainCreateInfoKHR{
            .sType = c.VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
            .surface = self.surface,
            .minImageCount = self.image_count,
            .imageFormat = self.format.format,
            .imageColorSpace = self.format.colorSpace,
            .imageExtent = extent,
            .presentMode = present_mode,
            .clipped = c.VK_TRUE,
            .imageArrayLayers = 1,
            .compositeAlpha = c.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
            .imageUsage = c.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
            .queueFamilyIndexCount = family_count,
            .pQueueFamilyIndices = &unique_families[0],
            .oldSwapchain = old_swapchain,

            .preTransform = device.physical_device.capabilities.currentTransform,

            .imageSharingMode = if (family_count > 1)
                c.VK_SHARING_MODE_CONCURRENT
            else
                c.VK_SHARING_MODE_EXCLUSIVE,
        };

        try check(device.dispatch.vkCreateSwapchainKHR(
            device.handle,
            &info,
            null,
            &self.handle,
        ));

        try check(device.dispatch.vkGetSwapchainImagesKHR(
            device.handle,
            self.handle,
            &self.image_count,
            self.images.ptr,
        ));

        if (old_swapchain) |_| {
            for (0..self.image_count) |i| {
                device.dispatch.vkDestroyImageView(
                    device.handle,
                    self.image_views[i],
                    null,
                );
                device.dispatch.vkDestroyFramebuffer(
                    device.handle,
                    self.framebuffers[i],
                    null,
                );
            }

            device.dispatch.vkDestroySemaphore(
                device.handle,
                self.image_available,
                null,
            );
            device.dispatch.vkDestroySwapchainKHR(
                device.handle,
                old_swapchain,
                null,
            );
        }

        for (0..self.image_count) |i| {
            self.image_views[i] = try Image.view_init(
                self.images[i],
                self.format.format,
                device,
            );

            const framebuffer_info = c.VkFramebufferCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO,
                .renderPass = self.render_pass,
                .attachmentCount = 1,
                .pAttachments = &self.image_views[i],
                .width = self.size.x,
                .height = self.size.y,
                .layers = 1,
            };

            try check(device.dispatch.vkCreateFramebuffer(
                device.handle,
                &framebuffer_info,
                null,
                &self.framebuffers[i],
            ));
        }

        const semaphore_info = c.VkSemaphoreCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
        };

        try check(device.dispatch.vkCreateSemaphore(
            device.handle,
            &semaphore_info,
            null,
            &self.image_available,
        ));

        self.valid = true;
    }

    pub fn wait(self: *const Swapchain) !void {
        try check(self.device.dispatch.vkWaitForFences(
            self.device.handle,
            1,
            &self.in_flight,
            c.VK_TRUE,
            0xFFFFFF,
        ));

        try check(self.device.dispatch.vkQueueWaitIdle(
            self.device.queues[0],
        ));
    }

    pub fn image_index(self: *Swapchain) !u32 {
        var index: u32 = 0;
        var result = self.device.dispatch.vkAcquireNextImageKHR(
            self.device.handle,
            self.handle,
            0xFFFFFF,
            self.image_available,
            null,
            &index,
        );

        while (result ==
            c.VK_ERROR_OUT_OF_DATE_KHR or result ==
            c.VK_SUBOPTIMAL_KHR or !self.valid)
        {
            try self.recreate();

            result = self.device.dispatch.vkAcquireNextImageKHR(
                self.device.handle,
                self.handle,
                0xFFFFFF,
                self.image_available,
                null,
                &index,
            );
        }

        try check(result);
        return index;
    }

    fn resize(ptr: *anyopaque, data: *const anyopaque) void {
        const self: *Swapchain = @ptrCast(@alignCast(ptr));

        self.size.move(@ptrCast(@alignCast(data)));
        self.valid = false;
    }

    pub fn resize_listener(self: *Swapchain) Listener {
        return Listener{
            .f = resize,
            .ptr = self,
        };
    }

    pub fn deinit(self: *const Swapchain) void {
        const device = self.device;
        const count = self.framebuffers.len;

        for (0..count) |i| {
            device.dispatch.vkDestroyImageView(
                device.handle,
                self.image_views[i],
                null,
            );

            device.dispatch.vkDestroyFramebuffer(
                device.handle,
                self.framebuffers[i],
                null,
            );
        }

        self.allocator.free(self.framebuffers);
        self.allocator.free(self.image_views);

        device.dispatch.vkDestroySemaphore(
            device.handle,
            self.render_finished,
            null,
        );

        device.dispatch.vkDestroySemaphore(
            device.handle,
            self.image_available,
            null,
        );

        device.dispatch.vkDestroyFence(device.handle, self.in_flight, null);
        device.dispatch.vkDestroySwapchainKHR(
            device.handle,
            self.handle,
            null,
        );
    }
};
