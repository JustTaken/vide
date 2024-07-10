const std = @import("std");

const Allocator = std.mem.Allocator;

const MAX_BYTES: u32 = 20000;

const OPEN = "open";
const BUFFER = "buffer";
const SAVE = "save";
const NEXT_CHAR = "next_char";
const PREV_CHAR = "prev_char";
const NEXT_CMD_CHAR = "next_cmd_char";
const PREV_CMD_CHAR = "prev_cmd_char";
const ACTIVATE = "activate";

pub const CommandLine = struct {
    content: []u8,
    allocator: Allocator,

    pub fn init(cols: u32, allocator: Allocator) !CommandLine {
        return CommandLine {
            .content = try allocator.alloc(u8, cols),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *const CommandLine) void {
        self.allocator.free(self.content);
    }
};

// pub fn reset(self: *Self) void {
//     self.last = null;
// }

// pub fn activate_mode(self: *Self) void {
//     const buff = &self.window.buffers[self.window.buffer_index];

//     self.window.mode = .Command;
//     self.window.mode_line.cursor = buff.cursor;
//     self.window.mode_line.line.char_count = 0;

//     buffer.place_cursor(buff, .{ 1, self.window.rows - 1 }, 0);
//     // try wayland.chars_update(core);
// }

// fn open_file(self: *Self, file_path: []const u8) !void {
//     const window = self.window;

//     self.open_buffer(file_path) catch {
//         if (window.buffers.len <= window.buffer_count) {
//             const new = window.allocator.alloc(buffer.Buffer, window.buffers.len * 2) catch return Error.AllocationFail;
//             util.copy(buffer.Buffer, window.buffers, new);

//             window.allocator.free(window.buffers);

//             window.buffers.ptr = new.ptr;
//             window.buffers.len = new.len;
//         }

//         const buff = &window.buffers[window.buffer_count];

//         {
//             const file = std.fs.cwd().openFile(file_path, .{}) catch return Error.FileNotFound;
//             defer file.close();

//             const end_pos = file.getEndPos() catch return Error.FileReadFail;
//             if (end_pos >= MAX_BYTES) {
//                 std.debug.print("File too big, max is {} bytes\n", .{MAX_BYTES});
//                 return;
//             }

//             const content = window.allocator.alloc(u8, math.max(50, @intCast(end_pos))) catch return Error.AllocationFail;
//             defer window.allocator.free(content);

//             const len = file.read(content) catch return Error.FileReadFail;

//             const line_count = content.len / 50;
//             buff.line_count = 1;
//             buff.lines = window.allocator.alloc(buffer.Line, line_count) catch return Error.AllocationFail;

//             var line = &buff.lines[0];
//             line.char_count = 0;
//             line.content = window.allocator.alloc(u8, 50) catch return Error.AllocationFail;
//             line.indent = 0;
//             var indent_flag = false;

//             for (0..len) |i| {
//                 if (buff.line_count >= buff.lines.len) {
//                     const new = window.allocator.alloc(buffer.Line, buff.lines.len * 2) catch return Error.AllocationFail;
//                     util.copy(buffer.Line, buff.lines, new);

//                     window.allocator.free(buff.lines);

//                     buff.lines.ptr = new.ptr;
//                     buff.lines.len = new.len;

//                     line = &buff.lines[buff.line_count - 1];
//                 }

//                 if (content[i] == '\n') {
//                     line = &buff.lines[buff.line_count];
//                     line.content = window.allocator.alloc(u8, 50) catch return Error.AllocationFail;
//                     line.char_count = 0;
//                     line.indent = 0;
//                     buff.line_count += 1;
//                     indent_flag = false;

//                     continue;
//                 }

//                 if (content[i] != ' ') {
//                     indent_flag = true;
//                 } else if (!indent_flag) {
//                     line.indent += 1;
//                 }

//                 if (line.content.len <= line.char_count + 1) {
//                     const new = window.allocator.alloc(u8, line.content.len * 2) catch return Error.AllocationFail;

//                     util.copy(u8, line.content, new);
//                     window.allocator.free(line.content);

//                     line.content.ptr = new.ptr;
//                     line.content.len = new.len;
//                 }

//                 line.content[line.char_count] = content[i];
//                 line.char_count += 1;
//             }
//         }

//         buff.offset = .{ 0, 0 };
//         buff.cursor = buffer.Cursor {
//             .x = 0,
//             .y = 0,
//             .byte_offset = 0,
//         };

//         buff.selection_active = false;
//         buff.selection = buffer.Cursor {
//             .x = 0,
//             .y = 0,
//             .byte_offset = 0,
//         };

//         buff.name = window.allocator.alloc(u8, file_path.len) catch return Error.AllocationFail;
//         for (0..file_path.len) |i| {
//             buff.name[i] = file_path[i];
//         }

//         {
//             var last_dot = file_path.len;
//             for (0..file_path.len) |i| {
//                 if (file_path[i] == '.') last_dot = i;
//             }

//             highlight.init(buff, window.allocator, window.rows, file_path[last_dot + 1..]);
//         }

//         window.buffer_index = window.buffer_count;
//         window.buffer_count += 1;
//     };
// }

// fn open_buffer(self: *Self, buffer_name: []const u8) Error!void {
//     for (0..self.window.buffer_count) |i| {
//         if (std.mem.eql(u8, buffer_name, self.window.buffers[i].name)) {
//             self.window.buffer_index = @intCast(i);
//             break;
//         }
//     } else {
//         return Error.NoSuchBuffer;
//     }
// }

// fn insert_last_char(self: *Self) Error!void {
//     const buff = &self.window.buffers[self.window.buffer_index];
//     const line = &buffer.lines[buffer.cursor.y];

//     line.content.insert(self.window.last_char, buffer.cursor.x);

//     // if (len <= line.char_count + 1) {
//     //     const new = self.window.allocator.alloc(u8, len * 2);

//     //     util.copy(u8, line.content[0..buffer.cursor.x], new[0..buffer.cursor.x]);
//     //     util.copy(u8, line.content[buffer.cursor.x..line.char_count], new[buffer.cursor.x + 1..line.char_count + 1]);

//     //     self.window.allocator.free(line.content);
//     //     line.content.ptr = new.ptr;
//     //     line.content.len = new.len;
//     // } else {
//     //     const dif = line.char_count - buffer.cursor.x;
//     //     for (0..dif) |i| {
//     //         line.content[line.char_count - i] = line.content[line.char_count - i - 1];
//     //     }
//     // }

//     // line.content[buffer.cursor.x] = self.window.last_char;
//     // const prev_cursor = buffer.cursor;

//     place_cursor(buffer, .{ buffer.cursor.x + 1, buffer.cursor.y }, buffer.cursor.byte_offset + 1);

//     // line.char_count += 1;

//     // _ = check_col_offset(buffer, self.window.cols);
//     // if (buffer.highlight.on) {
//     //     try highlight.edit_tree(
//     //         &buffer.highlight,
//     //         .Add,
//     //         &prev_cursor,
//     //         &buffer.cursor,
//     //         buffer.offset[1],
//     //         self.window.rows - 1,
//     //     );
//     // }
// }

// fn save_buffer(self: *Self) Error!void {
//     const buff = &self.window.buffers[self.window.buffer_index];
//     _ = buff;
//     // var content = Vec(u8).init(self.window.allocator, buff.line_count * 50) catch return CommandError.AllocationFail;

//     // var index: u32 = 0;

//     // for (0..buff.line_count) |i| {
//     //     const line = &buff.lines[i];
//     //     // content.push()
//     //     if (content.len < buff.lines[i].char_count + index + 1) {
//     //         content = self.window.allocator.realloc(content, content.len * 2) catch return CommandError.AllocationFail;
//     //     }

//     //     util.copy(u8, line.content[0..line.char_count], content[index..]);
//     //     index += line.char_count + 1;

//     //     content[index - 1] = '\n';
//     // }


//     // const file = std.fs.cwd().openFile(buff.name, .{ .mode = .write_only, }) catch return CommandError.FileReadFail;

//     // _ = file.write(content[0..index - 1]) catch return CommandError.FileWriteFail;

//     // file.close();
//     // self.window.allocator.free(content);
// }

// pub fn execute(self: *Self, command_string: []const u8) Error!void {
//     var argument_start = command_string.len;

//     for (0..command_string.len) |i| {
//         if (command_string[i] == ' ') {
//             argument_start = @intCast(i + 1);
//             break;
//         }
//     }

//     const command = command_string[0..argument_start];
//     const argument = command_string[argument_start..];

//     const cmd = util.hash(command);

//     switch (cmd) {
//         util.hash(OPEN) => try self.open_file(argument),
//         util.hash(BUFFER) => try self.open_buffer(argument),
//         util.hash(SAVE) => try self.save_buffer(),
//         util.hash(ACTIVATE) => self.activate_mode(),
//         else => return Error.CommandNotFound,
//     }
// }
