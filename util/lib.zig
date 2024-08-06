const std = @import("std");
pub const math = @import("math.zig");
pub const collections = @import("collections.zig");
pub const Arena = @import("allocator.zig").Allocator;

const Allocator = std.mem.Allocator;

pub const Listener = struct {
    ptr: *anyopaque,
    f: *const fn (*anyopaque, *const anyopaque) void,

    pub fn listen(self: *Listener, data: *const anyopaque) void {
        self.f(self.ptr, data);
    }
};

pub fn read_file(path: []const u8, buffer: []u8) !u32 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const end_pos = try file.getEndPos();

    if (try file.read(buffer) != end_pos) return error.IncompleteContetent;

    return @intCast(end_pos);
}

pub fn copy(T: type, src: []const T, dst: []T) void {
    @setRuntimeSafety(false);
    for (0..src.len) |i| {
        dst[i] = src[i];
    }
}

pub fn back_copy(T: type, src: []const T, dst: []T) void {
    @setRuntimeSafety(false);
    for (0..src.len) |i| {
        dst[dst.len - i - 1] = src[src.len - i - 1];
    }
}

pub fn parse(i: u32, buffer: []u8) u32 {
    var k: u32 = 0;
    var num = i;

    if (i == 0) {
        buffer[0] = '0';
        return 1;
    }

    while (num > 0) {
        const rem: u8 = @intCast(num % 10);
        buffer[k] = rem + '0';

        k += 1;
        num /= 10;
    }

    return k;
}

pub fn hash(string: []const u8) u32 {
    var h: u32 = 0;

    for (0..string.len) |j| {
        h += @intCast(string[j]);
    }

    return h;
}

pub fn concat(buffer: []u8, len: usize, string: []const u8) []const u8 {
    for (0..string.len) |i| {
        buffer[i + len] = string[i];
    }

    return buffer[0..string.len + len];
}

pub fn is_ascii(u: u8) bool {
    if ((u >= 65 and u <= 90) or (u >= 97 and u <= 122)) return true;
    return false;
}

pub fn assert(b: bool) error{False}!void {
    if (!b) return error.False;
}
