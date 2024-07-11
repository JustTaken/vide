const c = @import("../bind.zig").c;
const std = @import("std");
const check = @import("result.zig").check;

const CHAR_COUNT: u32 = 95;

const Device = @import("device.zig").Device;
const Allocator = std.mem.Allocator;
const Buffer = @import("buffer.zig").Buffer;
const Uniform = @import("buffer.zig").Uniform;
const Vec = @import("buffer.zig").Vec;
const Texture = @import("image.zig").Texture;
const GraphicsPipeline = @import("graphics_pipeline.zig").GraphicsPipeline;
const CommandPool = @import("command_pool.zig").CommandPool;
const Font = @import("../truetype.zig").TrueType;

const Size = @import("../math.zig").Vec2D;

pub const Painter = struct {
    index: Buffer,
    uniform: Uniform,

    vertices: []Vec([5]u32),

    coords: Buffer,
    font_atlas: Texture,
    general_texture: Texture,

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

        const uniform_data = [_]f32 { scale, font.scale, font.x_ratio };
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

    fn update(
        self: *Painter,
        lines: ?[]const []const u8,
        general_elements: ?[]const [2]u32,
        device: *const Device
    ) !void {
        if (lines) |l| {
            for (l, 0..) |line, i| {
                for (line, 0..) |char, j| {
                    const code = char - 32;
                    if (code == 0) continue;

                    const row: u32 = @intCast(i);
                    const col: u32 = @intCast(j);

                    try self.vertices[code + 1].push(
                        .{ row, col, 255, 255, 255 },
                        device,
                    );
                }
            }
        }

        if (general_elements) |g| {
            for (g) |e| {
                try self.vertices[0].push(
                    .{ e[0], e[1], 255, 255, 255 },
                    device
                );
            }
        }

        // painter.general_elements.dst.len = 1;
        // const offset = wayland.get_offset(window);

        // if (wayland.is_selection_active(window)) {
        //     const lines = wayland.get_selected_lines(window);
        //     const selection_boundary = wayland.get_selection_boundary(window);

        //     const len = selection_boundary[1].y + 1 - selection_boundary[0].y;
        //     const cols = window.cols - 1;
        //     const position_count: u32 = len * cols;

        //     if (painter.general_elements.capacity <= position_count + 1) {
        //         try check(device.vkUnmapMemory(device.handle, painter.general_elements.positions.memory));
        //         buffer_deinit(device, &painter.general_elements.positions);

        //         painter.general_elements.positions = buffer_init(
        //             [5]u32,
        //             device,
        //             c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
        //             c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
        //             position_count,
        //         );

        //         painter.general_elements.capacity = position_count;
        //         try check(device.vkMapMemory(device.handle, painter.general_elements.positions.memory, 0, (1 + position_count) * @sizeOf([2]u32), 0, @ptrCast(&painter.general_elements.dst)));
        //     }

        //     var index: u32 = 1;
        //     for (0..len) |i| {
        //         const boundary: [2]u32 = condition: {
        //             if (i == 0) {
        //                 break :condition .{
        //                     math.max(offset[0], selection_boundary[0].x),
        //                     if (len == 1) selection_boundary[1].x else lines[selection_boundary[0].y].char_count,
        //                 };
        //             }
        //             if (i == len - 1) break :condition .{ math.max(0, offset[0]), selection_boundary[1].x };
        //             break :condition .{ math.max(0, offset[0]), lines[selection_boundary[0].y + i].char_count };
        //         };

        //         const diff = boundary[1] - boundary[0] + 1;
        //         painter.general_elements.dst.len += diff;

        //         const ii: u32 = @intCast(i);
        //         for (boundary[0]..boundary[1] + 1) |j| {
        //             const jj: u32 = @intCast(j);
        //             painter.general_elements.dst[index] = .{
        //                 jj - offset[0], ii + selection_boundary[0].y - offset[1],
        //                 0, 255, 255
        //             };

        //             index += 1;
        //         }
        //     }
        }

    //     const cursor_data = wayland.get_cursor_position(window);
    //     painter.general_elements.dst[0] = .{
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
