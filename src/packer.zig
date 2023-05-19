
const std = @import("std");
const os = std.os;
const fs = std.fs;
const io = std.io;
const mem = std.mem;
const Allocator = mem.Allocator;

const BitPredictor = @import("bit-predictor.zig").BitPredictor;
const Encoder = @import("bit-encoder.zig").Encoder;
const Decoder = @import("bit-decoder.zig").Decoder;
const Reader = @import("buff-reader.zig").Reader;
const Writer = @import("buff-writer.zig").Writer;
const Ranker = @import("sr-model.zig").Ranker;
const SREncoder = @import("sr-encoder.zig").SREncoder;
const SRDecoder = @import("sr-decoder.zig").SRDecoder;

pub fn compress(rf: *fs.File, wf: *fs.File, a: Allocator) !void {

    var reader = try Reader.init(rf, 4096, a);
    var writer = try Writer.init(wf, 4096, a);
    var bp = try BitPredictor.init(a, 26);
    var encoder = Encoder.init(&bp, wf, &writer);
    var ranker = try Ranker.init(a);
    var sr_encoder = SREncoder.init(&ranker, &encoder);

    // store file header
    var hdr: [5]u8 = .{'S','R','Z', '4', 0x55};
    // NOTE about 0x55
    // hi nibble (4 or 5) is for tweaking range coder adaptivity, see DS const in bit-predictor
    // lo nibble (5 or 6 or 7) is for hash tweaking, see sr-model in the very end
    // 5 - slower, but a bit better compression, 7 - faster, but a bit worse compression
    // currently fixed (hardcoded), 5/5
    // 4/6 works better for small files (Calgary, Canterbury)
    // 5/5 works better for, for example, enwiks

    try writer.take(hdr[0]);
    try writer.take(hdr[1]);
    try writer.take(hdr[2]);
    try writer.take(hdr[3]);
    try writer.take(hdr[4]);

    while (true) {
        var byte = try reader.give() orelse break;
        try sr_encoder.take(byte);
    }

    try sr_encoder.eof();
    try writer.flush();
}

const DecompressError = error {
    IsNotSRZFile,
};

pub fn decompress(rf: *fs.File, wf: *fs.File, a: Allocator) !void {

    var reader = try Reader.init(rf, 4096, a);
    var writer = try Writer.init(wf, 4096, a);
    var byte: u8 = 0;

    // fetch file header
    byte = try reader.give() orelse unreachable;
    if (byte != 'S') return DecompressError.IsNotSRZFile;
    byte = try reader.give() orelse unreachable;
    if (byte != 'R') return DecompressError.IsNotSRZFile;
    byte = try reader.give() orelse unreachable;
    if (byte != 'Z') return DecompressError.IsNotSRZFile;
    byte = try reader.give() orelse unreachable;
    if (byte != '4') return DecompressError.IsNotSRZFile;
    _ = try reader.give() orelse unreachable;

    var bp = try BitPredictor.init(a, 26);
    var decoder = try Decoder.init(&bp, rf, &reader);
    var ranker = try Ranker.init(a);
    var sr_decoder = SRDecoder.init(&ranker, &decoder);

    while (true) {
        byte = try sr_decoder.give() orelse break;
        _ = try writer.take(byte);
    }
    try writer.flush();
}
