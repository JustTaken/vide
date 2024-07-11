const std = @import("std");

const TrueType = @import("truetype.zig").TrueType;
const Window = @import("window/core.zig").Core;
const Wayland = @import("wayland/core.zig").Wayland;
const Instance = @import("vulkan/instance.zig").Instance;
const Device = @import("vulkan/device.zig").Device;
const GraphicsPipeline = @import("vulkan/graphics_pipeline.zig").GraphicsPipeline;
const Swapchain = @import("vulkan/swapchain.zig").Swapchain;
const CommandPool = @import("vulkan/command_pool.zig").CommandPool;
const Painter = @import("vulkan/painter.zig").Painter;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}) {};
    const allocator = gpa.allocator();

    const font = try TrueType.init(25, "assets/font/font.ttf", allocator);
    const window = try Window(Wayland).init(1920, 1080, allocator);
    const instance = try Instance.init(Wayland, &window.handle);
    const device = try Device.init(&instance);
    const graphics_pipeline = try GraphicsPipeline.init(&instance, &device);
    const swapchain = try Swapchain.init(&instance, &device, &graphics_pipeline, window.size, allocator);
    const command_pool = try CommandPool.init(&device, &swapchain, allocator);
    const painter = try Painter.init(&device, &graphics_pipeline, &command_pool, &font, window.scale, allocator);

    font.deinit();
    painter.deinit(&device);
    command_pool.deinit(&device);
    swapchain.deinit(&device);
    graphics_pipeline.deinit(&device);
    device.deinit();
    instance.deinit();
    window.deinit();

    // const window = try wayland.init(1920, 1080, font.scale, font.x_ratio, allocator);


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
