const std = @import("std");
const math = @import("../math.zig");
const util = @import("../util.zig");

const Vec = @import("../collections.zig").Vec;
const FixedVec = @import("../collections.zig").FixedVec;
const Cursor = @import("../collections.zig").Cursor;
const Buffer = @import("buffer.zig").Buffer;
const ModeLine = @import("mode_line.zig").ModeLine;
const CommandHandler = @import("command.zig").CommandHandler;
const Size = @import("../math.zig").Vec2D;
const Painter = @import("../vulkan/painter.zig").Painter;
const Fn = @import("command.zig").FnSub;

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
        mode_line: ModeLine,

        state: State,
        mode: Mode,

        size: Size,
        ratios: [3]f32,
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

            try self.commands.push(try CommandHandler.init(self, commands_handle(), null, allocator));

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
            try self.commands.push(try CommandHandler.init(buffer, Buffer.commands(), null, allocator));

            self.mode_line = try ModeLine.init(cels.y, allocator);
            try self.commands.push(try CommandHandler.init(&self.mode_line, ModeLine.commands(), null, allocator));

            self.state = State.Running;
            self.mode = .Normal;
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
                self.mode_line.set_row(cels.y);
            }
        }

        pub fn update(self: *Self) !void {
            try self.painter.update(self.buffers.get(), &self.mode_line);
            try self.painter.draw();

            self.handle.update_surface();
        }

        pub fn add_listener(self: *Self, listener: ResizeListener) !void {
            try self.listeners.push(listener);
        }

        pub fn key_input(self: *Self, key_string: []const u8) !void {
            if (key_string.len == 1) {
                if (self.mode == .Normal) {
                    try self.buffers.get_mut().insert_string(key_string);
                } else {
                    try self.mode_line.insert_string(key_string);
                }
            } else {
                const window_command = try self.commands.get(0);

                if (!window_command.execute_key(key_string)) {
                    const command_handler = if (self.mode == .Normal) try self.commands.get(1) else try self.commands.get(2);
                    if (!command_handler.execute_key(key_string)) return;
                }
            }

            try self.update();
        }

        pub fn key_up(self: *Self) void {
            _ = self;
        }

        pub fn deinit(self: *Self) void {
           self.buffers.deinit();
           self.mode_line.deinit();
           self.handle.deinit();

           for (self.commands.elements()) |c| {
               c.deinit();
           }

           self.allocator.destroy(self);
        }

        fn commands_handle() []const Fn {
            return &[_]Fn {
                Fn { .f = enter,        .hash = util.hash_key("Ret") },
                Fn { .f = command_mode, .hash = util.hash_key("A-x") },
            };
        }

        fn enter(ptr: *anyopaque) !void {
            const self: *Self = @ptrCast(@alignCast(ptr));

            if (self.mode == .Command) {
                self.mode = .Normal;
                self.mode_line.toggle_cursor();
            } else {
                return error.DoNotHandle;
            }
        }

        fn command_mode(ptr: *anyopaque) !void {
            const self: *Self = @ptrCast(@alignCast(ptr));

            if (self.mode == .Command) {
                return error.AlreadyCommandMode;
            } else {
                self.mode_line.toggle_cursor();
                self.mode = .Command;
            }
        }
    };
}

