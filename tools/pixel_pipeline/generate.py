"""Stage 1 CLI: ComfyUI concept generation with repo-defended prompt templates.

Failure-mode defenses baked in (docs/art/pixel_art_pipeline.md):
- #3/#4: "single subject only, one object, centered" + negative scene/decoration
- #7: "bold saturated colors, vivid not pale" (warm-neutral subjects)
- #9: occupation subjects never carry the entity noun ("buffalo handler" -> "farmer")
- #10: "plain flat pure white background" language

Usage:
  python generate.py --subject "clay cooking stove" --out /tmp/stove.png
  python generate.py --tile-subject "dry cracked earth" --out /tmp/earth.png
  python generate.py --subject "..." --lora my-pixel-lora.safetensors --steps 20
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from comfy_client import ComfyClient, build_txt2img_workflow, DEFAULT_POS_TMPL, DEFAULT_NEG

# failure mode #9: occupation subjects must not carry the entity noun
ENTITY_NOUNS = {
    "buffalo", "horse", "monkey", "cat", "goat", "chicken", "fish",
    "elephant", "dog", "duck", "frog", "monk",
}


def defend_subject(subject: str) -> str:
    """Strip entity nouns from multi-word occupation-style subjects (#9)."""
    words = subject.split()
    if len(words) > 2:
        kept = [w for w in words if w.lower().strip(",.") not in ENTITY_NOUNS]
        if kept and kept != words:
            return defend_subject(" ".join(kept))
    return subject


def main() -> int:
    ap = argparse.ArgumentParser(description="Stage 1: ComfyUI concept render")
    mode = ap.add_mutually_exclusive_group(required=True)
    mode.add_argument("--subject", help="single-object subject to generate")
    mode.add_argument("--tile-subject", help="seamless tile pattern to generate")
    ap.add_argument("--out", required=True)
    ap.add_argument("--checkpoint", default=None, help="checkpoint filename in ComfyUI/models/checkpoints")
    ap.add_argument("--lora", default=None, help="LoRA filename in ComfyUI/models/loras")
    ap.add_argument("--steps", type=int, default=20)
    ap.add_argument("--cfg", type=float, default=7.0)
    ap.add_argument("--size", type=int, default=512)
    ap.add_argument("--base", default=None, help="ComfyUI base URL override")
    args = ap.parse_args()

    client = ComfyClient(args.base) if args.base else ComfyClient()
    if not client.alive():
        print(f"ERROR: ComfyUI not reachable at {client.base}", file=sys.stderr)
        print("Start it:  cd ~/ComfyUI && ~/.venvs/artpipe/bin/python main.py --cpu --listen 127.0.0.1 --port 8188")
        print("(first run downloads ~1.2GB of SD1.5 text-encoder/VAE files into ComfyUI/models/)")
        return 2

    # pick a checkpoint automatically if none given
    checkpoint = args.checkpoint
    if checkpoint is None:
        ckpt_dir = Path.home() / "ComfyUI/models/checkpoints"
        cands = sorted(p.name for p in ckpt_dir.glob("*.safetensors")) if ckpt_dir.exists() else []
        checkpoint = cands[0] if cands else "v1-5-pruned-emaonly-fp16.safetensors"

    # auto-pick a pixel-art LoRA if one is present and none specified
    lora = args.lora
    if lora is None:
        lora_dir = Path.home() / "ComfyUI/models/loras"
        if lora_dir.exists():
            for cand in sorted(lora_dir.glob("*pixel*.safetensors")):
                lora = cand.name
                break

    subject = defend_subject(args.subject or args.tile_subject or "")
    if args.tile_subject:
        positive = (
            f"seamless repeating tileable pattern of {subject}, full-bleed, "
            "edge-to-edge, no border, no frame, no vignette, "
            "bold saturated colors, vivid not pale, thai rural countryside style"
        )
        negative = "horizon, sky, border, frame, vignette, perspective, " + DEFAULT_NEG
    else:
        positive = DEFAULT_POS_TMPL.format(subject=subject)
        negative = DEFAULT_NEG

    wf = build_txt2img_workflow(
        positive=positive,
        negative=negative,
        checkpoint=checkpoint,
        lora=lora,
        width=args.size,
        height=args.size,
        steps=args.steps,
        cfg=args.cfg,
    )
    png = client.generate(wf)
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_bytes(png)
    print(f"OK {out}: concept render saved ({len(png)} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
