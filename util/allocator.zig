const std = @import("std");
const Vec = @import("collections.zig").Vec;
const List = @import("collections.zig").List;

pub fn malloc(size: usize) []u8 {
    const ptr: [*]u8 = @ptrCast(std.c.malloc(size) orelse @panic("Coldn ot allocate"));

    return ptr[0..size];
}

pub fn free(buffer: []u8) void {
    std.c.free(@ptrCast(buffer.ptr));
}

pub const Arena = struct {
    ptr: *anyopaque,
    next_free: usize,
    size: usize,
    name: []const u8,

    pub fn init(name: []const u8, buffer: []u8) Arena {
        return .{
            .ptr = @ptrCast(buffer.ptr),
            .next_free = 0,
            .size = buffer.len,
            .name = name,
        };
    }

    pub fn alloc(self: *Arena, T: type, size: usize) [*]T {
        const length = @sizeOf(T) * size;
        std.debug.print("{s}: {}, units of size: {}, for: {s}, total: {}, current size: {}\n", .{ self.name, size, @sizeOf(T), @typeName(T), length, self.size - self.next_free });
        if (self.next_free + length > self.size) {
            @panic("No more space available");
        }

        var addr = @intFromPtr(self.ptr);
        addr += self.next_free;
        self.next_free += length;

        const ptr: *anyopaque = @ptrFromInt(addr);

        return @ptrCast(@alignCast(ptr));
    }

    pub fn reset(self: *Arena) void {
        self.next_free = 0;
    }
};

// pub fn LinkedList(T: type) type {
//     return struct {
//         first: *C,

//         const Self = @This();
//         const C = N(T);

//         fn init(first: *C) Self {
//             return .{
//                 .first = first,
//             };
//         }

//         fn remove(self: *Self, node: *C) void {
//             if (self.first == node) {
//                 self.first = node.next orelse @panic("Should not happend");
//             } else {
//                 var current_node = self.first;
//                 while (current_node.next != node) {
//                     current_node = current_node.next.?;
//                 }

//                 current_node.next = node.next;
//             }
//         }
//     };
// }

// test "Init" {
//     const L = 1000;
//     const T = u32;
//     const A = List(T, L);

//     const buffer = malloc(A.size);
//     defer free(buffer);

//     var allocator = Arena.init(buffer);
//     var arena = A.init(&allocator);

//     var start = try std.time.Instant.now();
//     for (1..L) |i| {
//         const t = arena.new();
//         t.* = @truncate(i);
//         arena.loc[i - 1].next = @intCast(i);
//         arena.loc[i].prev = @intCast(i - 1);
//     }
//     var end = try std.time.Instant.now();
//     const l = end.since(start);

//     start = try std.time.Instant.now();
//     var vec = try Vec(T).init(L, std.testing.allocator);
//     defer vec.deinit();
//     for (0..L) |i| {
//         try vec.push(@truncate(i));
//     }
//     end = try std.time.Instant.now();
//     const v = end.since(start);

//     std.debug.print("list: {}, vec: {}\n", .{ l / 1000000, v / 1000000 });

//     // const T = u8;
//     // const L = 4;
//     // const Region = Arena(T, L);
//     // const List = LinkedList(T);

//     // var arena = Region.init(&allocator);
//     // const list = List.init(arena.new());
//     // const first = list.first;

//     // try std.testing.expect(@intFromPtr(arena.ptr) == @intFromPtr(first));
//     // arena.destroy(first);

//     // const second = arena.new();

//     // try std.testing.expect(@intFromPtr(arena.ptr) == @intFromPtr(second));

//     // defer allocator.deinit();
// }

test "benchmark" {
    // const T = u32;
    // const L = 1000000;
    // const Region = Arena(T, L);
    // var allocator = Arena.init(@sizeOf(Region) * L + @sizeOf(T) * L);

    // var arena = Region.init(&allocator);
    // const List = LinkedList(T);
    // var list = List.init(arena.new());

    // var start = try std.time.Instant.now();
    // var last = list.first;
    // last.push(arena.new());
    // for (0..L - 1) |_| {
    //     const new = arena.new();
    //     // new.set(@intCast(i));
    //     last.next = new;
    //     last = new;
    // }

    // var start = try std.time.Instant.now();
    // var end = try std.time.Instant.now();
    // var l = end.since(start);
    // start = end;

    // var vec = try Vec(T).init(L, std.testing.allocator);
    // defer vec.deinit();
    // for (0..L) |i| {
    //     try vec.push(@intCast(i));
    // }

    // end = try std.time.Instant.now();

    // var v = end.since(start);

    // std.debug.print("create | list: {}, vec: {}\n", .{l / 1000000, v / 1000000});

    // start = try std.time.Instant.now();
    // list.remove(last);
    // end = try std.time.Instant.now();
    // v = end.since(start);

    // start = end;
    // vec.remove(0);
    // end = try std.time.Instant.now();
    // l = end.since(start);

    // std.debug.print("remove | list: {}, vec: {}\n", .{l / 1000000, v / 1000000});
}
