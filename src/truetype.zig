const std = @import("std");
const c = @import("bind.zig").c;

const math = @import("math.zig");
const Allocator = std.mem.Allocator;

const Vec2D = math.Vec2D;
const Size = Vec2D;
const Offset = Vec2D;

const PADDING: u32 = 3;

const CBitmap = struct {
    handle: [*c]u8,
    size: Size,
};

const Bitmap = struct {
    handle: []u8,
    offsets: []Offset,

    size: Size,
    allocator: Allocator,

    fn init(size: Size, allocator: Allocator) !Bitmap {
        const bitmap = try allocator.alloc(u8, size.x * size.y);

        @memset(bitmap, 0);

        return Bitmap {
            .handle = bitmap,
            .offsets = try allocator.alloc(Offset, GLYPH_COUNT),
            .size = size,
            .allocator = allocator,
        };
    }

    fn append(self: *Bitmap, from: *const CBitmap, offset: Offset) void {
        @setRuntimeSafety(false);

        for (0..from.size.y) |y| {
            const self_line_offset = (y + offset.y) * self.size.x;
            const from_line_offset = y * from.size.x;

            for (0..from.size.x) |x| {
                self.handle[offset.x + x + self_line_offset] = from.handle[x + from_line_offset];
            }
        }
    }

    fn append_offset(self: *Bitmap, offset: Offset, index: u32) void {
        self.offsets[index] = offset;
    }

    fn deinit(self: *const Bitmap) void {
        self.allocator.free(self.handle);
        self.allocator.free(self.offsets);
    }
};

const Glyph = struct {
    bitmap: CBitmap,
    offset: Offset,
    top: i32,
    left: u32,
};

const Face = struct {
    handle: c.FT_Face,
    library: c.FT_Library,

    em: u32,
    ascender: u32,
    glyph_size: Size,

    const DPI: u32 = 72;

    fn init(path: []const u8, size: u32) Face {
        var library: c.FT_Library = undefined;
        var face: c.FT_Face = undefined;

        _ = c.FT_Init_FreeType(&library);
        _ = c.FT_New_Face(library, &path[0], 0, &face);
        _ = c.FT_Set_Char_Size(face, 0, size * DPI, DPI, DPI);

        const glyph_size = Size.init(
            math.from_fixed(face.*.size.*.metrics.max_advance),
            math.from_fixed(face.*.size.*.metrics.height) + 1,
        );

        return Face {
            .handle = face,
            .library = library,
            .glyph_size = glyph_size,
            .ascender = math.from_fixed(face.*.size.*.metrics.ascender),
            .em = face.*.units_per_EM,
        };
    }

    fn get_glyph(
        self: *const Face,
        code: u32
    ) Glyph {
        const index = c.FT_Get_Char_Index(self.handle, code);
        const glyph = self.handle.*.glyph;

        _ = c.FT_Load_Glyph(self.handle, index, c.FT_LOAD_DEFAULT);
        _ = c.FT_Render_Glyph(glyph, c.FT_RENDER_MODE_NORMAL);

        const glyph_bitmap = glyph.*.bitmap;

        const bitmap = CBitmap {
            .handle = glyph_bitmap.buffer,
            .size = Size.init(glyph_bitmap.width, glyph_bitmap.rows),
        };

        const i = code - 32;
        const line: u32 = i / COLS;
        const col: u32 = index - line * COLS;

        const offset = Offset.init(
            col * (self.glyph_size.x + PADDING),
            line * (self.glyph_size.y + PADDING),
        );

        return Glyph {
            .bitmap = bitmap,
            .offset = offset,
            .top = glyph.*.bitmap_top,
            .left = math.from_fixed(glyph.*.metrics.horiBearingX),
        };
    }

    fn deinit(self: *const Face) void {
        _ = c.FT_Done_Face(self.handle);
    }
};

pub const TrueType = struct {
    bitmap: Bitmap,
    glyph_count: u32,

    scale: f32,
    x_ratio: f32,
    glyph_size: Size,

    pub fn init(size: u32, path: []const u8, allocator: Allocator) !TrueType {
        const face = Face.init(path, size);
        defer face.deinit();

        var bitmap = try Bitmap.init(
            Size.init(
                (face.glyph_size.x + PADDING) * COLS,
                (face.glyph_size.y + PADDING) * ROWS,
            ),
            allocator,
        );

        for (32..127) |code| {
            const i: u32 = @intCast(code);
            const index = i - 32;
            const glyph = face.get_glyph(i);

            const insert_offset = Offset {
                .x = glyph.offset.x + glyph.left,
                .y = math.sub(glyph.offset.y + face.ascender, glyph.top),
            };

            bitmap.append(&glyph.bitmap, insert_offset);
            bitmap.append_offset(glyph.offset, index);
        }

        return TrueType {
            .bitmap = bitmap,
            .glyph_count = GLYPH_COUNT,
            .glyph_size = face.glyph_size,
            .x_ratio = math.divide(face.glyph_size.x, face.glyph_size.y),
            .scale = math.divide(face.glyph_size.y, face.em),
        };
    }

    pub fn normalized_width(self: *const TrueType) f32 {
        return math.divide(self.glyph_size.x, self.bitmap.size.x);
    }

    pub fn normalized_height(self: *const TrueType) f32 {
        return math.divide(self.glyph_size.y, self.bitmap.size.y);
    }

    pub fn glyph_normalized_offset(self: *const TrueType, index: usize) [2]f32 {
        return .{
            math.divide(self.bitmap.offsets[index].x, self.bitmap.size.x),
            math.divide(self.bitmap.offsets[index].y, self.bitmap.size.y),
        };
    }

    pub fn deinit(self: *const TrueType) void {
        self.bitmap.deinit();
    }
};

const ROWS: u32 = 9;
const COLS: u32 = 11;
const GLYPH_COUNT: u32 = 95;
