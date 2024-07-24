const std = @import("std");
const math = @import("../math.zig");
const util = @import("../util.zig");

const Allocator = std.mem.Allocator;

const Vec = @import("../collections.zig").Vec;
const Fn = @import("command.zig").Fn;

const Rect = math.Rect;
const Coord = math.Vec2D;
const Length = math.Vec2D;
const Cursor = math.Vec2D;

const Line = struct {
    content: Vec(u8),
    indent: u32,

    const TAB: u32 = 2;
    const CHAR_COUNT: u32 = 50;

    fn init(content: []const u8, allocator: Allocator) !Line {
        const content_len: u32 = @intCast(content.len);

        var indent: u32 = 0;
        var vec = try Vec(u8).init(math.max(content_len, CHAR_COUNT), allocator);

        if (content_len > 0) {
            while (content[indent] == ' ') : (indent += 1) {}
            try vec.extend(content);
        }

        return Line {
            .content = vec,
            .indent = indent,
        };
    }

    fn with_indent(content: []const u8, indent: u32, allocator: Allocator) !Line {
        const content_len = @as(u32, @intCast(content.len)) + indent;

        var vec = try Vec(u8).init(math.max(content_len, CHAR_COUNT), allocator);
        try vec.repeat(' ', indent);
        try vec.extend_insert(content, indent);

        return Line {
            .content = vec,
            .indent = indent,
        };
    }

    fn insert_string(self: *Line, string: []const u8, col: u32) !void {
        try self.content.extend_insert(string, col);
    }

    fn len(self: *const Line) u32 {
        return self.content.len() - 1;
    }

    fn deinit(self: *const Line) void {
        self.content.deinit();
    }
};

const Selection = struct {
    cursor: Cursor,
    active: bool,

    fn init(cursor: Cursor) Selection {
        return Selection {
            .cursor = cursor,
            .active = false,
        };
    }

    fn move(self: *Selection, to: *const Cursor) void {
        if (!self.active) self.cursor.move(to);
    }

    fn toggle(self: *Selection) void {
        self.active = !self.active;
    }
};

pub const Buffer = struct {
    name: []const u8,
    lines: Vec(Line),
    rect: Rect,
    cursor: Cursor,
    selection: Selection,

    pub fn init(
        name: []const u8,
        content: []const u8,
        size: Length,
        allocator: Allocator
    ) !Buffer {
        const len: u32 = @intCast(content.len);
        var lines = try Vec(Line).init((len + Line.CHAR_COUNT) / Line.CHAR_COUNT, allocator);

        {
            var start: usize = 0;
            for (0..len) |i| {
                if (content[i] == '\n') {
                    try lines.push(
                        try Line.init(content[start..i + 1], allocator)
                    );

                    start = i + 1;
                }
            }
        }

        {
            if (len == 0) {
                try lines.push(try Line.init("", allocator));
            }
        }

        const cursor = Cursor.init(0, 0);

        return Buffer {
            .name = name,
            .lines = lines,

            .rect = Rect.init(Coord.init(0, 0), size),
            .cursor = cursor,
            .selection = Selection.init(cursor),
        };
    }

    pub fn char_iter(
        self: *const Buffer, 
        T: type, 
        ptr: *T, 
        f: fn (*T, u8, usize, usize) anyerror!void
    ) !void {
        const end = self.rect.end();
        const lines = self.lines.range(self.rect.coord.y, end.y) catch return;

        for (lines, 0..) |line, i| {
            const chars = line.content.range(self.rect.coord.x, end.x) catch continue;

            for (chars, 0..) |char, j| {
                try f(ptr, char, j, i);
            }
        }
    }

    pub fn back_iter(
        self: *const Buffer, 
        T: type, 
        ptr: *T, 
        f: fn (*T, usize, usize) anyerror!void
    ) !void {
        const coord = self.cursor.sub(&self.rect.coord);
        try f(ptr, coord.x, coord.y);

        if (!self.selection.active) return;

        const boundary = blk: { 
            if (self.cursor.greater(&self.selection.cursor)) {
                break :blk [_]Coord { self.selection.cursor, self.cursor};
            } else {
                const cursor_flag = self.cursor.x >= self.lines.items[self.cursor.y].content.len();
                const selection_flag = self.selection.cursor.x >= self.lines.items[self.selection.cursor.y].content.len();

                const cursor_at_end = self.cursor.y + 1 >= self.lines.len();
                const selection_at_end = self.selection.cursor.y + 1 >= self.lines.len();

                break :blk [_]Coord {
                    Coord.init(
                        if (cursor_flag) if (cursor_at_end) self.cursor.x else 0 else self.cursor.x + 1,
                        if (cursor_at_end or !cursor_flag) self.cursor.y else self.cursor.y + 1,
                    ),
                    Coord.init(
                        if (selection_flag) if (selection_at_end) self.selection.cursor.x else 0 else self.selection.cursor.x + 1,
                        if (selection_at_end or !selection_flag) self.selection.cursor.y else self.selection.cursor.y + 1,
                    )
                };
            }
        };

        const start = boundary[0].max(&self.rect.coord).sub(&self.rect.coord);
        const end = boundary[1].sub(&self.rect.coord).min(&Coord.init(self.rect.coord.x + self.rect.size.x, self.rect.coord.y + self.rect.size.y));

        if (start.y == end.y) {
            for (start.x..end.x) |i| {
                try f(ptr, i, start.y);
            }
        } else {
            for (start.x..math.min(self.lines.items[self.rect.coord.y + start.y].content.len(), self.rect.coord.x + self.rect.size.x + 1)) |i| try f(ptr, i, start.y);
            for (0..math.min(self.lines.items[self.rect.coord.y + end.y].content.len(), end.x)) |i| try f(ptr, i, end.y);
            for (start.y + 1..end.y) |i| {
                for (0..self.lines.items[self.rect.coord.y + i].content.len()) |j| {
                    try f(ptr, j, i);
                }
            }
        }
    }

    pub fn move_cursor(self: *Buffer, to: *const Cursor) void {
        self.cursor.move(to);
        self.selection.move(to);
    }

    pub fn set_size(self: *Buffer, size: *const Length) void {
        self.rect.size.move(size);
    }

    pub fn insert_string(self: *Buffer, string: []const u8) !void {
        const len: u32 = @intCast(string.len);
        const line = try self.lines.get_mut(self.cursor.y);

        try line.insert_string(string, self.cursor.x);

        self.selection.active = false;
        self.move_cursor(&Cursor.init(self.cursor.x + len, self.cursor.y));
        self.rect.reajust(&self.cursor);
    }

    pub fn commands() []const Fn {
        return &[_]Fn {
            Fn { .f = enter,       .string = "Ret" },
            Fn { .f = delete,      .string = "C-d" },
            Fn { .f = next_line,   .string = "C-n" },
            Fn { .f = prev_line,   .string = "C-p" },
            Fn { .f = next_char,   .string = "C-f" },
            Fn { .f = prev_char,   .string = "C-b" },
            Fn { .f = line_end,    .string = "C-e" },
            Fn { .f = line_start,  .string = "C-a" },
            Fn { .f = space,       .string = "Spc" },
            Fn { .f = scroll_up,   .string = "A-v" },
            Fn { .f = scroll_down, .string = "C-v" },
            Fn { .f = selection,   .string = "C-Spc" },
        };
    }

    pub fn deinit(self: *const Buffer) void {
        self.lines.deinit();
    }
};

fn enter(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *Buffer = @ptrCast(@alignCast(ptr));

    const line = try self.lines.get_mut(self.cursor.y);
    const content = line.content.truncate(self.cursor.x);

    const new_cursor = Cursor.init(line.indent, self.cursor.y + 1);

    try self.lines.insert(
        try Line.with_indent(content, line.indent, self.lines.allocator),
        new_cursor.y,
    );

    try self.lines.items[self.cursor.y].content.push('\n');

    self.selection.active = false;
    self.rect.reajust(&new_cursor);
    self.move_cursor(&new_cursor);
}

fn next_line(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *Buffer = @ptrCast(@alignCast(ptr));

    const y = self.cursor.y + 1;
    const line = try self.lines.get(y);

    const x = math.min(self.cursor.x, line.len());
    const new_cursor = Cursor.init(x, y);

    self.rect.reajust(&new_cursor);
    self.move_cursor(&new_cursor);
}

fn prev_line(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *Buffer = @ptrCast(@alignCast(ptr));

    try util.assert(self.cursor.y > 0);

    const y = self.cursor.y - 1;
    const line = try self.lines.get(y);

    const len = line.len();
    const x = math.min(self.cursor.x, len);
    const new_cursor = Cursor.init(x, y);

    self.rect.reajust(&new_cursor);
    self.move_cursor(&new_cursor);
}

fn next_char(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *Buffer = @ptrCast(@alignCast(ptr));

    var line = try self.lines.get(self.cursor.y);

    var y = self.cursor.y;
    var x = self.cursor.x;

    if (x == line.len()) {
        y += 1;
        x = 0;
        try util.assert(y < self.lines.len());
    } else {
        x += 1;
    }

    const new_cursor = Cursor.init(x, y);

    self.rect.reajust(&new_cursor);
    self.move_cursor(&new_cursor);
}

fn prev_char(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *Buffer = @ptrCast(@alignCast(ptr));

    var y = self.cursor.y;
    var x = self.cursor.x;

    if (x < 1) {
        try util.assert(y > 0);
        y -= 1;

        const line = try self.lines.get(y);
        x = line.content.len() - 1;
    } else {
        x -= 1;
    }

    const new_cursor = Coord.init(x, y);
    self.rect.reajust(&new_cursor);
    self.move_cursor(&new_cursor);
}

fn line_end(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *Buffer = @ptrCast(@alignCast(ptr));

    const line = try self.lines.get(self.cursor.y);
    const len = line.len();

    const new_cursor = Cursor.init(len, self.cursor.y);

    self.rect.reajust(&new_cursor);
    self.move_cursor(&new_cursor);
}

fn line_start(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *Buffer = @ptrCast(@alignCast(ptr));

    try util.assert(self.cursor.x > 0);
    const new_cursor = Cursor.init(0, self.cursor.y);

    self.rect.reajust(&new_cursor);
    self.move_cursor(&new_cursor);
}

fn delete(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *Buffer = @ptrCast(@alignCast(ptr));

    const start = if (self.cursor.greater(&self.selection.cursor)) self.selection.cursor else self.cursor;
    var end = if (self.cursor.greater(&self.selection.cursor)) self.cursor else self.selection.cursor;

    const start_line = try self.lines.get_mut(start.y);

    if (end.x < self.lines.items[end.y].len()) {
        end.x += 1;
    } else if (self.lines.len() > end.y + 1) {

        end.x = 0;
        end.y += 1;
    }

    const end_line = self.lines.items[end.y].content.items[end.x..];
    start_line.content.items.len = start.x;

    for (end_line) |char| {
        try start_line.content.push(char);
    }

    self.selection.active = false;

    self.rect.reajust(&start);
    self.move_cursor(&start);

    if (start.y == end.y) return;

    for (start.y..end.y) |i| {
        self.lines.items[i + 1].deinit();
    }

    util.copy(Line, self.lines.items[end.y + 1..], self.lines.items[start.y + 1..]);
    self.lines.items.len -= end.y - start.y;

}

fn selection(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *Buffer = @ptrCast(@alignCast(ptr));

    self.selection.toggle();
    self.move_cursor(&self.cursor);
}

fn scroll_down(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *Buffer = @ptrCast(@alignCast(ptr));
    if (self.rect.coord.y + 1 >= self.lines.len()) return error.NoMoreSpace;

    const size = math.min(self.rect.coord.y + self.rect.size.y / 2, self.lines.len() - 1);

    self.rect.coord.move(&Coord.init(0, size));
    self.move_cursor(&self.rect.fit(&self.cursor));
}

fn scroll_up(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *Buffer = @ptrCast(@alignCast(ptr));
    if (self.rect.coord.y == 0) return error.NoMoreSpace;

    const half = math.min(self.rect.size.y / 2, self.rect.coord.y);
    const size = self.rect.coord.y - half;

    self.rect.coord.move(&Coord.init(0, size));
    self.move_cursor(&self.rect.fit(&self.cursor));
}

fn space(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *Buffer = @ptrCast(@alignCast(ptr));

    try self.insert_string(" ");
}

// fn enter(core: *Wayland) !void {
//     const buffer = &core.buffers[core.buffer_index];

//     if (core.mode_line.mode == .Command) {
//         core.mode_line.mode = .Normal;
//         buffer.cursor = core.mode_line.cursor;

//         command.execute_command(core) catch |e| {
//             try wayland.chars_update(core);
//             return e;
//         };

//         try wayland.chars_update(core);

//         return;
//     }

//     const y = buffer.cursor.y + 1;

//     const len = buffer.lines.len;
//     if (len <= buffer.line_count) {
//         const new = try core.allocator.alloc(Line, len * 2);

//         util.copy(Line, buffer.lines[0..y], new[0..y]);
//         util.copy(Line, buffer.lines[y..], new[y + 1..]);

//         core.allocator.free(buffer.lines);
//         buffer.lines.ptr = new.ptr;
//         buffer.lines.len = new.len;
//     } else {
//         const ii = buffer.line_count - buffer.cursor.y;

//         for (0..ii) |i| {
//             buffer.lines[buffer.line_count - i] = buffer.lines[buffer.line_count - 1 - i];
//         }
//     }

//     const previous_line = &buffer.lines[buffer.cursor.y];
//     const current_line = &buffer.lines[y];
//     const count = math.max(50, previous_line.char_count - buffer.cursor.x + previous_line.indent);

//     current_line.char_count = previous_line.char_count - buffer.cursor.x + previous_line.indent;
//     current_line.content = try core.allocator.alloc(u8, count);
//     current_line.indent = previous_line.indent;

//     for (buffer.cursor.x..previous_line.char_count) |i| {
//         current_line.content[i - buffer.cursor.x + current_line.indent] = previous_line.content[i];
//     }

//     for (0..current_line.indent) |k| {
//         current_line.content[k] = ' ';
//     }

//     previous_line.char_count = buffer.cursor.x;

//     buffer.line_count += 1;
//     const prev_cursor = buffer.cursor;
//     place_cursor(buffer, .{ current_line.indent, y }, buffer.cursor.offset + current_line.indent + 1);

//     _ = check_row_offset(buffer, core.rows - 1);
//     buffer.offset[0] = 0;
//     if (buffer.highlight.on) {
//         try highlight.edit_tree(
//             &buffer.highlight,
//             .Add,
//             &prev_cursor,
//             &buffer.cursor,
//             buffer.offset[1],
//             core.rows - 1,
//         );
//     }
//     try wayland.chars_update(core);
// }

// pub fn tab(core: *Wayland) !void {
//     const buffer = &core.buffers[core.buffer_index];

//     if (core.mode_line.mode == .Command) return;

//     const line = &buffer.lines[buffer.cursor.y];
//     const len = line.content.len;

//     if (len <= line.char_count + TAB) {
//         const new = try core.allocator.alloc(u8, len * 2);
//         util.copy(u8, line.content, new[TAB..]);

//         core.allocator.free(line.content);
//         line.content.ptr = new.ptr;
//         line.content.len = new.len;
//     } else {
//         for (0..line.char_count) |i| {
//             line.content[line.char_count + TAB - 1 - i] = line.content[line.char_count - i - 1];
//         }
//     }

//     for (0..TAB) |i| {
//         line.content[i] = ' ';
//     }

//     const prev_cursor = buffer.cursor;
//     place_cursor(buffer, .{ buffer.cursor.x + TAB, buffer.cursor.y }, buffer.cursor.offset + TAB);
//     line.indent += TAB;
//     line.char_count += TAB;

//     if (buffer.highlight.on) {
//         try highlight.edit_tree(
//             &buffer.highlight,
//             .Add,
//             &prev_cursor,
//             &buffer.cursor,
//             buffer.offset[1],
//             core.rows - 1,
//         );
//     }

//     try wayland.chars_update(core);
// }

// pub fn back_tab(core: *Wayland) !void {
//     const buffer = &core.buffers[core.buffer_index];
//     const line = &buffer.lines[buffer.cursor.y];
//     var remove_from_start: u32 = TAB;

//     if (line.indent == 0) {
//         return;
//     } else if (line.indent < TAB) {
//         remove_from_start = line.indent;
//     }

//     for (remove_from_start..line.char_count) |i| {
//         line.content[i - remove_from_start] = line.content[i];
//     }

//     line.char_count -= remove_from_start;
//     line.indent -= remove_from_start;
//     const prev_cursor = buffer.cursor;
//     place_cursor(buffer, .{ buffer.cursor.x - remove_from_start, buffer.cursor.y }, buffer.cursor.offset - remove_from_start);

//     if (buffer.highlight.on) {
//         try highlight.edit_tree(
//             &buffer.highlight,
//             .Add,
//             &buffer.cursor,
//             &prev_cursor,
//             buffer.offset[1],
//             core.rows - 1,
//         );
//     }

//     try wayland.chars_update(core);
// }

// pub fn new_char(core: *Wayland) !void {
//     const buffer = &core.buffers[core.buffer_index];

//     if (core.mode_line.mode == .Command) {
//         const line = &core.mode_line.line;
//         const dif = line.char_count + 1 - buffer.cursor.x;

//         for (0..dif) |i| {
//             line.content[line.char_count - i] = line.content[line.char_count - i - 1];
//         }

//         line.content[buffer.cursor.x - 1] = core.last_char;
//         line.char_count += 1;
//         place_cursor(buffer, .{ buffer.cursor.x + 1, buffer.cursor.y }, 0);

//         try wayland.chars_update(core);
//         return;
//     }

//     const line = &buffer.lines[buffer.cursor.y];
//     const len = line.content.len;

//     if (len <= line.char_count + 1) {
//         const new = try core.allocator.alloc(u8, len * 2);

//         util.copy(u8, line.content[0..buffer.cursor.x], new[0..buffer.cursor.x]);
//         util.copy(u8, line.content[buffer.cursor.x..line.char_count], new[buffer.cursor.x + 1..line.char_count + 1]);

//         core.allocator.free(line.content);
//         line.content.ptr = new.ptr;
//         line.content.len = new.len;
//     } else {
//         const dif = line.char_count - buffer.cursor.x;
//         for (0..dif) |i| {
//             line.content[line.char_count - i] = line.content[line.char_count - i - 1];
//         }
//     }

//     line.content[buffer.cursor.x] = core.last_char;
//     const prev_cursor = buffer.cursor;
//     place_cursor(buffer, .{ buffer.cursor.x + 1, buffer.cursor.y }, buffer.cursor.offset + 1);

//     line.char_count += 1;

//     _ = check_col_offset(buffer, core.cols);
//     if (buffer.highlight.on) {
//         try highlight.edit_tree(
//             &buffer.highlight,
//             .Add,
//             &prev_cursor,
//             &buffer.cursor,
//             buffer.offset[1],
//             core.rows - 1,
//         );
//     }
//     try wayland.chars_update(core);
// }

// pub fn next_line(core: *Wayland) !void {
//     if (core.mode_line.mode == .Command) return;

//     const buffer = &core.buffers[core.buffer_index];
//     if (buffer.cursor.y + 1 < buffer.line_count) {
//         const y = buffer.cursor.y + 1;
//         var x = buffer.cursor.x;

//         if (buffer.lines[y].char_count < x) {
//             x = buffer.lines[y].char_count;
//         }

//         const offset_addition = buffer.lines[buffer.cursor.y].char_count + x - buffer.cursor.x + 1;
//         place_cursor(buffer, .{ x, y }, buffer.cursor.offset + offset_addition);
        
//         if (check_col_offset(buffer, core.cols - 1) or check_row_offset(buffer, core.rows - 1)) {
//             if (buffer.highlight.on) {
//                 try highlight.fill_id_ranges(
//                     &buffer.highlight,
//                     buffer.offset[1],
//                     core.rows - 1,
//                 );
//             }
//         }

//         try wayland.chars_update(core);
//     }
// }

// pub fn prev_line(core: *Wayland) !void {
//     const buffer = &core.buffers[core.buffer_index];
//     if (core.mode_line.mode == .Command) return;

//     if (buffer.cursor.y > 0) {
//         const y = buffer.cursor.y - 1;
//         var x = buffer.cursor.x;

//         if (buffer.lines[y].char_count < x) {
//             x = buffer.lines[y].char_count;
//         }

//         const new_offset = buffer.cursor.offset + x - 1 - buffer.cursor.x - buffer.lines[y].char_count;

//         place_cursor(buffer, .{ x, y }, new_offset);

//         if (check_col_offset(buffer, core.cols - 1) or check_row_offset(buffer, core.rows - 1)) {
//             if (buffer.highlight.on) {
//                 try highlight.fill_id_ranges(
//                     &buffer.highlight,
//                     buffer.offset[1],
//                     core.rows - 1,
//                 );
//             }
//         }

//         try wayland.chars_update(core);
//     }
// }

// pub fn line_start(core: *Wayland) !void {
//     const buffer = &core.buffers[core.buffer_index];

//     if (core.mode_line.mode == .Command) {
//         if (buffer.cursor.x == 1) return;

//         place_cursor(buffer, .{ 1, buffer.cursor.y }, 0);
//     } else {
//         if (buffer.cursor.x == 0) return;

//         place_cursor(buffer, .{ 0, buffer.cursor.y }, buffer.cursor.offset - buffer.cursor.x);
//         if (check_col_offset(buffer, core.cols - 1)) {
//             if (buffer.highlight.on) {
//                 try highlight.fill_id_ranges(
//                     &buffer.highlight,
//                     buffer.offset[1],
//                     core.rows - 1,
//                 );
//             }
//         }
//     }
//     try wayland.chars_update(core);
// }

// pub fn line_end(core: *Wayland) !void {
//     const buffer = &core.buffers[core.buffer_index];

//     if (core.mode_line.mode == .Command) {
//         const line = &core.mode_line.line;
//         if (buffer.cursor.x == line.char_count + 1) return;

//         place_cursor(buffer, .{ line.char_count + 1, buffer.cursor.y }, 0);
//     } else {
//         const count = buffer.lines[buffer.cursor.y].char_count;

//         if (buffer.cursor.x == count) return;

//         place_cursor(buffer, .{ count, buffer.cursor.y }, buffer.cursor.offset + count - buffer.cursor.x);
//         if (check_col_offset(buffer, core.cols - 1)) {
//             if (buffer.highlight.on) {
//                 try highlight.fill_id_ranges(
//                     &buffer.highlight,
//                     buffer.offset[1],
//                     core.rows - 1,
//                 );
//             }
//         }
//     }

//     try wayland.chars_update(core);
// }

// pub fn delete_selection(core: *Wayland) !void {
//     const buffer = &core.buffers[core.buffer_index];

//     if (core.mode_line.mode == .Command) {
//         const start = if (buffer.cursor.x < buffer.selection.x) buffer.cursor.x else buffer.selection.x;
//         var end = buffer.cursor.x + buffer.selection.x - start;
//         const line = &core.mode_line.line;

//         if (end <= line.char_count) {
//             end += 1;
//         }

//         util.copy(u8, line.content[end - 1..line.char_count], line.content[start - 1..]);

//         const len = line.char_count + start - end;
//         line.char_count = len;

//         buffer.selection_active = false;
//         place_cursor(buffer, .{ start, buffer.cursor.y}, 0);

//         try wayland.chars_update(core);
//         return;
//     }

//     const boundary = wayland.get_selection_boundary(core);

//     const start = boundary[0];
//     var end = boundary[1];

//     if (buffer.lines[end.y].char_count == end.x) {
//         if (buffer.line_count > end.y + 1) {
//             end.y += 1;
//             end.x = 0;
//             end.offset += 1;
//         }
//     } else {
//         end.x += 1;
//         end.offset += 1;
//     }

//     const len = buffer.lines[end.y].char_count + start.x - end.x;

//     if (buffer.lines[start.y].content.len <= len + 1) {
//         const new = try core.allocator.alloc(u8, 2 * len);

//         const end_of_line = buffer.lines[end.y].char_count;
//         util.copy(u8, buffer.lines[start.y].content[0..start.x], new);
//         util.copy(u8, buffer.lines[end.y].content[end.x..end_of_line], new[start.x..]);

//         core.allocator.free(buffer.lines[start.y].content);

//         buffer.lines[start.y].content.ptr = new.ptr;
//         buffer.lines[start.y].content.len = new.len;
//     } else {
//         const end_of_line = buffer.lines[end.y].char_count;
//         util.copy(u8, buffer.lines[end.y].content[end.x..end_of_line], buffer.lines[start.y].content[start.x..]);
//     }

//     buffer.lines[start.y].char_count = len;
//     buffer.selection_active = false;

//     place_cursor(buffer, .{ start.x, start.y }, start.offset);

//     const diff = end.y - start.y;
//     if (diff != 0) {
//         for (0..diff) |i| {
//             core.allocator.free(buffer.lines[i + start.y + 1].content);
//         }

//         const delta = buffer.line_count - end.y;
//         for (0..delta) |i| {
//             buffer.lines[start.y + 1 + i] = buffer.lines[end.y + 1 + i];
//         }

//         buffer.line_count -= diff;
//     }

//     if (buffer.highlight.on) {
//         try highlight.edit_tree(
//             &buffer.highlight,
//             .Remove,
//             &start,
//             &end,
//             buffer.offset[1],
//             core.rows - 1,
//         );
//     }

//     try wayland.chars_update(core);
// }

// pub fn prev_char(core: *Wayland) !void {
//     const buffer = &core.buffers[core.buffer_index];

//     if (core.mode_line.mode == .Command) {
//         if (buffer.cursor.x == 1) return;
//         place_cursor(buffer, .{ buffer.cursor.x - 1, buffer.cursor.y }, 0);
//     } else {
//         if (buffer.cursor.x != 0){
//             place_cursor(buffer, .{ buffer.cursor.x - 1, buffer.cursor.y }, buffer.cursor.offset - 1);
//         } else if (buffer.cursor.y != 0) {
//             const y = buffer.cursor.y - 1;
//             const line = &buffer.lines[y];

//             place_cursor(buffer, .{ line.char_count, y }, buffer.cursor.offset - 1);
//         } else {
//             return;
//         }
//         if (check_col_offset(buffer, core.cols - 1) or check_row_offset(buffer, core.rows - 1)) {
//             if (buffer.highlight.on) {
//                 try highlight.fill_id_ranges(
//                     &buffer.highlight,
//                     buffer.offset[1],
//                     core.rows - 1,
//                 );
//             }
//         }
//     }

//     try wayland.chars_update(core);
// }

// pub fn next_char(core: *Wayland) !void {
//     const buffer = &core.buffers[core.buffer_index];
//     if (core.mode_line.mode == .Command) {
//         const line = &core.mode_line.line;
//         if (buffer.cursor.x == line.char_count + 1) return;

//         place_cursor(buffer, .{ buffer.cursor.x + 1, buffer.cursor.y }, 0);
//     } else {
//         if (buffer.cursor.x < buffer.lines[buffer.cursor.y].char_count) {
//             place_cursor(buffer, .{ buffer.cursor.x + 1, buffer.cursor.y }, buffer.cursor.offset + 1);
//         } else if (buffer.cursor.y + 1 < buffer.line_count) {
//             place_cursor(buffer, .{ 0, buffer.cursor.y + 1 }, buffer.cursor.offset + 1);
//         } else {
//             return;
//         }

//         if (check_col_offset(buffer, core.cols - 1) or check_row_offset(buffer, core.rows - 1)) {
//             if (buffer.highlight.on) {
//                 try highlight.fill_id_ranges(
//                     &buffer.highlight,
//                     buffer.offset[1],
//                     core.rows - 1,
//                 );
//             }
//         }
//     }
//     try wayland.chars_update(core);
// }

// pub fn next_word(core: *Wayland) !void {
//     const buffer = &core.buffers[core.buffer_index];
//     const line = if (core.mode_line.mode == .Command) &core.mode_line.line else &buffer.lines[buffer.cursor.y];
//     const correction: u32 = if (core.mode_line.mode == .Command) 1 else 0;

//     var searching_for_word = false;

//     for (buffer.cursor.x..line.char_count) |i| {
//         if (line.content[i - correction] == ' ') {
//             searching_for_word = true;
//         } else if (searching_for_word) {
//             const ii: u32 = @intCast(i);
//             place_cursor(buffer, .{ ii, buffer.cursor.y }, buffer.cursor.offset + ii - buffer.cursor.x);
//             break;
//         }
//     }

//     if (!searching_for_word) return;
//     if (check_col_offset(buffer, core.cols - 1) or check_row_offset(buffer, core.rows - 1)) {
//         if (buffer.highlight.on) {
//             try highlight.fill_id_ranges(
//                 &buffer.highlight,
//                 buffer.offset[1],
//                 core.rows - 1,
//             );
//         }
//     }

//     try wayland.chars_update(core);
// }

// pub fn prev_word(core: *Wayland) !void {
//     const buffer = &core.buffers[core.buffer_index];
//     const line = if (core.mode_line.mode == .Command) &core.mode_line.line else &buffer.lines[buffer.cursor.y];
//     const right_boundary: u32 = if (core.mode_line.mode == .Command) buffer.cursor.x - 1 else buffer.cursor.x;

//     var searching_for_space = false;

//     for (0..right_boundary) |i| {
//         const ii: u32 = @intCast(i);

//         if (line.content[right_boundary - i - 1] != ' ') {
//             searching_for_space = true;
//             if (i == right_boundary - 1) {
//                 const offset = if (core.mode_line.mode == .Command) 0 else buffer.cursor.offset - right_boundary;
//                 place_cursor(buffer, .{ buffer.cursor.x - right_boundary, buffer.cursor.y }, offset);
//             } else {
//                 return;
//             }
//         } else if (searching_for_space) {
//             const offset = if (core.mode_line.mode == .Command) 0 else buffer.cursor.offset - ii;
//             place_cursor(buffer, .{ buffer.cursor.x - ii, buffer.cursor.y }, offset);
//             break;
//         }
//     }

//     if (check_col_offset(buffer, core.cols - 1) or check_row_offset(buffer, core.rows - 1)) {
//         if (buffer.highlight.on) {
//             try highlight.fill_id_ranges(
//                 &buffer.highlight,
//                 buffer.offset[1],
//                 core.rows - 1,
//             );
//         }
//     }

//     try wayland.chars_update(core);
// }

// pub fn selection_mode(core: *Wayland) !void {
//     const buffer = &core.buffers[core.buffer_index];

//     buffer.selection_active = !buffer.selection_active;

//     if (!buffer.selection_active) {
//         buffer.selection.x = buffer.cursor.x;
//         buffer.selection.y = buffer.cursor.y;
//         buffer.selection.offset = buffer.cursor.offset;
//         core.update = true;
//     }
// }

// pub fn scroll_down(core: *Wayland) !void {
//     const buffer = &core.buffers[core.buffer_index];

//     const add = (core.rows - 1) / 2;
//     if (buffer.offset[1] + add >= buffer.line_count - 2) return;
//     buffer.offset[1] += add;

//     if (buffer.cursor.y < buffer.offset[1]) {
//         var offset: u32 = buffer.cursor.offset;
//         for (buffer.cursor.y..buffer.offset[1]) |i| {
//             offset += buffer.lines[i].char_count + 1;
//         }

//         place_cursor(buffer, .{ 0, buffer.offset[1] }, offset - buffer.cursor.x);
//         buffer.offset[0] = 0;
//     }

//     if (buffer.highlight.on) {
//         try highlight.fill_id_ranges(
//             &buffer.highlight,
//             buffer.offset[1],
//             core.rows - 1,
//         );
//     }

//     try wayland.chars_update(core);
// }

// pub fn scroll_up(core: *Wayland) !void {
//     const buffer = &core.buffers[core.buffer_index];

//     const sub = (core.rows - 1) / 2;
//     if (buffer.offset[1] < sub) {
//         if (buffer.offset[1] == 0) return;
//         buffer.offset[1] = 0;
//     } else {
//         buffer.offset[1] -= sub;
//     }

//     const rows = core.rows - 1;
//     if (buffer.cursor.y >= buffer.offset[1] + rows) {
//         var offset: u32 = buffer.cursor.offset;

//         for (buffer.offset[1] + rows..buffer.cursor.y) |i| {
//             offset -= buffer.lines[i].char_count + 1;
//         }

//         place_cursor(buffer, .{ 0, buffer.offset[1] + rows }, offset + buffer.cursor.x);
//         buffer.offset[0] = 0;
//     }

//     if (buffer.highlight.on) {
//         try highlight.fill_id_ranges(
//             &buffer.highlight,
//             buffer.offset[1],
//             core.rows - 1,
//         );
//     }

//     try wayland.chars_update(core);
// }
