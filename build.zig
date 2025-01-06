const std = @import("std");

pub fn build(b: *std.Build) void {
    // defaults to building targetting windows with gcc and debug optimization
    // to specify a different target its zig build -Dtarget="new target" for example: zig build -Dtarget="x86_64-windows-msvc" to use msvc instead of gcc
    const target = b.standardTargetOptions(.{ .default_target = .{ .os_tag = .windows, .cpu_arch = .x86_64, .abi = .gnu } });
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .Debug });

    const injectorPath = switch (target.query.os_tag.?) {
        .windows => "src/injector/windows.zig",
        else => "src/injector/windows.zig", //defaults to windows for now
    };

    const injector = b.addExecutable(.{
        .name = "injector",
        .root_source_file = b.path(injectorPath),
        .target = target,
        .optimize = optimize,
    });

    const modloaderPath = switch (target.query.os_tag.?) {
        .windows => "src/modloader/windows-wrapper.zig",
        else => "src/modloader/windows-wrapper.zig", //defaults to windows for now
    };

    const modloader = b.addSharedLibrary(.{
        .name = "modloader",
        .root_source_file = b.path(modloaderPath),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(modloader);
    b.installArtifact(injector);
}
