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
            const memory = allocator.alloc(T, capacity) catch return Error.AllocationFail;

            var items: []T = undefined;
            items.len = 0;
            items.ptr = memory.ptr;

            return Self {
                .items = items,
                .capacity = capacity,
                .allocator = allocator,
            };
        }

        pub fn push(self: *Self, item: T) Error!void {
            const len: u32 = @intCast(self.items.len);

            if (self.capacity <= len) try self.resize(len * 2);

            self.items.len += 1;
            self.items[len] = item;
        }

        fn resize(self: *Self, capacity: u32) Error!void {
            const new = self.allocator.alloc(T, capacity) catch return Error.AllocationFail;
            const len = self.items.len;

            copy(T, self.items, new);
            self.allocator.free(self.items.ptr[0..self.capacity]);

            self.items.ptr = new.ptr;
            self.items.len = len;
            self.capacity = capacity;
        }

        pub fn extend(self: *Self, items: []const T) Error!void {
            const new_len: u32 = @intCast(self.items.len + items.len);

            if (self.capacity <= new_len) try self.resize(new_len * 2);
            copy(T, items, self.items[self.items.len..]);

            self.items.len = new_len;
        }

        pub fn insert(self: *Self, item: T, index: u32) Error!void {
            const len = self.items.len;

            if (index > len) return Error.OutOfLength;

            if (self.capacity <= len) {
                const new = self.allocator.alloc(T, len * 2) catch return Error.AllocationFail;

                copy(T, self.items[0..index], new);
                copy(T, self.items[index..], new[index + 1..]);

                self.allocator.free(self.items.ptr[0..self.capacity]);

                self.items.ptr = new.ptr;
                self.items.len = len + 1;

                self.capacity = @intCast(new.len);
            } else {
                self.items.len += 1;

                for (index..self.items.len) |i| {
                    self.items[i + 1] = self.items[i];
                }
            }

            self.items[index] = item;
        }

        pub fn get_mut(self: *Self, index: u32) !*T {
            if (index >= self.items.len) return Error.OutOfLength;

            return &self.items[index];
        }

        pub fn last_mut(self: *Self) *T {
            return &self.items[self.items.len - 1];
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

        pub fn get(self: *Self) *T {
            return self.elements.get(self.index) catch unreachable;
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
        elements: Vec(T),
        next: u32,

        const Self = @This();
        pub fn init(elements: Vec(T)) Self {
            return Self {
                .elements = elements,
                .last = 0,
            };
        }

        pub fn next(self: *Self) ?*T {
            self.elements.get_mut(self.next) catch return null;
            self.next += 1;
        }

        pub fn reset(self: *Self) void {
            self.next = 0;
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

    try expect(vec.insert(10, 1) == .OutOfLength);
}

test "extend vec" {
    var vec = try Vec(u8).init(2, std.testing.allocator);
    defer vec.deinit();

    try vec.extend(&.{ 10, 20, 30 });
    try expect(vec.items.len == 3);
    try expect(eql(u8, vec.items, &.{ 10, 20, 30 }));
}
