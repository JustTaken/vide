pub inline fn copy(T: type, src: []const T, dst: []T) void {
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
    const len: u32 = @intCast(string.len);

    for (0..len) |i| {
        const index: u32 = @intCast(i);
        h += string[i] + index;
    }

    return h * len;
}
