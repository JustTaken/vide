const wayland = @import("wayland/core.zig");
const vulkan = @import("vulkan/core.zig");

pub fn main() !void {
    const window = try wayland.init(1920, 1080);
    const instance = try vulkan.instance_init(window.display, window.surface);
    const device = try vulkan.device_init(&instance);

    vulkan.deinit_device(&device);
    vulkan.deinit_instance(&instance);
    wayland.deinit(&window);
}
