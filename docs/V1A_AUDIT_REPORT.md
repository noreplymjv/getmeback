# GetMeBack V1A — Expert Team Audit Report

**Date:** 2026-08-25  
**Version:** `1.0.0-a1+10`  
**Verdict:** **Ship-ready V1A** — core product complete; release hygiene applied in this pass.

---

## Team roles & findings

| Role | Lead focus | V1A status |
|------|------------|------------|
| **Product PM** | Core loop, privacy promise, store framing | ✅ Dual-path loop (Characters + Room Rampage → Calm) is complete |
| **Game Designer** | Feedback, pacing, session arc | ✅ Hit-stop, SFX pool, haptics, zen streak, 22 vents, 20 rooms |
| **UX / UI** | First-run clarity, settings, typography | ✅ Settings screen, content tips, Ubuntu sans stack |
| **QA Engineer** | Analyze, unit/widget tests, ship checklist | ✅ `flutter analyze` clean; 93 tests; CI workflow added |
| **Security / Privacy** | Local-only, permissions, data wipe | ✅ No analytics; clear-data; secure storage on native |
| **Release Engineer** | Web CF artifact, docs, versioning | ✅ README + checklist; cf-dist verify script; CI |

---

## What V1A includes

- **26 presets** (6 illustrated PNGs + emoji avatars)
- **21 face vent scenes** + **Room Rampage** (22 actions)
- **20 illustrated rooms** with layered sprite destruction
- **Calm outro** with breathing, zen streak, micro-journal
- **Settings:** haptics, SFX mute, journal history, clear local data, privacy copy
- **Platforms:** Android, iOS (macOS build), Linux, Windows, Web (PWA)
- **Deploy:** Cloudflare (`cf-dist` + `wrangler.jsonc`), GitHub Pages script

---

## QA summary (this session)

```
flutter analyze  → No issues found
flutter test     → 93 tests (after widget test fix)
npm run build    → cf-dist prebuilt verify (when artifact present)
```

---

## Remaining before public store launch (post-V1A)

1. **Play Store listing** — screenshots, content rating, privacy policy URL, permission justifications
2. **Refresh `cf-dist`** — run `flutter build web --release && cp -a build/web cf-dist` after final code freeze
3. **Signed AAB** — production keystore (not only local JKS)
4. **iOS** — requires macOS + Xcode for IPA
5. **Optional:** more preset PNG art; integration/E2E tests; golden screenshots

---

## How to ship V1A today

**Web (fastest):**
```bash
flutter build web --release
rm -rf cf-dist && cp -a build/web cf-dist
npm run build   # verify
npx wrangler deploy   # or Cloudflare dashboard upload
```

**Android side-load:**
```bash
flutter build apk --release
# APK → $GETMEBACK_BUILDS/
```

**Smoke:** follow [`docs/V1A_SHIP_CHECKLIST.md`](V1A_SHIP_CHECKLIST.md)

---

## Content & ethics framing (gaming-adjacent wellness)

GetMeBack is a **cartoon stress toy**, not a competitive game. V1A ships with in-app copy: private venting, permission for photos, no harassment. Suitable for side-load and web demo; store review should emphasize wellness + local privacy.
