const std = @import("std");
const c = @import("bind.zig").c;

const check = @import("result.zig").check;

pub const Dispatch = struct {
    vkGetInstanceProcAddr: *const fn (c.VkInstance, ?[*:0]const u8) callconv(.C) c.PFN_vkVoidFunction,
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
    vkCreateWaylandSurfaceKHR: *const fn (c.VkInstance, *const c.VkWaylandSurfaceCreateInfoKHR, ?*const c.VkAllocationCallbacks, ?*c.VkSurfaceKHR) callconv(.C) void,
    vkDestroyInstance: *const fn (c.VkInstance, ?*const c.VkAllocationCallbacks) callconv(.C) void,

    fn init(library: *std.DynLib, instance: c.VkInstance) !Dispatch {
        var self: Dispatch = undefined;

        self.vkGetInstanceProcAddr = (library.lookup(
            c.PFN_vkGetInstanceProcAddr,
            "vkGetInstanceProcAddr",
        ) orelse return error.PFN_vkGetInstanceProcAddr) orelse
            return error.PointerError;

        inline for (@typeInfo(Dispatch).Struct.fields[1..]) |field| {
            const name: [:0]const u8 = @ptrCast(
                std.fmt.comptimePrint("{s}\x00", .{field.name}),
            );

            const f = self.vkGetInstanceProcAddr(
                instance,
                name,
            ) orelse return error.FunctionNotFound;

            @field(self, field.name) = @ptrCast(f);
        }

        return self;
    }
};
pub const Instance = struct {
    library: std.DynLib,
    handle: c.VkInstance,
    surface: c.VkSurfaceKHR,
    dispatch: Dispatch,

    pub fn init(Backend: type, backend: *const Backend) !Instance {
        var self: Instance = undefined;
        self.library = try std.DynLib.open("libvulkan.so");

        const vkCreateInstance = (self.library.lookup(
            c.PFN_vkCreateInstance,
            "vkCreateInstance",
        ) orelse return error.PFN_vkCreateInstanceNotFound) orelse
            return error.PointerError;

        const application_info = c.VkApplicationInfo{
            .sType = c.VK_STRUCTURE_TYPE_APPLICATION_INFO,
            .pApplicationName = "vide",
            .pEngineName = "vide",
            .engineVersion = 1,
            .apiVersion = c.VK_MAKE_API_VERSION(0, 1, 3, 0),
        };

        const validation_layers: []const [*c]const u8 = &[_][*c]const u8{
            "VK_LAYER_KHRONOS_validation",
        };

        const extensions: []const [*c]const u8 = &[_][*c]const u8{
            "VK_KHR_surface",
            "VK_KHR_wayland_surface",
        };

        const instance_create_info = c.VkInstanceCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
            .enabledLayerCount = validation_layers.len,
            .ppEnabledLayerNames = validation_layers.ptr,
            .enabledExtensionCount = extensions.len,
            .ppEnabledExtensionNames = extensions.ptr,
            .pApplicationInfo = &application_info,
        };

        try check(vkCreateInstance(&instance_create_info, null, &self.handle));

        self.dispatch = try Dispatch.init(&self.library, self.handle);
        self.create_surface(backend.display, backend.surface);

        return self;
    }

    fn create_surface(self: *Instance, display: *anyopaque, surface: *anyopaque) void {
        const info = c.VkWaylandSurfaceCreateInfoKHR{
            .sType = c.VK_STRUCTURE_TYPE_WAYLAND_SURFACE_CREATE_INFO_KHR,
            .display = @ptrCast(display),
            .surface = @ptrCast(surface),
        };

        _ = self.dispatch.vkCreateWaylandSurfaceKHR(
            self.handle,
            &info,
            null,
            &self.surface,
        );
    }

    pub fn deinit(self: *Instance) void {
        self.dispatch.vkDestroySurfaceKHR(self.handle, self.surface, null);
        self.dispatch.vkDestroyInstance(self.handle, null);

        self.library.close();
    }
};
