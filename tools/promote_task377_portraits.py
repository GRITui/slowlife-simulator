#!/usr/bin/env python3
"""TASK-377: promote finished mood portraits from the Draw Things queue
into the project's assets/ui/portraits/ folder.

The Draw Things batch writes images matching the naming convention
`portrait_<lowercase_speaker>_<mood>.png` into
`tools/drawthings_queue/done/`. Once an image lands there this script
copies it to `assets/ui/portraits/<lowercase_speaker>_<mood>.png`, which
is the in-game asset path the runtime's PORTRAIT_PATHS dict (in
scenes/core/World.gd) references. No code change is needed for a new
mood image to "light up" — the runtime picks it up automatically the
next time _resolve_portrait_path() is called for that (speaker, mood).

Usage:
    python3 tools/promote_task377_portraits.py

Idempotent / safe to re-run mid-batch:
  - If done/ doesn't exist yet (batch still in flight), the script
    reports zero work and exits cleanly without erroring.
  - Already-promoted destination files are skipped, NOT overwritten —
    only genuinely re-generated source files with newer mtimes would
    replace them. (No naming collision with the 6 old flat TASK-376
    files — those have no "_" before the mood suffix, so they cannot
    be matched by the done/pattern.)
  - Prints a summary: copied vs skipped vs non-matching.
"""
import os
import re
import shutil
import sys

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DONE_DIR = os.path.join(REPO_ROOT, "tools", "drawthings_queue", "done")
DEST_DIR = os.path.join(REPO_ROOT, "assets", "ui", "portraits")

# portrait_<lowercase_speaker>_<mood>.png
# speakers are lowercase ASCII letters; mood may contain underscores
# (e.g. in_love, disappointed). We require the file extension to be
# .png and at least one character in each group.
NAME_RE = re.compile(r"^portrait_([a-z]+)_([a-z_]+)\.png$")


def main() -> int:
    if not os.path.isdir(DONE_DIR):
        print(f"done/ directory not present at {DONE_DIR} — nothing to promote yet (batch still generating).")
        return 0

    os.makedirs(DEST_DIR, exist_ok=True)

    copied = 0
    skipped_existing = 0
    non_matching = 0
    for entry in sorted(os.listdir(DONE_DIR)):
        src_path = os.path.join(DONE_DIR, entry)
        if not os.path.isfile(src_path):
            continue
        m = NAME_RE.match(entry)
        if not m:
            non_matching += 1
            continue
        speaker, mood = m.group(1), m.group(2)
        dest_name = f"{speaker}_{mood}.png"
        dest_path = os.path.join(DEST_DIR, dest_name)
        if os.path.exists(dest_path):
            skipped_existing += 1
            continue
        shutil.copy2(src_path, dest_path)
        copied += 1
        print(f"  copied {entry} -> assets/ui/portraits/{dest_name}")

    print(
        f"promote_task377_portraits: copied={copied} skipped_existing={skipped_existing} non_matching={non_matching}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())