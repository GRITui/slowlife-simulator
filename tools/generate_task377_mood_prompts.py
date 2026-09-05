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
# Gender audit (2026-09-05): the original TASK-376 prompts and this
# generator's first draft specified NO gender at all -- a real prompt-
# precision gap that leaves the model to default arbitrarily, which
# compounds the identity-drift problem this whole img2img pipeline
# exists to fix. Locked per owner decision, cross-checked against
# established canon where it exists:
#   - Elder: FEMALE ("grandmother-figure", "she tells it" --
#     VILLAGE_LORE.md:9,19). The ALREADY-SHIPPED elder.png contradicts
#     this (prompted with "wispy white beard") -- being regenerated here,
#     replacing the shipped file (owner-approved correction, not a
#     regression of TASK-376's "don't touch the 6 neutrals" rule).
#   - Fah: FEMALE ("her", "she" -- VILLAGE_LORE.md:37). Confirmed in canon.
#   - Ploy: FEMALE ("she loves" -- DialogueDB.gd:680, GameData.gd:370-372).
#     Confirmed in canon.
#   - Klong: owner rule below overrides a stale "he loves it" comment
#     that existed in GameData.gd (now fixed to "she") -- was a leftover
#     inconsistency, not an actual design intent.
#   - Ek, Chang, Yaa: no established gender existed anywhere in the repo.
#   - Owner decision (2026-09-05): ALL 6 romance candidates are female;
#     all 6 of their paired rivals (yai/ohm/rung/note/fon/boon -- not
#     currently in this portrait batch) are male; the player character
#     is male.
#   - Child/Handler/Trader: genuinely unspecified in VILLAGE_LORE.md
#     (deliberately gender-neutral text). Owner: "just pick one" --
#     picked Female (child), Male (handler), Male (trader). Documented
#     here as an explicit content decision, not a silent guess, in case
#     it needs correcting later.
#   - Monk: not stated in lore; kept Male per real-world Thai Buddhist
#     monastic convention (bhikkhu) -- reasonable default, not a guess.
#   - Buffalo: an animal, not a human -- no gender descriptor needed.
BASES = {
    "elder": "pixel art portrait, elderly Thai woman, village elder, traditional conical straw hat, warm wrinkled kind face, silver hair tied back",
    "child": "pixel art portrait, young Thai girl, village child, round cheerful face, simple traditional rural clothing, carrying a small woven basket",
    "handler": "pixel art portrait, Thai man, buffalo handler, sturdy weathered face, traditional headwrap and rolled sleeves, farmer clothing",
    "monk": "pixel art portrait, Thai Buddhist monk, man, shaved head, orange and saffron colored robes, gentle face",
    "trader": "pixel art portrait, Thai man, traveling market trader, colorful traditional vest, small round hat, gold jewelry accent",
    "buffalo": "pixel art portrait, friendly water buffalo face, large curved horns, gray weathered hide",
    "ek": "pixel art portrait, young Thai woman, rice-paddy farmer, sturdy build, sun-tanned skin, straw sun hat hanging behind neck, rolled-up work sleeves",
    "fah": "pixel art portrait, young Thai woman, fisher, composed face, wide-brim woven hat, simple boatman's clothes, coiled fishing net over one shoulder",
    "ploy": "pixel art portrait, young Thai woman, dessert vendor, confident charming smile, warm expressive eyes, colorful sabai sash over traditional dress, flower tucked in her hair, apron dusted with sticky rice flour",
    "chang": "pixel art portrait, young Thai woman, wood carver, steady focused eyes, wood shavings dusting her shoulders, simple apprentice clothes, holding a small chisel",
    "klong": "pixel art portrait, young Thai woman, festival drummer, bright energetic eyes, colorful festival headband, holding a pair of drumsticks",
    "yaa": "pixel art portrait, young Thai woman, herbalist and gardener, serene gentle face, a flower tucked behind one ear, earth-toned garden clothes, small herb basket",
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
