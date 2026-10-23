# Lean release owner CLI

Owner instructions and PowerShell installation: [CICD-README](../../CICD-README.md).

Apple publishing: [offline CLI contract and IPA retention](../../docs/ci-cd/IOS_PUBLISHING.md).
`ios_store.py validate-publish` parses the same generated publish argv with the
pinned CLI 0.70.0, before dependency resolution/build, without API/actions/upload.
It requires explicit attempt counts 1/1/1, not invalid zeros or defaults 10/3/3.
The final argv is revalidated before publishing. Version/parse failures block.
Both iOS workflows retain `build/ios/ipa/*.ipa` on every outcome using standard
Codemagic retention; no exit-code-only cleanup or additional storage is introduced.

SwiftPM CI: [retry policy and troubleshooting](../../docs/ci-cd/IOS_SWIFTPM_RETRIES.md).
`swiftpm_resolve.py start|resolve` is CI-only and invokes only the hardcoded locked
resolver. Three attempts at most, backoffs 15/45 seconds, recognized network logs
plus exit 74 only. Exact HEAD locks are checked before/after; raw resolver output
is never logged. Limits: 600 seconds per command, 32 minutes total and a 60-minute
phase deadline from the first script; existing 90-minute workflow stays unchanged.
Tests use fake runners/clocks, never actual SDK downloads or publishing.

Apple diagnostics: [manual workflow, codes and recovery](../../docs/ci-cd/IOS_CI_DIAGNOSTICS.md).
The custom Python client (early auth, diagnostic and release preflight) reads
private PEM **only** from `PROKAT_ASC_PRIVATE_KEY_PEM`, with no fallback to
`APP_STORE_CONNECT_PRIVATE_KEY`. Owner must manually add this Secret to existing
`prokat-ios-release`: the original raw PEM of the same API key, real newlines,
without quoting/base64/references. Python does not read files or resolve env
references. Leave existing `APP_STORE_CONNECT_*` values, integration/signing and
Codemagic CLI publishing unchanged; issuer and key identifier still come from
their existing variables and must match the isolated PEM. No new Apple API key.

`apple_diagnostic.py auth --channel rc|production` is network-free;
`apple_diagnostic.py check --build 20` reads Apple through GET only. Both use
in-memory credentials, fixed sanitized codes and no snapshots/publisher. Real
credentials/API calls require separate owner approval. The manual Codemagic
workflow targets main and uses only `requirements-apple.txt` (PyJWT 2.15.1,
cryptography 50.0.2). The ordinary release requirements include that same file;
the CLI and YAML pins remain unchanged. Legacy `ios_store.py access` still writes
a snapshot and must not be substituted for the no-write diagnostic.

Cross-platform entry point from repository root:

```text
dart tool/release/cli.dart android rc --dry-run
dart tool/release/cli.dart ios rc --dry-run
dart tool/release/cli.dart android production --dry-run
dart tool/release/cli.dart ios production --dry-run
```

No yes/force/SHA/version override. Production dry-run requires a fresh local
`refs/remotes/origin/main` that matches `git ls-remote` and already contains
that commit's objects; it never fetches. A real `prokat-prod-*` command is the
release intent after `Continue? [y/N]`. It does not ask for `PUBLISH PRODUCTION`
and does not read a local `PRODUCTION_PUBLISHING_ENABLED`. CI independently
requires the permanent cloud gate `PRODUCTION_PUBLISHING_ENABLED=true` and
rejects Android GitHub Actions re-runs (`GITHUB_RUN_ATTEMPT` must be `1`).
Per-release `PRODUCTION_RELEASE_AUTH_*` variables are not used. Never enable
the cloud gate for testing. RC is Internal only and uses the same `y/N`
prompt. No automatic production promotion exists.

Normal planning fetches main into a disposable bare object cache, not the user's
checkout. Cancel leaves checkout/index/refs/object database unchanged; temp cache
is deleted. Dry-run compares ls-remote with the existing local origin/main ref
and reads objects only for that exact SHA; it never creates the cache or
fetches. A missing or stale tracking ref, or a missing object, fails closed
with a manual refresh instruction.
After a real production command (or RC confirmation): recheck clean tree, remote
main and tags, fetch origin/main, recheck again, create annotated tag at approved
SHA, push exactly that ref, print the provider pipeline URL.
No branch switching/pushing, credentials or store requests. Existing tags are
immutable. An ambiguous push retains the local tag and prints recovery guidance.
The final check/push race cannot be atomic with a read-only protected main.
If that push fails, is interrupted, or times out, the exit code is not proof
the tag is absent: do not push it again by hand. Re-classify with
`dart tool/release/cli.dart <platform> <channel> --resume-push <tag> --expect-sha <40-hex>`
(`--dry-run` classifies only). The command reads the local annotated tag and
`git ls-remote` for that tag object and its peeled commit. `REMOTE_SAME` means
the push already landed: watch the provider and do not push again. A missing
workflow run is not proof that no run was created. `REMOTE_DIFFERS` and
`REMOTE_UNKNOWN` stop with no changes. `REMOTE_ABSENT` pushes the exact ref
only when this is not a dry-run, remote main still equals the expected SHA,
build history allows the number, and the owner types the full tag name; it
then reads the remote tag again. Any other result stops until a new
confirmation. The command never deletes, moves, or force-updates a tag.

Shared release.dart owns strict tag parsing, pubspec parsing, metadata/notes,
production gate and common-counter rules. CI still checks current main ancestry,
provider event and tag identity, then existing signature/config/live-store checks.
Source main must contain the new CLI contract before it can be tagged by this CLI.
Cached play-state.json/apple-state.json, if available under build/release, are
conservative history evidence, not live credentials or proof a number is free.
Malformed snapshots block. No snapshot is required: CI is authoritative live.
Common counter is 1..9999. A same-version/build paired tag requires identical SHA
and the same channel; RC and production never share a build number.
Same-platform different-channel tag blocks (promotion unsupported).

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
