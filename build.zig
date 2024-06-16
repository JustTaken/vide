const std = @import("std");

pub fn build(builder: *std.Build) void {
    const target = builder.standardTargetOptions(.{});
    const optimize = builder.standardOptimizeOption(.{});
    const main = builder.addExecutable(.{
        .name = "vide",
        .root_source_file = builder.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    main.linkSystemLibrary("dl");
    main.linkSystemLibrary("wayland-client");
    main.addCSourceFile(.{ .file = .{ .src_path = .{ .owner = builder, .sub_path = "assets/xdg-shell.c" } } });
    main.addIncludePath(.{ .src_path = .{ .owner = builder, .sub_path = "include" } });

    builder.installArtifact(main);

    const run_cmd = builder.addRunArtifact(main);
    run_cmd.step.dependOn(builder.getInstallStep());

    const run_step = builder.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = builder.addTest(.{
        .root_source_file = builder.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = builder.addRunArtifact(exe_unit_tests);
    const test_step = builder.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
