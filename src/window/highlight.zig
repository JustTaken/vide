const std = @import("std");
const Buffer = @import("buffer.zig");
const util = @import("../collections.zig");

pub const c = @cImport({
    @cInclude("tree_sitter/api.h");
    @cInclude("dlfcn.h");
});

const tree_lang = ?*const fn () callconv(.C) *c.TSLanguage;

pub const Highlight = struct {
    library: *anyopaque,
    on: bool,
    tree: *c.TSTree,
    parser: *c.TSParser,
    input: c.TSInput,
    id_ranges: IdRangeVec
};

pub const IdRangeVec = struct {
    elements: []IdRange,
    count: u32,
    last_range_asked: u32,
    allocator: std.mem.Allocator,
};

pub const IdRange = struct {
    id: u16,
    start: c.TSPoint,
    end: c.TSPoint,
};

pub const Color = packed struct {
    red: u8,
    green: u8,
    blue: u8,
};

pub inline fn get_rgb(color: Color) [3]u32 {
    return .{ color.red, color.green, color.blue };
}

pub inline fn get_id_range(id_ranges: *IdRangeVec, line: usize, column: usize) !*const IdRange {
    var next_range = &id_ranges.elements[id_ranges.last_range_asked];

    while (next_range.end.row < line or next_range.end.column <= column) {
        id_ranges.last_range_asked += 1;
        next_range = &id_ranges.elements[id_ranges.last_range_asked];
    }

    if (
        next_range.start.row <= line and next_range.start.column <= column and
        next_range.end.row >= line and next_range.end.column > column
    ) {
        id_ranges.last_range_asked += 1;

        return next_range;
    }

    return error.NotFound;
}

const Id = enum(u16) {
    Const = 14,
    At = 150,
    Pub = 2,
    Fn = 12,
    Equal = 17,
    If = 56,
    Return = 28,
    Comment = 121,
    Buildin = 40,
    Var = 15,
    Integer = 244,
    While = 57,
    And = 86,
    For = 58,
};

pub inline fn get_id_color(id: u16) Color {
    return switch (id) {
        @intFromEnum(Id.Const) => Color {
            .red = 0,
            .green = 0,
            .blue = 255,
        },
        @intFromEnum(Id.For) => Color {
            .red = 70,
            .green = 0,
            .blue = 4,
        },
        @intFromEnum(Id.And) => Color {
            .red = 10,
            .green = 50,
            .blue = 20,
        },
        @intFromEnum(Id.While) => Color {
            .red = 70,
            .green = 70,
            .blue = 20,
        },
        @intFromEnum(Id.Integer) => Color {
            .red = 50,
            .green = 250,
            .blue = 70,
        },
        @intFromEnum(Id.Var) => Color {
            .red = 0,
            .green = 0,
            .blue = 255,
        },
        @intFromEnum(Id.Buildin) => Color {
            .red = 100,
            .green = 200,
            .blue = 0,
        },
        @intFromEnum(Id.Comment) => Color {
            .red = 10,
            .green = 10,
            .blue = 10,
        },
        @intFromEnum(Id.Pub) => Color {
            .red = 200,
            .green = 0,
            .blue = 255,
        },
        @intFromEnum(Id.Equal) => Color {
            .red = 0,
            .green = 255,
            .blue = 255,
        },
        @intFromEnum(Id.Return) => Color {
            .red = 255,
            .green = 0,
            .blue = 0,
        },
        @intFromEnum(Id.If) => Color {
            .red = 0,
            .green = 200,
            .blue = 100,
        },
        @intFromEnum(Id.Fn) => Color {
            .red = 10,
            .green = 100,
            .blue = 50,
        },
        else => Color {
            .red = 255,
            .green = 255,
            .blue = 255,
        },
    };
}

inline fn push_id_range(vec: *IdRangeVec, id: u16, start: c.TSPoint, end: c.TSPoint) !void {
    if (vec.elements.len <= vec.count) {
        const new = try vec.allocator.alloc(IdRange, vec.elements.len * 2);

        util.copy(IdRange, vec.elements[0..], new);

        vec.allocator.free(vec.elements);
        vec.elements.ptr = new.ptr;
        vec.elements.len = new.len;
    }

    vec.elements[vec.count] = .{
        .id = id,
        .start = start,
        .end = end,
    };

    vec.count += 1;
}

fn read_from_buffer(payload: ?*anyopaque, _: u32, position: c.TSPoint, bytes_read: [*c]u32) callconv(.C) [*c]const u8 {
    const buff: *Buffer = @ptrCast(@alignCast(payload));

    if (position.row >= buff.line_count) {
        bytes_read[0] = 0;
        return null;
    }

    const line = &buff.lines[position.row];
    if (position.column >= line.char_count) {
        bytes_read[0] = 1;
        return "\n";
    }

    bytes_read[0] = line.char_count + 1 - position.column;
    line.content[line.char_count] = '\n';

    return @ptrCast(line.content[position.column..]);
}

const EditType = enum {
    Add,
    Remove,
};

// pub fn edit_tree(
//     highlight: *Highlight,
//     t: EditType,
//     start: *const Cursor,
//     end: *const Cursor,
//     offset: u32,
//     rows: u32,
// ) !void {
//     const old_end = if (t == EditType.Add) start else end;
//     const new_end = if (t == EditType.Add) end else start;

//     const edit = c.TSInputEdit {
//         .start_byte = start.byte_offset,
//         .old_end_byte = old_end.byte_offset,
//         .new_end_byte = new_end.byte_offset,
//         .start_point = .{
//             .row = start.y,
//             .column = start.x,
//         },
//         .old_end_point = .{
//             .row = old_end.y,
//             .column = old_end.x,
//         },
//         .new_end_point = .{
//             .row = new_end.y,
//             .column = new_end.x,
//         },
//     };

//     c.ts_tree_edit(highlight.tree, &edit);
//     highlight.tree = c.ts_parser_parse(
//         highlight.parser,
//         highlight.tree,
//         highlight.input,
//     ) orelse return error.ParseTree;

//     try fill_id_ranges(highlight, offset, rows);
// }

fn get_language(highlight: *Highlight, lang_name: []const u8) !*c.TSLanguage {
    var language: *c.TSLanguage = undefined;
    var string_builder: [30]u8 = undefined;
    var string_builder_len: usize = 0;

    {
        const extension = ".so";

        util.copy(u8, lang_name, &string_builder);
        util.copy(u8, extension, string_builder[lang_name.len..]);

        string_builder[lang_name.len + extension.len] = 0;
        string_builder_len = lang_name.len + extension.len + 1;
    }

    highlight.library = c.dlopen(&string_builder[0..string_builder_len][0], 1) orelse return error.LanguageLibraryLoading;

    {
        const prefix = "tree_sitter_";

        util.copy(u8, prefix, &string_builder);
        util.copy(u8, lang_name, string_builder[prefix.len..]);

        string_builder[prefix.len + lang_name.len] = 0;
        string_builder_len = prefix.len + lang_name.len + 1;

        const function_pointer: tree_lang = @ptrCast(c.dlsym(highlight.library, &string_builder[0..string_builder_len][0]));
        const f = function_pointer orelse return error.MissingFunctionPointer;

        language = f();
    }

    return language;
}

pub fn init(
    buff: *Buffer,
    allocator: std.mem.Allocator,
    rows: u32,
    lang_name: []const u8,
) void {
    buff.highlight.parser = c.ts_parser_new() orelse return;

    const language = get_language(&buff.highlight, lang_name) catch |e| {
        std.debug.print("no syntax highlight for {s} language, {}\n", .{lang_name, e});
        return;
    };

    const result = c.ts_parser_set_language(buff.highlight.parser, language);
    if (!result) return;

    buff.highlight.input = .{
        .payload = @ptrCast(@alignCast(buff)),
        .read = read_from_buffer,
        .encoding = 0,
    };

    buff.highlight.tree = c.ts_parser_parse(
        buff.highlight.parser,
        null,
        buff.highlight.input,
    ) orelse return;

    buff.highlight.id_ranges = .{
        .count = 0,
        .elements = allocator.alloc(IdRange, 50) catch return,
        .last_range_asked = 0,
        .allocator = allocator,
    };

    buff.highlight.on = true;
    fill_id_ranges(&buff.highlight, buff.offset[1], buff.offset[1] + rows - 1) catch {
        buff.highlight.on = false;
    };
}

pub fn fill_id_ranges(
    core: *Highlight,
    offset: u32,
    rows: u32,
) !void {
    const root_node = c.ts_tree_root_node(core.tree);
    var cursor = c.ts_tree_cursor_new(root_node);

    var point = .{
        .column = 0,
        .row = offset,
    };

    while (c.ts_tree_cursor_goto_first_child_for_point(&cursor, point) < 0) {
        point.row += 1;
    }

    core.id_ranges.count = 0;

    outer: while (true) {

        const node = c.ts_tree_cursor_current_node(&cursor);
        const string = c.ts_node_string(node);
        const id = c.ts_node_symbol(node);
        const start = c.ts_node_start_point(node);
        const end = c.ts_node_end_point(node);

        std.debug.print("id: {}, {s}, start: {} {}, end: {} {}\n", .{id, string, start.row, start.column, end.row, end.column});
        if (c.ts_tree_cursor_goto_first_child(&cursor)) continue;

        {
            // const node = c.ts_tree_cursor_current_node(&cursor);
 
            if (start.row > offset + rows) return;

            // const id = c.ts_node_symbol(node);

            try push_id_range(&core.id_ranges, id, start, end);
        }

        while (!c.ts_tree_cursor_goto_next_sibling(&cursor)) {
            if (!c.ts_tree_cursor_goto_parent(&cursor)) break :outer;
        }
    }
}

pub fn deinit(core: *Highlight) void {
    core.id_ranges.allocator.free(core.id_ranges.elements);

    c.ts_tree_delete(core.tree);
    c.ts_parser_delete(core.parser);

    _ = c.dlclose(core.library);
}

