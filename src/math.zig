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

