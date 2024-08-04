const std = @import("std");

pub const c = @cImport({
    @cInclude("wayland-client.h");
    @cInclude("xdg-shell.h");
    @cInclude("protocol.h");
});

const util = @import("util");
const math = util.math;

const Allocator = std.mem.Allocator;
const Window = @import("window/core.zig").Core(Wayland);
const VkInstance = @import("vulkan").instance.Instance;

var libwaylandclient: LibWaylandClient = undefined;

export fn wl_proxy_add_listener(
    proxy: ?*c.struct_wl_proxy,
    implementation: [*c]?*const fn () callconv(.C) void,
    data: ?*anyopaque,
) c_int {
    return @call(
        .always_tail,
        libwaylandclient.wl_proxy_add_listener,
        .{ proxy, implementation, data },
    );
}

export fn wl_proxy_get_version(proxy: ?*c.struct_wl_proxy) u32 {
    return @call(
        .always_tail,
        libwaylandclient.wl_proxy_get_version,
        .{proxy},
    );
}

export fn wl_proxy_marshal_flags(
    proxy: ?*c.struct_wl_proxy,
    opcode: u32,
    interface: [*c]const c.struct_wl_interface,
    version: u32,
    flags: u32,
    ...,
) ?*c.struct_wl_proxy {
    var arg_list: std.builtin.VaList = @cVaStart();
    defer @cVaEnd(&arg_list);

    return @call(
        .always_tail,
        libwaylandclient.wl_proxy_marshal_flags,
        .{ proxy, opcode, interface, version, flags, arg_list },
    );
}

export fn wl_proxy_destroy(proxy: ?*c.struct_wl_proxy) void {
    return @call(.always_tail, libwaylandclient.wl_proxy_destroy, .{proxy});
}

const LibWaylandClient = struct {
    handle: std.DynLib,

    wl_display_connect: *const @TypeOf(c.wl_display_connect),
    wl_proxy_add_listener: *const @TypeOf(c.wl_proxy_add_listener),
    wl_proxy_get_version: *const @TypeOf(c.wl_proxy_get_version),
    wl_proxy_marshal_flags: *const @TypeOf(c.wl_proxy_marshal_flags),
    wl_display_roundtrip: *const @TypeOf(c.wl_display_roundtrip),
    wl_display_dispatch: *const @TypeOf(c.wl_display_dispatch),
    wl_display_disconnect: *const @TypeOf(c.wl_display_disconnect),
    wl_proxy_destroy: *const @TypeOf(c.wl_proxy_destroy),

    wl_compositor_interface: *@TypeOf(c.wl_compositor_interface),
    wl_keyboard_interface: *@TypeOf(c.wl_keyboard_interface),

    wl_buffer_interface: *@TypeOf(c.wl_buffer_interface),
    wl_callback_interface: *@TypeOf(c.wl_callback_interface),
    wl_data_device_interface: *@TypeOf(c.wl_data_device_interface),
    wl_data_offer_interface: *@TypeOf(c.wl_data_offer_interface),
    wl_data_source_interface: *@TypeOf(c.wl_data_source_interface),
    wl_output_interface: *@TypeOf(c.wl_output_interface),
    wl_pointer_interface: *@TypeOf(c.wl_pointer_interface),
    wl_region_interface: *@TypeOf(c.wl_region_interface),
    wl_registry_interface: *@TypeOf(c.wl_registry_interface),
    wl_seat_interface: *@TypeOf(c.wl_seat_interface),
    wl_shell_surface_interface: *@TypeOf(c.wl_shell_surface_interface),
    wl_shm_pool_interface: *@TypeOf(c.wl_shm_pool_interface),
    wl_subsurface_interface: *@TypeOf(c.wl_subsurface_interface),
    wl_surface_interface: *@TypeOf(c.wl_surface_interface),
    wl_touch_interface: *@TypeOf(c.wl_touch_interface),

    pub extern const xdg_wm_base_interface: @TypeOf(c.xdg_wm_base_interface);

    fn init() !LibWaylandClient {
        var self: LibWaylandClient = undefined;
        self.handle = try std.DynLib.open("libwayland-client.so");

        inline for (@typeInfo(LibWaylandClient).Struct.fields[1..]) |field| {
            const name: [:0]const u8 = @ptrCast(
                std.fmt.comptimePrint("{s}\x00", .{field.name}),
            );

            @field(self, field.name) = self.handle.lookup(
                field.type,
                name,
            ) orelse return error.SymbolNoFound;
        }

        return self;
    }

    fn deinit(self: *LibWaylandClient) void {
        self.handle.close();
    }
};

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
        window.handle.seat_listener = c.wl_seat_listener{
            .name = seat_name,
            .capabilities = seat_capabilities,
        };

        window.handle.shell_listener = c.xdg_wm_base_listener{
            .ping = shell_ping,
        };

        window.handle.shell_surface_listener = c.xdg_surface_listener{
            .configure = shell_surface_configure,
        };

        window.handle.xdg_toplevel_listener = c.xdg_toplevel_listener{
            .configure = toplevel_configure,
            .close = toplevel_close,
        };

        window.handle.registry_listener = c.wl_registry_listener{
            .global = global_listener,
            .global_remove = global_remove_listener,
        };

        window.handle.keyboard_listener = c.wl_keyboard_listener{
            .keymap = keyboard_keymap,
            .enter = keyboard_enter,
            .leave = keyboard_leave,
            .key = keyboard_key,
            .modifiers = keyboard_modifiers,
            .repeat_info = keyboard_repeat_info,
        };

        libwaylandclient = try LibWaylandClient.init();

        const window_ptr: *anyopaque = @ptrCast(window);
        window.handle.display = libwaylandclient.wl_display_connect(
            null,
        ) orelse return error.DisplayConnect;

        window.handle.registry = c.wl_display_get_registry(
            window.handle.display,
        ) orelse return error.RegistryGet;

        _ = c.wl_registry_add_listener(
            window.handle.registry,
            &window.handle.registry_listener,
            window_ptr,
        );

        _ = libwaylandclient.wl_display_roundtrip(window.handle.display);

        window.handle.surface = c.wl_compositor_create_surface(
            window.handle.compositor,
        ) orelse return error.SurfaceCreate;

        _ = c.xdg_wm_base_add_listener(
            window.handle.xdg_shell,
            &window.handle.shell_listener,
            window_ptr,
        );

        window.handle.xdg_surface = c.xdg_wm_base_get_xdg_surface(
            window.handle.xdg_shell,
            window.handle.surface,
        ) orelse return error.XdgSurfaceGet;

        _ = c.xdg_surface_add_listener(
            window.handle.xdg_surface,
            &window.handle.shell_surface_listener,
            window_ptr,
        );

        window.handle.xdg_toplevel = c.xdg_surface_get_toplevel(
            window.handle.xdg_surface,
        ) orelse return error.XdgToplevelGet;

        _ = c.xdg_toplevel_add_listener(
            window.handle.xdg_toplevel,
            &window.handle.xdg_toplevel_listener,
            window_ptr,
        );

        _ = c.wl_seat_add_listener(
            window.handle.seat,
            &window.handle.seat_listener,
            window_ptr,
        );

        c.wl_surface_commit(window.handle.surface);
        _ = libwaylandclient.wl_display_roundtrip(window.handle.display);
    }

    pub fn update_surface(self: *const Wayland) void {
        c.wl_surface_commit(self.surface);
    }

    pub fn get_events(self: *const Wayland) void {
        _ = libwaylandclient.wl_display_roundtrip(self.display);
    }

    pub fn deinit(self: *Wayland) void {
        c.wl_keyboard_release(self.keyboard);
        c.xdg_toplevel_destroy(self.xdg_toplevel);
        c.xdg_surface_destroy(self.xdg_surface);
        c.xdg_wm_base_destroy(self.xdg_shell);
        c.wl_surface_destroy(self.surface);
        c.wl_compositor_destroy(self.compositor);
        c.wl_registry_destroy(self.registry);
        libwaylandclient.wl_display_disconnect(self.display);

        libwaylandclient.deinit();
    }
};

fn build_key_string(
    string: []u8,
    control: bool,
    alt: bool,
    chars: []const u8,
) u32 {
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

pub fn global_remove_listener(
    _: ?*anyopaque,
    _: ?*c.wl_registry,
    _: u32,
) callconv(.C) void {}

pub fn global_listener(
    data: ?*anyopaque,
    registry: ?*c.wl_registry,
    name: u32,
    interface: [*c]const u8,
    _: u32,
) callconv(.C) void {
    const window: *Window = @ptrCast(@alignCast(data));
    const core = &window.handle;
    const interface_name = std.mem.span(interface);

    if (std.mem.eql(u8, interface_name, "wl_compositor")) {
        const compositor = c.wl_registry_bind(
            registry,
            name,
            libwaylandclient.wl_compositor_interface,
            4,
        ) orelse return;
        core.compositor = @ptrCast(@alignCast(compositor));
    } else if (std.mem.eql(u8, interface_name, "xdg_wm_base")) {
        const shell = c.wl_registry_bind(
            registry,
            name,
            &LibWaylandClient.xdg_wm_base_interface,
            1,
        ) orelse return;
        core.xdg_shell = @ptrCast(@alignCast(shell));
    } else if (std.mem.eql(u8, interface_name, "wl_seat")) {
        const seat = c.wl_registry_bind(
            registry,
            name,
            libwaylandclient.wl_seat_interface,
            4,
        ) orelse return;
        core.seat = @ptrCast(@alignCast(seat));
    }
}

pub fn seat_name(
    _: ?*anyopaque,
    _: ?*c.wl_seat,
    _: [*c]const u8,
) callconv(.C) void {}
pub fn seat_capabilities(
    data: ?*anyopaque,
    seat: ?*c.wl_seat,
    cap: u32,
) callconv(.C) void {
    const window: *Window = @ptrCast(@alignCast(data));
    const core = &window.handle;

    if (cap != 0 and c.WL_SEAT_CAPABILITY_KEYBOARD != 0) {
        core.keyboard = c.wl_seat_get_keyboard(seat) orelse return;
        _ = c.wl_keyboard_add_listener(
            core.keyboard,
            &core.keyboard_listener,
            window,
        );
    }
}

pub fn shell_ping(
    _: ?*anyopaque,
    surface: ?*c.xdg_wm_base,
    serial: u32,
) callconv(.C) void {
    c.xdg_wm_base_pong(surface, serial);
}

pub fn shell_surface_configure(
    _: ?*anyopaque,
    shell_surface: ?*c.xdg_surface,
    serial: u32,
) callconv(.C) void {
    c.xdg_surface_ack_configure(shell_surface, serial);
}

pub fn toplevel_configure(
    data: ?*anyopaque,
    _: ?*c.xdg_toplevel,
    width: i32,
    height: i32,
    _: ?*c.wl_array,
) callconv(.C) void {
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

pub fn keyboard_keymap(
    _: ?*anyopaque,
    _: ?*c.wl_keyboard,
    _: u32,
    _: i32,
    _: u32,
) callconv(.C) void {}

pub fn keyboard_enter(
    _: ?*anyopaque,
    _: ?*c.wl_keyboard,
    _: u32,
    _: ?*c.wl_surface,
    _: ?*c.wl_array,
) callconv(.C) void {}

pub fn keyboard_leave(
    _: ?*anyopaque,
    _: ?*c.wl_keyboard,
    _: u32,
    _: ?*c.wl_surface,
) callconv(.C) void {}

pub fn keyboard_key(
    data: ?*anyopaque,
    _: ?*c.wl_keyboard,
    _: u32,
    _: u32,
    id: u32,
    state: u32,
) callconv(.C) void {
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
    const key_string_len = build_key_string(
        &key_string,
        core.control,
        core.alt,
        string,
    );

    window.key_input(key_string[0..key_string_len]) catch return;
}

const SHIFT_BIT: u32 = 0x01;
const CAPSLOCK_BIT: u32 = 0x02;
const CONTROL_BIT: u32 = 0x04;
const ALT_BIT: u32 = 0x08;

pub fn keyboard_modifiers(
    data: ?*anyopaque,
    _: ?*c.wl_keyboard,
    _: u32,
    depressed: u32,
    _: u32,
    locked: u32,
    _: u32,
) callconv(.C) void {
    const window: *Window = @ptrCast(@alignCast(data));
    const core = &window.handle;
    const pressed = depressed | locked;

    core.control = pressed & CONTROL_BIT > 0;
    core.shift = pressed & (SHIFT_BIT | CAPSLOCK_BIT) > 0;
    core.alt = pressed & ALT_BIT > 0;
}

pub fn keyboard_repeat_info(
    data: ?*anyopaque,
    _: ?*c.wl_keyboard,
    rate: i32,
    delay: i32,
) callconv(.C) void {
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
