
const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const Allocator = mem.Allocator;

pub const Writer = struct {

    buff: []u8 = undefined,
    bcnt: u32 = 0,
    file: *fs.File = undefined,

    pub fn init(f: *fs.File, s: u32, a: Allocator) !Writer {
        var self = Writer{};
        self.buff = try a.alloc(u8, s);
        self.file = f;
        return self;
    }

    pub inline fn take(self: *Writer, byte: u8) !void {
        if (self.bcnt == self.buff.len) {
            _ = try self.file.write(self.buff[0..]);
            self.bcnt = 0;
        }
        self.buff[self.bcnt] = byte;
        self.bcnt += 1;
    }

    pub fn flush(self: *Writer) !void {
        if (self.bcnt > 0) {
            _ = try self.file.write(self.buff[0..self.bcnt]);
            self.bcnt = 0;
        }
    }
};
