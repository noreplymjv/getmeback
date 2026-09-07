# GetMeBack — World-Class Feature Areas Audit

**Date:** 2026-09-06  
**Project:** `/media/mj/My Passport/mjI/AllProjects/GetMeBack/app`  
**Version:** `1.0.0-a1+11`  
**Method:** `graphify query` (graphify-out/graph.json present) + targeted code/docs review  

**Overall:** V1A already ships a strong local-only vent → calm loop. Against a “world-class” proposal checklist, most polish/retention pieces are **PARTIAL**; true physics, biometrics, IAP, DBT, and GPU shaders are **MISSING**.

---

## Feature matrix

### 1. Interactive destruction & physics
**Status: PARTIAL**

| Have | Missing |
|------|---------|
| Custom Canvas particle/shard FX, hit-stop, multi-stage prop destruction, material-mapped SFX/haptics intensity, scars/decals | Forge2D/Box2D, Voronoi fracture, true rigid-body collision, Core Haptics / material waveforms |

**Key files + symbols**
- `/media/mj/My Passport/mjI/AllProjects/GetMeBack/app/lib/widgets/dramatic_fx.dart` — `DramaticFxController`, `triggerHitStop`, `isHitStopped`
- `/media/mj/My Passport/mjI/AllProjects/GetMeBack/app/lib/widgets/base_vent_scene.dart` — heavy smash + hit-stop helper
- `/media/mj/My Passport/mjI/AllProjects/GetMeBack/app/lib/widgets/prop_shatter_fx.dart` — `PropShatterController`, `PropShatterStyle`, `microBurst`, floor bounce
- `/media/mj/My Passport/mjI/AllProjects/GetMeBack/app/lib/widgets/prop_destruction_scars.dart` — `DestructionScarsLayer`, `_DestructionScarsPainter`
- `/media/mj/My Passport/mjI/AllProjects/GetMeBack/app/lib/widgets/interactive_room_prop.dart` — `InteractiveRoomProp`, multi-stage smash
- `/media/mj/My Passport/mjI/AllProjects/GetMeBack/app/lib/models/prop_state.dart` — `PropMaterial`, `PropMaterialShatter`
- `/media/mj/My Passport/mjI/AllProjects/GetMeBack/app/lib/vent_scenes/room_rampage_scene.dart` — `_playMaterial`, hit-stop on smash
- `/media/mj/My Passport/mjI/AllProjects/GetMeBack/app/lib/services/vent_sfx.dart` — `light` / `medium` / `heavy` / `rumble`
- Tests: `/media/mj/My Passport/mjI/AllProjects/GetMeBack/app/test/audit_features_test.dart`

**Notes:** No `forge2d` in `pubspec.yaml`. Shards are style polygons, not Voronoi. Material haptics = Flutter `HapticFeedback` intensity tiers, not AHAP/Core Haptics.

---

### 2. Emotional regulation / calm outro / DBT / breathing
**Status: PARTIAL**

| Have | Missing |
|------|---------|
| Calm breathing outro, inhale/exhale UI, zen streak on completion, micro-journal prompt, demo onboarding copy | Structured DBT skills, TIPP/STOP, guided multi-step protocols, clinical framing |

**Key files + symbols**
- `/media/mj/My Passport/mjI/AllProjects/GetMeBack/app/lib/screens/calm_outro_screen.dart` — `CalmOutroScreen`, `_breathController`, `_ZenStreakBadge`, `_finish`
- `/media/mj/My Passport/mjI/AllProjects/GetMeBack/app/lib/widgets/micro_journal_dialog.dart` — `showMicroJournalDialog`
- `/media/mj/My Passport/mjI/AllProjects/GetMeBack/app/lib/screens/demo_mode_screen.dart` — calm outro education slide
- `/media/mj/My Passport/mjI/AllProjects/GetMeBack/app/lib/services/storage_service.dart` — `recordCalmCompletion`

**Notes:** Product framing is correctly “cartoon stress toy / wellness,” not therapy. DBT would be net-new content + clinical-copy review.

---

### 3. Biometrics (HealthKit, Health Connect, BPM)
**Status: MISSING**

No HealthKit / Health Connect / heart-rate packages or services in `pubspec.yaml` or `lib/services/`.

**Notes:** Would need platform entitlements, privacy policy updates, and store justification. High compliance cost vs. vent-toy value.

---

### 4. Sensors (mic dB, accelerometer, gyro parallax)
**Status: HAVE** (with platform caveats)

**Key files + symbols**
- `/media/mj/My Passport/mjI/AllProjects/GetMeBack/app/lib/services/scream_meter_service.dart` — `ScreamMeterService`, `noise_meter`, dB→intensity, tap fallback
- `/media/mj/My Passport/mjI/AllProjects/GetMeBack/app/lib/services/sensor_service.dart` — `SensorService`, `parallax`, `onShake`, gyro + accel (disabled on web)
- `/media/mj/My Passport/mjI/AllProjects/GetMeBack/app/lib/vent_scenes/tornado_scene.dart` — mic scream meter UI
- `/media/mj/My Passport/mjI/AllProjects/GetMeBack/app/lib/vent_scenes/room_rampage_scene.dart` — applies `_parallax`
- Deps: `noise_meter`, `sensors_plus`, `permission_handler`
- Web headers: `/media/mj/My Passport/mjI/AllProjects/GetMeBack/app/docs/_headers` — mic / accel / gyro Permissions-Policy

**Notes:** Mic used mainly in Tornado (not all scenes). Sensors no-op on web (`kIsWeb` early return).

---

### 5. Visual polish (FragmentProgram shaders, parallax, decals)
**Status: PARTIAL**

| Have | Missing |
|------|---------|
| Gyro parallax on Room Rampage, destruction scars/decals, shatter overlays, gradient/ShaderMask chrome, comic FX, ambient stage motes | `FragmentProgram` / `.frag` GPU shaders, advanced post-FX |

**Key files + symbols**
- `SensorService.parallax` + `room_rampage_scene.dart` stage offset
- `DestructionScarsLayer` / `_DestructionScarsPainter` (Canvas radial gradients as “shaders”)
- `/media/mj/My Passport/mjI/AllProjects/GetMeBack/app/lib/widgets/premium_chrome.dart` — `ShaderMask`, `PremiumBackdrop`, glass/shine
- `/media/mj/My Passport/mjI/AllProjects/GetMeBack/app/lib/widgets/vent_scene_shell.dart` — photorealistic / 2.5D room stage comment + lighting

**Notes:** “Shader” usage today is Canvas `RadialGradient.createShader` / `ShaderMask`, not SkSL `FragmentProgram`.

---

### 6. Monetization / streaks / unlocks / zen points
**Status: PARTIAL**

| Have | Missing |
|------|---------|
| Daily zen streak, “unlock” SFX, room-clear → Cool Down messaging | IAP / subscriptions, zen points currency, gated content unlocks, paywalls |

**Key files + symbols**
- `StorageService.getZenStreak` / `recordCalmCompletion`
- `CalmOutroScreen._ZenStreakBadge`
- `SettingsScreen` streak display
- `VentSfx.unlock()` — audio sting only (not progression unlocks)
- No `in_app_purchase` / RevenueCat in deps

---

### 7. Journaling (text shredder, mood log)
**Status: PARTIAL**

| Have | Missing |
|------|---------|
| Optional one-line micro-journal after calm; history in Settings (≤30 entries) | Dedicated text-shredder journaling UX, mood tags/scales, searchable journal |

**Key files + symbols**
- `showMicroJournalDialog` / `StorageService.saveJournalEntry` / `loadJournalEntries`
- `/media/mj/My Passport/mjI/AllProjects/GetMeBack/app/lib/vent_scenes/shredder_scene.dart` — **face vent** shredder (not text journaling)

**Notes:** Journal text lives in `SharedPreferences`, not secure storage (targets do).

---

### 8. Privacy / flutter_secure_storage / encryption
**Status: PARTIAL → strong for V1A promise**

| Have | Missing / gaps |
|------|----------------|
| Local-only, no analytics SDKs, Android no INTERNET (per README), targets on native via `FlutterSecureStorage` + migration | Journal/streak/settings in plain prefs; web targets in prefs/localStorage; no end-to-end photo encryption beyond OS file storage |

**Key files + symbols**
- `StorageService` — `_secure`, `_migrateTargetsToSecureIfNeeded`, `_writeTargets`, `clearAllLocalData`
- Settings privacy copy + clear-data
- Docs: `README.md` Privacy; `docs/V1A_AUDIT_REPORT.md`; `docs/project_audit.md`

---

### 9. Settings (SFX, haptics, clear data)
**Status: HAVE**

**Key files + symbols**
- `/media/mj/My Passport/mjI/AllProjects/GetMeBack/app/lib/screens/settings_screen.dart` — haptics, SFX, zen streak, micro-journal list, privacy, clear data
- `StorageService.loadSettings` / `setHapticsEnabled` / `setSfxEnabled` / `clearAllLocalData`

---

### 10. Room content catalog / prop sprites
**Status: HAVE**

**Key files + symbols**
- `/media/mj/My Passport/mjI/AllProjects/GetMeBack/app/lib/models/room_setup.dart` — `RoomSetup`, `RoomProp`, `PropSmashStyle`, `RoomSetup.all` (**20 rooms**)
- `/media/mj/My Passport/mjI/AllProjects/GetMeBack/app/lib/models/prop_sprite_catalog.dart` — `PropSpriteCatalog`, `materialFor`, layout/z-index
- `/media/mj/My Passport/mjI/AllProjects/GetMeBack/app/lib/screens/room_picker_screen.dart`
- Assets: `assets/rooms/` (+ `*_base.png`), `assets/rooms/props/` (**120** sprites)
- Tools: `tools/generate_room_sprites.py`, `tools/remask_room_props.py`
- Docs: `docs/ROOM_GRAPHICS_FIX.md`

**Also:** 22 vent scenes under `lib/vent_scenes/` (21 face + Room Rampage).

---

## Status summary

| # | Area | Status |
|---|------|--------|
| 1 | Destruction & physics | **PARTIAL** |
| 2 | Calm / DBT / breathing | **PARTIAL** |
| 3 | Biometrics | **MISSING** |
| 4 | Sensors | **HAVE** |
| 5 | Visual polish / shaders | **PARTIAL** |
| 6 | Monetization / streaks / unlocks | **PARTIAL** |
| 7 | Journaling | **PARTIAL** |
| 8 | Privacy / secure storage | **PARTIAL** (strong local-only) |
| 9 | Settings | **HAVE** |
| 10 | Room catalog / props | **HAVE** |

---

## Important gaps the proposal missed (from docs + code)

These already matter for ship quality and are under-emphasized in a “world-class FX” proposal:

1. **Store compliance / ethics framing** — wellness + cartoon venting, not harassment; content rating, privacy policy URL, permission justifications (`docs/V1A_AUDIT_REPORT.md`).
2. **Onboarding** — `demo_mode_screen.dart` exists; first-run clarity still a store risk if skipped.
3. **Web parity** — sensors off on web; secure storage falls back to prefs; photo base64/`localStorage` **~5MB** quota risk (`docs/project_audit.md`).
4. **Accessibility** — sparse `Semantics` (home + props); no systematic screen-reader / reduce-motion / large-text pass.
5. **i18n** — no `flutter_localizations` / ARB; all English hard-coded.
6. **Offline / PWA** — intentional offline-first; service worker present in web build — keep validating cache + mic permission UX.
7. **Analytics privacy** — correctly **no** analytics (product strength); proposal should not casually add telemetry.
8. **Performance** — many per-scene FX controllers; earlier audit flagged audio pool crackle + scene boilerplate (`docs/project_audit.md`).
9. **Photo path portability** — absolute paths can break on iOS container UUID changes.
10. **Release hygiene** — signed AAB, iOS IPA on macOS, refresh `cf-dist`, Play listing (`V1A_SHIP_CHECKLIST` / audit report).
11. **Clinical / medical claims** — DBT + BPM invite “medical app” review; keep framing recreational unless intentionally pivoting.
12. **Mood + crisis safety** — if journaling deepens, need crisis disclaimer / resources policy (not in proposal).

---

## Prioritized implementation shortlist

### Shipped 2026-09-06 (this session)

1. **Material smash juice** — per-material hit-stop (`PropMaterial.hitStop`), patterned haptics (`VentSfx.material`), higher glass/ceramic shard counts; reduce-motion softens `_burst`.
2. **Journal → secure storage (native)** — `FlutterSecureStorage` + legacy prefs migration; wipe clears secure key.
3. **Mood chips** — micro-journal ChoiceChips (`lighter|calm|tired|tense|mixed`) stored with entries; Settings shows mood.
4. **Reduce motion** — Settings toggle; calm outro skips confetti/glitter; room smash uses lighter impact.
5. **Web photo guard** — reject uploads &gt; ~1.8MB with clear error (picker already resizes to 720² @72%).
6. **Journal shred micro-moment** — post-save `Sfx.shred` + short FX before home.

### Still later / multi-session (world-class delta)

1. **Forge2D + Voronoi fracture** for 1–2 hero props (then expand) — large engine + art cost.
2. **FragmentProgram** shatter / dust / heat-haze shaders.
3. **Core Haptics / advanced patterns** (iOS) + richer Android vibration effects.
4. **IAP + zen points + unlock rooms/weapons** — product + store + entitlement design.
5. **DBT-inspired calm modules** (non-clinical copy) — content pack + QA.
6. **Health Connect / HealthKit BPM** — only if wellness pivot is intentional.
7. **Full i18n** + a11y audit + golden/E2E tests.
8. **IndexedDB/Hive for web photos**; relative photo paths on native.
9. **Store listing pack** — screenshots, privacy policy URL, content rating, signed release.

### Extra gaps found vs market (not in original proposal)

- **Voice-at-photo** competitors (e.g. Vent) — GetMeBack has Tornado mic but not face-photo scream primary loop.
- **AI talk-listener** (Yelly) — out of scope for privacy-local product; do not add cloud AI casually.
- **30-second arcade sessions / upgrade loops** (House Breaker) — optional time-boxed modes.
- **Screenshot/desktop smash** (Zen Rage) — desktop-adjacent, not mobile V1A.

---

## Graphify orientation (sample)

Queries confirmed dense communities around: `DramaticFxController` / hit-stop, `CalmOutroScreen`, `SensorService.parallax`, `ScreamMeterService`, `StorageService` / zen streak / journal, `PropSpriteCatalog` / `RoomSetup`, `PropShatterController`, room sprite tooling. No graph nodes for Forge2D, HealthKit, FragmentProgram, or IAP.
