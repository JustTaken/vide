const std = @import("std");

const TrueType = @import("truetype.zig").TrueType;
const Window = @import("window/core.zig").Core;
const Wayland = @import("wayland.zig").Wayland;
const Instance = @import("vulkan/instance.zig").Instance;
const Device = @import("vulkan/device.zig").Device;
const GraphicsPipeline = @import("vulkan/graphics_pipeline.zig").GraphicsPipeline;
const Swapchain = @import("vulkan/swapchain.zig").Swapchain;
const CommandPool = @import("vulkan/command_pool.zig").CommandPool;
const Painter = @import("vulkan/painter.zig").Painter;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}) {};
    const allocator = gpa.allocator();

    const font = try TrueType.init(35, "assets/font/font.ttf", allocator);
    const window = try Window(Wayland).init(1920, 1080, font.scale, font.ratio, allocator);
    const instance = try Instance.init(Wayland, &window.handle);
    const device = try Device.init(&instance);
    const graphics_pipeline = try GraphicsPipeline.init(&instance, &device);
    var swapchain = try Swapchain.init(&device, instance.surface, graphics_pipeline.format, graphics_pipeline.render_pass, window.size, allocator);
    const command_pool = try CommandPool.init(&device, &swapchain, allocator);
    var painter = try Painter.init(&swapchain, &graphics_pipeline, &command_pool, &font, window.size, allocator);

    window.set_painter(&painter);
    try window.add_listener(painter.resize_listener());
    try window.add_listener(swapchain.resize_listener());

    while (window.state != .Closing) {
        window.handle.get_events();
        try window.update();

        std.time.sleep(1000000 * 30);
        try swapchain.wait();
    }

    font.deinit();
    painter.deinit();
    command_pool.deinit(&device);
    swapchain.deinit(&device);
    graphics_pipeline.deinit(&device);
    device.deinit();
    instance.deinit();
    window.deinit();
}
