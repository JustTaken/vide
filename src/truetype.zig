const std = @import("std");

const c = @cImport({
    @cInclude("ft2build.h");
    @cInclude("freetype/freetype.h");
});

const util = @import("util");
const math = util.math;

const Allocator = std.mem.Allocator;
const FixedVec = util.collections.FixedVec;

const Size = math.Vec2D;
const Offset = math.Vec2D;

const ROWS: u32 = 9;
const COLS: u32 = 11;
const GLYPH_COUNT: u32 = 95;
const PADDING: u32 = 3;
const OPACITY: u32 = 100;

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

        return Bitmap{
            .handle = bitmap,
            .offsets = try allocator.alloc(Offset, GLYPH_COUNT),
            .size = size,
            .allocator = allocator,
        };
    }

    fn append(self: *Bitmap, from: *const CBitmap, offset: Offset) void {
        @setRuntimeSafety(false);

        for (0..from.size.y) |y| {
            const self_offset = (offset.y + y) * self.size.x + offset.x;
            const from_offset = y * from.size.x;

            for (0..from.size.x) |x| {
                self.handle[x + self_offset] = from.handle[x + from_offset];
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

const Bearing = struct {
    x: i32,
    y: i32,

    fn init(x: i32, y: i32) Bearing {
        return Bearing{
            .x = x,
            .y = y,
        };
    }
};

const Glyph = struct {
    bitmap: CBitmap,
    offset: Offset,
    bearing: Bearing,
};

const FreeType = struct {
    handle: std.DynLib,
    FT_Init_FreeType: *const @TypeOf(c.FT_Init_FreeType),
    FT_New_Face: *const @TypeOf(c.FT_New_Face),
    FT_Set_Char_Size: *const @TypeOf(c.FT_Set_Char_Size),
    FT_Load_Glyph: *const @TypeOf(c.FT_Load_Glyph),
    FT_Render_Glyph: *const @TypeOf(c.FT_Render_Glyph),
    FT_Done_Face: *const @TypeOf(c.FT_Done_Face),
    FT_Get_Char_Index: *const @TypeOf(c.FT_Get_Char_Index),

    fn init() !FreeType {
        var self: FreeType = undefined;
        self.handle = try std.DynLib.open("libfreetype.so");

        inline for (@typeInfo(FreeType).Struct.fields[1..]) |field| {
            const name: [:0]const u8 = @ptrCast(
                std.fmt.comptimePrint("{s}\x00", .{field.name}),
            );

            @field(self, field.name) = self.handle.lookup(
                field.type,
                name,
            ) orelse return error.SymbolNoFound;
        }

        return self;
    }

    fn deinit(self: *FreeType) void {
        self.handle.close();
    }
};

const Face = struct {
    handle: c.FT_Face,
    library: c.FT_Library,

    em: u32,
    ascender: u32,
    descender: u32,
    glyph_size: Size,

    const DPI: u32 = 72;

    fn init(freetype: *FreeType, path: []const u8, size: u32) Face {
        var library: c.FT_Library = undefined;
        var face: c.FT_Face = undefined;

        _ = freetype.FT_Init_FreeType(&library);
        _ = freetype.FT_New_Face(library, &path[0], 0, &face);
        _ = freetype.FT_Set_Char_Size(face, 0, size * DPI, DPI, DPI);

        const glyph_size = Size.init(
            math.from_fixed(face.*.size.*.metrics.max_advance),
            math.from_fixed(face.*.size.*.metrics.height),
        );

        return Face{
            .handle = face,
            .library = library,
            .glyph_size = glyph_size,
            .ascender = math.from_fixed(face.*.size.*.metrics.ascender),
            .descender = math.from_fixed(-face.*.size.*.metrics.descender),
            .em = face.*.units_per_EM,
        };
    }

    fn get_glyph(self: *const Face, freetype: *FreeType, code: u32) Glyph {
        const index = freetype.FT_Get_Char_Index(self.handle, code);
        const glyph = self.handle.*.glyph;

        _ = freetype.FT_Load_Glyph(self.handle, index, c.FT_LOAD_DEFAULT);
        _ = freetype.FT_Render_Glyph(glyph, c.FT_RENDER_MODE_NORMAL);

        const glyph_bitmap = glyph.*.bitmap;
        const bitmap = CBitmap{
            .handle = glyph_bitmap.buffer,
            .size = Size.init(glyph_bitmap.width, glyph_bitmap.rows),
        };

        const i = code - 32;
        const line: u32 = i / COLS;
        const col: u32 = i - line * COLS;

        const offset = Offset.init(
            col * (self.glyph_size.x + PADDING),
            line * (self.glyph_size.y + PADDING),
        );

        return Glyph{
            .bitmap = bitmap,
            .offset = offset,
            .bearing = Bearing.init(glyph.*.bitmap_left, glyph.*.bitmap_top),
        };
    }

    fn deinit(self: *const Face, freetype: *FreeType) void {
        _ = freetype.FT_Done_Face(self.handle);
    }
};

fn find_path(name: []const u8, allocator: Allocator) !FixedVec(u8, 100) {
    const data_home = try std.process.getEnvVarOwned(
        allocator,
        "XDG_DATA_HOME",
    );

    defer allocator.free(data_home);

    var path = FixedVec(u8, 100).init();
    try path.extend(data_home);
    try path.extend("fonts/");

    const fs = std.fs.cwd();

    var dir = try fs.openDir(path.elements(), .{ .iterate = true });
    defer dir.close();

    var iter = dir.iterate();

    while (try iter.next()) |d| {
        var nest_dir = try dir.openDir(d.name, .{ .iterate = true });
        var d_iter = nest_dir.iterate();

        while (try d_iter.next()) |f| {
            if (std.mem.eql(u8, f.name, name)) {
                try path.extend(d.name);
                try path.push('/');
                try path.extend(f.name);
                try path.push(0);

                return path;
            }
        }
    }

    return error.NotFound;
}

pub const TrueType = struct {
    bitmap: Bitmap,
    glyph_count: u32,

    scale: f32,
    ratio: f32,
    glyph_size: Size,

    pub fn init(size: u32, name: []const u8, allocator: Allocator) !TrueType {
        var self: TrueType = undefined;
        var path = try find_path(name, allocator);
        var freetype = try FreeType.init();
        defer freetype.deinit();

        const face = Face.init(&freetype, path.elements(), size);
        defer face.deinit(&freetype);

        self.bitmap = try Bitmap.init(
            Size.init(
                (face.glyph_size.x + PADDING) * COLS,
                (face.glyph_size.y + PADDING) * ROWS,
            ),
            allocator,
        );

        for (32..127) |code| {
            const i: u32 = @intCast(code);
            const index = i - 32;
            const glyph = face.get_glyph(&freetype, i);

            const insert_offset = Offset{
                .x = math.sum(glyph.offset.x, glyph.bearing.x),
                .y = glyph.offset.y + face.glyph_size.y - math.sum(
                    face.descender,
                    glyph.bearing.y,
                ),
            };

            self.bitmap.append(&glyph.bitmap, insert_offset);
            self.bitmap.append_offset(glyph.offset, index);
        }
        {
            const i = GLYPH_COUNT;
            const line: u32 = i / COLS;
            const col: u32 = i - line * COLS;

            const offset = Offset.init(
                col * (face.glyph_size.x + PADDING),
                line * (face.glyph_size.y + PADDING),
            );

            for (0..face.glyph_size.y + 2) |y| {
                for (0..face.glyph_size.x + 2) |x| {
                    self.bitmap.handle[
                        (y + offset.y - 1) * self.bitmap.size.x + offset.x + x - 1
                    ] = OPACITY;
                }
            }
        }

        self.glyph_count = GLYPH_COUNT;
        self.glyph_size = face.glyph_size;
        self.ratio = math.divide(face.glyph_size.x, face.glyph_size.y);
        self.scale = math.divide(face.glyph_size.y, face.em);

        return self;
    }

    pub fn width(self: *const TrueType) f32 {
        return @floatFromInt(self.bitmap.size.x);
    }

    pub fn height(self: *const TrueType) f32 {
        return @floatFromInt(self.bitmap.size.y);
    }

    pub fn glyph_width(self: *const TrueType) f32 {
        return @floatFromInt(self.glyph_size.x);
    }

    pub fn glyph_height(self: *const TrueType) f32 {
        return @floatFromInt(self.glyph_size.y);
    }

    pub fn deinit(self: *const TrueType) void {
        self.bitmap.deinit();
    }
};
