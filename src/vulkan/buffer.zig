const c = @import("../bind.zig").c;
const check = @import("result.zig").check;
const util = @import("../util.zig");

const Device = @import("device.zig").Device;
const Descriptor = @import("graphics_pipeline.zig").Descritor;
const CommandPool = @import("command_pool.zig").CommandPool;

const Buffer = struct {
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

        try check(device.vkCreateBuffer(device.handle, &info, null, &buffer.handle));

        var requirements: c.VkMemoryRequirements = undefined;
        try check(device.vkGetBufferMemoryRequirements(device.handle, buffer.handle, &requirements));

        buffer.memory = device.allocate_memory(properties, &requirements);
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
        const buffer = init(T, device, usage, properties, len);

        var dst: []T = undefined;

        const staging_buffer = init(T, device, c.VK_BUFFER_USAGE_TRANSFER_SRC_BIT, c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, len);
        try check(device.vkMapMemory(device.handle, staging_buffer.memory, 0, len * @sizeOf(T), 0, @ptrCast(&dst)));

        util.copy(T, data, &dst);

        const copy_info = c.VkBufferCopy {
            .srcOffset = 0,
            .dstOffset = 0,
            .size = @sizeOf(T) * len,
        };

        const command_buffer = command_pool.allocate_buffer(device);

        device.vkCmdCopyBuffer(command_buffer, staging_buffer.handle, buffer.handle, 1, &copy_info);
        device.vkUnmapMemory(device.handle, staging_buffer.memory);

        command_buffer.end(device);
        staging_buffer.deinit(device);

        return buffer;
    }

    fn deinit(self: *const Buffer, device: *const Device) void {
        device.dispatch.vkDestroyBuffer(device.handle, self.handle, null);
        device.dispatch.vkFreeMemory(device.handle, self.memory, null);
    }
};

pub fn Vec(T: type) type {
    return struct {
        handle: Buffer,
        elements: []T,
        capacity: u32,

        usage: u32,
        properties: u32,

        const Self = @This();

        pub fn init(
            usage: u32,
            properties: u32,
            capacity: u32, 
            device: *const Device
        ) !Self {
            var vec: Self = undefined;

            vec.handle = Buffer.init(
                T,
                capacity,
                usage,
                properties,
                device,
            );

            try check(device.dispatch.vkMapMemory(device.handle, vec.handle.memory, 0, capacity * @sizeOf(T), 0, @ptrCast(&vec.elements)));

            vec.capacity = capacity;
            vec.elements.len = 0;

            vec.usage = usage;
            vec.properties = properties;

            return vec;
        }

        fn deinit(self: *const Self, device: *const Device) void {
            self.handle.deinit(device);
        }
    };
}

const Uniform = struct {
    buffer: Buffer,
    set: c.VkDescriptorSet,
    dst: []f32,

    fn init(
        T: type,
        data: []const T,
        binding: u32,
        descriptor: Descriptor,
        device: *const Device,
    ) !Uniform {
        var uniform: Uniform = undefined;

        const len: u32 = @intCast(data.len);

        uniform.buffer = Buffer.init(T, device, c.VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT, c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, len);

        try check(device.vkMapMemory(device.handle, uniform.buffer.memory, 0, len * @sizeOf(T), 0, @ptrCast(&uniform.dst)));

        util.copy(T, data, &uniform.dst);

        uniform.set = descriptor.get_set(device);
        uniform.set.update(null, .{ .buffer = uniform.buffer, .T = T, .len = len }, binding, device);

        return uniform;
    }
};

