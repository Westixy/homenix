#!/usr/bin/env python3
"""Convert the Gohu 8x14 BDF font into Limine's raw CP437 bitmap format.

Limine's `term_font` expects a headerless font: 256 glyphs, 8 px wide,
one byte per row, top to bottom. Gohu is 8x14, so each glyph is 14 bytes
and the resulting file is exactly 256 * 14 = 3584 bytes.

Gohu's `-14.bdf` is ISO8859-1 (Latin-1), so its ASCII range maps 1:1 onto
CP437. The high CP437 block (box drawing, etc.) is not present in Gohu, so
those glyphs are emitted as blanks — fine for the boot menu, which is ASCII.
"""

import sys

WIDTH = 8
HEIGHT = 14
NGLYPHS = 256


def parse_bdf(path):
    glyphs = {}
    encoding = None
    bitmap = None
    in_bitmap = False

    with open(path, "rb") as f:
        for raw in f:
            line = raw.decode("latin-1").rstrip("\n")
            if line.startswith("ENCODING"):
                encoding = int(line.split()[1])
                bitmap = []
                in_bitmap = False
            elif line == "BITMAP":
                in_bitmap = True
            elif line == "ENDCHAR":
                if encoding is not None and bitmap is not None:
                    glyphs[encoding] = bitmap
                encoding = None
                bitmap = None
                in_bitmap = False
            elif in_bitmap:
                bitmap.append(line)

    return glyphs


def main():
    bdf_path, out_path = sys.argv[1], sys.argv[2]
    glyphs = parse_bdf(bdf_path)

    out = bytearray()
    for code in range(NGLYPHS):
        # ASCII printable range maps 1:1 from Latin-1; everything else blank.
        rows = glyphs.get(code) if 32 <= code <= 126 else None
        if rows is None:
            rows = ["00"] * HEIGHT
        for row in rows[:HEIGHT]:
            out.append(int(row, 16))

    with open(out_path, "wb") as f:
        f.write(bytes(out))


if __name__ == "__main__":
    main()
