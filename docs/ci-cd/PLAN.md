# PROKAT: tag-only mobile delivery

Audit date: 2026-10-15. This is an implementation record, not permission to release.

## Baseline (A0)

- Repository remote: `git@github-work:auyltech/prokat.git`; owner `auyltech`.
  Privacy, billing, rulesets and provider settings need authenticated verification:
  SSH fetch works, but GitHub CLI has no authenticated account. Do not change visibility.
- Started on clean `dev` at `7346fea1ed9942da5aa1bc6c49c33fcc7a1eab76`.
  Fetched origin before editing. Work branch: `feat/tag-only-mobile-release`, from
  current `origin/dev`. No other worktrees. No root/ancestor AGENTS.md found.
- `origin/main`: `b481e0c` (release 1.2.2+18); merge base with dev: `c07bbd0`.
  Main has 1 exclusive commit, dev 177. History uses PRs and release commits;
  merging this branch or selecting an approved main commit requires the owner.
- Existing tags: `v1.0.12+4` and two `archive/*` tags. No platform release tags.
- Only CI: `.github/workflows/pull-request.yml`, PR/manual quality checks, no
  binary build or upload. Keep these development checks; tag-only applies to
  release builds and publishing. No existing Codemagic or Fastlane configuration.
- Flutter 3.47.2 pinned in `.flutter-version` and pubspec; Dart constraint ^3.13.0,
  local SDK Dart 3.13.2. No FVM config initially. `pubspec.lock` tracked.
  pubspec version 1.2.2+18 is a development default, not evidence of store state.
- Android applicationId/namespace `com.auyltech.prokat`; AGP 9.1.1, Gradle 9.3.1,
  Kotlin 2.4.0, compileSdk 37, Java source target 17. AGP runtime needs JDK 17+;
  use JDK 21 in CI. Existing AGP9 patch for play_install_referrer is tracked.
  No product flavors. `android/key.properties` and a local upload keystore are
  ignored. Their contents/passwords have not been read. Existing release signing
  falls back to debug: CI must explicitly forbid this. Do not replace upload key.
- iOS bundle `com.auyltech.prokat`; Team `VT7KXG8NBR`; Runner scheme; iOS Podfile
  minimum 15.0, Runner overrides use Xcode recommended minimum. Automatic signing
  in project; no distribution certificate or profile in Git. Info.plist already
  uses FLUTTER_BUILD_NAME/NUMBER, no manual version synchronization needed.
- **BLOCKED reproducibility:** tracked `ios/Podfile.lock` contains only Flutter,
  despite native Firebase/Mapbox/etc dependencies. It must be regenerated on a
  supported macOS/Xcode environment and committed before an authorized RC.
  Do not resolve floating native dependencies silently in a release job.
- Firebase project `prokat-bfbec`; `firebase_options.dart` tracked. Native Android
  JSON and iOS plist ignored; Android JSON exists locally, iOS plist absent.
  CI needs native configurations from Firebase, not personal Mac paths.
- Crashlytics 5.4.0, native Gradle plugin 3.0.8 conditionally applied when JSON
  exists; R8 enabled. Dart crash reporting explicitly enabled in production.
  No existing obfuscation/split-debug-info, no iOS Crashlytics upload build phase.
  Preserve Android mapping and native dSYM until upload is confirmed. Do not add
  Dart obfuscation: avoids introducing a unique external symbol archive.
- iOS entitlements: APNs and Associated Domains for `prokat-bfbec.web.app`,
  `prokat-bfbec.firebaseapp.com`, `open.prokat.auyltech.kz`; background fetch and
  remote notifications. Distribution profile must include these capabilities.
  Entitlement source says development APNs; verify exported distribution IPA is
  production APNs. No app extensions found. AppDelegate configures FCM delegate.
- Android verified links use the same three hosts. Signing identity must match
  existing assetlinks association (Play app signing certificate, not upload key).
- Compile-time configuration uses `--dart-define-from-file`; production endpoints
  are in `.env.example`, public Mapbox token must be supplied securely. Local
  replica overrides must never enter CI. No existing localized release metadata.
- Release history suggests previous manual uploads. Actual published versions,
  store app records, highest historical build numbers, key fingerprint and
  certificate/profile usability are **NOT VERIFIED** without store accounts.
  Public search did not establish a reliable current production version.

## Target and decisions

| Tag | Provider | Destination |
| --- | --- | --- |
| `rc/android/vM.m.p+B` | GitHub Actions, standard Ubuntu | Play internal |
| `android/vM.m.p+B` | GitHub Actions, standard Ubuntu | Play production |
| `rc/ios/vM.m.p+B` | Codemagic mac_mini_m2 | TestFlight |
| `ios/vM.m.p+B` | Codemagic mac_mini_m2 | App Review, AFTER_APPROVAL |

Provider glob filters select a platform. A separate anchored parser validates
the entire tag, platform, channel, version and build limit. Commits/PRs cannot
start release builds. Codemagic manual/API/scheduled starts must fail before
building. UI/webhook settings are independently checked at U1.

Version comes from tag via Flutter build arguments; never edit multiple native
files. Common notes are UTF-8 in `releases/<version>/{release.json,ru,en,kk}.txt`.
Use JSON instead of YAML for dependency-free Dart tooling. Google locales:
ru-RU/en-US/kk; Apple: ru/en-US/en-GB. Apple lacks Kazakh metadata: retain kk.txt
in Git, use English store fallback; never overwrite the Russian translation.
Primary store locale must be checked during account setup.

Production requires an explicit provider secret `PRODUCTION_PUBLISHING_ENABLED`
equal to `true`, only set after U5, plus approved SHA reachable from freshly
fetched origin/main. RC cannot select a production destination. Platform-wide
serialization prevents simultaneous uploads within each provider. Anyone who
can edit trusted workflow code/secrets can bypass code gates: restrict write
access; do not assume private-repo rulesets are available on GitHub Free.

Prefer monotonic, new build numbers for each platform attempt, including
RC -> production. Android promotion via Supply and Apple submission of an
existing TestFlight build are possible, but require extra recovery paths. The
initial implementation deliberately rebuilds production with a NEW build
number. Existing accepted build always blocks blind upload, with store IDs and
recovery instructions. No coordinator, state database or artifact server.

## Cost and retention

GitHub Free private-repo allowance currently lists 2,000 standard runner minutes
and 500 MB artifact storage, shared at account level. Existing PR jobs also
consume minutes. No release binary artifact upload is necessary on Android.
Use standard Ubuntu, no larger runners. Configure a blocking Actions budget;
cache storage is separately subject to limits.

Codemagic advertises 500 monthly M2 minutes on personal accounts, one concurrent
build, no free minutes for Teams. Pricing says hobby/indie/proof-of-concept;
FAQ says personal/hobby. **Commercial company project eligibility is NOT
VERIFIED**: U1 must confirm that PROKAT qualifies, with Codemagic support if
unclear. Do not move to a billed Team or enable billing. Paid features require
enabling billing; YAML cannot enforce account spending. Stop when quota expires.
Apple Developer and Play account fees are outside the CI budget; if accounts
are missing, the requested stores cannot operate at a total cost of $0.

Codemagic personal artifact/history retention is currently 30 days, not a
configurable one-day guarantee. Minimize artifact selection; investigate using
the built-in publishing CLI with no persistent IPA artifacts. Keep dSYM on
failed symbol upload; successful Firebase upload must precede cleanup. Do not
delete necessary symbols to satisfy binary retention preferences.

## Sequence and gates

| Stage | Status | Exit condition |
| --- | --- | --- |
| A0 | VERIFIED local audit | Baseline and official docs recorded |
| A1 | IN PROGRESS | Shared validation, tests, metadata, fail-closed gates |
| U1 | PENDING USER ACTION | Free eligibility, private connection, tag-only UI |
| A2 | Independent work permitted | Android workflow + account validation after U1 |
| U2 | PENDING USER ACTION | Play API, existing key, historical build floor |
| A3 | Independent work permitted | Codemagic workflow + lock/signing validation |
| U3 | PENDING USER ACTION | Apple integration, profiles, Firebase, native lock |
| A4 | Local/static checks permitted | Provider integration remains pending |
| U4 | PENDING USER ACTION | Explicit permission for exact RC tags/SHAs |
| A5 | NOT VERIFIED | Actual test distribution, symbols, retries, cost |
| U5 | PENDING USER ACTION | A5 success + one-time production authorization |
| A6 | NOT VERIFIED | Honest final acceptance after integration |

Next autonomous steps: implement/test Dart tag and metadata tools; Android
signing/materialization, Supply preflight and workflow; final Codemagic-only iOS
configuration; setup/runbook/verification; separate commits. No merge, tags,
store writes or billed-account changes. Stop at U1 after independent work.

## Official references (checked 2026-10-15)

- [GitHub filters and workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax)
- [GitHub Actions billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions)
- [Codemagic pricing](https://codemagic.io/pricing/), [plan eligibility and retention](https://docs.codemagic.io/billing/pricing/), [billing activation](https://docs.codemagic.io/billing/billing/), [FAQ](https://docs.codemagic.io/getting-started/faq/)
- [Codemagic tag triggers](https://docs.codemagic.io/yaml-running-builds/starting-builds-automatically/)
- [Codemagic signing](https://docs.codemagic.io/yaml-code-signing/signing-ios/), [App Store publishing](https://docs.codemagic.io/yaml-publishing/app-store-connect/), [localized notes](https://docs.codemagic.io/yaml-notification/publish-release-notes/)
- [Android version limits](https://developer.android.com/studio/publish/versioning), [current bundles API](https://developers.google.com/android-publisher/api-ref/rest/v3/edits.bundles/list), [Supply promotion](https://docs.fastlane.tools/actions/supply/)
- [Apple build version](https://developer.apple.com/documentation/bundleresources/information-property-list/cfbundleversion), [Apple localizations](https://developer.apple.com/help/app-store-connect/reference/app-information/app-store-localizations)
- [Codemagic Xcode 26.6 image](https://docs.codemagic.io/specs-macos/xcode-26-6/), [Firebase dSYM](https://docs.codemagic.io/knowledge-firebase/firebase-crashlytics-dsym-uploading/)
