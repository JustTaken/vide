const std = @import("std");
const c = @import("../bind.zig").c;
const truetype = @import("../font/core.zig");
const wayland = @import("../wayland/core.zig");
const math = @import("../math.zig");

const Window = wayland.Wayland;
const Font = truetype.TrueType;

var ARENA = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const ALLOCATOR = ARENA.allocator();












pub fn sync(device: *const DeviceDispatch, swapchain: *const Swapchain) void {
    std.time.sleep(1000000 * 20);
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

    update_painter_plain_elements(device, painter, window);
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
    device.vkCmdBindDescriptorSets(command_buffer, c.VK_PIPELINE_BIND_POINT_GRAPHICS, graphics_pipeline.layout, 0, 2, &.{ painter.uniform.set, painter.char_texture_descriptor.set }, 0, &0);
    device.vkCmdBindIndexBuffer(command_buffer, painter.index_buffer.handle, 0, c.VK_INDEX_TYPE_UINT16);

    for (0..CHAR_COUNT) |i| {
        const len: u32 = @intCast(painter.chars[i].dst.len);
        if (len == 0) continue;

        const vertex_offsets = &[_]u64 { @sizeOf(f32) * 4 * 2 * i, 0 };
        const vertex_buffers = &[_]c.VkBuffer { painter.char_coords.handle, painter.chars[i].positions.handle };

        device.vkCmdBindVertexBuffers(command_buffer, 0, vertex_buffers.len, &vertex_buffers[0], &vertex_offsets[0]);
        device.vkCmdDrawIndexed(command_buffer, 6, len, 0, 0, 0);
    }

    const vertex_offsets = &[_]u64 { 0, 0 };
    const vertex_buffers = &[_]c.VkBuffer { painter.general_coords.handle, painter.plain_elements.positions.handle };

    device.vkCmdBindDescriptorSets(command_buffer, c.VK_PIPELINE_BIND_POINT_GRAPHICS, graphics_pipeline.layout, 0, 2, &.{ painter.uniform.set, painter.general_texture_descriptor.set }, 0, &0);
    device.vkCmdBindVertexBuffers(command_buffer, 0, vertex_buffers.len, &vertex_buffers[0], &vertex_offsets[0]);
    device.vkCmdDrawIndexed(command_buffer, 6, @intCast(painter.plain_elements.dst.len), 0, 0, 0);

    device.vkCmdEndRenderPass(command_buffer);
    _ = device.vkEndCommandBuffer(command_buffer);
}








fn texture_descriptor_deinit(device: *const DeviceDispatch, texture_descriptor: *const TextureDescriptor) void {
    device.vkDestroySampler(device.handle, texture_descriptor.sampler, null);
}



pub fn device_deinit(device: *const DeviceDispatch) void {
    device.vkDestroyDevice(device.handle, null);
}
