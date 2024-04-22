
const std = @import("std");
const os = std.os;
const fs = std.fs;
const mem = std.mem;
const Allocator = mem.Allocator;
const BitPredictor = @import("bit-predictor.zig").BitPredictor;
const Writer = @import("buff-writer.zig").Writer;

pub const Encoder = struct {

    bp: *BitPredictor,
    file: *fs.File,
    writer: *Writer,
    xl: u32 = 0,
    xr: u32 = 0xFFFF_FFFF,

    pub fn init(bp: *BitPredictor, f: *fs.File, w: *Writer) Encoder {
        const self = Encoder {
            .bp = bp,
            .file = f,
            .writer = w,
        };
        return self;
    }

    pub inline fn take(self: *Encoder, bit: u1) !void {

        const xm = self.xl + ((self.xr - self.xl) >> BitPredictor.NBITS) * self.bp.getP0();

        // left/lower part of the interval corresponds to zero

        if (0 == bit) {
            self.xr = xm;
        } else {
            self.xl = xm + 1;
        }

        self.bp.update(bit);

        while (0 == ((self.xl ^ self.xr) & 0xFF00_0000)) {
            const byte: u8 = @intCast(self.xr >> 24);
            try self.writer.take(byte);
            self.xl <<= 8;
            self.xr = (self.xr << 8) | 0x0000_00FF;
        }
    }

    pub fn foldup(self: *Encoder) !void {
        const byte: u8 = @intCast(self.xr >> 24);
        try self.writer.take(byte);
    }
};
