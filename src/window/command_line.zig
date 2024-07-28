const std = @import("std");
const util = @import("../util.zig");
const math = @import("../math.zig");

const Allocator = std.mem.Allocator;
const Vec = @import("../collections.zig").Vec;
const Fn = @import("command.zig").Fn;
const Cursor = @import("../math.zig").Vec2D;
const Size = @import("../math.zig").Vec2D;
const Change = @import("core.zig").Change;

const PREFIX = " > ";

pub const CommandLine = struct {
    content: Vec(u8),
    size: Size,
    cursor: u32,
    selection: u32,
    selection_active: bool,
    foreground_changes: *Vec(Change),
    background_changes: *Vec(Change),

    pub fn init(
        size: Size,
        foreground_changes: *Vec(Change),
        background_changes: *Vec(Change),
        allocator: Allocator,
    ) !CommandLine {
        return CommandLine{
            .content = try Vec(u8).init(size.x, allocator),
            .foreground_changes = foreground_changes,
            .background_changes = background_changes,
            .cursor = @intCast(PREFIX.len),
            .selection = @intCast(PREFIX.len),
            .selection_active = false,
            .size = size.sub(&Size.init(0, 1)),
        };
    }

    pub fn resize(self: *CommandLine, size: Size) void {
        self.size = size.sub(&Size.init(0, 1));
    }

    pub fn insert_string(self: *CommandLine, string: []const u8) !void {
        const l: u32 = @intCast(PREFIX.len);
        const len: u32 = @intCast(string.len);

        if (self.size.x <= len + self.content.len() + l) return error.Full;
        try self.content.extend_insert(string, self.cursor - l);

        for (self.cursor - l..self.content.len()) |i| {
            try self.foreground_changes.push(
                Change.add_char(
                    self.content.items[i],
                    @intCast(i + l),
                    self.size.y,
                ),
            );
        }

        self.selection_active = false;
        try self.move_cursor(self.cursor + len);
    }

    fn move_cursor(self: *CommandLine, to: u32) !void {
        {
            const boundary = math.sort(self.cursor, self.selection);

            for (boundary[0]..boundary[1] + 1) |i| {
                try self.background_changes.push(
                    Change.remove(@intCast(i), self.size.y),
                );
            }
        }

        self.cursor = to;
        if (!self.selection_active) {
            self.selection = to;
        }

        {
            const boundary = math.sort(self.cursor, self.selection);

            for (boundary[0]..boundary[1] + 1) |i| {
                try self.background_changes.push(
                    Change.add_background(
                        @intCast(i),
                        self.size.y,
                    ),
                );
            }
        }
    }

    pub fn deactive(self: *CommandLine) !void {
        for (0..self.content.len() + PREFIX.len) |i| {
            try self.foreground_changes.push(
                Change.remove(
                    @intCast(i),
                    self.size.y,
                ),
            );
        }

        self.selection_active = false;
        const boundary = math.sort(self.cursor, self.selection);

        for (boundary[0]..boundary[1] + 1) |i| {
            try self.background_changes.push(
                Change.remove(
                    @intCast(i),
                    self.size.y,
                ),
            );
        }

        self.cursor = @intCast(PREFIX.len);
        self.content.clear();
    }

    pub fn active(self: *CommandLine) !void {
        try self.background_changes.push(
            Change.add_background(
                self.cursor,
                self.size.y,
            ),
        );

        for (0..PREFIX.len) |i| {
            try self.foreground_changes.push(
                Change.add_char(
                    PREFIX[i],
                    @intCast(i),
                    self.size.y,
                ),
            );
        }
    }

    pub fn chars(self: *const CommandLine) []const u8 {
        return self.content.elements();
    }

    pub fn deinit(self: *const CommandLine) void {
        self.content.deinit();
    }

    pub fn commands() []const Fn {
        return &[_]Fn{
            Fn{ .f = space, .string = "Spc" },
            Fn{ .f = prev_char, .string = "C-b" },
            Fn{ .f = next_char, .string = "C-f" },
            Fn{ .f = command_end, .string = "C-e" },
            Fn{ .f = command_start, .string = "C-a" },
            Fn{ .f = delete, .string = "C-d" },
            Fn{ .f = selection_mode, .string = "C-Spc" },
        };
    }
};

fn space(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *CommandLine = @ptrCast(@alignCast(ptr));
    try self.insert_string(" ");
}

fn prev_char(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *CommandLine = @ptrCast(@alignCast(ptr));

    if (self.cursor <= PREFIX.len) return error.NoPrevChar;

    try self.move_cursor(self.cursor - 1);
}

fn next_char(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *CommandLine = @ptrCast(@alignCast(ptr));
    const len: u32 = @intCast(PREFIX.len);

    if (self.cursor >= self.content.len() + len) return error.NoNextChar;

    try self.move_cursor(self.cursor + 1);
}

fn command_end(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *CommandLine = @ptrCast(@alignCast(ptr));
    const len: u32 = @intCast(PREFIX.len);

    if (self.cursor >= self.content.len() + len) return error.AlreadyAtEnd;

    try self.move_cursor(self.content.len() + len);
}

fn command_start(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *CommandLine = @ptrCast(@alignCast(ptr));
    const len: u32 = @intCast(PREFIX.len);

    if (self.cursor <= len) return error.AlreadyAtStart;

    try self.move_cursor(len);
}

fn selection_mode(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *CommandLine = @ptrCast(@alignCast(ptr));

    self.selection_active = !self.selection_active;
    self.selection = self.cursor;
}

fn delete(ptr: *anyopaque, _: []const []const u8) !void {
    const self: *CommandLine = @ptrCast(@alignCast(ptr));
    const len: u32 = @intCast(PREFIX.len);

    const prev_len = self.content.len();
    var boundary = math.sort(self.cursor, self.selection);

    boundary[0] -= len;
    boundary[1] -= len;

    if (boundary[1] < prev_len) boundary[1] += 1;

    for (boundary[1]..prev_len) |i| {
        self.content.put(
            self.content.items[i],
            boundary[0] + i - boundary[1],
        );

        try self.foreground_changes.push(
            Change.add_char(
                self.content.items[i],
                @intCast(boundary[0] + len + i - boundary[1]),
                self.size.y,
            ),
        );
    }

    self.content.items.len -= boundary[1] - boundary[0];

    for (self.content.len()..prev_len) |i| {
        try self.foreground_changes.push(
            Change.remove(
                @intCast(i + len),
                self.size.y,
            ),
        );
    }

    self.selection_active = false;

    try self.move_cursor(boundary[0] + len);
}
