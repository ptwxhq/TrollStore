#!/usr/bin/env python3
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: embed_file_as_objc.py <input> <output>", file=sys.stderr)
        return 2

    input_path = Path(sys.argv[1])
    output_path = Path(sys.argv[2])
    data = input_path.read_bytes()

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", encoding="ascii", newline="\n") as f:
        f.write('#import "EmbeddedTrollStoreTar.h"\n\n')
        f.write("const unsigned char EmbeddedTrollStoreTarData[] = {\n")
        for offset in range(0, len(data), 12):
            chunk = data[offset:offset + 12]
            values = ", ".join(f"0x{byte:02x}" for byte in chunk)
            f.write(f"\t{values},\n")
        f.write("};\n")
        f.write(f"const unsigned int EmbeddedTrollStoreTarLength = {len(data)};\n")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
