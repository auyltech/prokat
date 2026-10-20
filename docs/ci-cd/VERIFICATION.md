# Verification record — updated 2026-10-20

Historical execution records below are preserved. Current commands and retry
rules: [CICD-README](../../CICD-README.md). Lean CLI verification is recorded
separately in [LEAN_RELEASE_CLI](LEAN_RELEASE_CLI.md).

**VERIFIED** means executed local evidence only unless explicitly stated.
PASS appears only for an executed check; provider/account checks are BLOCKED or
PENDING USER ACTION. No RC/production tag or store upload was performed.

Latest complete preflight/status and risk ordering: [PREFLIGHT.md](PREFLIGHT.md).
Short owner guides: [OWNER_CHECKLIST.md](OWNER_CHECKLIST.md). Android and iOS
remain **NOT READY for U4** while external/native prerequisites are pending.

## U2 Play API Access Probe — 2026-10-19

**PASS / VERIFIED** against the actual Google Play API, 11:12:51–11:12:54 UTC.
Local credential identity matched project `prokat-bfbec` and service account
`prokat-play-ci@prokat-bfbec.iam.gserviceaccount.com`; the only package addressed
was `com.auyltech.prokat`.

| Operation | Actual HTTP status | Result |
| --- | --- | --- |
| OAuth authorization | 200 | PASS |
| Temporary edit create | 200 | PASS |
| Temporary edit GET | 200 | PASS |
| Temporary edit delete | 204 | PASS |

No working release changes, uploads, edit commit, track/metadata updates or
request retries occurred. Credentials/token were not printed. The existing
`play_access.rb` snapshot performs broader reads than authorized for this probe,
so an ephemeral restricted script used the locked SDK instead; repository code
and dependencies were unchanged.

**VERIFIED BY OWNER:** all 7 Android GitHub Secrets and 2 Variables are created;
Internal Testing is configured with `PROKAT developers` (2 testers). Historical
maximum versionCode **18** was reconfirmed by the owner on 2026-10-19; this probe
did not read build history or establish a permanently current maximum.

Google Play API access is confirmed. Actual AAB build, private-key signing,
upload and the correctness of GitHub Secret contents remain **NOT VERIFIED**
until separately authorized U4. This result does not authorize RC or production.

## Mac iOS preflight — 2026-10-20

Executed on the home Mac. No tag, push to `dev`/`main`, cloud build, signed IPA,
certificate or profile was created during the check.

| Check | Result | Limit |
| --- | --- | --- |
| FVM Flutter | 3.47.2, Dart 3.13.2 | Global PATH Flutter stayed 3.44.2 and was not switched |
| CocoaPods | 1.16.2 metadata-only lock fix; `--deployment` stable | Homebrew 1.17.0 was not installed; CI pin unchanged |
| SwiftPM | Both Package.resolved unchanged after two strict resolves | Local Xcode 26.3, not Codemagic 26.6 |
| Unsigned iOS release | `flutter build ios --release --no-codesign` exit 0, unsigned `Runner.app` | Not an IPA, not store signing |
| Distribution identity | Absent for `VT7KXG8NBR` | Do not mint a certificate on this Mac |
| Export compliance key at Mac preflight | Absent at that check; subsequently set to Boolean false on 2026-10-20 | See current decision below; no new signed IPA |

Owner-confirmed Codemagic group `prokat-ios-release` values, stored in
Codemagic and not as new Git secrets: `APP_STORE_APP_ID` 6817078475,
`IOS_HISTORICAL_MAX_BUILD` 17, `TESTFLIGHT_GROUP` `AuylTech Test Team`.
Recording them does not prove the Apple API key, Firebase plist, Mapbox token
or a distribution identity are present. U3 and U4 are not complete.

Git at probe and documentation follow-up: clean baseline on
`feat/tag-only-mobile-release`, HEAD `0ec2e3c706469dee70dce693227b8ac35bcc8fac`.
`7cdd45e` is an ancestor, followed by three commits: `2a33dc65` (Mac dependency
validation documentation), `5ec9cc99` (Apple export-compliance documentation),
and `0ec2e3c7` (owner's `prokat.iml`: 18 IDE exclusion entries). The range changes
only four CI/CD documents and `prokat.iml`, not runtime/workflow code. History
was not rewritten; the owner's IDE file remains untouched by this follow-up.

## Export compliance closure — 2026-10-20

Clean Git preflight on `feat/tag-only-mobile-release`, HEAD
`0c0108b54d957bb3c3d5ad0bce43f74a7d232ed8`; no worktree created.
The owner-confirmed ASC questionnaire/territories and current Apple guidance
justify Boolean false for this scenario; see [decision](APPLE_EXPORT_COMPLIANCE.md).

Executed locally on Windows:

- Python `plistlib` + XML parse: valid plist, unique top-level keys, exact Boolean
  false, no compliance code; all other parsed values equal HEAD's original plist.
- `build/release/python-env/Scripts/python.exe -B -m unittest discover -s tool/release -p '*ios*test.py' -v`:
  **22 tests PASS**, including all 5 `verify_ios_test.py` tests. These are local
  unit tests with mocked Apple/publisher calls, not an API probe or publication.
- `git diff --check`: PASS. Release verifier/publishing scripts unchanged.

The first test invocation with system Python lacked `jwt`; rerunning in the
existing release environment passed without installing/changing dependencies.
No cloud build, release tag, signed IPA check, upload or store mutation occurred.
Other U1/U3 prerequisites and explicit U4 permission remain pending.

## Git delivery

Local branch: `feat/tag-only-mobile-release`. Implementation commits:
`e0391fd` audit, `faf59ba` shared release tooling, `ccf8294` Android,
`60b980e` Codemagic iOS. Documentation is committed separately after validation.
No upstream is configured for the feature branch; it does not track origin/dev.
The original five commits through `f42a5a8` were pushed with the owner's explicit
permission using an exact branch ref and `push.followTags=false`; remote SHA and
unchanged tags were verified. The owner subsequently confirmed Codemagic sees
both YAML workflows and no build started. Follow-up preparation commits remain
local; the unrelated owner modification to `prokat.iml` was subsequently committed
by the owner in `0ec2e3c7` and is preserved unchanged.
Follow-up code commits: `f2bafdb` Android, `750fea4` iOS native dependencies.
The final documentation update is a separate commit. No `lib/main.dart` changes.
No merge, tag creation, certificate/key changes or billing activation occurred.

## Executed checks

| Check | Method / actual result | Result | Limits |
| --- | --- | --- | --- |
| Repository/branch/HEAD/dirty worktree | SSH origin identity inspected; clean dev 7346fea; fetched origin; feature branch from origin/dev | PASS / VERIFIED | Privacy/settings cannot be established over Git transport |
| Initial A0 main/dev relationship | merge-base c07bbd0; 1 main-exclusive / 177 dev-exclusive commits at A0 | PASS / VERIFIED (historical) | Current fetch/state recorded in PREFLIGHT; no automatic merge/approval inferred |
| SDK | Local Flutter 3.47.2, Dart 3.13.2, framework d3b14c8769; .flutter-version/pubspec/.fvmrc agree | PASS / VERIFIED | Provider image still untested |
| Dependency resolution | `flutter pub get --enforce-lockfile`, exit 0; pubspec.lock unchanged | PASS / VERIFIED | Actual Mac native resolution remains untested |
| Full Flutter analysis | `flutter analyze --no-pub --fatal-infos --fatal-warnings`, exit 0 | PASS / VERIFIED | Windows host |
| Full existing+release Flutter suite | Repeated preflight: `flutter test --no-pub --dart-define=ENABLE_FIREBASE_SERVICES=false --dart-define=ENABLE_PUSH_NOTIFICATIONS=false`, 1103 passed, 3 skipped; local log `build/release/flutter-tests-preflight.log` | PASS / VERIFIED | No device/Firebase/store calls; current feature source, not an uncreated merge commit |
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
| Python preflight policies | Selected config/Apple-store/IPA/adapter modules: 34 passed (5/17/5/7) | PASS / VERIFIED | API responses/publish process mocked; earlier 6 key fixture tests not regenerated/rerun in this preflight |
| Exact Android U2 inventory | Actual workflow expressions match 7 required Secrets, 2 Variables, optional production Secret; upload certificate verified before build | PASS / VERIFIED | Live repository settings/secret contents not read |
| Upload certificate comparator | Earlier preparation: 6 tests using temporary disposable RSA fixtures: DER/PEM/hash match, mismatch, wrong password, missing alias, malformed certificate; original fixture unchanged | PASS / VERIFIED | No fixture keys generated in the subsequent real-key U2 check; separate keyPassword not verified |
| Play access probe safety | Real locked Supply client with fake API: snapshot, API/abort failure, unsupported locale, retries=0; temporary edit always aborted after successful creation | PASS / VERIFIED | No actual Google authentication, upload-permission proof or historical ledger |
| iOS dependency architecture correction | Runner project/scheme show existing SwiftPM; both tracked Package.resolved graphs agree on 19 pins (Python JSON comparison), Firebase 12.19.0 / Mapbox 11.29.1; 19 installed native plugins have Package.swift manifests | PASS / VERIFIED (source inspection) | Supersedes earlier incorrect missing-native-Pods diagnosis; actual Xcode resolution pending Mac |
| Android Play state policy | Ruby 3.3.10 Linux container with network disabled, 22 cases including known floor18 and later live19/20, duplicates/track mismatch/redaction | PASS / VERIFIED | Latest store maximum still NOT VERIFIED; owner historical18 is a minimum, not cached current state |
| Malformed Play codes | Snapshot mocks reject nil/unknown/zero/negative/overflow instead of converting them to 0; edit cleanup attempted | PASS / VERIFIED | No actual Google access |
| Android release debug fallback | Removed debug identity fallback; configuration contract checks signing and stage order/cleanup | PASS / VERIFIED (source/config) | Real Gradle signing/AAB remains NOT VERIFIED |
| TestFlight group destination | RC requires exactly one existing internal group; missing/duplicate/external blocked in unit test | PASS / VERIFIED | Actual group/read permissions pending U3 |
| Apple access mode | GET-only path needs no tag, cannot call publisher; API failure never reports success; repeated fresh reads tested | PASS / VERIFIED (mocked API) | Not executed against actual account; does not prove write rights |
| Apple localized notes adapter | Real pinned CLI inheritance/Locale types; only existing locales updated, missing notes/API failure stop submission, first-version exception handled | PASS / VERIFIED (7 tests + CLI help) | Native upload/review NOT VERIFIED; version guard requires revalidation on CLI upgrade |
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
| Google Play API access | 2026-10-19 real restricted probe: identity/package match, OAuth 200, edit create/GET 200, delete 204; no release changes | PASS / VERIFIED | Not upload/signing proof; no live build-history, locale, onboarding or managed-publishing reads |
| GitHub Android inputs / Internal Testing | Owner confirms 7 Secrets, 2 Variables and configured Internal Testing (2 testers) | VERIFIED BY OWNER | Secret contents and runner usage NOT VERIFIED until U4; no credentials extracted from GitHub |
| Android existing upload certificate | Existing `android/app/upload-keystore.jks`, alias `upload`, PrivateKeyEntry: MATCH against owner-supplied Play SHA256 using existing comparator/keytool; local password consumed without logging; before/after keystore hash and properties bytes unchanged | PASS / VERIFIED | Play Console SHA source confirmed by owner, not independent account access; no key generation/export of private material/signing/store call |
| Android private key password and real signing | Certificate check does not decrypt/use the private key to sign an AAB; no release build performed | BLOCKED / NOT VERIFIED | Actual signed artifact in authorized U4/A5; never infer keyPassword validity from certificate match |
| Real signed AAB/build/API upload | No release build, artifact upload or edit commit performed; temporary probe edit deleted | BLOCKED / NOT VERIFIED | U4/A5 |
| Native iOS lock reproducibility | 2026-10-20 home Mac: CocoaPods metadata reconciled to 1.16.2; graph/checksums unchanged; `pod install --deployment` SHA-stable; both schema2 Swift graphs, 19 pins, strict resolve twice, locks unchanged; `ios-lock` check passed. Firebase 12.19.0, Mapbox 11.29.1 | PASS / VERIFIED on Xcode 26.3 | Not an Xcode 26.6 image run, signed IPA, or store upload. See the Mac preflight section |
| Current native-lock fail-closed guard | `dart tool/release/check_toolchain.dart ios-lock` executed on current baseline; exits 1 with pinned CocoaPods 1.16.2 requirement | PASS / VERIFIED (expected rejection) | No lock file edited; still BLOCKED for actual iOS release |
| Native dependencies focused follow-up | Windows inspection of the Flutter-only pod graph and 19 Swift pins, then the 2026-10-20 Mac install/strict resolution above | PASS / VERIFIED | Xcode image parity with Codemagic 26.6 remains open |
| Mac procedure syntax | 11 Bash blocks checked by bash -n; two Ruby snippets by ruby -c in offline local container | PASS / VERIFIED (syntax only) | No Mac command, pod install or xcodebuild executed |
| SwiftPM Crashlytics tool location | YAML path matches the resolved checkout. On the 2026-10-20 Mac resolve, `firebase-ios-sdk/Crashlytics/upload-symbols` was present | PASS / VERIFIED (path on Xcode 26.3) | Upload acceptance and readable crashes remain U4/A5 |
| iOS export compliance | Source Info.plist declares Boolean false. Audit finds standard Dart TLS/BoringSSL outside Apple OS; no app-owned non-standard algorithm found. Owner confirms Kazakhstan only, France unavailable, standard-outside-OS questionnaire saved without document request. See APPLE_EXPORT_COMPLIANCE.md | CLOSED / OWNER-CONFIRMED ASC RESULT | Closed SDK internals remain an audit limitation; recheck SDK/crypto/territory changes. Actual exported IPA verification remains U4; no build/upload authorization |
| Apple API/signing/profile | Mac login keychain has no Apple Distribution identity and no App Store profile for team `VT7KXG8NBR` / `com.auyltech.prokat`. Local profiles found belong to another team/app. Codemagic also has no suitable PROKAT identity yet. API key is not activated | BLOCKED / NOT VERIFIED | Account Holder activates the App Store Connect API; signing is then Codemagic API-managed. Do not create certificates on the Mac |
| Real signed IPA / production APNs | Unsigned local release on Xcode 26.3 built `Runner.app` and codesign reported it unsigned. No IPA. Source entitlements still say development APNs | BLOCKED / NOT VERIFIED | U4 signed IPA, production APNs and push smoke test A5 |
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
