const std = @import("std");
const util = @import("lib.zig");

const Allocator = std.mem.Allocator;
const Arena = util.allocator.Arena;

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

            util.copy(T, self.items, new);
            self.allocator.free(self.items.ptr[0..self.capacity]);

            self.items.ptr = new.ptr;
            self.items.len = count;
            self.capacity = capacity;
        }

        pub fn extend(self: *Self, items: []const T) Error!void {
            const new_len: u32 = @intCast(self.items.len + items.len);

            if (self.capacity <= new_len) try self.resize(new_len * 2);

            util.copy(T, items, self.items[self.items.len..]);

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

                util.copy(T, self.items[0..index], new);
                util.copy(T, self.items[index..], new[index + 1 ..]);

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

                util.copy(T, self.items[0..index], new);
                util.copy(T, self.items[index..], new[index + other_len ..]);

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

            util.copy(T, items, self.items[index..]);
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

        pub fn shift(self: *Self, index: u32, count: u32) !void {
            if (count == 0) return;
            if (self.capacity <= count + self.items.len) {
                const new_len = (self.items.len + count) * 2;
                const new = self.allocator.alloc(
                    T,
                    new_len,
                ) catch return Error.AllocationFail;

                util.copy(T, self.items[0..index], new);
                util.copy(T, self.items[index..], new[index + count ..]);

                self.allocator.free(self.items.ptr[0..self.capacity]);

                self.items.ptr = new.ptr;
                self.items.len += count;
                self.capacity = @intCast(new_len);
            } else {
                const l = self.items.len;
                self.items.len += count;

                util.back_copy(
                    T,
                    self.items[index..l],
                    self.items[index + count ..],
                );
            }
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

        pub fn get_back(self: *const Self, index: usize) !*T {
            if (index >= self.items.len) return Error.OutOfLength;

            return &self.items[self.items.len - index - 1];
        }

        pub fn last_mut(self: *Self) !*T {
            if (self.items.len == 0) return Error.OutOfLength;

            return &self.items[self.items.len - 1];
        }

        pub fn last(self: *const Self) !*const T {
            if (self.items.len == 0) return Error.OutOfLength;

            return &self.items[self.items.len - 1];
        }

        pub fn len(self: *const Self) u32 {
            return @intCast(self.items.len);
        }

        pub fn remove(self: *Self, index: usize) void {
            util.copy(T, self.items[index + 1 ..], self.items[index..]);
            self.items.len -= 1;
        }

        pub fn remove_range(self: *Self, start: usize, end: usize) !void {
            if (start >= self.items.len or end > self.items.len or start >= end)
                return error.OutOfLength;

            util.copy(T, self.items[end..], self.items[start..]);
            self.items.len -= end - start;
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

        pub fn set_len(self: *Self, index: usize) !void {
            if (self.elements.len() <= index) return error.NoSuchIndex;
            self.index = @intCast(index);
            self.elements.items.len = self.index;
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
        items: [*]T,
        len: u32,
        capacity: u32,

        const Self = @This();
        pub fn init(capacity: usize, arena: *Arena) !Self {
            const items = arena.alloc(T, capacity);

            const zero = T.init();
            for (0..capacity) |i| {
                items[i] = zero;
            }

            return Self{
                .len = 0,
                .capacity = @intCast(capacity),
                .items = items,
            };
        }

        pub fn push(self: *Self, item: T) !void {
            if (self.len >= self.capacity) return error.OutOfLenght;

            const hash = item.hash();
            var index = hash % self.capacity;

            while (!self.items[index].zero()) {
                index = (index + 1) % self.capacity;
            }

            self.len += 1;
            self.items[index] = item;
        }

        pub fn get(self: *const Self, item: T) !*const T {
            if (self.len == 0) return error.NoElements;

            const hash = item.hash();

            var index: u32 = hash % self.capacity;
            var count: u32 = 0;

            while (!self.items[index].zero() and count < self.capacity) {
                if (self.items[index].eql(&item)) return &self.items[index];
                index = (index + 1) % self.capacity;
                count += 1;
            }

            return error.NotFound;
        }

        pub fn contains(self: *const Self, item: T) bool {
            if (self.len == 0) return false;

            const hash = item.hash();

            var index: u32 = hash % self.capacity;
            var count: u32 = 0;

            while (!self.items[index].zero() or count < self.capacity) {
                if (self.items[index].eql(&item)) return true;
                index = (index + 1) % self.capacity;
                count += 1;
            }

            return false;
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

pub fn CiclicVec(T: type, L: u32) type {
    return struct {
        items: [L]T,
        len: u32,
        first: u32,

        const Self = @This();

        pub fn init() Self {
            return Self{
                .items = undefined,
                .len = 0,
                .first = 0,
            };
        }

        pub fn push(self: *Self, item: T) void {
            self.items[(self.len + self.first) % L] = item;

            if (self.len >= L) {
                self.first = (self.first + 1) % L;
            } else {
                self.len += 1;
            }
        }

        pub fn last(self: *const Self) *const T {
            return &self.items[(self.len + self.first - 1) % L];
        }

        pub fn last_mut(self: *Self) *T {
            return &self.items[(self.len + self.first - 1) % L];
        }

        pub fn get(self: *Self, index: u32) !*T {
            if (self.len == 0) return error.NoElements;
            return &self.items[index % L];
        }

        pub fn change(self: *Self, from: u32, to: u32) void {
            if (from > to) {
                self.len -= from - to;
            } else {
                if (to - from > L - self.len) @panic("Should not happen");
                self.len += to - from;
            }
        }
    };
}

pub fn Array(T: type) type {
    return struct {
        ptr: [*]T,
        len: u32,
        capacity: u32,

        const Self = @This();
        pub fn init(len: u32, arena: *Arena) Self {
            var self: Self = undefined;

            self.ptr = arena.alloc(T, len);
            self.len = 0;
            self.capacity = @intCast(len);

            return self;
        }

        pub fn push(self: *Self, item: T) void {
            if (self.len >= self.capacity) @panic("Should not happen");
            self.ptr[self.len] = item;
            self.len += 1;
        }

        pub fn extend_insert(self: *Self, items: []const T, index: usize) void {
            if (self.len + items.len > self.capacity)
                @panic("Should not happen");

            util.back_copy(
                T,
                self.ptr[index..self.len],
                self.ptr[index + items.len .. self.len + items.len],
            );

            self.len += @intCast(items.len);
            util.copy(T, items, self.ptr[index..self.len]);
        }

        pub fn clear(self: *Self) void {
            self.len = 0;
        }

        pub fn content(self: *const Self) []const T {
            return self.ptr[0..self.len];
        }
    };
}

pub fn List(T: type, L: usize) type {
    return struct {
        ptr: [*]T,
        loc: [*]Node,
        free: usize,

        const Node = struct {
            prev: u16,
            next: u16,
        };

        pub const size = (@sizeOf(T) + @sizeOf(Node)) * L;
        const Self = @This();

        pub fn init(allocator: *Arena) Self {
            var self: Self = undefined;

            self.loc = allocator.alloc(Node, L);
            self.ptr = allocator.alloc(T, L);

            for (0..L) |i| {
                self.loc[i] = Node{
                    .next = @intCast(i + 1),
                    .prev = @intCast(if (i == 0) L else i - 1),
                };
            }

            self.free = 0;

            return self;
        }

        pub fn new(self: *Self) *T {
            if (self.free == L) @panic("No free elements");

            var e = &self.loc[self.free];
            const free = self.free;

            self.free = e.next;
            e.next = L;
            e.prev = L;

            return &self.ptr[free];
        }

        pub fn remove(self: *Self, pos: u16) void {
            const p = self.loc[pos].prev;
            const n = self.loc[pos].next;

            self.loc[p].next = n;

            if (self.valid(n)) {
                self.loc[n].prev = p;
            }

            self.loc[pos].prev = @intCast(L);
            self.loc[pos].next = @intCast(self.free);
            self.free = pos;
        }

        pub fn remove_list(self: *Self, first: u16, last: u16) void {
            const p = self.loc[first].prev;
            const n = self.loc[last].next;

            self.loc[p].next = n;

            if (self.valid(n)) {
                self.loc[n].prev = p;
            }

            self.loc[first].prev = @intCast(L);
            self.loc[last].next = @intCast(self.free);

            self.free = first;
        }

        pub fn id(self: *Self, item: *T) u16 {
            return @intCast((@intFromPtr(item) - @intFromPtr(self.ptr)) /
                @sizeOf(T));
        }

        pub fn back(self: *Self, item: *T, off: u32) *T {
            var i = self.id(item);

            for (0..off) |_| {
                i = self.loc[i].prev;
            }

            return &self.ptr[i];
        }

        pub fn valid(_: *const Self, i: u16) bool {
            return i < L;
        }

        pub fn offset(self: *Self, item: *T, off: u32) *T {
            var i = self.id(item);
            for (0..off) |_| {
                i = self.loc[i].next;
            }

            return &self.ptr[i];
        }

        pub fn move(self: *Self, item: *T, from: u16, to: u16) *T {
            if (from > to) {
                return self.back(item, from - to);
            }

            return self.offset(item, to - from);
        }

        pub fn next_id(self: *Self, pos: u16) ?*T {
            const n = self.loc[pos].next;

            if (n == L) return null;

            return &self.ptr[n];
        }

        pub fn next(self: *Self, item: *T) ?*T {
            const pos = (@intFromPtr(item) - @intFromPtr(self.ptr)) /
                @sizeOf(T);

            return self.next_id(@intCast(pos));
        }

        pub fn insert_after(self: *Self, first: u16, last: u16) void {
            const n = self.loc[first].next;

            self.loc[first].next = last;
            self.loc[last].prev = first;
            self.loc[last].next = n;

            if (self.valid(n)) {
                self.loc[n].prev = last;
            }
        }

        pub fn insert_before(self: *Self, first: u16, last: u16) void {
            const p = self.loc[first].prev;

            self.loc[first].prev = last;
            self.loc[last].next = first;
            self.loc[last].prev = p;

            if (self.valid(p)) {
                self.loc[p].next = last;
            }
        }

        pub fn prev_id(self: *Self, pos: u16) ?*T {
            const p = self.loc[pos].prev;

            if (p == L) return null;

            return &self.ptr[p];
        }

        pub fn prev(self: *Self, item: *T) ?*T {
            const pos = (@intFromPtr(item) - @intFromPtr(self.ptr)) / @sizeOf(T);
            return self.prev_id(@intCast(pos));
        }
    };
}

const expect = std.testing.expect;
const eql = std.mem.eql;

test "LinkedList" {
    var arena = Arena.init("Testing", util.allocator.malloc(100));
    var list = List(u8, 10).init(&arena);
    const first = list.new();
    const first_id = list.id(first);

    var current = first;
    var id = first_id;
    for (0..9) |i| {
        current.* = @intCast(i);

        const next = list.new();
        const next_id = list.id(next);

        list.insert_after(id, next_id);

        id = next_id;
        current = next;
    }

    list.remove(5);
    list.remove(3);
    list.remove(2);

    const second = list.new();
    const second_id = list.id(second);
    current = second;
    id = second_id;
    for (0..2) |i| {
        current.* = @intCast(i);

        const next = list.new();
        const next_id = list.id(next);

        list.insert_after(id, next_id);

        id = next_id;
        current = next;
    }

    try expect(eql(u8, list.ptr[0..10], &.{ 0, 1, 0, 1, 4, 5, 6, 7, 8, 0 }));
}
