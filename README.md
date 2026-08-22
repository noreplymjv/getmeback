# GetMeBack v1

**GetMeBack** is a playful virtual stress-relief app. Pick a cartoon preset or upload a photo, choose one of 15 vent actions, release negative emotions in a safe cartoon way, then finish with a calming breathing reset.

All data stays **local on your device** — no accounts, no cloud uploads in v1.

**Version:** 1.0.0+1

## v1 features

- **6 preset cartoon characters** (Angry Boss, Rude Driver, Ex Friend, and more)
- **Photo upload** from gallery or camera
- **15 vent actions** with interactive animations (Smash Face, Juice Blender, Punch Bag, Trash Can, Balloon Pop, Fire Poof, Stomp, Ice Shatter, Dart Throw, Sledgehammer, Catapult, Lightning Zap, Sink & Drown, Paper Shredder, Piñata)
- **Calm outro** with guided breathing animation
- **Recent targets** saved locally via SharedPreferences
- **Platforms:** Android, iOS, Linux, Windows, Web demo

## Install files (pre-built)

Release builds are copied to:

```
/media/mj/DATA/getmeback-builds/
```

| File / folder | Use |
|---------------|-----|
| `GetMeBack-debug.apk` | Side-load for testing |
| `GetMeBack-release.apk` | Signed release APK |
| `GetMeBack-release.aab` | Google Play upload |
| `web/` | Static Flutter web demo (serve with any HTTP server) |
| `GetMeBack-linux-x64.tar.gz` | Linux desktop tarball (when built) |

**Android:** transfer an APK to your phone and install (enable “Install unknown apps” if prompted).

**Web demo:** from the `web/` folder:

```bash
cd /media/mj/DATA/getmeback-builds/web
python3 -m http.server 8080
# open http://localhost:8080
```

**Linux tarball:**

```bash
mkdir -p ~/getmeback
tar -xzf /media/mj/DATA/getmeback-builds/GetMeBack-linux-x64.tar.gz -C ~/getmeback
~/getmeback/getmeback
```

Rebuild and refresh artifacts with `./scripts/agent-full-build.sh` (copies APK/AAB/Linux outputs to the folder above).

## Run from source (development)

**Prerequisites:** [Flutter SDK](https://docs.flutter.dev/get-started/install) stable (3.16+), Dart 3.12+

```bash
cd ~/Projects/getmeback
flutter pub get
flutter run
```

Target a specific device:

```bash
flutter run -d android
flutter run -d linux      # requires Linux deps below
flutter run -d windows
flutter run -d chrome     # web
flutter run -d ios        # macOS + Xcode only
```

Verify setup:

```bash
export PATH="$HOME/flutter/bin:$PATH"
flutter doctor -v
```

### Linux desktop deps

GTK 3 dev libraries are required before `flutter run -d linux` or `flutter build linux`:

```bash
sudo ./scripts/install-linux-deps.sh
```

Then run or package:

```bash
flutter build linux --release
./scripts/run-linux.sh
# or package: ./scripts/package-linux.sh  →  dist/getmeback-linux-x64.tar.gz
```

### Android SDK (optional helper)

```bash
./scripts/install-android-sdk.sh
export JAVA_HOME=$HOME/.local/jdk
export PATH=$JAVA_HOME/bin:$PATH
```

## Build from source

Default Flutter output paths are under `build/`. After a full build, copies land in `/media/mj/DATA/getmeback-builds/` with the `GetMeBack-*` names above.

### Android APK & AAB (release)

Release signing reads `android/key.properties` (gitignored). Without it, release builds fall back to debug signing.

1. Generate a keystore (once):

```bash
keytool -genkey -v \
  -keystore android/getmeback-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias getmeback
```

2. Create `android/key.properties`:

```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=getmeback
storeFile=getmeback-release.jks
```

3. Build:

```bash
flutter build apk --debug
flutter build apk --release
flutter build appbundle --release
```

| Artifact | Project path |
|----------|--------------|
| Debug APK | `build/app/outputs/flutter-apk/app-debug.apk` |
| Release APK | `build/app/outputs/flutter-apk/app-release.apk` |
| App Bundle | `build/app/outputs/bundle/release/app-release.aab` |

Smaller per-CPU APKs: `flutter build apk --split-per-abi --release`

### Web demo

```bash
flutter build web --release
# output: build/web/
rsync -a build/web/ /media/mj/DATA/getmeback-builds/web/
```

### iOS IPA (macOS only)

Cannot be built on Linux. On a Mac with Xcode and an Apple Developer account:

```bash
flutter build ipa --export-options-plist=ios/ExportOptions.plist
```

Before building, edit `ios/ExportOptions.plist` — replace `YOUR_TEAM_ID` and `YOUR_APP_STORE_PROVISIONING_PROFILE`, and configure signing in Xcode (Runner → Signing & Capabilities).

**Output:** `build/ios/ipa/getmeback.ipa`

### Windows desktop

```bash
flutter build windows
```

**Output:** `build/windows/x64/runner/Release/`

## Signing & security

- `android/key.properties`, `*.jks`, and `*.keystore` are **gitignored** — never commit keystore passwords
- The dev keystore at `android/getmeback-release.jks` is for local/testing builds only
- For Play Store production: create a dedicated keystore, enable Play App Signing, store credentials in a password manager or CI secrets vault

## Project structure

```
lib/
├── main.dart                 # App entry
├── router.dart               # go_router navigation
├── models/                   # VentTarget, VentAction, presets
├── screens/                  # Home, Create, Vent Menu, Calm Outro
├── vent_scenes/              # 15 interactive vent animations
├── services/                 # Local storage (SharedPreferences)
├── theme/                    # Dark playful theme
└── widgets/                  # Reusable UI components
scripts/
├── install-linux-deps.sh     # apt install for Linux desktop build
├── install-android-sdk.sh    # Command-line Android SDK setup
├── package-linux.sh          # Tarball the Linux release bundle
└── run-linux.sh              # Launch Linux release binary
```

## Privacy

- Photos are copied to the app's local documents directory
- No network calls or analytics in v1
- No user accounts

## Analyze & test

```bash
flutter analyze
flutter test
```

## Platform matrix

| Platform | Build on Linux | Notes |
|----------|----------------|-------|
| Android  | Yes            | APK/AAB with Android SDK + JDK 17 |
| Web      | Yes            | Static site in `build/web/` |
| Linux    | Yes            | Needs `sudo ./scripts/install-linux-deps.sh` |
| iOS      | No             | macOS + Xcode for IPA |
| Windows  | Limited        | Best built on Windows with Visual Studio 2022 |

## License

Private project — not published to pub.dev.
