# Mobile update prompts and public outbound shares

## Scope and release metadata

Only Flutter changes. Backend, Admin/Web, database, production Remote Config,
server configuration and rollout settings are unchanged. No deployment or store
upload is performed. Version remains `1.2.2+18`; the release owner will bump it
separately before publication.

Base: `5ef7a21614f022053094bdaea35a46fd9beac965` (fetched and verified against
remote `dev` before branching). Branch: `feat/upgrader-public-share-outbound`.

## Update prompts

`upgrader: ^13.7.0` resolves to 13.7.0. `MyApp` adds `AppUpdatePrompt` below
`MaterialApp.router`, with the root GoRouter navigator key. The controller
survives route, startup and language changes; prompts are eligible only in guest,
client or owner startup states, not loading, OTP or error states. Android and iOS
use the standard Play Store / App Store adapters and installed package metadata
(`com.auyltech.prokat` on both). `countryCode: 'KZ'` selects Kazakhstan;
`languageCodeOverride` follows the application's selected `ru`, `kk` or `en`.
The public Apple bundle lookup in KZ returned listing 6817078475 during validation.
No available version is hard-coded.

The prompt offers Update, Later and Ignore, permits barrier/back dismissal,
keeps the package's normal three-day re-alert interval, and persists Ignore for
the offered version. Production leaves both debug-display options off,
`minAppVersion` unset and `showOnlyMandatoryUpdates` off. `SoftAppUpgrader.blocked`
always returns false so store-description minimum-version tags or critical
metadata cannot force this release's users to update.

Package 13.7.0 includes RU, KK and EN translations. Supported message overrides
clarify RU/KK Ignore, improve the Kazakh body and translate the Kazakh
release-notes heading. Other messages use the built-in translations. The package
is not forked. See the [versioned package documentation](https://pub.dev/packages/upgrader/versions/13.7.0).

The alert uses a specific dialog route. Dismissal removes that dialog even if a
warm share has pushed an equipment route above it. Barrier/back and router
replacement also reset the display guard. Eight combined bootstrap tests verify
cold pending / warm legacy and registry links, Later/Ignore, durable accepted
context, one OPENED recording and guest -> OTP -> client continuation.

## Outbound and compatibility

Every attempt generates a fresh 22-character base64url token and calls
`POST /equipment-shares/links`. Only a successful response matching both token
and equipment ID allows the platform sheet to receive
`https://prokat.auyltech.kz/e/{shareId}`. The public URL contains no equipment ID
and no legacy query. An unmounted caller aborts opening the sheet. Failure
propagates into the existing localized `somethingWentWrongTryAgain` error toast;
tapping Share again retries registration with a fresh token.

Registration is not SHARED. Existing `reportShareResult` behavior is preserved:
only platform success emits the share analytics event; authenticated success
also sends SHARED once, independently and best effort. Dismissed/unavailable
results and registration failures do not track a share.

The legacy equipment-ID URL builder and `SHARE_LINK_MODE` selector are removed.
Production always selects the canonical origin, even if a stale compile-time
base override is supplied. No PUBLIC_SHARE_LINKS_ENABLED, minimum-build gate,
Remote Config path or Firebase fallback exists in this repository. Local replica
builds retain their validated loopback registry URLs. Templates are aligned;
only the share-base values in ignored developer `.env`, `.env.hoster` and
`.env.ngrok.local` were aligned locally (these files are not committed).

Legacy Firebase hosts remain inbound-only in the parser and native associations.
Historical equipment-ID install-referrer parsing uses its own legacy base,
independent of the new outbound origin. The existing
`https://open.prokat.auyltech.kz/e/{shareId}` resolver flow remains intact.
The canonical Web host is not added to Android App Links or iOS associations.
Firebase Analytics, Crashlytics, Messaging, App Check and infrastructure are
unchanged. Future `deferredInstall` ingress is unchanged; deferred installs and
analytics redesign are not implemented here.

## Legacy-host occurrence audit

Search the joined host `prokat-bfbec` + `.web.app` using `git grep -n -F`
and `rg --hidden --no-ignore -n -F` (excluding Git metadata, build outputs,
package caches and generated platform dependency folders).

There are **50 tracked matching lines**: zero A (outbound generation),
three B (legacy inbound), the compatibility tests below (C), and one historical
documentation line (D). There are no E (unrelated Firebase functionality) matches.
Every tracked matching line is listed here:

| File | Matching lines | Classification |
| --- | --- | --- |
| `android/app/src/main/AndroidManifest.xml` | 49 | B — legacy inbound compatibility |
| `docs/architecture/public-share-c1.md` | 24 | D — historical documentation |
| `ios/Runner/Runner.entitlements` | 9 | B — legacy inbound compatibility |
| `lib/core/config/env.dart` | 63 | B — legacy inbound compatibility |
| `test/core/config/env_test.dart` | 90, 97, 101, 105, 117 | C — compatibility / rejection test |
| `test/features/equipment_share/equipment_share_bootstrap_test.dart` | 39 | C — compatibility / rejection test |
| `test/features/equipment_share/equipment_share_ingress_test.dart` | 140 | C — compatibility / rejection test |
| `test/features/equipment_share/equipment_share_install_referrer_test.dart` | 10, 15, 88, 90, 138 | C — compatibility / rejection test |
| `test/features/equipment_share/equipment_share_link_test.dart` | 59, 68, 72, 78, 87, 92, 109, 125, 135, 138, 144, 149, 155, 166, 175 | C — compatibility / rejection test |
| `test/features/equipment_share/equipment_share_open_recorder_test.dart` | 104, 305 | C — compatibility / rejection test |
| `test/features/equipment_share/equipment_share_open_test.dart` | 19, 30, 44, 63, 78, 79, 80, 95 | C — compatibility / rejection test |
| `test/features/equipment_share/equipment_share_overlay_race_test.dart` | 212, 225, 250, 260, 272, 290 | C — compatibility / rejection test |
| `test/features/equipment_share/equipment_share_recovery_test.dart` | 689, 1023 | C — compatibility / rejection test |
| `test/features/equipment_share/equipment_share_storage_overlay_test.dart` | 100 | C — compatibility / rejection test |

The broader workspace scan additionally finds ignored historical planning notes
in `.plans/sharing/equipment-sharing-implementation.md` at lines
268, 271, 281, 296 and 314: D (historical pre-migration documentation).
Ignored developer build profiles no longer contain the retired host. Generated
binaries/caches are not production outbound source and are excluded from this
source audit. Remaining native domain associations are deliberately unchanged.

## Completed validation

- `flutter pub get` and `flutter pub get --enforce-lockfile`: passed; upgrader
  resolved to 13.7.0 with no existing package downgrades.
- `flutter analyze --no-pub --fatal-infos --fatal-warnings`: no issues.
- Full CI-equivalent `flutter test --no-pub --reporter expanded
  --dart-define=ENABLE_FIREBASE_SERVICES=false
  --dart-define=ENABLE_PUSH_NOTIFICATIONS=false`: 918 passed, three local-only
  cases skipped. The dedicated local replica run passed all three cases.
- Focused `flutter test --no-pub --reporter expanded test/core/updates
  test/features/equipment_share test/features/auth test/features/bookings
  test/core/config/env_test.dart test/core/router`: 410 passed, one
  Firebase-disabled configuration case skipped in this default-config run.
  Includes app links, durable recovery, login/OTP, OPENED and booking attribution.
- Upgrader suite: 19 passed; outbound suite: 11 passed. Bootstrap suite:
  30 passed, including eight new prompt-plus-link continuation cases.
- Stale production build overrides (`SHARE_LINK_MODE=legacy` and retired
  `SHARE_BASE_URL`) with env/outbound suites: 18 passed, one configuration
  case skipped; outbound still uses only canonical links.
- `dart format --output=none --set-exit-if-changed lib test`: passed.
- `flutter gen-l10n` and localization drift check: passed, no generated changes.
- `git diff --check`: passed. Native platform/version files have no diff.
- `flutter build appbundle --release --dart-define-from-file=.env`: passed,
  `build/app/outputs/bundle/release/app-release.aab` (134,498,117 bytes).
  Merged Android manifests confirm versionName 1.2.2 and versionCode 18.
  Non-fatal plugin KGP and existing icon-font diagnostics were emitted.
- iOS compile/build: not run; this Windows environment has no macOS/Xcode.

## Manual QA (to perform on devices before release)

- Update prompt: verify no prompt when the installed version is current/newer;
  simulate an older installed version/newer store in the injected widget harness
  (`flutter test test/core/updates`), then verify Later, Ignore and Update. Check
  RU, KK and EN, and confirm Ignore suppresses that version across restart.
  Never enable debug forcing or change production metadata for simulation.
- Share: test guest and authenticated sharing from client, owner and booking
  entry points. Copy the result; it must be the canonical token URL, with no
  equipment ID, legacy query, Firebase host or app-transport host. Reject/block
  registration in the test environment: no sheet, localized retry error. Retry
  after restoring registration and check the new registered token.
- Web: open a newly shared URL and verify the SSR landing and Telegram/WhatsApp
  previews. Use Open in PROKAT and verify the correct equipment opens through
  the app-transport domain, both cold and warm.
- Inbound: use a known historical Firebase equipment link with its share token;
  verify cold/warm opening, guest login/OTP continuation and the intended equipment.
  Repeat registry-link delivery while an update alert is visible; dismiss it and
  verify route and attribution remain correct.

These device/social-preview checks are prepared, not claimed as performed in
this Windows environment. No app-store upload or production change is authorized.
