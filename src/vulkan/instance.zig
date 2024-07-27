const std = @import("std");
const c = @import("../bind.zig").c;

const check = @import("result.zig").check;

pub const Dispatch = struct {
    vkCreateDevice: *const fn (c.VkPhysicalDevice, *const c.VkDeviceCreateInfo, ?*const c.VkAllocationCallbacks, ?*c.VkDevice) callconv(.C) i32,
    vkEnumeratePhysicalDevices: *const fn (c.VkInstance, *u32, ?[*]c.VkPhysicalDevice) callconv(.C) i32,
    vkEnumerateDeviceExtensionProperties: *const fn (c.VkPhysicalDevice, ?[*]const u8, *u32, ?[*]c.VkExtensionProperties) callconv(.C) i32,
    vkGetPhysicalDeviceProperties: *const fn (c.VkPhysicalDevice, ?*c.VkPhysicalDeviceProperties) callconv(.C) void,
    vkGetPhysicalDeviceFeatures: *const fn (c.VkPhysicalDevice, ?*c.VkPhysicalDeviceFeatures) callconv(.C) void,
    vkGetPhysicalDeviceSurfaceFormatsKHR: *const fn (c.VkPhysicalDevice, c.VkSurfaceKHR, *u32, ?[*]c.VkSurfaceFormatKHR) callconv(.C) i32,
    vkGetPhysicalDeviceSurfacePresentModesKHR: *const fn (c.VkPhysicalDevice, c.VkSurfaceKHR, *u32, ?[*]c.VkPresentModeKHR) callconv(.C) i32,
    vkGetPhysicalDeviceQueueFamilyProperties: *const fn (c.VkPhysicalDevice, *u32, ?[*]c.VkQueueFamilyProperties) callconv(.C) void,
    vkGetPhysicalDeviceSurfaceCapabilitiesKHR: *const fn (c.VkPhysicalDevice, c.VkSurfaceKHR, *c.VkSurfaceCapabilitiesKHR) callconv(.C) i32,
    vkGetPhysicalDeviceSurfaceSupportKHR: *const fn (c.VkPhysicalDevice, u32, c.VkSurfaceKHR, *u32) callconv(.C) i32,
    vkGetPhysicalDeviceMemoryProperties: *const fn (c.VkPhysicalDevice, *c.VkPhysicalDeviceMemoryProperties) callconv(.C) void,
    vkGetPhysicalDeviceFormatProperties: *const fn (c.VkPhysicalDevice, c.VkFormat, *c.VkFormatProperties) callconv(.C) void,
    vkDestroySurfaceKHR: *const fn (c.VkInstance, c.VkSurfaceKHR, ?*const c.VkAllocationCallbacks) callconv(.C) void,
    vkDestroyInstance: *const fn (c.VkInstance, ?*const c.VkAllocationCallbacks) callconv(.C) void,
    vkGetInstanceProcAddr: *const fn (c.VkInstance, ?[*:0]const u8) callconv(.C) c.PFN_vkVoidFunction,

    fn init(library: *std.DynLib, instance: c.VkInstance) !Dispatch {
        const vkGetInstanceProcAddr = (library.lookup(c.PFN_vkGetInstanceProcAddr, "vkGetInstanceProcAddr") orelse return error.PFN_vkGetInstanceProcAddr) orelse return error.PointerError;
        return Dispatch {
            .vkGetInstanceProcAddr = vkGetInstanceProcAddr,
            .vkDestroySurfaceKHR = @as(c.PFN_vkDestroySurfaceKHR, @ptrCast(vkGetInstanceProcAddr(instance, "vkDestroySurfaceKHR"))) orelse return error.FunctionNotFound,
            .vkEnumeratePhysicalDevices = @as(c.PFN_vkEnumeratePhysicalDevices, @ptrCast(vkGetInstanceProcAddr(instance, "vkEnumeratePhysicalDevices"))) orelse return error.FunctionNotFound,
            .vkEnumerateDeviceExtensionProperties = @as(c.PFN_vkEnumerateDeviceExtensionProperties, @ptrCast(vkGetInstanceProcAddr(instance, "vkEnumerateDeviceExtensionProperties"))) orelse return error.FunctionNotFound,
            .vkGetPhysicalDeviceProperties = @as(c.PFN_vkGetPhysicalDeviceProperties, @ptrCast(vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceProperties"))) orelse return error.FunctionNotFound,
            .vkGetPhysicalDeviceFeatures = @as(c.PFN_vkGetPhysicalDeviceFeatures, @ptrCast(vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceFeatures"))) orelse return error.FunctionNotFound,
            .vkGetPhysicalDeviceSurfaceFormatsKHR = @as(c.PFN_vkGetPhysicalDeviceSurfaceFormatsKHR, @ptrCast(vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfaceFormatsKHR"))) orelse return error.FunctionNotFound,
            .vkGetPhysicalDeviceSurfacePresentModesKHR = @as(c.PFN_vkGetPhysicalDeviceSurfacePresentModesKHR, @ptrCast(vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfacePresentModesKHR"))) orelse return error.FunctionNotFound,
            .vkGetPhysicalDeviceQueueFamilyProperties = @as(c.PFN_vkGetPhysicalDeviceQueueFamilyProperties, @ptrCast(vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceQueueFamilyProperties"))) orelse return error.FunctionNotFound,
            .vkGetPhysicalDeviceSurfaceCapabilitiesKHR = @as(c.PFN_vkGetPhysicalDeviceSurfaceCapabilitiesKHR, @ptrCast(vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfaceCapabilitiesKHR"))) orelse return error.FunctionNotFound,
            .vkGetPhysicalDeviceSurfaceSupportKHR = @as(c.PFN_vkGetPhysicalDeviceSurfaceSupportKHR, @ptrCast(vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfaceSupportKHR"))) orelse return error.FunctionNotFound,
            .vkGetPhysicalDeviceMemoryProperties = @as(c.PFN_vkGetPhysicalDeviceMemoryProperties, @ptrCast(vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceMemoryProperties"))) orelse return error.FunctionNotFound,
            .vkGetPhysicalDeviceFormatProperties = @as(c.PFN_vkGetPhysicalDeviceFormatProperties, @ptrCast(vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceFormatProperties"))) orelse return error.FunctionNotFound,
            .vkCreateDevice = @as(c.PFN_vkCreateDevice, @ptrCast(vkGetInstanceProcAddr(instance, "vkCreateDevice"))) orelse return error.FunctionNotFound,
            .vkDestroyInstance = @as(c.PFN_vkDestroyInstance, @ptrCast(vkGetInstanceProcAddr(instance, "vkDestroyInstance"))) orelse return error.FunctionNotFound,
        };
    }
};
pub const Instance = struct {
    library: std.DynLib,
    handle: c.VkInstance,
    surface: c.VkSurfaceKHR,
    dispatch: Dispatch,

    pub fn init(Backend: type, backend: *const Backend) !Instance {
        var library = try std.DynLib.open("libvulkan.so");
        const vkCreateInstance = (library.lookup(c.PFN_vkCreateInstance, "vkCreateInstance") orelse return error.PFN_vkCreateInstanceNotFound) orelse return error.PointerError;

        const application_info = c.VkApplicationInfo {
            .sType = c.VK_STRUCTURE_TYPE_APPLICATION_INFO,
            .pApplicationName = "vide",
            .pEngineName = "vide",
            .engineVersion = 1,
            .apiVersion = c.VK_MAKE_API_VERSION(0, 1, 3, 0),
        };

        const validation_layers: []const [*c]const u8 = &[_][*c]const u8 { "VK_LAYER_KHRONOS_validation" };
        const extensions: []const [*c]const u8 = &[_][*c]const u8 {
            "VK_KHR_surface",
            "VK_KHR_wayland_surface"
        };

        const instance_create_info = c.VkInstanceCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
            .enabledLayerCount = validation_layers.len,
            .ppEnabledLayerNames = validation_layers.ptr,
            .enabledExtensionCount = extensions.len,
            .ppEnabledExtensionNames = extensions.ptr,
            .pApplicationInfo = &application_info,
        };

        var instance: c.VkInstance = undefined;
        try check(vkCreateInstance(&instance_create_info, null, &instance));

        const dispatch = try Dispatch.init(&library, instance);

        return Instance {
             .library = library,
             .handle = instance,
             .dispatch = dispatch,
             .surface = try backend.get_surface(instance, &dispatch),
        };
    }

    pub fn deinit(self: *Instance) void {
        self.dispatch.vkDestroySurfaceKHR(self.handle, self.surface, null);
        self.dispatch.vkDestroyInstance(self.handle, null);

        self.library.close();
    }
};

