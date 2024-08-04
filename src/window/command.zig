const std = @import("std");
const util = @import("util");

const HashSet = util.collections.HashSet;
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

const MultKey = struct {
    string: []const u8,

    pub fn hash(self: *const MultKey) u32 {
        return util.hash(self.string);
    }

    pub fn eql(self: *const MultKey, other: *const MultKey) bool {
        return std.mem.eql(u8, self.string, other.string);
    }
};

pub const Error = error{
    NotComplete,
    NotFound,
    NotExecuted,
};

pub const CommandHandler = struct {
    ptr: *anyopaque,
    key_fn: HashSet(Fn),
    cmd_fn: HashSet(Fn),
    mult_key: HashSet(MultKey),
    allocator: Allocator,

    pub fn init(
        comptime key_sub: []const Fn,
        comptime cmd_sub: []const Fn,
        allocator: Allocator,
    ) !CommandHandler {
        var self: CommandHandler = undefined;

        self.allocator = allocator;
        self.cmd_fn = try HashSet(Fn).init(
            (cmd_sub.len + 1) / 2 * 3,
            allocator,
        );

        self.key_fn = try HashSet(Fn).init(
            (key_sub.len + 1) / 2 * 3,
            allocator,
        );

        self.mult_key = try HashSet(MultKey).init(
            (key_sub.len + 1),
            allocator,
        );

        for (key_sub) |key| {
            try self.key_fn.push(key);

            var start: u32 = 0;
            for (0..key.string.len) |i| {
                if (key.string[i] == ' ') {
                    const new = MultKey{
                        .string = key.string[start..i],
                    };

                    if (self.mult_key.contains(new)) break;
                    try self.mult_key.push(new);
                    start = @intCast(i + 1);
                }
            }
        }

        for (cmd_sub) |cmd| try self.cmd_fn.push(cmd);

        return self;
    }

    pub fn set(self: *CommandHandler, ptr: *anyopaque) void {
        self.ptr = ptr;
    }

    pub fn execute_key(self: *CommandHandler, keys: []const u8) Error!void {
        if (self.mult_key.contains(MultKey{ .string = keys })) {
            return Error.NotComplete;
        }

        const element = self.key_fn.get(Fn{
            .string = keys,
            .f = undefined,
        }) catch return Error.NotFound;

        element.f(self.ptr, &.{}) catch return Error.NotExecuted;
    }

    pub fn execute_string(
        self: *const CommandHandler,
        string: []const u8,
    ) Error!void {
        var cmd_end: u32 = @intCast(string.len);
        var cmd = string;

        for (0..string.len) |i| {
            if (string[i] == ' ') {
                cmd_end = @intCast(i + 1);
                cmd = string[0..i];
                break;
            }
        }

        const element = self.cmd_fn.get(Fn{
            .string = cmd,
            .f = undefined,
        }) catch return Error.NotFound;

        element.f(
            self.ptr,
            &[_][]const u8{string[cmd_end..]},
        ) catch return Error.NotExecuted;
    }

    pub fn change(self: *CommandHandler, ptr: *anyopaque) void {
        self.ptr = ptr;
    }

    pub fn deinit(self: *const CommandHandler) void {
        self.cmd_fn.deinit();
        self.key_fn.deinit();
    }
};
