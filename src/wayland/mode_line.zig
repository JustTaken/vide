const std = @import("std");
const buffer = @import("buffer.zig");
const util = @import("util.zig");
const wayland = @import("core.zig");
const highlight = @import("highlight.zig");
const Line = buffer.Line;
const Cursor = buffer.Cursor;
const Wayland = wayland.Wayland;
const Allocator = std.mem.Allocator;

const ModeLineMode = enum {
    Command,
    Normal,
};

pub const ModeLine = struct {
    mode: ModeLineMode,
    line: Line,
    cursor: Cursor,
};

pub fn mode_line_init(allocator: Allocator) !ModeLine {
    return ModeLine {
        .mode = .Normal,
        .line = Line {
            .content = try allocator.alloc(u8, 50),
            .char_count = 0,
            .indent = 0,
        },
        .cursor = Cursor {
            .x = 0,
            .y = 0,
            .byte_offset = 0,
        },
    };
}

pub fn update_mode_line(core: *Wayland) !void {
    @setRuntimeSafety(false);

    const buff = &core.buffers[core.buffer_index];
    const rows = core.rows - 1;
    const cols = core.cols - 1;
    const color = highlight.get_id_color(0);

    if (core.mode_line.mode == .Command) {
        {
            const position: [2]u32 = .{ 0, rows };
            const index = ':' - 32;
            try wayland.push_char(core, index, position, color);
        }

        {
            const len = core.mode_line.line.char_count;

            for (0..len) |i| {
                const position: [2]u32 = .{ @intCast(i + 1), rows };
                const index = core.mode_line.line.content[i] - 32;
                try wayland.push_char(core, index, position, color);
            }
        }
    } else {
        var string: [10]u8 = undefined;
        var k: u32 = 0;

        {
            const len = util.parse(buff.cursor.x, &string);
            for (0..len) |i| {
                const position: [2]u32 = .{ @intCast(cols - k), rows };
                const index = string[i] - 32;
                try wayland.push_char(core, index, position, color);
                k += 1;
            }
        }

        {
            const sep = ", col: ";
            const len = sep.len;

            for (0..len) |i| {
                const position: [2]u32 = .{ @intCast(cols - k), rows };
                const index = sep[len - i - 1] - 32;
                try wayland.push_char(core, index, position, color);
                k += 1;
            }
        }

        {
            const len = util.parse(buff.cursor.y, &string);

            for (0..len) |i| {
                const position: [2]u32 = .{ @intCast(cols - k), rows };
                const index = string[i] - 32;
                try wayland.push_char(core, index, position, color);
                k += 1;
            }
        }

        {
            const sep = "line: ";

            const len = sep.len;
            for (0..len) |i| {
                const position: [2]u32 = .{ @intCast(cols - k), rows };
                const index = sep[len - i - 1] - 32;
                try wayland.push_char(core, index, position, color);
                k += 1;
            }

        }

        {
            const len = buff.name.len;
            for (0..len) |i| {
                const position: [2]u32 = .{ @intCast(i), rows };
                const index = buff.name[i] - 32;
                try wayland.push_char(core, index, position, color);
            }
        }
    }
}
