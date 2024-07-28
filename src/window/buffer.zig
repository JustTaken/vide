const std = @import("std");
const util = @import("util");
const math = util.math;

const Allocator = std.mem.Allocator;

const Change = @import("core.zig").Change;
const Vec = util.collections.Vec;
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
    char: u8,
    coord: Coord,

    fn add_char(char: u8, x: u32, y: u32) Modification {
        return .{
            .typ = .Insert,
            .char = char,
            .coord = Coord.init(x, y),
        };
    }

    fn remove_char(char: u8, x: u32, y: u32) Modification {
        return .{
            .typ = .Delete,
            .char = char,
            .coord = Coord.init(x, y),
        };
    }
};

const ModificationChain = struct {
    modifications: Vec(Modification),

    fn init(allocator: Allocator) !ModificationChain {
        return .{
            .modifications = try Vec(Modification).init(4, allocator),
        };
    }

    fn push(self: *ModificationChain, mod: Modification) void {
        self.modifications.push(mod) catch unreachable;
    }
};

pub const Buffer = struct {
    name: []const u8,
    lines: Vec(Line),
    rect: Rect,
    modification_chains: Vec(ModificationChain),
    background_changes: *Vec(Change),
    foreground_changes: *Vec(Change),
    cursor: Cursor,
    selection: Selection,

    pub fn init(
        name: []const u8,
        buf: []const u8,
        foreground_changes: *Vec(Change),
        background_changes: *Vec(Change),
        size: Length,
        allocator: Allocator,
    ) !Buffer {
        var buffer: Buffer = undefined;
        const len: u32 = @intCast(buf.len);

        buffer.modification_chains = try Vec(ModificationChain).init(
            10,
            allocator,
        );

        buffer.foreground_changes = foreground_changes;
        buffer.background_changes = background_changes;
        buffer.lines = try Vec(Line).init(
            (len + Line.CHAR_COUNT) / Line.CHAR_COUNT,
            allocator,
        );

        {
            var start: usize = 0;
            for (0..len) |i| {
                if (buf[i] == '\n') {
                    try buffer.lines.push(
                        try Line.init(buf[start..i], allocator),
                    );

                    start = i + 1;
                }
            }
        }

        {
            if (len == 0) {
                try buffer.lines.push(try Line.init("", allocator));
            }
        }

        buffer.cursor = Cursor.init(0, 0);
        buffer.selection = Selection.init(buffer.cursor);
        buffer.rect = Rect.init(Coord.init(0, 0), size);
        buffer.name = name;

        try buffer.background_changes.push(
            Change.add_background(buffer.cursor.x, buffer.cursor.y),
        );
        try buffer.build_foreground(0, buffer.rect.size.y);
        try buffer.modification_chains.push(
            try ModificationChain.init(allocator),
        );

        return buffer;
    }

    pub fn move_cursor(self: *Buffer, to: *const Cursor) !void {
        try self.selection_opeartion(Change.remove);

        self.cursor.move(to);
        self.selection.move(to);
        try self.reajust();

        try self.selection_opeartion(Change.add_background);
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
            math.max(rect_end.y, self.rect.coord.y + end_line),
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
        if (self.rect.reajust(&self.cursor)) try self.build_foreground(
            0,
            self.rect.size.y,
        );
    }

    pub fn resize(self: *Buffer, size: *const Length) void {
        self.rect.size.move(size);
    }

    fn inverse_modification(
        self: *Buffer,
        chain: *const ModificationChain,
    ) void {
        const len = chain.modifications.len();
        for (0..len) |i| {
            const mod = &chain.modifications.items[len - i - 1];
            const cursor = Cursor.init(mod.x, mod.y);
            switch (mod.typ) {
                .Delete => {
                    if (mod.char == '\n') {
                        try self
                            .lines
                            .insert(
                            Line.init("\n", self.lines.allocator),
                            mod.cursor.y,
                        );
                    } else {
                        try self.lines.items[cursor.y].content.insert(
                            mod.char,
                            cursor.x,
                        );
                        if (self.rect.contains(&cursor)) {
                            try self.foreground_changes.push(
                                Change.add_char(
                                    mod.char,
                                    cursor.x - self.rect.coord.x,
                                    cursor.y - self.rect.coord.y,
                                ),
                            );
                        }
                    }
                },
                .Insert => {
                    if (mod.char == '\n') {
                        try self.lines.items[cursor.y].content.extend(
                            self.lines.items[cursor.y + 1].content.items,
                        );
                        self.lines.items[cursor.y + 1].deinit();
                        self.lines.remove(cursor.y + 1);
                    } else {
                        try self.lines.items[cursor.y].content.remove(cursor.x);
                        if (self.rect.contains(&cursor)) {
                            try self.foreground_changes.push(
                                Change.remove(
                                    cursor.x - self.rect.coord.x,
                                    cursor.y - self.rect.coord.y,
                                ),
                            );
                        }
                    }
                },
            }
        }
    }

    pub fn insert_string(self: *Buffer, string: []const u8) !void {
        const len: u32 = @intCast(string.len);
        const line = try self.lines.get_mut(self.cursor.y);

        try line.insert_string(string, self.cursor.x);
        const line_content = try line.content.range(
            self.cursor.x,
            self.rect.end().x,
        );

        for (line_content, 0..) |char, j| {
            try self.foreground_changes.push(
                Change.add_char(
                    char,
                    @intCast(j + self.cursor.x),
                    self.cursor.y - self.rect.coord.y,
                ),
            );

            const mod_chain = try self.modification_chains.last_mut();
            mod_chain.push(
                Modification.add_char(char, @intCast(j), self.cursor.y),
            );
        }

        self.selection.active = false;
        try self.move_cursor(&Cursor.init(self.cursor.x + len, self.cursor.y));
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

    const line = try self.lines.get_mut(self.cursor.y);

    const start = self.cursor.x - self.rect.coord.x;
    const end = math.min(self.rect.size.x, line.len());

    for (start..end) |j| {
        try self.foreground_changes.push(
            Change.remove(
                @intCast(j),
                self.cursor.sub(&self.rect.coord).y,
            ),
        );
    }

    const new_cursor = Cursor.init(line.indent, self.cursor.y + 1);
    const indent = if (self.cursor.x >= line.indent) line.indent else 0;

    try self.lines.insert(
        try Line.init(
            line.content.truncate(self.cursor.x),
            self.lines.allocator,
        ),
        new_cursor.y,
    );

    try self.lines.items[new_cursor.y].insert_string(
        self.lines.items[self.cursor.y].content.items[0..indent],
        0,
    );

    if (self.rect.contains(&new_cursor)) {
        try self.build_foreground(
            new_cursor.y - self.rect.coord.y,
            math.min(
                self.lines.len() - self.rect.coord.y,
                self.rect.size.y,
            ),
        );
    }

    self.selection.active = false;
    try self.move_cursor(&new_cursor);
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
    } else {
        x += 1;
    }

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
    } else {
        x -= 1;
    }

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
    const start_line = try self.lines.get_mut(boundary[0].y);

    if (boundary[1].x < self.lines.items[boundary[1].y].len()) {
        boundary[1].x += 1;
    } else if (self.lines.len() > boundary[1].y + 1) {
        boundary[1].x = 0;
        boundary[1].y += 1;
    }

    const end_line = try self.lines.get(boundary[1].y);
    const end_line_content = end_line.content.items[boundary[1].x..];
    const start_line_len = start_line.len();

    try self.selection_opeartion(Change.remove);

    self.selection.active = false;
    self.selection.move(&self.cursor);
    start_line.content.items.len = boundary[0].x;

    for (end_line_content) |char| {
        try start_line.content.push(char);
    }

    if (boundary[0].y != boundary[1].y) {
        for (boundary[0].y..boundary[1].y) |i| {
            self.lines.items[i + 1].deinit();
        }

        util.copy(
            Line,
            self.lines.items[boundary[1].y + 1 ..],
            self.lines.items[boundary[0].y + 1 ..],
        );
        self.lines.items.len -= boundary[1].y - boundary[0].y;

        if (self.rect.contains(&boundary[0])) {
            try self.build_foreground(
                boundary[0].y - self.rect.coord.y,
                self.rect.size.y,
            );
        }
    } else {
        const rect_end = self.rect.end();
        if (self.rect.contains(&boundary[0])) {
            for (boundary[0].x..math.min(rect_end.x, start_line.len())) |j| {
                try self.foreground_changes.push(
                    Change.add_char(
                        start_line.content.items[j],
                        @intCast(j - self.rect.coord.x),
                        boundary[0].y - self.rect.coord.y,
                    ),
                );
            }

            const end = math.min(start_line_len, rect_end.x);

            if (start_line.len() < end) {
                for (start_line.len()..end) |j| {
                    try self.foreground_changes.push(
                        Change.remove(
                            @intCast(j - self.rect.coord.x),
                            boundary[0].y - self.rect.coord.y,
                        ),
                    );
                }
            }
        }
    }

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

test "Next line" {
    var foreground_changes = try Vec(Change).init(4, std.testing.allocator);
    var background_changes = try Vec(Change).init(4, std.testing.allocator);

    var buffer = Buffer.init(
        "test",
        "This is a test\nThis is a test\n",
        &foreground_changes,
        &background_changes,
        Length.init(30, 30),
        std.testing.allocator,
    );

    try next_line(&buffer, &.{});
}
