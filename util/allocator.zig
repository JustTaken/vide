const std = @import("std");

pub const Allocator = struct {
    ptr: *anyopaque,
    next_free: usize,
    size: usize,

    fn init(size: usize) Allocator {
        return .{
            .ptr = std.c.malloc(size) orelse @panic("Failed to allocate\n"),
            .next_free = 0,
            .size = size,
        };
    }

    fn alloc(self: *Allocator, T: type, size: usize) *T {
        const length = @sizeOf(T) * size;
        if (self.next_free + length > self.size) @panic("No more space available");

        var addr = @intFromPtr(self.ptr);
        addr += self.next_free;
        self.next_free += length;

        return @ptrFromInt(addr);
    }

    fn deinit(self: *const Allocator) void {
        std.c.free(self.ptr);
    }
};

pub fn Arena(T: type, L: usize) type {
    return struct {
        ptr: [*]T,
        loc: [*]Node,
        free: usize,

        const Node = struct {
            data: u32,
            next: u32,
            prev: u32,
        };

        const size = (@sizeOf(T) + @sizeOf(Node)) * L;
        const Self = @This();

        fn init(allocator: *Allocator) Self {
            var self: Self = undefined;

            self.loc = @ptrCast(allocator.alloc(Node, L));
            self.ptr = @ptrCast(allocator.alloc(T, L));

            for (0..L) |i| {
                self.loc[i] = Node{
                    .data = @intCast(i),
                    .next = @intCast(if (i + 1 == L) 0 else i + 1),
                    .prev = @intCast(if (i == 0) L - 1 else i - 1),
                };
            }

            self.free = 1;

            return self;
        }

        fn new(self: *Self) *T {
            if (self.free == 0) @panic("Should not be zero");

            const e = &self.loc[self.free];
            self.free = e.next;

            return &self.ptr[e.data];
        }

        fn remove(self: *Self, item: *T) void {
            const pos = (@intFromPtr(item) - @intFromPtr(self.ptr)) /
                @sizeOf(T);

            self.loc[pos].next = self.free;
            self.free = pos;
        }

        fn id(self: *Self, item: *T) u16 {
            return @intCast((@intFromPtr(item) - @intFromPtr(self.ptr)) /
                @sizeOf(T));
        }

        fn first(self: *Self) *T {
            return &self.ptr[0];
        }

        fn next(self: *Self, item: *T) *T {
            const pos = (@intFromPtr(item) - @intFromPtr(self.ptr)) /
                @sizeOf(T);

            return &self.ptr[
                self.loc[
                    self.loc[
                        pos
                    ].next
                ].data
            ];
        }

        fn prev(self: *Self, item: *T) *T {
            const pos = @intFromPtr(item) - @intFromPtr(self.ptr);

            return &self.ptr[
                self.loc[
                    self.loc[
                        pos /
                            @sizeOf(T)
                    ].prev
                ].data
            ];
        }
    };
}

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

test "Init" {
    const L = 1000000;
    const A = Arena(u8, L);

    var allocator = Allocator.init(A.size);
    var arena = A.init(&allocator);

    const start = try std.time.Instant.now();
    for (1..L) |i| {
        _ = arena.new();
        arena.loc[i - 1].next = @intCast(i);
        arena.loc[i].prev = @intCast(i - 1);
    }
    const end = try std.time.Instant.now();
    const l = end.since(start);

    std.debug.print("time: {}\n", .{l / 1000000});

    // const T = u8;
    // const L = 4;
    // const Region = Arena(T, L);
    // const List = LinkedList(T);

    // var arena = Region.init(&allocator);
    // const list = List.init(arena.new());
    // const first = list.first;

    // try std.testing.expect(@intFromPtr(arena.ptr) == @intFromPtr(first));
    // arena.destroy(first);

    // const second = arena.new();

    // try std.testing.expect(@intFromPtr(arena.ptr) == @intFromPtr(second));

    // defer allocator.deinit();
}

test "benchmark" {
    // const T = u32;
    // const L = 1000000;
    // const Region = Arena(T, L);
    // var allocator = Allocator.init(@sizeOf(Region) * L + @sizeOf(T) * L);

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
