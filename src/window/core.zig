const std = @import("std");
const math = @import("../math.zig");

const Vec = @import("../collections.zig").Vec;
const FixedVec = @import("../collections.zig").FixedVec;
const Cursor = @import("../collections.zig").Cursor;
const Buffer = @import("buffer.zig").Buffer;
const ModeLine = @import("mode_line.zig").ModeLine;
const CommandLine = @import("command_line.zig").CommandLine;
const Size = @import("../math.zig").Vec2D;
const Painter = @import("../vulkan/painter.zig").Painter;

const Allocator = std.mem.Allocator;

pub const State = enum {
    Running,
    Closing,
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
        handle: Backend,

        buffers: Cursor(Buffer),
        mode_line: ModeLine,
        command_line: CommandLine,
        size: Size,

        allocator: Allocator,
        listeners: FixedVec(ResizeListener, 2),
        painter: *Painter,
        state: State,

        ratios: [3]f32,
    // chars: [CHAR_COUNT] Char,
    // last_char: u8,
    // command_handler: command.Command,
    // mode: WindowMode,

    // buffer_index: u32,
    // update: bool,
    // running: bool,
    // resize: bool,

    // control: bool,
    // alt: bool,
    // shift: bool,

    // cols: u32,
    // rows: u32,

    // font_ratio: f32,
    // font_scale: f32,
    // scale: f32,

    // key_delay: u64,
    // key_rate: u64,

    // last_fetch_delay: Instant,
    // last_fetch_rate: Instant,

    // width: u32,
    // height: u32,

    // last_fn: ?*const fn(*Core) anyerror!void,
    // allocator: Allocator,

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

            self.ratios[0] = math.divide(height, width);
            self.ratios[1] = font_scale;
            self.ratios[2] = font_ratio;
            self.size = Size.init(width, height);

            const cels = Size.init(
                @intFromFloat(1.0 / self.ratios[1]),
                @intFromFloat(1.0 / (self.ratios[0] * self.ratios[1] * self.ratios[2]))
            );

            self.buffers = try Cursor(Buffer).init(5, allocator);
            try self.buffers.push(try Buffer.init("scratch", "This is a scratch buffer\n", cels, allocator));

            self.mode_line = try ModeLine.init(10, allocator);
            self.command_line = try CommandLine.init(10, allocator);
            self.listeners = FixedVec(ResizeListener, 2).init();
            self.allocator = allocator;

            self.state = State.Running;

            return self;
        }

        pub fn resize(self: *Self, width: u32, height: u32) void {
            const new_size = Size.init(width, height);
            if (!self.size.eql(&new_size)) {
                self.size.move(&new_size);

                for (self.listeners.items()) |*l| {
                    l.listen(&new_size);
                }

                self.ratios[0] = math.divide(height, width);

                const cels = Size.init(
                    @intFromFloat(1.0 / self.ratios[1]),
                    @intFromFloat(1.0 / (self.ratios[0] * self.ratios[1] * self.ratios[2])),
                );

                const buffer = self.buffers.get_mut();
                buffer.set_size(&cels);
            }
        }

        pub fn update(self: *Self) !void {
            const buffer = self.buffers.get();

            try self.painter.update(buffer);
            try self.painter.draw();

            self.handle.update_surface();
        }

        pub fn add_listener(self: *Self, listener: ResizeListener) !void {
            try self.listeners.push(listener);
        }

        pub fn add_painter(self: *Self, painter: *Painter) void {
            self.painter = painter;
        }

        pub fn key_input(self: *Self, key_string: []const u8) !void {
            // const hash = util.hash_key(key_string[0..key_string_len]);
            _ = self;
            std.debug.print("recieved string of key pressed: {s}\n", .{key_string});
        }

        pub fn key_up(self: *Self) void {
            _ = self;
        }

        pub fn deinit(self: *Self) void {
           self.buffers.deinit();
           self.mode_line.deinit();
           self.command_line.deinit();
           self.handle.deinit();

           self.allocator.destroy(self);
        }
    };
}
