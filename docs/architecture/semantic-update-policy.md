# Semantic update policy and emergency minimum

This follow-up continues PR #62 on `feat/upgrader-public-share-outbound` from
`1f16f6a738ca4fe75aadb4d81cafdc0f5fb86b52`. Application metadata remains
`1.2.2+18`. Public Share implementation, Backend, Admin/Web, database and remote
production configuration are unchanged. No deployment or upload is performed.

## Policy

`classifyAppUpdate` is pure and uses the existing `version` parser with complete
SemVer validation, then normalizes to numeric major.minor.patch. Build metadata
(and prerelease labels) do not participate in this policy. Malformed installed
or Store versions fail safely; malformed/empty emergency values mean no remote
override and are diagnosed using the application's Logger convention.

Precedence:

1. Installed below the effective minimum: HARD, even when Store lookup is absent
   or the normally available update would be silent or soft.
2. Newer major: HARD.
3. Same major, newer minor: SOFT.
4. Same major/minor, newer patch: SILENT.
5. Otherwise: UP_TO_DATE.

UP_TO_DATE and SILENT show no UI. SOFT retains Update/Later/Ignore, barrier/back
dismissal and upgrader's normal re-alert/Ignore persistence. HARD shows Update
only and overrides previous Ignore or snooze. Both sources of minimum version
are honored: the higher valid Remote Config or Store minimum wins; invalid or
absent sources cannot weaken a valid minimum from the other source.

`upgrader` stays at 13.7.0. The Store adapters still obtain minimum versions from
Store metadata; the application reads `versionInfo.minAppVersion`. No production
`minAppVersion`, emergency value, latest version or debug forcing is configured
in source. Standard KZ Play/App Store lookup and RU/KK/EN messages remain.

## Firebase Console configuration

Configure parameters manually in **Firebase Console -> Remote Config**:

| Platform | Parameter | In-app default |
| --- | --- | --- |
| Android | `min_supported_version_android` | empty string |
| iOS | `min_supported_version_ios` | empty string |

These are non-secret version strings, not credentials or sensitive data. This
PR does not create or publish Firebase Console parameters. Use complete semantic
versions such as `major.minor.patch`; examples in tests are not production values.
Empty, missing and malformed remote values mean no remote override. Removing a
remote minimum does not bypass a stricter Store minimum or a normal major update.

The official FlutterFire `firebase_remote_config` 6.7.0 dependency follows the
repository's pinned Firebase conventions. Integration starts once from the
provider used by MyApp, after the existing FirebaseBootstrap initializes Firebase.
Firebase-disabled builds, local replicas and non-mobile platforms use no remote
source. There is no new bootstrap await or dependency on Remote Config networking.

The controller reads activated cache immediately, hydrates SDK cache/defaults in
the background, then performs one background fetch/activate. Native fetch timeout
is 10 seconds, normal minimum fetch interval one hour, and each controller async
operation has a 15-second deadline. Preparation, cache, fetch, activation and
listener failures are contained and logged; failed fetch retains activated cache.
No timer polling or fetch on widget rebuild is introduced.

Real-time `onConfigUpdated` events already fetch new values in the native SDK.
Relevant platform-key updates activate serially and publish changed valid values.
Identical values do not publish duplicate state changes. Subscriptions are removed
on disposal. See [FlutterFire Remote Config guidance](https://github.com/firebase/flutterfire/blob/main/docs/remote-config/_get-started.md).

## Navigation and mandatory presentation

SOFT continues using the existing specific dialog-route dismissal, preserving a
share route pushed above it. HARD uses a stable modal layer above the router:
it blocks taps, background focus/semantics, and system back through a prioritized
child BackButtonDispatcher. Incoming cold/warm links and startup can still resolve
and persist their intended route beneath that layer; they cannot cover the block.
No navigation, pending share, durable context or attribution is cleared by policy.

When a live emergency value escalates SOFT to HARD, only the soft dialog route is
removed. One HARD layer remains. Clearing the remote minimum removes the layer
only if neither normal SemVer nor the Store minimum still requires HARD, and
releases back handling without replacing the router or deleting the equipment
route. Update uses upgrader's Store path; known platform Store URLs provide a
fallback if emergency enforcement arrives before Store lookup succeeds.

## Validation and manual QA

Completed validation:

- `flutter pub get` and `flutter pub get --enforce-lockfile`: passed with no
  existing dependency version changes. `version` moved from dev to runtime
  dependency; the launcher platform interface is declared for test injection.
- `flutter analyze --no-pub --fatal-infos --fatal-warnings`: no issues.
- Full CI-equivalent `flutter test --no-pub --reporter expanded
  --dart-define=ENABLE_FIREBASE_SERVICES=false
  --dart-define=ENABLE_PUSH_NOTIFICATIONS=false`: 1,003 passed, three local-only
  cases skipped. All three local replica configuration cases passed separately.
- Focused update-policy/upgrader/Remote Config/Public Share/auth/booking/router
  run: 493 passed, one Firebase-disabled configuration case skipped under
  default defines. Includes store-launch fallback and existing attribution suites.
- HARD pending/accepted share-context tests pass for registry and legacy links;
  prior cold/warm, Later/Ignore and login/OTP continuation tests still pass.
- Formatting, localization generation/drift and `git diff --check`: passed.
- Android `flutter build appbundle --release --dart-define-from-file=.env`:
  passed, `build/app/outputs/bundle/release/app-release.aab` (134,736,813 bytes).
  Generated manifests retain versionName 1.2.2 / versionCode 18. Non-fatal
  KGP/icon-font diagnostics were emitted; no artifact was uploaded.
- iOS compile/build was not run because this environment is Windows without
  macOS/Xcode. Device/Console manual QA is not claimed as performed.

Deterministic tests inject installed versions, Store versions/minimums, Remote
Config transport/updates and the URL launcher. No Store/Firebase networking or
production version changes are used in tests.

- Check patch and build-only releases: no dialog.
- Check minor: Update/Later/Ignore; dismiss and restart behavior.
- Check major and remote/Store emergency patch minimum: Update only, no barrier,
  hardware back or underlying route can bypass it.
- Check Android/iOS key selection, immediate activated cache, empty/malformed
  values, fetch timeout/failure and Store-vs-remote minimum precedence.
- Publish only in a separate QA Firebase environment when manually exercising
  real-time behavior: increase the minimum during a soft prompt, confirm one hard
  block, deliver a share link and verify its durable context beneath the block.
- Clear that QA minimum and verify that an otherwise silent update releases the
  block and preserves the intended equipment route.
- Re-run canonical outbound, legacy inbound, registry inbound, login/OTP and
  booking-attribution regression checks from the linked Public Share notes.

Device/Console QA is prepared, not claimed as performed. Production Remote Config
and rollout values are unchanged; no emergency minimum is configured by this PR.
