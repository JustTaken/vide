const std = @import("std");
const c = @import("../bind.zig").c;

const PADDING: u32 = 3;

const Face = struct {
    handle: c.FT_Face,
    library: c.FT_Library,

    em: u32,
    ascender: u32,
    line_height: u32,
    max_advance: u32,
};

pub const TrueType = struct {
    bitmap: Bitmap,
    glyph_count: u32,

    scale: f32,
    x_ratio: f32,
    advance: u32,
    line_height: u32,
};

const Bitmap = struct {
    offsets: []Offset,
    handle: []u8,

    width: u32,
    height: u32,

    allocator: std.mem.Allocator,
};

const CBitmap = struct {
    handle: [*c]u8,
    width: u32,
    height: u32,
};

const Offset = struct {
    x: u32,
    y: u32,
};

inline fn bitmap_append(src: *const CBitmap, dst: *Bitmap, offset: Offset) void {
    @setRuntimeSafety(false);

    for (0..src.height) |y| {
        const dst_line_offset = (y + offset.y) * dst.width;
        const src_line_offset = y * src.width;

        for (0..src.width) |x| {
            dst.handle[offset.x + x + dst_line_offset] = src.handle[x + src_line_offset];
        }
    }
}

inline fn division(numerator: u32, denumerator: u32) f32 {
    const f_numerator: f32 = @floatFromInt(numerator);
    const f_denumerator: f32 = @floatFromInt(denumerator);

    return f_numerator / f_denumerator;
}

inline fn from_fixed(fixed: isize) u32 {
    return @intCast(fixed >> 6);
}

inline fn add_glyph(
    bitmap: *Bitmap,
    face: *const Face,
    position: Offset,
    code: u32
) void {
    const index = c.FT_Get_Char_Index(face.handle, code);
    const glyph = face.handle.*.glyph;

    _ = c.FT_Load_Glyph(face.handle, index, c.FT_LOAD_DEFAULT);
    _ = c.FT_Render_Glyph(glyph, c.FT_RENDER_MODE_NORMAL);

    const glyph_bitmap = glyph.*.bitmap;
    const width = glyph_bitmap.width;
    const height = glyph_bitmap.rows;
    const left_bearing = from_fixed(glyph.*.metrics.horiBearingX);

    const src_bitmap = CBitmap {
        .handle = glyph_bitmap.buffer,
        .width = width,
        .height = height,
    };

    const top = glyph.*.bitmap_top;

    const top_offset: i32 = @intCast(position.y + face.ascender);
    const left_offset: u32 = position.x + left_bearing;

    const offset = Offset {
        .x = left_offset,
        .y = @intCast(top_offset - top),
    };

    bitmap_append(&src_bitmap, bitmap, offset);
}

fn face_init(size: u32) Face {
    var face: Face = undefined;

    _ = c.FT_Init_FreeType(&face.library);
    _ = c.FT_New_Face(face.library, "assets/font/font.ttf", 0, &face.handle);
    _ = c.FT_Set_Char_Size(face.handle, 0, size * 72, 72, 72);

    face.line_height = from_fixed(face.handle.*.size.*.metrics.height) + 1;
    face.max_advance = from_fixed(face.handle.*.size.*.metrics.max_advance);
    face.ascender = from_fixed(face.handle.*.size.*.metrics.ascender);
    face.em = face.handle.*.units_per_EM;

    return face;
}

const ROWS: u32 = 9;
const COLS: u32 = 11;
const GLYPH_COUNT: u32 = 95;

pub fn init(size: u32, allocator: std.mem.Allocator) !TrueType {
    var font: TrueType = undefined;
    const face = face_init(size);

    font.glyph_count = GLYPH_COUNT;
    font.advance = face.max_advance;
    font.line_height = face.line_height;
    font.x_ratio = division(font.advance, font.line_height);
    font.scale = division(font.line_height, face.em);
    font.bitmap.width = (face.max_advance + PADDING) * COLS;
    font.bitmap.height = (font.line_height + PADDING) * ROWS;
    font.bitmap.handle = try allocator.alloc(u8, font.bitmap.width * font.bitmap.height);
    font.bitmap.offsets = try allocator.alloc(Offset, GLYPH_COUNT);
    font.bitmap.allocator = allocator;

    @memset(font.bitmap.handle, 0);

    const start: u32 = 32;
    const end: u32 = 127;
    for (start..end) |code| {
        const i: u32 = @intCast(code);

        const index = i - 32;
        const line: u32 = index / COLS;
        const col: u32 = index - line * COLS;

        const offset = Offset {
            .x = col * (font.advance + PADDING),
            .y = line * (font.line_height + PADDING),
        };

        add_glyph(&font.bitmap, &face, offset, i);
        font.bitmap.offsets[index] = offset;
    }

    face_deinit(&face);

    return font;
}

pub fn normalized_width(font: *const TrueType) f32 {
    return division(font.advance, font.bitmap.width);
}

pub fn normalized_height(font: *const TrueType) f32 {
    return division(font.line_height, font.bitmap.height);
}

pub inline fn glyph_normalized_offset(font: *const TrueType, index: usize) [2]f32 {
    return .{
        division(font.bitmap.offsets[index].x, font.bitmap.width),
        division(font.bitmap.offsets[index].y, font.bitmap.height),
    };
}

fn face_deinit(face: *const Face) void {
    _ = c.FT_Done_Face(face.handle);
}

fn bitmap_deinit(bitmap: *const Bitmap) void {
    bitmap.allocator.free(bitmap.handle);
}

pub fn deinit(core: *const TrueType) void {
    bitmap_deinit(&core.bitmap);
}
