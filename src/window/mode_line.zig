const std = @import("std");

const Allocator = std.mem.Allocator;

pub const ModeLine = struct {
    content: []u8,
    allocator: Allocator,

    pub fn init(cols: u32, allocator: Allocator) !ModeLine {
        return ModeLine {
            .content = try allocator.alloc(u8, cols),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *const ModeLine) void {
        self.allocator.free(self.content);
    }
};

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
