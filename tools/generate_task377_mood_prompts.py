#!/usr/bin/env python3
"""TASK-377: generate the 120 mood-portrait prompt files into
tools/drawthings_queue/pending/, one per (speaker, mood) pair.

Style/steps/size match the winning approach from TASK-376's 6 base
portraits (see tools/drawthings_queue/done/portrait_*.json): pixel art
bust portrait, soft shading, warm earthy palette, isolated on pitch
black, "cozy game dialogue icon" tag, steps=24, 512x512.

Taxonomy (locked 2026-09-05, see ops/backlog-inbox.md TASK-377):
  universal (all 12 speakers): neutral, happy, excited, sad, angry,
    disappointed, worry, tired, bored
  romance-only (6 candidates): in love, shy

Run from repo root: python3 tools/generate_task377_mood_prompts.py
"""
import json
import os

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
PENDING_DIR = os.path.join(REPO_ROOT, "tools", "drawthings_queue", "pending")

STYLE_SUFFIX = (
    "soft shaded pixel art style, warm earthy color palette, "
    "bust portrait centered, isolated on pitch black background, "
    "cozy game dialogue icon"
)

# Base character descriptions. The 6 non-romance speakers reuse the
# exact winning phrasing from the already-shipped portraits (done/
# portrait_*.json) so the mood variants match the established look.
# The 6 romance candidates are new bases, written from their established
# occupation/personality in DialogueDB.gd (ek=paddy farmer/rivalry, fah=
# fisher/calm, ploy=dessert vendor/warm, chang=wood carver/focused,
# klong=festival drummer/energetic, yaa=herbalist/gentle) -- no prior
# portrait art exists for 5 of these 6 (only a loose, never-wired fah.png
# exists; regenerated here too for one consistent mood-variant set).
BASES = {
    "elder": "pixel art portrait, elderly Thai village elder, traditional conical straw hat, warm wrinkled kind face, wispy white beard",
    "child": "pixel art portrait, young Thai village child, round cheerful face, simple traditional rural clothing, carrying a small woven basket",
    "handler": "pixel art portrait, Thai buffalo handler, sturdy weathered face, traditional headwrap and rolled sleeves, farmer clothing",
    "monk": "pixel art portrait, Thai Buddhist monk, shaved head, orange and saffron colored robes, gentle face",
    "trader": "pixel art portrait, traveling Thai market trader, colorful traditional vest, small round hat, gold jewelry accent",
    "buffalo": "pixel art portrait, friendly water buffalo face, large curved horns, gray weathered hide",
    "ek": "pixel art portrait, young Thai rice-paddy farmer, sturdy build, sun-tanned skin, straw sun hat hanging behind neck, rolled-up work sleeves",
    "fah": "pixel art portrait, young Thai fisher, composed face, wide-brim woven hat, simple boatman's clothes, coiled fishing net over one shoulder",
    "ploy": "pixel art portrait, young Thai dessert vendor, round warm face, hair tied back with a cloth, apron dusted with sticky rice flour",
    "chang": "pixel art portrait, young Thai wood carver, steady focused eyes, wood shavings dusting his shoulders, simple apprentice clothes, holding a small chisel",
    "klong": "pixel art portrait, young Thai festival drummer, bright energetic eyes, colorful festival headband, holding a pair of drumsticks",
    "yaa": "pixel art portrait, young Thai herbalist and gardener, serene gentle face, a flower tucked behind one ear, earth-toned garden clothes, small herb basket",
}

# Mood -> expression modifier. Kept gentle/cozy even for negative moods
# (angry/disappointed/worry) per this project's established non-punishing
# tone -- see TASK-377's researcher_notes.
UNIVERSAL_MOODS = {
    "neutral": "calm neutral expression",
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

ROMANCE_CANDIDATE_IDS = ["ek", "fah", "ploy", "chang", "klong", "yaa"]


def build_prompts():
    prompts = {}
    for speaker, base in BASES.items():
        moods = dict(UNIVERSAL_MOODS)
        if speaker in ROMANCE_CANDIDATE_IDS:
            moods.update(ROMANCE_ONLY_MOODS)
        for mood_id, mood_desc in moods.items():
            key = f"portrait_{speaker}_{mood_id}"
            prompts[key] = {
                "prompt": f"{base}, {mood_desc}, {STYLE_SUFFIX}",
                "steps": 24,
                "width": 512,
                "height": 512,
            }
    return prompts


def main():
    os.makedirs(PENDING_DIR, exist_ok=True)
    prompts = build_prompts()
    for name, spec in sorted(prompts.items()):
        path = os.path.join(PENDING_DIR, f"{name}.json")
        with open(path, "w", encoding="utf-8") as f:
            json.dump(spec, f, indent=2)
            f.write("\n")
    print(f"Wrote {len(prompts)} prompt files to {PENDING_DIR}")


if __name__ == "__main__":
    main()
