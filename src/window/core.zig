const std = @import("std");
const math = @import("../math.zig");
const util = @import("../util.zig");

const Vec = @import("../collections.zig").Vec;
const FixedVec = @import("../collections.zig").FixedVec;
const Cursor = @import("../collections.zig").Cursor;
const Buffer = @import("buffer.zig").Buffer;
const CommandLine = @import("command_line.zig").CommandLine;
const CommandHandler = @import("command.zig").CommandHandler;
const Size = @import("../math.zig").Vec2D;
const Painter = @import("../vulkan/painter.zig").Painter;
const Fn = @import("command.zig").Fn;

const Allocator = std.mem.Allocator;

pub const State = enum {
    Running,
    Closing,
};

pub const Mode = enum {
    Normal,
    Command,
};

pub const ResizeListener = struct {
    ptr: *anyopaque,
    f: *const fn (*anyopaque, *const Size) void,

    fn listen(self: *ResizeListener, size: *const Size) void {
        self.f(self.ptr, size);
    }
};

pub fn Core(Backend: type) type {
    return struct {
        painter: *Painter,
        handle: Backend,

        commands: FixedVec(CommandHandler, 3),
        listeners: FixedVec(ResizeListener, 2),

        buffers: Cursor(Buffer),
        command_line: CommandLine,

        state: State,
        mode: Mode,

        size: Size,
        ratios: [3]f32,
        change: bool,
        allocator: Allocator,

        const Self = @This();

        pub fn init(
            width: u32,
            height: u32,
            font_scale: f32,
            font_ratio: f32,
            allocator: Allocator
        ) !*Self {
            const self = try allocator.create(Self);
            try Backend.init(self);

            self.listeners = FixedVec(ResizeListener, 2).init();
            self.commands = FixedVec(CommandHandler, 3).init();

            try self.commands.push(try CommandHandler.init(self, commands_handle(), string_commands(), allocator));

            self.ratios[0] = math.divide(height, width);
            self.ratios[1] = font_scale;
            self.ratios[2] = font_ratio;
            self.size = Size.init(width, height);

            const cels = Size.init(
                @intFromFloat(1.0 / (self.ratios[0] * self.ratios[1] * self.ratios[2])),
                @intFromFloat(1.0 / self.ratios[1])
            );

            self.buffers = try Cursor(Buffer).init(5, allocator);
            try self.buffers.push(try Buffer.init("scratch", "This is a scratch buffer\n", cels, allocator));

            const buffer = self.buffers.get_mut();
            try self.commands.push(try CommandHandler.init(buffer, Buffer.commands(), &.{}, allocator));

            self.command_line = try CommandLine.init(cels.y, allocator);
            try self.commands.push(try CommandHandler.init(&self.command_line, CommandLine.commands(), &.{}, allocator));

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
                    @intFromFloat(1.0 / (self.ratios[0] * self.ratios[1] * self.ratios[2])),
                    @intFromFloat(1.0 / self.ratios[1]),
                );

                const buffer = self.buffers.get_mut();

                buffer.set_size(&cels);
                self.command_line.set_row(cels.y);
            }

            self.change = true;
        }

        pub fn set_painter(self: *Self, painter: *Painter) void {
            self.painter = painter;
        }

        pub fn update(self: *Self) !void {
            const start = try std.time.Instant.now();
            if (!self.change) return;


            try self.painter.update(self.buffers.get(), &self.command_line);
            try self.painter.draw();

            self.handle.update_surface();
            self.change = false;

            const end = try std.time.Instant.now();
            std.debug.print("time for draw frame: {} ns\n", .{end.since(start)});
        }

        pub fn add_listener(self: *Self, listener: ResizeListener) !void {
            try self.listeners.push(listener);
        }

        pub fn key_input(self: *Self, key_string: []const u8) !void {
            if (key_string.len == 1) {
                if (self.mode == .Normal) {
                    try self.buffers.get_mut().insert_string(key_string);
                } else {
                    try self.command_line.insert_string(key_string);
                }
            } else {
                const window_command = try self.commands.get(0);

                if (!window_command.execute_key(key_string)) {
                    const command_handler = if (self.mode == .Normal) try self.commands.get(1) else try self.commands.get(2);
                    if (!command_handler.execute_key(key_string)) return;
                }
            }

            self.change = true;
        }

        pub fn key_up(self: *Self) void {
            _ = self;
        }

        pub fn deinit(self: *Self) void {
           self.buffers.deinit();
           self.command_line.deinit();
           self.handle.deinit();

           for (self.commands.elements()) |c| {
               c.deinit();
           }

           self.allocator.destroy(self);
        }

        fn commands_handle() []const Fn {
            return &[_]Fn {
                Fn { .f = enter,        .string = "Ret" },
                Fn { .f = esc,          .string = "Esc" },
                Fn { .f = command_mode, .string = "A-x" },
            };
        }

        fn string_commands() []const Fn {
            return &[_]Fn {
                Fn { .f = open_file,        .string = "open" },
            };
        }

        fn enter(ptr: *anyopaque, _: []const []const u8) !void {
            const self: *Self = @ptrCast(@alignCast(ptr));

            if (self.mode == .Command) {
                self.mode = .Normal;
                self.command_line.toggle_cursor();

                const command_handler = try self.commands.get(0);
                const content = self.command_line.chars();

                if (!command_handler.execute_string(content)) {
                    const buffer_command_handle = try self.commands.get(1);
                    if (!buffer_command_handle.execute_string(content)) return;
                }
            } else {
                return error.DoNotHandle;
            }
        }

        fn esc(ptr: *anyopaque, _: []const []const u8) !void {
            const self: *Self = @ptrCast(@alignCast(ptr));

            if (self.mode == .Command) {
                self.command_line.toggle_cursor();
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
                self.command_line.toggle_cursor();
                self.mode = .Command;
            }
        }

        fn open_buffer(ptr: *anyopaque, args: []const []const u8) !void {
            if (args.len != 1) return error.InvalidArgumentCount;
            const self: *Self = @ptrCast(@alignCast(ptr));

            for (self.buffers.elements.items, 0..) |buffer, i| {
                if (std.mem.eql(u8, buffer.name, args[0])) {
                    try self.buffers.set(i);
                    break;
                }
            } else return error.NotFound;

            const buffer_command_handler = try self.commands.get(1);
            buffer_command_handler.change(self.buffers.get_mut());
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

                if (try file.read(content) != end_pos) return error.IncompleteContetent;

                const cels = Size.init(
                    @intFromFloat(1.0 / (self.ratios[0] * self.ratios[1] * self.ratios[2])),
                    @intFromFloat(1.0 / self.ratios[1])
                );

                try self.buffers.push(try Buffer.init(args[0], content, cels, self.allocator));
                const buffer_command_handler = try self.commands.get(1);

                buffer_command_handler.change(self.buffers.get_mut());
            };
        }
    };
}

