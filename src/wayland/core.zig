const std = @import("std");
const c = @import("../bind.zig").c;

const math = @import("../math.zig");
const buffer = @import("buffer.zig");
const C = @import("c.zig");
const mode_line = @import("mode_line.zig");
const util = @import("util.zig");
const command = @import("command.zig");
const highlight = @import("highlight.zig");

const Allocator = std.mem.Allocator;
const Instant = std.time.Instant;
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

    buffers: []buffer.Buffer,
    buffer_count: u32,
    chars: [CHAR_COUNT] Char,
    mode_line: mode_line.ModeLine,
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

    key_delay: u64,
    key_rate: u64,

    last_fetch_delay: Instant,
    last_fetch_rate: Instant,

    width: u32,
    height: u32,

    last_fn: ?*const fn(*Wayland) anyerror!void,
    allocator: Allocator,
};

const Char = struct {
    pos: [][5]u32,
    capacity: u32,
};

pub inline fn get_cursor_position(core: *const Wayland) [2]u32 {
    const buff = &core.buffers[core.buffer_index];

    if (core.mode_line.mode == .Command) {
        return .{ buff.cursor.x + buff.offset[0], buff.cursor.y + buff.offset[1] };
    }

    return .{ buff.cursor.x , buff.cursor.y };
}

pub inline fn is_selection_active(core: *const Wayland) bool {
    const buff = &core.buffers[core.buffer_index];

    return buff.selection_active;
}

pub inline fn get_selection_boundary(core: *const Wayland) [2]buffer.Cursor {
    const buff = &core.buffers[core.buffer_index];

    if (buff.cursor.y == buff.selection.y) {
        if (buff.cursor.x < buff.selection.x) {
            return .{ buff.cursor, buff.selection };
        }

        return .{ buff.selection, buff.cursor };
    }

    if (buff.cursor.y < buff.selection.y) {
        return .{ buff.cursor, buff.selection };
    }

    return .{ buff.selection, buff.cursor };

    // const end: [2]u32 = .{ buff.cursor.x + buff.selection.x - start[0], buff.cursor.y + buff.selection.y - start[1] };

    // return .{
    //     start[0],
    //     start[1],
    //     end[0],
    //     end[1],
    // };
}

pub inline fn get_selected_lines(core: *const Wayland) []buffer.Line {
    const buff = &core.buffers[core.buffer_index];

    return buff.lines;
}

pub inline fn get_positions(core: *const Wayland, index: usize) [][5]u32 {
    return core.chars[index].pos;
}

pub inline fn get_offset(core: *const Wayland) [2]u32 {
    const buff = &core.buffers[core.buffer_index];

    return buff.offset;
}

inline fn reset_chars(core: *Wayland) void {
    for (0..CHAR_COUNT) |i| {
        core.chars[i].pos.len = 0;
    }
}

pub inline fn push_char(core: *Wayland, index: u32, pos: [2]u32, color: [3]u32) !void {
    @setRuntimeSafety(false);

    const char: *Char = &core.chars[index];
    const len = char.pos.len;

    if (char.capacity <= len) {
        const new = try core.allocator.alloc([5]u32, char.capacity * 2);

        util.copy([5]u32, char.pos, new);
        core.allocator.free(char.pos);

        char.capacity = @intCast(new.len);
        char.pos.ptr = new.ptr;
    }

    char.pos.len += 1;
    char.pos[len] = . {
        pos[0], pos[1],
        color[0], color[1], color[2]
    };
}

pub fn chars_update(
    core: *Wayland,
) !void {
    @setRuntimeSafety(false);

    const buf: *buffer.Buffer = &core.buffers[core.buffer_index];
    reset_chars(core);

    const y_max = buf.offset[1] + core.rows - 1;
    const line_max = math.min(y_max, buf.line_count);

    for (buf.offset[1]..line_max) |i| {
        if (buf.lines[i].char_count <= buf.offset[0]) continue;

        const x_max = buf.offset[0] + core.cols - 1;
        const col_max = math.min(x_max, buf.lines[i].char_count);

        for (buf.offset[0]..col_max) |j| {
            const index = buf.lines[i].content[j] - 32;
            if (index == 0) continue;

            const position: [2]u32 = .{ @intCast(j - buf.offset[0]), @intCast(i - buf.offset[1]) };
            try push_char(core, index, position, .{ 255, 255, 255 });
        }
    }

    try mode_line.update_mode_line(core);

    core.update = true;
}

pub fn key_pressed(core: *Wayland, key: u32) !void {
    const start = try Instant.now();

    const tuple = try C.try_ascci(key);
    const char = if (core.shift) tuple[1] else tuple[0];

    if (core.control) {
        switch (char) {
            'n' => core.last_fn = buffer.next_line,
            'p' => core.last_fn = buffer.prev_line,
            'a' => core.last_fn = buffer.line_start,
            'e' => core.last_fn = buffer.line_end,
            'd' => core.last_fn = buffer.delete_selection,
            'f' => core.last_fn = buffer.next_char,
            'b' => core.last_fn = buffer.prev_char,
            'v' => core.last_fn = buffer.scroll_down,
            ' ' => core.last_fn = buffer.selection_mode,
            '>' => core.last_fn = buffer.tab,
            '<' => core.last_fn = buffer.back_tab,
            else => return,
        }
    } else if (core.alt) {
        switch (char) {
            'x' => core.last_fn = command.command_mode,
            'v' => core.last_fn = buffer.scroll_up,
            'f' => core.last_fn = buffer.next_word,
            'b' => core.last_fn = buffer.prev_word,
            else => return,
        }
    } else {
        switch (char) {
            '\n' => core.last_fn = buffer.enter,
            '\t' => core.last_fn = buffer.tab,

            else => {
                core.last_char = char;
                core.last_fn = buffer.new_char;
            },
        }
    }

    if (core.last_fn) |f| {
        f(core) catch |e| {
            core.last_fn = null;
            return e;
        };
    }

    core.last_fetch_delay = try Instant.now();
    std.debug.print("time elapsed: {} ns\n", .{core.last_fetch_delay.since(start)});
}

pub fn init(
    width: u32,
    height: u32,
    font_scale: f32,
    font_ratio: f32,
    allocator: Allocator
) !*Wayland {
    const core = try allocator.create(Wayland);

    core.buffers = try allocator.alloc(buffer.Buffer, 2);
    core.last_char = ' ';
    try buffer.buffer_init(&core.buffers[0], allocator);
    core.buffer_count = 1;
    core.mode_line = try mode_line.mode_line_init(allocator);
    core.scale = math.divide(height, width);
    core.width = width;
    core.height = height;
    core.font_ratio = font_ratio;
    core.font_scale = font_scale;
    core.rows = @intFromFloat(1.0 / core.font_scale);
    core.cols = @intFromFloat(1.0 / (core.scale * core.font_ratio * core.font_scale));
    core.key_delay = 200 * 1000 * 1000;
    core.key_rate = 20 * 1000 * 1000;
    core.buffer_index = 0;
    core.running = true;
    core.update = true;
    core.last_fn = null;
    core.last_fetch_delay = try Instant.now();
    core.last_fetch_rate = try Instant.now();
    core.allocator = allocator;

    for (0..CHAR_COUNT) |i| {
        core.chars[i] = .{
            .pos = try allocator.alloc([5]u32, 10),
            .capacity = 10,
        };

        core.chars[i].pos.len = 0;
    }

    core.seat_listener = c.wl_seat_listener {
        .name = C.seat_name,
        .capabilities = C.seat_capabilities,
    };

    core.shell_listener = c.xdg_wm_base_listener {
        .ping = C.shell_ping,
    };

    core.shell_surface_listener = c.xdg_surface_listener {
        .configure = C.shell_surface_configure,
    };

    core.xdg_toplevel_listener = c.xdg_toplevel_listener {
        .configure = C.toplevel_configure,
        .close = C.toplevel_close,
    };

    core.registry_listener = c.wl_registry_listener {
        .global = C.global_listener,
        .global_remove = C.global_remove_listener,
    };

    core.keyboard_listener = c.wl_keyboard_listener {
        .keymap = C.keyboard_keymap,
        .enter = C.keyboard_enter,
        .leave = C.keyboard_leave,
        .key = C.keyboard_key,
        .modifiers = C.keyboard_modifiers,
        .repeat_info = C.keyboard_repeat_info,
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
}

pub fn get_events(core: *Wayland) void {
    _ = c.wl_display_roundtrip(core.display);

    if (core.last_fn) |f| {
        const now = Instant.now() catch return;
        if (now.since(core.last_fetch_delay) > core.key_delay) {
            if (now.since(core.last_fetch_rate) > core.key_rate) {
                f(core) catch {
                    return;
                };
            }
        }
    }
}

pub fn deinit(core: *Wayland) void {
    c.wl_keyboard_release(core.keyboard);
    c.xdg_toplevel_destroy(core.xdg_toplevel);
    c.xdg_surface_destroy(core.xdg_surface);
    c.xdg_wm_base_destroy(core.xdg_shell);
    c.wl_surface_destroy(core.surface);
    c.wl_compositor_destroy(core.compositor);
    c.wl_registry_destroy(core.registry);
    c.wl_display_disconnect(core.display);

    for (0..CHAR_COUNT) |i| {
        const char = &core.chars[i];

        char.pos.len = char.capacity;
        core.allocator.free(char.pos);
    }

    for (0..core.buffer_count) |k| {
        const buff = &core.buffers[k];
        for (0..buff.line_count) |i| {
            core.allocator.free(buff.lines[i].content);
        }

        core.allocator.free(buff.lines);
        if (buff.highlight.on) {
            highlight.deinit(&buff.highlight);
        }
    }

    core.allocator.free(core.buffers);
    core.allocator.free(core.mode_line.line.content);

    core.allocator.destroy(core);
}
