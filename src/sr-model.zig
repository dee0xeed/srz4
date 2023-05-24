
const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;

pub const Ranker = struct {
    const ORDER = 3;

    ctx: u32 = 0,

    // per context value ranked lists, 4 bytes each
    lst: []u32 = undefined,

    // first-place life-time counter for a symbol
    cnt: []u4 = undefined,

    pub fn init(a: Allocator) !Ranker {

        var ranker = Ranker{};
        const len = @as(u32, 1) << (8 * ORDER);

        ranker.lst = try a.alloc(u32, len);
        mem.set(u32, ranker.lst, 0);

        ranker.cnt = try a.alloc(u4, len);
        mem.set(u4, ranker.cnt, 0);

        return ranker;
    }

    pub inline fn getRank(self: *Ranker, sym: u8) u32 {

        var lst = self.lst[self.ctx];
        var rank: u32 = 0;
        var k: u32 = 0;

        while (k < 4) : (k += 1) {
            if (sym == lst & 0xff) {
                rank = k + 1;
                break;
            }
            lst >>= 8;
        }

        return rank;
    }

    pub inline fn update(self: *Ranker, s: u8, i: u32) void {

        var lst = self.lst[self.ctx];

        switch (i) {

            0 => {
                // not in the list
                const b3 = (lst & 0x00ff_0000) << 8;  // b3 <- b2
                const b2 = (lst & 0x0000_ff00) << 8;  // b2 <- b1
                const b1 = (lst & 0x0000_00ff) << 8;  // b1 <- b0
                lst = b3 | b2 | b1 | s;
                self.cnt[self.ctx] = 0;
            },

            1 => {
                // leave as is
                if (self.cnt[self.ctx] < 15) self.cnt[self.ctx] += 1;
            },

            2 => {
                const b1 = (lst & 0x0000_00ff) << 8;  // b1 <- b0
                const b0 = (lst & 0x0000_ff00) >> 8;  // b0 -> b1
                lst &= 0xffff_0000;
                lst |= b1 | b0;
                self.cnt[self.ctx] = 1;
            },

            3 => {
                const b2 = (lst & 0x0000_ff00) << 8;  // b2 <- b1
                const b1 = (lst & 0x0000_00ff) << 8;  // b1 <- b0
                const b0 = (lst & 0x00ff_0000) >> 16; // b2 -> b0
                lst &= 0xff00_0000;
                lst |= b2 | b1 | b0;
                self.cnt[self.ctx] = 1;
            },

            4 => {
                const b3 = (lst & 0x00ff_0000) << 8;  // b3 <- b2
                const b2 = (lst & 0x0000_ff00) << 8;  // b2 <- b1
                const b1 = (lst & 0x0000_00ff) << 8;  // b1 <- b0
                const b0 = (lst & 0xff00_0000) >> 24; // b3 -> b0
                lst = b3 | b2 | b1 | b0;
                self.cnt[self.ctx] = 1;
            },

            else => unreachable,
        }

        self.lst[self.ctx] = lst;
        self.ctx = ((self.ctx << 5) + s) & 0x00ffffff; // 3 byte hash of 4 bytes context
    }
};
