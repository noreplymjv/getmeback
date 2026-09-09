# GetMeBack v3 — Room visuals + Kintsugi (suggestions only)

**Date:** 2026-09-09  
**Live checked:** https://noreplymjv.github.io/getmeback/v3/  
**Branch:** `v3`  
**Status:** Recommendations only — **no code changes made**

---

## Verdict

**Keep Kintsugi in v3** — it is the right emotional payoff after smash/calm (mend with gold).  
**Do not polish Kintsugi first.** Room Rampage visuals are currently broken at a product level: smashable **prop sprites are not drawn**, so rooms look like empty photos with HUD labels/reticles.

Fix rooms (sprites) first, then upgrade Kintsugi art.

---

## What is wrong with Rooms (root cause)

Commit `d758663` (“tactical reticles and dark void craters”) heavily rewrote `lib/widgets/interactive_room_prop.dart` (−422 lines).

| Before (good) | After (current v3) |
|---------------|--------------------|
| Layered `Image.asset` prop sprites on clean `_base.png` | **No sprite `Image` at all** |
| Soft-masked smashable objects | Corner reticles + tiny text labels only |
| `spriteMode` drove visual props | `spriteMode` is still passed but **unused** |

Assets still exist and are fine for a first pass (`assets/rooms/*_base.png` + 120 props). The pipeline in `docs/ROOM_GRAPHICS_FIX.md` is still valid — the **renderer stopped using it**.

Secondary art issues (after sprites are restored):

1. **Style clash** — photoreal / 3D room bases vs cartoon Characters path.
2. **Mask quality uneven** — e.g. some glass props still look like soft rectangles (`bathroom_glass` ~7% transparent vs `dining_glass` ~62%).
3. **No broken-state art** — still vanish/shards instead of `*_broken.png` (already listed as V1B follow-up).
4. **Heavy vignette + reticle HUD** on top of empty bases makes the room feel like a debug overlay, not a smash toy.

---

## Why Kintsugi is still the better v3 addition

- Differentiates GetMeBack from pure destruction apps (Kick the Buddy clones).
- Completes the loop: **vent → breathe → mend**.
- Already wired: Calm Outro → `Mend with Gold (Kintsugi)` → `/kintsugi/:targetId`.
- Concept and copy are strong; **implementation is a flat CustomPainter circle**, not a ceramic object.

Current Kintsugi visual gaps:

| Area | Today | Needed |
|------|-------|--------|
| Bowl | Flat radial-gradient circle | Real bowl sprite / textured silhouette + stand |
| Cracks | Polyline through loose points | Authored crack paths that match the bowl |
| Gold | Free-paint strokes near points | Snap / brush-along-seam with molten gold look |
| Feedback | Progress % + confetti | Gold dust particles, soft chime, rim glow |
| Product link | Standalone bowl | Optional: mend a **smashed room prop** (plate/vase) after Rampage |

Also observed on Calm Outro: large **rectangular glow bleed** behind ShineButtons (clipped box-shadow) — cheap win when polishing that screen.

---

## Suggested fix order (do in this order)

### P0 — Restore room smash readability (must before any other visual work)

1. **Bring back prop `Image.asset(prop.resolvedSprite(roomId))`** in `InteractiveRoomProp` when `spriteMode == true`.
2. Keep reticles as a **light overlay** (holding / throw target only), not the only visual.
3. Verify smash juice + shatter still align to the sprite bounds.
4. Spot-check 3 rooms live on `/v3/` (kitchen, living, office) after redeploy.

**Success criteria:** User sees plates/glasses/furniture as objects, not empty room + labels.

### P1 — Room art QA pass (after sprites work)

1. Re-run / manually fix worst masks (glass, mirrors, plants).
2. Prefer **one visual language** for v3 rooms: either softer illustrated rooms *or* keep photo bases but grade them (warmth, contrast) so they match app chrome.
3. Add 1–2 hero `*_broken.png` states for glass/ceramic (plate, mug, vase) instead of instant empty hole.

### P2 — Upgrade Kintsugi (keep feature; raise art bar)

1. Replace circle painter with a **dedicated bowl asset** + alpha crack mask.
2. Gold brush **constrained to seams** (or magnetized to nearest seam).
3. Completion: gold fill + soft radiance + short affirmation (already there) + optional zen streak (already hooks `recordCalmCompletion`).
4. Product stretch (high value): after Room Rampage clear → offer “Mend the [vase] with gold” using that prop’s sprite as the canvas.

### P3 — Calm Outro / entry polish

1. Fix ShineButton rectangular glow.
2. Home “Rooms & Scenes” card: always show a **real room thumbnail** (kitchen already does when loaded; avoid empty gradient fallback).
3. Version badge on live site still says `V1A · 1.0.0-a1` — align with branch/marketing (`v3`) so testers know which build they are on.

---

## What not to do yet

- Do **not** add Forge2D / Voronoi / more weapons until sprites are restored.
- Do **not** remove Kintsugi — improve it after rooms read correctly.
- Do **not** ship another reticle-only UX pass.

---

## Recommended decision for v3

| Keep | Fix first | Then improve |
|------|-----------|--------------|
| Kintsugi as post-calm mend ritual | Prop sprite rendering on Room Rampage | Kintsugi bowl art + seam-gold UX |
| Smash → breath → mend loop | Reticle as overlay only | Hero broken sprites + mask QA |

When you want implementation, start with **P0 only**, redeploy `/getmeback/v3/`, then review kitchen/living before touching Kintsugi art.
