pub const c = @cImport({
    @cDefine("VK_USE_PLATFORM_WAYLAND_KHR", "");
    @cDefine("VK_NO_PROTOTYPES", "");
    @cInclude("vulkan/vulkan.h");
});
