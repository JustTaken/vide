const std = @import("std");
const util = @import("../util.zig");
const c = @cImport({
    @cInclude("tree_sitter/api.h");
    @cInclude("dlfcn.h");
});

const Buffer = @import("buffer.zig").Buffer;
const Vec = @import("../collections.zig").Vec;

const tree_lang = ?*const fn () callconv(.C) *c.TSLanguage;

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
    _,

    fn init(id: u16) !Id {
        const result: Id = @enumFromInt(id);

        switch (result) {
            .Const, .At, .Pub, .Fn, .Equal, .If, .Return, .Comment, .Buildin, .Var, .Integer, .While, .And, .For => {},
            _ => return error.NoToken,
        }
    }
};

pub const Range = struct {
    id: Id,
    start: c.TSPoint,
    end: c.TSPoint,
};

pub const Color = packed struct {
    red: u8,
    green: u8,
    blue: u8,
};

const EditType = enum {
    Add,
    Remove,
};

pub const Highlight = struct {
    library: *anyopaque,

    tree: *c.TSTree,
    parser: *c.TSParser,

    input: c.TSInput,
    ranges: Vec(Range),

    on: bool,

    pub fn init(
        lang_name: []const u8,
        buff: *const Buffer,
        allocator: std.mem.Allocator,
    ) !Highlight {
        var highlight: Highlight = undefined;
        highlight.parser = c.ts_parser_new() orelse return error.ParserInit;

        const language = try get_language(lang_name, &highlight.library);
        if (!c.ts_parser_set_language(buff.highlight.parser, language)) return error.ParserSetFail;

        highlight.input = .{
            .payload = @ptrCast(@alignCast(buff)),
            .read = read_from_buffer,
            .encoding = 0,
        };

        highlight.tree = c.ts_parser_parse(
            buff.highlight.parser,
            null,
            buff.highlight.input,
        ) orelse return error.ParseFail;

        highlight.ranges = try Vec(Range).init(50, allocator);
        highlight.on = true;
    }

    pub fn edit(
        self: *Highlight,
        t: EditType,
        start: u32,
        end: u32
    ) !void {
        const s = if (t == EditType.Add) start else end;
        const e = if (t == EditType.Add) end else start;

        const input = c.TSInputEdit {
            .start_byte = s,
            .old_end_byte = s,
            .new_end_byte = e,
            .start_point = .{ .row = 0, .column = 0 },
            .old_end_point = .{ .row = 0, .column = 0 },
            .new_end_point = .{ .row = 0, .column = 0 },
        };

        c.ts_tree_edit(self.tree, &input);
        self.tree = c.ts_parser_parse(
            self.parser,
            self.tree,
            self.input,
        ) orelse return error.ParseTree;
    }

    pub fn deinit(self: *Highlight) void {
        self.ranges.deinit();

        c.ts_tree_delete(self.tree);
        c.ts_parser_delete(self.parser);

        _ = c.dlclose(self.library);
    }
};

fn read_from_buffer(
    payload: ?*anyopaque,
    _: u32,
    position: c.TSPoint,
    bytes_read: [*c]u32
) callconv(.C) [*c]const u8 {
    const buffer: *const Buffer = @ptrCast(@alignCast(payload));

    bytes_read[0] = 0;

    if (position.row >= buffer.lines.len()) {
        return null;
    }

    const line = buffer.lines.get(position.row) catch return null;

    const len = line.content.len();
    bytes_read[0] = len - position.column;

    return @ptrCast(line.content.range(position.column, len));
}

fn get_language(lang_name: []const u8, library: **anyopaque) !*c.TSLanguage {
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

    library.* = c.dlopen(&string_builder[0..string_builder_len][0], 1) orelse return error.LanguageLibraryLoading;

    {
        const prefix = "tree_sitter_";

        util.copy(u8, prefix, &string_builder);
        util.copy(u8, lang_name, string_builder[prefix.len..]);

        string_builder[prefix.len + lang_name.len] = 0;
        string_builder_len = prefix.len + lang_name.len + 1;

        const function_pointer: tree_lang = @ptrCast(c.dlsym(library.*, &string_builder[0..string_builder_len][0]));
        const f = function_pointer orelse return error.MissingFunctionPointer;

        language = f();
    }

    return language;
}


// pub inline fn get_id_range(id_ranges: *RangeVec, line: usize, column: usize) !*const Range {
//     var next_range = &id_ranges.elements[id_ranges.last_range_asked];

//     while (next_range.end.row < line or next_range.end.column <= column) {
//         id_ranges.last_range_asked += 1;
//         next_range = &id_ranges.elements[id_ranges.last_range_asked];
//     }

//     if (
//         next_range.start.row <= line and next_range.start.column <= column and
//         next_range.end.row >= line and next_range.end.column > column
//     ) {
//         id_ranges.last_range_asked += 1;

//         return next_range;
//     }

//     return error.NotFound;
// }


    //     Id.Const => Color {
    //         .red = 0,
    //         .green = 0,
    //         .blue = 255,
    //     },
    //     Id.For => Color {
    //         .red = 70,
    //         .green = 0,
    //         .blue = 4,
    //     },
    //     Id.And => Color {
    //         .red = 10,
    //         .green = 50,
    //         .blue = 20,
    //     },
    //     Id.While => Color {
    //         .red = 70,
    //         .green = 70,
    //         .blue = 20,
    //     },
    //     Id.Integer => Color {
    //         .red = 50,
    //         .green = 250,
    //         .blue = 70,
    //     },
    //     Id.Var => Color {
    //         .red = 0,
    //         .green = 0,
    //         .blue = 255,
    //     },
    //     Id.Buildin => Color {
    //         .red = 100,
    //         .green = 200,
    //         .blue = 0,
    //     },
    //     Id.Comment => Color {
    //         .red = 10,
    //         .green = 10,
    //         .blue = 10,
    //     },
    //     Id.Pub => Color {
    //         .red = 200,
    //         .green = 0,
    //         .blue = 255,
    //     },
    //     Id.Equal => Color {
    //         .red = 0,
    //         .green = 255,
    //         .blue = 255,
    //     },
    //     Id.Return => Color {
    //         .red = 255,
    //         .green = 0,
    //         .blue = 0,
    //     },
    //     Id.If => Color {
    //         .red = 0,
    //         .green = 200,
    //         .blue = 100,
    //     },
    //     Id.Fn => Color {
    //         .red = 10,
    //         .green = 100,
    //         .blue = 50,
    //     },
    // };
    //     @intFromEnum(Id.Const) => Color {
    //         .red = 0,
    //         .green = 0,
    //         .blue = 255,
    //     },
    //     @intFromEnum(Id.For) => Color {
    //         .red = 70,
    //         .green = 0,
    //         .blue = 4,
    //     },
    //     @intFromEnum(Id.And) => Color {
    //         .red = 10,
    //         .green = 50,
    //         .blue = 20,
    //     },
    //     @intFromEnum(Id.While) => Color {
    //         .red = 70,
    //         .green = 70,
    //         .blue = 20,
    //     },
    //     @intFromEnum(Id.Integer) => Color {
    //         .red = 50,
    //         .green = 250,
    //         .blue = 70,
    //     },
    //     @intFromEnum(Id.Var) => Color {
    //         .red = 0,
    //         .green = 0,
    //         .blue = 255,
    //     },
    //     @intFromEnum(Id.Buildin) => Color {
    //         .red = 100,
    //         .green = 200,
    //         .blue = 0,
    //     },
    //     @intFromEnum(Id.Comment) => Color {
    //         .red = 10,
    //         .green = 10,
    //         .blue = 10,
    //     },
    //     @intFromEnum(Id.Pub) => Color {
    //         .red = 200,
    //         .green = 0,
    //         .blue = 255,
    //     },
    //     @intFromEnum(Id.Equal) => Color {
    //         .red = 0,
    //         .green = 255,
    //         .blue = 255,
    //     },
    //     @intFromEnum(Id.Return) => Color {
    //         .red = 255,
    //         .green = 0,
    //         .blue = 0,
    //     },
    //     @intFromEnum(Id.If) => Color {
    //         .red = 0,
    //         .green = 200,
    //         .blue = 100,
    //     },
    //     @intFromEnum(Id.Fn) => Color {
    //         .red = 10,
    //         .green = 100,
    //         .blue = 50,
    //     },
    //     else => Color {
    //         .red = 255,
    //         .green = 255,
    //         .blue = 255,
    //     },
    // };
// }



// pub fn fill_id_ranges(
//     core: *Highlight,
//     offset: u32,
//     rows: u32,
// ) !void {
//     const root_node = c.ts_tree_root_node(core.tree);
//     var cursor = c.ts_tree_cursor_new(root_node);

//     var point = .{
//         .column = 0,
//         .row = offset,
//     };

//     while (c.ts_tree_cursor_goto_first_child_for_point(&cursor, point) < 0) {
//         point.row += 1;
//     }

//     core.id_ranges.count = 0;

//     outer: while (true) {

//         const node = c.ts_tree_cursor_current_node(&cursor);
//         const string = c.ts_node_string(node);
//         const id = c.ts_node_symbol(node);
//         const start = c.ts_node_start_point(node);
//         const end = c.ts_node_end_point(node);

//         std.debug.print("id: {}, {s}, start: {} {}, end: {} {}\n", .{id, string, start.row, start.column, end.row, end.column});
//         if (c.ts_tree_cursor_goto_first_child(&cursor)) continue;

//         {
//             // const node = c.ts_tree_cursor_current_node(&cursor);
 
//             if (start.row > offset + rows) return;

//             // const id = c.ts_node_symbol(node);

//             try push_id_range(&core.id_ranges, id, start, end);
//         }

//         while (!c.ts_tree_cursor_goto_next_sibling(&cursor)) {
//             if (!c.ts_tree_cursor_goto_parent(&cursor)) break :outer;
//         }
//     }
// }

