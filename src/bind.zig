pub const c = @cImport({
    @cDefine("VK_USE_PLATFORM_WAYLAND_KHR", "");
    @cDefine("VK_NO_PROTOTYPES", "");
    @cInclude("vulkan/vulkan.h");
    @cInclude("xdg-shell.h");
    @cInclude("protocol.h");
    @cInclude("ft2build.h");
    @cInclude("freetype/freetype.h");
    @cInclude("dlfcn.h");
});
