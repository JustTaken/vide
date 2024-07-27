const std = @import("std");

const Allocator = std.mem.Allocator;

pub fn read_file(path: []const u8, buffer: []u8) !u32 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const end_pos = try file.getEndPos();

    if (try file.read(buffer) != end_pos) return error.IncompleteContetent;

    return @intCast(end_pos);
}

pub fn copy(T: type, src: []const T, dst: []T) void {
    @setRuntimeSafety(false);

    const len = src.len;

    for (0..len) |i| {
        dst[i] = src[i];
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

    for (0..string.len) |i| {
        h += string[i];
    }

    return h;
}

pub fn assert(b: bool) error { False }!void {
    if (!b) return error.False;
}
