
# Simple Symbol Ranking Compressor

## How To Build (zig 0.12 required)
```
/opt/zig-0.12/zig build -Doptimize=ReleaseFast
```
Resulting executable is in `zig-out/bin/srz`

## How To Use

For the sake of simplicity,
`srz` can only read from `stdin` (if it is not a `tty`)
and can only write to `stdout` (if it is also not a `tty`).
So, just use redirections and pipe-lining, like this:

### Compression
```
A. srz c < file > file.srz
B. a-prog | srz c > file.srz
```

### Decompression
```
srz d < file.srz > file
```

## Small Benchmark
```
  == enwik9 (1_000_000_000 bytes) ==

          cs, MB      ct, s   eff   opt
 gzip : 323.742882   31.707  0.779
 zstd : 278.180840   36.352  0.791  -10
  sr2 : 273.906319   32.156  0.908
 srz4 : 261.112120   28.895  1.060  // L1 ctx = ((ctx << 6) + s) & 0x00ffffff;
bzip2 : 253.977891   64.173  0.491
 srz4 : 246.719886   44.265  0.733  // L1 ctx = ((ctx << 5) + s) & 0x00ffffff;
 zstd : 242.303796  375.695  0.088  -19
  srx : 236.319404   23.931  1.415
   xz : 230.153052  427.564  0.081

 cs = compressed-size
 ct = compression-time
eff = (1_000_000_000 ^ 2) / (125 * cs * ct)
eff stands for 'efficiency'.
```

## How It Works

`srz` has two levels (stages) of encoding/decoding:

* LEVEL 1: symbol ranking codec (SR)
* LEVEL 2: arithmetic/range codec (AC)

### Symbol ranker

SR uses 3 byte context (hash of 4 most recently seen bytes).
For each context value SR maintains 4 byte list of symbols.
Symbols in these lists are kept ordered by recency using savage MTF.
Position of a symbol in a list is it's rank (1,2,3,4).
Symbols that were not in a list are encoded as is (literals).
Ranks are encoded with unary codes, like this:

```
     '1' : rank 1
    '01' : literal follows
   '001' : rank 2
  '0001' : rank 3
 '00001' : rank 4
'000001' : EOF marker
```
Such a choice of the codes is based on the observations that (usually)
the number of 1-st place matches is greater than the number of mismatches
and the latter is greater than any other.

### Arithmetic codec

Bit stream from SR is processed by arithmetic codec (borrowed from [fpaq0p](https://nishi.dreamhosters.com/u/fpaq0p.cpp)).
AC uses 26 bit context which includes:

* leading `1`, 1 bit (models position of bit in a codeword)
* first-place life-time counter, 4 bits (0..15)
* rank of the most recent symbol, 3 bits (0..4)
* most recent symbol itself, 8 bits
* already processed bits of unary code (and possible literal)

## Links

* [enwik9 benchmark](https://www.mattmahoney.net/dc/text.html)
* [srank (C)](https://www.cs.auckland.ac.nz/~peter-f/FTPfiles/srank.c) by P.M.Fenwick, 1996
* [sr2 (C++)](https://encode.su/threads/881-Symbol-ranking-compression) by M.Mahoney, 2007
* [srx (Rust)](https://encode.su/threads/4038-SRX-fast-multi-threaded-SR-compressor) by Mai Thanh Minh, 2023
* [MTF](https://hbfs.wordpress.com/2009/03/03/ad-hoc-compression-methods-move-to-front/)
* [Unary coding](https://en.wikipedia.org/wiki/Unary_coding)
