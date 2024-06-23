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
    physical_device_properties: c.VkPhysicalDeviceMemoryProperties,
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

pub const GraphicsPipeline = struct {
    handle: c.VkPipeline,
    layout: c.VkPipelineLayout,
    render_pass: c.VkRenderPass,
    global_pool: c.VkDescriptorPool,
    global_layout: c.VkDescriptorSetLayout,
    texture_pool: c.VkDescriptorPool,
    texture_layout: c.VkDescriptorSetLayout,
    format: c.VkSurfaceFormatKHR,
};

const Swapchain = struct {
    handle: c.VkSwapchainKHR,
    images: []c.VkImage,
    image_views: []c.VkImageView,
    framebuffers: []c.VkFramebuffer,
    render_finished: c.VkSemaphore,
    image_available: c.VkSemaphore,
    extent: c.VkExtent2D,
    in_flight: c.VkFence,
};

const CommandPool = struct {
    handle: c.VkCommandPool,
    buffers: []c.VkCommandBuffer,
    allocator: std.mem.Allocator,
};

pub const Painter = struct {
    coords_buffer: Buffer,
    index_buffer: Buffer,
    uniform: Uniform,
    uniform_dst: []f32,
    texture: Image,
};

const Buffer = struct {
    handle: c.VkBuffer,
    memory: c.VkDeviceMemory,
};

const Image = struct {
    handle: c.VkImage,
    memory: c.VkDeviceMemory,
    view: c.VkImageView,
    sampler: c.VkSampler,
    set: c.VkDescriptorSet,
    width: u32,
    height: u32,
};

const Uniform = struct {
    set: c.VkDescriptorSet,
    buffer: Buffer,
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

    var properties: c.VkPhysicalDeviceMemoryProperties = undefined;
    instance_dispatch.vkGetPhysicalDeviceMemoryProperties(physical_device, &properties);

    return DeviceDispatch {
        .handle = device,
        .queues = queues,
        .families = families,
        .physical_device = physical_device,
        .physical_device_properties = properties,
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

fn read_file(path: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const end_pos = try file.getEndPos();
    const content = try ALLOCATOR.alloc(u8, end_pos);
    if (try file.read(content) < end_pos) return error.IncompleteContetent;

    return content;
}

fn create_shader_module(device_dispatch: *const DeviceDispatch, path: []const u8) c.VkShaderModule {
    const code = read_file(path) catch blk: {
        std.debug.print("could not read file content", .{});
        break :blk "";
    };
    const info = c.VkShaderModuleCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
        .codeSize = code.len,
        .pCode = @as([*]const u32, @ptrCast(@alignCast(code))),
    };

    var shader_module: c.VkShaderModule = undefined;
    if (0 != device_dispatch.vkCreateShaderModule(device_dispatch.handle, &info, null, &shader_module)) {
        std.debug.print("could not create shader module", .{});
    }

    return shader_module;
}

pub fn graphics_pipeline_init(
    instance_dispatch: *const InstanceDispatch,
    device_dispatch: *const DeviceDispatch,
) !GraphicsPipeline {
    const vert_module = create_shader_module(device_dispatch, "assets/shader/vert.spv");
    defer device_dispatch.vkDestroyShaderModule(device_dispatch.handle, vert_module, null);

    const frag_module = create_shader_module(device_dispatch, "assets/shader/frag.spv");
    defer device_dispatch.vkDestroyShaderModule(device_dispatch.handle, frag_module, null);

    const name = "main";

    const shader_stage_infos = &[_]c.VkPipelineShaderStageCreateInfo {
        .{
            .sType = c.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
            .stage = c.VK_SHADER_STAGE_VERTEX_BIT,
            .pName = name,
            .module = vert_module,
        },
        .{
            .sType = c.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
            .stage = c.VK_SHADER_STAGE_FRAGMENT_BIT,
            .pName = name,
            .module = frag_module,
        },
    };

    const dynamic_states = &[_]c.VkDynamicState { c.VK_DYNAMIC_STATE_VIEWPORT, c.VK_DYNAMIC_STATE_SCISSOR };
    const dynamic_state_info = c.VkPipelineDynamicStateCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO,
        .pDynamicStates = dynamic_states.ptr,
        .dynamicStateCount = dynamic_states.len,
    };

    const vertex_binding_description = c.VkVertexInputBindingDescription {
        .binding = 0,
        .stride = @sizeOf(f32) * 2,
        .inputRate = c.VK_VERTEX_INPUT_RATE_VERTEX,
    };

    const vertex_attribute_description = c.VkVertexInputAttributeDescription {
        .binding = 0,
        .location = 0,
        .format = c.VK_FORMAT_R32_SFLOAT,
        .offset = 0,
    };

    const vertex_input_state_info = c.VkPipelineVertexInputStateCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
        .pVertexBindingDescriptions = &vertex_binding_description,
        .vertexBindingDescriptionCount = 1,
        .pVertexAttributeDescriptions = &vertex_attribute_description,
        .vertexAttributeDescriptionCount = 1,
    };

    const input_assembly_state_info = c.VkPipelineInputAssemblyStateCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
        .topology = c.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
        .primitiveRestartEnable = c.VK_FALSE,
    };

    const viewport = c.VkViewport {
        .x = 0.0,
        .y = 0.0,
        .width = 1920.0,
        .height = 1080.0,
        .minDepth = 0.0,
        .maxDepth = 1.0,
    };

    const scissor = c.VkRect2D {
        .offset = c.VkOffset2D {
            .x = 0,
            .y = 0,
        },
        .extent = c.VkExtent2D {
            .width = 1920,
            .height = 1080,
        }
    };

    const viewport_state_info = c.VkPipelineViewportStateCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO,
        .viewportCount = 1,
        .pViewports = &viewport,
        .scissorCount = 1,
        .pScissors = &scissor
    };

    const rasterize_state_info = c.VkPipelineRasterizationStateCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
        .cullMode = c.VK_CULL_MODE_BACK_BIT,
        .frontFace = c.VK_FRONT_FACE_CLOCKWISE,
        .polygonMode = c.VK_POLYGON_MODE_FILL,
        .depthBiasEnable = c.VK_FALSE,
        .depthClampEnable = c.VK_FALSE,
        .rasterizerDiscardEnable = c.VK_FALSE,
        .lineWidth = 1.0,
        .depthBiasClamp = 0.0,
        .depthBiasConstantFactor = 0.0,
    };

    const multisampling_state_info = c.VkPipelineMultisampleStateCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
        .pSampleMask = null,
        .alphaToOneEnable = c.VK_FALSE,
        .sampleShadingEnable = c.VK_FALSE,
        .rasterizationSamples = c.VK_SAMPLE_COUNT_1_BIT,
        .alphaToCoverageEnable = c.VK_FALSE,
        .minSampleShading = 1.0,
    };

    const color_blend_attachment = c.VkPipelineColorBlendAttachmentState {
        .blendEnable = c.VK_TRUE,
        .colorWriteMask = c.VK_COLOR_COMPONENT_R_BIT | c.VK_COLOR_COMPONENT_G_BIT | c.VK_COLOR_COMPONENT_B_BIT | c.VK_COLOR_COMPONENT_A_BIT,
        .srcColorBlendFactor = c.VK_BLEND_FACTOR_ONE,
        .dstColorBlendFactor = c.VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
        .srcAlphaBlendFactor = c.VK_BLEND_FACTOR_ONE,
        .dstAlphaBlendFactor = c.VK_BLEND_FACTOR_ZERO,
        .colorBlendOp = c.VK_BLEND_OP_ADD,
        .alphaBlendOp = c.VK_BLEND_OP_ADD,
    };

    const color_blend_state_info = c.VkPipelineColorBlendStateCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
        .logicOp = c.VK_LOGIC_OP_COPY,
        .logicOpEnable = c.VK_FALSE,
        .blendConstants = .{ 0.0, 0.0, 0.0, 0.0 },
        .attachmentCount = 1,
        .pAttachments = &color_blend_attachment,
    };

    const depth_stencil_state_info = c.VkPipelineDepthStencilStateCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO,
        .maxDepthBounds = 1.0,
        .minDepthBounds = 0.0,
        .depthCompareOp = c.VK_COMPARE_OP_LESS,
        .depthTestEnable = c.VK_FALSE,
        .depthWriteEnable = c.VK_FALSE,
        .stencilTestEnable = c.VK_FALSE,
        .depthBoundsTestEnable = c.VK_FALSE,
    };

    const global_binding = c.VkDescriptorSetLayoutBinding {
        .binding = 0,
        .stageFlags = c.VK_SHADER_STAGE_VERTEX_BIT,
        .descriptorType = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
        .descriptorCount = 1,
    };

    const global_layout_info = c.VkDescriptorSetLayoutCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
        .bindingCount = 1,
        .pBindings = &global_binding,
    };

    var global_descriptor_set_layout: c.VkDescriptorSetLayout = undefined;
    _ = device_dispatch.vkCreateDescriptorSetLayout(device_dispatch.handle, &global_layout_info, null, &global_descriptor_set_layout);

    const texture_binding = c.VkDescriptorSetLayoutBinding {
        .binding = 0,
        .stageFlags = c.VK_SHADER_STAGE_FRAGMENT_BIT,
        .descriptorType = c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
        .descriptorCount = 1,
    };

    const texture_layout_info = c.VkDescriptorSetLayoutCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
        .bindingCount = 1,
        .pBindings = &texture_binding,
    };

    var texture_descriptor_set_layout: c.VkDescriptorSetLayout = undefined;
    _ = device_dispatch.vkCreateDescriptorSetLayout(device_dispatch.handle, &texture_layout_info, null, &texture_descriptor_set_layout);

    const push_constant = c.VkPushConstantRange {
        .stageFlags = c.VK_SHADER_STAGE_VERTEX_BIT,
        .offset = 0,
        .size = @sizeOf(f32) * 2,
    };

    const set_layouts = [_]c.VkDescriptorSetLayout {global_descriptor_set_layout, texture_descriptor_set_layout };
    const layout_info = c.VkPipelineLayoutCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
        .pushConstantRangeCount = 1,
        .pPushConstantRanges = &push_constant,
        .setLayoutCount = set_layouts.len,
        .pSetLayouts = &set_layouts,
    };

    var layout: c.VkPipelineLayout = undefined;
    _ = device_dispatch.vkCreatePipelineLayout(device_dispatch.handle, &layout_info, null, &layout);

    const global_pool_size = c.VkDescriptorPoolSize {
        .type = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
        .descriptorCount = 16,
    };

    const global_pool_info = c.VkDescriptorPoolCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
        .poolSizeCount = 1,
        .pPoolSizes = &global_pool_size,
        .maxSets = 16,
    };

    var global_descriptor_pool: c.VkDescriptorPool = undefined;
    _ = device_dispatch.vkCreateDescriptorPool(device_dispatch.handle, &global_pool_info, null, &global_descriptor_pool);

    const texture_pool_size = c.VkDescriptorPoolSize {
        .type = c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
        .descriptorCount = 16,
    };

    const texture_pool_info = c.VkDescriptorPoolCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
        .poolSizeCount = 1,
        .pPoolSizes = &texture_pool_size,
        .maxSets = 16,
    };

    var texture_descriptor_pool: c.VkDescriptorPool = undefined;
    _ = device_dispatch.vkCreateDescriptorPool(device_dispatch.handle, &texture_pool_info, null, &texture_descriptor_pool);

    const format = blk: {
        var count: u32 = 0;
        _ = instance_dispatch.vkGetPhysicalDeviceSurfaceFormatsKHR(device_dispatch.physical_device, instance_dispatch.surface, &count, null);
        const formats = try ALLOCATOR.alloc(c.VkSurfaceFormatKHR, count);
        _ = instance_dispatch.vkGetPhysicalDeviceSurfaceFormatsKHR(device_dispatch.physical_device, instance_dispatch.surface, &count, formats.ptr);

        const format = for (formats) |format| {
            if (format.format == c.VK_FORMAT_R8G8B8A8_SRGB and format.colorSpace == c.VK_COLOR_SPACE_SRGB_NONLINEAR_KHR) break format;
        } else formats[0];

        break :blk format;
    };

    const render_pass_attachment = c.VkAttachmentDescription {
        .format = format.format,
        .samples = c.VK_SAMPLE_COUNT_1_BIT,
        .loadOp = c.VK_ATTACHMENT_LOAD_OP_CLEAR,
        .storeOp = c.VK_ATTACHMENT_STORE_OP_STORE,
        .finalLayout = c.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
        .initialLayout = c.VK_IMAGE_LAYOUT_UNDEFINED,
        .stencilLoadOp = c.VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        .stencilStoreOp = c.VK_ATTACHMENT_STORE_OP_DONT_CARE,
    };

    const subpass = c.VkSubpassDescription {
        .pipelineBindPoint = c.VK_PIPELINE_BIND_POINT_GRAPHICS,
        .colorAttachmentCount = 1,
        .pColorAttachments = &.{
            .attachment = 0,
            .layout = c.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
        },
    };

    const dependency = c.VkSubpassDependency {
        .srcSubpass = c.VK_SUBPASS_EXTERNAL,
        .dstSubpass = 0,
        .srcAccessMask = 0,
        .dstAccessMask = c.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT | c.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT,
        .srcStageMask = c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT | c.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT,
        .dstStageMask = c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT | c.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT,
    };

    const render_pass_info = c.VkRenderPassCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO,
        .attachmentCount = 1,
        .pAttachments = &render_pass_attachment,
        .subpassCount = 1,
        .pSubpasses = &subpass,
        .dependencyCount = 1,
        .pDependencies = &dependency,
    };

    var render_pass: c.VkRenderPass = undefined;
    _ = device_dispatch.vkCreateRenderPass(device_dispatch.handle, &render_pass_info, null, &render_pass);

    const graphics_pipeline_info = c.VkGraphicsPipelineCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
        .stageCount = shader_stage_infos.len,
        .pStages = shader_stage_infos.ptr,
        .pVertexInputState = &vertex_input_state_info,
        .pInputAssemblyState = &input_assembly_state_info,
        .pViewportState = &viewport_state_info,
        .pRasterizationState = &rasterize_state_info,
        .pMultisampleState = &multisampling_state_info,
        .pDepthStencilState = &depth_stencil_state_info,
        .pColorBlendState = &color_blend_state_info,
        .pDynamicState = &dynamic_state_info,
        .layout = layout,
        .renderPass = render_pass,
    };

    var graphics_pipeline: c.VkPipeline = undefined;
    _ = device_dispatch.vkCreateGraphicsPipelines(device_dispatch.handle, null, 1, &graphics_pipeline_info, null, &graphics_pipeline);

    return .{
        .handle = graphics_pipeline,
        .layout = layout,
        .render_pass = render_pass,
        .global_pool = global_descriptor_pool,
        .global_layout = global_descriptor_set_layout,
        .texture_pool = texture_descriptor_pool,
        .texture_layout = texture_descriptor_set_layout,
        .format = format,
    };
}

pub fn swapchain_init(
    instance_dispatch: *const InstanceDispatch,
    device_dispatch: *const DeviceDispatch,
    graphics_pipeline: *const GraphicsPipeline,
    allocator: std.mem.Allocator,
) !Swapchain {
    const width = 1920;
    const height = 1080;

    const extent = c.VkExtent2D {
        .width = width,
        .height = height,
    };

    const present_mode = c.VK_PRESENT_MODE_FIFO_KHR;
    var capabilities: c.VkSurfaceCapabilitiesKHR = undefined;
    _ = instance_dispatch.vkGetPhysicalDeviceSurfaceCapabilitiesKHR(device_dispatch.physical_device, instance_dispatch.surface, &capabilities);

    const image_count = if (capabilities.maxImageCount > 0) @min(capabilities.minImageCount + 1, capabilities.maxImageCount)
  else capabilities.minImageCount + 1;

    var unique_families: [4]u32 = undefined;
    var family_count: u32 = 0;
    {
        var last_value: u32 = 255;
        for (device_dispatch.families) |family| {
            if (family != last_value) {
                unique_families[family_count] = family;
                last_value = family;
                family_count += 1;
            }
        }
    }

    const info = c.VkSwapchainCreateInfoKHR {
        .sType = c.VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
        .surface = instance_dispatch.surface,
        .minImageCount = image_count,
        .imageFormat = graphics_pipeline.format.format,
        .imageColorSpace = graphics_pipeline.format.colorSpace,
        .imageExtent = extent,
        .imageSharingMode = if (family_count > 1) c.VK_SHARING_MODE_CONCURRENT else c.VK_SHARING_MODE_EXCLUSIVE,
        .presentMode = present_mode,
        .preTransform = capabilities.currentTransform,
        .clipped = c.VK_TRUE,
        .imageArrayLayers = 1,
        .compositeAlpha = c.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
        .imageUsage = c.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
        .queueFamilyIndexCount = family_count,
        .pQueueFamilyIndices = &unique_families[0],
    };

    var swapchain: c.VkSwapchainKHR = undefined;
    _ = device_dispatch.vkCreateSwapchainKHR(device_dispatch.handle, &info, null, &swapchain);

    var count: u32 = 0;

    _ = device_dispatch.vkGetSwapchainImagesKHR(device_dispatch.handle, swapchain, &count, null);
    const images = try allocator.alloc(c.VkImage, count);
    _ = device_dispatch.vkGetSwapchainImagesKHR(device_dispatch.handle, swapchain, &count, images.ptr);

    const image_views = try allocator.alloc(c.VkImageView, count);
    const framebuffers = try allocator.alloc(c.VkFramebuffer, count);
    for (0..count) |i| {
        image_views[i] = create_image_view(device_dispatch, images[i], graphics_pipeline.format.format);

        const framebuffer_info = c.VkFramebufferCreateInfo {
            .sType = c.VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO,
            .renderPass = graphics_pipeline.render_pass,
            .attachmentCount = 1,
            .pAttachments = &image_views[i],
            .width = extent.width,
            .height = extent.height,
            .layers = 1,
        };

        var framebuffer: c.VkFramebuffer = undefined;
        _ = device_dispatch.vkCreateFramebuffer(device_dispatch.handle, &framebuffer_info, null, &framebuffer);
        framebuffers[i] = framebuffer;
    }

    const semaphore_info = c.VkSemaphoreCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
    };

    const fence_info = c.VkFenceCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
        .flags = c.VK_FENCE_CREATE_SIGNALED_BIT,
    };

    var render_finished: c.VkSemaphore = undefined;
    var image_available: c.VkSemaphore = undefined;
    var in_flight: c.VkFence = undefined;

    _ = device_dispatch.vkCreateSemaphore(device_dispatch.handle, &semaphore_info, null, &render_finished);
    _ = device_dispatch.vkCreateSemaphore(device_dispatch.handle, &semaphore_info, null, &image_available);
    _ = device_dispatch.vkCreateFence(device_dispatch.handle, &fence_info, null, &in_flight);

    return .{
        .handle = swapchain,
        .images = images,
        .image_views = image_views,
        .framebuffers = framebuffers,
        .render_finished = render_finished,
        .image_available = image_available,
        .extent = extent,
        .in_flight = in_flight,
    };
}

pub fn command_pool_init(
    device: *const DeviceDispatch,
    swapchain: *const Swapchain,
    allocator: std.mem.Allocator,
) !CommandPool {
    const info = c.VkCommandPoolCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
        .flags = c.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
        .queueFamilyIndex = device.families[0],
    };

    var handle: c.VkCommandPool = undefined;
    _ = device.vkCreateCommandPool(device.handle, &info, null, &handle);

    const count = swapchain.framebuffers.len;
    const buffers = try allocator.alloc(c.VkCommandBuffer, count);

    {
        const buffers_info = c.VkCommandBufferAllocateInfo {
            .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
            .commandPool = handle,
            .level = c.VK_COMMAND_BUFFER_LEVEL_PRIMARY,
            .commandBufferCount = @intCast(count),
        };

        _ = device.vkAllocateCommandBuffers(device.handle, &buffers_info, &buffers[0]);
    }

    return .{
        .buffers = buffers,
        .handle = handle,
        .allocator = allocator,
    };
}

pub fn painter_init(
    device: *const DeviceDispatch,
    graphics_pipeline: *const GraphicsPipeline,
    command_pool: *const CommandPool
) Painter {
    const uniform_data = [_]f32 { 1.0, 1.0, -1.0, -1.0, 1.0 };
    const global_uniform = uniform_buffer_init(f32, device, &uniform_data, graphics_pipeline.global_pool, graphics_pipeline.global_layout, 0);

    const coords = [4][2]f32 { .{ 0.0, 0.0 }, .{ 1.0, 0.0 }, .{ 0.0, 1.0 }, .{ 1.0, 1.0 }, };
    const coords_buffer = buffer_init([2]f32, device, c.VK_BUFFER_USAGE_TRANSFER_DST_BIT | c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT, c.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, 4);
    copy_data_to_buffer([2]f32, device, &coords, &coords_buffer, command_pool);

    const indices = [_]u16 { 0, 1, 2, 1, 3, 2 };
    const index_buffer = buffer_init(u16, device, c.VK_BUFFER_USAGE_TRANSFER_DST_BIT | c.VK_BUFFER_USAGE_INDEX_BUFFER_BIT, c.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, indices.len);
    copy_data_to_buffer(u16, device, &indices, &index_buffer, command_pool);

    const image_data: [512]u8 = undefined;
    const texture_image = image_init(
        device,
        graphics_pipeline,
        c.VK_FORMAT_R8_UNORM,
        c.VK_IMAGE_USAGE_TRANSFER_DST_BIT | c.VK_IMAGE_USAGE_SAMPLED_BIT,
        16, 16
    );
    copy_data_to_image(device, &texture_image, &image_data, command_pool);

    return .{
        .uniform = global_uniform.handle,
        .uniform_dst = global_uniform.dst,
        .coords_buffer = coords_buffer,
        .index_buffer = index_buffer,
        .texture = texture_image
    };
}

fn image_init(
    device: *const DeviceDispatch,
    graphics_pipeline: *const GraphicsPipeline,
    format: u32,
    usage: u32,
    width: u32,
    height: u32
) Image {
    const info = c.VkImageCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
        .imageType = c.VK_IMAGE_TYPE_2D,
        .mipLevels = 1,
        .arrayLayers = 1,
        .tiling = c.VK_IMAGE_TILING_OPTIMAL,
        .initialLayout = c.VK_IMAGE_LAYOUT_UNDEFINED,
        .sharingMode = c.VK_SHARING_MODE_EXCLUSIVE,
        .samples = c.VK_SAMPLE_COUNT_1_BIT,

        .usage = usage,
        .format = format,
        .extent = c.VkExtent3D {
            .width = width,
            .height = height,
            .depth = 1,
        },
    };

    var image: c.VkImage = undefined;
    _ = device.vkCreateImage(device.handle, &info, null, &image);

    var memory_requirements: c.VkMemoryRequirements = undefined;
    device.vkGetImageMemoryRequirements(device.handle, image, &memory_requirements);

    const image_memory = allocate_device_memory(device, c.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, &memory_requirements);
    _ = device.vkBindImageMemory(device.handle, image, image_memory, 0);

    const image_view = create_image_view(device, image, format);

    const sampler = sampler_init(device);
    const set = allocate_descriptor_set(device, graphics_pipeline.texture_pool, graphics_pipeline.texture_layout);
    update_image_descriptor_set(device, image_view, sampler, set);

    return .{
        .handle = image,
        .memory = image_memory,
        .view = image_view,
        .sampler = sampler,
        .set = set,
        .width = width,
        .height = height,
    };
}

fn update_image_descriptor_set(
    device: *const DeviceDispatch,
    view: c.VkImageView,
    sampler: c.VkSampler,
    set: c.VkDescriptorSet
) void {
    const info = c.VkDescriptorImageInfo {
        .imageLayout = c.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        .imageView = view,
        .sampler = sampler,
    };

    const write = c.VkWriteDescriptorSet {
        .sType = c.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
        .dstSet = set,
        .dstBinding = 0,
        .descriptorCount = 1,
        .descriptorType = c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
        .pImageInfo = &info,
    };

    device.vkUpdateDescriptorSets(device.handle, 1, &.{ write }, 0, null);
}

fn sampler_init(device: *const DeviceDispatch) c.VkSampler {
    const info = c.VkSamplerCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO,
        .magFilter = c.VK_FILTER_LINEAR,
        .minFilter = c.VK_FILTER_LINEAR,
        .addressModeU = c.VK_SAMPLER_ADDRESS_MODE_REPEAT,
        .addressModeV = c.VK_SAMPLER_ADDRESS_MODE_REPEAT,
        .addressModeW = c.VK_SAMPLER_ADDRESS_MODE_REPEAT,
        .anisotropyEnable = c.VK_FALSE,
        .maxAnisotropy = 1.0,
        .borderColor = c.VK_BORDER_COLOR_INT_OPAQUE_BLACK,
        .unnormalizedCoordinates = c.VK_FALSE,
        .compareEnable = c.VK_FALSE,
        .compareOp = c.VK_COMPARE_OP_ALWAYS,
        .mipmapMode = c.VK_SAMPLER_MIPMAP_MODE_LINEAR,
        .mipLodBias = 0.0,
        .minLod = 0.0,
        .maxLod = 0.0,
    };

    var handle: c.VkSampler = undefined;
    _ = device.vkCreateSampler(device.handle, &info, null, &handle);

    return handle;
}

pub fn sync(device: *const DeviceDispatch, swapchain: *const Swapchain) void {
    _ = device.vkWaitForFences(device.handle, 1, &swapchain.in_flight, c.VK_TRUE, 0xFFFFFF);
}

pub fn draw_frame(
    device: *const DeviceDispatch,
    swapchain: *const Swapchain,
    command_pool: *const CommandPool,
    graphics_pipeline: *const GraphicsPipeline,
    painter: *const Painter,
) void {
    var image_index: u32 = 0;
    _ = device.vkAcquireNextImageKHR(device.handle, swapchain.handle, 0xFFFFFF, swapchain.image_available, null, &image_index);

    record_draw_command(
        device,
        graphics_pipeline,
        command_pool,
        swapchain,
        painter,
        image_index,
    );

    const wait_dst_stage: u32 = c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;

    _ = device.vkResetFences(device.handle, 1, &swapchain.in_flight);
    const submit_info = c.VkSubmitInfo {
        .sType = c.VK_STRUCTURE_TYPE_SUBMIT_INFO,
        .waitSemaphoreCount = 1,
        .pWaitSemaphores = &swapchain.image_available,
        .pWaitDstStageMask = &wait_dst_stage,
        .commandBufferCount = 1,
        .pCommandBuffers = &command_pool.buffers[image_index],
        .signalSemaphoreCount = 1,
        .pSignalSemaphores = &swapchain.render_finished,
    };

    _ = device.vkQueueSubmit(device.queues[0], 1, &submit_info, swapchain.in_flight);

    const present_info = c.VkPresentInfoKHR {
        .sType = c.VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
        .swapchainCount = 1,
        .pSwapchains = &swapchain.handle,
        .waitSemaphoreCount = 1,
        .pWaitSemaphores = &swapchain.render_finished,
        .pImageIndices = &image_index,
    };

    _ = device.vkQueuePresentKHR(device.queues[1], &present_info);
}

fn record_draw_command(
    device: *const DeviceDispatch,
    graphics_pipeline: *const GraphicsPipeline,
    command_pool: *const CommandPool,
    swapchain: *const Swapchain,
    painter: *const Painter,
    index: u32,
) void {
    const command_buffer = command_pool.buffers[index];
    const framebuffer = swapchain.framebuffers[index];

    const begin_info = c.VkCommandBufferBeginInfo {
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
    };

    const clear_value = c.VkClearValue {
        .color = .{
            .float32 = .{ 0.0, 0.0, 0.0, 1.0 },
        },
    };

    const width = swapchain.extent.width;
    const height = swapchain.extent.height;

    const render_pass_info = c.VkRenderPassBeginInfo {
        .sType = c.VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO,
        .renderPass = graphics_pipeline.render_pass,
        .framebuffer = framebuffer,
        .renderArea = c.VkRect2D {
            .offset = c.VkOffset2D {
                .x = 0,
                .y = 0,
            },
            .extent = c.VkExtent2D {
                .width = width,
                .height = height,
            },
        },
        .pClearValues = &clear_value,
        .clearValueCount = 1,
    };

    const viewport = c.VkViewport {
        .x = 0.0,
        .y = 0.0,
        .width = @floatFromInt(width),
        .height = @floatFromInt(height),
        .minDepth = 0.0,
        .maxDepth = 1.0,
    };

    const scissor = c.VkRect2D {
        .offset = c.VkOffset2D {
            .x = 0,
            .y = 0,
        },
        .extent = c.VkExtent2D {
            .width = width,
            .height = height,
        },
    };
    const push_constant = [_]f32 { 0.0, 0.0 };

    _ = device.vkBeginCommandBuffer(command_buffer, &begin_info);
    device.vkCmdBeginRenderPass(command_buffer, &render_pass_info, c.VK_SUBPASS_CONTENTS_INLINE);
    device.vkCmdSetViewport(command_buffer, 0, 1, &viewport);
    device.vkCmdSetScissor(command_buffer, 0, 1, &scissor);
    device.vkCmdBindPipeline(command_buffer, c.VK_PIPELINE_BIND_POINT_GRAPHICS, graphics_pipeline.handle);
    device.vkCmdBindDescriptorSets(command_buffer, c.VK_PIPELINE_BIND_POINT_GRAPHICS, graphics_pipeline.layout, 0, 2, &.{ painter.uniform.set, painter.texture.set }, 0, &0);
    device.vkCmdPushConstants(command_buffer, graphics_pipeline.layout, c.VK_SHADER_STAGE_VERTEX_BIT, 0, @sizeOf(f32) * 2, @ptrCast(&push_constant));
    device.vkCmdBindVertexBuffers(command_buffer, 0, 1, &painter.coords_buffer.handle, &0);
    device.vkCmdBindIndexBuffer(command_buffer, painter.index_buffer.handle, 0, c.VK_INDEX_TYPE_UINT16);
    device.vkCmdDrawIndexed(command_buffer, 4, 1, 0, 0, 0);
    device.vkCmdEndRenderPass(command_buffer);
    _ = device.vkEndCommandBuffer(command_buffer);
}

fn create_image_view(device: *const DeviceDispatch, image: c.VkImage, format: u32) c.VkImageView {
    const sub = c.VkImageSubresourceRange {
        .aspectMask = c.VK_IMAGE_ASPECT_COLOR_BIT,
        .baseMipLevel = 0,
        .levelCount = 1,
        .baseArrayLayer = 0,
        .layerCount = 1,
    };

    const comp = c.VkComponentMapping {
        .r = c.VK_COMPONENT_SWIZZLE_IDENTITY,
        .g = c.VK_COMPONENT_SWIZZLE_IDENTITY,
        .b = c.VK_COMPONENT_SWIZZLE_IDENTITY,
        .a = c.VK_COMPONENT_SWIZZLE_IDENTITY,
    };

    const info = c.VkImageViewCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
        .viewType = c.VK_IMAGE_VIEW_TYPE_2D,
        .subresourceRange = sub,
        .components = comp,

        .image = image,
        .format = format,
    };

    var image_view: c.VkImageView = undefined;
    _ = device.vkCreateImageView(device.handle, &info, null, &image_view);

    return image_view;
}

fn copy_data_to_image(device: *const DeviceDispatch, image: *const Image, data: []const u8, command_pool: *const CommandPool) void {
    var dst: []u8 = undefined;
    const len: u32 = @intCast(data.len);

    const buffer = buffer_init(u8, device, c.VK_BUFFER_USAGE_TRANSFER_SRC_BIT, c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, len);
    _ = device.vkMapMemory(device.handle, buffer.memory, 0, len, 0, @ptrCast(&dst));

    for (0..len) |i| {
        dst[i] = data[i];
    }

    _ = device.vkUnmapMemory(device.handle, buffer.memory);
    const sub = c.VkImageSubresourceRange {
        .aspectMask = c.VK_IMAGE_ASPECT_COLOR_BIT,
        .baseMipLevel = 0,
        .levelCount = 1,
        .layerCount = 1,
        .baseArrayLayer = 0,
    };

    const barrier = c.VkImageMemoryBarrier {
        .sType = c.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
        .oldLayout = c.VK_IMAGE_LAYOUT_UNDEFINED,
        .newLayout = c.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
        .srcQueueFamilyIndex = c.VK_QUEUE_FAMILY_IGNORED,
        .dstQueueFamilyIndex = c.VK_QUEUE_FAMILY_IGNORED,
        .image = image.handle,
        .subresourceRange = sub,
        .srcAccessMask = 0,
        .dstAccessMask = c.VK_ACCESS_TRANSFER_WRITE_BIT,
    };

    const command_buffer = begin_command_buffer(device, command_pool);
    device.vkCmdPipelineBarrier(command_buffer, c.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, c.VK_PIPELINE_STAGE_TRANSFER_BIT, 0, 0, null, 0, null, 1, &barrier);

    const image_sub = c.VkImageSubresourceLayers {
        .aspectMask = c.VK_IMAGE_ASPECT_COLOR_BIT,
        .mipLevel = 0,
        .baseArrayLayer = 0,
        .layerCount = 1,
    };

    const offset = c.VkOffset3D {
        .x = 0, .y = 0, .z = 0,
    };

    const extent = c.VkExtent3D {
        .width = image.width,
        .height = image.height,
        .depth = 1,
    };

    const region = c.VkBufferImageCopy {
        .bufferOffset = 0,
        .bufferRowLength = 0,
        .bufferImageHeight = 0,
        .imageSubresource = image_sub,
        .imageOffset = offset,
        .imageExtent = extent,
    };

    device.vkCmdCopyBufferToImage(command_buffer, buffer.handle, image.handle, c.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, &region);

    const second_barrier = c.VkImageMemoryBarrier {
        .sType = c.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
        .oldLayout = c.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
        .newLayout = c.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        .srcQueueFamilyIndex = c.VK_QUEUE_FAMILY_IGNORED,
        .dstQueueFamilyIndex = c.VK_QUEUE_FAMILY_IGNORED,
        .image = image.handle,
        .subresourceRange = sub,
        .srcAccessMask = c.VK_ACCESS_TRANSFER_WRITE_BIT,
        .dstAccessMask = c.VK_ACCESS_SHADER_READ_BIT,
    };

    device.vkCmdPipelineBarrier(command_buffer, c.VK_PIPELINE_STAGE_TRANSFER_BIT, c.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, 0, 0, null, 0, null, 1, &second_barrier);

    end_command_buffer(device, command_pool, command_buffer);
    deinit_buffer(device, &buffer);
}

fn allocate_device_memory(device: *const DeviceDispatch, properties: u32, memory_requirements: *const c.VkMemoryRequirements) c.VkDeviceMemory {
    var index: u32 = 0;

    for (0..device.physical_device_properties.memoryTypeCount) |i| {
        const a: u5 = @intCast(i);
        const b: u32 = 1;

        if ((memory_requirements.memoryTypeBits & (b << a)) > 0 and (device.physical_device_properties.memoryTypes[i].propertyFlags & properties) == properties) {
            index = @intCast(i);
            break;
        }
    }

    const alloc_info = c.VkMemoryAllocateInfo {
        .sType = c.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
        .allocationSize = memory_requirements.size,
        .memoryTypeIndex = index,
    };

    var memory: c.VkDeviceMemory = undefined;
    _ = device.vkAllocateMemory(device.handle, &alloc_info, null, &memory);

    return memory;
}

fn uniform_buffer_init(
    T: type,
    device: *const DeviceDispatch,
    data: []const T,
    pool: c.VkDescriptorPool,
    layout: c.VkDescriptorSetLayout,
    binding: u32,
) struct {
    dst: []T,
    handle: Uniform
} {
    const len: u32 = @intCast(data.len);

    var dst: []T = undefined;
    const buffer = buffer_init(T, device, c.VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT, c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, len);

    _ = device.vkMapMemory(device.handle, buffer.memory, 0, len, 0, @ptrCast(&dst));

    for (0..len) |i| {
        dst[i] = data[i];
    }

    const info = c.VkDescriptorBufferInfo {
        .buffer = buffer.handle,
        .offset = 0,
        .range = @sizeOf(T) * len,
    };

    const descriptor_set = allocate_descriptor_set(device, pool, layout);
    const write = c.VkWriteDescriptorSet {
        .sType = c.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
        .dstSet = descriptor_set,
        .dstBinding = binding,
        .dstArrayElement = 0,
        .descriptorType = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
        .pBufferInfo = &info,
        .descriptorCount = 1,
    };

    device.vkUpdateDescriptorSets(device.handle, 1, &.{ write }, 0, null);

    return .{
        .dst = dst,
        .handle = .{
            .buffer = buffer,
            .set = descriptor_set,
        },
    };
}

fn copy_data_to_buffer(T: type, device: *const DeviceDispatch, data: []const T, buffer: *const Buffer, command_pool: *const CommandPool) void {
    var dst: []T = undefined;
    const len: u32 = @intCast(data.len);

    const staging_buffer = buffer_init(T, device, c.VK_BUFFER_USAGE_TRANSFER_SRC_BIT, c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, len);
    _ = device.vkMapMemory(device.handle, staging_buffer.memory, 0, len * @sizeOf(T), 0, @ptrCast(&dst));

    for (0..len) |i| {
        dst[i] = data[i];
    }

    const copy_info = c.VkBufferCopy {
        .srcOffset = 0,
        .dstOffset = 0,
        .size = @sizeOf(T) * len,
    };

    const command_buffer = begin_command_buffer(device, command_pool);

    device.vkCmdCopyBuffer(command_buffer, staging_buffer.handle, buffer.handle, 1, &copy_info);
    device.vkUnmapMemory(device.handle, staging_buffer.memory);

    end_command_buffer(device, command_pool, command_buffer);
    deinit_buffer(device, &staging_buffer);
}

fn end_command_buffer(device: *const DeviceDispatch, command_pool: *const CommandPool, command_buffer: c.VkCommandBuffer) void {
    _ = device.vkEndCommandBuffer(command_buffer);

    const submit_info = c.VkSubmitInfo {
        .sType = c.VK_STRUCTURE_TYPE_SUBMIT_INFO,
        .commandBufferCount = 1,
        .pCommandBuffers = &command_buffer,
    };

    _ = device.vkQueueSubmit(device.queues[0], 1, &submit_info, null);
    _ = device.vkQueueWaitIdle(device.queues[0]);
    device.vkFreeCommandBuffers(device.handle, command_pool.handle, 1, &command_buffer);
}

fn begin_command_buffer(device: *const DeviceDispatch, command_pool: *const CommandPool) c.VkCommandBuffer {
    var command_buffer: c.VkCommandBuffer = undefined;

    const alloc_info = c.VkCommandBufferAllocateInfo {
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
        .commandPool = command_pool.handle,
        .level = c.VK_COMMAND_BUFFER_LEVEL_PRIMARY,
        .commandBufferCount = 1,
    };

    _ = device.vkAllocateCommandBuffers(device.handle, &alloc_info, &command_buffer);
    const begin_info = c.VkCommandBufferBeginInfo {
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
        .flags = c.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
    };

    _ = device.vkBeginCommandBuffer(command_buffer, &begin_info);

    return command_buffer;
}

fn allocate_descriptor_set(device: *const DeviceDispatch, descriptor_pool: c.VkDescriptorPool, layout: c.VkDescriptorSetLayout) c.VkDescriptorSet {
    const info = c.VkDescriptorSetAllocateInfo {
        .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO,
        .descriptorPool = descriptor_pool,
        .descriptorSetCount = 1,
        .pSetLayouts = &layout,
    };

    var set: c.VkDescriptorSet = undefined;
    _ = device.vkAllocateDescriptorSets(device.handle, &info, &set);

    return set;
}

fn buffer_init(
    T: type,
    device: *const DeviceDispatch,
    usage: u32,
    properties: u32,
    len: u32,
) Buffer {
    const info = c.VkBufferCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
        .size = @sizeOf(T) * len,
        .usage = usage,
        .sharingMode = c.VK_SHARING_MODE_EXCLUSIVE,
    };

    var buffer: c.VkBuffer = undefined;
    _ = device.vkCreateBuffer(device.handle, &info, null, &buffer);

    var memory_requirements: c.VkMemoryRequirements = undefined;
    _ = device.vkGetBufferMemoryRequirements(device.handle, buffer, &memory_requirements);

    const memory = allocate_device_memory(device, properties, &memory_requirements);
    _ = device.vkBindBufferMemory(device.handle, buffer, memory, 0);

    return .{
        .handle = buffer,
        .memory = memory,
    };
}

fn deinit_buffer(device: *const DeviceDispatch, buffer: *const Buffer) void {
    device.vkDestroyBuffer(device.handle, buffer.handle, null);
    device.vkFreeMemory(device.handle, buffer.memory, null);
}

fn deinit_image(device: *const DeviceDispatch, image: *const Image) void {
    device.vkFreeMemory(device.handle, image.memory, null);
    device.vkDestroyImage(device.handle, image.handle, null);
    device.vkDestroyImageView(device.handle, image.view, null);
    device.vkDestroySampler(device.handle, image.sampler, null);
}

pub fn deinit_painter(device: *const DeviceDispatch, painter: *const Painter) void {
    deinit_buffer(device, &painter.uniform.buffer);
    deinit_buffer(device, &painter.coords_buffer);
    deinit_buffer(device, &painter.index_buffer);
    deinit_image(device, &painter.texture);
}

pub fn deinit_command_pool(device: *const DeviceDispatch, command_pool: *const CommandPool) void {
    const count: u32 = @intCast(command_pool.buffers.len);

    device.vkFreeCommandBuffers(device.handle, command_pool.handle, count, &command_pool.buffers[0]);
    device.vkDestroyCommandPool(device.handle, command_pool.handle, null);

    command_pool.allocator.free(command_pool.buffers);
}

pub fn deinit_swapchain(device: *const DeviceDispatch, swapchain: *const Swapchain) void {
    const count = swapchain.framebuffers.len;
    for (0..count) |i| {
        device.vkDestroyImageView(device.handle, swapchain.image_views[i], null);
        device.vkDestroyFramebuffer(device.handle, swapchain.framebuffers[i], null);
    }

    device.vkDestroySemaphore(device.handle, swapchain.render_finished, null);
    device.vkDestroySemaphore(device.handle, swapchain.image_available, null);
    device.vkDestroyFence(device.handle, swapchain.in_flight, null);

    device.vkDestroySwapchainKHR(device.handle, swapchain.handle, null);
}

pub fn deinit_instance(instance: *const InstanceDispatch) void {
    instance.vkDestroySurfaceKHR(instance.handle, instance.surface, null);
    instance.vkDestroyInstance(instance.handle, null);
    _ = c.dlclose(instance.library);
    _ = ARENA.deinit();
}

pub fn deinit_device(device: *const DeviceDispatch) void {
    device.vkDestroyDevice(device.handle, null);
}

pub fn deinit_graphics_pipeline(dispatch: *const DeviceDispatch, graphics_pipeline: *const GraphicsPipeline) void {
    dispatch.vkDestroyDescriptorPool(dispatch.handle, graphics_pipeline.global_pool, null);
    dispatch.vkDestroyDescriptorSetLayout(dispatch.handle, graphics_pipeline.global_layout, null);
    dispatch.vkDestroyDescriptorPool(dispatch.handle, graphics_pipeline.texture_pool, null);
    dispatch.vkDestroyDescriptorSetLayout(dispatch.handle, graphics_pipeline.texture_layout, null);
    dispatch.vkDestroyPipelineLayout(dispatch.handle, graphics_pipeline.layout, null);
    dispatch.vkDestroyRenderPass(dispatch.handle, graphics_pipeline.render_pass, null);
    dispatch.vkDestroyPipeline(dispatch.handle, graphics_pipeline.handle, null);
}
