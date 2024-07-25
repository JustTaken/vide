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

const testing: []const []const u8 = &.{
    "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
    "Ret",
    "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "1", " ", "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e",
    "C-b", "C-b", "C-b", "C-b", "C-b", "C-b", "C-b", "C-b", "C-b", "C-b", "Ret",
    "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "Ret",
    "3", " ", "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "Ret",
    "C-p", "C-p",
    "4", " ", "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "Ret",
    "5", " ", "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "Ret",
    "C-b", "C-b", "C-n",
    "6", " ", "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "Ret",
    "7", " ", "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "Ret",
    "8", " ", "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "Ret",
    "9", " ", "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "Ret",
    "1", "0", " ", "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "Ret",
    "1", "1", " ", "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "Ret",
    "1", "2", " ", "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "Ret",
    "C-Spc", "C-p", "C-p", "C-e", "C-b", "C-d",
    "1", "3", " ", "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "Ret",
    "1", "4", " ", "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "Ret",
    "1", "5", " ", "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "Ret",
    "1", "6", " ", "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "Ret",
    "1", "7", " ", "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "Ret",
    "1", "8", " ", "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "Ret",
    "1", "9", " ", "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "Ret",
    "2", "0", " ", "T", "h", "i", "s", " ", "i", "s", " ", "C-a", "C-f", "C-f", "C-f", "C-f", "C-f", "C-Spc", "C-p", "C-p", "C-d", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "Ret",
    "C-p", "C-a", "Ret",
    "2", "1", " ", "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "Ret",
    "2", "2", " ", "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "Ret",
    "2", "2", " ", "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "Ret",
    "2", "4", " ", "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "Ret",
    "2", "5", " ", "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "Ret",
    "2", "6", " ", "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "Ret",
    "2", "7", " ", "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "Ret",
    "2", "7", " ", "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "Ret",
    "2", "7", " ", "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "Ret",
    "2", "7", " ", "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "Ret",
    "2", "7", " ", "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "Ret",
    "2", "7", " ", "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "Ret",
    "2", "7", " ", "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "Ret",
    "2", "7", " ", "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "Ret",
    "2", "7", " ", "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "Ret",
    "2", "8", " ", "T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "t", "e", "s", "t", " ", "m", "e", "s", "s", "a", "g", "e", "Ret",
    "C-Spc", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-d",
};

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

    for (testing) |c| {
        try window.key_input(c);
        window.handle.get_events();
        try window.update();

        std.time.sleep(1000000 * 30);
        try swapchain.wait();
    }
    // while (window.state != .Closing) {
    //     window.handle.get_events();
    //     try window.update();

    //     std.time.sleep(1000000 * 100);
    //     try swapchain.wait();
    // }

    font.deinit();
    painter.deinit();
    command_pool.deinit(&device);
    swapchain.deinit(&device);
    graphics_pipeline.deinit(&device);
    device.deinit();
    instance.deinit();
    window.deinit();
}
