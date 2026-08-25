# GetMeBack V1A

**GetMeBack** is a Flutter stress-relief vent app. Pick a cartoon character (or your own photo), smash through face vent scenes or **Room Rampage**, then reset with a calm breathing outro. Everything stays **local on your device** — no accounts, no cloud sync.

**Version:** `1.0.0-a1+11` (see `pubspec.yaml`)

Cartoon venting only. Private. Not harassment.

## Features (V1A)

- **Dual paths:** Characters (faces) and Rooms & Scenes (Room Rampage)
- **25 preset characters** — 6 with PNG art in `assets/presets/`; the rest use emoji avatars
- **Photo upload** from gallery or camera
- **22 vent actions** — 21 face vents + Room Rampage
- **20 illustrated rooms** with soft-silhouette smashable props (see `docs/ROOM_GRAPHICS_FIX.md`)
- **Calm breathing outro**, zen streak, micro-journal
- **Settings** — haptics, SFX mute, journal history, clear local data
- **Platforms:** Android, iOS (macOS build), Linux, Windows, Web

## Privacy

- Local-only; no user accounts
- No analytics SDKs
- Android: no `INTERNET` permission; camera / mic / gallery for features only

## Quick start

```bash
cd /path/to/getmeback
flutter pub get
flutter run
```

```bash
flutter analyze
flutter test
```

## Room Rampage art

Props are remasked soft silhouettes (not opaque frame crops). Regenerate:

```bash
python3 tools/remask_room_props.py
```

Details: [`docs/ROOM_GRAPHICS_FIX.md`](docs/ROOM_GRAPHICS_FIX.md)

## Web deploy

```bash
flutter build web --release
rm -rf cf-dist && cp -a build/web cf-dist
bash scripts/cf-verify-prebuilt.sh
# Cloudflare: wrangler / Pages from cf-dist
# GitHub Pages: ./scripts/deploy-github-pages.sh
```

Live demo: https://noreplymjv.github.io/getmeback/

## Android

```bash
flutter build apk --release
flutter build appbundle --release
```

Signing: `android/key.properties` (gitignored).

## iOS IPA (macOS only)

Cannot produce a signed IPA on Linux. On a Mac with Xcode + Apple Developer:

```bash
flutter build ipa
# or: flutter build ios --release
```

Configure signing in Xcode (Runner → Signing & Capabilities). See `ios/ExportOptions.plist` if present.

## Ship checklist

See [`docs/V1A_SHIP_CHECKLIST.md`](docs/V1A_SHIP_CHECKLIST.md) and [`docs/V1A_AUDIT_REPORT.md`](docs/V1A_AUDIT_REPORT.md).

## License

Private project — not published to pub.dev.
