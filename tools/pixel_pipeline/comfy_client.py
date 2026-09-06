"""ComfyUI API client — stage 1 concept generation.

Talks to a local ComfyUI instance (http://127.0.0.1:8188) over its HTTP API:
POST /prompt -> poll /history/{id} -> GET /view. The workflow is a minimal
SD1.5 txt2img graph with an optional pixel-art LoRA slot, prompt language
defensively written against this repo's documented failure modes
(docs/art/pixel_art_pipeline.md #3/#4/#7/#9/#10).
"""
from __future__ import annotations

import json
import random
import time
import urllib.parse
import urllib.request
from typing import Any, Dict, Optional

DEFAULT_BASE = "http://127.0.0.1:8188"
DEFAULT_CHECKPOINT = "v1-5-pruned-emaonly-fp16.safetensors"
DEFAULT_NEG = (
    "scene, scenery, horizon, sky, ground, landscape, background details, "
    "multiple objects, extra objects, decoration, decorations, frame, border, "
    "text, watermark, signature, blur, photo, realistic, "
    "pale, washed out, low contrast, faded, gradient background, "
    "detailed background, shadows on ground"
)

# failure-mode #7: warm-neutral subjects wash out — bake anti-pale language in
DEFAULT_POS_TMPL = (
    "pixel art sprite of {subject}, single subject only, one object, centered, "
    "full silhouette visible, plain flat pure white background, "
    "bold simple shapes, minimal detail, chunky pixels, crisp edges, "
    "bold saturated colors, vivid not pale, "
    "thai rural countryside style, game asset"
)


def build_txt2img_workflow(
    positive: str,
    negative: str = DEFAULT_NEG,
    checkpoint: str = DEFAULT_CHECKPOINT,
    lora: Optional[str] = None,
    lora_strength: float = 0.8,
    width: int = 512,
    height: int = 512,
    steps: int = 20,
    cfg: float = 7.0,
    seed: Optional[int] = None,
) -> Dict[str, Any]:
    """API-format graph: checkpoint -> (optional LoRA) -> KSampler -> VAEDecode -> SaveImage."""
    seed = seed if seed is not None else random.randint(0, 2**31 - 1)
    wf: Dict[str, Any] = {
        "7": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": checkpoint}},
        "10": {
            "class_type": "CLIPTextEncode",
            "inputs": {"text": positive, "clip": ["7", 1]},
        },
        "11": {
            "class_type": "CLIPTextEncode",
            "inputs": {"text": negative, "clip": ["7", 1]},
        },
        "4": {
            "class_type": "EmptyLatentImage",
            "inputs": {"width": width, "height": height, "batch_size": 1},
        },
        "3": {
            "class_type": "KSampler",
            "inputs": {
                "seed": seed,
                "steps": steps,
                "cfg": cfg,
                "sampler_name": "dpmpp_2m",
                "scheduler": "karras",
                "denoise": 1.0,
                "model": ["20", 0] if lora else ["7", 0],
                "positive": ["10", 0],
                "negative": ["11", 0],
                "latent_image": ["4", 0],
            },
        },
        "8": {"class_type": "VAEDecode", "inputs": {"samples": ["3", 0], "vae": ["7", 2]}},
        "9": {
            "class_type": "SaveImage",
            "inputs": {"filename_prefix": "pipeline/concept", "images": ["8", 0]},
        },
    }
    if lora:
        wf["20"] = {
            "class_type": "LoraLoader",
            "inputs": {
                "lora_name": lora,
                "strength_model": lora_strength,
                "strength_clip": lora_strength,
                "model": ["7", 0],
                "clip": ["7", 1],
            },
        }
    return wf


class ComfyClient:
    def __init__(self, base: str = DEFAULT_BASE, timeout: int = 300):
        self.base = base.rstrip("/")
        self.timeout = timeout

    def alive(self) -> bool:
        try:
            with urllib.request.urlopen(f"{self.base}/system_stats", timeout=3) as r:
                return r.status == 200
        except Exception:
            return False

    def generate(self, workflow: Dict[str, Any], poll_every: float = 1.0) -> bytes:
        """Queue a prompt, block until done, return the PNG bytes of the first image."""
        body = json.dumps({"prompt": workflow}).encode()
        req = urllib.request.Request(
            f"{self.base}/prompt", data=body, headers={"Content-Type": "application/json"}
        )
        with urllib.request.urlopen(req, timeout=30) as r:
            resp = json.loads(r.read())
        prompt_id = resp["prompt_id"]
        deadline = time.time() + self.timeout
        while time.time() < deadline:
            with urllib.request.urlopen(f"{self.base}/history/{prompt_id}", timeout=15) as r:
                hist = json.loads(r.read())
            if prompt_id in hist:
                outputs = hist[prompt_id].get("outputs", {})
                for node_out in outputs.values():
                    for img in node_out.get("images", []):
                        if img.get("type") == "output":
                            q = urllib.parse.urlencode(
                                {
                                    "filename": img["filename"],
                                    "subfolder": img.get("subfolder", ""),
                                    "type": img.get("type", "output"),
                                }
                            )
                            with urllib.request.urlopen(
                                f"{self.base}/view?{q}", timeout=30
                            ) as vr:
                                return vr.read()
                if outputs:
                    raise RuntimeError(f"prompt {prompt_id} finished with no output images")
            time.sleep(poll_every)
        raise TimeoutError(f"comfyui prompt {prompt_id} did not finish in {self.timeout}s")
