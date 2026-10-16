# Verification record — 2026-10-16

**VERIFIED** means executed local evidence only unless explicitly stated.
PASS appears only for an executed check; provider/account checks are BLOCKED or
PENDING USER ACTION. No RC/production tag or store upload was performed.

## Git delivery

Local branch: `feat/tag-only-mobile-release`. Implementation commits:
`e0391fd` audit, `faf59ba` shared release tooling, `ccf8294` Android,
`60b980e` Codemagic iOS. Documentation is committed separately after validation.
No upstream is configured for the feature branch; it does not track origin/dev.
The original five commits through `f42a5a8` were pushed with the owner's explicit
permission using an exact branch ref and `push.followTags=false`; remote SHA and
unchanged tags were verified. The owner subsequently confirmed Codemagic sees
both YAML workflows and no build started. Follow-up preparation commits remain
local; the unrelated owner modification to `prokat.iml` is preserved/excluded.
Follow-up code commits: `f2bafdb` Android, `750fea4` iOS native dependencies.
The final documentation update is a separate commit. No `lib/main.dart` changes.
No merge, tag creation, certificate/key changes or billing activation occurred.

## Executed checks

| Check | Method / actual result | Result | Limits |
| --- | --- | --- | --- |
| Repository/branch/HEAD/dirty worktree | SSH origin identity inspected; clean dev 7346fea; fetched origin; feature branch from origin/dev | PASS / VERIFIED | Privacy/settings cannot be established over Git transport |
| main/dev relationship | merge-base c07bbd0; 1 main-exclusive / 177 dev-exclusive commits | PASS / VERIFIED | No automatic merge/approval inferred |
| SDK | Local Flutter 3.47.2, Dart 3.13.2, framework d3b14c8769; .flutter-version/pubspec/.fvmrc agree | PASS / VERIFIED | Provider image still untested |
| Dependency resolution | `flutter pub get --enforce-lockfile`, exit 0; pubspec.lock unchanged | PASS / VERIFIED | Actual Mac native resolution remains untested |
| Full Flutter analysis | `flutter analyze --no-pub --fatal-infos --fatal-warnings`, exit 0 | PASS / VERIFIED | Windows host |
| Full existing+release Flutter suite | `flutter test --no-pub --dart-define=ENABLE_FIREBASE_SERVICES=false --dart-define=ENABLE_PUSH_NOTIFICATIONS=false`, 1103 passed, 3 skipped; local log `build/release/flutter-tests-20261016.log` | PASS / VERIFIED | No device/Firebase/store calls |
| Release-focused suite after final source hardening | `flutter test --no-pub test/release`, 41 passed | PASS / VERIFIED | No real release tags created; Git ancestry fixtures use local temporary repositories |
| Dart release tooling analysis | `dart analyze tool/release test/release`, no issues | PASS / VERIFIED | Does not compile Gradle/Xcode |
| Tag parsing and store limits | Positive four-channel cases; leading zero/newline/injection/suffix/overflow invalid tags rejected | PASS / VERIFIED | Globs intentionally broad; parser is strict |
| Production source | Real local Git fixtures: main accepted; unmerged candidate/wrong SHA/dirty source rejected | PASS / VERIFIED | Live main ancestry checked at CI runtime, not approval proof |
| Production default deny | Missing/false/TRUE/1 variables rejected; only literal true accepted | PASS / VERIFIED | Authorized repository writers can change trusted code; no available ruleset assumed |
| Platform build history | Same/older platform attempt rejected; other platform numbers independent | PASS / VERIFIED | Legacy history comes from owner-confirmed historical floor |
| Notes | Mandatory RU/EN/KK, empty/missing/oversized/BOM/HTML/control/placeholder input rejection, exact locale exports | PASS / VERIFIED | Actual final release notes are not authored/approved yet |
| Workflow isolation | Python tests parse actual YAML and check canonical tag table; only tag push/tag events, no branch/PR/manual/schedule release trigger | PASS / VERIFIED | Local glob contract check, actual webhook deliveries pending U4 |
| GitHub syntax | actionlint 1.7.12 on android-release.yml, exit 0; downloaded asset SHA256 verified | PASS / VERIFIED | shellcheck/pyflakes not installed for this Windows validation |
| Codemagic schema | JSON Schema downloaded from https://codemagic.io/codemagic-schema.json, jsonschema validation exit 0 | PASS / VERIFIED | UI/account overrides and provider runtime not validated |
| Python store/config/signing policies | `python -m unittest discover -s tool/release -p '*_test.py'`, 25 passed | PASS / VERIFIED | API responses mocked; no real IPA |
| Exact Android U2 inventory | Actual workflow expressions match 7 required Secrets, 2 Variables, optional production Secret; upload certificate verified before build | PASS / VERIFIED | Live repository settings/secret contents not read |
| Upload certificate comparator | 6 tests using temporary disposable RSA fixtures: DER/PEM/hash match, mismatch, wrong password, missing alias, malformed certificate; original fixture unchanged | PASS / VERIFIED | Existing application key never opened; separate keyPassword not verified |
| Play access probe safety | Real locked Supply client with fake API: snapshot, API/abort failure, unsupported locale, retries=0; temporary edit always aborted after successful creation | PASS / VERIFIED | No actual Google authentication, upload-permission proof or historical ledger |
| iOS dependency architecture correction | Runner project/scheme show existing SwiftPM; both tracked Package.resolved graphs agree on 19 pins (Python JSON comparison), Firebase 12.19.0 / Mapbox 11.29.1; 19 installed native plugins have Package.swift manifests | PASS / VERIFIED (source inspection) | Supersedes earlier incorrect missing-native-Pods diagnosis; actual Xcode resolution pending Mac |
| Android Play state policy | Ruby 3.3.10 Linux container, 9 cases including existing/new/track mismatch and unknown-error redaction | PASS / VERIFIED | No network store calls |
| Actual Fastlane SDK contract | Bundler frozen install, pinned Fastlane 2.241.0; real Google API methods/Supply option names checked; `ruby -c play.rb` exit 0 | PASS / VERIFIED | No credential authentication or edit commit |
| Apple CLI syntax/retry semantics | Installed CLI 0.70.0 `publish --help` and builds list help; source confirms altool-retries=0 performs one attempt | PASS / VERIFIED | Mac altool/signing unavailable on Windows |
| Signing input safety | CI-only input writer, refusal to overwrite, 0600 files; Java-properties escaping unit test; no secrets in added source | PASS / VERIFIED (code/local tests) | Live CI log masking not tested |
| Artifact configuration | No Android upload-artifact; no IPA/AAB in Codemagic artifacts; only failed-symbols ZIP | PASS / VERIFIED (config) | Actual provider collection/ephemeral cleanup pending A5 |
| Secret path/key scan and whitespace | `python tool/release/scan_staged.py` on staged implementation/docs; `git diff --check` | PASS / VERIFIED | Pattern scan is not a complete secret detector; existing ignored key files not staged/read |

## Intentionally blocked and external checks

| Check | Actual state / method | Result | Required action |
| --- | --- | --- | --- |
| GitHub private status, Actions settings, billing/rulesets | `gh` has no authenticated session; no account reads possible | BLOCKED / PENDING USER ACTION | U1; SSH fetch alone is not account-setting verification |
| Codemagic account/Free eligibility for company-owned commercial project | Official docs distinguish Personal indie/hobby from paid Team; no account available | BLOCKED / PENDING USER ACTION | U1 eligibility confirmation; never enable billing automatically |
| Codemagic UI tag-only settings | Owner reports YAML workflows visible, Default Workflow triggers disabled, no schedules/builds after branch push | VERIFIED BY OWNER / local account access NOT VERIFIED | U1 billing/eligibility/privacy still pending; no actual CI build authorized |
| Actual isolation on webhooks | No test tags pushed | BLOCKED / PENDING USER GATE U4 | Observe both providers on exact authorized RC refs; ordinary branch releases must remain absent |
| Google account/API scopes/Play versions | No credentials read or calls made | BLOCKED / NOT VERIFIED | U2 package, floor, primary locale, tracks, onboarding, managed publishing |
| Android existing upload key fingerprint/signature | Ignored local keystore exists; contents/passwords not read; no replacement | BLOCKED / NOT VERIFIED | U2 fingerprint + secrets; signed artifact in U4 |
| Real signed AAB/build/API upload | No release build or store write performed | BLOCKED / NOT VERIFIED | U4/A5 |
| Native iOS lock reproducibility | Flutter-only Podfile.lock is valid SwiftPM fallback, NOT proof of missing native dependencies. Firebase/Mapbox are pinned in Package.resolved. Remaining CocoaPods 1.17.0 metadata conflicts with pinned 1.16.2 | BLOCKED / actual Mac NOT VERIFIED | Follow IOS_DEPENDENCIES.md: normal pinned pod install, resolve existing SwiftPM pins, review public lock diffs; do not fabricate a full native Podfile.lock |
| Current native-lock fail-closed guard | `dart tool/release/check_toolchain.dart ios-lock` executed on current baseline; exits 1 with pinned CocoaPods 1.16.2 requirement | PASS / VERIFIED (expected rejection) | No lock file edited; still BLOCKED for actual iOS release |
| SwiftPM Crashlytics tool location | YAML uses resolved firebase-ios-sdk/Crashlytics/upload-symbols, not nonexistent Pods FirebaseCrashlytics; strict resolved-file and post-build drift checks added | PASS / VERIFIED (config) | Xcode checkout layout and successful symbols acceptance require U4/A5 |
| iOS export compliance | No ITSAppUsesNonExemptEncryption declaration in current Info.plist | BLOCKED / PENDING USER ACTION | Owner confirms declaration at U3; no guessed legal metadata |
| Apple API/signing/profile | Bundle/team/capabilities read from repo only; portal state unknown | BLOCKED / NOT VERIFIED | U3 existing distribution identity + profiles + API app record |
| Real signed IPA / production APNs | Only pure entitlement policy tested | BLOCKED / NOT VERIFIED | U4 export codesign/profile checks, push smoke test A5 |
| Actual TestFlight availability / App Review / public release | No binary upload/submission | BLOCKED / NOT VERIFIED | U4/A5; production still requires U5 |
| Crashlytics R8 mapping + all dSYMs acceptance/readable crashes | Existing integration audited; upload commands added, not executed against Firebase | BLOCKED / NOT VERIFIED | U4/A5 verify real native + Dart stack traces, absent missing-symbol warnings |
| Accepted-build recovery API operations | Pure duplicate/UNKNOWN policy tested; no real promotion/resubmission | BLOCKED / NOT VERIFIED | A5 inspect accepted build without reupload; recovery only with exact-state authorization |
| Production activation | Gate secrets not created/set by agent; no tag created | BLOCKED BY DESIGN | Successful A5 and explicit U5, first production tag by owner |
| Quota consumption and artifact deletion | No provider runs launched by this work | BLOCKED / NOT VERIFIED | A5 compare real account usage and collection result |

## Reproduction of local checks

```powershell
flutter pub get --enforce-lockfile
flutter analyze --no-pub --fatal-infos --fatal-warnings
flutter test --no-pub test/release
dart analyze tool/release test/release
python -m pip install -r tool/release/requirements.txt
python -m unittest discover -s tool/release -p '*_test.py'
```

Use a local virtual environment for Python tools. Ruby checks on Windows may
use installed Ruby 3.3.10 or the same local Docker image used during validation:

```powershell
docker run --rm --mount "type=bind,source=$($PWD.Path),target=/workspace" -w /workspace -e BUNDLE_GEMFILE=/workspace/tool/release/Gemfile -e BUNDLE_PATH=/workspace/build/release/gems -e BUNDLE_FROZEN=true ruby:3.3.10 bash -lc 'bundle install --jobs 4 --retry 0 && ruby tool/release/play_policy_test.rb && bundle exec ruby tool/release/sdk_contract_test.rb && bundle exec ruby tool/release/play_store_test.rb'
```

No test requires store credentials or creates a release tag. These checks do
not substitute for U4/A5. See [PLAN](PLAN.md), [setup](MANUAL_SETUP.md), and
[runbook](RELEASE_RUNBOOK.md) for remaining gates and recovery.
