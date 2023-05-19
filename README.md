
# Simple Symbol Ranking Compressor/Decompressor

## How to build
```
/opt/zig-0.10.1/zig build -Drelease-fast
```
## How to use
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
## How it works
...
