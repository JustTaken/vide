const std = @import("std");
const c = @import("../bind.zig").c;
const truetype = @import("../font/core.zig");
const wayland = @import("../wayland/core.zig");
const math = @import("../math.zig");

const Window = wayland.Wayland;
const Font = truetype.TrueType;

var ARENA = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const ALLOCATOR = ARENA.allocator();






















fn texture_descriptor_deinit(device: *const DeviceDispatch, texture_descriptor: *const TextureDescriptor) void {
    device.vkDestroySampler(device.handle, texture_descriptor.sampler, null);
}



pub fn device_deinit(device: *const DeviceDispatch) void {
    device.vkDestroyDevice(device.handle, null);
}
