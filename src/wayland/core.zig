const std = @import("std");
const c = @import("../bind.zig").c;

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

    running: bool,
    resize: bool,

    control: bool,
    alt: bool,
    shift: bool,

    key_delay: u32,
    key_rate: u32,

    width: u32,
    height: u32,
    scale: f32,
};

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

        core.scale = division(core.height, core.width);
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
    _ = core;
    _ = id;

    if (state == 1) {
    }
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

fn division(numerator: u32, denumerator: u32) f32 {
    const f_numerator: f32 = @floatFromInt(numerator);
    const f_denumerator: f32 = @floatFromInt(denumerator);

    return f_numerator / f_denumerator;
}

pub fn init(width: u32, height: u32, allocator: std.mem.Allocator) !*Wayland {
    const core = try allocator.create(Wayland);
    core.* = Wayland {
        .display = undefined,
        .registry = undefined,
        .seat = undefined,
        .compositor = undefined,
        .keyboard = undefined,
        .surface = undefined,

        .xdg_shell = undefined,
        .xdg_surface = undefined,
        .xdg_toplevel = undefined,

        .resize = false,
        .running = true,

        .width = width,
        .height = height,
        .scale = division(height, width),

        .key_delay = 200,
        .key_rate = 20,

        .control = false,
        .alt = false,
        .shift = false,

        .seat_listener = c.wl_seat_listener{
            .name = seat_name,
            .capabilities = seat_capabilities,
        },
        .shell_listener = c.xdg_wm_base_listener{
            .ping = shell_ping,
        },
        .shell_surface_listener = c.xdg_surface_listener{
            .configure = shell_surface_configure,
        },
        .xdg_toplevel_listener = c.xdg_toplevel_listener{
            .configure = toplevel_configure,
            .close = toplevel_close,
        },
        .registry_listener = c.wl_registry_listener{
            .global = global_listener,
            .global_remove = global_remove_listener,
        },
        .keyboard_listener = c.wl_keyboard_listener{
            .keymap = keyboard_keymap,
            .enter = keyboard_enter,
            .leave = keyboard_leave,
            .key = keyboard_key,
            .modifiers = keyboard_modifiers,
            .repeat_info = keyboard_repeat_info,
        },
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

pub fn update(core: *const Wayland) void {
    c.wl_surface_commit(core.surface);
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
}
