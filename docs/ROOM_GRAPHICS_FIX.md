# Room Rampage graphics fix (V1A)

## Problem
Props looked like rectangular “frame cuts” pasted on the room, then erased —
not like smashable objects.

## Root cause
1. Prop PNGs were opaque rectangular crops of full room art
2. Instant vanish on tap (`SizedBox.shrink`)
3. Base + props used different layout spaces (`BoxFit.cover` crop vs full stage anchors)
4. Bases had pre-baked crater stickers instead of clean empty surfaces

## Fix shipped (A + B + C)

### A — Asset remask
- Tool: `tools/remask_room_props.py` (hybrid edge-flood + difference vs clean base)
- Regenerated all **120** props + **20** clean `_base.png` rooms
- Soft transparent corners on **120/120** props
- Report: `tools/room_remask_report.json`

### B — Smash juice
- Props tip / squash / fade ~280ms before removal
- Shatter shards use a color palette derived from the prop

### C — Placement
- Shared cover-fitted stage at room art aspect **1.5** (1536×1024)
- Base, scars, and props share the same coordinate space

## V1B follow-ups
- Authored broken-state sprites (`*_broken.png`)
- Textured debris sheets sampled from prop pixels
- Manual art pass for glass/transparent props (still hard to auto-mask)
