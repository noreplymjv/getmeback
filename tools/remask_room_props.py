#!/usr/bin/env python3
"""Remask Room Rampage props with hybrid edge-flood + difference vs clean base.

Produces soft silhouettes (not opaque rectangular cards) and clean empty bases.
Runtime scars stay in Flutter. See docs/ROOM_GRAPHICS_FIX.md.
"""

from __future__ import annotations

import json
import sys
from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
ROOMS = ROOT / "assets" / "rooms"
PROPS = ROOMS / "props"

sys.path.insert(0, str(ROOT / "tools"))
from generate_room_sprites import HOTSPOTS, prop_box  # noqa: E402


def color_dist(a: tuple[int, ...], b: tuple[int, ...]) -> int:
    return abs(a[0] - b[0]) + abs(a[1] - b[1]) + abs(a[2] - b[2])


def clean_inpaint(base: Image.Image, box: tuple[int, int, int, int]) -> None:
    x0, y0, x1, y1 = box
    w, h = base.size
    pad = max(8, int((x1 - x0) * 0.15))
    ex0, ey0 = max(0, x0 - pad), max(0, y0 - pad)
    ex1, ey1 = min(w, x1 + pad), min(h, y1 + pad)
    px = base.load()
    samples: list[tuple[int, int, int]] = []
    for x in range(ex0, ex1, 2):
        for y in (ey0, max(ey0, ey1 - 1)):
            if not (x0 <= x < x1 and y0 <= y < y1):
                samples.append(px[x, y][:3])
    for y in range(ey0, ey1, 2):
        for x in (ex0, max(ex0, ex1 - 1)):
            if not (x0 <= x < x1 and y0 <= y < y1):
                samples.append(px[x, y][:3])
    fill = (
        tuple(sum(c[i] for c in samples) // len(samples) for i in range(3))
        if samples
        else (90, 80, 70)
    )
    ImageDraw.Draw(base).rectangle((x0, y0, x1 - 1, y1 - 1), fill=fill)
    region = base.crop((max(0, x0 - 5), max(0, y0 - 5), min(w, x1 + 5), min(h, y1 + 5)))
    blurred = region.filter(ImageFilter.GaussianBlur(radius=5))
    bx0, by0 = max(0, x0 - 5), max(0, y0 - 5)
    for yy in range(y0, y1):
        for xx in range(x0, x1):
            d = min(xx - x0, x1 - 1 - xx, yy - y0, y1 - 1 - yy)
            t = min(1.0, d / 8.0) if d < 8 else 1.0
            br, bg, bb = blurred.getpixel((xx - bx0, yy - by0))[:3]
            fr, fg, fb = fill
            px[xx, yy] = (
                int(br * (1 - t) + fr * t),
                int(bg * (1 - t) + fg * t),
                int(bb * (1 - t) + fb * t),
            )


def edge_flood_bg(rgba: Image.Image, tol: int = 62) -> list[list[bool]]:
    w, h = rgba.size
    px = rgba.load()
    border: list[tuple[int, int, int]] = []
    for x in range(w):
        border.append(px[x, 0][:3])
        border.append(px[x, h - 1][:3])
    for y in range(h):
        border.append(px[0, y][:3])
        border.append(px[w - 1, y][:3])
    bg = tuple(sum(c[i] for c in border) // len(border) for i in range(3))
    visited = [[False] * w for _ in range(h)]
    q: deque[tuple[int, int]] = deque()
    bgm = [[False] * w for _ in range(h)]

    def seed(x: int, y: int) -> None:
        if visited[y][x]:
            return
        r, g, b, a = px[x, y]
        if a == 0 or color_dist((r, g, b), bg) <= tol:
            visited[y][x] = True
            q.append((x, y))

    for x in range(w):
        seed(x, 0)
        seed(x, h - 1)
    for y in range(h):
        seed(0, y)
        seed(w - 1, y)
    while q:
        x, y = q.popleft()
        bgm[y][x] = True
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < w and 0 <= ny < h and not visited[ny][nx]:
                r, g, b, a = px[nx, ny]
                if a == 0 or color_dist((r, g, b), bg) <= tol:
                    visited[ny][nx] = True
                    q.append((nx, ny))
                else:
                    visited[ny][nx] = True
    return bgm


def _near_bg(bgm: list[list[bool]], x: int, y: int, w: int, h: int, rad: int) -> bool:
    for dy in range(-rad, rad + 1):
        for dx in range(-rad, rad + 1):
            xx, yy = x + dx, y + dy
            if 0 <= xx < w and 0 <= yy < h and bgm[yy][xx]:
                return True
    return False


def hybrid_sprite(room_crop: Image.Image, base_crop: Image.Image) -> Image.Image:
    room = room_crop.convert("RGBA")
    base = base_crop.convert("RGB")
    w, h = room.size
    rp, bp = room.load(), base.load()
    bgm = edge_flood_bg(room, tol=62)
    out = Image.new("RGBA", (w, h))
    op = out.load()
    for y in range(h):
        for x in range(w):
            r, g, b, _ = rp[x, y]
            br, bg, bb = bp[x, y]
            d = abs(r - br) + abs(g - bg) + abs(b - bb)
            if bgm[y][x] or d < 22:
                op[x, y] = (r, g, b, 0)
            elif d < 50 or _near_bg(bgm, x, y, w, h, 2):
                a = int(255 * min(1.0, (d - 22) / 28)) if not bgm[y][x] else 40
                if _near_bg(bgm, x, y, w, h, 2):
                    a = min(a, 120)
                op[x, y] = (r, g, b, max(0, min(255, a)))
            else:
                op[x, y] = (r, g, b, 255)
    for x in range(w):
        op[x, 0] = (op[x, 0][0], op[x, 0][1], op[x, 0][2], 0)
        op[x, h - 1] = (op[x, h - 1][0], op[x, h - 1][1], op[x, h - 1][2], 0)
    for y in range(h):
        op[0, y] = (op[0, y][0], op[0, y][1], op[0, y][2], 0)
        op[w - 1, y] = (op[w - 1, y][0], op[w - 1, y][1], op[w - 1, y][2], 0)
    bbox = out.getbbox()
    if bbox:
        l, t, r, b = bbox
        out = out.crop((max(0, l - 1), max(0, t - 1), min(w, r + 1), min(h, b + 1)))
    return out


def process_room(room_id: str) -> dict:
    src = ROOMS / f"{room_id}.png"
    if not src.exists():
        return {"room": room_id, "error": "missing"}
    room = Image.open(src).convert("RGB")
    w, h = room.size
    boxes = [(pid, prop_box(w, h, nx, ny, pid)) for pid, (nx, ny) in HOTSPOTS[room_id].items()]
    boxes.sort(key=lambda it: (it[1][2] - it[1][0]) * (it[1][3] - it[1][1]), reverse=True)
    base = room.copy()
    for _, box in boxes:
        clean_inpaint(base, box)
    base.save(ROOMS / f"{room_id}_base.png", optimize=True)
    PROPS.mkdir(parents=True, exist_ok=True)
    soft = 0
    paths = []
    for pid, box in boxes:
        spr = hybrid_sprite(room.crop(box), base.crop(box))
        out = PROPS / f"{room_id}_{pid}.png"
        spr.save(out, optimize=True)
        paths.append(str(out.relative_to(ROOT)))
        s = spr.convert("RGBA")
        sw, sh = s.size
        px = s.load()
        corners = [px[0, 0][3], px[sw - 1, 0][3], px[0, sh - 1][3], px[sw - 1, sh - 1][3]]
        if sum(1 for a in corners if a < 40) >= 3:
            soft += 1
    return {
        "room": room_id,
        "soft": soft,
        "count": len(paths),
        "size": [w, h],
        "props": paths,
    }


def main() -> None:
    results = [process_room(r) for r in HOTSPOTS]
    soft = sum(r.get("soft", 0) for r in results)
    total = sum(r.get("count", 0) for r in results)
    report = {"rooms": results, "totals": {"soft": soft, "props": total}}
    (ROOT / "tools" / "room_remask_report.json").write_text(json.dumps(report, indent=2))
    print(f"Hybrid remask: {soft}/{total} soft-corner props across {len(results)} rooms")


if __name__ == "__main__":
    main()
