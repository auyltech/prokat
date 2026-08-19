# Prokat Flutter app

## Environment files

Flutter reads configuration at compile time with `--dart-define-from-file`.
The ignored `.env` contains the production endpoint and developer-specific
Mapbox public token. The ignored `.env.local` overrides only local values.
Templates are available in `.env.example` and `.env.local.example`.

Local endpoint mapping:

- Windows and web: `http://localhost:4000`
- Android Studio emulator: `http://10.0.2.2:4000`
- Physical Android device: the stack is intentionally unavailable over LAN.
  Use `adb reverse tcp:4000 tcp:4000` and override both Android URLs with
  `http://localhost:4000` when device testing is needed.

Local Firebase services and push notifications are disabled. Socket.IO still
connects to the local backend, so in-app real-time events remain testable.
Local and production auth sessions use separate secure-storage keys.

## Run

Install dependencies:

```powershell
flutter pub get
```

Run against production:

```powershell
flutter run --dart-define-from-file=.env
```

## Production builds

All production artifacts must be built with `.env` only. Flutter reads
`version` from `pubspec.yaml` (`1.0.13+5` → name `1.0.13`, number `5`).
Bump that field before every store upload; the build number must always
increase. Do not pass `--build-name` / `--build-number` unless you intend
to override `pubspec.yaml`.

Build a universal Android APK for direct installation outside a store:

```powershell
flutter build apk --release --dart-define-from-file=.env
```

Build smaller APKs split by CPU architecture for direct distribution:

```powershell
flutter build apk --release --split-per-abi --dart-define-from-file=.env
```

Build an Android App Bundle (`.aab`) for Google Play:

```powershell
flutter build appbundle --release --dart-define-from-file=.env
```

The universal APK is written to
`build\app\outputs\flutter-apk\app-release.apk`. Split APKs are written to the
same directory, and the Google Play bundle is written to
`build\app\outputs\bundle\release\app-release.aab`.

Before uploading to Google Play, `android/key.properties` must reference the
real release keystore. Without it, this project falls back to a debug signing
key, and the resulting artifact is not suitable for store publication.

Build an iOS archive and signed `.ipa` for App Store Connect. This command must
run on macOS with Xcode, an Apple Developer account, a distribution certificate,
and a valid provisioning profile configured for `com.auyltech.prokat`:

```bash
flutter build ipa --release --dart-define-from-file=.env
```

The Xcode archive is written to `build/ios/archive/Runner.xcarchive`, and the
exported package is written to `build/ios/ipa`. Upload the `.ipa` with Xcode
Organizer or Apple's Transporter app.

Build a release APK that connects to the ngrok tunnel configured in the
ignored `.env.ngrok.local` file:

```powershell
flutter build apk --release --dart-define-from-file=.env.ngrok.local
```

The APK is created at `build\app\outputs\flutter-apk\app-release.apk`. The
ngrok tunnel and the local backend must be running while testers use the app.

VS Code exposes the equivalent `prokat (Local)`, `prokat (Production Debug)`,
and `prokat (Production Release)` launch configurations.

After high-risk changes on this branch, use
[docs/architecture/manual-smoke-checklist.md](docs/architecture/manual-smoke-checklist.md).
