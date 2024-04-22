
const std = @import("std");
const os = std.os;
const mem = std.mem;
const Allocator = mem.Allocator;

const packer = @import("packer.zig");

fn help(prog: []const u8) void {
    std.debug.print("  to compress: {s} c < file > file.srz\n", .{prog});
    std.debug.print("           or: prog | {s} c > file.srz\n", .{prog});
    std.debug.print("to decompress: {s} d < file.srz > file\n", .{prog});
}

pub fn main() !void {

    const prog = mem.sliceTo(os.argv[0], 0);

    if (os.argv.len != 2) {
        help(prog);
        return;
    }

    const mode = mem.sliceTo(os.argv[1], 0);
    if ((mode.len != 1) or ((mode[0] != 'c') and (mode[0] != 'd'))) {
        help(prog);
        return;
    }

    var rf = std.io.getStdIn();
    var wf = std.io.getStdOut();

    if (rf.isTty() or wf.isTty()) {
        help(prog);
        return;
    }

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    switch (mode[0]) {
        'c' => try packer.compress(&rf, &wf, allocator),
        'd' => try packer.decompress(&rf, &wf, allocator),
        else => unreachable,
    }
}
