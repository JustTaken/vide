const std = @import("std");

const TrueType = @import("truetype.zig").TrueType;
const Window = @import("window/core.zig").Core;
const Wayland = @import("wayland.zig").Wayland;
const Instance = @import("vulkan").instance.Instance;
const Device = @import("vulkan").device.Device;
const GraphicsPipeline = @import("vulkan").graphics_pipeline.GraphicsPipeline;
const Swapchain = @import("vulkan").swapchain.Swapchain;
const CommandPool = @import("vulkan").command_pool.CommandPool;
const Painter = @import("painter.zig").Painter;

const testing: []const []const u8 = &.{
    "a",   "b",   "c",   "d",   "e",   "f",   "g",   "h",   "i",   "j",   "k",   "l",   "m",   "n",   "o",   "p",   "q",   "r",   "s",   "t",   "u",   "v",   "w",   "x",   "y",     "z",   "A",   "B",     "C",     "D",   "E",   "F",   "G",   "H", "I", "J", "K",   "L", "M", "N", "O", "P", "Q",   "R",   "S",   "T",   "U",     "V",     "W",   "X",   "Y",   "Z",
    "Ret", "T",   "h",   "i",   "s",   " ",   "i",   "s",   " ",   "a",   " ",   "t",   "e",   "s",   "t",   " ",   "m",   "e",   "s",   "s",   "a",   "g",   "e",   "1",   " ",     "T",   "h",   "i",     "s",     " ",   "i",   "s",   " ",   "a", " ", "t", "e",   "s", "t", " ", "m", "e", "s",   "s",   "a",   "g",   "e",     "C-b",   "C-b", "C-b", "C-b", "C-b",
    "C-b", "C-b", "C-b", "C-b", "C-b", "Ret", "T",   "h",   "i",   "s",   " ",   "i",   "s",   " ",   "a",   " ",   "t",   "e",   "s",   "t",   " ",   "m",   "e",   "s",   "s",     "a",   "g",   "e",     "Ret",   "3",   " ",   "T",   "h",   "i", "s", " ", "i",   "s", " ", "a", " ", "t", "e",   "s",   "t",   " ",   "m",     "e",     "s",   "s",   "a",   "g",
    "e",   "Ret", "C-p", "C-p", "4",   " ",   "T",   "h",   "i",   "s",   " ",   "i",   "s",   " ",   "a",   " ",   "t",   "e",   "s",   "t",   " ",   "m",   "e",   "s",   "s",     "a",   "g",   "e",     "Ret",   "5",   " ",   "T",   "h",   "i", "s", " ", "i",   "s", " ", "a", " ", "t", "e",   "s",   "t",   " ",   "m",     "e",     "s",   "s",   "a",   "g",
    "e",   "Ret", "C-b", "C-b", "C-n", "6",   " ",   "T",   "h",   "i",   "s",   " ",   "i",   "s",   " ",   "a",   " ",   "t",   "e",   "s",   "t",   " ",   "m",   "e",   "s",     "s",   "a",   "g",     "e",     "Ret", "7",   " ",   "T",   "h", "i", "s", " ",   "i", "s", " ", "a", " ", "t",   "e",   "s",   "t",   " ",     "m",     "e",   "s",   "s",   "a",
    "g",   "e",   "Ret", "8",   " ",   "T",   "h",   "i",   "s",   " ",   "i",   "s",   " ",   "a",   " ",   "t",   "e",   "s",   "t",   " ",   "m",   "e",   "s",   "s",   "a",     "g",   "e",   "Ret",   "9",     " ",   "T",   "h",   "i",   "s", " ", "i", "s",   " ", "a", " ", "t", "e", "s",   "t",   " ",   "m",   "e",     "s",     "s",   "a",   "g",   "e",
    "Ret", "1",   "0",   " ",   "T",   "h",   "i",   "s",   " ",   "i",   "s",   " ",   "a",   " ",   "t",   "e",   "s",   "t",   " ",   "m",   "e",   "s",   "s",   "a",   "g",     "e",   "Ret", "1",     "1",     " ",   "T",   "h",   "i",   "s", " ", "i", "s",   " ", "a", " ", "t", "e", "s",   "t",   " ",   "m",   "e",     "s",     "s",   "a",   "g",   "e",
    "Ret", "1",   "2",   " ",   "T",   "h",   "i",   "s",   " ",   "i",   "s",   " ",   "a",   " ",   "t",   "e",   "s",   "t",   " ",   "m",   "e",   "s",   "s",   "a",   "g",     "e",   "Ret", "C-Spc", "C-p",   "C-p", "C-e", "C-b", "C-d", "1", "3", " ", "T",   "h", "i", "s", " ", "i", "s",   " ",   "a",   " ",   "t",     "e",     "s",   "t",   " ",   "m",
    "e",   "s",   "s",   "a",   "g",   "e",   "Ret", "1",   "4",   " ",   "T",   "h",   "i",   "s",   " ",   "i",   "s",   " ",   "a",   " ",   "t",   "e",   "s",   "t",   " ",     "m",   "e",   "s",     "s",     "a",   "g",   "e",   "Ret", "1", "5", " ", "T",   "h", "i", "s", " ", "i", "s",   " ",   "a",   " ",   "t",     "e",     "s",   "t",   " ",   "m",
    "e",   "s",   "s",   "a",   "g",   "e",   "Ret", "1",   "6",   " ",   "T",   "h",   "i",   "s",   " ",   "i",   "s",   " ",   "a",   " ",   "t",   "e",   "s",   "t",   " ",     "m",   "e",   "s",     "s",     "a",   "g",   "e",   "Ret", "1", "7", " ", "T",   "h", "i", "s", " ", "i", "s",   " ",   "a",   " ",   "t",     "e",     "s",   "t",   " ",   "m",
    "e",   "s",   "s",   "a",   "g",   "e",   "Ret", "1",   "8",   " ",   "T",   "h",   "i",   "s",   " ",   "i",   "s",   " ",   "a",   " ",   "t",   "e",   "s",   "t",   " ",     "m",   "e",   "s",     "s",     "a",   "g",   "e",   "Ret", "1", "9", " ", "T",   "h", "i", "s", " ", "i", "s",   " ",   "a",   " ",   "t",     "e",     "s",   "t",   " ",   "m",
    "e",   "s",   "s",   "a",   "g",   "e",   "Ret", "2",   "0",   " ",   "T",   "h",   "i",   "s",   " ",   "i",   "s",   " ",   "C-a", "C-f", "C-f", "C-f", "C-f", "C-f", "C-Spc", "C-p", "C-p", "C-d",   "a",     " ",   "t",   "e",   "s",   "t", " ", "m", "e",   "s", "s", "a", "g", "e", "Ret", "C-p", "C-a", "Ret", "2",     "1",     " ",   "T",   "h",   "i",
    "s",   " ",   "i",   "s",   " ",   "a",   " ",   "t",   "e",   "s",   "t",   " ",   "m",   "e",   "s",   "s",   "a",   "g",   "e",   "Ret", "2",   "2",   " ",   "T",   "h",     "i",   "s",   " ",     "i",     "s",   " ",   "a",   " ",   "t", "e", "s", "t",   " ", "m", "e", "s", "s", "a",   "g",   "e",   "Ret", "2",     "2",     " ",   "T",   "h",   "i",
    "s",   " ",   "i",   "s",   " ",   "a",   " ",   "t",   "e",   "s",   "t",   " ",   "m",   "e",   "s",   "s",   "a",   "g",   "e",   "Ret", "2",   "4",   " ",   "T",   "h",     "i",   "s",   " ",     "i",     "s",   " ",   "a",   " ",   "t", "e", "s", "t",   " ", "m", "e", "s", "s", "a",   "g",   "e",   "Ret", "2",     "5",     " ",   "T",   "h",   "i",
    "s",   " ",   "i",   "s",   " ",   "a",   " ",   "t",   "e",   "s",   "t",   " ",   "m",   "e",   "s",   "s",   "a",   "g",   "e",   "Ret", "2",   "6",   " ",   "T",   "h",     "i",   "s",   " ",     "i",     "s",   " ",   "a",   " ",   "t", "e", "s", "t",   " ", "m", "e", "s", "s", "a",   "g",   "e",   "Ret", "2",     "7",     " ",   "T",   "h",   "i",
    "s",   " ",   "i",   "s",   " ",   "a",   " ",   "t",   "e",   "s",   "t",   " ",   "m",   "e",   "s",   "s",   "a",   "g",   "e",   "Ret", "2",   "7",   " ",   "T",   "h",     "i",   "s",   " ",     "i",     "s",   " ",   "a",   " ",   "t", "e", "s", "t",   " ", "m", "e", "s", "s", "a",   "g",   "e",   "Ret", "2",     "7",     " ",   "T",   "h",   "i",
    "s",   " ",   "i",   "s",   " ",   "a",   " ",   "t",   "e",   "s",   "t",   " ",   "m",   "e",   "s",   "s",   "a",   "g",   "e",   "Ret", "2",   "7",   " ",   "T",   "h",     "i",   "s",   " ",     "i",     "s",   " ",   "a",   " ",   "t", "e", "s", "t",   " ", "m", "e", "s", "s", "a",   "g",   "e",   "Ret", "2",     "7",     " ",   "T",   "h",   "i",
    "s",   " ",   "i",   "s",   " ",   "a",   " ",   "t",   "e",   "s",   "t",   " ",   "m",   "e",   "s",   "s",   "a",   "g",   "e",   "Ret", "2",   "7",   " ",   "T",   "h",     "i",   "s",   " ",     "i",     "s",   " ",   "a",   " ",   "t", "e", "s", "t",   " ", "m", "e", "s", "s", "a",   "g",   "e",   "Ret", "2",     "7",     " ",   "T",   "h",   "i",
    "s",   " ",   "i",   "s",   " ",   "a",   " ",   "t",   "e",   "s",   "t",   " ",   "m",   "e",   "s",   "s",   "a",   "g",   "e",   "Ret", "2",   "7",   " ",   "T",   "h",     "i",   "s",   " ",     "i",     "s",   " ",   "a",   " ",   "t", "e", "s", "t",   " ", "m", "e", "s", "s", "a",   "g",   "e",   "Ret", "2",     "7",     " ",   "T",   "h",   "i",
    "s",   " ",   "i",   "s",   " ",   "a",   " ",   "t",   "e",   "s",   "t",   " ",   "m",   "e",   "s",   "s",   "a",   "g",   "e",   "Ret", "2",   "8",   " ",   "T",   "h",     "i",   "s",   " ",     "i",     "s",   " ",   "a",   " ",   "t", "e", "s", "t",   " ", "m", "e", "s", "s", "a",   "g",   "e",   "Ret", "C-Spc", "C-p",   "C-p", "C-p", "C-p", "C-p",
    "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p", "C-p",   "C-d", "A-x", "o",     "p",     "e",   "n",   " ",   "s",   "r", "c", "/", "m",   "a", "i", "n", ".", "z", "i",   "g",   "Ret", "C-n", "C-n",   "C-Spc", "C-n", "C-e", "C-n", "C-d",
    "A-x", "b",   "u",   "f",   "f",   "e",   "r",   " ",   "s",   "c",   "r",   "a",   "t",   "c",   "h",   "i",   "m",   "a",   "d",   "e",   "a",   "m",   "i",   "s",   "t",     "a",   "k",   "e",     "C-Spc", "C-a", "C-d", "b",   "u",   "f", "f", "e", "r",   " ", "s", "c", "r", "a", "t",   "c",   "h",   "Ret", "C-Spc", "C-e",   "C-b", "C-d", "e",   "n",
    "d",   "T",   "h",   "i",   "s",   " ",   "i",   "s",   " ",   "a",   " ",   "e",   "n",   "d",   " ",   "m",   "e",   "s",   "s",   "a",   "g",   "e",   "Ret", "T",   "h",     "i",   "s",   " ",     "i",     "s",   " ",   "a",   " ",   "e", "n", "d", " ",   "m", "e", "s", "s", "a", "g",   "e",   "Ret", "T",   "h",     "i",     "s",   " ",   "i",   "s",
    " ",   "a",   " ",   "e",   "n",   "d",   " ",   "m",   "e",   "s",   "s",   "a",   "g",   "e",   "Ret", "T",   "h",   "i",   "s",   " ",   "i",   "s",   " ",   "a",   " ",     "e",   "n",   "d",     " ",     "m",   "e",   "s",   "s",   "a", "g", "e", "Ret",
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const font = try TrueType.init(
        25,
        "RecMonoLinearNerdFont-Regular.ttf",
        allocator
    );
    defer font.deinit();
    var window: Window(Wayland) = undefined;

    try Window(Wayland).init(
        &window,
        1920,
        1080,
        font.scale,
        font.ratio,
        allocator,
    );
    defer window.deinit();

    var instance = try Instance.init(Wayland, &window.handle);
    defer instance.deinit();

    const device = try Device.init(&instance);
    defer device.deinit();

    const graphics_pipeline = try GraphicsPipeline.init(&instance, &device);
    defer graphics_pipeline.deinit(&device);

    var swapchain = try Swapchain.init(
        &device,
        instance.surface,
        graphics_pipeline.format,
        graphics_pipeline.render_pass,
        window.size,
        window.frame_rate,
        allocator,
    );
    defer swapchain.deinit();

    const command_pool = try CommandPool.init(&device, &swapchain, allocator);
    defer command_pool.deinit(&device);

    var painter = try Painter.init(
        &swapchain,
        &graphics_pipeline,
        &command_pool,
        &font,
        window.size,
        allocator,
    );
    defer painter.deinit();

    window.set_painter(&painter);
    try window.add_listener(painter.resize_listener());
    try window.add_listener(swapchain.resize_listener());


    // for (testing) |c| {
    //     try window.key_input(c);
    //     window.handle.get_events();

    //     try window.update();
    //     try swapchain.wait();
    // }

    while (window.state != .Closing) {
        window.handle.get_events();
        try window.update();
        try swapchain.wait();
    }
}
