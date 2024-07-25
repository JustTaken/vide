const std = @import("std");
const util = @import("../util.zig");
const math = @import("../math.zig");

const Allocator = std.mem.Allocator;
const Vec = @import("../collections.zig").Vec;
const Fn = @import("command.zig").Fn;
const Cursor = @import("../math.zig").Vec2D;

const PREFIX = " > ";

pub const CommandLine = struct {
    content: Vec(u8),
    row: u32,
    cursor: ?u32,
    selection: ?u32,

    pub fn init(rows: u32, allocator: Allocator) !CommandLine {
        return CommandLine {
            .content = try Vec(u8).init(50, allocator),
            .cursor = null,
            .selection = null,
            .row = rows - 1,
        };
    }

    fn move_cursor(self: *CommandLine, pos: u32) void {
        if (self.cursor) |*c| {
            c.* = pos;
        }
    }

    pub fn insert_string(self: *CommandLine, string: []const u8) !void {
        const cursor = self.cursor orelse return error.NoCursor;

        const l: u32 = @intCast(PREFIX.len);
        const len: u32 = @intCast(string.len);

        try self.content.extend_insert(string, cursor - l);
        self.move_cursor(cursor + len);
        self.selection = null;
    }

    pub fn set_row(self: *CommandLine, rows: u32) void {
        self.row = rows - 1;
    }

    pub fn toggle_cursor(self: *CommandLine) void {
        if (self.cursor) |_| {
            self.cursor = null;
            self.selection = null;
        } else {
            self.cursor = PREFIX.len;
        }
    }

    pub fn chars(self: *const CommandLine) []const u8 {
        return self.content.elements();
    }

    pub fn char_iter(
        self: *const CommandLine,
        T: type, 
        ptr: *T, 
        f: fn (*T, u8, usize, usize) anyerror!void
    ) !void {
        if (self.cursor) |_| {
            for (PREFIX, 0..) |char, i| {
                try f(ptr, char, i, self.row);
            }

            for (self.content.elements(), 0..) |char, j| {
                try f(ptr, char, j + PREFIX.len, self.row);
            }
        }
    }

    pub fn cursor_back(
        self: *const CommandLine,
        T: type,
        ptr: *T,
        f: fn(*T, u8, usize, usize) anyerror!void
    ) !void {
        if (self.cursor) |cursor| {
            try f(ptr, 0, cursor, self.row);

            if (self.selection) |selection| {

                if (selection == cursor) return;

                const start = if (selection < cursor) selection else cursor + 1;
                const end = if(selection > cursor) selection + 1 else cursor;

                for (start..end) |i| try f(ptr, 0, i, self.row);
            }
        }
    }

    pub fn deinit(self: *const CommandLine) void {
        self.content.deinit();
    }

    pub fn commands() []const Fn {
        return &[_]Fn {
            Fn { .f = space,  .string = "Spc" },
            Fn { .f = delete, .string = "C-d" },
            Fn { .f = prev_char, .string = "C-b" },
            Fn { .f = next_char, .string = "C-f" },
            Fn { .f = command_end, .string = "C-e" },
            Fn { .f = command_start, .string = "C-a" },
            Fn { .f = selection_mode,  .string = "C-Spc" },
        };
    }
};

fn space(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *CommandLine = @ptrCast(@alignCast(ptr));
    try self.insert_string(" ");
}

fn prev_char(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *CommandLine = @ptrCast(@alignCast(ptr));
    const cursor = self.cursor orelse return error.NoCursor;

    if (cursor <= PREFIX.len) return error.NoPrevChar;

    self.move_cursor(cursor - 1);
}

fn next_char(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *CommandLine = @ptrCast(@alignCast(ptr));
    const cursor = self.cursor orelse return error.NoCursor;
    const len: u32 = @intCast(PREFIX.len);

    if (cursor >= self.content.len() + len) return error.NoNextChar;

    self.move_cursor(cursor + 1);
}

fn command_end(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *CommandLine = @ptrCast(@alignCast(ptr));
    const len: u32 = @intCast(PREFIX.len);
    _ = self.cursor orelse return error.NoCursor;

    self.move_cursor(self.content.len() + len);
}

fn command_start(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *CommandLine = @ptrCast(@alignCast(ptr));
    const len: u32 = @intCast(PREFIX.len);
    _ = self.cursor orelse return error.NoCursor;

    self.move_cursor(len);
}

fn selection_mode(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *CommandLine = @ptrCast(@alignCast(ptr));

    if (self.selection) |_| {
        self.selection = null;
    } else {
        self.selection = self.cursor;
    }
}

fn delete(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *CommandLine = @ptrCast(@alignCast(ptr));
    const len: u32 = @intCast(PREFIX.len);

    const cursor = self.cursor orelse return error.NoCursor;
    const selection = self.selection orelse cursor;

    const start = if (selection > cursor) cursor - len else selection - len ;
    var end = if (cursor > selection) cursor - len else selection - len;

    if (end < self.content.len()) end += 1;
    util.copy(u8, self.content.items[end..], self.content.items[start..]);

    self.content.items.len -= end - start;
    self.cursor = start + len;
    self.selection = null;
}

// pub fn update(self: *ModeLine) !void {
//     @setRuntimeSafety(false);

//     const buff = &core.buffers[core.buffer_index];
//     const rows = core.rows - 1;
//     const cols = core.cols - 1;
//     const color = highlight.get_id_color(0);

//     // if (core.mode_line.mode == .Command) {
//     //     {
//     //         const position: [2]u32 = .{ 0, rows };
//     //         const index = ':' - 32;
//     //         try wayland.push_char(core, index, position, color);
//     //     }

//     //     {
//     //         const len = core.mode_line.line.char_count;

//     //         for (0..len) |i| {
//     //             const position: [2]u32 = .{ @intCast(i + 1), rows };
//     //             const index = core.mode_line.line.content[i] - 32;
//     //             try wayland.push_char(core, index, position, color);
//     //         }
//     //     }
//     // } else {
//     var string: [10]u8 = undefined;
//     var k: u32 = 0;

//     {
//         const len = util.parse(buff.cursor.x, &string);
//         for (0..len) |i| {
//             const position: [2]u32 = .{ @intCast(cols - k), rows };
//             const index = string[i] - 32;
//             try wayland.push_char(core, index, position, color);
//             k += 1;
//         }
//     }

//     {
//         const sep = ", col: ";
//         const len = sep.len;

//         for (0..len) |i| {
//             const position: [2]u32 = .{ @intCast(cols - k), rows };
//             const index = sep[len - i - 1] - 32;
//             try wayland.push_char(core, index, position, color);
//             k += 1;
//         }
//     }

//     {
//         const len = util.parse(buff.cursor.y, &string);

//         for (0..len) |i| {
//             const position: [2]u32 = .{ @intCast(cols - k), rows };
//             const index = string[i] - 32;
//             try wayland.push_char(core, index, position, color);
//             k += 1;
//         }
//     }

//     {
//         const sep = "line: ";

//         const len = sep.len;
//         for (0..len) |i| {
//             const position: [2]u32 = .{ @intCast(cols - k), rows };
//             const index = sep[len - i - 1] - 32;
//             try wayland.push_char(core, index, position, color);
//             k += 1;
//         }

//     }

//     {
//         const len = buff.name.len;
//         for (0..len) |i| {
//             const position: [2]u32 = .{ @intCast(i), rows };
//             const index = buff.name[i] - 32;
//             try wayland.push_char(core, index, position, color);
//         }
//     }
// }
