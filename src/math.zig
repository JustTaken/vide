pub const Vec2D = struct {
    x: u32,
    y: u32,

    pub fn init(x: u32, y: u32) Vec2D {
        return Vec2D {
            .x = x,
            .y = y,
        };
    }

    pub fn eql(self: *const Vec2D, other: *const Vec2D) bool {
        return self.x == other.x and self.y == other.y;
    }

    pub fn move(self: *Vec2D, to: *const Vec2D) void {
        self.x = to.x;
        self.y = to.y;
    }

    pub fn sub(self: *const Vec2D, other: *const Vec2D) Vec2D {
        return Vec2D {
            .x = self.x - other.x,
            .y = self.y - other.y,
        };
    }
};

pub const Rect = struct {
    coord: Vec2D,
    size: Vec2D,

    pub fn init(coord: Vec2D, size: Vec2D) Rect {
        return Rect {
            .coord = coord,
            .size = size,
        };
    }

    pub fn contains(self: *const Rect, coord: Vec2D) bool {
        const contain_x = self.coord.x <= coord.x and self.coord.x + self.size.x >= coord.x;
        const contain_y = self.coord.y <= coord.y and self.coord.y + self.size.y >= coord.y;

        return contain_x and contain_y;
    }

    pub fn end(self: *const Rect) Vec2D {
        return Vec2D.init(self.coord.x + self.size.x, self.coord.y + self.size.y);
    }
};

pub inline fn sub(first: u32, second: i32) u32 {
    const f: i32 = @intCast(first);

    return @intCast(f - second);
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

