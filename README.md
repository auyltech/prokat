# Prokat Flutter app

## Environment files

Flutter reads configuration at compile time with `--dart-define-from-file`.
The ignored `.env` contains the production endpoint and developer-specific
Mapbox public token. The ignored `.env.local` overrides only local values.
Templates are available in `.env.example` and `.env.local.example`.

Local endpoint mapping:

- Windows, web, Android emulator, and physical Android: `http://localhost:4000`
- Physical phones and emulators need `adb reverse tcp:4000 tcp:4000`
  and `adb reverse tcp:3000 tcp:3000` for the share landing
  (`scripts/local-start.ps1` and `scripts/local-refresh.ps1` apply it to every
  `adb devices` entry with status `device`). The stack is not published on LAN.

Local Firebase and push notifications stay enabled (`ENABLE_FIREBASE_SERVICES`
and `ENABLE_PUSH_NOTIFICATIONS` in `.env`, `.env.local`, `.env.ngrok.local`,
and `.env.hoster`).
Grant OS notification permission on first launch so the FCM token can register
with the backend. Socket.IO still delivers in-app events while the app is open.
Local and production auth sessions use separate secure-storage keys.

The local Docker project is `prokat-local`. Its database and private MinIO
bucket are a verified production snapshot with production device tokens
excluded, imported delivery jobs cancelled, and pending OTPs invalidated.
The local OTP is `000000` for any valid phone number. Automatic billing,
expiry and deletion jobs are paused; delivery of new local notifications works.
GA, Crashlytics and new share attribution are disabled in local builds.

Local shares use the existing web app at `http://localhost:3000/e/<shareId>`.
The app registers the token with the local backend before sharing, including
for guests. The landing's Open button uses `prokat-local://app/e/<shareId>`.
Build with `.env.local`; it includes the Mapbox token and both endpoints.
These links work on the PC and Android devices connected through adb reverse.

To replace the local data with a fresh production snapshot, run from
`../prokat-backend`: `node scripts/local-replica-refresh.mjs --replace-local-data`,
then `powershell -File scripts/local-start.ps1`. The refresh replaces only
`prokat-local` volumes, reads production through SSH, and retains a checked
database/object backup under `prokat-backend/backups/replica-*`.
Production stays running, so database and object snapshots can represent
slightly different moments if production writes occur during copying.

Hoster lab (own VPS in KZ): copy `.env.hoster.example` → `.env.hoster`, set the
VPS IP (API on port `4000`), then run the **Prokat Hoster** configuration or:

```powershell
flutter run --dart-define-from-file=.env.hoster
```

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

Store releases use platform Git tags and CI, with version/build arguments
derived from the tag. See [release runbook](docs/ci-cd/RELEASE_RUNBOOK.md) and
[one-time account setup](docs/ci-cd/MANUAL_SETUP.md). Production stays disabled
until owner gate U5. Do not upload local builds as a routine release procedure.
The owner CLI reads version/build from pubspec.yaml at fresh origin/main, then
creates the immutable tag; CI verifies that tag and pubspec agree. Bump the common
build counter in dev before the release PR. Use the four commands in
[CICD-README](CICD-README.md), not manual tag creation.

The commands below are local diagnostic builds. They read the ignored `.env`
and use the development pubspec version unless explicitly overridden.

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
