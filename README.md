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

Run against the local backend:

```powershell
flutter run -d windows --dart-define-from-file=.env --dart-define-from-file=.env.local
flutter run -d chrome --dart-define-from-file=.env --dart-define-from-file=.env.local
flutter run -d emulator-5554 --dart-define-from-file=.env --dart-define-from-file=.env.local
```

Run against production:

```powershell
flutter run --dart-define-from-file=.env
```

VS Code exposes the equivalent `prokat (Local)`, `prokat (Production Debug)`,
and `prokat (Production Release)` launch configurations.
