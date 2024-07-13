const std = @import("std");
const util = @import("../util.zig");

const Allocator = std.mem.Allocator;
const Vec = @import("../collections.zig").Vec;
const Fn = @import("command.zig").FnSub;
const Cursor = @import("../math.zig").Vec2D;

pub const ModeLine = struct {
    content: Vec(u8),
    row: u32,
    cursor: ?Cursor,

    pub fn init(rows: u32, allocator: Allocator) !ModeLine {
        return ModeLine {
            .content = try Vec(u8).init(50, allocator),
            .cursor = null,
            .row = rows - 1,
        };
    }

    pub fn insert_string(self: *ModeLine, string: []const u8) !void {
        if (self.cursor) |*cursor| {
            try self.content.extend_insert(string, cursor.x - 1);
            const len: u32 = @intCast(string.len);
            cursor.move(&Cursor.init(cursor.x + len, cursor.y));
        } else {
            return error.NoCursor;
        }
    }

    pub fn set_row(self: *ModeLine, rows: u32) void {
        self.row = rows - 1;

        if (self.cursor) |*cursor| {
            cursor.y = self.row;
        }
    }

    pub fn toggle_cursor(self: *ModeLine) void {
        if (self.cursor) |_| {
            self.cursor = null;
        } else {
            self.cursor = Cursor.init(1, self.row);
        }
    }

    pub fn chars(self: *const ModeLine) []const u8 {
        return self.content.elements();
    }

    pub fn char_iter(
        self: *const ModeLine, 
        T: type, 
        ptr: *T, 
        f: fn (*T, u8, usize, usize) anyerror!void
    ) !void {

        if (self.cursor) |_| {
            try f(ptr, ':', 0, self.row);
        }
        for (self.content.elements(), 0..) |char, j| {
            try f(ptr, char, j + 1, self.row);
        }
    }

    pub fn cursor_back(
        self: *const ModeLine,
        T: type,
        ptr: *T,
        f: fn(*T, usize, usize) anyerror!void
    ) !void {
        if (self.cursor) |cursor| {
            try f(ptr, cursor.x, cursor.y);
        }
    }

    pub fn deinit(self: *const ModeLine) void {
        self.content.deinit();
    }

    pub fn commands() []const Fn {
        return &[_]Fn {
            Fn {
                .f = enter,
                .hash = util.hash_key("\n"),
            },
        };
    }
};

fn enter(ptr: *anyopaque) !void {
    const self: *ModeLine = @ptrCast(@alignCast(ptr));
    _ = self;
    std.debug.print("mode line return\n", .{});
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
