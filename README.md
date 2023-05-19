
# Simple Symbol Ranking Compressor/Decompressor

## How To Build
```
/opt/zig-0.10.1/zig build -Drelease-fast
```
Resulting executable is in `zig-out/bin/srz`

## How To use
For the sake of simplicity,
`srz` can only read from `stdin` (if it is not a `tty`)
and can only write to `stdout` (if it is not a `tty`).
Just use redirections and pipe-lining, like this:

### Compression
```
A. srz c < file > file.srz
B. a-prog | srz > file.srz
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
  srx:  236.319404   23.931  1.415
   xz : 230.153052  427.564  0.081

eff = (1_000_000_000 ^ 2) / (125 * cs * ct)
```

## How It Works
...
