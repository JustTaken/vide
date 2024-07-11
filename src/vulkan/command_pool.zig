const std = @import("std");
const c = @import("../bind.zig").c;
const check = @import("result.zig").check;

const Allocator = std.mem.Allocator;
const Device = @import("device.zig").Device;
const Swapchain = @import("swapchain.zig").Swapchain;

pub const CommandPool = struct {
    handle: c.VkCommandPool,
    buffers: []c.VkCommandBuffer,
    allocator: Allocator,

    pub fn init(
        device: *const Device,
        swapchain: *const Swapchain,
        allocator: Allocator,
    ) !CommandPool {
        var command_pool: CommandPool = undefined;
        const count = swapchain.framebuffers.len;

        {
            const info = c.VkCommandPoolCreateInfo {
                .sType = c.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
                .flags = c.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
                .queueFamilyIndex = device.physical_device.families[0],
            };

            try check(device.dispatch.vkCreateCommandPool(device.handle, &info, null, &command_pool.handle));
        }

        {
            command_pool.buffers = try allocator.alloc(c.VkCommandBuffer, count);
            command_pool.allocator = allocator;
        }

        {
            const buffers_info = c.VkCommandBufferAllocateInfo {
                .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
                .commandPool = command_pool.handle,
                .level = c.VK_COMMAND_BUFFER_LEVEL_PRIMARY,
                .commandBufferCount = @intCast(count),
            };

            try check(device.dispatch.vkAllocateCommandBuffers(device.handle, &buffers_info, &command_pool.buffers[0]));
        }

        return command_pool;
    }

    pub fn allocate_buffer(self: *CommandPool, device: *const Device) !Buffer {
        return Buffer.begin(device, self);
    }

    pub fn deinit(self: *const CommandPool, device: *const Device) void {
        const count: u32 = @intCast(self.buffers.len);

        device.dispatch.vkFreeCommandBuffers(device.handle, self.handle, count, &self.buffers[0]);
        device.dispatch.vkDestroyCommandPool(device.handle, self.handle, null);

        self.allocator.free(self.buffers);
    }
};

const Buffer = struct {
    handle: c.VkCommandBuffer,
    pool: *const CommandPool,

    fn end(self: *Buffer, device: *const Device) !void {
        device.dispatch.vkEndCommandBuffer(self.handle);

        const submit_info = c.VkSubmitInfo {
            .sType = c.VK_STRUCTURE_TYPE_SUBMIT_INFO,
            .commandBufferCount = 1,
            .pCommandBuffers = &self.handle,
        };

        try check(device.dispatch.vkQueueSubmit(device.queues[0], 1, &submit_info, null));
        try check(device.dispatch.vkQueueWaitIdle(device.queues[0]));
        device.disaptch.vkFreeCommandBuffers(device.handle, self.pool, 1, &self.handle);
    }

    fn begin(device: *const Device, pool: *const CommandPool) !Buffer {
        var command_buffer: Buffer = undefined;

        const alloc_info = c.VkCommandBufferAllocateInfo {
            .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
            .commandPool = pool.handle,
            .level = c.VK_COMMAND_BUFFER_LEVEL_PRIMARY,
            .commandBufferCount = 1,
        };

        try check(device.dispatch.vkAllocateCommandBuffers(device.handle, &alloc_info, &command_buffer));
        const begin_info = c.VkCommandBufferBeginInfo {
            .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
            .flags = c.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
        };

        try check(device.dispatch.vkBeginCommandBuffer(command_buffer.handle, &begin_info));
        command_buffer.pool = pool;

        return command_buffer;
    }
};
