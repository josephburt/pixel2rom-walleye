#!/usr/bin/env python3
"""Convert Android sparse ext4 images to raw ext4 images. Read-only decoder."""
import sys, struct

def main():
    inp, outp = sys.argv[1], sys.argv[2]
    with open(inp, 'rb') as f:
        magic = f.read(4)
        if magic != b'\x3a\xff\x26\xed':
            print('not sparse (magic mismatch); copying raw')
            f.seek(0)
            with open(outp, 'wb') as o:
                while True:
                    b = f.read(8 * 1024 * 1024)
                    if not b: break
                    o.write(b)
            return
        major, minor, fhs, chs, blk_sz, total_blks, total_chunks = struct.unpack('<HHHHIII', f.read(20))
        f.seek(fhs)
        with open(outp, 'wb') as o:
            written = 0
            chunks = 0
            while written < total_blks and chunks < total_chunks:
                ch = f.read(12)
                if len(ch) < 12: break
                ctype, _res, chunk_blocks, total_bytes = struct.unpack('<HHII', ch)
                chunks += 1
                nbytes = chunk_blocks * blk_sz
                if ctype == 0xCAC1:  # RAW
                    data = f.read(total_bytes - 12)
                    if len(data) != nbytes:
                        sys.exit(f'RAW size mismatch: got {len(data)} expected {nbytes}')
                    o.write(data)
                    written += chunk_blocks
                elif ctype == 0xCAC2:  # FILL
                    pat = f.read(4)
                    blk = 1024 * 1024  # 1MiB slices
                    pattern = (int.from_bytes(pat, 'little') * blk_sz).to_bytes(blk_sz, 'little') if blk_sz < blk else pat * (blk // blk_sz)
                    full, rem = divmod(nbytes, len(pattern))
                    buf = pattern * full
                    if rem: buf += pattern[:rem]
                    o.write(buf)
                    written += chunk_blocks
                elif ctype == 0xCAC3:  # DONT_CARE
                    pos = 0
                    blk = 64 * 1024 * 1024
                    while pos < nbytes:
                        o.write(b'\x00' * min(blk, nbytes - pos))
                        pos += blk
                    written += chunk_blocks
                elif ctype == 0xCAC4:  # CRC32
                    f.read(total_size - 12)
                else:
                    sys.exit(f'unknown chunk type 0x{ctype:04X} at chunk {chunks}')
        print(f'blocks written: {written}/{total_blks}, chunks: {chunks}, blk_sz={blk_sz}')

if __name__ == '__main__':
    main()
