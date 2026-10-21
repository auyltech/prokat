# Preflight PROKAT — updated 2026-10-20

Current publishing correction: [offline parser and IPA retention](IOS_PUBLISHING.md).
The historical help-only CLI check and no-IPA storage policy below are superseded:
0.70.0 requires positive attempt counts; 1/1/1 means no retry. Full parser tests
now cover generated argv. IPA uses standard Codemagic retention on all outcomes.

Current owner workflow: [CICD-README](../../CICD-README.md). Dated account/native
results below remain evidence, not a live readiness verdict. CLI adoption still
requires review/integration into main and explicit release authorization.

Android: **NOT READY for U4**. iOS: **NOT READY for U4**.
U4-B local preparation (main guard, 1.2.3 notes, tests and integration preview)
is recorded in [RC_1.2.3_PREPARATION.md](RC_1.2.3_PREPARATION.md).
It does not authorize PR merge, release tags, cloud builds or uploads.
Autonomous code preparation is complete for the inspected branch; account,
native-Mac and owner-approval checks below remain. A local test is not a store
release. No cloud build, store request, tag, push, merge, billing change or new
secret/signing identity was created during the original 2026-10-16 preflight.
The separately authorized 2026-10-19 Play probe below made only the listed
OAuth/edit requests; this documentation follow-up makes no new API requests.

## U2 update — 2026-10-19

**Play API access: PASS / VERIFIED.** Expected project/service-account identity
and package `com.auyltech.prokat` matched. OAuth **200**, temporary edit create
**200**, edit GET **200**, edit delete **204**. No upload, commit, track/metadata
update, working release change or retry. See [evidence](VERIFICATION.md#u2-play-api-access-probe--2026-10-19).

Owner confirms all **7 Android GitHub Secrets and 2 Variables** are created and
Internal Testing is configured (`PROKAT developers`, 2 testers). The historical
maximum versionCode **18** was reconfirmed by the owner on 2026-10-19; it remains
a floor, not a replacement for fresh store-state checks before an upload.
Actual AAB build, signing, upload and GitHub Secret contents remain **NOT VERIFIED
until U4**. Production gates remain closed; no RC permission is implied.

Current inspected HEAD is `0ec2e3c706469dee70dce693227b8ac35bcc8fac` on the same
feature branch. It descends from `7cdd45e` through `2a33dc65` (Mac dependency docs),
`5ec9cc99` (Apple compliance docs), then the owner's `0ec2e3c7` (`prokat.iml`,
18 IDE exclusions). No runtime/workflow code changes occur in that range.
Git history and the owner's IDE file were not changed by this follow-up.

## Baseline and Git scope

- Started on `feat/tag-only-mobile-release`, HEAD `c946d3e`; four local commits
  after the previously delivered `origin/feat/tag-only-mobile-release` (`f42a5a8`).
- Origin identity: `git@github-work:auyltech/prokat.git`; fetched with
  `git fetch --prune --no-tags origin`. No upstream added, no branch switched.
- Current remote dev: `b927dd37f468d189112c3695d55efacfae4a5392`; main:
  `b481e0c4f0f13dc711b722d8e760b9048966983e`. Dev advanced by one application
  commit after feature-base `7346fea`. Those changes were not merged/rebased;
  tests here cover the feature source only, not an uncreated integration commit.
- At the original preflight, owner modification `prokat.iml` was uncommitted;
  it is now committed by the owner in `0ec2e3c7` and remains untouched here.
  No Dart runtime/application code, production config, secrets or native locks
  changed. Only Android release-signing behavior, release tools/tests and docs.
- Code commits: `1aa9417` Android history/signing, `b85eb60` Apple group/profile
  checks and GET-only probe, `f41e3b0` fail-closed Apple localized notes.

## Architecture reconciliation

| Input | GitHub release | Codemagic release | Destination |
| --- | --- | --- | --- |
| `rc/android/vX.Y.Z+N` | Android only | None | Play Internal |
| `android/vX.Y.Z+N` | Android only, U5 gate | None | Play Production |
| `rc/ios/vX.Y.Z+N` | None | ios-rc only | Internal TestFlight group |
| `ios/vX.Y.Z+N` | None | ios-production only, U5 gate | App Review, AFTER_APPROVAL |
| Branch push / PR / schedule / dispatch | No release | No release | None |

Globs select provider/workflow; strict Dart parsing separately rejects malformed
tags, wrong platform/channel/event and unapproved source. Production additionally
requires current main ancestry and literal protected gate value `true`.
The existing unrelated PR quality workflow has a manual trigger but does not
build/publish releases; it was not changed.

Owner CLI reads version/build from pubspec at fresh remote main; CI derives them
from the immutable tag and rejects disagreement. Common counter: 1..9999,
increasing across both platforms except same-version/build/SHA pairs.
Git/cached snapshots are only bounds: live preflight before build and before
upload remains mandatory. Accepted binaries are never re-uploaded. Current
publishers do not implement promotion; accepted-RC production needs separate
owner-authorized recovery, not another same-build tag.

RU/EN/KK notes stay in Git, all mandatory and approved, plain UTF-8 <=500 UTF-16
units. Play mapping ru-RU/en-US/kk; Apple ru/en-US/en-GB, KK retained in Git with
English store fallback. Actual store locales remain to be confirmed by owner.

## Confirmed issues corrected

1. Android trusted only a configured historical floor. `PlayPolicy` now rejects
   a floor below the owner-confirmed **18**. This is a lower bound, NOT a claim
   that nobody uploaded 19/20 since confirmation. Fresh API snapshots still run
   before build and upload, with no automatic upload retry. Malformed observed
   codes now produce UNKNOWN rather than silently becoming 0 via `to_i`.
2. Gradle retained debug release-signing fallback outside CI. It is removed;
   a missing release identity is unconfigured and must fail signing validation.
   Debug development builds use their separate AGP config. Existing upload key
   was not changed. Its earlier certificate MATCH / alias `upload` remains
   evidence, not proof of private keyPassword or actual AAB signing.
3. Pinned Codemagic CLI merely warns for a missing beta group. RC preflight now
   reads all beta groups and requires exactly one matching **internal** group.
   Missing/ambiguous/external groups block before any build/upload.
4. IPA profile checks now require matching app/team/distribution/APNs, and reject
   a ProvisionedDevices field even if empty. Actual codesign/profile validation
   still needs the authorized signed IPA on macOS.
5. Codemagic CLI 0.70.0 catches App Store localization API failures and may
   continue to review; common notes also offered unconfigured English locales.
   A narrow adapter (`apple_publish.py`) keeps standard Codemagic upload/review
   logic but replaces that one metadata method: only existing locales, mandatory
   translations, immediate stop on error. No auto-create listing locale, no
   submission after failed notes. First App Store version does not accept What's
   New; adapter skips that PATCH, preserving Git notes. The adapter is version
   guarded and SDK-contract tested; no Fastlane or new orchestrator for iOS.

Added one reuse of existing Apple preflight, `ios_store.py access`: GET-only
app/builds/uploads/internal-group check, no tag/IPA/CI/signature/submission. It
does not prove write permissions. Play access probe creates/deletes a temporary
edit (not strictly read-only HTTP), never uploads/commits. Neither probe was run
against actual accounts during the original preflight. The restricted Play
probe was subsequently executed successfully on 2026-10-19 as recorded above;
Apple account verification remains pending.

## Actually executed checks

| Check | Evidence | Status / limitation |
| --- | --- | --- |
| Flutter resolution | `flutter pub get --enforce-lockfile`, lock unchanged | VERIFIED |
| Full Flutter analysis | fatal infos/warnings, exit 0 | VERIFIED, Windows |
| Full Flutter tests | 1103 passed, 3 skipped; ignored log `build/release/flutter-tests-preflight.log` | VERIFIED, no native/store integration |
| Focused release tests | 41 passed, parser/notes/gates/Git fixtures | VERIFIED, no real tags |
| Release Dart analysis | No issues | VERIFIED |
| Python preflight policies | 34 passed: config 5, Apple store 17, IPA policy 5, metadata adapter 7 | VERIFIED, APIs/process publishing mocked |
| Earlier upload certificate tests | 6 passed in previous preparation; not regenerated/rerun now | Prior VERIFIED only; no keys generated in this preflight |
| Ruby Play policy | 22 cases including floor18/newer live state/duplicates/redaction | VERIFIED, Docker network disabled |
| Supply SDK / state probe | Actual pinned methods/options; mocked API errors/abort/malformed codes; retries=0 | VERIFIED, Docker network disabled |
| Apple adapter SDK | Real 0.70.0 inheritance/Locale types and `--help` | VERIFIED, no credentials/store access |
| GHA syntax | actionlint 1.7.12 exit 0 | VERIFIED, shellcheck/pyflakes disabled locally |
| Codemagic schema | Fresh official JSON Schema download, validation exit 0 | VERIFIED, not a runner execution |
| Gradle ordering suspicion | Isolated Gradle9.3.1 Kotlin DSL fixture `help --offline` succeeded with logic before plugins | VERIFIED: suspected ordering bug not reproduced; NOT an Android app build |
| Signing/storage contracts | No debug fallback, preflight/verify/symbols before publish; Android always-cleanup; no AAB/IPA artifact upload | VERIFIED config only |
| Whitespace/staged credential scan | Executed before commits | VERIFIED pattern scan, not a complete secret detector |

Android mapping must upload to Crashlytics before Play. On iOS all native dSYMs
upload before Apple; a failed symbol stage retains the recovery ZIP, successful
upload removes it. No obfuscate/split-debug-info. Actual Firebase symbol acceptance
and readable crash reports remain NOT VERIFIED. The 2026-10-20 Mac resolve
found Crashlytics `upload-symbols` in the pinned checkout; the upload was not run.

## Remaining blockers, highest priority first

1. **Remaining U2/U3 checks:** Play API access is now VERIFIED; Android GitHub
   inputs and Internal Testing are owner-confirmed. Actual AAB/signing/upload
   remain NOT VERIFIED until U4; the probe did not inspect live build history,
   locales, onboarding or managed publishing. Apple Team API key, existing
   identities/profiles, credentials installation and Apple probe remain pending.
2. **U1 financial/security facts:** private visibility, blocking GitHub budgets,
   Codemagic Personal commercial eligibility still owner/support pending.
   Do not activate billing, change visibility or start runs to test eligibility.
3. **iOS native locks:** closed on the home Mac on 2026-10-20. CocoaPods metadata
   is 1.16.2, `--deployment` is stable, and both SwiftPM graphs resolved strictly
   without drift. An unsigned iOS release build passed on local Xcode 26.3.
   Codemagic remains Xcode 26.6; that image was not executed. No signed IPA.
4. **Apple export compliance — CLOSED (2026-10-20):** owner confirmed Kazakhstan
   only, France unavailable, standard encryption outside Apple OS and no document
   request after saving the questionnaire. Info.plist now declares Boolean false.
   Recheck SDK/crypto/territory changes; see [decision](APPLE_EXPORT_COMPLIANCE.md).
   Actual exported IPA verification remains U4; other prerequisites stay open.
5. **Release source/content/delivery:** approve exact SHA/version/new platform
   numbers and Git release notes. The Mac lock and preflight docs may be pushed
   to the feature branch only. That push is not a release and does not authorize
   tags, `dev`/`main`, or store delivery.
6. **U4/A5 real integration:** AAB/IPA, actual signing, Play/TestFlight availability,
   Crashlytics, webhook isolation and quota usage remain NOT VERIFIED. Store
   acceptance, processing, review and public release are distinct states.
7. **Residual trusted-writer/store risks:** trusted repo/CI administrators can
   change pipeline/gates; no paid protected-tag/environment feature is assumed.
   Play testing permission covers more than Internal. Apple Team Key covers all
   team apps. Reconcile human console edits before access probes/releases.

## Owner action and acceptance

Do not recreate the configured Play account/key, 7 Secrets or 2 Variables, or
repeat the successful probe. For remaining owner prerequisites follow
[two short U2/U3 guides](OWNER_CHECKLIST.md), using
[ANDROID_SETUP](ANDROID_SETUP.md) / [MANUAL_SETUP](MANUAL_SETUP.md) for exact
sources/secret storage and [IOS_DEPENDENCIES](IOS_DEPENDENCIES.md) for Mac steps.
Native lock validation is done. The home Mac keychain has no PROKAT Apple
Distribution identity, so there is no private key there to export. Do not return
to that Mac to create certificates. Remaining account, API and signing setup is
not a local Xcode project change. Codemagic API-managed signing still waits on
Account Holder API activation.

**READY FOR U4 has NOT been reached.** It can be requested only after U1/U2/U3,
native locks/export compliance, non-publishing access checks, approved source/
notes/numbers and authorized delivery. Then request explicit permission for
specific RC tags; do not create them now. Production remains closed until A5/U5.

References checked 2026-10-16: [Apple Team API](https://developer.apple.com/help/app-store-connect/get-started/app-store-connect-api),
[betaGroups endpoint](https://developer.apple.com/documentation/appstoreconnectapi/get-v1-apps-_id_-betagroups),
[Codemagic signing](https://docs.codemagic.io/yaml-code-signing/signing-ios/),
[Codemagic publishing](https://docs.codemagic.io/yaml-publishing/app-store-connect/),
[Xcode image](https://docs.codemagic.io/specs-macos/xcode-26-6/),
[Play setup](https://developers.google.com/android-publisher/getting_started).
The installed pinned Flutter/Codemagic/Fastlane source was also inspected.
