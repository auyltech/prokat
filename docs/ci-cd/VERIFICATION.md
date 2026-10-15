# Verification record — 2026-10-15

**VERIFIED** means executed local evidence only unless explicitly stated.
PASS appears only for an executed check; provider/account checks are BLOCKED or
PENDING USER ACTION. No RC/production tag or store upload was performed.

## Git delivery

Local branch: `feat/tag-only-mobile-release`. Implementation commits:
`e0391fd` audit, `faf59ba` shared release tooling, `ccf8294` Android,
`60b980e` Codemagic iOS. Documentation is committed separately after validation.
No upstream is configured for the feature branch; it does not track origin/dev.
Branch push waits for U1 verification of external auto-trigger settings.
No merge, tag creation, certificate/key changes or billing activation occurred.

## Executed checks

| Check | Method / actual result | Result | Limits |
| --- | --- | --- | --- |
| Repository/branch/HEAD/dirty worktree | SSH origin identity inspected; clean dev 7346fea; fetched origin; feature branch from origin/dev | PASS / VERIFIED | Privacy/settings cannot be established over Git transport |
| main/dev relationship | merge-base c07bbd0; 1 main-exclusive / 177 dev-exclusive commits | PASS / VERIFIED | No automatic merge/approval inferred |
| SDK | Local Flutter 3.47.2, Dart 3.13.2, framework d3b14c8769; .flutter-version/pubspec/.fvmrc agree | PASS / VERIFIED | Provider image still untested |
| Dependency resolution | `flutter pub get --enforce-lockfile`, exit 0; pubspec.lock unchanged | PASS / VERIFIED | Native Pods separately blocked |
| Full Flutter analysis | `flutter analyze --no-pub --fatal-infos --fatal-warnings`, exit 0 | PASS / VERIFIED | Windows host |
| Full existing+release Flutter suite | `flutter test --no-pub --dart-define=ENABLE_FIREBASE_SERVICES=false --dart-define=ENABLE_PUSH_NOTIFICATIONS=false`, 1096 passed, 3 skipped | PASS / VERIFIED | No device/Firebase/store calls; final additional Git-fixture tests checked separately |
| Release-focused suite after final source hardening | `flutter test --no-pub test/release`, 40 passed | PASS / VERIFIED | No real release tags created; Git ancestry fixtures use local temporary repositories |
| Dart release tooling analysis | `dart analyze tool/release test/release`, no issues | PASS / VERIFIED | Does not compile Gradle/Xcode |
| Tag parsing and store limits | Positive four-channel cases; leading zero/newline/injection/suffix/overflow invalid tags rejected | PASS / VERIFIED | Globs intentionally broad; parser is strict |
| Production source | Real local Git fixtures: main accepted; unmerged candidate/wrong SHA/dirty source rejected | PASS / VERIFIED | Live main ancestry checked at CI runtime, not approval proof |
| Production default deny | Missing/false/TRUE/1 variables rejected; only literal true accepted | PASS / VERIFIED | Authorized repository writers can change trusted code; no available ruleset assumed |
| Platform build history | Same/older platform attempt rejected; other platform numbers independent | PASS / VERIFIED | Legacy history comes from owner-confirmed historical floor |
| Notes | Mandatory RU/EN/KK, empty/missing/oversized/BOM/HTML/control/placeholder input rejection, exact locale exports | PASS / VERIFIED | Actual final release notes are not authored/approved yet |
| Workflow isolation | Python tests parse actual YAML and check canonical tag table; only tag push/tag events, no branch/PR/manual/schedule release trigger | PASS / VERIFIED | Local glob contract check, actual webhook deliveries pending U4 |
| GitHub syntax | actionlint 1.7.12 on android-release.yml, exit 0; downloaded asset SHA256 verified | PASS / VERIFIED | shellcheck/pyflakes not installed for this Windows validation |
| Codemagic schema | JSON Schema downloaded from https://codemagic.io/codemagic-schema.json, jsonschema validation exit 0 | PASS / VERIFIED | UI/account overrides and provider runtime not validated |
| Python store/config/signing policies | `python -m unittest discover -s tool/release -p '*_test.py'`, 18 passed | PASS / VERIFIED | API responses mocked; no real IPA |
| Android Play state policy | Ruby 3.3.10 Linux container, 7 cases including existing/new/track mismatch | PASS / VERIFIED | No network store calls |
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
| Codemagic UI tag-only settings | Not accessible; YAML is checked but UI is not | BLOCKED / NOT VERIFIED | U1 inspect Workflow Editor/Webhooks/schedules/duplicate app |
| Actual isolation on webhooks | No test tags pushed | BLOCKED / PENDING USER GATE U4 | Observe both providers on exact authorized RC refs; ordinary branch releases must remain absent |
| Google account/API scopes/Play versions | No credentials read or calls made | BLOCKED / NOT VERIFIED | U2 package, floor, primary locale, tracks, onboarding, managed publishing |
| Android existing upload key fingerprint/signature | Ignored local keystore exists; contents/passwords not read; no replacement | BLOCKED / NOT VERIFIED | U2 fingerprint + secrets; signed artifact in U4 |
| Real signed AAB/build/API upload | No release build or store write performed | BLOCKED / NOT VERIFIED | U4/A5 |
| Native iOS lock reproducibility | Inspected tracked Podfile.lock: only Flutter; full native dependencies missing; CocoaPods 1.17.0 vs pinned 1.16.2 | BLOCKED (actual baseline defect) | U3 regenerate/review/commit lock; CI fails before floating resolution |
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
docker run --rm --mount "type=bind,source=$($PWD.Path),target=/workspace" -w /workspace -e BUNDLE_GEMFILE=/workspace/tool/release/Gemfile -e BUNDLE_PATH=/workspace/build/release/gems -e BUNDLE_FROZEN=true ruby:3.3.10 bash -lc 'bundle install --jobs 4 --retry 0 && ruby tool/release/play_policy_test.rb && bundle exec ruby tool/release/sdk_contract_test.rb'
```

No test requires store credentials or creates a release tag. These checks do
not substitute for U4/A5. See [PLAN](PLAN.md), [setup](MANUAL_SETUP.md), and
[runbook](RELEASE_RUNBOOK.md) for remaining gates and recovery.
