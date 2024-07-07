const std = @import("std");
const buffer = @import("buffer.zig");
const Line = buffer.Line;
const Buffer = buffer.Buffer;
const Cursor = buffer.Cursor;

pub const c = @cImport({
    @cInclude("tree_sitter/api.h");
});

extern fn tree_sitter_zig() callconv(.C) ?*c.TSLanguage;


pub const Highlight = struct {
    on: bool,
    tree: *c.TSTree,
    parser: *c.TSParser,
    input: c.TSInput,
};

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
    // std.debug.print("parsing tree, row: {}, col: {}, offset: {}, content: {s}\n", .{position.row, position.column, byte_offset, line.content[position.column..]});

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

    const root_node = c.ts_tree_root_node(highlight.tree);
    const count = c.ts_node_child_count(root_node);

    std.debug.print("child count: {}\n", .{count});
    std.debug.print("edit: {any}\n", .{edit});

    c.ts_tree_edit(highlight.tree, &edit);
    highlight.tree = c.ts_parser_parse(
        highlight.parser,
        highlight.tree,
        highlight.input,
    ) orelse return error.ParseTree;
}

pub fn init(buff: *Buffer) !void {
    buff.highlight.parser = c.ts_parser_new() orelse return error.ParserInit;

    const language = tree_sitter_zig();
    const result = c.ts_parser_set_language(buff.highlight.parser, language);
    if (!result) return error.SettingLanguage;

    // var buff = buffer_init(allocator) catch return error.BufferInit;
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

    buff.highlight.on = true;

    // std.debug.print("padding\n", .{});

    // modify_buffer(&buff);

    // const start_cursor = Cursor {
    //     .x = 0,
    //     .y = 3,
    //     .byte_offset = 67,
    // };

    // const end_cursor = Cursor {
    //     .x = 0,
    //     .y = 4,
    //     .byte_offset = 83,
    // };

    // try edit_tree(&highlight, .Add, &start_cursor, &end_cursor);

    // const root_node = c.ts_tree_root_node(buff.highlight.tree);
    // const count = c.ts_node_child_count(root_node);

    // for (0..count) |i| {
    //     const node = c.ts_node_child(root_node, @intCast(i));
    //     const string = c.ts_node_string(node);
    //     std.debug.print("string: {s}, start: {}\n end: {}\n", .{string, c.ts_node_start_point(node), c.ts_node_end_point(node)});
    // }

    // for (0..buff.line_count) |i| {
    //     allocator.free(buff.lines[i].content);
    // }

    // allocator.free(buff.lines);
}

inline fn do_with_node(node: c.TSNode) void {
    const string = c.ts_node_string(node);
    std.debug.print("string: {s}, start: {}\n end: {}\n", .{string, c.ts_node_start_point(node), c.ts_node_end_point(node)});
}

pub fn walk_tree(core: *const Highlight) void {
    var current_node = c.ts_tree_root_node(core.tree);
    var parent_walk = false;

    while (!c.ts_node_is_null(current_node)) {
        if (parent_walk) {
            const sibling = c.ts_node_next_sibling(current_node);

            if (c.ts_node_is_null(sibling)) {
                current_node = c.ts_node_parent(current_node);
            } else {
                current_node = sibling;
                parent_walk = false;
            }

            continue;
        }

        const nesting_count = c.ts_node_child_count(current_node);

        if (nesting_count != 0) {
            current_node = c.ts_node_child(current_node, 0);
            continue;
        }

        do_with_node(current_node);

        // break;
        const sibling = c.ts_node_next_sibling(current_node);
        std.debug.print("found sibling\n", .{});

        if (c.ts_node_is_null(sibling)) {
            current_node = c.ts_node_parent(current_node);
            std.debug.print("its null\n", .{});
            parent_walk = true;
        } else {
            current_node = sibling;
        }
    }
}

pub fn deinit(core: *const Highlight) void {
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
