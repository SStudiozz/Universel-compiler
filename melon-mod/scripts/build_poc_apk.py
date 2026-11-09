#!/usr/bin/env python3
"""Rebuild Melon APK: drop broken arm64 libunity.so, inject marker, leave ready to sign."""
import argparse
import shutil
import zipfile
from datetime import datetime, timezone
from pathlib import Path

BAD_ENTRY = "lib/arm64-v8a/libunity.so"
MARKER = "assets/melon_patch_poc.txt"


def rebuild(src: Path, dst: Path, marker_text: str) -> None:
    skipped = []
    with zipfile.ZipFile(src, "r") as zin, zipfile.ZipFile(dst, "w") as zout:
        for info in zin.infolist():
            name = info.filename
            if name == BAD_ENTRY:
                skipped.append(name)
                continue
            if name == MARKER:
                continue
            try:
                data = zin.read(name)
            except Exception as e:
                skipped.append(f"{name} ({e})")
                continue
            zout.writestr(info, data)
        zout.writestr(MARKER, marker_text.encode("utf-8"))
    print(f"Wrote {dst} ({dst.stat().st_size} bytes)")
    print("Skipped:")
    for s in skipped:
        print(f"  - {s}")


def main():
    p = argparse.ArgumentParser()
    p.add_argument("src_apk")
    p.add_argument("-o", "--output", default="melon-pipeline-unsigned.apk")
    args = p.parse_args()
    src, dst = Path(args.src_apk), Path(args.output)
    marker = f"MELON_PATCH_PIPELINE {datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}\n"
    rebuild(src, dst, marker)


if __name__ == "__main__":
    main()
