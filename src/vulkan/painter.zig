
const c = @import("../bind.zig");
const std = @import("std");
const check = @import("result.zig").check;

const CHAR_COUNT: u32 = 95;

const Device = @import("device.zig").Device;
const Allocator = std.mem.Allocator;
const Buffer = @import("buffer.zig").Buffer;
const Uniform = @import("buffer.zig").Uniform;
const Vec = @import("buffer.zig").Vec;
const Image = @import("image.zig").Image;
const Texture = @import("image.zig").Texture;
const TextureDescriptor = @import("image.zig").TextureDescriptor;
const GraphicsPipeline = @import("graphics_pipeline.zig").GraphicsPipeline;
const CommandPool = @import("command_pool.zig").CommandPool;
const Font = @import("../truetype.zig").TrueType;

const Size = @import("../math.zig").Vec2D;

pub const Painter = struct {
    index_buffer: Buffer,
    uniform: Uniform,

    char_coords: Buffer,
    chars: []Vec,
    char_texture: Image,
    char_texture_descriptor: TextureDescriptor,

    plain_elements: Vec([5]u32),

    general_coords: Buffer,
    general_texture: Image,
    general_texture_descriptor: TextureDescriptor,

    allocator: Allocator,

    pub fn init(
        device: *const Device,
        graphics_pipeline: *const GraphicsPipeline,
        command_pool: *const CommandPool,
        font: *const Font,
        scale: f32,

        allocator: Allocator,
    ) !Painter {
        var painter: Painter = undefined;

        const global_binding = 0;
        const uniform_data = [_]f32 { scale, font.scale, font.x_ratio };
        painter.uniform = Uniform.init(
            f32,
            device,
            &uniform_data,
            graphics_pipeline.global_pool,
            graphics_pipeline.global_layout,
            global_binding
        );

        const glyph_width = font.normalized_width();
        const glyph_height = font.normalized_height();

        var coords: [CHAR_COUNT][4][2]f32 = undefined;
        painter.chars = try allocator.alloc(Vec([5]u32), CHAR_COUNT);
        painter.allocator = allocator;

        for (0..CHAR_COUNT) |i| {
            const offset = font.glyph_normalized_offset(i);

            coords[i] = .{
                .{ offset[0], offset[1] },
                .{ offset[0] + glyph_width, offset[1] },
                .{ offset[0], offset[1] + glyph_height},
                .{ offset[0] + glyph_width, offset[1] + glyph_height },
            };

            painter.chars[i] = try Vec([5]u32).init(
                c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
                c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
                10,
                device,
            );
        }

        painter.plain_elements = try Vec([5]u32).init(
            c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
            c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
            10,
            device,
        );

        painter.char_coords = Buffer.with_data(
            [4][2]f32,
            coords,
            c.VK_BUFFER_USAGE_TRANSFER_DST_BIT | c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
            c.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
            device,
            command_pool,
        );

        const general_coords: [4][2]f32 = .{
            .{ 0.0, 0.0 },
            .{ 1.0, 0.0 },
            .{ 0.0, 1.0 },
            .{ 1.0, 1.0 },
        };

        painter.general_coords = try Buffer.with_data(
            [4][2]f32,
            &general_coords,
            c.VK_BUFFER_USAGE_TRANSFER_DST_BIT | c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
            c.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
            device,
            command_pool,
        );

        const indices = [_]u16 { 0, 1, 2, 1, 3, 2 };
        painter.index_buffer = Buffer.with_data(
            u16,
            &indices,
            c.VK_BUFFER_USAGE_TRANSFER_DST_BIT | c.VK_BUFFER_USAGE_INDEX_BUFFER_BIT,
            c.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
            device,
            command_pool,
        );

        painter.char_texture = Image.init(
            device,
            c.VK_FORMAT_R8_UNORM,
            c.VK_IMAGE_USAGE_TRANSFER_DST_BIT | c.VK_IMAGE_USAGE_SAMPLED_BIT,
            Size.init(font.bitmap.width, font.bitmap.height),
        );


        painter.general_texture = Image.init(
            device,
            c.VK_FORMAT_R8_UNORM,
            c.VK_IMAGE_USAGE_TRANSFER_DST_BIT | c.VK_IMAGE_USAGE_SAMPLED_BIT,
            Size.init(16, 16),
        );

        const plain_elements_texture = [_]u8 { 100 } ** 256;

        try painter.char_texture.copy_data(font.bitmap.handle, device, command_pool);
        try painter.general_texture.copy_data(&plain_elements_texture, device, command_pool);

        painter.char_texture_descriptor = try Texture.init(&painter.char_texture, device, graphics_pipeline);
        painter.general_texture_descriptor = try Texture.init(&painter.general_texture, device, graphics_pipeline);

        return painter;
    }

    // fn update(device: *const Device, painter: *Painter) void {
    //     painter.plain_elements.dst.len = 1;
    //     const offset = wayland.get_offset(window);

    //     if (wayland.is_selection_active(window)) {
    //         const lines = wayland.get_selected_lines(window);
    //         const selection_boundary = wayland.get_selection_boundary(window);

    //         const len = selection_boundary[1].y + 1 - selection_boundary[0].y;
    //         const cols = window.cols - 1;
    //         const position_count: u32 = len * cols;

    //         if (painter.plain_elements.capacity <= position_count + 1) {
    //             try check(device.vkUnmapMemory(device.handle, painter.plain_elements.positions.memory));
    //             buffer_deinit(device, &painter.plain_elements.positions);

    //             painter.plain_elements.positions = buffer_init(
    //                 [5]u32,
    //                 device,
    //                 c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
    //                 c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
    //                 position_count,
    //             );

    //             painter.plain_elements.capacity = position_count;
    //             try check(device.vkMapMemory(device.handle, painter.plain_elements.positions.memory, 0, (1 + position_count) * @sizeOf([2]u32), 0, @ptrCast(&painter.plain_elements.dst)));
    //         }

    //         var index: u32 = 1;
    //         for (0..len) |i| {
    //             const boundary: [2]u32 = condition: {
    //                 if (i == 0) {
    //                     break :condition .{
    //                         math.max(offset[0], selection_boundary[0].x),
    //                         if (len == 1) selection_boundary[1].x else lines[selection_boundary[0].y].char_count,
    //                     };
    //                 }
    //                 if (i == len - 1) break :condition .{ math.max(0, offset[0]), selection_boundary[1].x };
    //                 break :condition .{ math.max(0, offset[0]), lines[selection_boundary[0].y + i].char_count };
    //             };

    //             const diff = boundary[1] - boundary[0] + 1;
    //             painter.plain_elements.dst.len += diff;

    //             const ii: u32 = @intCast(i);
    //             for (boundary[0]..boundary[1] + 1) |j| {
    //                 const jj: u32 = @intCast(j);
    //                 painter.plain_elements.dst[index] = .{
    //                     jj - offset[0], ii + selection_boundary[0].y - offset[1],
    //                     0, 255, 255
    //                 };

    //                 index += 1;
    //             }
    //         }
    //     }

    //     const cursor_data = wayland.get_cursor_position(window);
    //     painter.plain_elements.dst[0] = .{
    //         cursor_data[0] - offset[0], cursor_data[1] - offset[1],
    //         255, 255, 255
    //     };
    // }

    // fn update_painter(device: *const Device, painter: *Painter) void {
    //     for (0..CHAR_COUNT) |i| {
    //         const data = wayland.get_char_data(window, i);
    //         const len: u32 = @intCast(data.pos.len);
    //         painter.chars[i].dst.len = len;

    //         if (len == 0) continue;
    //         if (painter.chars[i].capacity < len) {
    //             try check(device.vkUnmapMemory(device.handle, painter.chars[i].positions.memory));
    //             buffer_deinit(device, &painter.chars[i].positions);

    //             painter.chars[i].positions = buffer_init(
    //                 [5]u32,
    //                 device,
    //                 c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
    //                 c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
    //                 len,
    //             );

    //             painter.chars[i].capacity = len;
    //             try check(device.vkMapMemory(device.handle, painter.chars[i].positions.memory, 0, len * @sizeOf([5]u32), 0, @ptrCast(&painter.chars[i].dst)));
    //         }

    //         for (0..len) |k| {
    //             painter.chars[i].dst[k] = data.pos[k];
    //         }
    //     }
    // }

    pub fn deinit(self: *const Painter, device: *const Device) void {
        self.char_texture_descriptor.init(device);
        self.general_texture_descriptor.deinit(device);
        self.char_texture.deinit(device);
        self.general_texture.deinit(device);

        self.uniform.buffer.deinit(device);
        self.char_coords.deinit(device);
        self.general_coords.deinit(device);
        self.index_buffer.deinit(device);
        self.plain_elements.deinit(device);

        for (self.chars) |char| {
            char.deinit();
        }

        self.allocator.free(self.chars);
    }
};
