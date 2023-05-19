
const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const Allocator = mem.Allocator;

pub const Reader = struct {

    file: *fs.File = undefined,
    buff: []u8 = undefined,
    bcnt: u32 = 0,
    curr: u32 = 0,

    pub fn init(f: *fs.File, s: u32, a: Allocator) !Reader {
        var self = Reader{};
        self.buff = try a.alloc(u8, s);
        self.file = f;
        return self;
    }

    pub inline fn give(self: *Reader) !?u8 {
        if (0 == self.bcnt) {
            self.bcnt = @intCast(u32, try self.file.read(self.buff[0..]));
            if (0 == self.bcnt) return null;
            self.curr = 0;
        }
        self.bcnt -= 1;
        const byte = self.buff[self.curr];
        self.curr += 1;
        return byte;
    }
};
