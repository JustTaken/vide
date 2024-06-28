const std = @import("std");
const c = @import("../bind.zig").c;
const math = @import("../math.zig");

const Allocator = std.mem.Allocator;
const CHAR_COUNT: u32 = 95;

pub const Wayland = struct {
  display: *c.wl_display,
  registry: *c.wl_registry,
  surface: *c.wl_surface,
  seat: *c.wl_seat,
  compositor: *c.wl_compositor,
  keyboard: *c.wl_keyboard,

  xdg_shell: *c.xdg_wm_base,
  xdg_surface: *c.xdg_surface,
  xdg_toplevel: *c.xdg_toplevel,

  registry_listener: c.wl_registry_listener,
  shell_listener: c.xdg_wm_base_listener,
  shell_surface_listener: c.xdg_surface_listener,
  xdg_toplevel_listener: c.xdg_toplevel_listener,
  seat_listener: c.wl_seat_listener,
  keyboard_listener: c.wl_keyboard_listener,

  buffers: []Buffer,
  last_char: u8,

  buffer_index: u32,
  update: bool,
  running: bool,
  resize: bool,

  control: bool,
  alt: bool,
  shift: bool,

  cols: u32,
  rows: u32,

  font_ratio: f32,
  font_scale: f32,
  scale: f32,

  key_delay: u32,
  key_rate: u32,

  width: u32,
  height: u32,

};

const Buffer = struct {
  chars: [CHAR_COUNT] Char,
  lines: []Line,
  line_count: u32,
  offset: [2]u32,
  cursor: Cursor,
  chars_update: bool,
  allocator: Allocator,
};

const Line = struct {
  content: []u8,
  char_count: u32,
};

const Cursor = struct {
  x: u32,
  y: u32,
};

const Char = struct {
  pos: [][2]u32,
  capacity: u32,
};

pub inline fn get_positions(core: *const Wayland, index: usize) [][2]u32 {
  const buffer = &core.buffers[core.buffer_index];
  return buffer.chars[index].pos;
}

pub inline fn get_cursor_position(core: *const Wayland) [2]u32 {
  const buffer = &core.buffers[core.buffer_index];

  return .{ buffer.cursor.x - buffer.offset[0], buffer.cursor.y - buffer.offset[1] };
}

pub inline fn has_chars_update(core: *const Wayland) bool {
  return core.buffers[core.buffer_index].chars_update;
}

fn buffer_init(allocator: Allocator) !Buffer {
  var buffer: Buffer = undefined;

  buffer.lines = try allocator.alloc(Line, 10);
  buffer.allocator = allocator;
  buffer.offset = .{ 0, 0 };
  buffer.line_count = 1;

  buffer.lines[0] = Line {
    .content = try allocator.alloc(u8, 50),
    .char_count = 0,
  };

  buffer.cursor = Cursor {
    .x = 0,
    .y = 0,
  };

  const count: u32 = 10;
  for (0..CHAR_COUNT) |i| {
    buffer.chars[i] = .{
      .pos = try allocator.alloc([2]u32, count),
      .capacity = count,
    };

    buffer.chars[i].pos.len = 0;
  }

  return buffer;
}

inline fn reset_chars(buffer: *Buffer) void {
  for (0..CHAR_COUNT) |i| {
    buffer.chars[i].pos.len = 0;
  }
}

inline fn copy(T: type, src: []const T, dst: []T) void {
  @setRuntimeSafety(false);

  const len = src.len;

  for (0..len) |i| {
    dst[i] = src[i];
  }
}

inline fn push_char(buffer: *Buffer, index: u32, pos: [2]u32) !void {
  @setRuntimeSafety(false);

  const char: *Char = &buffer.chars[index];
  const len = char.pos.len;

  if (char.capacity <= len) {
    const new = try buffer.allocator.alloc([2]u32, char.capacity * 2);

    copy([2]u32, char.pos, new);
    buffer.allocator.free(char.pos);

    char.capacity = @intCast(new.len);
    char.pos.ptr = new.ptr;
  }

  char.pos[len] = pos;
  char.pos.len += 1;
}

fn chars_update(
  core: *Wayland,
) !void {
  @setRuntimeSafety(false);

  const buffer: *Buffer = &core.buffers[core.buffer_index];
  reset_chars(buffer);

  const y_max = buffer.offset[1] + core.rows;
  const line_max = math.min(y_max, buffer.line_count);

  for (buffer.offset[1]..line_max) |i| {
    if (buffer.lines[i].char_count <= buffer.offset[0]) continue;

    const x_max = buffer.offset[0] + core.cols;
    const col_max = math.min(x_max, buffer.lines[i].char_count);

    for (buffer.offset[0]..col_max) |j| {
      const index = buffer.lines[i].content[j] - 32;
      if (index == 0) continue;

      const position: [2]u32 = .{ @intCast(j - buffer.offset[0]), @intCast(i - buffer.offset[1]) };
      try push_char(buffer, index, position);
    }
  }

  buffer.chars_update = true;
}

fn check_col_offset(buffer: *Buffer, cols: u32) bool {
  const last_index = cols - 1;
  var flag = false;

  if (last_index + buffer.offset[0] < buffer.cursor.x) {
    buffer.offset[0] = buffer.cursor.x - last_index;
    flag = true;
  } else if (buffer.cursor.x < buffer.offset[0]) {
    buffer.offset[0] = buffer.cursor.x;
    flag = true;
  }

  return flag;
}

fn check_row_offset(buffer: *Buffer, rows: u32) bool {
  const last_index = rows - 1;
  var flag = false;

  if (last_index + buffer.offset[1] < buffer.cursor.y) {
    buffer.offset[1] = buffer.cursor.y - last_index;

    flag = true;
  } else if (buffer.cursor.y < buffer.offset[1]) {
    buffer.offset[1] = buffer.cursor.y;

    flag = true;
  }

  return flag;
}

fn new_line(core: *Wayland) !void {
  const buffer = &core.buffers[core.buffer_index];
  buffer.cursor.y += 1;

  const len = buffer.lines.len;
  if (len <= buffer.line_count) {
    const new = try buffer.allocator.alloc(Line, len * 2);

    copy(Line, buffer.lines[0..buffer.cursor.y], new[0..buffer.cursor.y]);
    copy(Line, buffer.lines[buffer.cursor.y..], new[buffer.cursor.y + 1..]);

    buffer.allocator.free(buffer.lines);
    buffer.lines.ptr = new.ptr;
    buffer.lines.len = new.len;
  } else {
    const ii = buffer.line_count - buffer.cursor.y;

    for (0..ii) |i| {
      buffer.lines[buffer.line_count - i].content.ptr = buffer.lines[buffer.line_count - 1 - i].content.ptr;
      buffer.lines[buffer.line_count - i].content.len = buffer.lines[buffer.line_count - 1 - i].content.len;
      buffer.lines[buffer.line_count - i].char_count = buffer.lines[buffer.line_count - 1 - i].char_count;
    }
  }

  const previous_line = &buffer.lines[buffer.cursor.y - 1];
  const current_line = &buffer.lines[buffer.cursor.y];
  const count = math.max(50, previous_line.char_count - buffer.cursor.x);

  current_line.char_count = previous_line.char_count - buffer.cursor.x;
  current_line.content = try buffer.allocator.alloc(u8, count);

  for (buffer.cursor.x..previous_line.char_count) |i| {
    current_line.content[i - buffer.cursor.x] = previous_line.content[i];
  }

  previous_line.char_count = buffer.cursor.x;

  buffer.line_count += 1;
  buffer.cursor.x = 0;

  _ = check_row_offset(buffer, core.rows);
  buffer.offset[0] = 0;
  try chars_update(core);
}

const TAB: u32 = 2;
fn tab(core: *Wayland) !void {
  const buffer = &core.buffers[core.buffer_index];
  const line = &buffer.lines[buffer.cursor.y];
  const len = line.content.len;

  if (len <= line.char_count) {
    const new = try buffer.allocator.alloc(u8, len * 2);
    copy(u8, line.content, new[TAB..]);

    buffer.allocator.free(line.content);
    line.content.ptr = new.ptr;
    line.content.len = new.len;
  } else {
    for (0..line.char_count) |i| {
      line.content[line.char_count + TAB - 1 - i] = line.content[line.char_count - i - 1];
    }
  }

  for (0..TAB) |i| {
    line.content[i] = ' ';
  }

  buffer.cursor.x += TAB;
  line.char_count += TAB;
  _ = check_col_offset(buffer, core.cols);
  try chars_update(core);
}

fn new_char(core: *Wayland) !void {
  const buffer = &core.buffers[core.buffer_index];
  const line = &buffer.lines[buffer.cursor.y];
  const len = line.content.len;

  if (len <= line.char_count) {
    const new = try buffer.allocator.alloc(u8, len * 2);

    copy(u8, line.content[0..buffer.cursor.x], new[0..buffer.cursor.x]);
    copy(u8, line.content[buffer.cursor.x..], new[buffer.cursor.x + 1..]);

    buffer.allocator.free(line.content);
    line.content.ptr = new.ptr;
    line.content.len = new.len;
  } else {
    for (buffer.cursor.x..line.char_count) |i| {
      line.content[line.char_count - i] = line.content[line.char_count - i - 1];
    }
  }

  line.content[buffer.cursor.x] = core.last_char;

  line.char_count += 1;
  buffer.cursor.x += 1;
  _ = check_col_offset(buffer, core.cols);
  try chars_update(core);
}

fn next_line(core: *Wayland) !void {
  const buffer = &core.buffers[core.buffer_index];

  if (buffer.cursor.y + 1 < buffer.line_count) {
    buffer.cursor.y += 1;

    if (buffer.lines[buffer.cursor.y].char_count < buffer.cursor.x) {
      buffer.cursor.x = buffer.lines[buffer.cursor.y].char_count;
    }

    if (check_col_offset(buffer, core.cols) or check_row_offset(buffer, core.rows)) {
      try chars_update(core);
    }
  }
}

fn prev_line(core: *Wayland) !void {
  const buffer = &core.buffers[core.buffer_index];

  if (buffer.cursor.y > 0) {
    buffer.cursor.y -= 1;

    if (buffer.lines[buffer.cursor.y].char_count < buffer.cursor.x) {
      buffer.cursor.x = buffer.lines[buffer.cursor.y].char_count;
    }

    if (check_col_offset(buffer, core.cols) or check_row_offset(buffer, core.rows)) {
      try chars_update(core);
    }
  }
}

fn line_start(core: *Wayland) !void {
  const buffer = &core.buffers[core.buffer_index];

  buffer.cursor.x = 0;

  if (check_col_offset(buffer, core.cols)) {
    try chars_update(core);
  }
}

fn line_end(core: *Wayland) !void {
  const buffer = &core.buffers[core.buffer_index];

  buffer.cursor.x = buffer.lines[buffer.cursor.y].char_count;

  if (check_col_offset(buffer, core.cols)) {
    try chars_update(core);
  }
}

fn key_pressed(core: *Wayland, key: u32) !void {
  const start = try std.time.Instant.now();

  const tuple = try try_ascci(key);
  const char = if (core.shift) tuple[1] else tuple[0];

  if (core.control) {
    switch (char) {
      'n' => try next_line(core),
      'p' => try prev_line(core),
      'a' => try line_start(core),
      'e' => try line_end(core),
      else => return,
    }
  } else {
    switch (char) {
      '\n' => try new_line(core),
      '\t' => try tab(core),

      else => {
        core.last_char = char;
        try new_char(core);
      },
    }
  }

  core.update = true;

  const end = try std.time.Instant.now();
  std.debug.print("time elapsed: {} ns\n", .{end.since(start)});
}

fn print(core: *const Wayland) void {
  const buffer = &core.buffers[core.buffer_index];

  for (0..buffer.line_count) |i| {
    const line = &buffer.lines[i];
    std.debug.print("{d}\n", .{line.content[0..line.char_count]});
  }
}

pub fn init(
  width: u32,
  height: u32,
  font_scale: f32,
  font_ratio: f32,
  allocator: Allocator
) !*Wayland {
  const core = try allocator.create(Wayland);

  core.buffers = try allocator.alloc(Buffer, 1);
  core.last_char = ' ';
  core.buffers[0] = try buffer_init(allocator);
  core.scale = math.divide(height, width);
  core.width = width;
  core.height = height;
  core.font_ratio = font_ratio;
  core.font_scale = font_scale;
  core.rows = @intFromFloat(1.0 / core.font_scale);
  core.cols = @intFromFloat(1.0 / (core.scale * core.font_ratio * core.font_scale));
  core.key_delay = 200;
  core.key_rate = 20;
  core.buffer_index = 0;
  core.running = true;
  core.update = true;

  core.seat_listener = c.wl_seat_listener {
    .name = seat_name,
    .capabilities = seat_capabilities,
  };

  core.shell_listener = c.xdg_wm_base_listener {
    .ping = shell_ping,
  };

  core.shell_surface_listener = c.xdg_surface_listener {
    .configure = shell_surface_configure,
  };

  core.xdg_toplevel_listener = c.xdg_toplevel_listener {
    .configure = toplevel_configure,
    .close = toplevel_close,
  };

  core.registry_listener = c.wl_registry_listener {
    .global = global_listener,
    .global_remove = global_remove_listener,
  };

  core.keyboard_listener = c.wl_keyboard_listener {
    .keymap = keyboard_keymap,
    .enter = keyboard_enter,
    .leave = keyboard_leave,
    .key = keyboard_key,
    .modifiers = keyboard_modifiers,
    .repeat_info = keyboard_repeat_info,
  };

  core.display = c.wl_display_connect(null) orelse return error.DisplayConnect;
  core.registry = c.wl_display_get_registry(core.display) orelse return error.RegistryGet;
  _ = c.wl_registry_add_listener(core.registry, &core.registry_listener, core);

  _ = c.wl_display_roundtrip(core.display);

  core.surface = c.wl_compositor_create_surface(core.compositor) orelse return error.SurfaceCreate;
  _ = c.xdg_wm_base_add_listener(core.xdg_shell, &core.shell_listener, core);

  core.xdg_surface = c.xdg_wm_base_get_xdg_surface(core.xdg_shell, core.surface) orelse return error.XdgSurfaceGet;
  _ = c.xdg_surface_add_listener(core.xdg_surface, &core.shell_surface_listener, core);

  core.xdg_toplevel = c.xdg_surface_get_toplevel(core.xdg_surface) orelse return error.XdgToplevelGet;
  _ = c.xdg_toplevel_add_listener(core.xdg_toplevel, &core.xdg_toplevel_listener, core);

  _ = c.wl_seat_add_listener(core.seat, &core.seat_listener, core);

  c.wl_surface_commit(core.surface);
  _ = c.wl_display_roundtrip(core.display);

  return core;
}

pub fn update_surface(core: *Wayland) void {
  c.wl_surface_commit(core.surface);
  core.update = false;
  core.buffers[core.buffer_index].chars_update = false;
}

pub fn get_events(core: *const Wayland) void {
  _ = c.wl_display_roundtrip(core.display);
}

pub fn deinit(core: *const Wayland) void {
  c.wl_keyboard_release(core.keyboard);
  c.xdg_toplevel_destroy(core.xdg_toplevel);
  c.xdg_surface_destroy(core.xdg_surface);
  c.xdg_wm_base_destroy(core.xdg_shell);
  c.wl_surface_destroy(core.surface);
  c.wl_compositor_destroy(core.compositor);
  c.wl_registry_destroy(core.registry);
  c.wl_display_disconnect(core.display);

  for (core.buffers) |*buffer| {
    buffer_deinit(buffer);
  }

  core.buffers[core.buffer_index].allocator.destroy(core);
}

fn buffer_deinit(buffer: *Buffer) void {
  for (0..CHAR_COUNT) |i| {
    const char = &buffer.chars[i];

    char.pos.len = char.capacity;
    buffer.allocator.free(char.pos);
  }

  for (0..buffer.line_count) |i| {
    buffer.allocator.free(buffer.lines[i].content);
  }

  buffer.allocator.free(buffer.lines);
}

fn global_remove_listener(_: ?*anyopaque, _: ?*c.wl_registry, _: u32) callconv(.C) void {}
fn global_listener(data: ?*anyopaque, registry: ?*c.wl_registry, name: u32, interface: [*c]const u8, _: u32) callconv(.C) void {
  const core: *Wayland = @ptrCast(@alignCast(data));
  const interface_name = std.mem.span(interface);

  if (std.mem.eql(u8, interface_name, std.mem.span(c.wl_compositor_interface.name))) {
    const compositor = c.wl_registry_bind(registry, name, &c.wl_compositor_interface, 4) orelse return;
    core.compositor = @ptrCast(@alignCast(compositor));
  } else if (std.mem.eql(u8, interface_name, std.mem.span(c.xdg_wm_base_interface.name))) {
    const shell = c.wl_registry_bind(registry, name, &c.xdg_wm_base_interface, 1) orelse return;
    core.xdg_shell = @ptrCast(@alignCast(shell));
  } else if (std.mem.eql(u8, interface_name, std.mem.span(c.wl_seat_interface.name))) {
    const seat = c.wl_registry_bind(registry, name, &c.wl_seat_interface, 4) orelse return;
    core.seat = @ptrCast(@alignCast(seat));
  }
}

fn seat_name(_: ?*anyopaque, _: ?*c.wl_seat, _: [*c]const u8) callconv(.C) void {}
fn seat_capabilities(data: ?*anyopaque, seat: ?*c.wl_seat, cap: u32) callconv(.C) void {
  const core: *Wayland = @ptrCast(@alignCast(data));

  if (cap != 0 and c.WL_SEAT_CAPABILITY_KEYBOARD != 0) {
    core.keyboard = c.wl_seat_get_keyboard(seat) orelse return;
    _ = c.wl_keyboard_add_listener(core.keyboard, &core.keyboard_listener, core);
  }
}

fn shell_ping(_: ?*anyopaque, surface: ?*c.xdg_wm_base, serial: u32) callconv(.C) void {
  c.xdg_wm_base_pong(surface, serial);
}

fn shell_surface_configure(_: ?*anyopaque, shell_surface: ?*c.xdg_surface, serial: u32) callconv(.C) void {
  c.xdg_surface_ack_configure(shell_surface, serial);
}

fn toplevel_configure(data: ?*anyopaque, _: ?*c.xdg_toplevel, width: i32, height: i32, _: ?*c.wl_array) callconv(.C) void {
  const core: *Wayland = @ptrCast(@alignCast(data));

  if (width > 0 and height > 0) {
    core.resize = true;
    core.width = @intCast(width);
    core.height = @intCast(height);

    core.scale = math.divide(core.height, core.width);
    core.rows = @intFromFloat(1.0 / core.font_scale);
    core.cols = @intFromFloat(1.0 / (core.scale * core.font_ratio * core.font_scale));
  }
}

fn toplevel_close(data: ?*anyopaque, _: ?*c.xdg_toplevel) callconv(.C) void {
  const core: *Wayland = @ptrCast(@alignCast(data));
  core.running = false;
}

fn keyboard_keymap(_: ?*anyopaque, _: ?*c.wl_keyboard, _: u32, _: i32, _: u32) callconv(.C) void {}
fn keyboard_enter(_: ?*anyopaque, _: ?*c.wl_keyboard, _: u32, _: ?*c.wl_surface, _: ?*c.wl_array) callconv(.C) void {}
fn keyboard_leave(_: ?*anyopaque, _: ?*c.wl_keyboard, _: u32, _: ?*c.wl_surface) callconv(.C) void {}
fn keyboard_key(data: ?*anyopaque, _: ?*c.wl_keyboard, _: u32, _: u32, id: u32, state: u32) callconv(.C) void {
  const core: *Wayland = @ptrCast(@alignCast(data));

  if (state == 1) key_pressed(core, id) catch return;
}

const SHIFT_BIT: u32 = 0x01;
const CAPSLOCK_BIT: u32 = 0x02;
const CONTROL_BIT: u32 = 0x04;
const ALT_BIT: u32 = 0x08;

fn keyboard_modifiers(data: ?*anyopaque, _: ?*c.wl_keyboard, _: u32, depressed: u32, _: u32, locked: u32, _: u32) callconv(.C) void {
  const core: *Wayland = @ptrCast(@alignCast(data));
  const pressed = depressed | locked;

  core.control = pressed & CONTROL_BIT > 0;
  core.shift = pressed & (SHIFT_BIT | CAPSLOCK_BIT) > 0;
  core.alt = pressed & ALT_BIT > 0;
}

fn keyboard_repeat_info(data: ?*anyopaque, _: ?*c.wl_keyboard, rate: i32, delay: i32) callconv(.C) void {
  const core: *Wayland = @ptrCast(@alignCast(data));

  core.key_delay = @intCast(delay);
  core.key_rate = @intCast(rate);
}

fn try_ascci(u: u32) ![2]u8 {
  const ascci: [2]u8 = switch (u) {
    2 => .{ '1', '!' },
    3 => .{ '2', '@' },
    4 => .{ '3', '#' },
    5 => .{ '4', '$' },
    6 => .{ '5', '%' },
    7 => .{ '6', '^' },
    8 => .{ '7', '&' },
    9 => .{ '8', '*' },
    10 => .{ '9', '(' },
    11 => .{ '0', ')' },
    12 => .{ '-', '_' },
    13 => .{ '=', '+' },
    15 => .{ '\t', '\t' },

    16 => .{ 'q', 'Q' },
    17 => .{ 'w', 'W' },
    18 => .{ 'e', 'E' },
    19 => .{ 'r', 'R' },
    20 => .{ 't', 'T' },
    21 => .{ 'y', 'Y' },
    22 => .{ 'u', 'U' },
    23 => .{ 'i', 'I' },
    24 => .{ 'o', 'O' },
    25 => .{ 'p', 'P' },

    26 => .{ '[', '{' },
    27 => .{ ']', '}' },
    28 => .{ '\n', '\n' },

    30 => .{ 'a', 'A' },
    31 => .{ 's', 'S' },
    32 => .{ 'd', 'D' },
    33 => .{ 'f', 'F' },
    34 => .{ 'g', 'G' },
    35 => .{ 'h', 'H' },
    36 => .{ 'j', 'J' },
    37 => .{ 'k', 'K' },
    38 => .{ 'l', 'L' },

    39 => .{ ';', ':' },
    40 => .{ '\'', '"' },

    43 => .{ '\\', '|' },

    44 => .{ 'z', 'Z' },
    45 => .{ 'x', 'X' },
    46 => .{ 'c', 'C' },
    47 => .{ 'v', 'V' },
    48 => .{ 'b', 'B' },
    49 => .{ 'n', 'N' },
    50 => .{ 'm', 'M' },

    51 => .{ ',', '<' },
    52 => .{ '.', '>' },
    53 => .{ '/', '?' },

    57 => .{ ' ', ' ' },

    else => return error.NotAscci,
  };

  return ascci;
}
