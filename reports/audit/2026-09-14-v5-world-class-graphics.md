# GetMeBack v5 — World-Class Smash Graphics

**Date:** 2026-09-14
**Branch:** `v5` (forked from `v3a` @ `5be0894`)
**Package:** `5.0.0-v5+15` · **Badge:** `v5 · 5.0.0`
**Live slot (only):** https://noreplymjv.github.io/getmeback/v5/

## Objective

Ship a visibly upgraded, "world-class" smash/rampage FX pass as an isolated
GitHub Pages slot (`/v5/`) without touching or redeploying `/`, `/v2/`, `/v3/`,
`/v3a/`, or the reserved-unused `/v4/` slot. Graphics-only + version/deploy-doc
scope; no runtime image-gen APIs, no secrets, web-safe (CanvasKit).

## OmniRoute (Lane 2) recommendations → what shipped

| # | Auditor recommendation | Implementation |
|---|------------------------|----------------|
| 1 | Hit lighting flash at impact (screen blend, 100–150 ms) | `_ImpactFlashPainter` — additive (`BlendMode.plus`) radial hot bloom anchored at the impact point + soft warm wash; flash decay tightened to ~120 ms. `flashPoint` now tracked in `DramaticFxController`. |
| 2 | Cinematic vignette that pulses on big hits | New `vignettePulse` state on the controller (spikes on `intensity ≥ 1.2` impacts + all `megaImpact`s, fast ~3.4/s decay). Vignette gradient reworked to darken/tighten on pulse plus a warm rim glow overlay. |
| 3 | Shockwave ring expanding + fading (300–500 ms) | Richer shockwave painter: soft pressure disc behind the leading edge, a trailing echo ring, blurred outer front + crisp white leading edge. Uses existing `FxShockwave` lifetimes. |
| 4 | Better crack decals (varied patterns, rotation/scale) | `FxCrack` now renders a seeded **jagged, branching** polyline (splinter branches) with a bright inner core instead of a single straight line. Persistent `DestructionScarsLayer` decals get per-scar seeded **rotation + scale** so no two smashes look identical. |
| 5 | More realistic shards (material color, bevel/edge highlight — Canvas) | `prop_shatter_fx` shards now use a material-colored **bevel gradient** (lit facet → shaded edge) plus a specular edge glint and lit top-left highlight on wood chunks. |

## Files changed (graphics)

- `lib/widgets/dramatic_fx.dart` — radial impact flash (`_ImpactFlashPainter`),
  `flashPoint` + `vignettePulse` controller state and decay, reworked vignette
  gradient + warm rim, richer shockwave rendering, seeded jagged/branching
  `FxCrack` path with bright core.
- `lib/widgets/prop_shatter_fx.dart` — beveled material-gradient shards, edge
  glint, wood bevel highlights (`_poly(..., bevel: true)`).
- `lib/widgets/prop_destruction_scars.dart` — per-scar rotation/scale variety.
- `lib/widgets/interactive_room_prop.dart` — reviewed (already branch-cracks);
  untouched code-wise this pass.
- `lib/vent_scenes/room_rampage_scene.dart` — reviewed; drives the enhanced FX
  through existing `fx.impact` / `fx.megaImpact` / `fx.triggerShockwave` calls
  (impact point now feeds the radial flash).

## Version / deploy docs

- `lib/utils/app_version.dart` → `marketing v5`, `package 5.0.0-v5`, `badge v5 · 5.0.0`.
- `pubspec.yaml` → `version: 5.0.0-v5+15` (drives web `version.json`).
- `scripts/deploy-github-pages.sh` → `versions.html` lists **v5 (recommended)**
  and keeps v3a/v3/v2/root; header + chooser note that `/v4/` is reserved/unused.
- `LIVE_HOSTING.md` → v5 recommended row + v4-reserved note + redeploy commands.

## Accessibility / safety

- All new motion (flash, vignette pulse, chromatic, shake) is gated by
  `MediaQuery.disableAnimations` via `VentFxLayer` (reduced-motion respected).
- Pure `CustomPainter` / `RadialGradient` / `MaskFilter.blur` — CanvasKit-safe,
  no plugins, no network, no secrets.

## Verification

- `flutter analyze` on the 6 touched files → **No issues found** (portable SDK).
- `graphify update .` → graph rebuilt (13,474 nodes / 48,747 edges).
- Deployed only via `./scripts/deploy-github-pages.sh v5`.
- Live checks: `/v5/` reachable, `/v5/version.json` = `5.0.0-v5` (+15);
  `/v3a/` unchanged; `/v4/` still 404 (reserved).

### Live results (verified 2026-09-14)

| Endpoint | Result |
|----------|--------|
| `GET /v5/` | `200` |
| `GET /v5/version.json` | `{"version":"5.0.0-v5","build_number":"15",...}` ✅ |
| `GET /v3a/version.json` | `3.0.0-v3a` (+14) — **unchanged** ✅ |
| `GET /v3a/` | `200` — unchanged ✅ |
| `GET /v4/` | `404` — reserved/unused, untouched ✅ |

- Branch `v5` pushed to `origin/v5` (commit `d9291b7`).
- Deploy performed with `./scripts/deploy-github-pages.sh v5` only; the script
  clones the existing `gh-pages` tree and writes solely into `/v5/` +
  `versions.html`, so `/`, `/v2/`, `/v3/`, `/v3a/`, `/v4/` remain as-is.

**Live (recommended):** https://noreplymjv.github.io/getmeback/v5/
