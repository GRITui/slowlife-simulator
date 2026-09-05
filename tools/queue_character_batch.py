#!/usr/bin/env python3
"""TASK-377: queue one character's full mood-portrait set at a time
(owner directive: "fire drawthings 1 character per batch").

For the 6 already-shipped base speakers (elder/child/handler/monk/
trader/buffalo): their canonical neutral image already exists (except
elder.png, which is being regenerated -- see the gender-audit comment in
generate_task377_mood_prompts.py). This script queues their 8 non-neutral
universal moods directly via img2img against that canonical file --
no separate neutral phase needed.

For the 6 romance candidates (no existing canonical art): queue the
neutral ANCHOR ALONE first (txt2img, --phase neutral), wait for it to
land in done/, then run again with --phase moods to queue the other 10
mood variants via img2img against that freshly-generated neutral.

Usage:
    python3 tools/queue_character_batch.py elder            # base speaker, 1 phase
    python3 tools/queue_character_batch.py fah --phase neutral   # romance candidate, phase 1
    python3 tools/queue_character_batch.py fah --phase moods      # romance candidate, phase 2 (after phase 1 lands)
"""
import argparse
import json
import os
import sys

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
PENDING_DIR = os.path.join(REPO_ROOT, "tools", "drawthings_queue", "pending")
DONE_DIR = os.path.join(REPO_ROOT, "tools", "drawthings_queue", "done")
PORTRAITS_DIR = os.path.join(REPO_ROOT, "assets", "ui", "portraits")

STYLE_SUFFIX = (
    "soft shaded pixel art style, warm earthy color palette, "
    "bust portrait centered, isolated on pitch black background, "
    "cozy game dialogue icon"
)
DENOISING_STRENGTH = 0.4
STEPS = 24
SIZE = 512

# Gender-audited base descriptions -- see generate_task377_mood_prompts.py
# for the full audit comment (elder/romance-candidates=female, handler/
# trader/monk=male, child=female per owner decision 2026-09-05).
# 2026-09-05 fix: base descriptions must NOT bake in a facial expression
# word (a smile, "cheerful", "serene", "energetic", "focused", etc.) --
# the mood modifier appended at generation time is the ONLY thing that
# should control expression. Found empirically: Ploy's original base
# ("confident charming smile") directly fought the "angry" mood modifier
# ("mildly stern expression, furrowed brow") in the same prompt, and the
# img2img result came back nearly identical to neutral -- the model
# just kept the smile. Audited every base below and stripped anything
# expression-adjacent, keeping only identity/physical/occupation traits.
BASES = {
    "elder": "pixel art portrait, elderly Thai woman, village elder, traditional conical straw hat, silver hair tied back, wrinkled skin",
    "child": "pixel art portrait, young Thai girl, village child, simple traditional rural clothing, carrying a small woven basket",
    "handler": "pixel art portrait, Thai man, buffalo handler, sturdy build, traditional headwrap and rolled sleeves, farmer clothing",
    "monk": "pixel art portrait, Thai Buddhist monk, man, shaved head, orange and saffron colored robes",
    "trader": "pixel art portrait, Thai man, traveling market trader, colorful traditional vest, small round hat, gold jewelry accent",
    "buffalo": "pixel art portrait, water buffalo face, large curved horns, gray weathered hide",
    "ek": "pixel art portrait, young Thai woman, rice-paddy farmer, sturdy build, sun-tanned skin, straw sun hat hanging behind neck, rolled-up work sleeves",
    "fah": "pixel art portrait, young Thai woman, fisher, wide-brim woven hat, simple boatman's clothes, coiled fishing net over one shoulder",
    "ploy": "pixel art portrait, young Thai woman, dessert vendor, colorful sabai sash over traditional dress, flower tucked in her hair, apron dusted with sticky rice flour",
    "chang": "pixel art portrait, young Thai woman, wood carver, wood shavings dusting her shoulders, simple apprentice clothes, holding a small chisel",
    "klong": "pixel art portrait, young Thai woman, festival drummer, colorful festival headband, holding a pair of drumsticks",
    "yaa": "pixel art portrait, young Thai woman, herbalist and gardener, a flower tucked behind one ear, earth-toned garden clothes, small herb basket",
}

UNIVERSAL_MOODS = {
    "happy": "warm smiling happy expression",
    "excited": "wide bright excited expression, eyes lit up, eager energy",
    "sad": "downcast melancholic sad expression, gentle frown",
    "angry": "mildly stern expression, furrowed brow, arms crossed -- annoyed, never rageful",
    "disappointed": "gentle disappointed frown, slightly lowered gaze",
    "worry": "concerned worried expression, faintly furrowed brow, uneasy eyes",
    "tired": "sleepy tired expression, half-lidded eyes, faint yawn",
    "bored": "flat bored expression, unimpressed half-lidded eyes, chin resting on hand",
}
ROMANCE_ONLY_MOODS = {
    "in_love": "soft blushing loving expression, warm affectionate eyes, gentle fond smile",
    "shy": "shy bashful expression, light blush, eyes glancing away, timid smile",
}

ROMANCE_CANDIDATES = {"ek", "fah", "ploy", "chang", "klong", "yaa"}
BASE_SPEAKERS = {"elder", "child", "handler", "monk", "trader", "buffalo"}

# The canonical anchor file for each base speaker's img2img reference.
# elder.png is about to be regenerated (gender fix); the other 5 keep
# their existing TASK-376 shipped file untouched.
BASE_ANCHOR_PATH = {
    "elder": os.path.join(PORTRAITS_DIR, "elder.png"),
    "child": os.path.join(PORTRAITS_DIR, "child.png"),
    "handler": os.path.join(PORTRAITS_DIR, "handler.png"),
    "monk": os.path.join(PORTRAITS_DIR, "monk.png"),
    "trader": os.path.join(PORTRAITS_DIR, "trader.png"),
    "buffalo": os.path.join(PORTRAITS_DIR, "buffalo.png"),
}


def write_prompt(name: str, prompt: str, init_image: str = None) -> None:
    spec = {"prompt": prompt, "steps": STEPS, "width": SIZE, "height": SIZE}
    if init_image:
        spec["init_image"] = os.path.relpath(init_image, REPO_ROOT)
        spec["denoising_strength"] = DENOISING_STRENGTH
    path = os.path.join(PENDING_DIR, f"{name}.json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(spec, f, indent=2)
        f.write("\n")
    print(f"queued {path}" + (f" (img2img ref={os.path.basename(init_image)})" if init_image else " (txt2img)"))


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("speaker")
    ap.add_argument("--phase", choices=["neutral", "moods", "all"], default="all")
    args = ap.parse_args()
    speaker = args.speaker.lower()

    if speaker not in BASES:
        print(f"unknown speaker '{speaker}' -- must be one of {sorted(BASES.keys())}", file=sys.stderr)
        return 1

    os.makedirs(PENDING_DIR, exist_ok=True)
    base = BASES[speaker]

    if speaker in ROMANCE_CANDIDATES:
        neutral_anchor = os.path.join(DONE_DIR, f"portrait_{speaker}_neutral.png")
        if args.phase in ("neutral", "all"):
            write_prompt(f"portrait_{speaker}_neutral", f"{base}, calm neutral expression, {STYLE_SUFFIX}")
        if args.phase in ("moods", "all"):
            if args.phase == "moods" and not os.path.isfile(neutral_anchor):
                print(f"ERROR: {neutral_anchor} does not exist yet -- run --phase neutral first and wait for it to land in done/.", file=sys.stderr)
                return 1
            if args.phase == "all":
                print(f"NOTE: --phase all queues moods referencing {neutral_anchor}, which doesn't exist yet this run -- "
                      f"only safe if you already ran --phase neutral for {speaker} in a PRIOR invocation and it's done.")
            all_moods = {**UNIVERSAL_MOODS, **ROMANCE_ONLY_MOODS}
            for mood_id, mood_desc in all_moods.items():
                write_prompt(f"portrait_{speaker}_{mood_id}", f"{base}, {mood_desc}, {STYLE_SUFFIX}", init_image=neutral_anchor)
    else:
        anchor = BASE_ANCHOR_PATH[speaker]
        if speaker != "elder" and not os.path.isfile(anchor):
            print(f"ERROR: expected canonical anchor {anchor} not found.", file=sys.stderr)
            return 1
        if speaker == "elder":
            # elder.png is being regenerated fresh (gender-fix correction)
            # -- same neutral-then-moods two-phase flow as a romance
            # candidate, but she stays a BASE speaker in PORTRAIT_PATHS
            # (her "neutral" key still points at res://assets/ui/portraits
            # /elder.png -- that file just gets overwritten with corrected
            # art once this generates, not renamed).
            if args.phase in ("neutral", "all"):
                write_prompt("portrait_elder_neutral_regen", f"{base}, calm neutral expression, {STYLE_SUFFIX}")
            if args.phase in ("moods", "all"):
                regen_anchor = os.path.join(DONE_DIR, "portrait_elder_neutral_regen.png")
                if args.phase == "moods" and not os.path.isfile(regen_anchor):
                    print(f"ERROR: {regen_anchor} does not exist yet -- run --phase neutral first, confirm it looks right, "
                          f"copy it over assets/ui/portraits/elder.png yourself, then re-run with --phase moods.", file=sys.stderr)
                    return 1
                for mood_id, mood_desc in UNIVERSAL_MOODS.items():
                    write_prompt(f"portrait_elder_{mood_id}", f"{base}, {mood_desc}, {STYLE_SUFFIX}", init_image=anchor)
        else:
            for mood_id, mood_desc in UNIVERSAL_MOODS.items():
                write_prompt(f"portrait_{speaker}_{mood_id}", f"{base}, {mood_desc}, {STYLE_SUFFIX}", init_image=anchor)

    return 0


if __name__ == "__main__":
    sys.exit(main())
