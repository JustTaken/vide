const std = @import("std");
const util = @import("util.zig");
const copy = util.copy;

const Allocator = std.mem.Allocator;

pub fn Vec(T: type) type {
    const Error = error{
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
            const memory = allocator.alloc(
                T,
                capacity,
            ) catch return Error.AllocationFail;

            items.len = 0;
            items.ptr = memory.ptr;

            return Self{
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

        pub fn repeat(self: *Self, item: T, count: u32) Error!void {
            const self_len = self.len();
            const sum: u32 = self_len + count;

            if (self.capacity <= sum) try self.resize(sum * 2);

            self.items.len += count;
            for (0..count) |i| {
                self.items[i + self_len] = item;
            }
        }

        fn resize(self: *Self, capacity: u32) Error!void {
            const new = self.allocator.alloc(
                T,
                capacity,
            ) catch return Error.AllocationFail;
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

        pub fn insert(self: *Self, item: T, index: usize) Error!void {
            const count = self.len();

            if (index > count) return Error.OutOfLength;

            if (self.capacity <= count) {
                const new_len = count * 2;
                const new = self.allocator.alloc(
                    T,
                    new_len,
                ) catch return Error.AllocationFail;

                copy(T, self.items[0..index], new);
                copy(T, self.items[index..], new[index + 1 ..]);

                self.allocator.free(self.items.ptr[0..self.capacity]);

                self.items.ptr = new.ptr;
                self.items.len = count + 1;

                self.capacity = new_len;
            } else {
                self.items.len = count + 1;

                util.back_copy(
                    T,
                    self.items[index..count],
                    self.items[index + 1 ..],
                );
            }

            self.items[index] = item;
        }

        pub fn put(self: *Self, item: T, index: usize) void {
            self.items[index] = item;
        }

        pub fn extend_insert(
            self: *Self,
            items: []const T,
            index: u32,
        ) Error!void {
            const self_len: u32 = @intCast(self.items.len);
            const other_len: u32 = @intCast(items.len);
            const count: u32 = self_len + other_len;

            if (self.capacity <= count) {
                const new_len = count * 2;
                const new = self.allocator.alloc(
                    T,
                    new_len,
                ) catch return Error.AllocationFail;

                copy(T, self.items[0..index], new);
                copy(T, self.items[index..], new[index + other_len ..]);

                self.allocator.free(self.items.ptr[0..self.capacity]);

                self.items.ptr = new.ptr;
                self.items.len = count;
                self.capacity = new_len;
            } else {
                self.items.len = count;

                util.back_copy(
                    T,
                    self.items[index..self_len],
                    self.items[index + other_len ..],
                );
            }

            copy(T, items, self.items[index..]);
        }

        pub fn range(
            self: *const Self,
            start: usize,
            end: usize,
        ) Error![]const T {
            if (start > end) return Error.OutOfLength;
            if (start >= self.items.len) return &.{};
            if (end > self.items.len) return self.items[start..];

            return self.items[start..end];
        }

        pub fn truncate(self: *Self, index: u32) []const T {
            if (index >= self.items.len) return &[_]T{};
            const items = self.items[index..];

            self.items.len = index;
            return items;
        }

        pub fn clear(self: *Self) void {
            self.items.len = 0;
        }

        pub fn get(self: *const Self, index: usize) !*const T {
            if (index >= self.items.len) return Error.OutOfLength;

            return &self.items[index];
        }

        pub fn get_mut(self: *Self, index: usize) !*T {
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

        pub fn remove(self: *Self, index: usize) void {
            copy(T, self.items[index + 1 ..], self.items[index..]);
            self.items.len -= 1;
        }

        pub fn elements(self: *const Self) []const T {
            return self.items;
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
    const Error = error{
        AllocationFail,
    };

    return struct {
        elements: Vec(T),
        index: u32,

        const Self = @This();

        pub fn init(capacity: u32, allocator: Allocator) Error!Self {
            return Self{
                .index = 0,
                .elements = Vec(T).init(
                    capacity,
                    allocator,
                ) catch return Error.AllocationFail,
            };
        }

        pub fn set(self: *Self, index: usize) !void {
            if (self.elements.len() <= index) return error.NoSuchIndex;
            self.index = @intCast(index);
        }

        pub fn get(self: *const Self) *const T {
            return self.elements.get(self.index) catch unreachable;
        }

        pub fn get_mut(self: *Self) *T {
            return self.elements.get_mut(self.index) catch unreachable;
        }

        pub fn push(self: *Self, item: T) !void {
            self.index = self.elements.len();
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
            return Self{
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

pub fn HashSet(T: type) type {
    return struct {
        items: []T,
        ocupation: []bool,
        len: u32,
        allocator: Allocator,

        const Self = @This();
        pub fn init(capacity: usize, allocator: Allocator) !Self {
            return Self{
                .len = 0,
                .allocator = allocator,
                .items = allocator.alloc(
                    T,
                    capacity,
                ) catch return error.AllocationFail,
                .ocupation = allocator.alloc(
                    bool,
                    capacity,
                ) catch return error.AllocationFail,
            };
        }

        pub fn push(self: *Self, item: T) !void {
            const len: u32 = @intCast(self.items.len);
            if (self.len >= len) return error.OutOfLenght;

            const hash = item.hash();
            var index = hash % len;

            while (self.ocupation[index]) {
                index = (index + 1) % len;
            }

            self.len += 1;
            self.ocupation[index] = true;
            self.items[index] = item;
        }

        pub fn get(self: *const Self, item: T) !*const T {
            const hash = item.hash();
            const len: u32 = @intCast(self.items.len);

            var index: u32 = hash % len;
            var count: u32 = 0;

            while (self.ocupation[index] or count >= len) {
                if (self.items[index].eql(&item)) return &self.items[index];
                index = (index + 1) % len;
                count += 1;
            }

            return error.NotFound;
        }

        pub fn deinit(self: *const Self) void {
            self.allocator.free(self.items);
            self.allocator.free(self.ocupation);
        }
    };
}

pub fn FixedVec(T: type, L: u32) type {
    return struct {
        items: [L]T,
        len: u32,

        const Self = @This();

        pub fn init() Self {
            return Self{
                .items = undefined,
                .len = 0,
            };
        }

        pub fn push(self: *Self, item: T) error{OutOfLength}!void {
            if (self.items.len <= self.len) return error.OutOfLength;

            self.items[self.len] = item;
            self.len += 1;
        }

        pub fn extend(self: *Self, items: []const T) error{OutOfLength}!void {
            if (self.items.len <= self.len + items.len) {
                return error.OutOfLength;
            }

            util.copy(T, items, self.items[self.len..]);
            self.len += @intCast(items.len);
        }

        pub fn get(self: *Self, index: u32) !*T {
            if (index >= self.len) return error.OutOfLength;

            return &self.items[index];
        }

        pub fn clear(self: *Self) void {
            self.len = 0;
        }

        pub fn elements(self: *Self) []T {
            return self.items[0..self.len];
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
    try expect(eql(u8, vec.items, &.{ 10, 100 }));
}

test "insert at vec start" {
    var vec = try Vec(u8).init(2, std.testing.allocator);
    defer vec.deinit();

    try vec.push(100);
    try vec.insert(10, 0);
    try expect(vec.items.len == 2);
    try expect(eql(u8, vec.items, &.{ 10, 100 }));
}

test "insert at vec middle" {
    var vec = try Vec(u8).init(2, std.testing.allocator);
    defer vec.deinit();

    try vec.push(10);
    try vec.push(30);
    try vec.push(30);
    try vec.push(30);
    try vec.push(30);
    try vec.push(30);
    try vec.push(30);
    try vec.push(30);
    try vec.push(30);
    try vec.insert(20, 3);
    try expect(vec.items.len == 10);
    try expect(
        eql(u8, vec.items, &.{ 10, 30, 30, 20, 30, 30, 30, 30, 30, 30 }),
    );
}

test "extend insert at vec middle" {
    var vec = try Vec(u8).init(2, std.testing.allocator);
    defer vec.deinit();

    try vec.push(10);
    try vec.push(30);
    try vec.push(30);
    try vec.push(30);
    try vec.push(30);
    try vec.push(30);
    try vec.push(30);
    try vec.push(30);
    try vec.push(30);
    try vec.extend_insert(&.{ 20, 20, 40 }, 3);
    try expect(vec.items.len == 12);
    try expect(
        eql(
            u8,
            vec.items,
            &.{ 10, 30, 30, 20, 20, 40, 30, 30, 30, 30, 30, 30 },
        ),
    );
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

const Test = struct {
    content: []const u8,

    fn hash(self: *const Test) u32 {
        return util.hash(self.content);
    }

    fn eql(self: *const Test, other: *const Test) bool {
        return std.mem.eql(u8, self.content, other.content);
    }
};

test "hash map" {
    var set = try HashSet(Test).init(20, std.testing.allocator);
    defer set.deinit();

    try set.push(Test{ .content = "maca" });
    try set.push(Test{ .content = "maconha" });
    try set.push(Test{ .content = "princesa" });
    try set.push(Test{ .content = "ladrao" });
    try set.push(Test{ .content = "programer" });
    try set.push(Test{ .content = "progamer" });
    try set.push(Test{ .content = "programador" });
    try set.push(Test{ .content = "presidente" });

    const member = try set.get(Test{ .content = "programador" });

    try expect(std.mem.eql(u8, member.content, "programador"));
}
