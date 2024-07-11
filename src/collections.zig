const std = @import("std");
const copy = @import("util.zig").copy;

const Allocator = std.mem.Allocator;

pub fn Vec(T: type) type {
    const Error = error {
        AllocationFail,
        OutOfLength,
    };

    return struct {
        items: []T,
        capacity: u32,
        allocator: Allocator,

        const Self = @This();

        pub fn init(capacity: u32, allocator: Allocator) Error!Self {
            var items: []T = undefined;
            const memory = allocator.alloc(T, capacity) catch return Error.AllocationFail;

            items.len = 0;
            items.ptr = memory.ptr;

            return Self {
                .items = items,
                .capacity = capacity,
                .allocator = allocator,
            };
        }

        pub fn push(self: *Self, item: T) Error!void {
            const count: u32 = self.len();

            if (self.capacity <= count) try self.resize(count * 2);

            self.items.len += 1;
            self.items[count] = item;
        }

        fn resize(self: *Self, capacity: u32) Error!void {
            const new = self.allocator.alloc(T, capacity) catch return Error.AllocationFail;
            const count = self.len();

            copy(T, self.items, new);
            self.allocator.free(self.items.ptr[0..self.capacity]);

            self.items.ptr = new.ptr;
            self.items.len = count;
            self.capacity = capacity;
        }

        pub fn extend(self: *Self, items: []const T) Error!void {
            const new_len: u32 = @intCast(self.items.len + items.len);

            if (self.capacity <= new_len) try self.resize(new_len * 2);
            copy(T, items, self.items[self.items.len..]);

            self.items.len = new_len;
        }

        pub fn insert(self: *Self, item: T, index: u32) Error!void {
            const count = self.len();

            if (index > count) return Error.OutOfLength;

            if (self.capacity <= count) {
                const new_len = count * 2;
                const new = self.allocator.alloc(T, new_len) catch return Error.AllocationFail;

                copy(T, self.items[0..index], new);
                copy(T, self.items[index..], new[index + 1..]);

                self.allocator.free(self.items.ptr[0..self.capacity]);

                self.items.ptr = new.ptr;
                self.items.len = count + 1;

                self.capacity = new_len;
            } else {
                self.items.len += 1;

                for (index..count) |i| {
                    self.items[i + 1] = self.items[i];
                }
            }

            self.items[index] = item;
        }

        pub fn range(self: *const Self, start: u32, end: u32) ![]const T {
            var e = end + 1;

            if (start > end) return Error.OutOfLength;
            if (start >= self.items.len) return Error.OutOfLength;
            if (e > self.items.len) e = self.len();

            return self.items[start..e];
        }

        pub fn get(self: *const Self, index: u32) !*const T {
            if (index >= self.items.len) return Error.OutOfLength;

            return &self.items[index];
        }

        pub fn get_mut(self: *Self, index: u32) !*T {
            if (index >= self.items.len) return Error.OutOfLength;

            return &self.items[index];
        }

        pub fn last_mut(self: *Self) !*T {
            if (self.items.len == 0) return Error.OutOfLength;

            return &self.items[self.items.len - 1];
        }

        pub fn len(self: *const Self) u32 {
            return @intCast(self.items.len);
        }

        pub fn iter(self: *const Self) Iter(T) {
            return Iter(T).init(self);
        }

        pub fn deinit(self: *const Self) void {
            self.allocator.free(self.items.ptr[0..self.capacity]);
        }
    };
}

pub fn Cursor(T: type) type {
    const Error = error {
        AllocationFail,
    };

    return struct {
        elements: Vec(T),
        index: u32,

        const Self = @This();

        pub fn init(capacity: u32, allocator: Allocator) Error!Self {
            return Self {
                .elements = Vec(T).init(capacity, allocator) catch return Error.AllocationFail,
                .index = 0,
            };
        }

        pub fn get(self: *const Self) *const T {
            return self.elements.get(self.index) catch unreachable;
        }

        pub fn get_mut(self: *Self) *T {
            return self.elements.get_mut(self.index) catch unreachable;
        }

        pub fn push(self: *Self, item: T) !void {
             self.elements.push(item) catch return Error.AllocationFail;
        }

        pub fn deinit(self: *const Self) void {
            self.elements.deinit();
        }
    };
}

pub fn Iter(T: type) type {
    return struct {
        elements: *const Vec(T),
        next: u32,

        const Self = @This();
        pub fn init(elements: *const Vec(T)) Self {
            return Self {
                .elements = elements,
                .next = 0,
            };
        }

        pub fn next(self: *Self) ?*const T {
            self.elements.get(self.next) catch return null;
            self.next += 1;
        }

        pub fn take(self: *Self, f: fn (*const T) bool) ?*const T {
            for (self.elements.items) |*e| {
                if (f(e)) return e;
            }

            return null;
        }

        pub fn reset(self: *Self) void {
            self.next = 0;
        }
    };
}

pub fn FixedVec(T: type, L: u32) type {
    return struct {
        elements: [L]T,
        len: u32,

        const Self = @This();

        pub fn init() Self {
            return Self {
                .elements = undefined,
                .len = 0,
            };
        }

        pub fn push(self: *Self, item: T) error { OutOfLength }!void {
            if (self.elements.len <= self.len) return error.OutOfLength;

            self.elements[self.len] = item;
            self.len += 1;
        }

        pub fn items(self: *Self) []T {
            return self.elements[0..self.len];
        }
    };
}

const expect = std.testing.expect;
const eql = std.mem.eql;

test "push to vec" {
    var vec = try Vec(u8).init(2, std.testing.allocator);
    defer vec.deinit();
    try vec.push(10);
    try vec.push(100);

    try expect(vec.items.len == 2);
    try expect(eql(u8, vec.items, &.{ 10 , 100 }));
}

test "insert at vec start" {
    var vec = try Vec(u8).init(2, std.testing.allocator);
    defer vec.deinit();

    try vec.push(100);
    try vec.insert(10, 0);
    try expect(vec.items.len == 2);
    try expect(eql(u8, vec.items, &.{ 10, 100}));
}

test "insert at vec middle" {
    var vec = try Vec(u8).init(2, std.testing.allocator);
    defer vec.deinit();

    try vec.push(10);
    try vec.push(30);
    try vec.insert(20, 1);
    try expect(vec.items.len == 3);
    try expect(eql(u8, vec.items, &.{ 10, 20, 30}));
}

test "insert in vec should fail" {
    var vec = try Vec(u8).init(2, std.testing.allocator);
    defer vec.deinit();

    try expect(vec.insert(10, 1) == error.OutOfLength);
}

test "extend vec" {
    var vec = try Vec(u8).init(2, std.testing.allocator);
    defer vec.deinit();

    try vec.extend(&.{ 10, 20, 30 });
    try expect(vec.items.len == 3);
    try expect(eql(u8, vec.items, &.{ 10, 20, 30 }));
}

fn p(e: *const u8) bool {
    return e.* == 60;
}

test "take iter" {
    var vec = try Vec(u8).init(2, std.testing.allocator);
    defer vec.deinit();
    try vec.extend(&.{ 0, 10, 20, 30, 42, 50, 60, 70, 80, 90, 100 });

    var iter = vec.iter();

    const result = iter.take(p);

    if (result) |r| {
        try expect(r.* == 60);
    }
}
