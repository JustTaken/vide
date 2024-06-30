const std = @import("std");
const c = @import("../bind.zig").c;
const math = @import("../math.zig");

const Allocator = std.mem.Allocator;
const Instant = std.time.Instant;
const CHAR_COUNT: u32 = 95;

pub const Wayland = struct {
    display: *c.wl_display,
    registry: *c.wl_registry,
    surface: *c.wl_surface,
    seat: *c.wl_seat,
    compositor: *c.wl_compositor,
    keyboard: *c.wl_keyboard,

    xdg_shell: *c.xdg_wm_base,
    xdg_surface: *c.xdg_surface,
    xdg_toplevel: *c.xdg_toplevel,

    registry_listener: c.wl_registry_listener,
    shell_listener: c.xdg_wm_base_listener,
    shell_surface_listener: c.xdg_surface_listener,
    xdg_toplevel_listener: c.xdg_toplevel_listener,
    seat_listener: c.wl_seat_listener,
    keyboard_listener: c.wl_keyboard_listener,

    buffers: []Buffer,
    buffer_count: u32,
    chars: [CHAR_COUNT] Char,
    mode_line: ModeLine,
    last_char: u8,

    buffer_index: u32,
    update: bool,
    running: bool,
    resize: bool,

    control: bool,
    alt: bool,
    shift: bool,

    cols: u32,
    rows: u32,

    font_ratio: f32,
    font_scale: f32,
    scale: f32,

    key_delay: u64,
    key_rate: u64,

    last_fetch_delay: Instant,
    last_fetch_rate: Instant,

    width: u32,
    height: u32,

    last_fn: ?*const fn(*Wayland) anyerror!void,
    allocator: Allocator,
};

const Buffer = struct {
    name: []u8,
    lines: []Line,
    line_count: u32,
    offset: [2]u32,
    cursor: Cursor,
    selection: Cursor,
    selection_active: bool,
};

const Line = struct {
    content: []u8,
    char_count: u32,
};

const ModeLineMode = enum {
    Command,
    Normal,
};

const ModeLine = struct {
    mode: ModeLineMode,
    line: Line,
    cursor: Cursor,
};

const Cursor = struct {
    x: u32,
    y: u32,
};

const Char = struct {
    pos: [][2]u32,
    capacity: u32,
};

pub inline fn get_positions(core: *const Wayland, index: usize) [][2]u32 {
    return core.chars[index].pos;
}

pub inline fn get_cursor_position(core: *const Wayland) [2]u32 {
    const buffer = &core.buffers[core.buffer_index];

    if (core.mode_line.mode == .Command) {
        return .{ buffer.cursor.x, buffer.cursor.y };
    }

    return .{ buffer.cursor.x - buffer.offset[0], buffer.cursor.y - buffer.offset[1] };
}

pub inline fn is_selection_active(core: *const Wayland) bool {
    const buffer = &core.buffers[core.buffer_index];

    return buffer.selection_active;
}

pub inline fn get_selection_boundary(core: *const Wayland) [4]u32 {
    const buffer = &core.buffers[core.buffer_index];

    const start: [2]u32 = blk: {
        if (buffer.cursor.y == buffer.selection.y) {
            if (buffer.cursor.x < buffer.selection.x) {
                break :blk .{ buffer.cursor.x, buffer.cursor.y };
            }

            break :blk .{ buffer.selection.x, buffer.selection.y };
        }

        if (buffer.cursor.y < buffer.selection.y) {
            break :blk .{ buffer.cursor.x, buffer.cursor.y };
        }

        break :blk .{ buffer.selection.x, buffer.selection.y };
    };

    const end: [2]u32 = .{ buffer.cursor.x + buffer.selection.x - start[0], buffer.cursor.y + buffer.selection.y - start[1] };

    return .{
        start[0],
        start[1],
        end[0],
        end[1],
    };
}

pub inline fn get_selected_lines(core: *const Wayland) []Line {
    const buffer = &core.buffers[core.buffer_index];

    return buffer.lines;
}

pub inline fn place_cursor(buffer: *Buffer, position: [2]u32) void {
    buffer.cursor.x = position[0];
    buffer.cursor.y = position[1];

    if (!buffer.selection_active) {
        buffer.selection.x = buffer.cursor.x;
        buffer.selection.y = buffer.cursor.y;
    }
}

fn buffer_init(allocator: Allocator) !Buffer {
    var buffer: Buffer = undefined;
    const name = "scratch";

    buffer.name = try allocator.alloc(u8, name.len);
    buffer.lines = try allocator.alloc(Line, 10);
    buffer.offset = .{ 0, 0 };
    buffer.line_count = 1;
    buffer.selection_active = false;
    buffer.selection = Cursor {
        .x = 0,
        .y = 0,
    };

    buffer.lines[0] = Line {
        .content = try allocator.alloc(u8, 50),
        .char_count = 0,
    };

    buffer.cursor = Cursor {
        .x = 0,
        .y = 0,
    };

    for (0..name.len) |i| {
        buffer.name[i] = name[i];
    }

    return buffer;
}

fn mode_line_init(allocator: Allocator) !ModeLine {
    return ModeLine {
        .mode = .Normal,
        .line = Line {
            .content = try allocator.alloc(u8, 50),
            .char_count = 0,
        },
        .cursor = Cursor {
            .x = 0,
            .y = 0,
        },
    };
}

inline fn reset_chars(core: *Wayland) void {
    for (0..CHAR_COUNT) |i| {
        core.chars[i].pos.len = 0;
    }
}

inline fn copy(T: type, src: []const T, dst: []T) void {
    @setRuntimeSafety(false);

    const len = src.len;

    for (0..len) |i| {
        dst[i] = src[i];
    }
}

fn parse(i: u32, buffer: []u8) u32 {
    var k: u32 = 0;
    var num = i;

    if (i == 0) {
        buffer[0] = '0';
        return 1;
    }

    while (num > 0) {
        const rem: u8 = @intCast(num % 10);
        buffer[k] = rem + '0';

        k += 1;
        num /= 10;
    }

    return k;
}

inline fn push_char(core: *Wayland, index: u32, pos: [2]u32) !void {
    @setRuntimeSafety(false);

    const char: *Char = &core.chars[index];
    const len = char.pos.len;

    if (char.capacity <= len) {
        const new = try core.allocator.alloc([2]u32, char.capacity * 2);

        copy([2]u32, char.pos, new);
        core.allocator.free(char.pos);

        char.capacity = @intCast(new.len);
        char.pos.ptr = new.ptr;
    }

    char.pos[len] = pos;
    char.pos.len += 1;
}

fn update_mode_line(core: *Wayland) !void {
    @setRuntimeSafety(false);

    const buffer = &core.buffers[core.buffer_index];
    const rows = core.rows - 1;
    const cols = core.cols - 1;

    if (core.mode_line.mode == .Command) {
        {
            const position: [2]u32 = .{ 0, rows };
            const index = ':' - 32;
            try push_char(core, index, position);
        }

        {
            const len = core.mode_line.line.char_count;

            for (0..len) |i| {
                const position: [2]u32 = .{ @intCast(i + 1), rows };
                const index = core.mode_line.line.content[i] - 32;
                try push_char(core, index, position);
            }
        }
    } else {
        var string: [10]u8 = undefined;
        var k: u32 = 0;

        {
            const len = parse(buffer.cursor.x, &string);
            for (0..len) |i| {
                const position: [2]u32 = .{ @intCast(cols - k), rows };
                const index = string[i] - 32;
                try push_char(core, index, position);
                k += 1;
            }
        }

        {
            const sep = ", col: ";
            const len = sep.len;

            for (0..len) |i| {
                const position: [2]u32 = .{ @intCast(cols - k), rows };
                const index = sep[len - i - 1] - 32;
                try push_char(core, index, position);
                k += 1;
            }
        }

        {
            const len = parse(buffer.cursor.y, &string);

            for (0..len) |i| {
                const position: [2]u32 = .{ @intCast(cols - k), rows };
                const index = string[i] - 32;
                try push_char(core, index, position);
                k += 1;
            }
        }

        {
            const sep = "line: ";

            const len = sep.len;
            for (0..len) |i| {
                const position: [2]u32 = .{ @intCast(cols - k), rows };
                const index = sep[len - i - 1] - 32;
                try push_char(core, index, position);
                k += 1;
            }

        }

        {
            const len = buffer.name.len;
            for (0..len) |i| {
                const position: [2]u32 = .{ @intCast(i), rows };
                const index = buffer.name[i] - 32;
                try push_char(core, index, position);
            }
        }
    }
}

fn chars_update(
    core: *Wayland,
) !void {
    @setRuntimeSafety(false);

    const buffer: *Buffer = &core.buffers[core.buffer_index];
    reset_chars(core);

    const y_max = buffer.offset[1] + core.rows - 1;
    const line_max = math.min(y_max, buffer.line_count);

    for (buffer.offset[1]..line_max) |i| {
        if (buffer.lines[i].char_count <= buffer.offset[0]) continue;

        const x_max = buffer.offset[0] + core.cols - 1;
        const col_max = math.min(x_max, buffer.lines[i].char_count);

        for (buffer.offset[0]..col_max) |j| {
            const index = buffer.lines[i].content[j] - 32;
            if (index == 0) continue;

            const position: [2]u32 = .{ @intCast(j - buffer.offset[0]), @intCast(i - buffer.offset[1]) };
            try push_char(core, index, position);
        }
    }

    try update_mode_line(core);

    core.update = true;
}

fn check_col_offset(buffer: *Buffer, cols: u32) void {
    const last_index = cols - 1;

    if (last_index + buffer.offset[0] < buffer.cursor.x) {
        buffer.offset[0] = buffer.cursor.x - last_index;
    } else if (buffer.cursor.x < buffer.offset[0]) {
        buffer.offset[0] = buffer.cursor.x;
    }
}

fn check_row_offset(buffer: *Buffer, rows: u32) void {
    const last_index = rows - 1;

    if (last_index + buffer.offset[1] < buffer.cursor.y) {
        buffer.offset[1] = buffer.cursor.y - last_index;
    } else if (buffer.cursor.y < buffer.offset[1]) {
        buffer.offset[1] = buffer.cursor.y;
    }
}

fn hash(string: []const u8) u32 {
    var h: u32 = 0;
    const len: u32 = @intCast(string.len);

    for (0..len) |i| {
        const index: u32 = @intCast(i);
        h += string[i] + index;
    }

    return h * len;
}

const OPEN = "open";
const BUFFER = "buffer";
const SAVE = "save";

fn open_file(core: *Wayland, file_path: []const u8) !void {
    open_buffer(core, file_path) catch {
        const start = try Instant.now();
        var buffer: Buffer = undefined;

        {
            const file = try std.fs.cwd().openFile(file_path, .{});
            defer file.close();

            const end_pos = try file.getEndPos();
            const content = try core.allocator.alloc(u8, end_pos);
            defer core.allocator.free(content);

            const len = try file.read(content);

            const line_count = len / 50;
            buffer.line_count = 1;
            buffer.lines = try core.allocator.alloc(Line, line_count);

            var line = &buffer.lines[0];
            line.char_count = 0;
            line.content = try core.allocator.alloc(u8, 50);

            for (0..len) |i| {
                if (buffer.line_count >= buffer.lines.len) {
                    const new = try core.allocator.alloc(Line, buffer.lines.len * 2);
                    copy(Line, buffer.lines, new);

                    core.allocator.free(buffer.lines);

                    buffer.lines.ptr = new.ptr;
                    buffer.lines.len = new.len;

                    line = &buffer.lines[buffer.line_count - 1];
                }

                if (content[i] == '\n') {
                    line = &buffer.lines[buffer.line_count];
                    line.content = try core.allocator.alloc(u8, 50);
                    line.char_count = 0;
                    buffer.line_count += 1;

                    continue;
                }

                if (line.content.len <= line.char_count) {
                    const new = try core.allocator.alloc(u8, line.content.len * 2);

                    copy(u8, line.content, new);
                    core.allocator.free(line.content);

                    line.content.ptr = new.ptr;
                    line.content.len = new.len;
                }

                line.content[line.char_count] = content[i];
                line.char_count += 1;
            }
        }

        buffer.offset = .{ 0, 0 };
        buffer.cursor = Cursor {
            .x = 0,
            .y = 0,
        };

        buffer.selection_active = false;
        buffer.selection = Cursor {
            .x = 0,
            .y = 0,
        };

        buffer.name = try core.allocator.alloc(u8, file_path.len);
        for (0..file_path.len) |i| {
            buffer.name[i] = file_path[i];
        }

        if (core.buffers.len <= core.buffer_count) {
            const new = try core.allocator.alloc(Buffer, core.buffers.len * 2);
            copy(Buffer, core.buffers, new);

            core.allocator.free(core.buffers);

            core.buffers.ptr = new.ptr;
            core.buffers.len = new.len;
        }

        core.buffers[core.buffer_count] = buffer;
        core.buffer_index = core.buffer_count;
        core.buffer_count += 1;

        const end = try Instant.now();
        std.debug.print("open file time: {} ns\n", .{end.since(start)});
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
    const buffer = &core.buffers[core.buffer_index];
    var content = try core.allocator.alloc(u8, buffer.line_count * 50);
    defer core.allocator.free(content);
    var index: u32 = 0;
    for (0..buffer.line_count) |i| {
        const line = &buffer.lines[i];
        if (content.len < buffer.lines[i].char_count + index + 1) {
            content = try core.allocator.realloc(content, content.len * 2);
        }

        copy(u8, line.content[0..line.char_count], content[index..]);
        index += line.char_count + 1;

        content[index - 1] = '\n';
    }

    const file = try std.fs.cwd().openFile(buffer.name, .{ .mode = .write_only, });

    defer file.close();

    _ = try file.write(content[0..index - 1]);
}

fn execute_command(core: *Wayland) !void {
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
    const h = hash(command);

    switch (h) {
        hash(OPEN) => try open_file(core, argument),
        hash(BUFFER) => try open_buffer(core, argument),
        hash(SAVE) => try save_buffer(core),
        else => std.debug.print("alguma outra coisa\n", .{}),
    }
}

fn enter(core: *Wayland) !void {
    const buffer = &core.buffers[core.buffer_index];

    if (core.mode_line.mode == .Command) {
        core.mode_line.mode = .Normal;
        buffer.cursor = core.mode_line.cursor;

        execute_command(core) catch |e| {
            std.debug.print("error: {any}\n", .{e});
            return e;
        };

        try chars_update(core);
        return;
    }

    place_cursor(buffer, .{ buffer.cursor.x, buffer.cursor.y + 1 });

    const len = buffer.lines.len;
    if (len <= buffer.line_count) {
        const new = try core.allocator.alloc(Line, len * 2);

        copy(Line, buffer.lines[0..buffer.cursor.y], new[0..buffer.cursor.y]);
        copy(Line, buffer.lines[buffer.cursor.y..], new[buffer.cursor.y + 1..]);

        core.allocator.free(buffer.lines);
        buffer.lines.ptr = new.ptr;
        buffer.lines.len = new.len;
    } else {
        const ii = buffer.line_count - buffer.cursor.y;

        for (0..ii) |i| {
            buffer.lines[buffer.line_count - i].content.ptr = buffer.lines[buffer.line_count - 1 - i].content.ptr;
            buffer.lines[buffer.line_count - i].content.len = buffer.lines[buffer.line_count - 1 - i].content.len;
            buffer.lines[buffer.line_count - i].char_count = buffer.lines[buffer.line_count - 1 - i].char_count;
        }
    }

    const previous_line = &buffer.lines[buffer.cursor.y - 1];
    const current_line = &buffer.lines[buffer.cursor.y];
    const count = math.max(50, previous_line.char_count - buffer.cursor.x);

    current_line.char_count = previous_line.char_count - buffer.cursor.x;
    current_line.content = try core.allocator.alloc(u8, count);

    for (buffer.cursor.x..previous_line.char_count) |i| {
        current_line.content[i - buffer.cursor.x] = previous_line.content[i];
    }

    previous_line.char_count = buffer.cursor.x;

    buffer.line_count += 1;
    place_cursor(buffer, .{ 0, buffer.cursor.y });

    check_row_offset(buffer, core.rows - 1);
    buffer.offset[0] = 0;
    try chars_update(core);
}

const TAB: u32 = 2;
fn tab(core: *Wayland) !void {
    const buffer = &core.buffers[core.buffer_index];

    if (core.mode_line.mode == .Command) return;

    const line = &buffer.lines[buffer.cursor.y];
    const len = line.content.len;

    if (len <= line.char_count + TAB) {
        const new = try core.allocator.alloc(u8, len * 2);
        copy(u8, line.content, new[TAB..]);

        core.allocator.free(line.content);
        line.content.ptr = new.ptr;
        line.content.len = new.len;
    } else {
        for (0..line.char_count) |i| {
            line.content[line.char_count + TAB - 1 - i] = line.content[line.char_count - i - 1];
        }
    }

    for (0..TAB) |i| {
        line.content[i] = ' ';
    }

    place_cursor(buffer, .{ buffer.cursor.x + TAB, buffer.cursor.y });
    line.char_count += TAB;
    check_col_offset(buffer, core.cols);
    try chars_update(core);
}

fn new_char(core: *Wayland) !void {
    const buffer = &core.buffers[core.buffer_index];

    if (core.mode_line.mode == .Command) {
        const line = &core.mode_line.line;
        const dif = line.char_count + 1 - buffer.cursor.x;

        for (0..dif) |i| {
            line.content[line.char_count - i] = line.content[line.char_count - i - 1];
        }

        line.content[buffer.cursor.x - 1] = core.last_char;
        line.char_count += 1;
        place_cursor(buffer, .{ buffer.cursor.x + 1, buffer.cursor.y });

        try chars_update(core);
        return;
    }

    const line = &buffer.lines[buffer.cursor.y];
    const len = line.content.len;

    if (len <= line.char_count) {
        const new = try core.allocator.alloc(u8, len * 2);

        copy(u8, line.content[0..buffer.cursor.x], new[0..buffer.cursor.x]);
        copy(u8, line.content[buffer.cursor.x..line.char_count], new[buffer.cursor.x + 1..line.char_count + 1]);

        core.allocator.free(line.content);
        line.content.ptr = new.ptr;
        line.content.len = new.len;
    } else {
        const dif = line.char_count - buffer.cursor.x;
        for (0..dif) |i| {
            line.content[line.char_count - i] = line.content[line.char_count - i - 1];
        }
    }

    line.content[buffer.cursor.x] = core.last_char;

    place_cursor(buffer, .{ buffer.cursor.x + 1, buffer.cursor.y });
    line.char_count += 1;

    check_col_offset(buffer, core.cols);
    try chars_update(core);
}

fn next_line(core: *Wayland) !void {
    const buffer = &core.buffers[core.buffer_index];
    if (core.mode_line.mode == .Command) return;

    if (buffer.cursor.y + 1 < buffer.line_count) {
        const y = buffer.cursor.y + 1;
        var x = buffer.cursor.x;

        if (buffer.lines[y].char_count < x) {
            x = buffer.lines[y].char_count;
        }

        place_cursor(buffer, .{ x, y });
        check_col_offset(buffer, core.cols);
        check_row_offset(buffer, core.rows - 1);

        try chars_update(core);
    }
}

fn prev_line(core: *Wayland) !void {
    const buffer = &core.buffers[core.buffer_index];
    if (core.mode_line.mode == .Command) return;

    if (buffer.cursor.y > 0) {
        const y = buffer.cursor.y - 1;
        var x = buffer.cursor.x;

        if (buffer.lines[y].char_count < x) {
            x = buffer.lines[y].char_count;
        }

        place_cursor(buffer, .{ x, y });
        check_col_offset(buffer, core.cols);
        check_row_offset(buffer, core.rows - 1);

        try chars_update(core);
    }
}

fn line_start(core: *Wayland) !void {
    const buffer = &core.buffers[core.buffer_index];

    if (core.mode_line.mode == .Command) {
        if (buffer.cursor.x == 1) return;

        place_cursor(buffer, .{ 1, buffer.cursor.y });
    } else {
        if (buffer.cursor.x == 0) return;

        place_cursor(buffer, .{ 0, buffer.cursor.y });
        check_col_offset(buffer, core.cols);
    }
    try chars_update(core);
}

fn line_end(core: *Wayland) !void {
    const buffer = &core.buffers[core.buffer_index];
    if (core.mode_line.mode == .Command) {
        const line = &core.mode_line.line;
        if (buffer.cursor.x == line.char_count + 1) return;

        place_cursor(buffer, .{ line.char_count + 1, buffer.cursor.y });
    } else {
        const count = buffer.lines[buffer.cursor.y].char_count;

        if (buffer.cursor.x == count) return;

        place_cursor(buffer, .{ count, buffer.cursor.y });
        check_col_offset(buffer, core.cols);
    }

    try chars_update(core);
}

fn command_mode(core: *Wayland) !void {
    const buffer = &core.buffers[core.buffer_index];
    if (core.mode_line.mode == .Command) return;

    core.mode_line.mode = .Command;
    core.mode_line.cursor = buffer.cursor;
    core.mode_line.line.char_count = 0;
    place_cursor(buffer, .{ 1, core.rows - 1 });

    try chars_update(core);
}

fn delete_selection(core: *Wayland) !void {
    const buffer = &core.buffers[core.buffer_index];

    if (core.mode_line.mode == .Command) {
        const start = if (buffer.cursor.x < buffer.selection.x) buffer.cursor.x else buffer.selection.x;
        var end = buffer.cursor.x + buffer.selection.x - start;
        const line = &core.mode_line.line;

        if (end <= line.char_count) {
            end += 1;
        }

        copy(u8, line.content[end - 1..line.char_count], line.content[start - 1..]);

        const len = line.char_count + start - end;
        line.char_count = len;

        buffer.selection_active = false;
        place_cursor(buffer, .{ start, buffer.cursor.y});

        try chars_update(core);
        return;
    }

    const start_y = if (buffer.cursor.y < buffer.selection.y) buffer.cursor.y else buffer.selection.y;
    const start_x = if (buffer.cursor.x < buffer.selection.x) buffer.cursor.x else buffer.selection.x;
    var end_y = buffer.cursor.y + buffer.selection.y - start_y;
    var end_x = buffer.cursor.x + buffer.selection.x - start_x;

    if (buffer.lines[end_y].char_count == end_x) {
        if (buffer.line_count > end_y + 1) {
            end_y += 1;
            end_x = 0;
        }
    } else {
        end_x += 1;
    }

    const len = buffer.lines[end_y].char_count + start_x - end_x;

    if (buffer.lines[start_y].content.len < len) {
        const new = try core.allocator.alloc(u8, len);

        const end_of_line = buffer.lines[end_y].char_count;
        copy(u8, buffer.lines[start_y].content[0..start_x], new);
        copy(u8, buffer.lines[end_y].content[end_x..end_of_line], new[start_x..]);

        core.allocator.free(buffer.lines[start_y].content);

        buffer.lines[start_y].content.ptr = new.ptr;
        buffer.lines[start_y].content.len = new.len;
    } else {
        const end_of_line = buffer.lines[end_y].char_count;
        copy(u8, buffer.lines[end_y].content[end_x..end_of_line], buffer.lines[start_y].content[start_x..]);
    }

    buffer.lines[start_y].char_count = len;
    buffer.selection_active = false;
    place_cursor(buffer, .{ start_x, start_y });

    const diff = end_y - start_y;
    if (diff != 0) {
        for (0..diff) |i| {
            core.allocator.free(buffer.lines[i + start_y + 1].content);
        }

        const delta = buffer.line_count - end_y;
        for (0..delta) |i| {
            buffer.lines[start_y + 1 + i] = buffer.lines[end_y + 1 + i];
        }

        buffer.line_count -= diff;
    }

    try chars_update(core);
}

fn prev_char(core: *Wayland) !void {
    const buffer = &core.buffers[core.buffer_index];

    if (core.mode_line.mode == .Command) {
        if (buffer.cursor.x == 1) return;
        place_cursor(buffer, .{ buffer.cursor.x - 1, buffer.cursor.y });
    } else {
        if (buffer.cursor.x != 0){
            place_cursor(buffer, .{ buffer.cursor.x - 1, buffer.cursor.y });
        } else if (buffer.cursor.y != 0) {
            const y = buffer.cursor.y - 1;
            const line = &buffer.lines[y];
            place_cursor(buffer, .{ line.char_count, y });
        } else {
            return;
        }
    }

    try chars_update(core);
}

fn next_char(core: *Wayland) !void {
    const buffer = &core.buffers[core.buffer_index];
    if (core.mode_line.mode == .Command) {
        const line = &core.mode_line.line;
        if (buffer.cursor.x == line.char_count + 1) return;

        place_cursor(buffer, .{ buffer.cursor.x + 1, buffer.cursor.y });
    } else {
        if (buffer.cursor.x < buffer.lines[buffer.cursor.y].char_count) {
            place_cursor(buffer, .{ buffer.cursor.x + 1, buffer.cursor.y });
        } else if (buffer.cursor.y + 1 < buffer.line_count) {
            place_cursor(buffer, .{ 0, buffer.cursor.y + 1 });
        } else {
            return;
        }
    }
    try chars_update(core);
}

fn selection_mode(core: *Wayland) !void {
    const buffer = &core.buffers[core.buffer_index];

    buffer.selection_active = !buffer.selection_active;

    if (!buffer.selection_active) {
        buffer.selection.x = buffer.cursor.x;
        buffer.selection.y = buffer.cursor.y;
        core.update = true;
    }
}

fn scroll_down(core: *Wayland) !void {
    const buffer = &core.buffers[core.buffer_index];

    const add = (core.rows - 1) / 2;
    if (buffer.offset[1] + add >= buffer.line_count - 2) return;
    buffer.offset[1] += add;

    if (buffer.cursor.y < buffer.offset[1]) {
        place_cursor(buffer, .{ 0, buffer.offset[1] });
    }

    try chars_update(core);
}

fn scroll_up(core: *Wayland) !void {
    const buffer = &core.buffers[core.buffer_index];

    const sub = (core.rows - 1) / 2;
    if (buffer.offset[1] < sub) {
        if (buffer.offset[1] == 0) return;
        buffer.offset[1] = 0;
    } else {
        buffer.offset[1] -= sub;
    }

    if (buffer.cursor.y > buffer.offset[1] + core.rows - 2) {
        buffer.cursor.y = buffer.offset[1] + core.rows - 2;
    }

    try chars_update(core);
}

fn key_pressed(core: *Wayland, key: u32) !void {
    const start = try Instant.now();

    const tuple = try try_ascci(key);
    const char = if (core.shift) tuple[1] else tuple[0];

    if (core.control) {
        switch (char) {
            'n' => core.last_fn = next_line,
            'p' => core.last_fn = prev_line,
            'a' => core.last_fn = line_start,
            'e' => core.last_fn = line_end,
            'd' => core.last_fn = delete_selection,
            'f' => core.last_fn = next_char,
            'b' => core.last_fn = prev_char,
            'v' => core.last_fn = scroll_down,
            ' ' => core.last_fn = selection_mode,
            else => return,
        }
    } else if (core.alt) {
        switch (char) {
            'x' => core.last_fn = command_mode,
            'v' => core.last_fn = scroll_up,
            else => return,
        }
    } else {
        switch (char) {
            '\n' => core.last_fn = enter,
            '\t' => core.last_fn = tab,

            else => {
                core.last_char = char;
                core.last_fn = new_char;
            },
        }
    }

    if (core.last_fn) |f| {
        try f(core);
    }

    core.last_fetch_delay = try Instant.now();
    std.debug.print("time elapsed: {} ns\n", .{core.last_fetch_delay.since(start)});
}

fn print(core: *const Wayland) void {
    const buffer = &core.buffers[core.buffer_index];

    for (0..buffer.line_count) |i| {
        const line = &buffer.lines[i];
        std.debug.print("{d}\n", .{line.content[0..line.char_count]});
    }
}

pub fn init(
    width: u32,
    height: u32,
    font_scale: f32,
    font_ratio: f32,
    allocator: Allocator
) !*Wayland {
    const core = try allocator.create(Wayland);

    core.buffers = try allocator.alloc(Buffer, 2);
    core.last_char = ' ';
    core.buffers[0] = try buffer_init(allocator);
    core.buffer_count = 1;
    core.mode_line = try mode_line_init(allocator);
    core.scale = math.divide(height, width);
    core.width = width;
    core.height = height;
    core.font_ratio = font_ratio;
    core.font_scale = font_scale;
    core.rows = @intFromFloat(1.0 / core.font_scale);
    core.cols = @intFromFloat(1.0 / (core.scale * core.font_ratio * core.font_scale));
    core.key_delay = 200 * 1000 * 1000;
    core.key_rate = 20 * 1000 * 1000;
    core.buffer_index = 0;
    core.running = true;
    core.update = true;
    core.last_fn = null;
    core.last_fetch_delay = try Instant.now();
    core.last_fetch_rate = try Instant.now();
    core.allocator = allocator;

    for (0..CHAR_COUNT) |i| {
        core.chars[i] = .{
            .pos = try allocator.alloc([2]u32, 10),
            .capacity = 10,
        };

        core.chars[i].pos.len = 0;
    }

    core.seat_listener = c.wl_seat_listener {
        .name = seat_name,
        .capabilities = seat_capabilities,
    };

    core.shell_listener = c.xdg_wm_base_listener {
        .ping = shell_ping,
    };

    core.shell_surface_listener = c.xdg_surface_listener {
        .configure = shell_surface_configure,
    };

    core.xdg_toplevel_listener = c.xdg_toplevel_listener {
        .configure = toplevel_configure,
        .close = toplevel_close,
    };

    core.registry_listener = c.wl_registry_listener {
        .global = global_listener,
        .global_remove = global_remove_listener,
    };

    core.keyboard_listener = c.wl_keyboard_listener {
        .keymap = keyboard_keymap,
        .enter = keyboard_enter,
        .leave = keyboard_leave,
        .key = keyboard_key,
        .modifiers = keyboard_modifiers,
        .repeat_info = keyboard_repeat_info,
    };

    core.display = c.wl_display_connect(null) orelse return error.DisplayConnect;
    core.registry = c.wl_display_get_registry(core.display) orelse return error.RegistryGet;
    _ = c.wl_registry_add_listener(core.registry, &core.registry_listener, core);

    _ = c.wl_display_roundtrip(core.display);

    core.surface = c.wl_compositor_create_surface(core.compositor) orelse return error.SurfaceCreate;
    _ = c.xdg_wm_base_add_listener(core.xdg_shell, &core.shell_listener, core);

    core.xdg_surface = c.xdg_wm_base_get_xdg_surface(core.xdg_shell, core.surface) orelse return error.XdgSurfaceGet;
    _ = c.xdg_surface_add_listener(core.xdg_surface, &core.shell_surface_listener, core);

    core.xdg_toplevel = c.xdg_surface_get_toplevel(core.xdg_surface) orelse return error.XdgToplevelGet;
    _ = c.xdg_toplevel_add_listener(core.xdg_toplevel, &core.xdg_toplevel_listener, core);

    _ = c.wl_seat_add_listener(core.seat, &core.seat_listener, core);

    c.wl_surface_commit(core.surface);
    _ = c.wl_display_roundtrip(core.display);

    return core;
}

pub fn update_surface(core: *Wayland) void {
    c.wl_surface_commit(core.surface);
    core.update = false;
}

pub fn get_events(core: *Wayland) void {
    _ = c.wl_display_roundtrip(core.display);

    if (core.last_fn) |f| {
        const now = Instant.now() catch return;
        if (now.since(core.last_fetch_delay) > core.key_delay) {
            if (now.since(core.last_fetch_rate) > core.key_rate) {
                f(core) catch {
                    return;
                };
            }
        }
    }
}

pub fn deinit(core: *Wayland) void {
    c.wl_keyboard_release(core.keyboard);
    c.xdg_toplevel_destroy(core.xdg_toplevel);
    c.xdg_surface_destroy(core.xdg_surface);
    c.xdg_wm_base_destroy(core.xdg_shell);
    c.wl_surface_destroy(core.surface);
    c.wl_compositor_destroy(core.compositor);
    c.wl_registry_destroy(core.registry);
    c.wl_display_disconnect(core.display);

    for (0..CHAR_COUNT) |i| {
        const char = &core.chars[i];

        char.pos.len = char.capacity;
        core.allocator.free(char.pos);
    }

    for (0..core.buffer_count) |k| {
        for (0..core.buffers[k].line_count) |i| {
            core.allocator.free(core.buffers[k].lines[i].content);
        }

        core.allocator.free(core.buffers[k].lines);
    }

    core.allocator.free(core.buffers);
    core.allocator.free(core.mode_line.line.content);

    core.allocator.destroy(core);
}

fn global_remove_listener(_: ?*anyopaque, _: ?*c.wl_registry, _: u32) callconv(.C) void {}
fn global_listener(data: ?*anyopaque, registry: ?*c.wl_registry, name: u32, interface: [*c]const u8, _: u32) callconv(.C) void {
    const core: *Wayland = @ptrCast(@alignCast(data));
    const interface_name = std.mem.span(interface);

    if (std.mem.eql(u8, interface_name, std.mem.span(c.wl_compositor_interface.name))) {
        const compositor = c.wl_registry_bind(registry, name, &c.wl_compositor_interface, 4) orelse return;
        core.compositor = @ptrCast(@alignCast(compositor));
    } else if (std.mem.eql(u8, interface_name, std.mem.span(c.xdg_wm_base_interface.name))) {
        const shell = c.wl_registry_bind(registry, name, &c.xdg_wm_base_interface, 1) orelse return;
        core.xdg_shell = @ptrCast(@alignCast(shell));
    } else if (std.mem.eql(u8, interface_name, std.mem.span(c.wl_seat_interface.name))) {
        const seat = c.wl_registry_bind(registry, name, &c.wl_seat_interface, 4) orelse return;
        core.seat = @ptrCast(@alignCast(seat));
    }
}

fn seat_name(_: ?*anyopaque, _: ?*c.wl_seat, _: [*c]const u8) callconv(.C) void {}
fn seat_capabilities(data: ?*anyopaque, seat: ?*c.wl_seat, cap: u32) callconv(.C) void {
    const core: *Wayland = @ptrCast(@alignCast(data));

    if (cap != 0 and c.WL_SEAT_CAPABILITY_KEYBOARD != 0) {
        core.keyboard = c.wl_seat_get_keyboard(seat) orelse return;
        _ = c.wl_keyboard_add_listener(core.keyboard, &core.keyboard_listener, core);
    }
}

fn shell_ping(_: ?*anyopaque, surface: ?*c.xdg_wm_base, serial: u32) callconv(.C) void {
    c.xdg_wm_base_pong(surface, serial);
}

fn shell_surface_configure(_: ?*anyopaque, shell_surface: ?*c.xdg_surface, serial: u32) callconv(.C) void {
    c.xdg_surface_ack_configure(shell_surface, serial);
}

fn toplevel_configure(data: ?*anyopaque, _: ?*c.xdg_toplevel, width: i32, height: i32, _: ?*c.wl_array) callconv(.C) void {
    const core: *Wayland = @ptrCast(@alignCast(data));

    if (width > 0 and height > 0) {
        if (width == core.width and height == core.height) return;

        core.resize = true;
        core.width = @intCast(width);
        core.height = @intCast(height);

        core.scale = math.divide(core.height, core.width);
        core.rows = @intFromFloat(1.0 / core.font_scale);
        core.cols = @intFromFloat(1.0 / (core.scale * core.font_ratio * core.font_scale));

        chars_update(core) catch return;
    }
}

fn toplevel_close(data: ?*anyopaque, _: ?*c.xdg_toplevel) callconv(.C) void {
    const core: *Wayland = @ptrCast(@alignCast(data));
    core.running = false;
}

fn keyboard_keymap(_: ?*anyopaque, _: ?*c.wl_keyboard, _: u32, _: i32, _: u32) callconv(.C) void {}
fn keyboard_enter(_: ?*anyopaque, _: ?*c.wl_keyboard, _: u32, _: ?*c.wl_surface, _: ?*c.wl_array) callconv(.C) void {}
fn keyboard_leave(_: ?*anyopaque, _: ?*c.wl_keyboard, _: u32, _: ?*c.wl_surface) callconv(.C) void {}
fn keyboard_key(data: ?*anyopaque, _: ?*c.wl_keyboard, _: u32, _: u32, id: u32, state: u32) callconv(.C) void {
    const core: *Wayland = @ptrCast(@alignCast(data));

    core.last_fn = null;
    if (state == 1) key_pressed(core, id) catch return;
}

const SHIFT_BIT: u32 = 0x01;
const CAPSLOCK_BIT: u32 = 0x02;
const CONTROL_BIT: u32 = 0x04;
const ALT_BIT: u32 = 0x08;

fn keyboard_modifiers(data: ?*anyopaque, _: ?*c.wl_keyboard, _: u32, depressed: u32, _: u32, locked: u32, _: u32) callconv(.C) void {
    const core: *Wayland = @ptrCast(@alignCast(data));
    const pressed = depressed | locked;

    core.control = pressed & CONTROL_BIT > 0;
    core.shift = pressed & (SHIFT_BIT | CAPSLOCK_BIT) > 0;
    core.alt = pressed & ALT_BIT > 0;
}

fn keyboard_repeat_info(data: ?*anyopaque, _: ?*c.wl_keyboard, rate: i32, delay: i32) callconv(.C) void {
    const core: *Wayland = @ptrCast(@alignCast(data));
    const d: u64 = @intCast(delay);
    const r: u64 = @intCast(rate);

    core.key_delay = d * 1000 * 1000;
    core.key_rate = r * 1000 * 1000;
}

fn try_ascci(u: u32) ![2]u8 {
    const ascci: [2]u8 = switch (u) {
        2 => .{ '1', '!' },
        3 => .{ '2', '@' },
        4 => .{ '3', '#' },
        5 => .{ '4', '$' },
        6 => .{ '5', '%' },
        7 => .{ '6', '^' },
        8 => .{ '7', '&' },
        9 => .{ '8', '*' },
        10 => .{ '9', '(' },
        11 => .{ '0', ')' },
        12 => .{ '-', '_' },
        13 => .{ '=', '+' },
        15 => .{ '\t', '\t' },

        16 => .{ 'q', 'Q' },
        17 => .{ 'w', 'W' },
        18 => .{ 'e', 'E' },
        19 => .{ 'r', 'R' },
        20 => .{ 't', 'T' },
        21 => .{ 'y', 'Y' },
        22 => .{ 'u', 'U' },
        23 => .{ 'i', 'I' },
        24 => .{ 'o', 'O' },
        25 => .{ 'p', 'P' },

        26 => .{ '[', '{' },
        27 => .{ ']', '}' },
        28 => .{ '\n', '\n' },

        30 => .{ 'a', 'A' },
        31 => .{ 's', 'S' },
        32 => .{ 'd', 'D' },
        33 => .{ 'f', 'F' },
        34 => .{ 'g', 'G' },
        35 => .{ 'h', 'H' },
        36 => .{ 'j', 'J' },
        37 => .{ 'k', 'K' },
        38 => .{ 'l', 'L' },

        39 => .{ ';', ':' },
        40 => .{ '\'', '"' },

        43 => .{ '\\', '|' },

        44 => .{ 'z', 'Z' },
        45 => .{ 'x', 'X' },
        46 => .{ 'c', 'C' },
        47 => .{ 'v', 'V' },
        48 => .{ 'b', 'B' },
        49 => .{ 'n', 'N' },
        50 => .{ 'm', 'M' },

        51 => .{ ',', '<' },
        52 => .{ '.', '>' },
        53 => .{ '/', '?' },

        57 => .{ ' ', ' ' },

        else => return error.NotAscci,
    };

    return ascci;
}
