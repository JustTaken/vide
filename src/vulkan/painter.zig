const c = @import("../bind.zig").c;
const std = @import("std");
const check = @import("result.zig").check;
const math = @import("../math.zig");

const CHAR_COUNT: u32 = 95;

const Device = @import("device.zig").Device;
const Swapchain = @import("swapchain.zig").Swapchain;
const Buffer = @import("buffer.zig").Buffer;
const Uniform = @import("buffer.zig").Uniform;
const Vec = @import("buffer.zig").Vec;
const Texture = @import("image.zig").Texture;
const GraphicsPipeline = @import("graphics_pipeline.zig").GraphicsPipeline;
const CommandPool = @import("command_pool.zig").CommandPool;
const Font = @import("../truetype.zig").TrueType;

const WindowBuffer = @import("../window/buffer.zig").Buffer;
const ResizeListener = @import("../window/core.zig").ResizeListener;

const Allocator = std.mem.Allocator;

const Size = @import("../math.zig").Vec2D;

pub const Painter = struct {
    swapchain: *Swapchain,
    graphics_pipeline: *const GraphicsPipeline,
    command_pool: *const CommandPool,

    index: Buffer,
    uniform: Uniform,

    vertices: []Vec([5]u32),

    coords: Buffer,
    font_atlas: Texture,
    general_texture: Texture,

    allocator: Allocator,

    pub fn init(
        swapchain: *Swapchain,
        graphics_pipeline: *const GraphicsPipeline,
        command_pool: *const CommandPool,
        font: *const Font,
        size: Size,
        allocator: Allocator,
    ) !Painter {
        var painter: Painter = undefined;
        const device = swapchain.device;

        painter.graphics_pipeline = graphics_pipeline;
        painter.command_pool = command_pool;
        painter.swapchain = swapchain;

        const scale = math.divide(size.y, size.x);

        const uniform_data = [_]f32 { scale, font.scale, font.ratio };
        painter.uniform = try Uniform.init(
            f32,
            &uniform_data,
            0,
            graphics_pipeline.descriptors[0],
            device,
        );

        var coords: [CHAR_COUNT + 1][4][2]f32 = undefined;
        painter.vertices = try allocator.alloc(Vec([5]u32), CHAR_COUNT + 1);
        painter.allocator = allocator;

        {
            coords[0] = .{
                .{ 0.0, 0.0 },
                .{ 1.0, 0.0 },
                .{ 0.0, 1.0 },
                .{ 1.0, 1.0 },
            };

            painter.vertices[0] = try Vec([5]u32).init(
                c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
                c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
                10,
                device,
            );
        }

        {
            const glyph_width = font.normalized_width();
            const glyph_height = font.normalized_height();

            for (0..CHAR_COUNT) |i| {
                const offset = font.glyph_normalized_offset(i);

                coords[i + 1] = .{
                    .{ offset[0], offset[1] },
                    .{ offset[0] + glyph_width, offset[1] },
                    .{ offset[0], offset[1] + glyph_height},
                    .{ offset[0] + glyph_width, offset[1] + glyph_height },
                };

                painter.vertices[i + 1] = try Vec([5]u32).init(
                    c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
                    c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
                    10,
                    device,
                );
            }
        }

        painter.coords = try Buffer.with_data(
            [4][2]f32,
            &coords,
            c.VK_BUFFER_USAGE_TRANSFER_DST_BIT | c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
            c.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
            device,
            command_pool,
        );

        const indices = [_]u16 { 0, 1, 2, 1, 3, 2 };
        painter.index = try Buffer.with_data(
            u16,
            &indices,
            c.VK_BUFFER_USAGE_TRANSFER_DST_BIT | c.VK_BUFFER_USAGE_INDEX_BUFFER_BIT,
            c.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
            device,
            command_pool,
        );

        painter.font_atlas = try Texture.init(
            font.bitmap.handle,
            c.VK_FORMAT_R8_UNORM,
            font.bitmap.size,
            device,
            command_pool,
            graphics_pipeline,
        );

        const general_elements_texture = [_]u8 { 100 } ** 256;
        painter.general_texture = try Texture.init(
            &general_elements_texture,
            c.VK_FORMAT_R8_UNORM,
            Size.init(16, 16),
            device,
            command_pool,
            graphics_pipeline,
        );

        return painter;
    }

    fn on_char(self: *Painter, char: u8, col: usize, row: usize) !void {
        const code = char - 32;
        if (code == 0) return;

        const j: u32 = @intCast(col);
        const i: u32 = @intCast(row);

        try self.vertices[code + 1].push(
            .{ j, i, 255, 255, 255 },
            self.swapchain.device,
        );
    }

    fn on_back(self: *Painter, col: usize, row: usize) !void {
        const j: u32 = @intCast(col);
        const i: u32 = @intCast(row);

        try self.vertices[0].push(
            .{ j, i, 255, 255, 255 },
            self.swapchain.device,
        );
    }

    pub fn update(self: *Painter, buffer: *const WindowBuffer) !void {
        for (self.vertices) |*v| {
            v.reset();
        }

        try buffer.char_iter(Painter, self, on_char);
        try buffer.back_iter(Painter, self, on_back);
    }

    pub fn draw(self: *const Painter) !void {
        if (!self.swapchain.valid) return error.InvalidSwapchain;

        const start = try std.time.Instant.now();
        const index = try self.swapchain.image_index();
        const device = self.swapchain.device;

        try self.record_draw(index);
        try check(device.dispatch.vkResetFences(device.handle, 1, &self.swapchain.in_flight));

        const wait_dst_stage: u32 = c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
        const submit_info = c.VkSubmitInfo {
            .sType = c.VK_STRUCTURE_TYPE_SUBMIT_INFO,
            .waitSemaphoreCount = 1,
            .pWaitSemaphores = &self.swapchain.image_available,
            .pWaitDstStageMask = &wait_dst_stage,
            .commandBufferCount = 1,
            .pCommandBuffers = &self.command_pool.buffers[index],
            .signalSemaphoreCount = 1,
            .pSignalSemaphores = &self.swapchain.render_finished,
        };

        try check(device.dispatch.vkQueueSubmit(device.queues[0], 1, &submit_info, self.swapchain.in_flight));

        const present_info = c.VkPresentInfoKHR {
            .sType = c.VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
            .swapchainCount = 1,
            .pSwapchains = &self.swapchain.handle,
            .waitSemaphoreCount = 1,
            .pWaitSemaphores = &self.swapchain.render_finished,
            .pImageIndices = &index,
        };

        try check(device.dispatch.vkQueuePresentKHR(device.queues[1], &present_info));

        const end = try std.time.Instant.now();
        std.debug.print("time for draw frame: {} ns\n", .{end.since(start)});
    }

    fn record_draw(self: *const Painter, index: u32) !void {
        const command_buffer = self.command_pool.buffers[index];
        const framebuffer = self.swapchain.framebuffers[index];
        const device = self.swapchain.device;

        const size = self.swapchain.size;

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
            .renderPass = self.swapchain.render_pass,
            .framebuffer = framebuffer,
            .renderArea = c.VkRect2D {
                .offset = c.VkOffset2D {
                    .x = 0,
                    .y = 0,
                },
                .extent = c.VkExtent2D {
                    .width = size.x,
                    .height = size.y,
                },
            },
            .pClearValues = &clear_value,
            .clearValueCount = 1,
        };

        const viewport = c.VkViewport {
            .x = 0.0,
            .y = 0.0,
            .width = @floatFromInt(size.x),
            .height = @floatFromInt(size.y),
            .minDepth = 0.0,
            .maxDepth = 1.0,
        };

        const scissor = c.VkRect2D {
            .offset = c.VkOffset2D {
                .x = 0,
                .y = 0,
            },
            .extent = c.VkExtent2D {
                .width = size.x,
                .height = size.y,
            },
        };

        try check(device.dispatch.vkBeginCommandBuffer(command_buffer, &begin_info));

        device.dispatch.vkCmdBeginRenderPass(command_buffer, &render_pass_info, c.VK_SUBPASS_CONTENTS_INLINE);
        device.dispatch.vkCmdSetViewport(command_buffer, 0, 1, &viewport);
        device.dispatch.vkCmdSetScissor(command_buffer, 0, 1, &scissor);
        device.dispatch.vkCmdBindPipeline(command_buffer, c.VK_PIPELINE_BIND_POINT_GRAPHICS, self.graphics_pipeline.handle);
        device.dispatch.vkCmdBindIndexBuffer(command_buffer, self.index.handle, 0, c.VK_INDEX_TYPE_UINT16);
        device.dispatch.vkCmdBindDescriptorSets(command_buffer, c.VK_PIPELINE_BIND_POINT_GRAPHICS, self.graphics_pipeline.layout, 0, 1, &.{ self.uniform.set.handle }, 0, &0);

        {
            const vertex_offsets = &[_]u64 { 0, 0 };
            const vertex_buffers = &[_]c.VkBuffer { self.coords.handle, self.vertices[0].buffer.handle };

            device.dispatch.vkCmdBindDescriptorSets(command_buffer, c.VK_PIPELINE_BIND_POINT_GRAPHICS, self.graphics_pipeline.layout, 1, 1, &.{ self.general_texture.set.handle }, 0, &0);
            device.dispatch.vkCmdBindVertexBuffers(command_buffer, 0, vertex_buffers.len, &vertex_buffers[0], &vertex_offsets[0]);
            device.dispatch.vkCmdDrawIndexed(command_buffer, 6, self.vertices[0].len(), 0, 0, 0);
        }

        {
            device.dispatch.vkCmdBindDescriptorSets(command_buffer, c.VK_PIPELINE_BIND_POINT_GRAPHICS, self.graphics_pipeline.layout, 1, 1, &.{ self.font_atlas.set.handle }, 0, &0);

            for (0..CHAR_COUNT) |i| {
                const len = self.vertices[i + 1].len();
                if (len == 0) continue;

                const vertex_offsets = &[_]u64 { @sizeOf(f32) * 4 * 2 * (i + 1), 0 };
                const vertex_buffers = &[_]c.VkBuffer { self.coords.handle, self.vertices[i + 1].buffer.handle };

                device.dispatch.vkCmdBindVertexBuffers(command_buffer, 0, vertex_buffers.len, &vertex_buffers[0], &vertex_offsets[0]);
                device.dispatch.vkCmdDrawIndexed(command_buffer, 6, len, 0, 0, 0);
            }
        }

        device.dispatch.vkCmdEndRenderPass(command_buffer);
        try check(device.dispatch.vkEndCommandBuffer(command_buffer));
    }

    fn resize(ptr: *anyopaque, size: *const Size) void {
        const self: *Painter = @ptrCast(@alignCast(ptr));

        self.uniform.dst[0] = math.divide(size.y, size.x);
    }

    pub fn resize_listener(self: *Painter) ResizeListener {
        return ResizeListener {
            .f = resize,
            .ptr = self,
        };
    }

    pub fn deinit(self: *const Painter) void {
        const device = self.swapchain.device;
        self.font_atlas.deinit(device);
        self.general_texture.deinit(device);

        self.uniform.deinit(device);
        self.coords.deinit(device);
        self.index.deinit(device);

        for (self.vertices) |v| {
            v.deinit(device);
        }

        self.allocator.free(self.vertices);
    }
};
