const std = @import("std");

pub fn build(b: *std.build.Builder) void {

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "srz",
        .root_source_file = .{ .path = "src/srz.zig" },
        .target = target,
        .optimize = optimize,
        .single_threaded = true,
//        .strip = true,
    });

    b.installArtifact(exe);
}
