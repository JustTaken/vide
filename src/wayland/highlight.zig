const std = @import("std");
const buffer = @import("buffer.zig");
const Line = buffer.Line;
const Buffer = buffer.Buffer;
const Cursor = buffer.Cursor;
const util = @import("util.zig");

pub const c = @cImport({
    @cInclude("tree_sitter/api.h");
});

extern fn tree_sitter_zig() callconv(.C) ?*c.TSLanguage;

pub const Highlight = struct {
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

pub inline fn get_id_color(id: u16) Color {
    return switch (id) {
        14 => Color {
            .red = 0,
            .green = 0,
            .blue = 255,
        },

        250 => Color {
            .red = 10,
            .green = 100,
            .blue = 0,
        },

        else => Color {
            .red = 200,
            .green = 200,
            .blue = 200,
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

pub fn edit_tree(
    highlight: *Highlight,
    t: EditType,
    start: *const Cursor,
    end: *const Cursor,
    offset: u32,
    rows: u32,
) !void {
    const old_end = if (t == EditType.Add) start else end;
    const new_end = if (t == EditType.Add) end else start;

    const edit = c.TSInputEdit {
        .start_byte = start.byte_offset,
        .old_end_byte = old_end.byte_offset,
        .new_end_byte = new_end.byte_offset,
        .start_point = .{
            .row = start.y,
            .column = start.x,
        },
        .old_end_point = .{
            .row = old_end.y,
            .column = old_end.x,
        },
        .new_end_point = .{
            .row = new_end.y,
            .column = new_end.x,
        },
    };

    c.ts_tree_edit(highlight.tree, &edit);
    highlight.tree = c.ts_parser_parse(
        highlight.parser,
        highlight.tree,
        highlight.input,
    ) orelse return error.ParseTree;

    try fill_id_ranges(highlight, offset, rows);
}

pub fn init(
    buff: *Buffer,
    allocator: std.mem.Allocator,
    rows: u32
) !void {
    buff.highlight.parser = c.ts_parser_new() orelse return error.ParserInit;

    const language = tree_sitter_zig();
    const result = c.ts_parser_set_language(buff.highlight.parser, language);
    if (!result) return error.SettingLanguage;

    buff.highlight.input = .{
        .payload = @ptrCast(@alignCast(buff)),
        .read = read_from_buffer,
        .encoding = 0,
    };

    buff.highlight.tree = c.ts_parser_parse(
        buff.highlight.parser,
        null,
        buff.highlight.input,
    ) orelse return error.ParseTree;

    buff.highlight.id_ranges = .{
        .count = 0,
        .elements = try allocator.alloc(IdRange, 50),
        .last_range_asked = 0,
        .allocator = allocator,
    };

    buff.highlight.on = true;
    try fill_id_ranges(&buff.highlight, buff.offset[1], buff.offset[1] + rows - 1);
}

pub fn fill_id_ranges(
    core: *Highlight,
    offset: u32,
    rows: u32,
) !void {
    if (!core.on) return;
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
    core.id_ranges.last_range_asked = 0;
    outer: while (true) {
        if (c.ts_tree_cursor_goto_first_child(&cursor)) continue;

        {
            const node = c.ts_tree_cursor_current_node(&cursor);
            const start = c.ts_node_start_point(node);
 
            if (start.row > offset + rows) return;

            const end = c.ts_node_end_point(node);
            const id = c.ts_node_symbol(node);

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
}

// fn modify_buffer(buff: *Buffer) void {
//     buff.line_count += 1;

//     var offset: u32 = 0;
//     for (0..5) |i| {
//         const line = &buff.lines[i];
//         line.char_count = 0;
//         line.indent = 0;

//         while(FINAL[offset] != '\n') {
//             line.content[line.char_count] = FINAL[offset];
//             line.char_count += 1;
//             offset += 1;
//         }

//         offset += 1;
//     }

// }

// pub fn buffer_init(allocator: std.mem.Allocator) !Buffer {
//     var buff: Buffer = undefined;
//     const name = "scratch";

//     buff.name = try allocator.alloc(u8, name.len);
//     buff.lines = try allocator.alloc(Line, 5);
//     buff.offset = .{ 0, 0 };
//     buff.line_count = 4;
//     buff.selection_active = false;
//     buff.selection = Cursor {
//         .x = 0,
//         .y = 0,
//         .byte_offset = 0,
//     };

//     var offset: u32 = 0;
//     for (0..buff.line_count) |i| {
//         const line = &buff.lines[i];
//         line.content = try allocator.alloc(u8, 50);
//         line.char_count = 0;
//         line.indent = 0;

//         while(INITIAL[offset] != '\n') {
//             line.content[line.char_count] = INITIAL[offset];
//             line.char_count += 1;
//             offset += 1;
//         }

//         offset += 1;
//     }

//     buff.lines[4].content = try allocator.alloc(u8 ,50);

//     buff.cursor = Cursor {
//         .x = 0,
//         .y = 0,
//         .byte_offset = 0,
//     };

//     for (0..name.len) |i| {
//         buff.name[i] = name[i];
//     }

//     return buff;
// }
