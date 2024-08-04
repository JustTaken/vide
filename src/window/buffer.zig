const std = @import("std");
const util = @import("util");
const math = util.math;

const Allocator = std.mem.Allocator;
const Change = @import("core.zig").Change;
const Vec = util.collections.Vec;
const Deque = util.collections.Cursor;
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
        var vec = try Vec(u8).init(
            math.max(content_len, CHAR_COUNT),
            allocator,
        );

        if (content_len > 0) {
            while (content[indent] == ' ') : (indent += 1) {}
            try vec.extend(content);
        }

        return Line{
            .content = vec,
            .indent = indent,
        };
    }

    fn insert_string(self: *Line, string: []const u8, col: u32) !void {
        if (col <= self.indent) {
            var indent: u32 = 0;

            for (string) |char| {
                if (char != ' ') break;
                indent += 1;
            }

            self.indent += indent;
        }

        try self.content.extend_insert(string, col);
    }

    fn len(self: *const Line) u32 {
        return self.content.len();
    }

    fn deinit(self: *const Line) void {
        self.content.deinit();
    }
};

const Selection = struct {
    cursor: Cursor,
    active: bool,

    fn init(cursor: Cursor) Selection {
        return Selection{
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

const ModificationType = enum {
    Delete,
    Insert,
};

const Modification = struct {
    typ: ModificationType,
    index: u32,
    count: u32,

    pub fn do_delete(
        self: *const Modification,
        buffer: *Buffer,
        coord: *const Coord,
    ) !void {
        var left: u32 = self.count + coord.x;
        var line_count: u32 = coord.y;

        for (coord.y..buffer.lines.len()) |i| {
            const l = buffer.lines.items[i].content.len();

            if (l < left) {
                left -= l + 1;
            } else break;

            line_count += 1;
        }
        const last = buffer.lines.items[line_count].content.items[left..];
        util.copy(
            u8,
            last,
            buffer.lines.items[coord.y].content.items[coord.x..],
        );

        buffer.lines.items[coord.y].content.items.len = last.len + coord.x;

        for (coord.y + 1..line_count + 1) |i| {
            buffer.lines.items[i].deinit();
        }

        buffer.lines.remove_range(coord.y + 1, line_count + 1) catch {};

        if (buffer.rect.contains(coord)) {
            const y = coord.y - buffer.rect.coord.y;

            try buffer.build_foreground(
                y,
                if (coord.y == line_count) y + 1 else buffer.rect.size.y,
            );
        }
    }

    fn do_insert(
        self: *const Modification,
        buffer: *Buffer,
        coord: *const Coord,
    ) !void {
        const content =
            buffer.modification_chain.chars.items[self.index .. self.index +
            self.count];

        var line_count: u32 = 0;
        for (0..content.len) |i| {
            if (content[i] == '\n') line_count += 1;
        }

        try buffer.lines.shift(coord.y + 1, line_count);
        const first_line_len = buffer.lines.items[coord.y].content.len();

        var start: u32 = 0;
        var line_index: u32 = coord.y;
        var col_index: u32 = coord.x;
        for (0..content.len) |i| {
            if (content[i] == '\n') {
                const line = try buffer.lines.get_mut(line_index);
                try line.content.extend_insert(content[start..i], col_index);

                start = @intCast(i + 1);
                line_index += 1;
                col_index = 0;

                buffer.lines.items[line_index] = try Line.init(
                    "",
                    buffer.lines.allocator,
                );
            }
        }

        try buffer.lines.items[line_index].content.extend_insert(
            content[start..content.len],
            col_index,
        );

        if (line_count != 0) {
            const first_line = &buffer.lines.items[coord.y];
            const trunc = first_line.content.truncate(
                coord.x + first_line.len() - first_line_len,
            );

            try buffer.lines.items[coord.y + line_count].content.extend(trunc);
        }

        if (buffer.rect.contains(coord)) {
            const y = coord.y - buffer.rect.coord.y;
            try buffer.build_foreground(
                y,
                if (line_count == 0) y + 1 else buffer.rect.size.y,
            );
        }
    }
};

const ModificationChain = struct {
    chars: Vec(u8),
    modifications: Vec(Modification),
    coords: Vec(Coord),
    register_new: bool,
    len: u32,

    fn init(allocator: Allocator) !ModificationChain {
        return .{
            .modifications = try Vec(Modification).init(10, allocator),
            .coords = try Vec(Coord).init(10, allocator),
            .chars = try Vec(u8).init(10, allocator),
            .register_new = true,
            .len = 0,
        };
    }

    fn go_backward(self: *ModificationChain) !void {
        if (self.len == 0) return error.NoBackwardModification;
        self.len -= 1;
    }

    fn go_foward(self: *ModificationChain) !void {
        if (self.len >= self.modifications.len()) {
            return error.NoFowardModification;
        }

        self.len += 1;
    }

    fn do_last(self: *ModificationChain, buffer: *Buffer) !void {
        const last = try self.modifications.last();
        const coord = try self.coords.last();

        switch (last.typ) {
            .Insert => try last.do_insert(buffer, coord),
            .Delete => try last.do_delete(buffer, coord),
        }
    }

    fn register(
        self: *ModificationChain,
        coord: Coord,
        typ: ModificationType,
    ) !void {
        self.register_new = false;
        self.modifications.items.len = self.len;
        self.coords.items.len = self.len;
        try self.coords.push(coord);

        if (self.len > 0) {
            const mod = self.modifications.items[self.len - 1];
            self.chars.items.len = mod.index + mod.count;
        }

        switch (typ) {
            .Insert => {
                try self.modifications.push(Modification{
                    .typ = .Insert,
                    .count = 0,
                    .index = self.chars.len(),
                });
            },
            .Delete => {
                try self.modifications.push(Modification{
                    .typ = .Delete,
                    .count = 0,
                    .index = self.chars.len(),
                });
            },
        }

        self.len += 1;
    }

    fn push(
        self: *ModificationChain,
        coord: Coord,
        mod: Modification,
    ) !void {
        self.chars.items.len = mod.index;
        if (self.register_new) try self.register(coord, mod.typ);

        const last = try self.modifications.last_mut();

        last.count += mod.count;
        self.chars.items.len += mod.count;
    }

    fn insert(
        self: *ModificationChain,
        coord: Coord,
        chars: []const u8,
    ) !void {
        if (self.register_new) try self.register(coord, .Insert);
        const last = try self.modifications.last_mut();

        last.count += @intCast(chars.len);
        try self.chars.extend(chars);
    }

    fn delete(
        self: *ModificationChain,
        coord: Coord,
        chars: []const u8,
    ) !void {
        if (self.register_new) try self.register(coord, .Delete);
        const last = try self.modifications.last_mut();

        last.count += @intCast(chars.len);
        try self.chars.extend(chars);
    }
};

pub const Buffer = struct {
    name: []const u8,
    lines: Vec(Line),
    cursor: Cursor,
    selection: Selection,
    rect: Rect,
    modification_chain: ModificationChain,
    background_changes: *Vec(Change),
    foreground_changes: *Vec(Change),

    pub fn init(
        name: []const u8,
        buf: []const u8,
        foreground_changes: *Vec(Change),
        background_changes: *Vec(Change),
        size: Length,
        allocator: Allocator,
    ) !Buffer {
        var self: Buffer = undefined;
        const len: u32 = @intCast(buf.len);

        self.modification_chain = try ModificationChain.init(
            allocator,
        );

        self.foreground_changes = foreground_changes;
        self.background_changes = background_changes;
        self.lines = try Vec(Line).init(
            (len + Line.CHAR_COUNT) / Line.CHAR_COUNT,
            allocator,
        );

        {
            var start: usize = 0;
            for (0..len) |i| {
                if (buf[i] == '\n') {
                    try self.lines.push(
                        try Line.init(buf[start..i], allocator),
                    );

                    start = i + 1;
                }
            }
        }

        {
            if (len == 0) {
                try self.lines.push(try Line.init("", allocator));
            }
        }

        self.cursor = Cursor.init(0, 0);
        self.selection = Selection.init(self.cursor);
        self.rect = Rect.init(Coord.init(0, 0), size);
        self.name = name;

        try self.background_changes.push(
            Change.add_background(self.cursor.x, self.cursor.y),
        );
        try self.build_foreground(0, self.rect.size.y);

        return self;
    }

    pub fn move_cursor(self: *Buffer, to: *const Cursor) !void {
        try self.selection_opeartion(Change.remove);

        self.cursor.move(to);
        self.selection.move(to);
        try self.reajust();
        try self.selection_opeartion(Change.add_background);
        self.modification_chain.register_new = true;
    }

    fn selection_opeartion(self: *Buffer, f: fn (u32, u32) Change) !void {
        const rect_end = self.rect.end();
        const greater = self.cursor.greater(&self.selection.cursor);

        var s = if (greater) self.selection.cursor else self.cursor;
        var e = if (greater) self.cursor else self.selection.cursor;

        s.x = math.clamp(self.rect.coord.x, s.x, rect_end.x - 1);
        e.x = math.clamp(self.rect.coord.x, e.x, rect_end.x - 1);

        const start = s.max(&self.rect.coord).sub(&self.rect.coord);
        const end = e.min(
            &rect_end.sub(&Cursor.init(1, 1)),
        ).sub(&self.rect.coord);

        if (start.y == end.y) {
            for (start.x..end.x + 1) |j| {
                try self.background_changes.push(f(@intCast(j), start.y));
            }
        } else {
            const start_line_end = math.min(
                self.lines.items[start.y + self.rect.coord.y].len() + 1,
                rect_end.x,
            ) - self.rect.coord.x;

            for (start.x..start_line_end) |j| {
                try self.background_changes.push(f(@intCast(j), start.y));
            }

            for (0..end.x + 1) |j| {
                try self.background_changes.push(f(@intCast(j), end.y));
            }

            for (start.y + 1..end.y) |i| {
                const line = try self.lines.get(self.rect.coord.y + i);

                if (line.len() < self.rect.coord.x) continue;

                const middle_line_end = math.min(
                    line.len() + 1 - self.rect.coord.x,
                    self.rect.size.x,
                );

                for (0..middle_line_end) |j| {
                    try self.background_changes.push(
                        f(@intCast(j), @intCast(i)),
                    );
                }
            }
        }
    }

    fn build_foreground(self: *Buffer, start_line: u32, end_line: u32) !void {
        const rect_end = self.rect.end();
        const end = Coord.init(
            rect_end.x,
            math.min(rect_end.y, self.rect.coord.y + end_line),
        );

        const lines = try self.lines.range(
            self.rect.coord.y + start_line,
            end.y,
        );

        for (lines, 0..) |line, i| {
            const cols = try line.content.range(self.rect.coord.x, end.x);
            for (cols, 0..) |char, j| {
                try self.foreground_changes.push(
                    Change.add_char(
                        char,
                        @intCast(j),
                        @intCast(i + start_line),
                    ),
                );
            }

            for (cols.len..self.rect.size.x) |j| {
                try self.foreground_changes.push(
                    Change.remove(@intCast(j), @intCast(i + start_line)),
                );
            }
        }

        for (lines.len + start_line..end.y - self.rect.coord.y) |i| {
            for (0..self.rect.size.x) |j| {
                try self.foreground_changes.push(
                    Change.remove(@intCast(j), @intCast(i)),
                );
            }
        }
    }

    fn reajust(self: *Buffer) !void {
        if (self.rect.reajust(&self.cursor)) {
            try self.build_foreground(
                0,
                self.rect.size.y,
            );
        }
    }

    pub fn resize(self: *Buffer, size: *const Length) void {
        self.rect.size.move(size);
    }

    pub fn insert_string(self: *Buffer, string: []const u8) !void {
        const len: u32 = @intCast(string.len);
        const modification = Modification{
            .typ = .Insert,
            .count = len,
            .index = self.modification_chain.chars.len(),
        };

        try self.modification_chain.chars.extend(string);
        try modification.do_insert(self, &self.cursor);
        try self.modification_chain.push(self.cursor, modification);

        self.selection.active = false;
        try self.move_cursor(
            &Cursor.init(self.cursor.x + len, self.cursor.y),
        );
        self.modification_chain.register_new = false;
    }

    pub fn content(self: *const Buffer, allocator: Allocator) !Vec(u8) {
        var vec = try Vec(u8).init(self.lines.len() * 40, allocator);

        for (self.lines.items) |line| {
            try vec.extend(line.content.items);
            try vec.push('\n');
        }

        return vec;
    }

    pub fn commands() []const Fn {
        return &[_]Fn{
            Fn{ .f = enter, .string = "Ret" },
            Fn{ .f = delete, .string = "C-d" },
            Fn{ .f = next_line, .string = "C-n" },
            Fn{ .f = prev_line, .string = "C-p" },
            Fn{ .f = next_char, .string = "C-f" },
            Fn{ .f = prev_char, .string = "C-b" },
            Fn{ .f = line_end, .string = "C-e" },
            Fn{ .f = line_start, .string = "C-a" },
            Fn{ .f = space, .string = "Spc" },
            Fn{ .f = scroll_up, .string = "A-v" },
            Fn{ .f = scroll_down, .string = "C-v" },
            Fn{ .f = selection, .string = "C-Spc" },
            Fn{ .f = undo, .string = "C-u" },
            Fn{ .f = redo, .string = "C-U" },
            Fn{ .f = mult_test, .string = "C-x C-h" },
        };
    }

    pub fn hide(self: *Buffer) !void {
        try self.selection_opeartion(Change.remove);
    }

    pub fn show(self: *Buffer) !void {
        try self.build_foreground(0, self.rect.size.y);
        try self.selection_opeartion(Change.add_background);
    }

    pub fn deinit(self: *const Buffer) void {
        for (self.lines) |line| {
            line.deinit();
        }

        self.lines.deinit();
    }
};

fn enter(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *Buffer = @ptrCast(@alignCast(ptr));

    const modification = Modification{
        .typ = .Insert,
        .count = 1,
        .index = self.modification_chain.chars.len(),
    };

    try self.modification_chain.chars.push('\n');
    try modification.do_insert(self, &self.cursor);
    try self.modification_chain.push(self.cursor, modification);

    const line = try self.lines.get(self.cursor.y);

    self.selection.active = false;
    try self.move_cursor(&Cursor.init(line.indent, self.cursor.y + 1));
    self.modification_chain.register_new = false;
}

fn next_line(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *Buffer = @ptrCast(@alignCast(ptr));

    const y = self.cursor.y + 1;
    const line = try self.lines.get(y);

    const x = math.min(self.cursor.x, line.len());
    const new_cursor = Cursor.init(x, y);

    try self.move_cursor(&new_cursor);
}

fn prev_line(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *Buffer = @ptrCast(@alignCast(ptr));

    try util.assert(self.cursor.y > 0);

    const y = self.cursor.y - 1;
    const line = try self.lines.get(y);

    const len = line.len();
    const x = math.min(self.cursor.x, len);

    try self.move_cursor(&Cursor.init(x, y));
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
    } else x += 1;

    try self.move_cursor(&Cursor.init(x, y));
}

fn prev_char(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *Buffer = @ptrCast(@alignCast(ptr));

    var y = self.cursor.y;
    var x = self.cursor.x;

    if (x < 1) {
        try util.assert(y > 0);
        y -= 1;

        x = self.lines.items[y].content.len() - 1;
    } else x -= 1;

    try self.move_cursor(&Coord.init(x, y));
}

fn line_end(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *Buffer = @ptrCast(@alignCast(ptr));

    const line = try self.lines.get(self.cursor.y);
    try self.move_cursor(&Cursor.init(line.len(), self.cursor.y));
}

fn line_start(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *Buffer = @ptrCast(@alignCast(ptr));

    try util.assert(self.cursor.x > 0);
    try self.move_cursor(&Cursor.init(0, self.cursor.y));
}

fn delete(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *Buffer = @ptrCast(@alignCast(ptr));

    var boundary = self.cursor.sort(&self.selection.cursor);

    if (boundary[1].x < self.lines.items[boundary[1].y].len()) {
        boundary[1].x += 1;
    } else if (self.lines.len() > boundary[1].y + 1) {
        boundary[1].x = 0;
        boundary[1].y += 1;
    }

    var modification = Modification{
        .typ = .Delete,
        .count = 0,
        .index = self.modification_chain.chars.len(),
    };

    var content = self.lines.items[boundary[0].y].content.items[boundary[0].x..];
    for (boundary[0].y + 1..boundary[1].y + 1) |i| {
        try self.modification_chain.chars.extend(content);
        try self.modification_chain.chars.extend("\n");

        modification.count += @intCast(content.len + 1);
        content = self.lines.items[i].content.items[0..];
    }

    const start = if (boundary[0].y != boundary[1].y) 0 else boundary[0].x;
    content = content[0 .. boundary[1].x - start];
    modification.count += @intCast(content.len);
    try self.modification_chain.chars.extend(content);

    try self.selection_opeartion(Change.remove);
    try modification.do_delete(self, &boundary[0]);
    try self.modification_chain.push(boundary[0], modification);

    self.selection.active = false;
    self.selection.move(&self.cursor);
    try self.move_cursor(&boundary[0]);
}

fn selection(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *Buffer = @ptrCast(@alignCast(ptr));

    self.selection.toggle();
    try self.move_cursor(&self.cursor);
}

fn scroll_down(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *Buffer = @ptrCast(@alignCast(ptr));
    if (self.rect.coord.y + 1 >= self.lines.len()) return error.NoMoreSpace;

    const size = math.min(
        self.rect.coord.y + self.rect.size.y / 2,
        self.lines.len() - 1,
    );

    try self.selection_opeartion(Change.remove);
    self.rect.coord.move(&Coord.init(0, size));

    const fit = self.rect.fit(&self.cursor);
    self.cursor.move(&fit);
    self.selection.move(&fit);

    try self.build_foreground(0, self.rect.size.y);
    try self.selection_opeartion(Change.add_background);
}

fn scroll_up(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *Buffer = @ptrCast(@alignCast(ptr));
    if (self.rect.coord.y == 0) return error.NoMoreSpace;

    const half = math.min(self.rect.size.y / 2, self.rect.coord.y);
    const size = self.rect.coord.y - half;

    try self.selection_opeartion(Change.remove);
    self.rect.coord.move(&Coord.init(0, size));

    const fit = self.rect.fit(&self.cursor);
    self.cursor.move(&fit);
    self.selection.move(&fit);

    try self.build_foreground(0, self.rect.size.y);
    try self.selection_opeartion(Change.add_background);
}

fn space(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *Buffer = @ptrCast(@alignCast(ptr));

    try self.insert_string(" ");
}

fn undo(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *Buffer = @ptrCast(@alignCast(ptr));
    const chain = &self.modification_chain;

    if (chain.len == 0) return error.NoModification;

    const mod = try chain.modifications.get(chain.len - 1);
    const coord = try chain.coords.get(chain.len - 1);
    try self.modification_chain.go_backward();

    switch (mod.typ) {
        .Insert => try mod.do_delete(self, coord),
        .Delete => try mod.do_insert(self, coord),
    }

    try self.move_cursor(coord);
}

fn redo(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *Buffer = @ptrCast(@alignCast(ptr));
    const chain = &self.modification_chain;

    const mod = try chain.modifications.get(chain.len);
    const coord = try chain.coords.get(chain.len);
    try self.modification_chain.go_foward();

    switch (mod.typ) {
        .Insert => try mod.do_insert(self, coord),
        .Delete => try mod.do_delete(self, coord),
    }

    try self.move_cursor(coord);
}

fn mult_test(ptr: *anyopaque, _: []const []const u8) !void {
    _ = ptr;
    std.debug.print("testing\n", .{});
}
