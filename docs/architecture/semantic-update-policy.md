# Semantic update policy and emergency rules

PR #62 continues on `feat/upgrader-public-share-outbound`. The exact-force
follow-up starts at `0ffe2f338776c8b85511cc3501db854b3efefdc5`. Application metadata
remains `1.2.2+18`. Public Share implementation, Backend, Admin/Web, database and
production Remote Config are unchanged. No deployment or upload is performed.

## Policy and precedence

`evaluateAppUpdate` is pure; `classifyAppUpdate` exposes its central
`AppUpdatePolicy` result. Complete SemVer inputs are validated with the existing
`version` parser and normalized to numeric major.minor.patch. Normal comparisons
ignore build metadata (and retain the existing normalization of prerelease
labels). For example, 1.2.10 is newer than 1.2.9, but 1.2.3+19 is not a newer
semantic version than 1.2.3+18. Malformed installed/Store versions fail safely.

Highest priority first:

1. A matching exact-force rule plus a proven newer Store semantic version: HARD.
2. Installed below the effective minimum, with a proven newer Store version that
   reaches that minimum: HARD.
3. Newer major: HARD.
4. Same major, newer minor: SOFT.
5. Same major/minor, newer patch: SILENT.
6. Otherwise: UP_TO_DATE.

The effective minimum is the higher valid Firebase Remote Config / Store
minimum. Missing or invalid sources cannot weaken the other valid source.
`upgrader` 13.7.0 still reads Store minimum metadata through
`versionInfo.minAppVersion`; this behavior has not been disabled.

UP_TO_DATE and SILENT show nothing. SOFT retains Update/Later/Ignore, barrier/back
dismissal and upgrader's normal three-day re-alert/Ignore persistence. HARD has
Update only and overrides previous Ignore/snooze. All HARD reasons use the same
mandatory UI. Standard KZ Play/App Store lookup and RU/KK/EN messages remain.
No production latest version, emergency value or debug forcing is configured.

## Deadlock protection and Store limitations

The actual upgrader 13.7.0 `UpgraderVersionInfo` and standard Store adapters expose
Store semantic versions, not reliable native Store build numbers. Therefore:

- Only `latestStore.major.minor.patch > installed.major.minor.patch` proves a
  usable newer release for exact-force enforcement.
- Same-semantic-version builds are never treated as proof of availability, even
  if a version display string has a larger `+build` suffix. For a defective
  1.3.0+27 build, publish a newer semantic release before enforcing its rule.
- Minimum enforcement additionally requires `latestStore >= effectiveMinimum`.
- Missing, invalid, equal or older Store versions cannot cause HARD through
  either emergency rule. The result is UP_TO_DATE when no newer release exists.
- An unreachable minimum is diagnosed and falls back to normal SemVer policy:
  patch SILENT, minor SOFT, or major HARD. The major case itself proves a newer
  release. Exact-force remains higher priority when its own condition is met.

Deferred emergency enforcement is logged through the existing Logger, deduplicated
until the relevant state changes. Remote Config and a known Store URL alone do
not prove release availability. A subsequent successful Store lookup can enable
HARD without replacing the router or losing pending navigation.

## Firebase Console configuration

Configure these manually in **Firebase Console -> Remote Config**:

| Platform | Parameter | In-app default |
| --- | --- | --- |
| Android | `min_supported_version_android` | empty string |
| iOS | `min_supported_version_ios` | empty string |
| Android | `force_update_versions_android` | `[]` (JSON string) |
| iOS | `force_update_versions_ios` | `[]` (JSON string) |

Illustrative configuration only; this PR does not publish these values:

```text
min_supported_version_android = "1.1.0"
force_update_versions_android = ["1.2.4", "1.3.0+27"]
min_supported_version_ios = ""
force_update_versions_ios = []
```

Use a **minimum** when all clients below X are no longer supported. Use a
**force list** when a particular released version/build is defective, but earlier
versions do not necessarily need to be blocked. Parameters are not secrets;
never put credentials or sensitive data in them. No emergency minimum or force
entry is configured by this PR.

### Exact-force syntax and parsing

- `"1.2.4"` matches every installed build of semantic version 1.2.4, including
  1.2.4+19 and 1.2.4+999.
- `"1.3.0+27"` requires semantic version 1.3.0 and native build exactly `27`.
  Builds `26`, `28` and `027` do not match.
- Installed build comes from structured `PackageInfo.buildNumber`, not an
  arbitrary display-version suffix. Native build identifiers are trimmed and
  otherwise compared exactly and case-sensitively. Dotted native builds such as
  `27.1` are supported by `"1.3.0+27.1"`.
- Rules require a complete stable semantic version, optionally followed by a
  legal SemVer build identifier. Prerelease force entries are unsupported and
  ignored. Numeric semantic cores cannot have leading zeroes.
- Empty/missing values and `[]` mean no forced versions. Outer whitespace around
  the JSON and each version is trimmed. Duplicates are harmless and deduplicated.
- Malformed JSON or a non-array root rejects the entire list with diagnostics.
  Non-string or invalid members are skipped individually with diagnostics;
  valid members remain active. Internal whitespace is not silently repaired.
- Empty/missing/invalid minimum strings mean no remote minimum. Malformed
  configuration never invents a HARD result; an independent valid rule may
  still apply.

## Cache, fetch and real-time safety

The existing official FlutterFire `firebase_remote_config` 6.7.0 integration
starts once from MyApp's provider, after FirebaseBootstrap initializes Firebase.
Firebase-disabled builds, local replicas and non-mobile platforms use no remote
source. There is no new bootstrap await or startup network dependency.

The controller immediately reads activated cache, hydrates SDK cache/defaults in
the background, then makes one background fetch/activate. Native fetch timeout is
10 seconds, normal minimum fetch interval one hour, and each async operation has
a 15-second deadline. Preparation, cache, fetch, activation and listener failures
are contained and logged; failed fetch retains activated cache. There is no
polling or fetch on widget rebuild.

Real-time `onConfigUpdated` events already fetch in the native SDK. Events for
either relevant platform key activate serially. Minimum and force list publish
as one configuration snapshot; identical snapshots do not trigger duplicate UI
state. Other-platform keys are not used. Subscriptions are removed on disposal.

## Navigation and mandatory presentation

SOFT keeps specific dialog-route dismissal, preserving a share route pushed above
it. HARD uses the existing stable modal layer above the router, blocking taps,
background focus/semantics and system Back through a prioritized child
BackButtonDispatcher. Cold/warm links and startup can still resolve and persist
their intended route underneath. Policy never deletes pending share URIs,
durable envelopes, guest intents, login/OTP continuation or attribution state.

A real-time emergency escalation removes only the SOFT dialog route and retains
one HARD layer. Removing the emergency rule releases the layer only if no other
rule still requires HARD. The router, equipment route and durable context remain.
Update uses upgrader's existing Store launch path. Known platform listing URLs
remain available as a voluntary launch fallback, not as availability evidence.

## Validation and manual QA

Deterministic tests inject installed version/native build, Store version/minimum,
Remote Config transport/events and URL launcher. No live Store/Firebase calls or
production metadata edits are needed. See PR #62 for final validation results.

- Check equal, build-only and patch releases: no dialog.
- Check minor: Update/Later/Ignore; dismiss and restart behavior.
- Check major, supported minimum and matching force rules: Update only, no
  barrier dismissal or system Back bypass.
- With installed 1.3.0+27, force `1.3.0+27` and Store 1.3.1: HARD. Builds 26/28
  with that rule remain SILENT. Force `1.3.0` instead to cover every build.
- With the same Store semantic version, a force rule or higher minimum must not
  hard-lock the app. A Store version below the floor follows normal policy.
- Check Android/iOS keys, cached activation, malformed JSON/members, timeout and
  fetch failure, and higher Remote Config / Store minimum precedence.
- In a separate QA Firebase environment only, add/remove a force rule during a
  SOFT prompt. Confirm one HARD layer, retained share route/context and safe
  rollback. Do not change production parameters for this verification.
- Re-run canonical outbound, legacy/new cold/warm inbound, guest/login/OTP and
  booking-attribution checks from the linked Public Share notes.

Device/Console QA is prepared, not claimed as performed. iOS compile validation
requires macOS/Xcode and cannot run in this Windows environment.
