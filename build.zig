const std = @import("std");

pub fn build(b: *std.build.Builder) void {

    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("srz", "src/srz.zig");
    exe.single_threaded = true;
    exe.strip = true;
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();
}
