const std = @import("std");
const c = @import("../bind.zig").c;
const math = @import("../math.zig");
const wayland = @import("core.zig");
const Wayland = wayland.Wayland;

pub fn global_remove_listener(_: ?*anyopaque, _: ?*c.wl_registry, _: u32) callconv(.C) void {}
pub fn global_listener(data: ?*anyopaque, registry: ?*c.wl_registry, name: u32, interface: [*c]const u8, _: u32) callconv(.C) void {
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

pub fn seat_name(_: ?*anyopaque, _: ?*c.wl_seat, _: [*c]const u8) callconv(.C) void {}
pub fn seat_capabilities(data: ?*anyopaque, seat: ?*c.wl_seat, cap: u32) callconv(.C) void {
    const core: *Wayland = @ptrCast(@alignCast(data));

    if (cap != 0 and c.WL_SEAT_CAPABILITY_KEYBOARD != 0) {
        core.keyboard = c.wl_seat_get_keyboard(seat) orelse return;
        _ = c.wl_keyboard_add_listener(core.keyboard, &core.keyboard_listener, core);
    }
}

pub fn shell_ping(_: ?*anyopaque, surface: ?*c.xdg_wm_base, serial: u32) callconv(.C) void {
    c.xdg_wm_base_pong(surface, serial);
}

pub fn shell_surface_configure(_: ?*anyopaque, shell_surface: ?*c.xdg_surface, serial: u32) callconv(.C) void {
    c.xdg_surface_ack_configure(shell_surface, serial);
}

pub fn toplevel_configure(data: ?*anyopaque, _: ?*c.xdg_toplevel, width: i32, height: i32, _: ?*c.wl_array) callconv(.C) void {
    const core: *Wayland = @ptrCast(@alignCast(data));

    if (width > 0 and height > 0) {
        if (width == core.width and height == core.height) return;

        core.resize = true;
        core.width = @intCast(width);
        core.height = @intCast(height);

        core.scale = math.divide(core.height, core.width);
        core.rows = @intFromFloat(1.0 / core.font_scale);
        core.cols = @intFromFloat(1.0 / (core.scale * core.font_ratio * core.font_scale));

        wayland.chars_update(core) catch return;
    }
}

pub fn toplevel_close(data: ?*anyopaque, _: ?*c.xdg_toplevel) callconv(.C) void {
    const core: *Wayland = @ptrCast(@alignCast(data));
    core.running = false;
}

pub fn keyboard_keymap(_: ?*anyopaque, _: ?*c.wl_keyboard, _: u32, _: i32, _: u32) callconv(.C) void {}
pub fn keyboard_enter(_: ?*anyopaque, _: ?*c.wl_keyboard, _: u32, _: ?*c.wl_surface, _: ?*c.wl_array) callconv(.C) void {}
pub fn keyboard_leave(_: ?*anyopaque, _: ?*c.wl_keyboard, _: u32, _: ?*c.wl_surface) callconv(.C) void {}
pub fn keyboard_key(data: ?*anyopaque, _: ?*c.wl_keyboard, _: u32, _: u32, id: u32, state: u32) callconv(.C) void {
    const core: *Wayland = @ptrCast(@alignCast(data));

    core.last_fn = null;
    if (state == 1) wayland.key_pressed(core, id) catch return;
}

const SHIFT_BIT: u32 = 0x01;
const CAPSLOCK_BIT: u32 = 0x02;
const CONTROL_BIT: u32 = 0x04;
const ALT_BIT: u32 = 0x08;

pub fn keyboard_modifiers(data: ?*anyopaque, _: ?*c.wl_keyboard, _: u32, depressed: u32, _: u32, locked: u32, _: u32) callconv(.C) void {
    const core: *Wayland = @ptrCast(@alignCast(data));
    const pressed = depressed | locked;

    core.control = pressed & CONTROL_BIT > 0;
    core.shift = pressed & (SHIFT_BIT | CAPSLOCK_BIT) > 0;
    core.alt = pressed & ALT_BIT > 0;
}

pub fn keyboard_repeat_info(data: ?*anyopaque, _: ?*c.wl_keyboard, rate: i32, delay: i32) callconv(.C) void {
    const core: *Wayland = @ptrCast(@alignCast(data));
    const d: u64 = @intCast(delay);
    const r: u64 = @intCast(rate);

    core.key_delay = d * 1000 * 1000;
    core.key_rate = r * 1000 * 1000;
}

pub fn try_ascci(u: u32) ![2]u8 {
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
