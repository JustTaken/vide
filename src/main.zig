const std = @import("std");
const wayland = @import("wayland/core.zig");
// const vulkan = @import("vulkan/core.zig");
const TrueType = @import("font/core.zig").TrueType;
const Window = @import("window/core.zig").Core;
const Wayland = @import("wayland/core.zig").Wayland;
const Instance = @import("vulkan/instance.zig").Instance;
const Device = @import("vulkan/device.zig").Device;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}) {};
    const allocator = gpa.allocator();

    const font = try TrueType.init(30, "assets/font/font.ttf", allocator);
    const window = try Window(Wayland).init(1920, 1080, allocator);
    const instance = try Instance.init(Wayland, &window.handle);
    const device = try Device.init(&instance);

    font.deinit();
    device.deinit();
    instance.deinit();
    window.deinit();

    // const window = try wayland.init(1920, 1080, font.scale, font.x_ratio, allocator);

    // const graphics_pipeline = try vulkan.graphics_pipeline_init(&instance, &device);
    // var swapchain = try vulkan.swapchain_init(&instance, &device, &graphics_pipeline, window, allocator);
    // const command_pool = try vulkan.command_pool_init(&device, &swapchain, allocator);
    // var painter = try vulkan.painter_init(&device, &graphics_pipeline, &command_pool, window, &font, allocator);

    // while (window.running) {
    //   vulkan.sync(&device, &swapchain);

    //   if (window.update) {
    //     vulkan.draw_frame(
    //       &swapchain,
    //       &instance,
    //       &device,
    //       &command_pool,
    //       &graphics_pipeline,
    //       window,
    //       &painter
    //     );

    //     wayland.update_surface(window);
    //   }

    //   wayland.get_events(window);
    // }

    // vulkan.painter_deinit(&device, &painter);
    // vulkan.command_pool_deinit(&device, &command_pool);
    // vulkan.swapchain_deinit(&device, &swapchain);
    // vulkan.graphics_pipeline_deinit(&device, &graphics_pipeline);
    // vulkan.device_deinit(&device);
    // vulkan.instance_deinit(&instance);

    // true_type.deinit(&font);
    // wayland.deinit(window);
}
