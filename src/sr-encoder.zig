
const std = @import("std");
const Encoder = @import("bit-encoder.zig").Encoder;
const Ranker = @import("sr-model.zig").Ranker;

pub const SREncoder = struct {

    ranker: *Ranker = undefined,
    encoder: *Encoder = undefined,

    pub fn init(ranker: *Ranker, encoder: *Encoder) SREncoder {
        var sr_encoder = SREncoder{.ranker = ranker, .encoder = encoder};
        return sr_encoder;
    }

    /// emits unary code for the rank
    inline fn outputRank(self: *SREncoder, rank: u32) !void {

        var n0: u32 = rank - 1;
        var k: isize = 0;

        while (k < n0) : (k += 1) {
            try self.encoder.take(0);
            // update LEVEL-2 context
            self.encoder.bp.cx <<= 1;
        }

        try self.encoder.take(1);
        // update LEVEL-2 context
        self.encoder.bp.cx = (self.encoder.bp.cx << 1) | 1;
    }

    inline fn outputLiteral(self: *SREncoder, sym: u8) !void {
        var k: isize = 7;
        while (k >= 0) : (k -= 1) {
            var bit: u1 = @intCast(u1, (sym >> @intCast(u3, k)) & 1);
            try self.encoder.take(bit);
            // update LEVEL-2 context
            self.encoder.bp.cx = (self.encoder.bp.cx << 1) | bit;
        }
    }

    pub inline fn take(self: *SREncoder, sym: u8) !void {

        var rank = self.ranker.getRank(sym);

        if (0 == rank) { // miss
            try self.outputRank(2);
            try self.outputLiteral(sym);
        } else {         // hit
            var r = if (1 == rank) rank else rank + 1;
            try self.outputRank(r);
        }

        self.ranker.update(sym, rank);

        // set LEVEL-2 context
        self.encoder.bp.cx = 1;
        self.encoder.bp.cx = (self.encoder.bp.cx << 4) | self.ranker.cnt[self.ranker.ctx];
        self.encoder.bp.cx = (self.encoder.bp.cx << 3) | rank;
        self.encoder.bp.cx = (self.encoder.bp.cx << 8) | sym;
    }

    pub fn eof(self: *SREncoder) !void {
        try self.outputRank(6);
        try self.encoder.foldup();
    }
};
