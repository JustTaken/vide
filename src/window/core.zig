const std = @import("std");
const util = @import("util");
const math = util.math;

const Vec = util.collections.Vec;
const FixedVec = util.collections.FixedVec;
const Cursor = util.collections.Cursor;
const Buffer = @import("buffer.zig").Buffer;
const CommandLine = @import("command_line.zig").CommandLine;
const CommandHandler = @import("command.zig").CommandHandler;
const Size = math.Vec2D;
const Painter = @import("../painter.zig").Painter;
const Fn = @import("command.zig").Fn;
const Listener = util.Listener;

const Instant = std.time.Instant;
const Allocator = std.mem.Allocator;

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
    primary: CommandHandlerType,
    fallback: CommandHandlerType,
    key: FixedVec(u8, 20),

    const WINDOW: u32 = 0;
    const BUFFER: u32 = 1;
    const COMMAND_LINE: u32 = 2;

    fn init(T: type, allocator: Allocator) !Commander {
        var self: Commander = undefined;

        self.commands = FixedVec(CommandHandler, 3).init();
        self.key = FixedVec(u8, 20).init();

        try self.commands.push(
            try CommandHandler.init(
                T.commands_handle(),
                T.string_commands(),
                allocator,
            ),
        );

        try self.commands.push(
            try CommandHandler.init(Buffer.commands(), &.{}, allocator),
        );

        try self.commands.push(
            try CommandHandler.init(CommandLine.commands(), &.{}, allocator),
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

    fn execute_key(
        self: *Commander,
        key: []const u8,
        primary: CommandHandlerType,
        fallback: CommandHandlerType,
    ) !void {
        if (!self.get(primary).execute_key(key)) {
            if (!self.get(fallback).execute_key(key))
                return error.CommandFail;
        }

        self.key.clear();
        self.primary = primary;
        self.fallback = fallback;
        try self.key.extend(key);
    }

    fn execute_string(
        self: *Commander,
        string: []const u8,
        primary: CommandHandlerType,
        fallback: CommandHandlerType,
    ) !void {
        if (!self.get(primary).execute_string(string)) {
            if (!self.get(fallback).execute_string(string))
                return error.CommandFail;
        }
    }

    fn repeat(self: *Commander) !void {
        if (!self.get(self.primary).execute_key(self.key.elements()))
            if (!self.get(self.fallback).execute_key(self.key.elements()))
                return error.CommandFail;
    }

    fn deinit(self: *Commander) void {
        for (self.commands.elements()) |c| {
            c.deinit();
        }
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

        allocator: Allocator,

        const Self = @This();

        pub fn init(
            width: u32,
            height: u32,
            font_scale: f32,
            font_ratio: f32,
            allocator: Allocator,
        ) !*Self {
            const self = try allocator.create(Self);
            try Backend.init(self);

            self.listeners = FixedVec(Listener, 2).init();
            self.buffers = try Cursor(Buffer).init(5, allocator);
            self.background_changes = try Vec(Change).init(20, allocator);
            self.foreground_changes = try Vec(Change).init(20, allocator);

            self.commander = try Commander.init(Self, allocator);

            self.frame_rate = 10;
            self.repeating = false;
            self.rate = 20 * 1000 * 1000;
            self.delay = 200 * 1000 * 1000;

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
                ),
            );
            self.command_line = try CommandLine.init(
                cels,
                &self.foreground_changes,
                &self.background_changes,
                allocator,
            );

            self.commander.set(.Window, self);
            self.commander.set(.Buffer, self.buffers.get_mut());
            self.commander.set(.CommandLine, &self.command_line);

            self.state = State.Running;
            self.mode = .Normal;
            self.change = true;
            self.allocator = allocator;

            return self;
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
        }

        pub fn add_listener(self: *Self, listener: Listener) !void {
            try self.listeners.push(listener);
        }

        pub fn key_input(self: *Self, key_string: []const u8) !void {
            self.repeating = false;

            if (key_string.len != 1) {
                self.commander.execute_key(
                    key_string,
                    .Window,
                    if (self.mode == .Normal) .Buffer else .CommandLine,
                ) catch return;
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
            self.command_line.deinit();
            self.handle.deinit();
            self.commander.deinit();
            self.allocator.destroy(self);
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
                    .Buffer,
                ) catch return;
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
            } else return error.NotFound;

            self.commander.set(.Buffer, self.buffers.get_mut());
        }

        fn open_file(ptr: *anyopaque, args: []const []const u8) !void {
            if (args.len != 1) return error.InvalidArgumentCount;
            open_buffer(ptr, args) catch {
                const self: *Self = @ptrCast(@alignCast(ptr));

                const file = try std.fs.cwd().openFile(args[0], .{});
                defer file.close();

                const end_pos = try file.getEndPos();
                const content = try self.allocator.alloc(u8, end_pos);
                defer self.allocator.free(content);

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
                    ),
                );

                self.commander.set(.Buffer, self.buffers.get_mut());
                try self.command_line.show(&.{ args[0], " opend" });
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

            const content = try buffer.content(self.allocator);
            defer content.deinit();

            _ = file.write(content.items) catch |e| {
                std.debug.print("error: {}\n", .{e});
            };

            try self.command_line.show(&.{ buffer.name, " saved" });
        }
    };
}
