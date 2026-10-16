# iOS dependency recovery on the existing Mac — no app build or publishing

Correction to the first audit (2026-10-16): PROKAT **already uses SwiftPM**.
Runner references FlutterGeneratedPluginSwiftPackage and has its prepare
pre-action. Both native Swift lockfiles are tracked:

- `ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved`
- `ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`

Their Firebase SDK 12.19.0 and Mapbox 11.29.1 pins agree with the Package.swift
manifests of locked firebase_core 4.15.0 / mapbox_maps_flutter 2.29.1. All 19 native
iOS plugins found in the local locked package cache have SwiftPM manifests.
CocoaPods legitimately has only Flutter when there are no fallback plugins.
Do not force a CocoaPods migration just to make Podfile.lock longer.

Remaining issue: Podfile.lock names CocoaPods 1.17.0, whereas CI pins 1.16.2.
Reconcile it using the actual pinned tool on Mac and verify the native graph.
This is a new verified dependency resolution, not proof of recovering every
native version from a historical published release. No Mac is a permanent CI
dependency. These steps require no Apple login, distribution key or profile.

## Procedure for the owner

1. Use a separate checkout/worktree on the Mac. Do not run these commands in a
   dirty production development directory. First make the reviewed preparation
   commit available to this checkout (sync of the feature branch is a separate
   Git action; do not merge or create a tag). From an existing repository:

   ```bash
   git fetch origin
   source_sha='REPLACE_WITH_REVIEWED_FULL_FEATURE_COMMIT_SHA'
   git worktree add --detach ../prokat-native-lock-check "$source_sha"
   cd ../prokat-native-lock-check
   git status --short
   ```

2. Read installed tool versions; do not change the global Xcode selection:

   ```bash
   flutter --version
   xcodebuild -version
   xcode-select -p
   ruby --version
   gem list --local cocoapods
   ```

   Flutter must be 3.47.2 (use the existing FVM SDK if needed). Xcode 26.6 is
   the CI target. If the Mac cannot run a compatible Xcode, report its versions;
   do not upgrade macOS/Xcode/signing automatically. Ruby 3.3 is the CI baseline;
   use an existing compatible user-managed Ruby, not sudo/system Ruby changes.

3. Download SDK/dependencies only. These commands do not compile an app:

   ```bash
   export COCOAPODS_DISABLE_STATS=true
   export FLUTTER_SWIFT_PACKAGE_MANAGER=true
   flutter precache --ios
   flutter pub get --enforce-lockfile
   test -f ios/Flutter/Generated.xcconfig
   git diff --exit-code -- pubspec.lock
   ```

   pub get regenerates platform plugin metadata and Generated.xcconfig on Mac;
   precache supplies the Flutter.xcframework required by the Podfile helper.
   No .env, Firebase native config or signing secrets are needed for resolution.
   The project now explicitly enables SwiftPM, avoiding dependence on a Mac's
   global Flutter feature preference. Do not edit global Flutter config.

4. If CocoaPods 1.16.2 is absent, install it alongside existing user gems:

   ```bash
   gem install --user-install cocoapods --version 1.16.2 --no-document
   export PATH="$(ruby -r rubygems -e 'print Gem.user_dir')/bin:$PATH"
   ```

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

5. Resolve Swift packages without a build and without provisioning updates:

   ```bash
   xcodebuild -resolvePackageDependencies \
     -workspace ios/Runner.xcworkspace -scheme Runner \
     -clonedSourcePackagesDirPath "$PWD/build/release/SourcePackages" \
     CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
   ```

   Do not add -allowProvisioningUpdates. The scheme's build pre-action is not
   an instruction to run a build; only dependency resolution is requested.
   Resolution can download source/binary dependencies and evaluate manifests.
   If a server requires credentials, stop with the hostname/error; do not paste
   access tokens into commands or disable security.

6. Verify generated locks with pinned versions, then ensure resolution succeeds
   strictly from the resolved file:

   ```bash
   dart tool/release/check_toolchain.dart ios-lock
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

   If the two Swift graphs differ, give both files/diff to the agent for review;
   do not silently discard one lock. Check no DEVELOPMENT_TEAM, signing identity,
   provisioning selection or entitlements changed. Do not commit a changed
   signing setting merely because a tool generated it.

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
Actual Mac resolution and dSYM upload remain NOT VERIFIED until owner action
and authorized integration testing.

Sources: [Flutter SwiftPM](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers),
[CocoaPods install vs update](https://guides.cocoapods.org/using/pod-install-vs-update.html),
[CocoaPods --deployment](https://guides.cocoapods.org/terminal/commands.html).
The pinned local Flutter SDK podhelper.rb and plugin Package.swift manifests
were also inspected; SDK commands above have not been executed on a Mac here.
