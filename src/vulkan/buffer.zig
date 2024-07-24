const std = @import("std");
const c = @import("../bind.zig").c;
const check = @import("result.zig").check;
const util = @import("../util.zig");

const Device = @import("device.zig").Device;
const Descriptor = @import("graphics_pipeline.zig").Descriptor;
const DescriptorSet = @import("graphics_pipeline.zig").DescriptorSet;
const CommandPool = @import("command_pool.zig").CommandPool;

pub const Buffer = struct {
    handle: c.VkBuffer,
    memory: c.VkDeviceMemory,

    pub fn init(
        T: type,
        len: u32,
        usage: u32,
        properties: u32,
        device: *const Device,
    ) !Buffer {
        var buffer: Buffer = undefined;

        const info = c.VkBufferCreateInfo {
            .sType = c.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
            .size = @sizeOf(T) * len,
            .usage = usage,
            .sharingMode = c.VK_SHARING_MODE_EXCLUSIVE,
        };

        try check(device.dispatch.vkCreateBuffer(device.handle, &info, null, &buffer.handle));

        var requirements: c.VkMemoryRequirements = undefined;
        device.dispatch.vkGetBufferMemoryRequirements(device.handle, buffer.handle, &requirements);

        buffer.memory = try device.allocate_memory(properties, &requirements);
        try check(device.dispatch.vkBindBufferMemory(device.handle, buffer.handle, buffer.memory, 0));

        return buffer;
    }

    pub fn with_data(
        T: type,
        data: []const T,
        usage: u32,
        properties: u32,
        device: *const Device,
        command_pool: *const CommandPool,
    ) !Buffer {
        const len: u32 = @intCast(data.len);
        const buffer = try init(T, len, usage, properties, device);

        var dst: []T = undefined;

        const staging_buffer = try init(T, len, c.VK_BUFFER_USAGE_TRANSFER_SRC_BIT, c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, device);
        try check(device.dispatch.vkMapMemory(device.handle, staging_buffer.memory, 0, len * @sizeOf(T), 0, @ptrCast(&dst)));

        util.copy(T, data, dst);

        const copy_info = c.VkBufferCopy {
            .srcOffset = 0,
            .dstOffset = 0,
            .size = @sizeOf(T) * len,
        };

        const command_buffer = try command_pool.allocate_buffer(device);

        device.dispatch.vkCmdCopyBuffer(command_buffer.handle, staging_buffer.handle, buffer.handle, 1, &copy_info);
        device.dispatch.vkUnmapMemory(device.handle, staging_buffer.memory);

        try command_buffer.end(device);
        staging_buffer.deinit(device);

        return buffer;
    }

    pub fn deinit(self: *const Buffer, device: *const Device) void {
        device.dispatch.vkDestroyBuffer(device.handle, self.handle, null);
        device.dispatch.vkFreeMemory(device.handle, self.memory, null);
    }
};

pub fn Vec(T: type) type {
    return struct {
        buffer: Buffer,

        elements: []T,
        capacity: u32,

        usage: u32,
        properties: u32,

        device: *const Device,
        command_pool: *const CommandPool,

        const Self = @This();

        pub fn init(
            usage: u32,
            properties: u32,
            capacity: u32, 
            device: *const Device,
            command_pool: *const CommandPool,
        ) !Self {
            var vec: Self = undefined;

            vec.buffer = try Buffer.init(
                T,
                capacity,
                usage,
                properties,
                device,
            );

            try check(device.dispatch.vkMapMemory(device.handle, vec.buffer.memory, 0, capacity * @sizeOf(T), 0, @ptrCast(&vec.elements)));

            vec.capacity = capacity;
            vec.elements.len = 0;

            vec.usage = usage;
            vec.properties = properties;
            vec.device = device;
            vec.command_pool = command_pool;

            return vec;
        }

        pub fn push(self: *Self, item: T) !void {
            const count = self.len();

            if (self.capacity <= count) {
                const new_len = count * 2;
                const buffer = try Buffer.init(
                    T,
                    new_len,
                    self.usage,
                    self.properties,
                    self.device,
                );

                var new: []T = undefined;
                try check(self.device.dispatch.vkMapMemory(self.device.handle, buffer.memory, 0, new_len * @sizeOf(T), 0, @ptrCast(&new)));

                util.copy(T, self.elements, new);

                self.deinit();

                self.buffer = buffer;
                self.elements.ptr = new.ptr;
                self.capacity = new_len;
            }

            self.elements.len += 1;
            self.elements[count] = item;
        }

        pub fn reset(self: *Self) void {
            self.elements.len = 0;
        }

        pub fn len(self: *const Self) u32 {
            return @intCast(self.elements.len);
        }

        pub fn deinit(self: *const Self) void {
            self.buffer.deinit(self.device);
        }
    };
}

pub const Uniform = struct {
    handle: Buffer,
    set: DescriptorSet,
    dst: []f32,

    pub fn init(
        T: type,
        data: []const T,
        binding: u32,
        descriptor: Descriptor,
        device: *const Device,
    ) !Uniform {
        var uniform: Uniform = undefined;

        const len: u32 = @intCast(data.len);

        uniform.handle = try Buffer.init(
            T, 
            len,
            c.VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT, 
            c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, 
            device, 
        );

        try check(device.dispatch.vkMapMemory(device.handle, uniform.handle.memory, 0, len * @sizeOf(T), 0, @ptrCast(&uniform.dst)));

        util.copy(T, data, uniform.dst);

        uniform.set = try descriptor.get_set(device);
        uniform.set.update_buffer(T, uniform.handle.handle, binding, len, device);

        return uniform;
    }

    pub fn deinit(self: *const Uniform, device: *const Device) void {
        self.handle.deinit(device);
    }
    
};

