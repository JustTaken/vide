const std = @import("std");

const Allocator = std.mem.Allocator;

const Highlight = @import("highlight.zig").Highlight;
const Vec = @import("../collections.zig").Vec;
const Vec2D = @import("../math.zig").Vec2D;
const Rect = @import("../math.zig").Rect;

const Coord = Vec2D;
const Length = Vec2D;

const Line = struct {
    content: Vec(u8),
    indent: u32,

    const TAB: u32 = 2;
    const CHAR_COUNT: u32 = 50;

    fn init(content: []const u8, allocator: Allocator) !Line {
        var indent = 0;
        if (content.len > 0) {
            while (content[indent] == ' ') : (indent += 1) {}
        }

        return Line {
            .content = try Vec(u8).init(allocator, CHAR_COUNT),
            .indent = indent,
        };
    }

    fn deinit(self: *const Line) void {
        self.content.deinit();
    }
};

const Cursor = struct {
    coord: Coord,
    offset: u32,

    fn init(coord: Coord, offset: u32) Cursor {
        return Cursor {
            .offset = offset,
            .coord = coord,
        };
    }

    fn move(self: *Cursor, to: *const Cursor) void {
        self.coord.move(&to.coord);
        self.offset = to.offset;
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
};

pub const Buffer = struct {
    name: []const u8,
    lines: Vec(Line),
    rect: Rect,
    cursor: Cursor,
    selection: Selection,
    highlight: Highlight,

    pub fn init(
        name: []const u8,
        content: []const u8,
        size: Length,
        allocator: Allocator
    ) !Buffer {
        var lines = try Vec(Line).init((content.len + Line.CHAR_COUNT) / Line.CHAR_COUNT, allocator);

        {
            var line_start: u32 = 0;
            for (0..content.len) |i| {
                if (content[i] == '\n') {
                    lines.push(
                        Line.init(content[line_start..i], allocator)
                    );

                    line_start = i + 1;
                }
            }
        }

        {
            if (content.len == 0) {
                try lines.push("", allocator);
            }
        }

        const cursor = Cursor.init(Coord.init(0, 0), 0);
        const selection = Selection.init(cursor);

        return Buffer {
            .name = name,
            .lines = lines,

            .rect = Rect.init(Coord.init(0, 0), size),
            .cursor = cursor,
            .selection = selection,
        };
    }

    pub fn move_cursor(self: *Buffer, to: *const Cursor) void {
        self.cursor.move(to);
        self.selection.move(to);
    }

    pub fn deinit(self: *const Buffer) void {
        self.lines.deinit();
    }
};

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
