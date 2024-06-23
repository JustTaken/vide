const std = @import("std");
const wayland = @import("wayland/core.zig");
const vulkan = @import("vulkan/core.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}) {};
    const allocator = gpa.allocator();

    const window = try wayland.init(1920, 1080);

    const instance = try vulkan.instance_init(window.display, window.surface);
    const device = try vulkan.device_init(&instance);
    const graphics_pipeline = try vulkan.graphics_pipeline_init(&instance, &device);
    const swapchain = try vulkan.swapchain_init(&instance, &device, &graphics_pipeline, allocator);
    const command_pool = try vulkan.command_pool_init(&device, &swapchain, allocator);
    const painter = vulkan.painter_init(&device, &graphics_pipeline, &command_pool);

    vulkan.draw_frame(&device, &swapchain, &command_pool, &graphics_pipeline, &painter);
    vulkan.sync(&device, &swapchain);

    vulkan.deinit_painter(&device, &painter);
    vulkan.deinit_command_pool(&device, &command_pool);
    vulkan.deinit_swapchain(&device, &swapchain);
    vulkan.deinit_graphics_pipeline(&device, &graphics_pipeline);
    vulkan.deinit_device(&device);
    vulkan.deinit_instance(&instance);

    wayland.deinit(&window);
}
