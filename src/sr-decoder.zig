
const std = @import("std");
const Decoder = @import("bit-decoder.zig").Decoder;
const Ranker = @import("sr-model.zig").Ranker;

pub const SRDecoder = struct {

    ranker: *Ranker = undefined,
    decoder: *Decoder = undefined,

    pub fn init(ranker: *Ranker, decoder: *Decoder) SRDecoder {
        var sr_decoder = SRDecoder{.ranker = ranker, .decoder = decoder};
        return sr_decoder;
    }

    pub inline fn give(self: *SRDecoder) !?u8 {

        var rank: u32 = 0;
        var bit: u1 = 0;

        // input rank unary code
        while (0 == bit) {
            bit = try self.decoder.give();
            self.decoder.bp.cx = (self.decoder.bp.cx << 1) | bit;
            rank += 1;
        }

        // EOF
        if (6 == rank)
            return null;

        var sym: u8 = 0;
        if (2 == rank) { // literal
            var k: isize = 0;
            while (k < 8) : (k += 1) {
                bit = try self.decoder.give();
                self.decoder.bp.cx = (self.decoder.bp.cx << 1) | bit;
                sym = (sym << 1) | bit;
            }
            rank = 0;
        } else {
            var lst = self.ranker.lst[self.ranker.ctx];
            if (rank > 1) rank -= 1;
            var shift = @intCast(u5, (rank - 1) * 8);
            sym = @intCast(u8, (lst >> shift) & 0xFF);
        }

        self.ranker.update(sym, rank);

        // set LEVEL-2 context
        self.decoder.bp.cx = 1;
        self.decoder.bp.cx = (self.decoder.bp.cx << 4) | self.ranker.cnt[self.ranker.ctx];
        self.decoder.bp.cx = (self.decoder.bp.cx << 3) | rank;
        self.decoder.bp.cx = (self.decoder.bp.cx << 8) | sym;

        return sym;
    }
};
