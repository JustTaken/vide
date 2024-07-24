const std = @import("std");
const util = @import("../util.zig");
const HashSet = @import("../collections.zig").HashSet;

const Allocator = std.mem.Allocator;

pub const Fn = struct {
    string: []const u8,
    f: *const fn (*anyopaque, []const []const u8) anyerror!void,

    pub fn hash(self: *const Fn) u32 {
        return util.hash(self.string);
    }

    pub fn eql(self: *const Fn, other: *const Fn) bool {
        return std.mem.eql(u8, self.string, other.string);
    }
};

pub const CommandHandler = struct {
    ptr: *anyopaque,
    key_fn: HashSet(Fn),
    cmd_fn: HashSet(Fn),
    allocator: Allocator,

    pub fn init(
        ptr: *anyopaque, 
        key_sub: []const Fn,
        cmd_sub: []const Fn,
        allocator: Allocator
    ) !CommandHandler {
        var command_handler: CommandHandler = undefined;

        command_handler.ptr = ptr;
        command_handler.allocator = allocator;
        command_handler.cmd_fn = try HashSet(Fn).init((cmd_sub.len + 1) / 2 * 3, allocator);
        command_handler.key_fn = try HashSet(Fn).init((key_sub.len + 1) / 2 * 3, allocator);

        for (key_sub) |key| try command_handler.key_fn.push(key);
        for (cmd_sub) |cmd| try command_handler.cmd_fn.push(cmd);

        return command_handler;
    }

    pub fn execute_key(self: *const CommandHandler, keys: []const u8) bool {
        if (self.key_fn.items.len == 0) return false;
        const element = self.key_fn.get(Fn { .string = keys, .f = undefined }) catch return false;

        element.f(self.ptr, &.{}) catch return false;
        return true;
    }

    pub fn execute_string(self: *const CommandHandler, string: []const u8) bool {
        if (self.cmd_fn.items.len == 0) return false;
        var cmd_end: u32 = @intCast(string.len);
        var cmd = string;

        for (0..string.len) |i| {
            if (string[i] == ' ') {
                cmd_end = @intCast(i + 1);
                cmd = string[0..i];
                break;
            }
        }


        const element = self.cmd_fn.get(Fn { .string = cmd, .f = undefined }) catch return false;

        element.f(self.ptr, &[_][]const u8 { string[cmd_end..] }) catch return false;
        return true;
    }

    pub fn change(self: *CommandHandler, ptr: *anyopaque) void {
        self.ptr = ptr;
    }

    pub fn deinit(self: *const CommandHandler) void {
        self.cmd_fn.deinit();
        self.key_fn.deinit();
    }
};
