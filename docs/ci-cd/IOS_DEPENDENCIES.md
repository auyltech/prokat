# One-time native dependency check on Mac mini — no app build/signing/publishing

Current CI network handling: [SwiftPM retry contract](IOS_SWIFTPM_RETRIES.md).
The historical commands below remain direct evidence, not a new execution.
RC/production CI retry only recognized transient resolver downloads, never
update packages or rewrite locks. Permanent/unknown errors and lock drift block.

Status 2026-10-20: **Mac dependency execution PASS** on macOS 15.7.3 arm64.
FVM Flutter 3.47.2, CocoaPods 1.16.2, local Xcode 26.3 (17C529). Codemagic
still pins Xcode 26.6; that image was not installed here and is not required
to keep the lock check closed.

Tracked result: `ios/Podfile.lock` generator metadata is `COCOAPODS: 1.16.2`.
The pod graph, Flutter checksum and PODFILE CHECKSUM
`4b015915ec662986b54bf30ab778da63f7dda016` match the previous 1.17.0 lock.
`pod _1.16.2_ install --deployment` left the lock SHA unchanged. Both schema 2
Swift graphs stayed equal (19 pins, Firebase 12.19.0, Mapbox 11.29.1). Two
strict `xcodebuild -resolvePackageDependencies -onlyUsePackageVersionsFromResolvedFile`
runs exited 0 and did not rewrite either Package.resolved.
`check_toolchain.dart ios-lock` passed. `pubspec.lock`, Podfile, the Xcode
project, Info.plist and entitlements were unchanged.

An unsigned `flutter build ios --release --no-codesign` produced a local
`Runner.app` on Xcode 26.3. It was not signed and no IPA was created. That is
not a Codemagic 26.6, signing, dSYM-upload or store PASS. Crashlytics
`upload-symbols` was present in the resolved `firebase-ios-sdk` checkout.
No Apple Distribution identity or App Store profile for team `VT7KXG8NBR` and
`com.auyltech.prokat` was on this Mac. Certificates and profiles were not created.
The procedure below records how the check was run; do not rerun it to recreate
the same metadata fix.

Correction to the first audit (2026-10-16): PROKAT **already uses SwiftPM**.
Runner references FlutterGeneratedPluginSwiftPackage and has its prepare
pre-action. Both native Swift lockfiles are tracked:

- `ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved`
- `ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`

Their Firebase SDK 12.19.0 and Mapbox 11.29.1 pins agree with the Package.swift
manifests of locked firebase_core 4.15.0 / mapbox_maps_flutter 2.29.1. All 19 native
iOS plugins found in the local locked package cache have SwiftPM manifests.
The inventory has 20 iOS entries: 19 `native_build: true`;
`path_provider_foundation` is `native_build: false` and has no Package.swift.
It must not be misdiagnosed as a missing native CocoaPods fallback.
CocoaPods legitimately has only Flutter when there are no fallback plugins.
Do not force a CocoaPods migration just to make Podfile.lock longer.

Resolved 2026-10-20: the lock previously named CocoaPods 1.17.0. That field is
generator metadata from commit `0457b9f`, not a native library pin and not proof
that CocoaPods 1.17.0 is the CI tool. This Mac already had the pinned 1.16.2
executable; the Homebrew 1.17.0 formula was available and was not installed.
PODFILE CHECKSUM remains `4b015915ec662986b54bf30ab778da63f7dda016`. Both Swift
graphs are schema 2 and equal on all 19 identities, locations, versions and
revisions. The metadata rewrite does not recover every native version from a
historical published release. No Mac is a permanent CI dependency. The check
did not need an Apple login, distribution key or profile.

## Procedure for the owner

Historical record of the 2026-10-20 check. The lock already says `COCOAPODS: 1.16.2`;
do not repeat `pod install` to change it again.

Run blocks in order in a dedicated Terminal session; stop on any failed command
or unexpected tracked diff. No Apple login, signing identity, Firebase config,
Mapbox token or production `.env` is needed for this check.

1. Use a separate checkout/worktree on the Mac. Do not run these commands in a
   dirty production development directory. First make the reviewed preparation
   commit available locally (see the no-push bundle option below). Do not assume
   origin contains the latest local feature commits. From an existing repository:

   ```bash
   source_sha='REPLACE_WITH_REVIEWED_FULL_FEATURE_COMMIT_SHA'
   git cat-file -e "$source_sha^{commit}"
   git worktree add --detach ../prokat-native-lock-check "$source_sha"
   cd ../prokat-native-lock-check
   test "$(git rev-parse HEAD)" = "$source_sha"
   test -z "$(git status --porcelain)"
   git status --short
   ```

2. Read installed tool versions; do not change the global Xcode selection:

   ```bash
   uname -m
   sw_vers
   flutter --version
   xcodebuild -version
   xcode-select -p
   ruby --version
   gem --version
   gem list --local cocoapods
   command -v pod || true
   pod --version || true
   ```

   Flutter must be 3.47.2 (use the existing FVM SDK if needed). Xcode 26.6 is
   the CI target. If the Mac cannot run a compatible Xcode, report its versions;
   do not upgrade macOS/Xcode/signing automatically. If another installed Xcode
   is required, select its existing path with `DEVELOPER_DIR` in this Terminal
   only; do not use `sudo xcode-select --switch` or enable provisioning updates.
   Ruby is NOT explicitly pinned in iOS YAML (Android Ruby3.3.10 is separate).
   Current Xcode26.6 image docs list Ruby4.0.5 and CocoaPods1.16.2. Record actual
   Mac Ruby; use an existing compatible user-managed installation, not sudo/system
   Ruby changes. Different Ruby means dependency validation, not proof of an
   identical provider environment.

3. Download SDK/dependencies only. These commands do not compile an app:

   ```bash
   export COCOAPODS_DISABLE_STATS=true
   export FLUTTER_SWIFT_PACKAGE_MANAGER=true
   flutter precache --ios
   flutter pub get --enforce-lockfile
   test -f ios/Flutter/Generated.xcconfig
   git diff --exit-code -- pubspec.lock
   git diff --exit-code -- ios/Podfile ios/Runner/Info.plist ios/Runner/Runner.entitlements
   ```

   pub get regenerates platform plugin metadata and Generated.xcconfig on Mac;
   precache supplies the Flutter.xcframework required by the Podfile helper.
   No .env, Firebase native config or signing secrets are needed for resolution.
   The project now explicitly enables SwiftPM, avoiding dependence on a Mac's
   global Flutter feature preference. Do not edit global Flutter config.

4. Diagnose the three distinct versions, then reconcile metadata with the CI pin:

   ```bash
   ruby -ryaml -e 'puts "Locked generator: #{YAML.load_file("ios/Podfile.lock").fetch("COCOAPODS")}"'
   pod --version || true
   pod _1.16.2_ --version
   ```

   The first line should currently say 1.17.0; default `pod` can be any installed
   version; the last command must say 1.16.2. If that gem is absent, isolate the
   installation in this worktree and Terminal (not a global/user-gem upgrade):

   ```bash
   export GEM_HOME="$PWD/build/release/native-cocoapods-gems"
   export GEM_PATH="$GEM_HOME"
   export PATH="$GEM_HOME/bin:$PATH"
   gem install cocoapods --version 1.16.2 --no-document
   pod _1.16.2_ --version
   ```

   Closing this Terminal restores inherited tool selection; these exports are
   not written to a shell profile. Existing CocoaPods installations stay intact.
   If Ruby/dependency installation fails, retain the error and stop; do not use
   sudo or replace existing signing/tools. If the version already exists, skip
   installation. Always invoke the selected version explicitly:

   ```bash
   (cd ios && pod _1.16.2_ install)
   ```

   Do not delete Podfile.lock or use pod update. Unlike release CI, this initial
   repair deliberately does not use --deployment: the lock's tool metadata may
   need updating. New Pods appear only for genuine CocoaPods fallback plugins.
   Pod install can integrate local Xcode project files; inspect that diff. It
   does not compile/archive/sign an IPA or manage portal certificates.
   Expected tracked change: **only COCOAPODS metadata 1.17.0 → 1.16.2**. Do not
   manually replace that line. Validate against the original Git lock:

   ```bash
   ruby -ryaml -e '
     before = YAML.safe_load(IO.popen(["git", "show", "HEAD:ios/Podfile.lock"], &:read))
     after = YAML.safe_load(File.read("ios/Podfile.lock"))
     abort "FAIL: tool metadata is not 1.16.2" unless after["COCOAPODS"] == "1.16.2"
     abort "FAIL: pod graph/checksums changed; review instead of updating" unless
       before.reject { |k, _| k == "COCOAPODS" } == after.reject { |k, _| k == "COCOAPODS" }
     puts "PASS: generator metadata only; pod graph and checksums unchanged"
   '
   git diff -- ios/Podfile.lock ios/Runner.xcodeproj/project.pbxproj
   ```

   A graph/checksum/project change is NOT automatically approved. Stop and return
   the diff; do not run pod update, deintegrate, repo-update, delete locks/Pods
   or change the CI pin to 1.17.0 as a workaround.

5. Resolve Swift packages without a build and without provisioning updates:

   ```bash
   xcodebuild -resolvePackageDependencies \
     -workspace ios/Runner.xcworkspace -scheme Runner \
     -clonedSourcePackagesDirPath "$PWD/build/release/SourcePackages" \
     -onlyUsePackageVersionsFromResolvedFile \
     CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
   ```

   Do not add -allowProvisioningUpdates. The scheme's build pre-action is not
   an instruction to run a build; only dependency resolution is requested.
   Resolution can download source/binary dependencies and evaluate manifests.
   If a server requires credentials, stop with the hostname/error; do not paste
   access tokens into commands or disable security.
   Keep strict resolution on the FIRST attempt too: no unlocked retry if it
   fails. Manifest evaluation/SDK downloads are allowed; app compile/archive
   is not part of this command.

6. Verify generated locks with pinned versions, then ensure resolution succeeds
   strictly from the resolved file:

   ```bash
   dart tool/release/check_toolchain.dart ios-lock
   git diff --exit-code -- \
     ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved \
     ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
   native_lock_sha="$(shasum -a 256 ios/Podfile.lock)"
   (cd ios && pod _1.16.2_ install --deployment)
   test "$native_lock_sha" = "$(shasum -a 256 ios/Podfile.lock)"
   xcodebuild -resolvePackageDependencies \
     -workspace ios/Runner.xcworkspace -scheme Runner \
     -clonedSourcePackagesDirPath "$PWD/build/release/SourcePackages" \
     -onlyUsePackageVersionsFromResolvedFile \
     CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
   git diff --check
   git status --short
   git diff -- ios/Podfile.lock \
     ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved \
     ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved \
     ios/Runner.xcodeproj/project.pbxproj ios/Runner/Runner.entitlements
   ```

   Dart checks both Swift graphs semantically (identities/locations/versions/
   40-hex revisions), not just file existence. Repeated deployment pod install
   and strict Swift resolve must leave all three locks unchanged after the
   initial metadata fix.

   If the two Swift graphs differ, give both files/diff to the agent for review;
   do not silently discard one lock. Check no DEVELOPMENT_TEAM, signing identity,
   provisioning selection or entitlements changed. Do not commit a changed
   signing setting merely because a tool generated it.

   Final scope gate (any other tracked file is an unexpected change):

   ```bash
   unexpected_native_files="$(git diff --name-only -- . ':!ios/Podfile.lock')"
   test -z "$unexpected_native_files"
   git diff --check
   ```

   If Xcode migrates Package.resolved formatting/schema, stop for review of both
   graphs and the new file format. It is not a dependency-update license and
   cannot be labelled PASS automatically.

7. Return the three public lockfiles and any project integration diff to the
   agent (or a separately agreed commit). No credentials, xcuserdata, Pods,
   generated xcconfigs or local .env files. The agent will inspect/check them
   on Windows. No release tag, CI build, archive or publishing permission is
   implied by this procedure. Do not open Xcode Organizer/Transporter or run
   flutter build/run/archive as part of lock recovery.

## CI consequences

CI keeps SwiftPM plus CocoaPods fallback, uses `pod install --deployment`, and
resolves Swift packages with `-onlyUsePackageVersionsFromResolvedFile` before
building. Lock drift after IPA creation blocks store upload. Crashlytics uses
`SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/upload-symbols` from the
explicitly resolved checkout, instead of assuming Firebase is installed in Pods.
Mac resolution of the pinned graph is VERIFIED on Xcode 26.3. dSYM upload and
execution on the Codemagic Xcode 26.6 image remain NOT VERIFIED until authorized
integration testing.

## PASS / FAIL / BLOCKED and file boundaries

| Result | Required evidence |
| --- | --- |
| PASS (dependencies only) | Correct SHA, Flutter3.47.2, Xcode26.6, invoked pod1.16.2; metadata-only lock fix verified; strict Swift resolutions and deployment pod install exit0; Dart native-lock check passes; no unexpected tracked changes |
| FAIL | Different dependency pins/checksums; missing/divergent locks; signing/team/capability/Info.plist/project changes; lock drift after deployment; failing validation command |
| BLOCKED | Required tool unavailable, SDK server/auth/network failure, or Xcode/macOS/Ruby setup needs intervention; do not loosen validation |
| NOT VERIFIED | Windows, or only reading files/tool versions without completing Mac commands |

2026-10-20 execution passed the lock and tool checks on Flutter 3.47.2 and
CocoaPods 1.16.2 with local Xcode 26.3. That does not satisfy the Xcode 26.6
image row above. Do not move the CI pin to 1.17.0.

Expected tracked diff: `ios/Podfile.lock` COCOAPODS line only. Both Package.resolved
files should stay unchanged. Do not change pubspec.yaml/lock, Podfile, Xcode project/
scheme/xcconfigs, Info.plist, entitlements, CI pins, signing settings or prokat.iml.
Ignored outputs may appear: `Pods/`, `.symlinks/`, generated xcconfig/plugin
registrants/Swift package, SourcePackages and Dart/Flutter caches. Do not commit
those, XCUserData, `.env`, Firebase config, keys, profiles or credential logs.
Return tool versions, exit statuses, safe diff and the three public lockfiles;
no IPA/AAB is produced. PASS here is NOT signing/build/TestFlight/App Store PASS.

## Getting the private feature commit onto the Mac without a push

Only if the approved SHA is absent there. These are optional owner commands,
not operations performed by the agent. On Windows, from this feature branch:

```powershell
git branch --show-current
git rev-parse HEAD
if ((git branch --show-current) -ne 'feat/tag-only-mobile-release') { throw 'Wrong branch' }
if (Test-Path -LiteralPath '..\prokat-native-check.bundle') { throw 'Choose a new bundle filename' }
git bundle create ..\prokat-native-check.bundle refs/heads/feat/tag-only-mobile-release
git bundle verify ..\prokat-native-check.bundle
```

Transfer the private bundle through an existing secure local channel/removable
drive. It contains private committed source/history, not ignored local keystores;
never upload it publicly or send it in chat. On the Mac, in an existing repo:

```bash
git bundle verify /PRIVATE/TRANSFER/prokat-native-check.bundle
git fetch --no-tags /PRIVATE/TRANSFER/prokat-native-check.bundle \
  refs/heads/feat/tag-only-mobile-release
```

Use the exact approved SHA in step1. This updates FETCH_HEAD, not dev/main or
a remote server; no push, merge, tag or build. Use a new bundle filename if one
already exists, not an unreviewed overwrite. No bundle was created in this audit.

Sources: [Flutter SwiftPM](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers),
[CocoaPods install vs update](https://guides.cocoapods.org/using/pod-install-vs-update.html),
[CocoaPods --deployment](https://guides.cocoapods.org/terminal/commands.html).
[Codemagic Xcode26.6 image](https://docs.codemagic.io/specs-macos/xcode-26-6/).
The pinned local Flutter SDK podhelper.rb and plugin Package.swift manifests
were also inspected; SDK commands above have not been executed on a Mac here.
