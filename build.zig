const Builder = @import("std").Build;

pub fn build(builder: *Builder) void {
    const target = builder.standardTargetOptions(.{});
    const optimize = builder.standardOptimizeOption(.{});

    const main = builder.addExecutable(.{
        .name = "vide",
        .root_source_file = builder.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    main.linkLibC();
    main.linkSystemLibrary("freetype");

    scan_wayland_xml(builder, "private-code", "include/xdg-shell.c");
    scan_wayland_xml(builder, "client-header", "include/xdg-shell.h");

    add_shader(builder, "vert");
    add_shader(builder, "frag");

    main.addIncludePath(.{
        .src_path = .{
            .owner = builder,
            .sub_path = "zig-out/include",
        },
    });

    main.addCSourceFile(.{ .file = .{
        .src_path = .{
            .owner = builder,
            .sub_path = "zig-out/include/xdg-shell.c",
        },
    } });

    main.addCSourceFile(.{ .file = .{
        .src_path = .{
            .owner = builder,
            .sub_path = "assets/xdg-shell.c",
        },
    } });

    builder.installArtifact(main);

    const run_cmd = builder.addRunArtifact(main);
    run_cmd.step.dependOn(builder.getInstallStep());

    const run_step = builder.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

fn scan_wayland_xml(
    builder: *Builder,
    flag: []const u8,
    output: []const u8,
) void {
    const scanner = builder.addSystemCommand(&.{"wayland-scanner"});

    scanner.addArgs(&.{ flag, "assets/xdg-shell.xml" });
    const out = scanner.addOutputFileArg(output);

    builder.getInstallStep().dependOn(
        &builder.addInstallFileWithDir(
            out,
            .prefix,
            output,
        ).step,
    );
}

fn add_shader(builder: *Builder, file: []const u8) void {
    const glslc = builder.addSystemCommand(&.{"glslc"});
    const output = builder.fmt("shader/{s}.spv", .{file});

    glslc.addArgs(&.{
        builder.fmt(
            "assets/shader/shader.{s}",
            .{file},
        ),
        "-o",
    });

    const out = glslc.addOutputFileArg(output);
    builder.getInstallStep().dependOn(
        &builder.addInstallFileWithDir(
            out,
            .prefix,
            output,
        ).step,
    );
}
