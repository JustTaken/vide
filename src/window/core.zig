const std = @import("std");
const util = @import("util");
const math = util.math;

const Vec = util.collections.Vec;
const FixedVec = util.collections.FixedVec;
const List = util.collections.List;
const Cursor = util.collections.Cursor;
const Buffer = @import("buffer.zig").Buffer;
const CommandLine = @import("command_line.zig").CommandLine;
const CommandHandler = @import("command.zig").CommandHandler;
const Size = math.Vec2D;
const Painter = @import("../painter.zig").Painter;
const Fn = @import("command.zig").Fn;
const Listener = util.Listener;
const Line = @import("buffer.zig").Line;

const Instant = std.time.Instant;
const Allocator = std.mem.Allocator;
const Arena = util.allocator.Arena;

pub const State = enum {
    Running,
    Closing,
};

pub const Mode = enum {
    Normal,
    Command,
};

pub const Change = struct {
    char: u8,
    x: u32,
    y: u32,

    pub fn add_char(char: u8, x: u32, y: u32) Change {
        return .{
            .char = char,
            .x = x,
            .y = y,
        };
    }
    pub fn add_background(x: u32, y: u32) Change {
        return .{
            .char = 127,
            .x = x,
            .y = y,
        };
    }

    pub fn remove(x: u32, y: u32) Change {
        return .{
            .char = 32,
            .x = x,
            .y = y,
        };
    }
};

const CommandHandlerType = enum {
    Window,
    Buffer,
    CommandLine,
};

const Commander = struct {
    commands: FixedVec(CommandHandler, 3),
    typ: CommandHandlerType,
    key: FixedVec(u8, 50),
    concatenating: bool,

    const WINDOW: u32 = 0;
    const BUFFER: u32 = 1;
    const COMMAND_LINE: u32 = 2;

    fn init(T: type, arena: *Arena) !Commander {
        var self: Commander = undefined;

        self.commands = FixedVec(CommandHandler, 3).init();
        self.key = FixedVec(u8, 50).init();
        self.concatenating = false;

        try self.commands.push(
            try CommandHandler.init(
                T.commands_handle(),
                T.string_commands(),
                &.{},
                arena,
            ),
        );

        try self.commands.push(
            try CommandHandler.init(
                Buffer.commands(),
                Buffer.string_commands(),
                Buffer.mult_keys(),
                arena,
            ),
        );

        try self.commands.push(
            try CommandHandler.init(
                CommandLine.commands(),
                &.{},
                &.{},
                arena,
            ),
        );

        return self;
    }

    fn set(self: *Commander, typ: CommandHandlerType, ptr: *anyopaque) void {
        const command_handler: *CommandHandler = self.commands.get(
            @intFromEnum(typ),
        ) catch unreachable;

        command_handler.set(ptr);
    }

    fn get(self: *Commander, typ: CommandHandlerType) *CommandHandler {
        return self.commands.get(@intFromEnum(typ)) catch unreachable;
    }

    fn push_key(self: *Commander, key: []const u8) void {
        if (!self.concatenating) {
            self.key.clear();
        } else {
            self.key.push(' ') catch unreachable;
        }

        self.key.extend(key) catch unreachable;
    }

    fn reset(self: *Commander) void {
        self.concatenating = false;
    }

    fn execute_key(
        self: *Commander,
        typ: CommandHandlerType,
    ) bool {
        self.get(typ).execute_key(self.key.elements()) catch |e| {
            switch (e) {
                error.NotComplete => {
                    self.concatenating = true;
                    return true;
                },
                else => return false,
            }
        };

        self.typ = typ;

        self.reset();
        return true;
    }

    fn execute_string(
        self: *Commander,
        string: []const u8,
        typ: CommandHandlerType,
    ) !void {
        self.typ = typ;
        try self.get(typ).execute_string(string);
    }

    fn repeat(self: *Commander) !void {
        try self.get(self.typ).execute_key(self.key.elements());
    }
};

pub fn Core(Backend: type) type {
    return struct {
        painter: *Painter,
        handle: Backend,

        commander: Commander,
        listeners: FixedVec(Listener, 2),
        foreground_changes: Vec(Change),
        background_changes: Vec(Change),

        buffers: Cursor(Buffer),
        command_line: CommandLine,

        state: State,
        mode: Mode,

        size: Size,
        ratios: [3]f32,
        change: bool,

        delay: u64,
        rate: u64,

        last_fetch_delay: Instant,
        last_fetch_rate: Instant,

        frame_rate: u32,
        repeating: bool,

        profiler: u64,

        allocator: Allocator,
        temp_arena: Arena,
        perm_arena: Arena,
        lines: List(Line, 1024),

        const Self = @This();

        pub fn init(
            self: *Self,
            width: u32,
            height: u32,
            font_scale: f32,
            font_ratio: f32,
            allocator: Allocator,
            arena: *Arena,
        ) !void {
            try Backend.init(self);

            self.listeners = FixedVec(Listener, 2).init();
            self.lines = List(Line, 1024).init(arena);
            self.buffers = try Cursor(Buffer).init(5, allocator);
            self.background_changes = try Vec(Change).init(20, allocator);
            self.foreground_changes = try Vec(Change).init(20, allocator);
            self.commander = try Commander.init(Self, arena);
            self.temp_arena = Arena.init("Temp", arena.alloc(u8, 0xFFFF)[0..0xFFFF]);
            self.perm_arena = Arena.init("Prem", arena.alloc(u8, 0xFF)[0..0xFF]);

            self.frame_rate = 60;
            self.repeating = false;
            self.rate = 20 * 1000 * 1000;
            self.delay = 200 * 1000 * 1000;
            self.profiler = 0;

            self.ratios[0] = math.divide(height, width);
            self.ratios[1] = font_scale;
            self.ratios[2] = font_ratio;
            self.size = Size.init(width, height);

            const cels = Size.init(
                @intFromFloat(
                    1.0 / (self.ratios[0] * self.ratios[1] * self.ratios[2]),
                ),
                @intFromFloat(1.0 / self.ratios[1]),
            );

            try self.buffers.push(
                try Buffer.init(
                    "scratch",
                    "This is a scratch buffer\n",
                    &self.foreground_changes,
                    &self.background_changes,
                    cels.sub(&Size.init(0, 1)),
                    allocator,
                    &self.lines,
                    &self.perm_arena,
                ),
            );

            self.command_line = try CommandLine.init(
                cels,
                &self.foreground_changes,
                &self.background_changes,
                arena,
            );

            self.commander.set(.Window, self);
            self.commander.set(.Buffer, self.buffers.get_mut());
            self.commander.set(.CommandLine, &self.command_line);

            self.state = State.Running;
            self.mode = .Normal;
            self.change = true;
            self.allocator = allocator;
        }

        pub fn resize(self: *Self, width: u32, height: u32) void {
            const new_size = Size.init(width, height);

            if (!self.size.eql(&new_size)) {
                self.size.move(&new_size);

                for (self.listeners.elements()) |*l| {
                    l.listen(&new_size);
                }

                self.ratios[0] = math.divide(height, width);

                const cels = Size.init(
                    @intFromFloat(
                        1.0 /
                            (self.ratios[0] * self.ratios[1] * self.ratios[2]),
                    ),
                    @intFromFloat(1.0 / self.ratios[1]),
                );

                self.buffers.get_mut().resize(&cels.sub(&Size.init(0, 1)));
                self.command_line.resize(cels);
            }

            self.change = true;
        }

        pub fn set_painter(self: *Self, painter: *Painter) void {
            self.painter = painter;
        }

        pub fn update(self: *Self) !void {
            const now = try std.time.Instant.now();
            if (self.repeating and now.since(
                self.last_fetch_delay,
            ) >= self.delay) {
                if (now.since(self.last_fetch_rate) >= self.rate) {
                    self.last_fetch_rate = now;

                    self.commander.repeat() catch {
                        self.repeating = false;
                        return;
                    };

                    self.change = true;
                }
            }

            if (!self.change) return;

            try self.painter.update(
                self.foreground_changes.items,
                self.background_changes.items,
            );
            try self.painter.draw();

            self.foreground_changes.clear();
            self.background_changes.clear();

            self.handle.update_surface();
            self.change = false;
            const end = try std.time.Instant.now();
            self.profiler += end.since(now);
        }

        pub fn add_listener(self: *Self, listener: Listener) !void {
            try self.listeners.push(listener);
        }

        pub fn key_input(self: *Self, key_string: []const u8) !void {
            const start = try std.time.Instant.now();
            self.repeating = false;

            if (key_string.len != 1) {
                self.commander.push_key(key_string);
                if (!self.commander.execute_key(.Window)) {
                    if (!self.commander.execute_key(
                        if (self.mode == .Normal) .Buffer else .CommandLine,
                    )) {
                        self.commander.reset();
                        return;
                    }
                }
            } else if (self.mode == .Normal) {
                try self.buffers.get_mut().insert_string(key_string);
            } else {
                try self.command_line.insert_string(key_string);
            }

            const now = try std.time.Instant.now();

            self.last_fetch_delay = now;
            self.last_fetch_rate = now;
            self.repeating = true;
            self.change = true;
            self.profiler += now.since(start);
        }

        pub fn key_up(self: *Self) void {
            self.repeating = false;
        }

        pub fn foreground(
            self: *Buffer,
            T: type,
            ptr: *T,
            f: fn (*T, u8, usize, usize) anyerror!void,
        ) !void {
            for (self.foreground_changes.items) |fore| {
                try f(ptr, @intCast(fore.char), fore.cursor.x, fore.cursor.y);
            }

            self.foreground_changes.clear();
        }

        pub fn background(
            self: *Buffer,
            T: type,
            ptr: *T,
            f: fn (*T, u8, usize, usize) anyerror!void,
        ) !void {
            for (self.background_changes.items) |back| {
                try f(ptr, @intCast(back.char), back.cursor.x, back.cursor.y);
            }

            self.background_changes.clear();
        }

        pub fn deinit(self: *Self) void {
            self.buffers.deinit();
            self.handle.deinit();

            std.debug.print("time taken: {}\n", .{self.profiler / 1000000});
        }

        fn commands_handle() []const Fn {
            return &[_]Fn{
                Fn{ .f = enter, .string = "Ret" },
                Fn{ .f = esc, .string = "Esc" },
                Fn{ .f = command_mode, .string = "A-x" },
            };
        }

        fn string_commands() []const Fn {
            return &[_]Fn{
                Fn{ .f = open_file, .string = "open" },
                Fn{ .f = open_buffer, .string = "buffer" },
                Fn{ .f = save, .string = "save" },
            };
        }

        fn enter(ptr: *anyopaque, _: []const []const u8) !void {
            const self: *Self = @ptrCast(@alignCast(ptr));

            if (self.mode == .Command) {
                self.mode = .Normal;

                const content = self.command_line.chars();
                try self.command_line.deactive();
                self.commander.execute_string(
                    content,
                    .Window,
                ) catch {
                    std.debug.print("pressed enter with: {s}\n", .{content});
                    self.commander.execute_string(
                        content,
                        .Buffer,
                    ) catch return;
                };
            } else {
                return error.DoNotHandle;
            }
        }

        fn esc(ptr: *anyopaque, _: []const []const u8) !void {
            const self: *Self = @ptrCast(@alignCast(ptr));

            if (self.mode == .Command) {
                try self.command_line.deactive();
                self.mode = .Normal;
            } else {
                return error.AlreadyNormalmode;
            }
        }

        fn command_mode(ptr: *anyopaque, _: []const []const u8) !void {
            const self: *Self = @ptrCast(@alignCast(ptr));

            if (self.mode == .Command) {
                return error.AlreadyCommandMode;
            } else {
                try self.command_line.active();
                self.mode = .Command;
            }
        }

        fn open_buffer(ptr: *anyopaque, args: []const []const u8) !void {
            if (args.len != 1) return error.InvalidArgumentCount;
            const self: *Self = @ptrCast(@alignCast(ptr));

            for (self.buffers.elements.items, 0..) |buffer, i| {
                if (std.mem.eql(u8, buffer.name, args[0])) {
                    try self.buffers.get_mut().hide();
                    try self.buffers.set(i);
                    try self.buffers.get_mut().show();
                    break;
                }
            } else {
                try self.command_line.show(&.{ args[0], " not found" });
                return error.NotFound;
            }

            self.commander.set(.Buffer, self.buffers.get_mut());
            try self.command_line.show(&.{ args[0], " opened" });
        }

        fn open_file(ptr: *anyopaque, args: []const []const u8) !void {
            if (args.len != 1) return error.InvalidArgumentCount;
            open_buffer(ptr, args) catch {
                const self: *Self = @ptrCast(@alignCast(ptr));

                const file = std.fs.cwd().openFile(args[0], .{}) catch {
                    try self.command_line.show(&.{ args[0], " not found" });
                    return error.NotFound;
                };

                defer file.close();

                const end_pos = try file.getEndPos();
                const content = self.temp_arena.alloc(u8, end_pos)[0..end_pos];
                defer self.temp_arena.reset();

                if (try file.read(content) != end_pos)
                    return error.IncompleteContetent;

                const cels = Size.init(
                    @intFromFloat(
                        1.0 /
                            (self.ratios[0] * self.ratios[1] * self.ratios[2]),
                    ),
                    @intFromFloat(1.0 / self.ratios[1]),
                );

                try self.buffers.get_mut().hide();
                try self.buffers.push(
                    try Buffer.init(
                        args[0],
                        content,
                        &self.foreground_changes,
                        &self.background_changes,
                        cels.sub(&Size.init(0, 1)),
                        self.allocator,
                        &self.lines,
                        &self.perm_arena,
                    ),
                );

                self.commander.set(.Buffer, self.buffers.get_mut());
                try self.command_line.show(&.{ args[0], " opened" });
            };
        }

        fn save(ptr: *anyopaque, _: []const []const u8) !void {
            const self: *Self = @ptrCast(@alignCast(ptr));
            const buffer = self.buffers.get_mut();

            const file = try std.fs.cwd().openFile(
                buffer.name,
                .{ .mode = .write_only },
            );
            defer file.close();

            const content = buffer.content(&self.temp_arena);
            defer self.temp_arena.reset();

            _ = try file.write(content);

            try self.command_line.show(&.{ buffer.name, " saved" });
        }
    };
}
