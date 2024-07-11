const std = @import("std");

const Vec = @import("../collections.zig").Vec;
const Cursor = @import("../collections.zig").Cursor;
const Buffer = @import("buffer.zig").Buffer;
const ModeLine = @import("mode_line.zig").ModeLine;
const CommandLine = @import("command_line.zig").CommandLine;
const Size = @import("../math.zig").Vec2D;

const Allocator = std.mem.Allocator;

pub fn Core(Backend: type) type {
    return struct {
        handle: Backend,

        buffers: Cursor(Buffer),
        mode_line: ModeLine,
        command_line: CommandLine,
        size: Size,
        scale: f32,

        allocator: Allocator,
        running: bool,
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

        pub fn init(width: u32, height: u32, allocator: Allocator) !*Self {
            const self = try allocator.create(Self);
            try Backend.init(self);

            self.buffers = try Cursor(Buffer).init(5, allocator);
            self.mode_line = try ModeLine.init(10, allocator);
            self.command_line = try CommandLine.init(10, allocator);
            self.size = Size.init(width, height);
            self.scale = 1.0;
            self.allocator = allocator;

            return self;
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
