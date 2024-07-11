const std = @import("std");

const c = @import("../bind.zig").c;
const Instance = @import("instance.zig").Instance;
const check = @import("result.zig").check;

// var ARENA = std.heap.ArenaAllocator.init(std.heap.page_allocator);
// const ALLOCATOR = ARENA.allocator();

pub const Dispatch = struct {
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
    // vkGetDeviceProcAddr: *const fn (c.VkDevice, ?[*:0]const u8) callconv(.C) c.PFN_vkVoidFunction,

    pub fn init(device: c.VkDevice, instance: *const Instance) !Dispatch {
        const vkGetDeviceProcAddr = @as(c.PFN_vkGetDeviceProcAddr, @ptrCast(instance.dispatch.vkGetInstanceProcAddr(instance.handle, "vkGetDeviceProcAddr"))) orelse return error.FunctionNotFound;

        return Dispatch {
            .vkAllocateCommandBuffers = @as(c.PFN_vkAllocateCommandBuffers, @ptrCast(vkGetDeviceProcAddr(device, "vkAllocateCommandBuffers"))) orelse return error.FunctionNotFound,
            .vkAllocateMemory = @as(c.PFN_vkAllocateMemory, @ptrCast(vkGetDeviceProcAddr(device, "vkAllocateMemory"))) orelse return error.FunctionNotFound,
            .vkAllocateDescriptorSets = @as(c.PFN_vkAllocateDescriptorSets, @ptrCast(vkGetDeviceProcAddr(device, "vkAllocateDescriptorSets"))) orelse return error.FunctionNotFound,
            .vkGetDeviceQueue = @as(c.PFN_vkGetDeviceQueue, @ptrCast(vkGetDeviceProcAddr(device, "vkGetDeviceQueue"))) orelse return error.FunctionNotFound,
            .vkQueueSubmit = @as(c.PFN_vkQueueSubmit, @ptrCast(vkGetDeviceProcAddr(device, "vkQueueSubmit"))) orelse return error.FunctionNotFound,
            .vkQueuePresentKHR = @as(c.PFN_vkQueuePresentKHR, @ptrCast(vkGetDeviceProcAddr(device, "vkQueuePresentKHR"))) orelse return error.FunctionNotFound,
            .vkQueueWaitIdle = @as(c.PFN_vkQueueWaitIdle, @ptrCast(vkGetDeviceProcAddr(device, "vkQueueWaitIdle"))) orelse return error.FunctionNotFound,
            .vkGetSwapchainImagesKHR = @as(c.PFN_vkGetSwapchainImagesKHR, @ptrCast(vkGetDeviceProcAddr(device, "vkGetSwapchainImagesKHR"))) orelse return error.FunctionNotFound,
            .vkGetImageMemoryRequirements = @as(c.PFN_vkGetImageMemoryRequirements, @ptrCast(vkGetDeviceProcAddr(device, "vkGetImageMemoryRequirements"))) orelse return error.FunctionNotFound,
            .vkGetBufferMemoryRequirements = @as(c.PFN_vkGetBufferMemoryRequirements, @ptrCast(vkGetDeviceProcAddr(device, "vkGetBufferMemoryRequirements"))) orelse return error.FunctionNotFound,
            .vkBindBufferMemory = @as(c.PFN_vkBindBufferMemory, @ptrCast(vkGetDeviceProcAddr(device, "vkBindBufferMemory"))) orelse return error.FunctionNotFound,
            .vkBindImageMemory = @as(c.PFN_vkBindImageMemory, @ptrCast(vkGetDeviceProcAddr(device, "vkBindImageMemory"))) orelse return error.FunctionNotFound,
            .vkAcquireNextImageKHR = @as(c.PFN_vkAcquireNextImageKHR, @ptrCast(vkGetDeviceProcAddr(device, "vkAcquireNextImageKHR"))) orelse return error.FunctionNotFound,
            .vkWaitForFences = @as(c.PFN_vkWaitForFences, @ptrCast(vkGetDeviceProcAddr(device, "vkWaitForFences"))) orelse return error.FunctionNotFound,
            .vkResetFences = @as(c.PFN_vkResetFences, @ptrCast(vkGetDeviceProcAddr(device, "vkResetFences"))) orelse return error.FunctionNotFound,
            .vkCreateSwapchainKHR = @as(c.PFN_vkCreateSwapchainKHR, @ptrCast(vkGetDeviceProcAddr(device, "vkCreateSwapchainKHR"))) orelse return error.FunctionNotFound,
            .vkCreateImage = @as(c.PFN_vkCreateImage, @ptrCast(vkGetDeviceProcAddr(device, "vkCreateImage"))) orelse return error.FunctionNotFound,
            .vkCreateImageView = @as(c.PFN_vkCreateImageView, @ptrCast(vkGetDeviceProcAddr(device, "vkCreateImageView"))) orelse return error.FunctionNotFound,
            .vkCreateShaderModule = @as(c.PFN_vkCreateShaderModule, @ptrCast(vkGetDeviceProcAddr(device, "vkCreateShaderModule"))) orelse return error.FunctionNotFound,
            .vkCreatePipelineLayout = @as(c.PFN_vkCreatePipelineLayout, @ptrCast(vkGetDeviceProcAddr(device, "vkCreatePipelineLayout"))) orelse return error.FunctionNotFound,
            .vkCreateRenderPass = @as(c.PFN_vkCreateRenderPass, @ptrCast(vkGetDeviceProcAddr(device, "vkCreateRenderPass"))) orelse return error.FunctionNotFound,
            .vkCreateGraphicsPipelines = @as(c.PFN_vkCreateGraphicsPipelines, @ptrCast(vkGetDeviceProcAddr(device, "vkCreateGraphicsPipelines"))) orelse return error.FunctionNotFound,
            .vkCreateFramebuffer = @as(c.PFN_vkCreateFramebuffer, @ptrCast(vkGetDeviceProcAddr(device, "vkCreateFramebuffer"))) orelse return error.FunctionNotFound,
            .vkCreateCommandPool = @as(c.PFN_vkCreateCommandPool, @ptrCast(vkGetDeviceProcAddr(device, "vkCreateCommandPool"))) orelse return error.FunctionNotFound,
            .vkCreateSemaphore = @as(c.PFN_vkCreateSemaphore, @ptrCast(vkGetDeviceProcAddr(device, "vkCreateSemaphore"))) orelse return error.FunctionNotFound,
            .vkCreateFence = @as(c.PFN_vkCreateFence, @ptrCast(vkGetDeviceProcAddr(device, "vkCreateFence"))) orelse return error.FunctionNotFound,
            .vkCreateBuffer = @as(c.PFN_vkCreateBuffer, @ptrCast(vkGetDeviceProcAddr(device, "vkCreateBuffer"))) orelse return error.FunctionNotFound,
            .vkCreateSampler = @as(c.PFN_vkCreateSampler, @ptrCast(vkGetDeviceProcAddr(device, "vkCreateSampler"))) orelse return error.FunctionNotFound,
            .vkDestroySampler = @as(c.PFN_vkDestroySampler, @ptrCast(vkGetDeviceProcAddr(device, "vkDestroySampler"))) orelse return error.FunctionNotFound,
            .vkCreateDescriptorSetLayout = @as(c.PFN_vkCreateDescriptorSetLayout, @ptrCast(vkGetDeviceProcAddr(device, "vkCreateDescriptorSetLayout"))) orelse return error.FunctionNotFound,
            .vkDestroyCommandPool = @as(c.PFN_vkDestroyCommandPool, @ptrCast(vkGetDeviceProcAddr(device, "vkDestroyCommandPool"))) orelse return error.FunctionNotFound,
            .vkCreateDescriptorPool = @as(c.PFN_vkCreateDescriptorPool, @ptrCast(vkGetDeviceProcAddr(device, "vkCreateDescriptorPool"))) orelse return error.FunctionNotFound,
            .vkDestroyPipeline = @as(c.PFN_vkDestroyPipeline, @ptrCast(vkGetDeviceProcAddr(device, "vkDestroyPipeline"))) orelse return error.FunctionNotFound,
            .vkDestroyPipelineLayout = @as(c.PFN_vkDestroyPipelineLayout, @ptrCast(vkGetDeviceProcAddr(device, "vkDestroyPipelineLayout"))) orelse return error.FunctionNotFound,
            .vkDestroyRenderPass = @as(c.PFN_vkDestroyRenderPass, @ptrCast(vkGetDeviceProcAddr(device, "vkDestroyRenderPass"))) orelse return error.FunctionNotFound,
            .vkDestroySwapchainKHR = @as(c.PFN_vkDestroySwapchainKHR, @ptrCast(vkGetDeviceProcAddr(device, "vkDestroySwapchainKHR"))) orelse return error.FunctionNotFound,
            .vkDestroyImage = @as(c.PFN_vkDestroyImage, @ptrCast(vkGetDeviceProcAddr(device, "vkDestroyImage"))) orelse return error.FunctionNotFound,
            .vkDestroyImageView = @as(c.PFN_vkDestroyImageView, @ptrCast(vkGetDeviceProcAddr(device, "vkDestroyImageView"))) orelse return error.FunctionNotFound,
            .vkDestroyShaderModule = @as(c.PFN_vkDestroyShaderModule, @ptrCast(vkGetDeviceProcAddr(device, "vkDestroyShaderModule"))) orelse return error.FunctionNotFound,
            .vkDestroySemaphore = @as(c.PFN_vkDestroySemaphore, @ptrCast(vkGetDeviceProcAddr(device, "vkDestroySemaphore"))) orelse return error.FunctionNotFound,
            .vkDestroyFence = @as(c.PFN_vkDestroyFence, @ptrCast(vkGetDeviceProcAddr(device, "vkDestroyFence"))) orelse return error.FunctionNotFound,
            .vkDestroyFramebuffer = @as(c.PFN_vkDestroyFramebuffer, @ptrCast(vkGetDeviceProcAddr(device, "vkDestroyFramebuffer"))) orelse return error.FunctionNotFound,
            .vkDestroyBuffer = @as(c.PFN_vkDestroyBuffer, @ptrCast(vkGetDeviceProcAddr(device, "vkDestroyBuffer"))) orelse return error.FunctionNotFound,
            .vkDestroyDescriptorSetLayout = @as(c.PFN_vkDestroyDescriptorSetLayout, @ptrCast(vkGetDeviceProcAddr(device, "vkDestroyDescriptorSetLayout"))) orelse return error.FunctionNotFound,
            .vkDestroyDescriptorPool = @as(c.PFN_vkDestroyDescriptorPool, @ptrCast(vkGetDeviceProcAddr(device, "vkDestroyDescriptorPool"))) orelse return error.FunctionNotFound,
            .vkBeginCommandBuffer = @as(c.PFN_vkBeginCommandBuffer, @ptrCast(vkGetDeviceProcAddr(device, "vkBeginCommandBuffer"))) orelse return error.FunctionNotFound,
            .vkCmdBeginRenderPass = @as(c.PFN_vkCmdBeginRenderPass, @ptrCast(vkGetDeviceProcAddr(device, "vkCmdBeginRenderPass"))) orelse return error.FunctionNotFound,
            .vkCmdBindPipeline = @as(c.PFN_vkCmdBindPipeline, @ptrCast(vkGetDeviceProcAddr(device, "vkCmdBindPipeline"))) orelse return error.FunctionNotFound,
            .vkCmdBindVertexBuffers = @as(c.PFN_vkCmdBindVertexBuffers, @ptrCast(vkGetDeviceProcAddr(device, "vkCmdBindVertexBuffers"))) orelse return error.FunctionNotFound,
            .vkCmdBindIndexBuffer = @as(c.PFN_vkCmdBindIndexBuffer, @ptrCast(vkGetDeviceProcAddr(device, "vkCmdBindIndexBuffer"))) orelse return error.FunctionNotFound,
            .vkCmdSetViewport = @as(c.PFN_vkCmdSetViewport, @ptrCast(vkGetDeviceProcAddr(device, "vkCmdSetViewport"))) orelse return error.FunctionNotFound,
            .vkCmdSetScissor = @as(c.PFN_vkCmdSetScissor, @ptrCast(vkGetDeviceProcAddr(device, "vkCmdSetScissor"))) orelse return error.FunctionNotFound,
            .vkCmdDraw = @as(c.PFN_vkCmdDraw, @ptrCast(vkGetDeviceProcAddr(device, "vkCmdDraw"))) orelse return error.FunctionNotFound,
            .vkCmdDrawIndexed = @as(c.PFN_vkCmdDrawIndexed, @ptrCast(vkGetDeviceProcAddr(device, "vkCmdDrawIndexed"))) orelse return error.FunctionNotFound,
            .vkCmdCopyBuffer = @as(c.PFN_vkCmdCopyBuffer, @ptrCast(vkGetDeviceProcAddr(device, "vkCmdCopyBuffer"))) orelse return error.FunctionNotFound,
            .vkCmdCopyBufferToImage = @as(c.PFN_vkCmdCopyBufferToImage, @ptrCast(vkGetDeviceProcAddr(device, "vkCmdCopyBufferToImage"))) orelse return error.FunctionNotFound,
            .vkCmdPushConstants = @as(c.PFN_vkCmdPushConstants, @ptrCast(vkGetDeviceProcAddr(device, "vkCmdPushConstants"))) orelse return error.FunctionNotFound,
            .vkCmdPipelineBarrier = @as(c.PFN_vkCmdPipelineBarrier, @ptrCast(vkGetDeviceProcAddr(device, "vkCmdPipelineBarrier"))) orelse return error.FunctionNotFound,
            .vkUpdateDescriptorSets = @as(c.PFN_vkUpdateDescriptorSets, @ptrCast(vkGetDeviceProcAddr(device, "vkUpdateDescriptorSets"))) orelse return error.FunctionNotFound,
            .vkCmdBindDescriptorSets = @as(c.PFN_vkCmdBindDescriptorSets, @ptrCast(vkGetDeviceProcAddr(device, "vkCmdBindDescriptorSets"))) orelse return error.FunctionNotFound,
            .vkCmdEndRenderPass = @as(c.PFN_vkCmdEndRenderPass, @ptrCast(vkGetDeviceProcAddr(device, "vkCmdEndRenderPass"))) orelse return error.FunctionNotFound,
            .vkEndCommandBuffer = @as(c.PFN_vkEndCommandBuffer, @ptrCast(vkGetDeviceProcAddr(device, "vkEndCommandBuffer"))) orelse return error.FunctionNotFound,
            .vkResetCommandBuffer = @as(c.PFN_vkResetCommandBuffer, @ptrCast(vkGetDeviceProcAddr(device, "vkResetCommandBuffer"))) orelse return error.FunctionNotFound,
            .vkFreeMemory = @as(c.PFN_vkFreeMemory, @ptrCast(vkGetDeviceProcAddr(device, "vkFreeMemory"))) orelse return error.FunctionNotFound,
            .vkFreeCommandBuffers = @as(c.PFN_vkFreeCommandBuffers, @ptrCast(vkGetDeviceProcAddr(device, "vkFreeCommandBuffers"))) orelse return error.FunctionNotFound,
            .vkFreeDescriptorSets = @as(c.PFN_vkFreeDescriptorSets, @ptrCast(vkGetDeviceProcAddr(device, "vkFreeDescriptorSets"))) orelse return error.FunctionNotFound,
            .vkMapMemory = @as(c.PFN_vkMapMemory, @ptrCast(vkGetDeviceProcAddr(device, "vkMapMemory"))) orelse return error.FunctionNotFound,
            .vkUnmapMemory = @as(c.PFN_vkUnmapMemory, @ptrCast(vkGetDeviceProcAddr(device, "vkUnmapMemory"))) orelse return error.FunctionNotFound,
            .vkDestroyDevice = @as(c.PFN_vkDestroyDevice, @ptrCast(vkGetDeviceProcAddr(device, "vkDestroyDevice"))) orelse return error.FunctionNotFound,
        };
    }
};

pub const Device = struct {
    handle: c.VkDevice,
    queues: [4]c.VkQueue,
    physical_device: PhysicalDevice,
    dispatch: Dispatch,

    pub fn init(instance: *const Instance) !Device {
        var device: Device = undefined;

        var count: u32 = 0;

        try check(instance.dispatch.vkEnumeratePhysicalDevices(instance.handle, &count, null));
        var physical_devices: [5]c.VkPhysicalDevice = undefined;
        try check(instance.dispatch.vkEnumeratePhysicalDevices(instance.handle, &count, &physical_devices));

        const required_extensions = [_][*:0]const u8{ c.VK_KHR_SWAPCHAIN_EXTENSION_NAME };

        device.physical_device.valuation = 0;

        for (0..count) |i| {
            const new_physical_device = PhysicalDevice.init(
                instance,
                physical_devices[i],
                &required_extensions,
            ) catch continue;

            device.physical_device.copy_if_better(&new_physical_device);
        }

        if (!device.physical_device.valid()) return error.InvalidPhysicalDevice;

        var queue_count: u32 = 0;
        var last_value: u32 = 0xFF;
        var queue_infos: [4]c.VkDeviceQueueCreateInfo = undefined;

        for (device.physical_device.families) |family| {
            if (family != last_value) {
                last_value = family;
                queue_infos[queue_count] = .{
                    .sType = c.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
                    .queueFamilyIndex = family,
                    .queueCount = 1,
                    .pQueuePriorities = &[_]f32 { 1.0 },
                };

                queue_count += 1;
            }
        }

        const info = c.VkDeviceCreateInfo {
            .sType = c.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
            .queueCreateInfoCount = queue_count,
            .pQueueCreateInfos = &queue_infos[0],
            .pEnabledFeatures = &device.physical_device.features,
            .enabledExtensionCount = @intCast(required_extensions.len),
            .ppEnabledExtensionNames = &required_extensions[0],
        };

        try check(instance.dispatch.vkCreateDevice(device.physical_device.handle, &info, null, &device.handle));

        device.dispatch = try Dispatch.init(device.handle, instance);

        for (0..4) |i| {
            device.dispatch.vkGetDeviceQueue(device.handle, device.physical_device.families[i], 0, &device.queues[i]);
        }

        return device;
    }

    pub fn allocate_memory(
        self: *const Device,
        properties: u32,
        requirements: *const c.VkMemoryRequirements
    ) !c.VkDeviceMemory {
        var index: u32 = 0;

        for (0..self.physical_device.memory_properties.memoryTypeCount) |i| {
            const a: u5 = @intCast(i);
            const b: u32 = 1;

            if ((requirements.memoryTypeBits & (b << a)) > 0 and (self.physical_device.memory_properties.memoryTypes[i].propertyFlags & properties) == properties) {
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
        try check(self.dispatch.vkAllocateMemory(self.handle, &alloc_info, null, &memory));

        return memory;
    }

    pub fn deinit(self: *const Device) void {
        self.dispatch.vkDestroyDevice(self.handle, null);
    }
};

const GpuType = enum {
    Discrete,
    Integrated,
    Virtual,
    Cpu,
    Other,

    fn init(n: u32) GpuType {
        return switch (n) {
            1 => GpuType.Integrated,
            2 => GpuType.Discrete,
            3 => GpuType.Virtual,
            4 => GpuType.Cpu,
            else => GpuType.Other,
        };
    }

    fn valuate(self: *const GpuType) u32 {
        return switch (self.*) {
            GpuType.Discrete => 4,
            GpuType.Integrated => 3,
            GpuType.Virtual => 2,
            GpuType.Cpu => 1,
            GpuType.Other => 0,
        };
    }
};

const PhysicalDevice = struct {
    handle: c.VkPhysicalDevice,
    families: [4]u8,
    valuation: u32,
    features: c.VkPhysicalDeviceFeatures,
    memory_properties: c.VkPhysicalDeviceMemoryProperties,

    fn init(
        instance: *const Instance,
        handle: c.VkPhysicalDevice,
        required_extensions: []const [*:0]const u8,
    ) !PhysicalDevice {
        {
            var count: u32 = 0;
            var properties: [200]c.VkExtensionProperties = undefined;
            try check(instance.dispatch.vkEnumerateDeviceExtensionProperties(handle, null, &count, null));
            try check(instance.dispatch.vkEnumerateDeviceExtensionProperties(handle, null, &count, &properties));

            var has_all_extensions = false;

            for (required_extensions) |extension| {
                has_all_extensions = false;

                for (properties) |property| {
                    if (std.mem.eql(u8, std.mem.span(extension), std.mem.sliceTo(&property.extensionName, 0))) break;
                } else continue;

                has_all_extensions = true;
            }

            if (!has_all_extensions) return error.MissingExtension;
        }

        {
            var count: u32 = 0;
            try check(instance.dispatch.vkGetPhysicalDeviceSurfaceFormatsKHR(handle, instance.surface, &count, null));
            if (count == 0) return error.MissingFeature;
        }

        {
            var count: u32 = 0;
            try check(instance.dispatch.vkGetPhysicalDeviceSurfacePresentModesKHR(handle, instance.surface, &count, null));
            if (count == 0) return error.MissingFeature;
        }

        var families: [4]u8 = .{ 0xFF, 0xFF, 0xFF, 0xFF };
        {
            var count: u32 = 0;

            var properties: [10]c.VkQueueFamilyProperties = undefined;
            instance.dispatch.vkGetPhysicalDeviceQueueFamilyProperties(handle, &count, null);
            instance.dispatch.vkGetPhysicalDeviceQueueFamilyProperties(handle, &count, &properties);

            for (0..count) |i| {
                const family: u8 = @intCast(i);
                const index: u32 = @intCast(i);

                var surface_support: u32 = 0;
                try check(instance.dispatch.vkGetPhysicalDeviceSurfaceSupportKHR(handle, index, instance.surface, &surface_support));

                if (families[0] == 0xFF and properties[i].queueFlags & c.VK_QUEUE_GRAPHICS_BIT != 0) families[0] = family;
                if (families[1] == 0xFF and surface_support != 0) families[1] = family;
                if (families[2] == 0xFF and properties[i].queueFlags & c.VK_QUEUE_COMPUTE_BIT != 0) families[2] = family;
                if (families[3] == 0xFF and properties[i].queueFlags & c.VK_QUEUE_TRANSFER_BIT != 0) families[3] = family;
            }

            for (families) |f| if (f == 0xFF) return error.MissingFeature;
        }

        var features: c.VkPhysicalDeviceFeatures = undefined;
        {
            instance.dispatch.vkGetPhysicalDeviceFeatures(handle, &features);
            if (features.geometryShader != 1 or features.samplerAnisotropy != 1) return error.MissingFeature;
        }

        const valuation = blk: {
            var device_properties: c.VkPhysicalDeviceProperties = undefined;
            instance.dispatch.vkGetPhysicalDeviceProperties(handle, &device_properties);
            const typ = GpuType.init(device_properties.deviceType);

            break :blk typ.valuate();
        };

        var memory_properties: c.VkPhysicalDeviceMemoryProperties = undefined;
        {
            instance.dispatch.vkGetPhysicalDeviceMemoryProperties(handle, &memory_properties);
        }

        return PhysicalDevice {
            .handle = handle,
            .families = families,
            .valuation = valuation,
            .features = features,
            .memory_properties = memory_properties,
        };
    }

    fn copy_if_better(self: *PhysicalDevice, other: *const PhysicalDevice) void {
        if (other.valuation > self.valuation) {
            self.* = other.*;
        }
    }

    fn valid(self: *const PhysicalDevice) bool {
        return self.valuation != 0;
    }
};
