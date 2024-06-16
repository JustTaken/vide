const wayland = @import("wayland/core.zig");

pub fn main() !void {
    const window = try wayland.init();
    wayland.deinit(&window);
}
