
const std = @import("std");
const os = std.os;
const fs = std.fs;

const BitPredictor = @import("bit-predictor.zig").BitPredictor;
const Reader = @import("buff-reader.zig").Reader;

pub const Decoder = struct {

    bp: *BitPredictor,
    file: *fs.File,
    reader: *Reader,

    xl: u32 = 0,
    xr: u32 = 0xFFFF_FFFF,
     x: u32 = 0,

    pub fn init(bp: *BitPredictor, f: *fs.File, r: *Reader) !Decoder {

        var d = Decoder {
            .bp = bp,
            .file = f,
            .reader = r,
        };

        var byte: u8 = undefined;
        for (0 .. 4) |_| {
            byte = try r.give() orelse 0;
            d.x = (d.x << 8) | byte;
        }
        return d;
    }

    pub inline fn give(self: *Decoder) !u1 {

        const xm = self.xl + ((self.xr - self.xl) >> BitPredictor.NBITS) * self.bp.getP0();
        var bit: u1 = 1;
        if (self.x <= xm) {
            bit = 0;
            self.xr = xm;
        } else {
            self.xl = xm + 1;
        }

        self.bp.update(bit);

        while (0 == ((self.xl ^ self.xr) & 0xFF00_0000)) {

            self.xl <<= 8;
            self.xr = (self.xr << 8) | 0x0000_00FF;

            var byte = try self.reader.give() orelse 0;
            self.x = (self.x << 8) | byte;
        }

        return bit;
    }
};
