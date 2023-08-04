
const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;

pub const BitPredictor = struct {

    pub const NBITS = 12;
    pub const P0MAX = 1 << NBITS;
    pub const DS = 5;

    cx: u32 = 1,
    p0: []u16 = undefined,

    pub fn init(a: Allocator, ctx_len: u5) !BitPredictor {
        var bp = BitPredictor{};
        bp.p0 = try a.alloc(u16, @as(u32, 1) << ctx_len);
        @memset(bp.p0, P0MAX / 2);
        return bp;
    }

    pub inline fn getP0(self: *BitPredictor) u16 {
        return self.p0[self.cx];
    }

    pub inline fn update(self: *BitPredictor, bit: u1) void {
        var delta: u16 = 0;
        const i: u32 = self.cx;
        if (0 == bit) {
            delta = (P0MAX - self.p0[i]) >> DS;
            self.p0[i] += delta;
        } else {
            delta = self.p0[i] >> DS;
            self.p0[i] -= delta;
        }
    }
};
