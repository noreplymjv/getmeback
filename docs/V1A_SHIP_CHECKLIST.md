# GetMeBack V1A — ship checklist

Smoke checks before cutting a V1A release (`1.0.0-a1+11`).

## Build & analyze

- [ ] `flutter pub get`
- [ ] `flutter analyze` clean
- [ ] `flutter test` passes
- [ ] Web: `flutter build web --release` → sync `cf-dist`
- [ ] Android APK/AAB (if shipping mobile)

## Core flows

- [ ] Home: Characters / Rooms / Demo / Settings gear
- [ ] Preset → vent → calm
- [ ] Room Rampage: soft silhouettes, smash juice, scars (not frame-cut cards)
- [ ] Settings: SFX mute, haptics, journal, clear data

## Web

- [ ] https://noreplymjv.github.io/getmeback/ kitchen room looks aligned
- [ ] SPA refresh does not 404

## iOS

- [ ] Build on macOS only (`flutter build ipa`)
