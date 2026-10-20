# Lean release owner CLI

Owner instructions and PowerShell installation: [CICD-README](../../CICD-README.md).
Cross-platform entry point from repository root:

```text
dart tool/release/cli.dart android rc --dry-run
dart tool/release/cli.dart ios rc --dry-run
dart tool/release/cli.dart android production --dry-run
dart tool/release/cli.dart ios production --dry-run
```

No yes/force/SHA/version override. Production dry-run also requires the explicit
local production gate; CI independently requires its protected gate. Never enable
either for testing. RC is Internal only. No automatic production promotion exists.

Normal planning fetches main into a disposable bare object cache, not the user's
checkout. Cancel leaves checkout/index/refs/object database unchanged; temp cache
is deleted. Dry-run only uses ls-remote plus existing local objects, never creates
the cache or fetches; missing objects fail closed with a manual refresh instruction.
After confirmation: recheck clean tree, remote main and tags, fetch origin/main,
recheck again, create annotated tag at approved SHA, push exactly that ref.
No branch switching/pushing, credentials or store requests. Existing tags are
immutable. An ambiguous push retains the local tag and prints recovery guidance.
The final check/push race cannot be atomic with a read-only protected main.

Shared release.dart owns strict tag parsing, pubspec parsing, metadata/notes,
production gate and common-counter rules. CI still checks current main ancestry,
provider event and tag identity, then existing signature/config/live-store checks.
Source main must contain the new CLI contract before it can be tagged by this CLI.
Cached play-state.json/apple-state.json, if available under build/release, are
conservative history evidence, not live credentials or proof a number is free.
Malformed snapshots block. No snapshot is required: CI is authoritative live.
Common counter is 1..9999. A same-version/build paired tag requires identical SHA;
same-platform different-channel tag blocks (promotion unsupported).

Local regression (no real remote tags/builds):

```powershell
flutter test --no-pub test/release --reporter expanded
flutter analyze --no-pub --fatal-infos --fatal-warnings
python -B -m unittest discover -s tool/release -p '*_test.py'
ruby tool/release/play_policy_test.rb
git diff --check
```

cli_test.dart injects Git, immutable blobs, confirmations and store snapshots;
source_test.dart exercises real Git ancestry only inside disposable local fixtures.
No test has permission to create a release tag in the application's origin.
Production permission tests use in-memory environment maps, never CI secrets.
