const std = @import("std");
const c = @import("../bind.zig").c;
const truetype = @import("../font/core.zig");
const wayland = @import("../wayland/core.zig");

const Window = wayland.Wayland;
const Font = truetype.TrueType;

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
    in_flight: c.VkFence,

    capabilities: c.VkSurfaceCapabilitiesKHR,
    extent: c.VkExtent2D,
    image_count: u32,

    allocator: std.mem.Allocator,
};

const CommandPool = struct {
    handle: c.VkCommandPool,
    buffers: []c.VkCommandBuffer,
    allocator: std.mem.Allocator,
};

const D: type = u32;

const CharType = struct {
    positions: Buffer,
    dst: [][2]D,
    capacity: u32,
};

const Cursor = struct {
    position: Buffer,
    dst: [][2]D,
};

pub const Painter = struct {
    index_buffer: Buffer,
    uniform: Uniform,

    coords_buffer: Buffer,
    chars: []CharType,
    texture: Image,
    texture_descriptor: TextureDescriptor,

    cursor_coords: Buffer,
    cursor: Cursor,
    cursor_texture: Image,
    cursor_texture_descriptor: TextureDescriptor,

    allocator: std.mem.Allocator,
};

const Buffer = struct {
    handle: c.VkBuffer,
    memory: c.VkDeviceMemory,
};

const TextureDescriptor = struct {
    sampler: c.VkSampler,
    set: c.VkDescriptorSet,
};

const Image = struct {
    handle: c.VkImage,
    memory: c.VkDeviceMemory,
    view: c.VkImageView,
    width: u32,
    height: u32,
};

const Uniform = struct {
    buffer: Buffer,
    set: c.VkDescriptorSet,
    dst: []f32,
};

const GpuType = enum {
    Other,
    Integrated,
    Discrete,
    Virtual,
    Cpu
};

pub fn instance_init(window: *const Window) !InstanceDispatch {
    var instance: InstanceDispatch = undefined;

    instance.library = c.dlopen("libvulkan.so", 1) orelse return error.VulkanLibraryLoading;
    const vkCreateInstance = @as(c.PFN_vkCreateInstance, @ptrCast(c.dlsym(instance.library, "vkCreateInstance"))) orelse return error.PFN_vkCreateInstanceNotFound;

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

    const result = vkCreateInstance(&instance_create_info, null, &instance.handle);
    if (result != 0) return error.InstanceCreate;

    instance.vkGetInstanceProcAddr = @as(c.PFN_vkGetInstanceProcAddr, @ptrCast(c.dlsym(instance.library, "vkGetInstanceProcAddr"))) orelse return error.PFN_vkGetInstanceProcAddr;
    instance.vkDestroySurfaceKHR = @as(c.PFN_vkDestroySurfaceKHR, @ptrCast(instance.vkGetInstanceProcAddr(instance.handle, "vkDestroySurfaceKHR"))) orelse return error.FunctionNotFound;
    instance.vkEnumeratePhysicalDevices = @as(c.PFN_vkEnumeratePhysicalDevices, @ptrCast(instance.vkGetInstanceProcAddr(instance.handle, "vkEnumeratePhysicalDevices"))) orelse return error.FunctionNotFound;
    instance.vkEnumerateDeviceExtensionProperties = @as(c.PFN_vkEnumerateDeviceExtensionProperties, @ptrCast(instance.vkGetInstanceProcAddr(instance.handle, "vkEnumerateDeviceExtensionProperties"))) orelse return error.FunctionNotFound;
    instance.vkGetPhysicalDeviceProperties = @as(c.PFN_vkGetPhysicalDeviceProperties, @ptrCast(instance.vkGetInstanceProcAddr(instance.handle, "vkGetPhysicalDeviceProperties"))) orelse return error.FunctionNotFound;
    instance.vkGetPhysicalDeviceFeatures = @as(c.PFN_vkGetPhysicalDeviceFeatures, @ptrCast(instance.vkGetInstanceProcAddr(instance.handle, "vkGetPhysicalDeviceFeatures"))) orelse return error.FunctionNotFound;
    instance.vkGetPhysicalDeviceSurfaceFormatsKHR = @as(c.PFN_vkGetPhysicalDeviceSurfaceFormatsKHR, @ptrCast(instance.vkGetInstanceProcAddr(instance.handle, "vkGetPhysicalDeviceSurfaceFormatsKHR"))) orelse return error.FunctionNotFound;
    instance.vkGetPhysicalDeviceSurfacePresentModesKHR = @as(c.PFN_vkGetPhysicalDeviceSurfacePresentModesKHR, @ptrCast(instance.vkGetInstanceProcAddr(instance.handle, "vkGetPhysicalDeviceSurfacePresentModesKHR"))) orelse return error.FunctionNotFound;
    instance.vkGetPhysicalDeviceQueueFamilyProperties = @as(c.PFN_vkGetPhysicalDeviceQueueFamilyProperties, @ptrCast(instance.vkGetInstanceProcAddr(instance.handle, "vkGetPhysicalDeviceQueueFamilyProperties"))) orelse return error.FunctionNotFound;
    instance.vkGetPhysicalDeviceSurfaceCapabilitiesKHR = @as(c.PFN_vkGetPhysicalDeviceSurfaceCapabilitiesKHR, @ptrCast(instance.vkGetInstanceProcAddr(instance.handle, "vkGetPhysicalDeviceSurfaceCapabilitiesKHR"))) orelse return error.FunctionNotFound;
    instance.vkGetPhysicalDeviceSurfaceSupportKHR = @as(c.PFN_vkGetPhysicalDeviceSurfaceSupportKHR, @ptrCast(instance.vkGetInstanceProcAddr(instance.handle, "vkGetPhysicalDeviceSurfaceSupportKHR"))) orelse return error.FunctionNotFound;
    instance.vkGetPhysicalDeviceMemoryProperties = @as(c.PFN_vkGetPhysicalDeviceMemoryProperties, @ptrCast(instance.vkGetInstanceProcAddr(instance.handle, "vkGetPhysicalDeviceMemoryProperties"))) orelse return error.FunctionNotFound;
    instance.vkGetPhysicalDeviceFormatProperties = @as(c.PFN_vkGetPhysicalDeviceFormatProperties, @ptrCast(instance.vkGetInstanceProcAddr(instance.handle, "vkGetPhysicalDeviceFormatProperties"))) orelse return error.FunctionNotFound;
    instance.vkCreateDevice = @as(c.PFN_vkCreateDevice, @ptrCast(instance.vkGetInstanceProcAddr(instance.handle, "vkCreateDevice"))) orelse return error.FunctionNotFound;
    instance.vkDestroyInstance = @as(c.PFN_vkDestroyInstance, @ptrCast(instance.vkGetInstanceProcAddr(instance.handle, "vkDestroyInstance"))) orelse return error.FunctionNotFound;

    const vkCreateWaylandSurfaceKHR = @as(c.PFN_vkCreateWaylandSurfaceKHR, @ptrCast(instance.vkGetInstanceProcAddr(instance.handle, "vkCreateWaylandSurfaceKHR"))) orelse return error.FunctionNotFound;

    const wayland_surface_create_info = c.VkWaylandSurfaceCreateInfoKHR {
        .sType = c.VK_STRUCTURE_TYPE_WAYLAND_SURFACE_CREATE_INFO_KHR,
        .display = window.display,
        .surface = window.surface,
    };

    _ = vkCreateWaylandSurfaceKHR(instance.handle, &wayland_surface_create_info, null, &instance.surface);

    return instance;
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
        var families: [4]u8 = .{ 0xFF, 0xFF, 0xFF, 0xFF };
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
    var device: DeviceDispatch = undefined;
    var count: u32 = 0;

    _ = instance_dispatch.vkEnumeratePhysicalDevices(instance_dispatch.handle, &count, null);
    var physical_devices: [3]c.VkPhysicalDevice = undefined;
    _ = instance_dispatch.vkEnumeratePhysicalDevices(instance_dispatch.handle, &count, &physical_devices);

    var max_valuation: u32 = 0;
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
            device.physical_device = physical_devices[i];
            max_valuation = sum;
            device.families = valuation.families;
        }
    }

    if (max_valuation == 0) return error.PhysicalDeviceRequisits;

    var queue_count: u32 = 0;
    var last_value: u32 = 0xFF;
    var queue_create_infos: [4]c.VkDeviceQueueCreateInfo = undefined;

    for (device.families) |family| {
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
    instance_dispatch.vkGetPhysicalDeviceFeatures(device.physical_device, &features);

    const device_create_info = c.VkDeviceCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
        .queueCreateInfoCount = queue_count,
        .pQueueCreateInfos = &queue_create_infos[0],
        .pEnabledFeatures = &features,
        .enabledExtensionCount = 1,
        .ppEnabledExtensionNames = &required_extensions[0],
    };

    _ = instance_dispatch.vkCreateDevice(device.physical_device, &device_create_info, null, &device.handle);
    device.vkGetDeviceProcAddr = @as(c.PFN_vkGetDeviceProcAddr, @ptrCast(instance_dispatch.vkGetInstanceProcAddr(instance_dispatch.handle, "vkGetDeviceProcAddr"))) orelse return error.FunctionNotFound;

    device.vkAllocateCommandBuffers = @as(c.PFN_vkAllocateCommandBuffers, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkAllocateCommandBuffers"))) orelse return error.FunctionNotFound;
    device.vkAllocateMemory = @as(c.PFN_vkAllocateMemory, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkAllocateMemory"))) orelse return error.FunctionNotFound;
    device.vkAllocateDescriptorSets = @as(c.PFN_vkAllocateDescriptorSets, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkAllocateDescriptorSets"))) orelse return error.FunctionNotFound;
    device.vkGetDeviceQueue = @as(c.PFN_vkGetDeviceQueue, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkGetDeviceQueue"))) orelse return error.FunctionNotFound;
    device.vkQueueSubmit = @as(c.PFN_vkQueueSubmit, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkQueueSubmit"))) orelse return error.FunctionNotFound;
    device.vkQueuePresentKHR = @as(c.PFN_vkQueuePresentKHR, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkQueuePresentKHR"))) orelse return error.FunctionNotFound;
    device.vkQueueWaitIdle = @as(c.PFN_vkQueueWaitIdle, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkQueueWaitIdle"))) orelse return error.FunctionNotFound;
    device.vkGetSwapchainImagesKHR = @as(c.PFN_vkGetSwapchainImagesKHR, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkGetSwapchainImagesKHR"))) orelse return error.FunctionNotFound;
    device.vkGetImageMemoryRequirements = @as(c.PFN_vkGetImageMemoryRequirements, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkGetImageMemoryRequirements"))) orelse return error.FunctionNotFound;
    device.vkGetBufferMemoryRequirements = @as(c.PFN_vkGetBufferMemoryRequirements, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkGetBufferMemoryRequirements"))) orelse return error.FunctionNotFound;
    device.vkBindBufferMemory = @as(c.PFN_vkBindBufferMemory, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkBindBufferMemory"))) orelse return error.FunctionNotFound;
    device.vkBindImageMemory = @as(c.PFN_vkBindImageMemory, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkBindImageMemory"))) orelse return error.FunctionNotFound;
    device.vkAcquireNextImageKHR = @as(c.PFN_vkAcquireNextImageKHR, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkAcquireNextImageKHR"))) orelse return error.FunctionNotFound;
    device.vkWaitForFences = @as(c.PFN_vkWaitForFences, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkWaitForFences"))) orelse return error.FunctionNotFound;
    device.vkResetFences = @as(c.PFN_vkResetFences, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkResetFences"))) orelse return error.FunctionNotFound;
    device.vkCreateSwapchainKHR = @as(c.PFN_vkCreateSwapchainKHR, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkCreateSwapchainKHR"))) orelse return error.FunctionNotFound;
    device.vkCreateImage = @as(c.PFN_vkCreateImage, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkCreateImage"))) orelse return error.FunctionNotFound;
    device.vkCreateImageView = @as(c.PFN_vkCreateImageView, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkCreateImageView"))) orelse return error.FunctionNotFound;
    device.vkCreateShaderModule = @as(c.PFN_vkCreateShaderModule, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkCreateShaderModule"))) orelse return error.FunctionNotFound;
    device.vkCreatePipelineLayout = @as(c.PFN_vkCreatePipelineLayout, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkCreatePipelineLayout"))) orelse return error.FunctionNotFound;
    device.vkCreateRenderPass = @as(c.PFN_vkCreateRenderPass, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkCreateRenderPass"))) orelse return error.FunctionNotFound;
    device.vkCreateGraphicsPipelines = @as(c.PFN_vkCreateGraphicsPipelines, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkCreateGraphicsPipelines"))) orelse return error.FunctionNotFound;
    device.vkCreateFramebuffer = @as(c.PFN_vkCreateFramebuffer, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkCreateFramebuffer"))) orelse return error.FunctionNotFound;
    device.vkCreateCommandPool = @as(c.PFN_vkCreateCommandPool, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkCreateCommandPool"))) orelse return error.FunctionNotFound;
    device.vkCreateSemaphore = @as(c.PFN_vkCreateSemaphore, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkCreateSemaphore"))) orelse return error.FunctionNotFound;
    device.vkCreateFence = @as(c.PFN_vkCreateFence, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkCreateFence"))) orelse return error.FunctionNotFound;
    device.vkCreateBuffer = @as(c.PFN_vkCreateBuffer, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkCreateBuffer"))) orelse return error.FunctionNotFound;
    device.vkCreateSampler = @as(c.PFN_vkCreateSampler, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkCreateSampler"))) orelse return error.FunctionNotFound;
    device.vkDestroySampler = @as(c.PFN_vkDestroySampler, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkDestroySampler"))) orelse return error.FunctionNotFound;
    device.vkCreateDescriptorSetLayout = @as(c.PFN_vkCreateDescriptorSetLayout, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkCreateDescriptorSetLayout"))) orelse return error.FunctionNotFound;
    device.vkDestroyCommandPool = @as(c.PFN_vkDestroyCommandPool, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkDestroyCommandPool"))) orelse return error.FunctionNotFound;
    device.vkCreateDescriptorPool = @as(c.PFN_vkCreateDescriptorPool, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkCreateDescriptorPool"))) orelse return error.FunctionNotFound;
    device.vkDestroyPipeline = @as(c.PFN_vkDestroyPipeline, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkDestroyPipeline"))) orelse return error.FunctionNotFound;
    device.vkDestroyPipelineLayout = @as(c.PFN_vkDestroyPipelineLayout, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkDestroyPipelineLayout"))) orelse return error.FunctionNotFound;
    device.vkDestroyRenderPass = @as(c.PFN_vkDestroyRenderPass, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkDestroyRenderPass"))) orelse return error.FunctionNotFound;
    device.vkDestroySwapchainKHR = @as(c.PFN_vkDestroySwapchainKHR, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkDestroySwapchainKHR"))) orelse return error.FunctionNotFound;
    device.vkDestroyImage = @as(c.PFN_vkDestroyImage, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkDestroyImage"))) orelse return error.FunctionNotFound;
    device.vkDestroyImageView = @as(c.PFN_vkDestroyImageView, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkDestroyImageView"))) orelse return error.FunctionNotFound;
    device.vkDestroyShaderModule = @as(c.PFN_vkDestroyShaderModule, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkDestroyShaderModule"))) orelse return error.FunctionNotFound;
    device.vkDestroySemaphore = @as(c.PFN_vkDestroySemaphore, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkDestroySemaphore"))) orelse return error.FunctionNotFound;
    device.vkDestroyFence = @as(c.PFN_vkDestroyFence, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkDestroyFence"))) orelse return error.FunctionNotFound;
    device.vkDestroyFramebuffer = @as(c.PFN_vkDestroyFramebuffer, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkDestroyFramebuffer"))) orelse return error.FunctionNotFound;
    device.vkDestroyBuffer = @as(c.PFN_vkDestroyBuffer, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkDestroyBuffer"))) orelse return error.FunctionNotFound;
    device.vkDestroyDescriptorSetLayout = @as(c.PFN_vkDestroyDescriptorSetLayout, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkDestroyDescriptorSetLayout"))) orelse return error.FunctionNotFound;
    device.vkDestroyDescriptorPool = @as(c.PFN_vkDestroyDescriptorPool, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkDestroyDescriptorPool"))) orelse return error.FunctionNotFound;
    device.vkBeginCommandBuffer = @as(c.PFN_vkBeginCommandBuffer, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkBeginCommandBuffer"))) orelse return error.FunctionNotFound;
    device.vkCmdBeginRenderPass = @as(c.PFN_vkCmdBeginRenderPass, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkCmdBeginRenderPass"))) orelse return error.FunctionNotFound;
    device.vkCmdBindPipeline = @as(c.PFN_vkCmdBindPipeline, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkCmdBindPipeline"))) orelse return error.FunctionNotFound;
    device.vkCmdBindVertexBuffers = @as(c.PFN_vkCmdBindVertexBuffers, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkCmdBindVertexBuffers"))) orelse return error.FunctionNotFound;
    device.vkCmdBindIndexBuffer = @as(c.PFN_vkCmdBindIndexBuffer, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkCmdBindIndexBuffer"))) orelse return error.FunctionNotFound;
    device.vkCmdSetViewport = @as(c.PFN_vkCmdSetViewport, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkCmdSetViewport"))) orelse return error.FunctionNotFound;
    device.vkCmdSetScissor = @as(c.PFN_vkCmdSetScissor, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkCmdSetScissor"))) orelse return error.FunctionNotFound;
    device.vkCmdDraw = @as(c.PFN_vkCmdDraw, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkCmdDraw"))) orelse return error.FunctionNotFound;
    device.vkCmdDrawIndexed = @as(c.PFN_vkCmdDrawIndexed, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkCmdDrawIndexed"))) orelse return error.FunctionNotFound;
    device.vkCmdCopyBuffer = @as(c.PFN_vkCmdCopyBuffer, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkCmdCopyBuffer"))) orelse return error.FunctionNotFound;
    device.vkCmdCopyBufferToImage = @as(c.PFN_vkCmdCopyBufferToImage, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkCmdCopyBufferToImage"))) orelse return error.FunctionNotFound;
    device.vkCmdPushConstants = @as(c.PFN_vkCmdPushConstants, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkCmdPushConstants"))) orelse return error.FunctionNotFound;
    device.vkCmdPipelineBarrier = @as(c.PFN_vkCmdPipelineBarrier, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkCmdPipelineBarrier"))) orelse return error.FunctionNotFound;
    device.vkUpdateDescriptorSets = @as(c.PFN_vkUpdateDescriptorSets, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkUpdateDescriptorSets"))) orelse return error.FunctionNotFound;
    device.vkCmdBindDescriptorSets = @as(c.PFN_vkCmdBindDescriptorSets, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkCmdBindDescriptorSets"))) orelse return error.FunctionNotFound;
    device.vkCmdEndRenderPass = @as(c.PFN_vkCmdEndRenderPass, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkCmdEndRenderPass"))) orelse return error.FunctionNotFound;
    device.vkEndCommandBuffer = @as(c.PFN_vkEndCommandBuffer, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkEndCommandBuffer"))) orelse return error.FunctionNotFound;
    device.vkResetCommandBuffer = @as(c.PFN_vkResetCommandBuffer, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkResetCommandBuffer"))) orelse return error.FunctionNotFound;
    device.vkFreeMemory = @as(c.PFN_vkFreeMemory, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkFreeMemory"))) orelse return error.FunctionNotFound;
    device.vkFreeCommandBuffers = @as(c.PFN_vkFreeCommandBuffers, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkFreeCommandBuffers"))) orelse return error.FunctionNotFound;
    device.vkFreeDescriptorSets = @as(c.PFN_vkFreeDescriptorSets, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkFreeDescriptorSets"))) orelse return error.FunctionNotFound;
    device.vkMapMemory = @as(c.PFN_vkMapMemory, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkMapMemory"))) orelse return error.FunctionNotFound;
    device.vkUnmapMemory = @as(c.PFN_vkUnmapMemory, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkUnmapMemory"))) orelse return error.FunctionNotFound;
    device.vkDestroyDevice = @as(c.PFN_vkDestroyDevice, @ptrCast(device.vkGetDeviceProcAddr(device.handle, "vkDestroyDevice"))) orelse return error.FunctionNotFound;

    for (0..4) |i| {
        device.vkGetDeviceQueue(device.handle, device.families[i], 0, &device.queues[i]);
    }

    instance_dispatch.vkGetPhysicalDeviceMemoryProperties(device.physical_device, &device.physical_device_properties);

    return device;
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
    var graphics_pipeline: GraphicsPipeline = undefined;

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

    const coords_binding_description = c.VkVertexInputBindingDescription {
        .binding = 0,
        .stride = @sizeOf(f32) * 2,
        .inputRate = c.VK_VERTEX_INPUT_RATE_VERTEX,
    };

    const coords_attribute_description = c.VkVertexInputAttributeDescription {
        .binding = 0,
        .location = 0,
        .format = c.VK_FORMAT_R32G32_SFLOAT,
        .offset = 0,
    };

    const position_binding_description = c.VkVertexInputBindingDescription {
        .binding = 1,
        .stride = @sizeOf(u32) * 2,
        .inputRate = c.VK_VERTEX_INPUT_RATE_INSTANCE,
    };

    const position_attribute_description = c.VkVertexInputAttributeDescription {
        .binding = 1,
        .location = 1,
        .format = c.VK_FORMAT_R32G32_UINT,
        .offset = 0,
    };

    const binding_descriptions = &[_]c.VkVertexInputBindingDescription {
        coords_binding_description,
        position_binding_description,
    };

    const attribute_descriptions = &[_]c.VkVertexInputAttributeDescription {
        coords_attribute_description,
        position_attribute_description,
    };

    const input_state_info = c.VkPipelineVertexInputStateCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
        .pVertexBindingDescriptions = binding_descriptions.ptr,
        .vertexBindingDescriptionCount = binding_descriptions.len,
        .pVertexAttributeDescriptions = attribute_descriptions.ptr,
        .vertexAttributeDescriptionCount = attribute_descriptions.len,
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
        .srcColorBlendFactor = c.VK_BLEND_FACTOR_SRC_ALPHA,
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

    _ = device_dispatch.vkCreateDescriptorSetLayout(device_dispatch.handle, &global_layout_info, null, &graphics_pipeline.global_layout);

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

    _ = device_dispatch.vkCreateDescriptorSetLayout(device_dispatch.handle, &texture_layout_info, null, &graphics_pipeline.texture_layout);

    // const push_constant = c.VkPushConstantRange {
    //   .stageFlags = c.VK_SHADER_STAGE_VERTEX_BIT,
    //   .offset = 0,
    //   .size = @sizeOf(f32) * 2,
    // };

    const set_layouts = [_]c.VkDescriptorSetLayout {
        graphics_pipeline.global_layout,
        graphics_pipeline.texture_layout
    };

    const layout_info = c.VkPipelineLayoutCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
        .pushConstantRangeCount = 0,
        .pPushConstantRanges = null,
        .setLayoutCount = set_layouts.len,
        .pSetLayouts = &set_layouts,
    };

    _ = device_dispatch.vkCreatePipelineLayout(device_dispatch.handle, &layout_info, null, &graphics_pipeline.layout);

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

    _ = device_dispatch.vkCreateDescriptorPool(device_dispatch.handle, &global_pool_info, null, &graphics_pipeline.global_pool);

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

    _ = device_dispatch.vkCreateDescriptorPool(device_dispatch.handle, &texture_pool_info, null, &graphics_pipeline.texture_pool);

    graphics_pipeline.format = blk: {
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
        .format = graphics_pipeline.format.format,
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

    _ = device_dispatch.vkCreateRenderPass(device_dispatch.handle, &render_pass_info, null, &graphics_pipeline.render_pass);

    const graphics_pipeline_info = c.VkGraphicsPipelineCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
        .stageCount = shader_stage_infos.len,
        .pStages = shader_stage_infos.ptr,
        .pVertexInputState = &input_state_info,
        .pInputAssemblyState = &input_assembly_state_info,
        .pViewportState = &viewport_state_info,
        .pRasterizationState = &rasterize_state_info,
        .pMultisampleState = &multisampling_state_info,
        .pDepthStencilState = &depth_stencil_state_info,
        .pColorBlendState = &color_blend_state_info,
        .pDynamicState = &dynamic_state_info,
        .layout = graphics_pipeline.layout,
        .renderPass = graphics_pipeline.render_pass,
    };

    _ = device_dispatch.vkCreateGraphicsPipelines(device_dispatch.handle, null, 1, &graphics_pipeline_info, null, &graphics_pipeline.handle);

    return graphics_pipeline;
}

pub fn swapchain_init(
    instance_dispatch: *const InstanceDispatch,
    device_dispatch: *const DeviceDispatch,
    graphics_pipeline: *const GraphicsPipeline,
    window: *const Window,
    allocator: std.mem.Allocator,
) !Swapchain {
    var swapchain: Swapchain = undefined;
    swapchain.handle = null;

    const semaphore_info = c.VkSemaphoreCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
    };

    const fence_info = c.VkFenceCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
        .flags = c.VK_FENCE_CREATE_SIGNALED_BIT,
    };

    _ = device_dispatch.vkCreateSemaphore(device_dispatch.handle, &semaphore_info, null, &swapchain.render_finished);
    _ = device_dispatch.vkCreateFence(device_dispatch.handle, &fence_info, null, &swapchain.in_flight);

    _ = instance_dispatch.vkGetPhysicalDeviceSurfaceCapabilitiesKHR(device_dispatch.physical_device, instance_dispatch.surface, &swapchain.capabilities);

    swapchain.image_count = if (swapchain.capabilities.maxImageCount > 0) @min(swapchain.capabilities.minImageCount + 1, swapchain.capabilities.maxImageCount)
  else swapchain.capabilities.minImageCount + 1;

    swapchain.images = try allocator.alloc(c.VkImage, swapchain.image_count);
    swapchain.image_views = try allocator.alloc(c.VkImageView, swapchain.image_count);
    swapchain.framebuffers = try allocator.alloc(c.VkFramebuffer, swapchain.image_count);
    swapchain.allocator = allocator;

    swapchain_init_aux(
        &swapchain,
        instance_dispatch,
        device_dispatch,
        graphics_pipeline,
        window,
    );

    return swapchain;
}

fn recreate_swapchain(
    swapchain: *Swapchain,
    instance_dispatch: *const InstanceDispatch,
    device_dispatch: *const DeviceDispatch,
    graphics_pipeline: *const GraphicsPipeline,
    window: *const Window,
) void {
    swapchain_init_aux(
        swapchain,
        instance_dispatch,
        device_dispatch,
        graphics_pipeline,
        window,
    );
}

fn swapchain_init_aux(
    swapchain: *Swapchain,
    instance_dispatch: *const InstanceDispatch,
    device_dispatch: *const DeviceDispatch,
    graphics_pipeline: *const GraphicsPipeline,
    window: *const Window,
) void {
    swapchain.extent = c.VkExtent2D {
        .width = window.width,
        .height = window.height,
    };

    const present_mode = c.VK_PRESENT_MODE_FIFO_KHR;

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

    const old_swapchain = swapchain.handle;

    const info = c.VkSwapchainCreateInfoKHR {
        .sType = c.VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
        .surface = instance_dispatch.surface,
        .minImageCount = swapchain.image_count,
        .imageFormat = graphics_pipeline.format.format,
        .imageColorSpace = graphics_pipeline.format.colorSpace,
        .imageExtent = swapchain.extent,
        .imageSharingMode = if (family_count > 1) c.VK_SHARING_MODE_CONCURRENT else c.VK_SHARING_MODE_EXCLUSIVE,
        .presentMode = present_mode,
        .preTransform = swapchain.capabilities.currentTransform,
        .clipped = c.VK_TRUE,
        .imageArrayLayers = 1,
        .compositeAlpha = c.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
        .imageUsage = c.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
        .queueFamilyIndexCount = family_count,
        .pQueueFamilyIndices = &unique_families[0],
        .oldSwapchain = old_swapchain,
    };

    _ = device_dispatch.vkCreateSwapchainKHR(device_dispatch.handle, &info, null, &swapchain.handle);
    _ = device_dispatch.vkGetSwapchainImagesKHR(device_dispatch.handle, swapchain.handle, &swapchain.image_count, swapchain.images.ptr);

    if (old_swapchain) |_| {
        for (0..swapchain.image_count) |i| {
            device_dispatch.vkDestroyImageView(device_dispatch.handle, swapchain.image_views[i], null);
            device_dispatch.vkDestroyFramebuffer(device_dispatch.handle, swapchain.framebuffers[i], null);
        }

        device_dispatch.vkDestroySemaphore(device_dispatch.handle, swapchain.image_available, null);
        device_dispatch.vkDestroySwapchainKHR(device_dispatch.handle, old_swapchain, null);
    }

    for (0..swapchain.image_count) |i| {
        swapchain.image_views[i] = image_view_init(device_dispatch, swapchain.images[i], graphics_pipeline.format.format);

        const framebuffer_info = c.VkFramebufferCreateInfo {
            .sType = c.VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO,
            .renderPass = graphics_pipeline.render_pass,
            .attachmentCount = 1,
            .pAttachments = &swapchain.image_views[i],
            .width = swapchain.extent.width,
            .height = swapchain.extent.height,
            .layers = 1,
        };

        _ = device_dispatch.vkCreateFramebuffer(device_dispatch.handle, &framebuffer_info, null, &swapchain.framebuffers[i]);
    }

    const semaphore_info = c.VkSemaphoreCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
    };

    _ = device_dispatch.vkCreateSemaphore(device_dispatch.handle, &semaphore_info, null, &swapchain.image_available);
}

pub fn command_pool_init(
    device: *const DeviceDispatch,
    swapchain: *const Swapchain,
    allocator: std.mem.Allocator,
) !CommandPool {
    var command_pool: CommandPool = undefined;

    const info = c.VkCommandPoolCreateInfo {
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
        .flags = c.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
        .queueFamilyIndex = device.families[0],
    };

    _ = device.vkCreateCommandPool(device.handle, &info, null, &command_pool.handle);

    const count = swapchain.framebuffers.len;
    command_pool.buffers = try allocator.alloc(c.VkCommandBuffer, count);
    command_pool.allocator = allocator;

    {
        const buffers_info = c.VkCommandBufferAllocateInfo {
            .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
            .commandPool = command_pool.handle,
            .level = c.VK_COMMAND_BUFFER_LEVEL_PRIMARY,
            .commandBufferCount = @intCast(count),
        };

        _ = device.vkAllocateCommandBuffers(device.handle, &buffers_info, &command_pool.buffers[0]);
    }

    return command_pool;
}

const CHAR_COUNT: u32 = 95;
pub fn painter_init(
    device: *const DeviceDispatch,
    graphics_pipeline: *const GraphicsPipeline,
    command_pool: *const CommandPool,
    window: *const Window,
    font: *const Font,
    allocator: std.mem.Allocator,
) !Painter {
    var painter: Painter = undefined;

    const global_binding = 0;
    const uniform_data = [_]f32 { window.scale, font.scale, font.x_ratio };
    painter.uniform = uniform_buffer_init(
        f32,
        device,
        &uniform_data,
        graphics_pipeline.global_pool,
        graphics_pipeline.global_layout,
        global_binding
    );

    const glyph_width = truetype.normalized_width(font);
    const glyph_height = truetype.normalized_height(font);

    var coords: [CHAR_COUNT][4][2]f32 = undefined;
    painter.chars = try allocator.alloc(CharType, CHAR_COUNT);
    painter.allocator = allocator;

    const initial_allocation_count: u32 = 10;
    for (0..CHAR_COUNT) |i| {
        const offset = truetype.glyph_normalized_offset(font, i);

        coords[i] = .{
            .{ offset[0], offset[1] },
            .{ offset[0] + glyph_width, offset[1] },
            .{ offset[0], offset[1] + glyph_height},
            .{ offset[0] + glyph_width, offset[1] + glyph_height },
        };

        painter.chars[i].positions = buffer_init(
            [2]D,
            device,
            c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
            c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
            initial_allocation_count
        );

        _ = device.vkMapMemory(device.handle, painter.chars[i].positions.memory, 0, initial_allocation_count * @sizeOf([2]D), 0, @ptrCast(&painter.chars[i].dst));
        painter.chars[i].capacity = initial_allocation_count;
        painter.chars[i].dst.len = 0;
    }

    const cursor_coords: [4][2]f32 = .{
        .{ 0.0, 0.0 },
        .{ 1.0, 0.0 },
        .{ 0.0, 1.0 },
        .{ 1.0, 1.0 },
    };

    painter.cursor.position = buffer_init(
        [2]D,
        device,
        c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
        c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
        1
    );

    _ = device.vkMapMemory(device.handle, painter.cursor.position.memory, 0, @sizeOf([2]D), 0, @ptrCast(&painter.cursor.dst));
    painter.cursor.dst.len = 1;

    painter.coords_buffer = buffer_init(
        [4][2]f32,
        device,
        c.VK_BUFFER_USAGE_TRANSFER_DST_BIT | c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
        c.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
        coords.len
    );

    painter.cursor_coords = buffer_init(
        [4][2]f32,
        device,
        c.VK_BUFFER_USAGE_TRANSFER_DST_BIT | c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
        c.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
        1
    );

    const indices = [_]u16 { 0, 1, 2, 1, 3, 2 };
    painter.index_buffer = buffer_init(
        u16,
        device,
        c.VK_BUFFER_USAGE_TRANSFER_DST_BIT | c.VK_BUFFER_USAGE_INDEX_BUFFER_BIT,
        c.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
        indices.len
    );

    painter.texture = image_init(
        device,
        c.VK_FORMAT_R8_UNORM,
        c.VK_IMAGE_USAGE_TRANSFER_DST_BIT | c.VK_IMAGE_USAGE_SAMPLED_BIT,
        font.bitmap.width,
        font.bitmap.height
    );

    var cursor_texture: [256]u8 = undefined;
    for (0..256) |i| {
        cursor_texture[i] = 255;
    }

    painter.cursor_texture = image_init(
        device,
        c.VK_FORMAT_R8_UNORM,
        c.VK_IMAGE_USAGE_TRANSFER_DST_BIT | c.VK_IMAGE_USAGE_SAMPLED_BIT,
        16,
        16,
    );

    copy_data_to_buffer([4][2]f32, device, &painter.coords_buffer, command_pool, &coords);
    copy_data_to_buffer([2]f32, device, &painter.cursor_coords, command_pool, &cursor_coords);
    copy_data_to_buffer(u16, device, &painter.index_buffer, command_pool, &indices);
    copy_data_to_image(device, &painter.texture, command_pool, font.bitmap.handle);
    copy_data_to_image(device, &painter.cursor_texture, command_pool, &cursor_texture);

    painter.texture_descriptor = texture_descriptor_init(device, graphics_pipeline, &painter.texture);
    painter.cursor_texture_descriptor = texture_descriptor_init(device, graphics_pipeline, &painter.cursor_texture);

    return painter;
}

fn update_painter_cursor(painter: *Painter, window: *const Window) void {
    const cursor_data = wayland.get_cursor_position(window);
    painter.cursor.dst[0][0] = cursor_data[0];
    painter.cursor.dst[0][1] = cursor_data[1];
}

fn update_painter(device: *const DeviceDispatch, painter: *Painter, window: *const Window) void {
    for (0..CHAR_COUNT) |i| {
        const data = wayland.get_positions(window, i);
        const len: u32 = @intCast(data.len);
        painter.chars[i].dst.len = len;

        if (len == 0) continue;
        if (painter.chars[i].capacity < len) {
            _ = device.vkUnmapMemory(device.handle, painter.chars[i].positions.memory);
            buffer_deinit(device, &painter.chars[i].positions);

            painter.chars[i].positions = buffer_init(
                [2]D,
                device,
                c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
                c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
                len,
            );

            painter.chars[i].capacity = len;
            _ = device.vkMapMemory(device.handle, painter.chars[i].positions.memory, 0, len * @sizeOf([2]D), 0, @ptrCast(&painter.chars[i].dst));
        }

        for (0..len) |k| {
            painter.chars[i].dst[k] = data[k];
        }
    }
}

fn texture_descriptor_init(
    device: *const DeviceDispatch,
    graphics_pipeline: *const GraphicsPipeline,
    image: *const Image
) TextureDescriptor {
    var handle: TextureDescriptor = undefined;

    handle.sampler = sampler_init(device);
    handle.set = allocate_descriptor_set(device, graphics_pipeline.texture_pool, graphics_pipeline.texture_layout);
    update_image_descriptor_set(device, image.view, handle.sampler, handle.set);

    return handle;
}

fn image_init(
    device: *const DeviceDispatch,
    format: u32,
    usage: u32,
    width: u32,
    height: u32
) Image {
    var image: Image = undefined;

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

    image.width = width;
    image.height = height;

    _ = device.vkCreateImage(device.handle, &info, null, &image.handle);

    var memory_requirements: c.VkMemoryRequirements = undefined;
    device.vkGetImageMemoryRequirements(device.handle, image.handle, &memory_requirements);

    image.memory = allocate_device_memory(device, c.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, &memory_requirements);
    _ = device.vkBindImageMemory(device.handle, image.handle, image.memory, 0);

    image.view = image_view_init(device, image.handle, format);

    return image;
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
        .addressModeU = c.VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER,
        .addressModeV = c.VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER,
        .addressModeW = c.VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER,
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
    std.time.sleep(1000000 * 100);
    _ = device.vkWaitForFences(device.handle, 1, &swapchain.in_flight, c.VK_TRUE, 0xFFFFFF);
    _ = device.vkQueueWaitIdle(device.queues[0]);
}

pub fn draw_frame(
    swapchain: *Swapchain,
    instance: *const InstanceDispatch,
    device: *const DeviceDispatch,
    command_pool: *const CommandPool,
    graphics_pipeline: *const GraphicsPipeline,
    window: *const Window,
    painter: *Painter,
) void {
    const start = std.time.Instant.now() catch return;

    var image_index: u32 = 0;
    var result = device.vkAcquireNextImageKHR(device.handle, swapchain.handle, 0xFFFFFF, swapchain.image_available, null, &image_index);

    while (result == c.VK_SUBOPTIMAL_KHR or result == c.VK_ERROR_OUT_OF_DATE_KHR) {
        recreate_swapchain(swapchain, instance, device, graphics_pipeline, window);
        result = device.vkAcquireNextImageKHR(device.handle, swapchain.handle, 0xFFFFFF, swapchain.image_available, null, &image_index);
        painter.uniform.dst[0] = window.scale;
    }

    update_painter_cursor(painter, window);
    update_painter(device, painter, window);
    record_draw_command(
        device,
        graphics_pipeline,
        command_pool,
        swapchain,
        painter,
        image_index,
    );

    _ = device.vkResetFences(device.handle, 1, &swapchain.in_flight);

    const wait_dst_stage: u32 = c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
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

    const end = std.time.Instant.now() catch return;
    std.debug.print("time for draw frame: {} ns\n", .{end.since(start)});
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

    const width = swapchain.extent.width;
    const height = swapchain.extent.height;

    const begin_info = c.VkCommandBufferBeginInfo {
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
    };

    const clear_value = c.VkClearValue {
        .color = .{
            .float32 = .{ 0.0, 0.0, 0.0, 1.0 },
        },
    };

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

    _ = device.vkBeginCommandBuffer(command_buffer, &begin_info);

    device.vkCmdBeginRenderPass(command_buffer, &render_pass_info, c.VK_SUBPASS_CONTENTS_INLINE);
    device.vkCmdSetViewport(command_buffer, 0, 1, &viewport);
    device.vkCmdSetScissor(command_buffer, 0, 1, &scissor);
    device.vkCmdBindPipeline(command_buffer, c.VK_PIPELINE_BIND_POINT_GRAPHICS, graphics_pipeline.handle);
    device.vkCmdBindDescriptorSets(command_buffer, c.VK_PIPELINE_BIND_POINT_GRAPHICS, graphics_pipeline.layout, 0, 2, &.{ painter.uniform.set, painter.texture_descriptor.set }, 0, &0);
    device.vkCmdBindIndexBuffer(command_buffer, painter.index_buffer.handle, 0, c.VK_INDEX_TYPE_UINT16);

    for (0..CHAR_COUNT) |i| {
        const len: u32 = @intCast(painter.chars[i].dst.len);
        if (len == 0) continue;

        const vertex_offsets = &[_]u64 { @sizeOf(f32) * 4 * 2 * i, 0 };
        const vertex_buffers = &[_]c.VkBuffer { painter.coords_buffer.handle, painter.chars[i].positions.handle };

        device.vkCmdBindVertexBuffers(command_buffer, 0, vertex_buffers.len, &vertex_buffers[0], &vertex_offsets[0]);
        device.vkCmdDrawIndexed(command_buffer, 6, len, 0, 0, 0);
    }

    const vertex_offsets = &[_]u64 { 0, 0 };
    const vertex_buffers = &[_]c.VkBuffer { painter.coords_buffer.handle, painter.cursor.position.handle };

    device.vkCmdBindDescriptorSets(command_buffer, c.VK_PIPELINE_BIND_POINT_GRAPHICS, graphics_pipeline.layout, 0, 2, &.{ painter.uniform.set, painter.cursor_texture_descriptor.set }, 0, &0);
    device.vkCmdBindVertexBuffers(command_buffer, 0, vertex_buffers.len, &vertex_buffers[0], &vertex_offsets[0]);
    device.vkCmdDrawIndexed(command_buffer, 6, 1, 0, 0, 0);

    device.vkCmdEndRenderPass(command_buffer);
    _ = device.vkEndCommandBuffer(command_buffer);
}

fn image_view_init(device: *const DeviceDispatch, image: c.VkImage, format: u32) c.VkImageView {
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

fn copy_data_to_image(
    device: *const DeviceDispatch,
    image: *const Image,
    command_pool: *const CommandPool,
    data: []const u8,
) void {
    var dst: []u8 = undefined;
    const len: u32 = @intCast(data.len);

    const buffer = buffer_init(u8, device, c.VK_BUFFER_USAGE_TRANSFER_SRC_BIT, c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, len);
    _ = device.vkMapMemory(device.handle, buffer.memory, 0, len * @sizeOf(u8), 0, @ptrCast(&dst));

    copy(u8, data, &dst);

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

    const command_buffer = begin_command_buffer(device, command_pool);

    device.vkCmdPipelineBarrier(
        command_buffer,
        c.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT,
        c.VK_PIPELINE_STAGE_TRANSFER_BIT,
        0, 0, null, 0, null, 1, &barrier
    );

    device.vkCmdCopyBufferToImage(
        command_buffer,
        buffer.handle,
        image.handle,
        c.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
        1, &region
    );

    device.vkCmdPipelineBarrier(
        command_buffer,
        c.VK_PIPELINE_STAGE_TRANSFER_BIT,
        c.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
        0, 0, null, 0, null, 1, &second_barrier
    );

    end_command_buffer(device, command_pool, command_buffer);
    _ = device.vkUnmapMemory(device.handle, buffer.memory);
    buffer_deinit(device, &buffer);
}

fn allocate_device_memory(
    device: *const DeviceDispatch,
    properties: u32,
    requirements: *const c.VkMemoryRequirements
) c.VkDeviceMemory {
    var index: u32 = 0;

    for (0..device.physical_device_properties.memoryTypeCount) |i| {
        const a: u5 = @intCast(i);
        const b: u32 = 1;

        if ((requirements.memoryTypeBits & (b << a)) > 0 and (device.physical_device_properties.memoryTypes[i].propertyFlags & properties) == properties) {
            index = @intCast(i);
            break;
        }
    }

    const alloc_info = c.VkMemoryAllocateInfo {
        .sType = c.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
        .allocationSize = requirements.size,
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
) Uniform {
    var uniform: Uniform = undefined;

    const len: u32 = @intCast(data.len);

    uniform.buffer = buffer_init(T, device, c.VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT, c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, len);

    _ = device.vkMapMemory(device.handle, uniform.buffer.memory, 0, len * @sizeOf(T), 0, @ptrCast(&uniform.dst));

    copy(T, data, &uniform.dst);

    const info = c.VkDescriptorBufferInfo {
        .buffer = uniform.buffer.handle,
        .offset = 0,
        .range = @sizeOf(T) * len,
    };

    uniform.set = allocate_descriptor_set(device, pool, layout);
    const write = c.VkWriteDescriptorSet {
        .sType = c.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
        .dstSet = uniform.set,
        .dstBinding = binding,
        .dstArrayElement = 0,
        .descriptorType = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
        .pBufferInfo = &info,
        .descriptorCount = 1,
    };

    device.vkUpdateDescriptorSets(device.handle, 1, &.{ write }, 0, null);

    return uniform;
}

fn copy(T: type, src: []const T, dst: *[]T) void {
    @setRuntimeSafety(false);

    const len = src.len;
    dst.*.len = len;

    for (0..len) |i| {
        dst.*[i] = src[i];
    }
}

fn copy_data_to_buffer(
    T: type,
    device: *const DeviceDispatch,
    buffer: *const Buffer,
    command_pool: *const CommandPool,
    data: []const T,
) void {
    var dst: []T = undefined;
    const len: u32 = @intCast(data.len);

    const staging_buffer = buffer_init(T, device, c.VK_BUFFER_USAGE_TRANSFER_SRC_BIT, c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, len);
    _ = device.vkMapMemory(device.handle, staging_buffer.memory, 0, len * @sizeOf(T), 0, @ptrCast(&dst));

    copy(T, data, &dst);

    const copy_info = c.VkBufferCopy {
        .srcOffset = 0,
        .dstOffset = 0,
        .size = @sizeOf(T) * len,
    };

    const command_buffer = begin_command_buffer(device, command_pool);

    device.vkCmdCopyBuffer(command_buffer, staging_buffer.handle, buffer.handle, 1, &copy_info);
    device.vkUnmapMemory(device.handle, staging_buffer.memory);

    end_command_buffer(device, command_pool, command_buffer);
    buffer_deinit(device, &staging_buffer);
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

fn allocate_descriptor_set(
    device: *const DeviceDispatch,
    descriptor_pool: c.VkDescriptorPool,
    layout: c.VkDescriptorSetLayout
) c.VkDescriptorSet {
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

inline fn buffer_init(
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

    var requirements: c.VkMemoryRequirements = undefined;
    _ = device.vkGetBufferMemoryRequirements(device.handle, buffer, &requirements);

    const memory = allocate_device_memory(device, properties, &requirements);
    _ = device.vkBindBufferMemory(device.handle, buffer, memory, 0);

    return .{
        .handle = buffer,
        .memory = memory,
    };
}

fn buffer_deinit(device: *const DeviceDispatch, buffer: *const Buffer) void {
    device.vkDestroyBuffer(device.handle, buffer.handle, null);
    device.vkFreeMemory(device.handle, buffer.memory, null);
}

fn image_deinit(device: *const DeviceDispatch, image: *const Image) void {
    device.vkFreeMemory(device.handle, image.memory, null);
    device.vkDestroyImage(device.handle, image.handle, null);
    device.vkDestroyImageView(device.handle, image.view, null);
}

fn texture_descriptor_deinit(device: *const DeviceDispatch, texture_descriptor: *const TextureDescriptor) void {
    device.vkDestroySampler(device.handle, texture_descriptor.sampler, null);
}

pub fn painter_deinit(device: *const DeviceDispatch, painter: *const Painter) void {
    texture_descriptor_deinit(device, &painter.texture_descriptor);
    texture_descriptor_deinit(device, &painter.cursor_texture_descriptor);
    image_deinit(device, &painter.texture);
    image_deinit(device, &painter.cursor_texture);

    buffer_deinit(device, &painter.uniform.buffer);
    buffer_deinit(device, &painter.coords_buffer);
    buffer_deinit(device, &painter.cursor_coords);
    buffer_deinit(device, &painter.index_buffer);

    buffer_deinit(device, &painter.cursor.position);
    for (painter.chars) |char| {
        buffer_deinit(device, &char.positions);
    }

    painter.allocator.free(painter.chars);
}

pub fn command_pool_deinit(device: *const DeviceDispatch, command_pool: *const CommandPool) void {
    const count: u32 = @intCast(command_pool.buffers.len);

    device.vkFreeCommandBuffers(device.handle, command_pool.handle, count, &command_pool.buffers[0]);
    device.vkDestroyCommandPool(device.handle, command_pool.handle, null);

    command_pool.allocator.free(command_pool.buffers);
}

pub fn swapchain_deinit(device: *const DeviceDispatch, swapchain: *const Swapchain) void {
    const count = swapchain.framebuffers.len;

    for (0..count) |i| {
        device.vkDestroyImageView(device.handle, swapchain.image_views[i], null);
        device.vkDestroyFramebuffer(device.handle, swapchain.framebuffers[i], null);
    }

    swapchain.allocator.free(swapchain.framebuffers);
    swapchain.allocator.free(swapchain.image_views);

    device.vkDestroySemaphore(device.handle, swapchain.render_finished, null);
    device.vkDestroySemaphore(device.handle, swapchain.image_available, null);
    device.vkDestroyFence(device.handle, swapchain.in_flight, null);

    device.vkDestroySwapchainKHR(device.handle, swapchain.handle, null);
}

pub fn graphics_pipeline_deinit(dispatch: *const DeviceDispatch, graphics_pipeline: *const GraphicsPipeline) void {
    dispatch.vkDestroyDescriptorPool(dispatch.handle, graphics_pipeline.global_pool, null);
    dispatch.vkDestroyDescriptorSetLayout(dispatch.handle, graphics_pipeline.global_layout, null);
    dispatch.vkDestroyDescriptorPool(dispatch.handle, graphics_pipeline.texture_pool, null);
    dispatch.vkDestroyDescriptorSetLayout(dispatch.handle, graphics_pipeline.texture_layout, null);
    dispatch.vkDestroyPipelineLayout(dispatch.handle, graphics_pipeline.layout, null);
    dispatch.vkDestroyRenderPass(dispatch.handle, graphics_pipeline.render_pass, null);
    dispatch.vkDestroyPipeline(dispatch.handle, graphics_pipeline.handle, null);
}

pub fn device_deinit(device: *const DeviceDispatch) void {
    device.vkDestroyDevice(device.handle, null);
}

pub fn instance_deinit(instance: *const InstanceDispatch) void {
    instance.vkDestroySurfaceKHR(instance.handle, instance.surface, null);
    instance.vkDestroyInstance(instance.handle, null);

    _ = c.dlclose(instance.library);
    _ = ARENA.deinit();
}
