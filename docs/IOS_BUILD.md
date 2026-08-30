# iOS build (macOS required)

IPA cannot be built on Linux. On a Mac:

```bash
flutter pub get
flutter build ipa
# or open ios/Runner.xcworkspace in Xcode and Archive
```

Configure Team ID / provisioning in Xcode → Runner → Signing & Capabilities.
