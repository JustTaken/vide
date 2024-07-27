pub const Vec2D = struct {
    x: u32,
    y: u32,

    pub inline fn init(x: u32, y: u32) Vec2D {
        return Vec2D {
            .x = x,
            .y = y,
        };
    }

    pub inline fn eql(self: *const Vec2D, other: *const Vec2D) bool {
        return self.x == other.x and self.y == other.y;
    }

    pub inline fn greater(self: *const Vec2D, other: *const Vec2D) bool {
        return (self.y > other.y) or (self.y == other.y and self.x >= other.x);
    }

    pub inline fn move(self: *Vec2D, to: *const Vec2D) void {
        self.x = to.x;
        self.y = to.y;
    }

    pub inline fn sub(self: *const Vec2D, other: *const Vec2D) Vec2D {
        return Vec2D {
            .x = self.x - other.x,
            .y = self.y - other.y,
        };
    }

    pub inline fn max(self: *const Vec2D, other: *const Vec2D) *const Vec2D {
        if (self.greater(other)) return self;
        return other;
    }

    pub inline fn min(self: *const Vec2D, other: *const Vec2D) *const Vec2D {
        if (self.greater(other)) return other;
        return self;
    }

    pub inline fn copy(self: *const Vec2D) Vec2D {
        return .{
            .x = self.x,
            .y = self.y,
        };
    }
};

pub const Rect = struct {
    coord: Vec2D,
    size: Vec2D,

    pub inline fn init(coord: Vec2D, size: Vec2D) Rect {
        return Rect {
            .coord = coord,
            .size = size,
        };
    }

    pub inline fn reajust(self: *Rect, coord: *const Vec2D) bool {
        var flag = false;
        const e = self.end();

        if (self.coord.x > coord.x) {
            self.coord.x = coord.x;
            flag = true;
        } else if (e.x <= coord.x) {
            self.coord.x = coord.x - self.size.x + 1;
            flag = true;
        }

        if (self.coord.y > coord.y) {
            self.coord.y = coord.y;
            flag = true;
        } else if (e.y <= coord.y) {
            self.coord.y = coord.y - self.size.y + 1;
            flag = true;
        }

        return flag;
    }

    pub inline fn fit(self: *const Rect, coord: *const Vec2D) Vec2D {
        var vec = coord.*;

        const e = self.end();
        if (self.coord.y > coord.y) {
            vec.y = self.coord.y;
            vec.x = 0;
        } else if (e.y < coord.y + 1) {
            vec.y = e.y - 1;
            vec.x = 0;
        }

        return vec;
    }

    pub fn contains(self: *const Rect, coord: *const Vec2D) bool {
        const e = self.end();
        return self.coord.y <= coord.y and e.y > coord.y and self.coord.x <= coord.x and e.x > coord.x;
    }

    pub inline fn end(self: *const Rect) Vec2D {
        return Vec2D.init(self.coord.x + self.size.x, self.coord.y + self.size.y);
    }
};

pub inline fn sub(first: u32, second: i32) u32 {
    const f: i32 = @intCast(first);

    return @intCast(f - second);
}

pub inline fn sum(first: u32, second: i32) u32 {
    const f: i32 = @intCast(first);

    return @intCast(f + second);
}

pub inline fn from_fixed(fixed: isize) u32 {
    return @intCast(fixed >> 6);
}

pub inline fn min(a: u32, b: u32) u32 {
  if (a > b) return b;
  return a;
}

pub inline fn max(a: u32, b: u32) u32 {
  if (a > b) return a;
  return b;
}

pub inline fn divide(numerator: u32, denumerator: u32) f32 {
  const f_numerator: f32 = @floatFromInt(numerator);
  const f_denumerator: f32 = @floatFromInt(denumerator);

  return f_numerator / f_denumerator;
}

