const std = @import("std");
const c = @import("../bind.zig");

var ARENA = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const ALLOCATOR = ARENA.allocator();

pub const InstanceDispatch = struct {
    handle: c.VkInstance,
    surface: c.VkSurfaceKHR,
    library: *anyopaque,
    vkCreateInstance: *const fn (?*const c.VkInstanceCreateInfo, ?*const c.VkAllocationCallbacks, ?*c.VkInstance) callconv(.C) i32,
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
    vkCreateWaylandSurfaceKHR: *const fn (c.VkInstance, *const c.VkWaylandSurfaceCreateInfoKHR, ?*const c.VkAllocationCallbacks, *c.VkSurfaceKHR) callconv(.C) i32,
    vkDestroyInstance: *const fn (c.VkInstance, ?*const c.VkAllocationCallbacks) callconv(.C) void,
    vkGetInstanceProcAddr: *const fn (c.VkInstance, ?[*:0]const u8) callconv(.C) c.PFN_vkVoidFunction,
};

pub const DeviceDispatch = struct {
    handle: c.VkDevice,
    queues: [4]c.VkQueue,
    families: [4]u8,
    physical_device: c.VkPhysicalDevice,
    vkGetDeviceQueue: *const fn (c.VkDevice, u32, u32, *c.VkQueue) callconv(.C) void,
    vkAllocateCommandBuffers: *const fn (c.VkDevice, *const c.VkCommandBufferAllocateInfo, *c.VkCommandBuffer) callconv(.C) i32,
    vkAllocateMemory: *const fn (c.VkDevice, *const c.VkMemoryAllocateInfo, ?*const c.VkAllocationCallbacks, *c.VkDeviceMemory) callconv(.C) i32,
    vkAllocateDescriptorSets: *const fn (c.VkDevice, *const c.VkDescriptorSetAllocateInfo, *c.VkDescriptorSet) callconv(.C) i32,
    vkQueueSubmit: *const fn (c.VkQueue, u32, *const c.VkSubmitInfo, c.VkFence) callconv(.C) i32,
    vkQueuePresentKHR: *const fn (c.VkQueue, *const c.VkPresentInfoKHR) callconv(.C) i32,
    vkQueueWaitIdle: *const fn (c.VkQueue) callconv(.C) i32,
    vkGetImageMemoryRequirements: *const fn (c.VkDevice, c.VkImage, *c.VkMemoryRequirements) callconv(.C) void,
    vkGetSwapchainImagesKHR: *const fn (c.VkDevice, c.VkSwapchainKHR, *u32, ?[*]c.VkImage) callconv(.C) i32,
    vkGetBufferMemoryRequirements: *const fn (c.VkDevice, c.VkBuffer, *c.VkMemoryRequirements) callconv(.C) void,
    vkBindBufferMemory: *const fn (c.VkDevice, c.VkBuffer, c.VkDeviceMemory, u64) callconv(.C) i32,
    vkBindImageMemory: *const fn (c.VkDevice, c.VkImage, c.VkDeviceMemory, u64) callconv(.C) i32,
    vkAcquireNextImageKHR: *const fn (c.VkDevice, c.VkSwapchainKHR, u64, c.VkSemaphore, c.VkFence, *u32) callconv(.C) i32,
    vkWaitForFences: *const fn (c.VkDevice, u32, *const c.VkFence, u32, u64) callconv(.C) i32,
    vkResetFences: *const fn (c.VkDevice, u32, *const c.VkFence) callconv(.C) i32,
    vkCreateSwapchainKHR: *const fn (c.VkDevice, *const c.VkSwapchainCreateInfoKHR, ?*const c.VkAllocationCallbacks, *c.VkSwapchainKHR) callconv(.C) i32,
    vkCreateImage: *const fn (c.VkDevice, *const c.VkImageCreateInfo, ?*const c.VkAllocationCallbacks, *c.VkImage) callconv(.C) i32,
    vkCreateShaderModule: *const fn (c.VkDevice, *const c.VkShaderModuleCreateInfo, ?*const c.VkAllocationCallbacks, *c.VkShaderModule) callconv(.C) i32,
    vkCreatePipelineLayout: *const fn (c.VkDevice, *const c.VkPipelineLayoutCreateInfo, ?*const c.VkAllocationCallbacks, *c.VkPipelineLayout) callconv(.C) i32,
    vkCreateImageView: *const fn (c.VkDevice, *const c.VkImageViewCreateInfo, ?*const c.VkAllocationCallbacks, *c.VkImageView) callconv(.C) i32,
    vkCreateRenderPass: *const fn (c.VkDevice, *const c.VkRenderPassCreateInfo, ?*const c.VkAllocationCallbacks, *c.VkRenderPass) callconv(.C) i32,
    vkCreateGraphicsPipelines: *const fn (c.VkDevice, c.VkPipelineCache, u32, *const c.VkGraphicsPipelineCreateInfo, ?*const c.VkAllocationCallbacks, *c.VkPipeline) callconv(.C) i32,
    vkCreateFramebuffer: *const fn (c.VkDevice, *const c.VkFramebufferCreateInfo, ?*const c.VkAllocationCallbacks, *c.VkFramebuffer) callconv(.C) i32,
    vkCreateCommandPool: *const fn (c.VkDevice, *const c.VkCommandPoolCreateInfo, ?*const c.VkAllocationCallbacks, *c.VkCommandPool) callconv(.C) i32,
    vkCreateSemaphore: *const fn (c.VkDevice, *const c.VkSemaphoreCreateInfo, ?*const c.VkAllocationCallbacks, *c.VkSemaphore) callconv(.C) i32,
    vkCreateFence: *const fn (c.VkDevice, *const c.VkFenceCreateInfo, ?*const c.VkAllocationCallbacks, *c.VkFence) callconv(.C) i32,
    vkCreateBuffer: *const fn (c.VkDevice, *const c.VkBufferCreateInfo, ?*const c.VkAllocationCallbacks, *c.VkBuffer) callconv(.C) i32,
    vkCreateSampler: *const fn (c.VkDevice, *const c.VkSamplerCreateInfo, ?*const c.VkAllocationCallbacks, *c.VkSampler) callconv(.C) i32,
    vkCreateDescriptorSetLayout: *const fn (c.VkDevice, *const c.VkDescriptorSetLayoutCreateInfo, ?*const c.VkAllocationCallbacks, *c.VkDescriptorSetLayout) callconv(.C) i32,
    vkCreateDescriptorPool: *const fn (c.VkDevice, *const c.VkDescriptorPoolCreateInfo, ?*const c.VkAllocationCallbacks, *c.VkDescriptorPool) callconv(.C) i32,
    vkDestroyCommandPool: *const fn (c.VkDevice, c.VkCommandPool, ?*const c.VkAllocationCallbacks) callconv(.C) void,
    vkDestroyPipeline: *const fn (c.VkDevice, c.VkPipeline, ?*const c.VkAllocationCallbacks) callconv(.C) void,
    vkDestroyPipelineLayout: *const fn (c.VkDevice, c.VkPipelineLayout, ?*const c.VkAllocationCallbacks) callconv(.C) void,
    vkDestroyRenderPass: *const fn (c.VkDevice, c.VkRenderPass, ?*const c.VkAllocationCallbacks) callconv(.C) void,
    vkDestroyImage: *const fn (c.VkDevice, c.VkImage, ?*const c.VkAllocationCallbacks) callconv(.C) void,
    vkDestroyImageView: *const fn (c.VkDevice, c.VkImageView, ?*const c.VkAllocationCallbacks) callconv(.C) void,
    vkDestroySwapchainKHR: *const fn (c.VkDevice, c.VkSwapchainKHR, ?*const c.VkAllocationCallbacks) callconv(.C) void,
    vkDestroyShaderModule: *const fn (c.VkDevice, c.VkShaderModule, ?*const c.VkAllocationCallbacks) callconv(.C) void,
    vkDestroySemaphore: *const fn (c.VkDevice, c.VkSemaphore, ?*const c.VkAllocationCallbacks) callconv(.C) void,
    vkDestroyFence: *const fn (c.VkDevice, c.VkFence, ?*const c.VkAllocationCallbacks) callconv(.C) void,
    vkDestroyFramebuffer: *const fn (c.VkDevice, c.VkFramebuffer, ?*const c.VkAllocationCallbacks) callconv(.C) void,
    vkDestroyBuffer: *const fn (c.VkDevice, c.VkBuffer, ?*const c.VkAllocationCallbacks) callconv(.C) void,
    vkDestroyDescriptorSetLayout: *const fn (c.VkDevice, c.VkDescriptorSetLayout, ?*const c.VkAllocationCallbacks) callconv(.C) void,
    vkDestroyDescriptorPool: *const fn (c.VkDevice, c.VkDescriptorPool, ?*const c.VkAllocationCallbacks) callconv(.C) void,
    vkBeginCommandBuffer: *const fn (c.VkCommandBuffer, *const c.VkCommandBufferBeginInfo) callconv(.C) i32,
    vkCmdBeginRenderPass: *const fn (c.VkCommandBuffer, *const c.VkRenderPassBeginInfo, c.VkSubpassContents) callconv(.C) void,
    vkCmdBindPipeline: *const fn (c.VkCommandBuffer, c.VkPipelineBindPoint, c.VkPipeline) callconv(.C) void,
    vkCmdBindVertexBuffers: *const fn (c.VkCommandBuffer, u32, u32, *const c.VkBuffer, *const u64) callconv(.C) void,
    vkCmdBindIndexBuffer: *const fn (c.VkCommandBuffer, c.VkBuffer, u64, c.VkIndexType) callconv(.C) void,
    vkCmdSetViewport: *const fn (c.VkCommandBuffer, u32, u32, *const c.VkViewport) callconv(.C) void,
    vkCmdSetScissor: *const fn (c.VkCommandBuffer, u32, u32, *const c.VkRect2D) callconv(.C) void,
    vkCmdCopyBufferToImage: *const fn (c.VkCommandBuffer, c.VkBuffer, c.VkImage, c.VkImageLayout, u32, *const c.VkBufferImageCopy) callconv(.C) void,
    vkCmdCopyBuffer: *const fn (c.VkCommandBuffer, c.VkBuffer, c.VkBuffer, u32, *const c.VkBufferCopy) callconv(.C) void,
    vkCmdDraw: *const fn (c.VkCommandBuffer, u32, u32, u32, u32) callconv(.C) void,
    vkCmdDrawIndexed: *const fn (c.VkCommandBuffer, u32, u32, u32, i32, u32) callconv(.C) void,
    vkCmdPushConstants: *const fn (c.VkCommandBuffer, c.VkPipelineLayout, c.VkShaderStageFlags, u32, u32, ?*const anyopaque) callconv(.C) void,
    vkCmdPipelineBarrier: *const fn (c.VkCommandBuffer, c.VkPipelineStageFlags, c.VkPipelineStageFlags, c.VkDependencyFlags, u32, ?*const c.VkMemoryBarrier, u32, ?*const c.VkBufferMemoryBarrier, u32, ?*const c.VkImageMemoryBarrier) callconv(.C) void,
    vkUpdateDescriptorSets: *const fn (c.VkDevice, u32, [*]const c.VkWriteDescriptorSet, u32, ?*const c.VkCopyDescriptorSet) callconv(.C) void,
    vkCmdBindDescriptorSets: *const fn (c.VkCommandBuffer, c.VkPipelineBindPoint, c.VkPipelineLayout, u32, u32, [*]const c.VkDescriptorSet, u32, ?*const u32) callconv(.C) void,
    vkCmdEndRenderPass: *const fn (c.VkCommandBuffer) callconv(.C) void,
    vkEndCommandBuffer: *const fn (c.VkCommandBuffer) callconv(.C) i32,
    vkResetCommandBuffer: *const fn (c.VkCommandBuffer, c.VkCommandBufferResetFlags) callconv(.C) i32,
    vkFreeMemory: *const fn (c.VkDevice, c.VkDeviceMemory, ?*const c.VkAllocationCallbacks) callconv(.C) void,
    vkFreeCommandBuffers: *const fn (c.VkDevice, c.VkCommandPool, u32, *const c.VkCommandBuffer) callconv(.C) void,
    vkFreeDescriptorSets: *const fn (c.VkDevice, c.VkDescriptorPool, u32, *const c.VkDescriptorSet) callconv(.C) i32,
    vkMapMemory: *const fn (c.VkDevice, c.VkDeviceMemory, u64, u64, u32, *?*anyopaque) callconv(.C) i32,
    vkUnmapMemory: *const fn (c.VkDevice, c.VkDeviceMemory) callconv(.C) void,
    vkDestroyDevice: *const fn (c.VkDevice, ?*const c.VkAllocationCallbacks) callconv(.C) void,
    vkDestroySampler: *const fn (c.VkDevice, c.VkSampler, ?*const c.VkAllocationCallbacks) callconv(.C) void,
    vkGetDeviceProcAddr: *const fn (c.VkDevice, ?[*:0]const u8) callconv(.C) c.PFN_vkVoidFunction,
};

const GpuType = enum {
    Other,
    Integrated,
    Discrete,
    Virtual,
    Cpu
};

pub fn instance_init(wayland_display: *c.wl_display, wayland_surface: *c.wl_surface) !InstanceDispatch {
    const vulkan = c.dlopen("libvulkan.so", 1) orelse return error.VulkanLibraryLoading;
    const vkCreateInstance = @as(c.PFN_vkCreateInstance, @ptrCast(c.dlsym(vulkan, "vkCreateInstance"))) orelse return error.PFN_vkCreateInstanceNotFound;
    var instance_handle: c.VkInstance = undefined;

    const application_info = c.VkApplicationInfo{
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

    const result = vkCreateInstance(&instance_create_info, null, &instance_handle);
    if (result != 0) return error.InstanceCreate;

    const vkGetInstanceProcAddr = @as(c.PFN_vkGetInstanceProcAddr, @ptrCast(c.dlsym(vulkan, "vkGetInstanceProcAddr"))) orelse return error.PFN_vkGetInstanceProcAddr;
    const vkDestroySurfaceKHR = @as(c.PFN_vkDestroySurfaceKHR, @ptrCast(vkGetInstanceProcAddr(instance_handle, "vkDestroySurfaceKHR"))) orelse return error.FunctionNotFound;
    const vkEnumeratePhysicalDevices = @as(c.PFN_vkEnumeratePhysicalDevices, @ptrCast(vkGetInstanceProcAddr(instance_handle, "vkEnumeratePhysicalDevices"))) orelse return error.FunctionNotFound;
    const vkEnumerateDeviceExtensionProperties = @as(c.PFN_vkEnumerateDeviceExtensionProperties, @ptrCast(vkGetInstanceProcAddr(instance_handle, "vkEnumerateDeviceExtensionProperties"))) orelse return error.FunctionNotFound;
    const vkGetPhysicalDeviceProperties = @as(c.PFN_vkGetPhysicalDeviceProperties, @ptrCast(vkGetInstanceProcAddr(instance_handle, "vkGetPhysicalDeviceProperties"))) orelse return error.FunctionNotFound;
    const vkGetPhysicalDeviceFeatures = @as(c.PFN_vkGetPhysicalDeviceFeatures, @ptrCast(vkGetInstanceProcAddr(instance_handle, "vkGetPhysicalDeviceFeatures"))) orelse return error.FunctionNotFound;
    const vkGetPhysicalDeviceSurfaceFormatsKHR = @as(c.PFN_vkGetPhysicalDeviceSurfaceFormatsKHR, @ptrCast(vkGetInstanceProcAddr(instance_handle, "vkGetPhysicalDeviceSurfaceFormatsKHR"))) orelse return error.FunctionNotFound;
    const vkGetPhysicalDeviceSurfacePresentModesKHR = @as(c.PFN_vkGetPhysicalDeviceSurfacePresentModesKHR, @ptrCast(vkGetInstanceProcAddr(instance_handle, "vkGetPhysicalDeviceSurfacePresentModesKHR"))) orelse return error.FunctionNotFound;
    const vkGetPhysicalDeviceQueueFamilyProperties = @as(c.PFN_vkGetPhysicalDeviceQueueFamilyProperties, @ptrCast(vkGetInstanceProcAddr(instance_handle, "vkGetPhysicalDeviceQueueFamilyProperties"))) orelse return error.FunctionNotFound;
    const vkGetPhysicalDeviceSurfaceCapabilitiesKHR = @as(c.PFN_vkGetPhysicalDeviceSurfaceCapabilitiesKHR, @ptrCast(vkGetInstanceProcAddr(instance_handle, "vkGetPhysicalDeviceSurfaceCapabilitiesKHR"))) orelse return error.FunctionNotFound;
    const vkGetPhysicalDeviceSurfaceSupportKHR = @as(c.PFN_vkGetPhysicalDeviceSurfaceSupportKHR, @ptrCast(vkGetInstanceProcAddr(instance_handle, "vkGetPhysicalDeviceSurfaceSupportKHR"))) orelse return error.FunctionNotFound;
    const vkGetPhysicalDeviceMemoryProperties = @as(c.PFN_vkGetPhysicalDeviceMemoryProperties, @ptrCast(vkGetInstanceProcAddr(instance_handle, "vkGetPhysicalDeviceMemoryProperties"))) orelse return error.FunctionNotFound;
    const vkGetPhysicalDeviceFormatProperties = @as(c.PFN_vkGetPhysicalDeviceFormatProperties, @ptrCast(vkGetInstanceProcAddr(instance_handle, "vkGetPhysicalDeviceFormatProperties"))) orelse return error.FunctionNotFound;
    const vkCreateDevice = @as(c.PFN_vkCreateDevice, @ptrCast(vkGetInstanceProcAddr(instance_handle, "vkCreateDevice"))) orelse return error.FunctionNotFound;
    const vkDestroyInstance = @as(c.PFN_vkDestroyInstance, @ptrCast(vkGetInstanceProcAddr(instance_handle, "vkDestroyInstance"))) orelse return error.FunctionNotFound;

    const vkCreateWaylandSurfaceKHR = @as(c.PFN_vkCreateWaylandSurfaceKHR, @ptrCast(vkGetInstanceProcAddr(instance_handle, "vkCreateWaylandSurfaceKHR"))) orelse return error.FunctionNotFound;
    var surface: c.VkSurfaceKHR = undefined;

    const wayland_surface_create_info = c.VkWaylandSurfaceCreateInfoKHR {
        .sType = c.VK_STRUCTURE_TYPE_WAYLAND_SURFACE_CREATE_INFO_KHR,
        .display = wayland_display,
        .surface = wayland_surface,
    };

    _ = vkCreateWaylandSurfaceKHR(instance_handle, &wayland_surface_create_info, null, &surface);

    return .{
        .handle = instance_handle,
        .surface = surface,
        .library = vulkan,
        .vkCreateInstance = vkCreateInstance,
        .vkCreateDevice = vkCreateDevice,
        .vkCreateWaylandSurfaceKHR = vkCreateWaylandSurfaceKHR,
        .vkEnumeratePhysicalDevices = vkEnumeratePhysicalDevices,
        .vkEnumerateDeviceExtensionProperties = vkEnumerateDeviceExtensionProperties,
        .vkGetPhysicalDeviceProperties = vkGetPhysicalDeviceProperties,
        .vkGetPhysicalDeviceFeatures = vkGetPhysicalDeviceFeatures,
        .vkGetPhysicalDeviceSurfaceFormatsKHR = vkGetPhysicalDeviceSurfaceFormatsKHR,
        .vkGetPhysicalDeviceSurfacePresentModesKHR = vkGetPhysicalDeviceSurfacePresentModesKHR,
        .vkGetPhysicalDeviceQueueFamilyProperties = vkGetPhysicalDeviceQueueFamilyProperties,
        .vkGetPhysicalDeviceSurfaceCapabilitiesKHR = vkGetPhysicalDeviceSurfaceCapabilitiesKHR,
        .vkGetPhysicalDeviceSurfaceSupportKHR = vkGetPhysicalDeviceSurfaceSupportKHR,
        .vkGetPhysicalDeviceMemoryProperties = vkGetPhysicalDeviceMemoryProperties,
        .vkGetPhysicalDeviceFormatProperties = vkGetPhysicalDeviceFormatProperties,
        .vkDestroySurfaceKHR = vkDestroySurfaceKHR,
        .vkDestroyInstance = vkDestroyInstance,
        .vkGetInstanceProcAddr = vkGetInstanceProcAddr,
    };
}

const PhysicalDeviceValuation = struct {
    match_extensions: bool,
    has_sampler_anisotropy: bool,
    has_geometry_shader: bool,
    has_formats: bool,
    has_present_modes: bool,
    families: [4]u8,
    typ: GpuType,
};

fn avaliate_physical_device(
    dispatch: *const InstanceDispatch,
    required_extensions: []const [*:0]const u8,
    physical_device: c.VkPhysicalDevice,
) PhysicalDeviceValuation {
    var valuation = PhysicalDeviceValuation {
        .match_extensions = false,
        .has_sampler_anisotropy = false,
        .has_geometry_shader = false,
        .has_formats = false,
        .has_present_modes = false,
        .families = .{ 0xFF, 0xFF, 0xFF, 0xFF },
        .typ = .Other,
    };

    {
        var count: u32 = 0;
        _ = dispatch.vkEnumerateDeviceExtensionProperties(physical_device, null, &count, null);
        const properties = ALLOCATOR.alloc(c.VkExtensionProperties, count) catch return valuation;
        _ = dispatch.vkEnumerateDeviceExtensionProperties(physical_device, null, &count, properties.ptr);

        for (required_extensions) |extension| {
            valuation.match_extensions = false;

            for (properties) |property| {
                if (std.mem.eql(u8, std.mem.span(extension), std.mem.sliceTo(&property.extensionName, 0))) break;
            } else continue;

            valuation.match_extensions = true;
        }
    }

    {
         var count: u32 = 0;
        _ = dispatch.vkGetPhysicalDeviceSurfaceFormatsKHR(physical_device, dispatch.surface, &count, null);
        if (count != 0) valuation.has_formats = true;
    }
    {
        var count: u32 = 0;
        _ = dispatch.vkGetPhysicalDeviceSurfacePresentModesKHR(physical_device, dispatch.surface, &count, null);
        if (count != 0) valuation.has_present_modes = true;
    }
    {
        var families: [4]u8 = .{0xFF, 0xFF, 0xFF, 0xFF};
        var count: u32 = 0;

        dispatch.vkGetPhysicalDeviceQueueFamilyProperties(physical_device, &count, null);
        const properties = ALLOCATOR.alloc(c.VkQueueFamilyProperties, count) catch return valuation;
        dispatch.vkGetPhysicalDeviceQueueFamilyProperties(physical_device, &count, properties.ptr);

        for (0..count) |i| {
            const family: u8 = @intCast(i);
            const index: u32 = @intCast(i);

            var surface_support: u32 = 0;
            _ = dispatch.vkGetPhysicalDeviceSurfaceSupportKHR(physical_device, index, dispatch.surface, &surface_support);

            if (families[0] == 0xFF and properties[i].queueFlags & c.VK_QUEUE_GRAPHICS_BIT != 0) families[0] = family;
            if (families[1] == 0xFF and surface_support != 0) families[1] = family;
            if (families[2] == 0xFF and properties[i].queueFlags & c.VK_QUEUE_COMPUTE_BIT != 0) families[2] = family;
            if (families[3] == 0xFF and properties[i].queueFlags & c.VK_QUEUE_TRANSFER_BIT != 0) families[3] = family;
        }

        valuation.families = families;
    }

    {
        var features: c.VkPhysicalDeviceFeatures = undefined;
        dispatch.vkGetPhysicalDeviceFeatures(physical_device, &features);
        valuation.has_geometry_shader = features.geometryShader == 1 ;
        valuation.has_sampler_anisotropy = features.samplerAnisotropy == 1;
    }
    {
        var properties: c.VkPhysicalDeviceProperties = undefined;
        dispatch.vkGetPhysicalDeviceProperties(physical_device, &properties);

        valuation.typ = switch (properties.deviceType) {
            @intFromEnum(GpuType.Discrete) => GpuType.Discrete,
            @intFromEnum(GpuType.Integrated) => GpuType.Integrated,
            @intFromEnum(GpuType.Virtual) => GpuType.Virtual,
            else => GpuType.Other,
        };
    }

    return valuation;
}

pub fn device_init(instance_dispatch: *const InstanceDispatch) !DeviceDispatch {
    var count: u32 = 0;

    _ = instance_dispatch.vkEnumeratePhysicalDevices(instance_dispatch.handle, &count, null);
    var physical_devices: [3]c.VkPhysicalDevice = undefined;
    _ = instance_dispatch.vkEnumeratePhysicalDevices(instance_dispatch.handle, &count, &physical_devices);

    var max_valuation: u32 = 0;
    var physical_device: c.VkPhysicalDevice = undefined;
    var families: [4]u8 = undefined;
    const required_extensions = [_][*:0]const u8{ c.VK_KHR_SWAPCHAIN_EXTENSION_NAME };

    out: for (0..count) |i| {
        var sum: u32 = 1;
        const valuation = avaliate_physical_device(instance_dispatch, &required_extensions, physical_devices[i]);

        if (
            !valuation.match_extensions or
            !valuation.has_geometry_shader or
            !valuation.has_sampler_anisotropy or
            !valuation.has_present_modes or
            !valuation.has_formats
        ) continue;

        for (valuation.families) |family| {
            if (family == 255) continue :out;
        }

        sum += switch (valuation.typ) {
            GpuType.Discrete => 4,
            GpuType.Integrated => 3,
            GpuType.Virtual => 2,
            GpuType.Other => 1,
            GpuType.Cpu => 0,
        };


        if (sum > max_valuation) {
            physical_device = physical_devices[i];
            max_valuation = sum;
            families = valuation.families;
        }
    }

    if (max_valuation == 0) return error.PhysicalDeviceRequisits;

    var queue_count: u32 = 0;
    var last_value: u32 = 0xFF;
    var queue_create_infos: [4]c.VkDeviceQueueCreateInfo = undefined;

    for (families) |family| {
        if (family != last_value) {
            last_value = family;
            queue_create_infos[queue_count] = .{
                .sType = c.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
                .queueFamilyIndex = family,
                .queueCount = 1,
                .pQueuePriorities = &[_]f32 { 1.0 },
            };

            queue_count += 1;
        }
    }

    var features: c.VkPhysicalDeviceFeatures = undefined;
    instance_dispatch.vkGetPhysicalDeviceFeatures(physical_device, &features);

    var device: c.VkDevice = undefined;
    const device_create_info = c.VkDeviceCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
        .queueCreateInfoCount = queue_count,
        .pQueueCreateInfos = &queue_create_infos[0],
        .pEnabledFeatures = &features,
        .enabledExtensionCount = 1,
        .ppEnabledExtensionNames = &required_extensions[0],
    };

    _ = instance_dispatch.vkCreateDevice(physical_device, &device_create_info, null, &device);

    const vkGetDeviceProcAddr = @as(c.PFN_vkGetDeviceProcAddr, @ptrCast(instance_dispatch.vkGetInstanceProcAddr(instance_dispatch.handle, "vkGetDeviceProcAddr"))) orelse return error.FunctionNotFound;

    const vkAllocateCommandBuffers = @as(c.PFN_vkAllocateCommandBuffers, @ptrCast(vkGetDeviceProcAddr(device, "vkAllocateCommandBuffers"))) orelse return error.FunctionNotFound;
    const vkAllocateMemory = @as(c.PFN_vkAllocateMemory, @ptrCast(vkGetDeviceProcAddr(device, "vkAllocateMemory"))) orelse return error.FunctionNotFound;
    const vkAllocateDescriptorSets = @as(c.PFN_vkAllocateDescriptorSets, @ptrCast(vkGetDeviceProcAddr(device, "vkAllocateDescriptorSets"))) orelse return error.FunctionNotFound;
    const vkGetDeviceQueue = @as(c.PFN_vkGetDeviceQueue, @ptrCast(vkGetDeviceProcAddr(device, "vkGetDeviceQueue"))) orelse return error.FunctionNotFound;
    const vkQueueSubmit = @as(c.PFN_vkQueueSubmit, @ptrCast(vkGetDeviceProcAddr(device, "vkQueueSubmit"))) orelse return error.FunctionNotFound;
    const vkQueuePresentKHR = @as(c.PFN_vkQueuePresentKHR, @ptrCast(vkGetDeviceProcAddr(device, "vkQueuePresentKHR"))) orelse return error.FunctionNotFound;
    const vkQueueWaitIdle = @as(c.PFN_vkQueueWaitIdle, @ptrCast(vkGetDeviceProcAddr(device, "vkQueueWaitIdle"))) orelse return error.FunctionNotFound;
    const vkGetSwapchainImagesKHR = @as(c.PFN_vkGetSwapchainImagesKHR, @ptrCast(vkGetDeviceProcAddr(device, "vkGetSwapchainImagesKHR"))) orelse return error.FunctionNotFound;
    const vkGetImageMemoryRequirements = @as(c.PFN_vkGetImageMemoryRequirements, @ptrCast(vkGetDeviceProcAddr(device, "vkGetImageMemoryRequirements"))) orelse return error.FunctionNotFound;
    const vkGetBufferMemoryRequirements = @as(c.PFN_vkGetBufferMemoryRequirements, @ptrCast(vkGetDeviceProcAddr(device, "vkGetBufferMemoryRequirements"))) orelse return error.FunctionNotFound;
    const vkBindBufferMemory = @as(c.PFN_vkBindBufferMemory, @ptrCast(vkGetDeviceProcAddr(device, "vkBindBufferMemory"))) orelse return error.FunctionNotFound;
    const vkBindImageMemory = @as(c.PFN_vkBindImageMemory, @ptrCast(vkGetDeviceProcAddr(device, "vkBindImageMemory"))) orelse return error.FunctionNotFound;
    const vkAcquireNextImageKHR = @as(c.PFN_vkAcquireNextImageKHR, @ptrCast(vkGetDeviceProcAddr(device, "vkAcquireNextImageKHR"))) orelse return error.FunctionNotFound;
    const vkWaitForFences = @as(c.PFN_vkWaitForFences, @ptrCast(vkGetDeviceProcAddr(device, "vkWaitForFences"))) orelse return error.FunctionNotFound;
    const vkResetFences = @as(c.PFN_vkResetFences, @ptrCast(vkGetDeviceProcAddr(device, "vkResetFences"))) orelse return error.FunctionNotFound;
    const vkCreateSwapchainKHR = @as(c.PFN_vkCreateSwapchainKHR, @ptrCast(vkGetDeviceProcAddr(device, "vkCreateSwapchainKHR"))) orelse return error.FunctionNotFound;
    const vkCreateImage = @as(c.PFN_vkCreateImage, @ptrCast(vkGetDeviceProcAddr(device, "vkCreateImage"))) orelse return error.FunctionNotFound;
    const vkCreateImageView = @as(c.PFN_vkCreateImageView, @ptrCast(vkGetDeviceProcAddr(device, "vkCreateImageView"))) orelse return error.FunctionNotFound;
    const vkCreateShaderModule = @as(c.PFN_vkCreateShaderModule, @ptrCast(vkGetDeviceProcAddr(device, "vkCreateShaderModule"))) orelse return error.FunctionNotFound;
    const vkCreatePipelineLayout = @as(c.PFN_vkCreatePipelineLayout, @ptrCast(vkGetDeviceProcAddr(device, "vkCreatePipelineLayout"))) orelse return error.FunctionNotFound;
    const vkCreateRenderPass = @as(c.PFN_vkCreateRenderPass, @ptrCast(vkGetDeviceProcAddr(device, "vkCreateRenderPass"))) orelse return error.FunctionNotFound;
    const vkCreateGraphicsPipelines = @as(c.PFN_vkCreateGraphicsPipelines, @ptrCast(vkGetDeviceProcAddr(device, "vkCreateGraphicsPipelines"))) orelse return error.FunctionNotFound;
    const vkCreateFramebuffer = @as(c.PFN_vkCreateFramebuffer, @ptrCast(vkGetDeviceProcAddr(device, "vkCreateFramebuffer"))) orelse return error.FunctionNotFound;
    const vkCreateCommandPool = @as(c.PFN_vkCreateCommandPool, @ptrCast(vkGetDeviceProcAddr(device, "vkCreateCommandPool"))) orelse return error.FunctionNotFound;
    const vkCreateSemaphore = @as(c.PFN_vkCreateSemaphore, @ptrCast(vkGetDeviceProcAddr(device, "vkCreateSemaphore"))) orelse return error.FunctionNotFound;
    const vkCreateFence = @as(c.PFN_vkCreateFence, @ptrCast(vkGetDeviceProcAddr(device, "vkCreateFence"))) orelse return error.FunctionNotFound;
    const vkCreateBuffer = @as(c.PFN_vkCreateBuffer, @ptrCast(vkGetDeviceProcAddr(device, "vkCreateBuffer"))) orelse return error.FunctionNotFound;
    const vkCreateSampler = @as(c.PFN_vkCreateSampler, @ptrCast(vkGetDeviceProcAddr(device, "vkCreateSampler"))) orelse return error.FunctionNotFound;
    const vkDestroySampler = @as(c.PFN_vkDestroySampler, @ptrCast(vkGetDeviceProcAddr(device, "vkDestroySampler"))) orelse return error.FunctionNotFound;
    const vkCreateDescriptorSetLayout = @as(c.PFN_vkCreateDescriptorSetLayout, @ptrCast(vkGetDeviceProcAddr(device, "vkCreateDescriptorSetLayout"))) orelse return error.FunctionNotFound;
    const vkDestroyCommandPool = @as(c.PFN_vkDestroyCommandPool, @ptrCast(vkGetDeviceProcAddr(device, "vkDestroyCommandPool"))) orelse return error.FunctionNotFound;
    const vkCreateDescriptorPool = @as(c.PFN_vkCreateDescriptorPool, @ptrCast(vkGetDeviceProcAddr(device, "vkCreateDescriptorPool"))) orelse return error.FunctionNotFound;
    const vkDestroyPipeline = @as(c.PFN_vkDestroyPipeline, @ptrCast(vkGetDeviceProcAddr(device, "vkDestroyPipeline"))) orelse return error.FunctionNotFound;
    const vkDestroyPipelineLayout = @as(c.PFN_vkDestroyPipelineLayout, @ptrCast(vkGetDeviceProcAddr(device, "vkDestroyPipelineLayout"))) orelse return error.FunctionNotFound;
    const vkDestroyRenderPass = @as(c.PFN_vkDestroyRenderPass, @ptrCast(vkGetDeviceProcAddr(device, "vkDestroyRenderPass"))) orelse return error.FunctionNotFound;
    const vkDestroySwapchainKHR = @as(c.PFN_vkDestroySwapchainKHR, @ptrCast(vkGetDeviceProcAddr(device, "vkDestroySwapchainKHR"))) orelse return error.FunctionNotFound;
    const vkDestroyImage = @as(c.PFN_vkDestroyImage, @ptrCast(vkGetDeviceProcAddr(device, "vkDestroyImage"))) orelse return error.FunctionNotFound;
    const vkDestroyImageView = @as(c.PFN_vkDestroyImageView, @ptrCast(vkGetDeviceProcAddr(device, "vkDestroyImageView"))) orelse return error.FunctionNotFound;
    const vkDestroyShaderModule = @as(c.PFN_vkDestroyShaderModule, @ptrCast(vkGetDeviceProcAddr(device, "vkDestroyShaderModule"))) orelse return error.FunctionNotFound;
    const vkDestroySemaphore = @as(c.PFN_vkDestroySemaphore, @ptrCast(vkGetDeviceProcAddr(device, "vkDestroySemaphore"))) orelse return error.FunctionNotFound;
    const vkDestroyFence = @as(c.PFN_vkDestroyFence, @ptrCast(vkGetDeviceProcAddr(device, "vkDestroyFence"))) orelse return error.FunctionNotFound;
    const vkDestroyFramebuffer = @as(c.PFN_vkDestroyFramebuffer, @ptrCast(vkGetDeviceProcAddr(device, "vkDestroyFramebuffer"))) orelse return error.FunctionNotFound;
    const vkDestroyBuffer = @as(c.PFN_vkDestroyBuffer, @ptrCast(vkGetDeviceProcAddr(device, "vkDestroyBuffer"))) orelse return error.FunctionNotFound;
    const vkDestroyDescriptorSetLayout = @as(c.PFN_vkDestroyDescriptorSetLayout, @ptrCast(vkGetDeviceProcAddr(device, "vkDestroyDescriptorSetLayout"))) orelse return error.FunctionNotFound;
    const vkDestroyDescriptorPool = @as(c.PFN_vkDestroyDescriptorPool, @ptrCast(vkGetDeviceProcAddr(device, "vkDestroyDescriptorPool"))) orelse return error.FunctionNotFound;
    const vkBeginCommandBuffer = @as(c.PFN_vkBeginCommandBuffer, @ptrCast(vkGetDeviceProcAddr(device, "vkBeginCommandBuffer"))) orelse return error.FunctionNotFound;
    const vkCmdBeginRenderPass = @as(c.PFN_vkCmdBeginRenderPass, @ptrCast(vkGetDeviceProcAddr(device, "vkCmdBeginRenderPass"))) orelse return error.FunctionNotFound;
    const vkCmdBindPipeline = @as(c.PFN_vkCmdBindPipeline, @ptrCast(vkGetDeviceProcAddr(device, "vkCmdBindPipeline"))) orelse return error.FunctionNotFound;
    const vkCmdBindVertexBuffers = @as(c.PFN_vkCmdBindVertexBuffers, @ptrCast(vkGetDeviceProcAddr(device, "vkCmdBindVertexBuffers"))) orelse return error.FunctionNotFound;
    const vkCmdBindIndexBuffer = @as(c.PFN_vkCmdBindIndexBuffer, @ptrCast(vkGetDeviceProcAddr(device, "vkCmdBindIndexBuffer"))) orelse return error.FunctionNotFound;
    const vkCmdSetViewport = @as(c.PFN_vkCmdSetViewport, @ptrCast(vkGetDeviceProcAddr(device, "vkCmdSetViewport"))) orelse return error.FunctionNotFound;
    const vkCmdSetScissor = @as(c.PFN_vkCmdSetScissor, @ptrCast(vkGetDeviceProcAddr(device, "vkCmdSetScissor"))) orelse return error.FunctionNotFound;
    const vkCmdDraw = @as(c.PFN_vkCmdDraw, @ptrCast(vkGetDeviceProcAddr(device, "vkCmdDraw"))) orelse return error.FunctionNotFound;
    const vkCmdDrawIndexed = @as(c.PFN_vkCmdDrawIndexed, @ptrCast(vkGetDeviceProcAddr(device, "vkCmdDrawIndexed"))) orelse return error.FunctionNotFound;
    const vkCmdCopyBuffer = @as(c.PFN_vkCmdCopyBuffer, @ptrCast(vkGetDeviceProcAddr(device, "vkCmdCopyBuffer"))) orelse return error.FunctionNotFound;
    const vkCmdCopyBufferToImage = @as(c.PFN_vkCmdCopyBufferToImage, @ptrCast(vkGetDeviceProcAddr(device, "vkCmdCopyBufferToImage"))) orelse return error.FunctionNotFound;
    const vkCmdPushConstants = @as(c.PFN_vkCmdPushConstants, @ptrCast(vkGetDeviceProcAddr(device, "vkCmdPushConstants"))) orelse return error.FunctionNotFound;
    const vkCmdPipelineBarrier = @as(c.PFN_vkCmdPipelineBarrier, @ptrCast(vkGetDeviceProcAddr(device, "vkCmdPipelineBarrier"))) orelse return error.FunctionNotFound;
    const vkUpdateDescriptorSets = @as(c.PFN_vkUpdateDescriptorSets, @ptrCast(vkGetDeviceProcAddr(device, "vkUpdateDescriptorSets"))) orelse return error.FunctionNotFound;
    const vkCmdBindDescriptorSets = @as(c.PFN_vkCmdBindDescriptorSets, @ptrCast(vkGetDeviceProcAddr(device, "vkCmdBindDescriptorSets"))) orelse return error.FunctionNotFound;
    const vkCmdEndRenderPass = @as(c.PFN_vkCmdEndRenderPass, @ptrCast(vkGetDeviceProcAddr(device, "vkCmdEndRenderPass"))) orelse return error.FunctionNotFound;
    const vkEndCommandBuffer = @as(c.PFN_vkEndCommandBuffer, @ptrCast(vkGetDeviceProcAddr(device, "vkEndCommandBuffer"))) orelse return error.FunctionNotFound;
    const vkResetCommandBuffer = @as(c.PFN_vkResetCommandBuffer, @ptrCast(vkGetDeviceProcAddr(device, "vkResetCommandBuffer"))) orelse return error.FunctionNotFound;
    const vkFreeMemory = @as(c.PFN_vkFreeMemory, @ptrCast(vkGetDeviceProcAddr(device, "vkFreeMemory"))) orelse return error.FunctionNotFound;
    const vkFreeCommandBuffers = @as(c.PFN_vkFreeCommandBuffers, @ptrCast(vkGetDeviceProcAddr(device, "vkFreeCommandBuffers"))) orelse return error.FunctionNotFound;
    const vkFreeDescriptorSets = @as(c.PFN_vkFreeDescriptorSets, @ptrCast(vkGetDeviceProcAddr(device, "vkFreeDescriptorSets"))) orelse return error.FunctionNotFound;
    const vkMapMemory = @as(c.PFN_vkMapMemory, @ptrCast(vkGetDeviceProcAddr(device, "vkMapMemory"))) orelse return error.FunctionNotFound;
    const vkUnmapMemory = @as(c.PFN_vkUnmapMemory, @ptrCast(vkGetDeviceProcAddr(device, "vkUnmapMemory"))) orelse return error.FunctionNotFound;
    const vkDestroyDevice = @as(c.PFN_vkDestroyDevice, @ptrCast(vkGetDeviceProcAddr(device, "vkDestroyDevice"))) orelse return error.FunctionNotFound;

    var queues: [4]c.VkQueue = undefined;
    for (0..4) |i| {
        vkGetDeviceQueue(device, families[i], 0, &queues[i]);
    }

    ARENA.deinit();

    return DeviceDispatch {
        .handle = device,
        .queues = queues,
        .families = families,
        .physical_device = physical_device,
        .vkGetDeviceQueue = vkGetDeviceQueue,
        .vkAllocateCommandBuffers = vkAllocateCommandBuffers,
        .vkAllocateMemory = vkAllocateMemory,
        .vkAllocateDescriptorSets = vkAllocateDescriptorSets,
        .vkQueueSubmit = vkQueueSubmit,
        .vkQueuePresentKHR = vkQueuePresentKHR,
        .vkQueueWaitIdle = vkQueueWaitIdle,
        .vkGetImageMemoryRequirements = vkGetImageMemoryRequirements,
        .vkGetSwapchainImagesKHR = vkGetSwapchainImagesKHR,
        .vkGetBufferMemoryRequirements = vkGetBufferMemoryRequirements,
        .vkBindBufferMemory = vkBindBufferMemory,
        .vkBindImageMemory = vkBindImageMemory,
        .vkAcquireNextImageKHR = vkAcquireNextImageKHR,
        .vkWaitForFences = vkWaitForFences,
        .vkResetFences = vkResetFences,
        .vkCreateSwapchainKHR = vkCreateSwapchainKHR,
        .vkCreateImage = vkCreateImage,
        .vkCreateShaderModule = vkCreateShaderModule,
        .vkCreatePipelineLayout = vkCreatePipelineLayout,
        .vkCreateImageView = vkCreateImageView,
        .vkCreateRenderPass = vkCreateRenderPass,
        .vkCreateGraphicsPipelines = vkCreateGraphicsPipelines,
        .vkCreateFramebuffer = vkCreateFramebuffer,
        .vkCreateCommandPool = vkCreateCommandPool,
        .vkCreateSemaphore = vkCreateSemaphore,
        .vkCreateFence = vkCreateFence,
        .vkCreateBuffer = vkCreateBuffer,
        .vkCreateSampler = vkCreateSampler,
        .vkCreateDescriptorSetLayout = vkCreateDescriptorSetLayout,
        .vkCreateDescriptorPool = vkCreateDescriptorPool,
        .vkDestroyCommandPool = vkDestroyCommandPool,
        .vkDestroyPipeline = vkDestroyPipeline,
        .vkDestroyPipelineLayout = vkDestroyPipelineLayout,
        .vkDestroyRenderPass = vkDestroyRenderPass,
        .vkDestroyImage = vkDestroyImage,
        .vkDestroyImageView = vkDestroyImageView,
        .vkDestroySwapchainKHR = vkDestroySwapchainKHR,
        .vkDestroyShaderModule = vkDestroyShaderModule,
        .vkDestroySemaphore = vkDestroySemaphore,
        .vkDestroyFence = vkDestroyFence,
        .vkDestroyFramebuffer = vkDestroyFramebuffer,
        .vkDestroyBuffer = vkDestroyBuffer,
        .vkDestroyDescriptorSetLayout = vkDestroyDescriptorSetLayout,
        .vkDestroyDescriptorPool = vkDestroyDescriptorPool,
        .vkBeginCommandBuffer = vkBeginCommandBuffer,
        .vkCmdBeginRenderPass = vkCmdBeginRenderPass,
        .vkCmdBindPipeline = vkCmdBindPipeline,
        .vkCmdBindVertexBuffers = vkCmdBindVertexBuffers,
        .vkCmdBindIndexBuffer = vkCmdBindIndexBuffer,
        .vkCmdSetViewport = vkCmdSetViewport,
        .vkCmdCopyBufferToImage = vkCmdCopyBufferToImage,
        .vkCmdSetScissor = vkCmdSetScissor,
        .vkCmdCopyBuffer = vkCmdCopyBuffer,
        .vkCmdDraw = vkCmdDraw,
        .vkCmdDrawIndexed = vkCmdDrawIndexed,
        .vkCmdPushConstants = vkCmdPushConstants,
        .vkCmdPipelineBarrier = vkCmdPipelineBarrier,
        .vkUpdateDescriptorSets = vkUpdateDescriptorSets,
        .vkCmdBindDescriptorSets = vkCmdBindDescriptorSets,
        .vkCmdEndRenderPass = vkCmdEndRenderPass,
        .vkEndCommandBuffer = vkEndCommandBuffer,
        .vkResetCommandBuffer = vkResetCommandBuffer,
        .vkFreeMemory = vkFreeMemory,
        .vkFreeCommandBuffers = vkFreeCommandBuffers,
        .vkFreeDescriptorSets = vkFreeDescriptorSets,
        .vkMapMemory = vkMapMemory,
        .vkUnmapMemory = vkUnmapMemory,
        .vkDestroyDevice = vkDestroyDevice,
        .vkDestroySampler = vkDestroySampler,
        .vkGetDeviceProcAddr = vkGetDeviceProcAddr,
    };
}

pub fn deinit_instance(instance: *const InstanceDispatch) void {
    instance.vkDestroySurfaceKHR(instance.handle, instance.surface, null);
    instance.vkDestroyInstance(instance.handle, null);
    _ = c.dlclose(instance.library);
}

pub fn deinit_device(device: *const DeviceDispatch) void {
    device.vkDestroyDevice(device.handle, null);
}
