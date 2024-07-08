const std = @import("std");
const wayland = @import("core.zig");
const Wayland = wayland.Wayland;
const highlight = @import("highlight.zig");
const buffer = @import("buffer.zig");
const util = @import("util.zig");

const math = @import("../math.zig");

const Allocator = std.mem.Allocator;

const MAX_BYTES: u32 = 20000;

const OPEN = "open";
const BUFFER = "buffer";
const SAVE = "save";

pub fn command_mode(core: *Wayland) !void {
    const buff = &core.buffers[core.buffer_index];
    if (core.mode_line.mode == .Command) return;

    core.mode_line.mode = .Command;
    core.mode_line.cursor = buff.cursor;
    core.mode_line.line.char_count = 0;
    buffer.place_cursor(buff, .{ 1, core.rows - 1 }, 0);

    try wayland.chars_update(core);
}

fn open_file(core: *Wayland, file_path: []const u8) !void {
    open_buffer(core, file_path) catch {
        if (core.buffers.len <= core.buffer_count) {
            const new = try core.allocator.alloc(buffer.Buffer, core.buffers.len * 2);
            util.copy(buffer.Buffer, core.buffers, new);

            core.allocator.free(core.buffers);

            core.buffers.ptr = new.ptr;
            core.buffers.len = new.len;
        }

        const buff = &core.buffers[core.buffer_count];

        {
            const file = try std.fs.cwd().openFile(file_path, .{});
            defer file.close();

            const end_pos = try file.getEndPos();
            if (end_pos >= MAX_BYTES) {
                std.debug.print("File too big, max is {} bytes\n", .{MAX_BYTES});
                return;
            }

            const content = try core.allocator.alloc(u8, math.max(50, @intCast(end_pos)));
            defer core.allocator.free(content);

            const len = try file.read(content);

            const line_count = content.len / 50;
            buff.line_count = 1;
            buff.lines = try core.allocator.alloc(buffer.Line, line_count);

            var line = &buff.lines[0];
            line.char_count = 0;
            line.content = try core.allocator.alloc(u8, 50);
            line.indent = 0;
            var indent_flag = false;

            for (0..len) |i| {
                if (buff.line_count >= buff.lines.len) {
                    const new = try core.allocator.alloc(buffer.Line, buff.lines.len * 2);
                    util.copy(buffer.Line, buff.lines, new);

                    core.allocator.free(buff.lines);

                    buff.lines.ptr = new.ptr;
                    buff.lines.len = new.len;

                    line = &buff.lines[buff.line_count - 1];
                }

                if (content[i] == '\n') {
                    line = &buff.lines[buff.line_count];
                    line.content = try core.allocator.alloc(u8, 50);
                    line.char_count = 0;
                    line.indent = 0;
                    buff.line_count += 1;
                    indent_flag = false;

                    continue;
                }

                if (content[i] != ' ') {
                    indent_flag = true;
                } else if (!indent_flag) {
                    line.indent += 1;
                }

                if (line.content.len <= line.char_count + 1) {
                    const new = try core.allocator.alloc(u8, line.content.len * 2);

                    util.copy(u8, line.content, new);
                    core.allocator.free(line.content);

                    line.content.ptr = new.ptr;
                    line.content.len = new.len;
                }

                line.content[line.char_count] = content[i];
                line.char_count += 1;
            }
        }

        buff.offset = .{ 0, 0 };
        buff.cursor = buffer.Cursor {
            .x = 0,
            .y = 0,
            .byte_offset = 0,
        };

        buff.selection_active = false;
        buff.selection = buffer.Cursor {
            .x = 0,
            .y = 0,
            .byte_offset = 0,
        };

        buff.name = try core.allocator.alloc(u8, file_path.len);
        for (0..file_path.len) |i| {
            buff.name[i] = file_path[i];
        }

        {
            var last_dot = file_path.len;
            for (0..file_path.len) |i| {
                if (file_path[i] == '.') last_dot = i;
            }

            highlight.init(buff, core.allocator, core.rows, file_path[last_dot + 1..]);
        }

        core.buffer_index = core.buffer_count;
        core.buffer_count += 1;
    };
}

fn open_buffer(core: *Wayland, buffer_name: []const u8) !void {
    for (0..core.buffer_count) |i| {
        if (std.mem.eql(u8, buffer_name, core.buffers[i].name)) {
            core.buffer_index = @intCast(i);
            break;
        }
    } else {
        return error.NoSuchBuffer;
    }
}

fn save_buffer(core: *Wayland) !void {
    const buff = &core.buffers[core.buffer_index];
    var content = try core.allocator.alloc(u8, buff.line_count * 50);

    var index: u32 = 0;

    for (0..buff.line_count) |i| {
        const line = &buff.lines[i];
        if (content.len < buff.lines[i].char_count + index + 1) {
            content = try core.allocator.realloc(content, content.len * 2);
        }

        util.copy(u8, line.content[0..line.char_count], content[index..]);
        index += line.char_count + 1;

        content[index - 1] = '\n';
    }


    const file = try std.fs.cwd().openFile(buff.name, .{ .mode = .write_only, });

    _ = try file.write(content[0..index - 1]);

    file.close();
    core.allocator.free(content);
}

pub fn execute_command(core: *Wayland) !void {
    const line = core.mode_line.line;
    const len = line.char_count;

    var argument_start: u32 = len;
    var command = line.content[0..len];

    for (0..len) |i| {
        if (line.content[i] == ' ') {
            argument_start = @intCast(i + 1);
            command = line.content[0..i];
            break;
        }
    }

    const argument = line.content[argument_start..len];
    const h = util.hash(command);

    switch (h) {
        util.hash(OPEN) => try open_file(core, argument),
        util.hash(BUFFER) => try open_buffer(core, argument),
        util.hash(SAVE) => try save_buffer(core),
        else => std.debug.print("alguma outra coisa\n", .{}),
    }
}
