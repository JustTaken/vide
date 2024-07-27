const std = @import("std");
const c = @import("bind.zig").c;

const math = @import("math.zig");
const util = @import("util.zig");

const Window = @import("window/core.zig").Core(Wayland);
const VkInstanceDispatch = @import("vulkan/instance.zig").Dispatch;

const Allocator = std.mem.Allocator;
const Instant = std.time.Instant;

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

    control: bool,
    alt: bool,
    shift: bool,

    pub fn init(
        window: *Window,
    ) !void {
        window.handle.seat_listener = c.wl_seat_listener {
            .name = seat_name,
            .capabilities = seat_capabilities,
        };

        window.handle.shell_listener = c.xdg_wm_base_listener {
            .ping = shell_ping,
        };

        window.handle.shell_surface_listener = c.xdg_surface_listener {
            .configure = shell_surface_configure,
        };

        window.handle.xdg_toplevel_listener = c.xdg_toplevel_listener {
            .configure = toplevel_configure,
            .close = toplevel_close,
        };

        window.handle.registry_listener = c.wl_registry_listener {
            .global = global_listener,
            .global_remove = global_remove_listener,
        };

        window.handle.keyboard_listener = c.wl_keyboard_listener {
            .keymap = keyboard_keymap,
            .enter = keyboard_enter,
            .leave = keyboard_leave,
            .key = keyboard_key,
            .modifiers = keyboard_modifiers,
            .repeat_info = keyboard_repeat_info,
        };

        const window_ptr: *anyopaque = @ptrCast(window);

        window.handle.display = c.wl_display_connect(null) orelse return error.DisplayConnect;
        window.handle.registry = c.wl_display_get_registry(window.handle.display) orelse return error.RegistryGet;
        _ = c.wl_registry_add_listener(window.handle.registry, &window.handle.registry_listener, window_ptr);

        _ = c.wl_display_roundtrip(window.handle.display);

        window.handle.surface = c.wl_compositor_create_surface(window.handle.compositor) orelse return error.SurfaceCreate;
        _ = c.xdg_wm_base_add_listener(window.handle.xdg_shell, &window.handle.shell_listener, window_ptr);

        window.handle.xdg_surface = c.xdg_wm_base_get_xdg_surface(window.handle.xdg_shell, window.handle.surface) orelse return error.XdgSurfaceGet;
        _ = c.xdg_surface_add_listener(window.handle.xdg_surface, &window.handle.shell_surface_listener, window_ptr);

        window.handle.xdg_toplevel = c.xdg_surface_get_toplevel(window.handle.xdg_surface) orelse return error.XdgToplevelGet;
        _ = c.xdg_toplevel_add_listener(window.handle.xdg_toplevel, &window.handle.xdg_toplevel_listener, window_ptr);

        _ = c.wl_seat_add_listener(window.handle.seat, &window.handle.seat_listener, window_ptr);

        c.wl_surface_commit(window.handle.surface);
        _ = c.wl_display_roundtrip(window.handle.display);
    }

    pub fn get_surface(self: *const Wayland, instance: c.VkInstance, dispatch: *const VkInstanceDispatch) !c.VkSurfaceKHR {
        const vkCreateWaylandSurfaceKHR = @as(c.PFN_vkCreateWaylandSurfaceKHR, @ptrCast(dispatch.vkGetInstanceProcAddr(instance, "vkCreateWaylandSurfaceKHR"))) orelse return error.FunctionNotFound;

        const info = c.VkWaylandSurfaceCreateInfoKHR {
            .sType = c.VK_STRUCTURE_TYPE_WAYLAND_SURFACE_CREATE_INFO_KHR,
            .display = self.display,
            .surface = self.surface,
        };

        var surface: c.VkSurfaceKHR = undefined;

        _ = vkCreateWaylandSurfaceKHR(instance, &info, null, &surface);

        return surface;
    }

    pub fn update_surface(self: *const Wayland) void {
        c.wl_surface_commit(self.surface);
    }

    pub fn get_events(self: *const Wayland) void {
        _ = c.wl_display_roundtrip(self.display);
    }

    pub fn deinit(self: *const Wayland) void {
        c.wl_keyboard_release(self.keyboard);
        c.xdg_toplevel_destroy(self.xdg_toplevel);
        c.xdg_surface_destroy(self.xdg_surface);
        c.xdg_wm_base_destroy(self.xdg_shell);
        c.wl_surface_destroy(self.surface);
        c.wl_compositor_destroy(self.compositor);
        c.wl_registry_destroy(self.registry);
        c.wl_display_disconnect(self.display);
    }
};

fn build_key_string(string: []u8, control: bool, alt: bool, chars: []const u8) u32 {
    var len: u32 = 0;

    if (control) {
        string[0] = 'C';
        string[1] = '-';
        len += 2;
    }

    if (alt) {
        string[len] = 'A';
        string[len + 1] = '-';
        len += 2;
    }

    for (chars) |ch| {
        string[len] = ch;
        len += 1;
    }

    return len;
}

pub fn global_remove_listener(_: ?*anyopaque, _: ?*c.wl_registry, _: u32) callconv(.C) void {}
pub fn global_listener(data: ?*anyopaque, registry: ?*c.wl_registry, name: u32, interface: [*c]const u8, _: u32) callconv(.C) void {
    const window: *Window = @ptrCast(@alignCast(data));
    const core = &window.handle;
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
    const window: *Window = @ptrCast(@alignCast(data));
    const core = &window.handle;

    if (cap != 0 and c.WL_SEAT_CAPABILITY_KEYBOARD != 0) {
        core.keyboard = c.wl_seat_get_keyboard(seat) orelse return;
        _ = c.wl_keyboard_add_listener(core.keyboard, &core.keyboard_listener, window);
    }
}

pub fn shell_ping(_: ?*anyopaque, surface: ?*c.xdg_wm_base, serial: u32) callconv(.C) void {
    c.xdg_wm_base_pong(surface, serial);
}

pub fn shell_surface_configure(_: ?*anyopaque, shell_surface: ?*c.xdg_surface, serial: u32) callconv(.C) void {
    c.xdg_surface_ack_configure(shell_surface, serial);
}

pub fn toplevel_configure(data: ?*anyopaque, _: ?*c.xdg_toplevel, width: i32, height: i32, _: ?*c.wl_array) callconv(.C) void {
    const window: *Window = @ptrCast(@alignCast(data));

    if (width > 0 and height > 0) {
        const w: u32 = @intCast(width);
        const h: u32 = @intCast(height);


        window.resize(w, h);
    }
}

pub fn toplevel_close(data: ?*anyopaque, _: ?*c.xdg_toplevel) callconv(.C) void {
    const window: *Window = @ptrCast(@alignCast(data));
    window.state = .Closing;
}

pub fn keyboard_keymap(_: ?*anyopaque, _: ?*c.wl_keyboard, _: u32, _: i32, _: u32) callconv(.C) void {}
pub fn keyboard_enter(_: ?*anyopaque, _: ?*c.wl_keyboard, _: u32, _: ?*c.wl_surface, _: ?*c.wl_array) callconv(.C) void {}
pub fn keyboard_leave(_: ?*anyopaque, _: ?*c.wl_keyboard, _: u32, _: ?*c.wl_surface) callconv(.C) void {}
pub fn keyboard_key(data: ?*anyopaque, _: ?*c.wl_keyboard, _: u32, _: u32, id: u32, state: u32) callconv(.C) void {
    const window: *Window = @ptrCast(@alignCast(data));

    if (state != 1) {
        window.key_up();
        return;
    }

    const core = &window.handle;
    const string = blk: {
        const tuple = ascci(id) catch null;

        if (tuple) |t| {
            break :blk if (core.shift) t[1] else t[0];
        }

        break :blk special(id) catch return;
    };

    var key_string: [10]u8 = undefined;
    const key_string_len = build_key_string(&key_string, core.control, core.alt, string);

    window.key_input(key_string[0..key_string_len]) catch return;
}

const SHIFT_BIT: u32 = 0x01;
const CAPSLOCK_BIT: u32 = 0x02;
const CONTROL_BIT: u32 = 0x04;
const ALT_BIT: u32 = 0x08;

pub fn keyboard_modifiers(data: ?*anyopaque, _: ?*c.wl_keyboard, _: u32, depressed: u32, _: u32, locked: u32, _: u32) callconv(.C) void {
    const window: *Window = @ptrCast(@alignCast(data));
    const core = &window.handle;
    const pressed = depressed | locked;

    core.control = pressed & CONTROL_BIT > 0;
    core.shift = pressed & (SHIFT_BIT | CAPSLOCK_BIT) > 0;
    core.alt = pressed & ALT_BIT > 0;
}

pub fn keyboard_repeat_info(data: ?*anyopaque, _: ?*c.wl_keyboard, rate: i32, delay: i32) callconv(.C) void {
    const window: *Window = @ptrCast(@alignCast(data));
    const d: u64 = @intCast(delay);
    const r: u64 = @intCast(rate);

    window.delay = d * 1000 * 1000;
    window.rate = r * 1000 * 1000;
}

pub fn ascci(u: u32) ![2][]const u8 {
    return switch (u) {
        2 => .{ "1", "!" },
        3 => .{ "2", "@" },
        4 => .{ "3", "#" },
        5 => .{ "4", "$" },
        6 => .{ "5", "%" },
        7 => .{ "6", "^" },
        8 => .{ "7", "&" },
        9 => .{ "8", "*" },
        10 => .{ "9", "(" },
        11 => .{ "0", ")" },
        12 => .{ "-", "_" },
        13 => .{ "=", "+" },

        16 => .{ "q", "Q" },
        17 => .{ "w", "W" },
        18 => .{ "e", "E" },
        19 => .{ "r", "R" },
        20 => .{ "t", "T" },
        21 => .{ "y", "Y" },
        22 => .{ "u", "U" },
        23 => .{ "i", "I" },
        24 => .{ "o", "O" },
        25 => .{ "p", "P" },

        26 => .{ "[", "{" },
        27 => .{ "]", "}" },

        30 => .{ "a", "A" },
        31 => .{ "s", "S" },
        32 => .{ "d", "D" },
        33 => .{ "f", "F" },
        34 => .{ "g", "G" },
        35 => .{ "h", "H" },
        36 => .{ "j", "J" },
        37 => .{ "k", "K" },
        38 => .{ "l", "L" },

        39 => .{ ";", ":" },
        40 => .{ "\'", "\"" },

        43 => .{ "\\", "|" },

        44 => .{ "z", "Z" },
        45 => .{ "x", "X" },
        46 => .{ "c", "C" },
        47 => .{ "v", "V" },
        48 => .{ "b", "B" },
        49 => .{ "n", "N" },
        50 => .{ "m", "M" },

        51 => .{ ",", "<" },
        52 => .{ ".", ">" },
        53 => .{ "/", "?" },

        else => return error.NotAscci,
    };
}

pub fn special(key: u32) ![]const u8 {
    return switch (key) {
        1 => "Esc",
        14 => "Bsp",
        15 => "Tab",
        28 => "Ret",
        57 => "Spc",
        else => return error.NotSpecial,
    };
}
