#!/usr/bin/env python3
"""Generate clean room bases + cropped prop sprites from illustrated room PNGs."""

from __future__ import annotations

import json
import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
ROOMS = ROOT / "assets" / "rooms"
PROPS = ROOMS / "props"

# Mirrors lib/models/room_hotspots.dart + prop_sprite_catalog.dart
HOTSPOTS: dict[str, dict[str, tuple[float, float]]] = {
    "kitchen": {
        "glass": (0.17, 0.56),
        "plate": (0.44, 0.52),
        "mug": (0.56, 0.48),
        "blender": (0.30, 0.40),
        "chair": (0.83, 0.50),
        "table": (0.47, 0.54),
    },
    "bathroom": {
        "mirror": (0.50, 0.22),
        "glass": (0.72, 0.38),
        "bottle": (0.68, 0.42),
        "soap": (0.58, 0.40),
        "toilet": (0.78, 0.62),
        "towel": (0.22, 0.35),
    },
    "office": {
        "monitor": (0.52, 0.38),
        "keyboard": (0.50, 0.48),
        "mug": (0.38, 0.46),
        "chair": (0.48, 0.62),
        "lamp": (0.18, 0.32),
        "plant": (0.82, 0.55),
    },
    "cabin": {
        "lantern": (0.22, 0.35),
        "mug": (0.48, 0.52),
        "chair": (0.62, 0.58),
        "table": (0.45, 0.55),
        "window": (0.78, 0.32),
        "logs": (0.28, 0.68),
    },
    "living": {
        "tv": (0.70, 0.36),
        "sofa": (0.30, 0.50),
        "glass": (0.50, 0.56),
        "vase": (0.74, 0.46),
        "lamp": (0.14, 0.40),
        "remote": (0.42, 0.58),
    },
    "bedroom": {
        "lamp": (0.18, 0.38),
        "clock": (0.72, 0.28),
        "mirror": (0.82, 0.32),
        "pillow": (0.38, 0.52),
        "frame": (0.55, 0.30),
        "glass": (0.62, 0.48),
    },
    "garage": {
        "can": (0.22, 0.62),
        "toolbox": (0.42, 0.58),
        "shelf": (0.72, 0.35),
        "bulb": (0.50, 0.22),
        "bucket": (0.58, 0.65),
        "chair": (0.35, 0.68),
    },
    "dining": {
        "plate": (0.48, 0.52),
        "glass": (0.38, 0.48),
        "chandelier": (0.50, 0.18),
        "chair": (0.28, 0.58),
        "table": (0.50, 0.55),
        "vase": (0.62, 0.46),
    },
    "hotel": {
        "minibar": (0.78, 0.48),
        "glass": (0.72, 0.52),
        "tv": (0.22, 0.38),
        "lamp": (0.15, 0.42),
        "tray": (0.48, 0.50),
        "phone": (0.55, 0.48),
    },
    "classroom": {
        "board": (0.50, 0.28),
        "desk": (0.35, 0.55),
        "chair": (0.38, 0.62),
        "globe": (0.72, 0.48),
        "books": (0.62, 0.52),
        "apple": (0.42, 0.50),
    },
    "locker": {
        "locker": (0.35, 0.42),
        "bottle": (0.55, 0.55),
        "bench": (0.48, 0.62),
        "mirror": (0.78, 0.32),
        "scale": (0.22, 0.58),
        "towel": (0.68, 0.48),
    },
    "cafe": {
        "cup": (0.42, 0.50),
        "chair": (0.28, 0.58),
        "table": (0.45, 0.54),
        "pastry": (0.52, 0.48),
        "sign": (0.18, 0.30),
        "glass": (0.48, 0.46),
    },
    "studio": {
        "fridge": (0.18, 0.48),
        "bed": (0.62, 0.52),
        "glass": (0.48, 0.55),
        "lamp": (0.38, 0.38),
        "speaker": (0.72, 0.58),
        "plant": (0.82, 0.45),
    },
    "gameroom": {
        "console": (0.48, 0.58),
        "controller": (0.42, 0.52),
        "tv": (0.50, 0.32),
        "chair": (0.35, 0.62),
        "snack": (0.58, 0.50),
        "can": (0.65, 0.55),
    },
    "laundry": {
        "washer": (0.32, 0.52),
        "dryer": (0.48, 0.52),
        "basket": (0.22, 0.62),
        "detergent": (0.58, 0.42),
        "iron": (0.72, 0.48),
        "shelf": (0.78, 0.32),
    },
    "balcony": {
        "plant": (0.22, 0.55),
        "chair": (0.42, 0.58),
        "glass": (0.50, 0.52),
        "table": (0.48, 0.55),
        "lantern": (0.68, 0.42),
        "rail": (0.50, 0.72),
    },
    "workshop": {
        "saw": (0.35, 0.52),
        "bench": (0.48, 0.58),
        "jar": (0.62, 0.45),
        "radio": (0.22, 0.42),
        "shelf": (0.78, 0.35),
        "can": (0.55, 0.65),
    },
    "penthouse": {
        "sculpture": (0.28, 0.48),
        "glass": (0.50, 0.52),
        "sofa": (0.62, 0.50),
        "window": (0.50, 0.28),
        "lamp": (0.18, 0.42),
        "vase": (0.72, 0.46),
    },
    "dorm": {
        "laptop": (0.42, 0.50),
        "ramen": (0.52, 0.48),
        "poster": (0.22, 0.28),
        "chair": (0.35, 0.58),
        "fridge": (0.78, 0.48),
        "lamp": (0.62, 0.38),
    },
    "server": {
        "rack": (0.35, 0.42),
        "monitor": (0.55, 0.48),
        "keyboard": (0.52, 0.55),
        "cable": (0.48, 0.62),
        "coffee": (0.72, 0.52),
        "fan": (0.82, 0.38),
    },
}

LAYOUT: dict[str, tuple[float, float]] = {
    "apple": (0.07, 1.0),
    "basket": (0.14, 1.0),
    "bed": (0.32, 0.65),
    "bench": (0.22, 0.45),
    "blender": (0.11, 1.25),
    "board": (0.38, 0.55),
    "books": (0.12, 0.8),
    "bottle": (0.08, 1.4),
    "bucket": (0.12, 1.1),
    "bulb": (0.07, 1.0),
    "cable": (0.16, 0.35),
    "can": (0.09, 1.2),
    "chair": (0.16, 1.15),
    "chandelier": (0.18, 1.4),
    "clock": (0.08, 1.0),
    "coffee": (0.08, 1.05),
    "console": (0.14, 0.55),
    "controller": (0.08, 0.65),
    "cup": (0.09, 1.05),
    "desk": (0.28, 0.55),
    "detergent": (0.09, 1.3),
    "dryer": (0.18, 1.1),
    "fan": (0.12, 1.0),
    "frame": (0.10, 0.75),
    "fridge": (0.16, 1.35),
    "glass": (0.08, 1.35),
    "globe": (0.11, 1.0),
    "iron": (0.10, 1.1),
    "jar": (0.08, 1.2),
    "keyboard": (0.14, 0.35),
    "lamp": (0.10, 1.2),
    "lantern": (0.09, 1.15),
    "laptop": (0.14, 0.65),
    "locker": (0.22, 1.4),
    "logs": (0.16, 0.45),
    "minibar": (0.14, 1.2),
    "mirror": (0.16, 1.25),
    "monitor": (0.18, 0.85),
    "mug": (0.09, 1.05),
    "phone": (0.07, 1.4),
    "pillow": (0.12, 0.75),
    "plant": (0.12, 1.1),
    "plate": (0.14, 0.35),
    "poster": (0.14, 0.75),
    "pastry": (0.08, 0.85),
    "rack": (0.22, 1.35),
    "radio": (0.09, 0.85),
    "rail": (0.34, 0.25),
    "ramen": (0.09, 0.95),
    "remote": (0.07, 0.45),
    "saw": (0.14, 0.55),
    "scale": (0.10, 1.0),
    "sculpture": (0.12, 1.3),
    "shelf": (0.20, 0.45),
    "sign": (0.12, 0.85),
    "snack": (0.08, 0.9),
    "soap": (0.08, 0.75),
    "sofa": (0.28, 0.55),
    "speaker": (0.10, 0.85),
    "table": (0.38, 0.55),
    "toilet": (0.14, 1.0),
    "toolbox": (0.12, 0.85),
    "towel": (0.14, 0.65),
    "tray": (0.12, 0.45),
    "tv": (0.22, 0.75),
    "vase": (0.10, 1.25),
    "washer": (0.18, 1.05),
    "window": (0.22, 1.1),
}


def layout_for(prop_id: str) -> tuple[float, float]:
    return LAYOUT.get(prop_id, (0.11, 1.0))


def prop_box(w: int, h: int, nx: float, ny: float, prop_id: str) -> tuple[int, int, int, int]:
    size_norm, aspect = layout_for(prop_id)
    bw = max(24, int(w * size_norm))
    bh = max(24, int(bw * aspect))
    cx = int(nx * w)
    cy = int(ny * h)
    x0 = max(0, cx - bw // 2)
    y0 = max(0, cy - bh // 2)
    x1 = min(w, x0 + bw)
    y1 = min(h, y0 + bh)
    return x0, y0, x1, y1


def make_transparent_sprite(crop: Image.Image) -> Image.Image:
    rgba = crop.convert("RGBA")
    w, h = rgba.size
    corners = [
        rgba.getpixel((0, 0)),
        rgba.getpixel((w - 1, 0)),
        rgba.getpixel((0, h - 1)),
        rgba.getpixel((w - 1, h - 1)),
    ]
    bg = tuple(sum(c[i] for c in corners) // 4 for i in range(3))
    px = rgba.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            dist = abs(r - bg[0]) + abs(g - bg[1]) + abs(b - bg[2])
            if dist < 42:
                px[x, y] = (r, g, b, 0)
    return rgba


def _border_color(img: Image.Image, box: tuple[int, int, int, int]) -> tuple[int, int, int]:
    x0, y0, x1, y1 = box
    w, h = img.size
    pad = max(8, int((x1 - x0) * 0.15))
    ex0 = max(0, x0 - pad)
    ey0 = max(0, y0 - pad)
    ex1 = min(w, x1 + pad)
    ey1 = min(h, y1 + pad)
    px = img.load()
    samples: list[tuple[int, int, int]] = []
    for x in range(ex0, ex1, 4):
        for y in (ey0, ey1 - 1):
            if 0 <= y < h:
                samples.append(px[x, y][:3])
        for y in range(ey0, ey1, 4):
            for x2 in (ex0, ex1 - 1):
                if 0 <= x2 < w:
                    samples.append(px[x2, y][:3])
    if not samples:
        return (120, 100, 80)
    return tuple(sum(c[i] for c in samples) // len(samples) for i in range(3))


def damage_region(base: Image.Image, box: tuple[int, int, int, int], prop_id: str, rng) -> None:
    """Replace prop footprint with surface colour + visible wreckage, not blur."""
    x0, y0, x1, y1 = box
    fill = _border_color(base, box)
    draw = ImageDraw.Draw(base)
    draw.rectangle((x0, y0, x1, y1), fill=fill)

    cx = (x0 + x1) // 2
    cy = (y0 + y1) // 2
    bw, bh = x1 - x0, y1 - y0
    dark = tuple(max(0, c - 55) for c in fill)
    deeper = tuple(max(0, c - 90) for c in fill)

    # Impact crater
    draw.ellipse(
        (cx - bw * 0.18, cy - bh * 0.15, cx + bw * 0.18, cy + bh * 0.15),
        fill=deeper,
    )

    # Radial cracks
    for _ in range(6 + rng.randint(0, 4)):
        angle = rng.random() * 6.283
        length = max(bw, bh) * (0.35 + rng.random() * 0.55)
        ex = cx + int(length * __import__("math").cos(angle))
        ey = cy + int(length * __import__("math").sin(angle))
        draw.line((cx, cy, ex, ey), fill=dark, width=1 + rng.randint(0, 2))

    # Chip specks
    for _ in range(8 + rng.randint(0, 8)):
        px = cx + int((rng.random() - 0.5) * bw * 0.9)
        py = cy + int((rng.random() - 0.5) * bh * 0.9)
        chip = 2 + rng.randint(0, 3)
        tone = tuple(min(255, c + rng.randint(20, 60)) for c in fill)
        draw.ellipse((px - chip, py - chip, px + chip, py + chip), fill=tone)

    # Wood / metal accents
    if prop_id in {"chair", "table", "desk", "bench", "shelf", "logs", "saw", "rail"}:
        for i in range(-2, 3):
            y = cy + int(i * bh * 0.12)
            draw.line((x0 + 2, y, x1 - 2, y + rng.randint(-2, 2)), fill=dark, width=2)
    if prop_id in {"blender", "monitor", "tv", "iron", "fan", "washer", "dryer"}:
        draw.ellipse(
            (cx - bw * 0.28, cy - bh * 0.22, cx + bw * 0.28, cy + bh * 0.22),
            outline=dark,
            width=2,
        )

    # Subtle grain so it reads as surface, not fog
    region = base.crop((x0, y0, x1, y1))
    noisy = region.filter(ImageFilter.GaussianBlur(radius=0.6))
    base.paste(noisy, (x0, y0))


def blur_region(base: Image.Image, box: tuple[int, int, int, int]) -> None:
    """Legacy alias — kept for compatibility."""
    damage_region(base, box, "generic", __import__("random").Random())


def process_room(room_id: str) -> dict:
    src_path = ROOMS / f"{room_id}.png"
    if not src_path.exists():
        return {"room": room_id, "error": "missing source png"}

    room = Image.open(src_path).convert("RGB")
    w, h = room.size
    spots = HOTSPOTS[room_id]
    boxes = [(pid, prop_box(w, h, nx, ny, pid)) for pid, (nx, ny) in spots.items()]
    boxes.sort(key=lambda item: (item[1][2] - item[1][0]) * (item[1][3] - item[1][1]), reverse=True)

    PROPS.mkdir(parents=True, exist_ok=True)
    prop_paths: list[str] = []
    for pid, box in boxes:
        crop = room.crop(box)
        sprite = make_transparent_sprite(crop)
        out = PROPS / f"{room_id}_{pid}.png"
        sprite.save(out, optimize=True)
        prop_paths.append(str(out.relative_to(ROOT)))

    base = room.copy()
    rng = __import__("random").Random(hash(room_id) & 0xFFFFFFFF)
    for pid, box in boxes:
        damage_region(base, box, pid, rng)
    base_path = ROOMS / f"{room_id}_base.png"
    base.save(base_path, optimize=True)

    return {
        "room": room_id,
        "base": str(base_path.relative_to(ROOT)),
        "props": prop_paths,
        "count": len(prop_paths),
    }


def main() -> None:
    results = [process_room(room_id) for room_id in HOTSPOTS]
    manifest = ROOT / "tools" / "room_sprite_manifest.json"
    manifest.write_text(json.dumps(results, indent=2))
    ok = sum(1 for r in results if "error" not in r)
    total_props = sum(r.get("count", 0) for r in results)
    print(f"Generated {ok}/{len(results)} room bases and {total_props} prop sprites")


if __name__ == "__main__":
    main()
