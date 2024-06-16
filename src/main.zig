const wayland = @import("wayland/core.zig");
const vulkan = @import("vulkan/core.zig");

pub fn main() !void {
    const window = try wayland.init(1920, 1080);
    const renderer = try vulkan.init();
    wayland.deinit(&window);
    vulkan.deinit(&renderer);
}
