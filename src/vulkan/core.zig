const c = @import("../bind.zig");

pub const Vulkan = struct {
    library: *anyopaque,
};

pub fn init() !Vulkan {
    const vulkan = c.dlopen("libvulkan.so", 1) orelse return error.VulkanLibraryLoading;
    return .{
        .library = vulkan,
    };
}

pub fn deinit(core: *const Vulkan) void {
    _ = c.dlclose(core.library);
}
