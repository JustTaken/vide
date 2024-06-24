const std = @import("std");
const wayland = @import("wayland/core.zig");
const vulkan = @import("vulkan/core.zig");
const true_type = @import("font/core.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}) {};
    const allocator = gpa.allocator();

    const window = try wayland.init(1920, 1080, allocator);
    const font = try true_type.init(30, allocator);

    const instance = try vulkan.instance_init(window);
    const device = try vulkan.device_init(&instance);
    const graphics_pipeline = try vulkan.graphics_pipeline_init(&instance, &device);
    var swapchain = try vulkan.swapchain_init(&instance, &device, &graphics_pipeline, window, allocator);
    const command_pool = try vulkan.command_pool_init(&device, &swapchain, allocator);
    var painter = vulkan.painter_init(&device, &graphics_pipeline, &command_pool, window, &font);

    while (window.running) {
        vulkan.draw_frame(
            &swapchain,
            &instance,
            &device,
            &command_pool,
            &graphics_pipeline,
            window,
            &painter
        );
        wayland.update(window);
        vulkan.sync(&device, &swapchain);
    }

    vulkan.painter_deinit(&device, &painter);
    vulkan.command_pool_deinit(&device, &command_pool);
    vulkan.swapchain_deinit(&device, &swapchain);
    vulkan.graphics_pipeline_deinit(&device, &graphics_pipeline);
    vulkan.device_deinit(&device);
    vulkan.instance_deinit(&instance);

    true_type.deinit(&font);
    wayland.deinit(window);
}
