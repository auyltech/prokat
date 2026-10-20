# Lean release CLI — review record

Date: 2026-10-20. Preparation only; no real release tags, cloud builds,
uploads, store/credential changes, gate activation or main mutations.

## Git/source evidence

Started clean on dev 192c8288fa2f237ae7373c1de3b41e65ca68b309.
Fetched origin dev/main, dev was already up to date (ff-only check).
Created feat/lean-release-cli in the existing checkout, no worktree.
Main c59884a1a1c53dfda4a119799d51b1785f51ac03 already contains the prior
1.2.3+19 squash PR #65. Direct main/dev tree diff contains only the old
CICD-README.md; no need to revert main or discard release content.
History divergence is 1 main-only / 182 dev-only commits, not 182 content changes.
pubspec is 1.2.3+19 on both. Normal feature → dev → main reviewed PRs suffice.
No merges are performed by this preparation or CLI.

Remote tag inspection found archive tags and legacy v1.0.12+4 only, no
Android/iOS contract release tags. Known store floors remain Play18 / Apple17;
no local play-state.json/apple-state.json was available. No live store request
was made; build19 availability is UNKNOWN until authorized CI live preflight.

## Implementation contract

Four PowerShell functions wrap dependency-free Dart cli.dart. Shared release.dart
parses strict tags/pubspec/notes, production gate and common build history.
CI also rejects tagged pubspec disagreement. Same version/build on the other
platform requires the same peeled commit; same-platform channel reuse blocks
because publishers upload new binaries and implement no promotion.

Normal planning uses a disposable bare object cache, deleted on completion.
Cancel leaves the actual checkout, index, refs and object database unchanged.
Dry-run uses read-only remote refs and cached immutable blobs: no fetch or cache
creation. Missing cached blobs block and require a separate owner cache refresh.
Git optional locks are disabled for read-only status/index inspection.
After consent the actual origin/main is fetched and remote main/tags checked
again, then exactly one annotated tag is pushed. Ambiguous push retains local
tag with safe inspection/recovery instructions. No force/delete/branch push.

Local preview checks main metadata, required translations, workflow guard presence,
production API/Firebase flags and iOS Boolean compliance. It is not YAML semantic
validation or proof of signing, credentials, CI tool availability, store rights,
profile capabilities or live number availability. Those remain CI/store checks.
There is a residual non-atomic main-check/tag-push race; CI independently verifies
main ancestry and exact webhook tag identity. Trusted repo admins remain trusted.

Main must contain the new CLI contract before the CLI can tag it. Until that PR
is merged, a real repository dry-run blocks on the missing main CLI blob by design.
Do not bypass this by tagging feature/dev. Review/merge and a new owner GO remain
required for real publication. Production 1.2.3+19 remains forbidden.

## Verification

Executed local evidence (no provider/store runs):

| Check | Result |
| --- | --- |
| Flutter full regression | Final rerun: 1190 passed / 3 skipped (first run: 1189 / 3 before the extra wrapper safety test) |
| Release subset | 118 passed, including shared CI rules and PowerShell collision/typo protection |
| Flutter analyze --no-pub --fatal-infos --fatal-warnings | PASS, no issues |
| dart analyze tool/release test/release; Dart formatting gate | PASS |
| Python unittest discover tool/release '*_test.py' | 45 passed, including 4 documentation/link tests and iOS verifier/store mocks |
| Ruby Play policy | 22 offline cases passed |
| Locked Supply/Google API contract + Play store snapshot tests | PASS, no real store requests |
| actionlint (both workflows, shellcheck/pyflakes disabled) | PASS |
| Codemagic JSON schema; iOS plistlib / Boolean false | PASS |
| PowerShell loading/reloading/forwarding/collision/unknown-flag checks | PASS |
| git diff --check | PASS |

Historical reports are preserved, not re-labelled as new executions.
Commands and test entry points: [tooling README](../../tool/release/README.md).
Store snapshot / publisher tests are offline; no credentials are needed locally.
Release tests create synthetic objects/refs only in disposable fixtures or mocks,
never actual origin release tags.

## Review / handoff

Changed scope: cli.dart, prokat-release.ps1, shared release.dart, cli_test.dart,
release_test.dart and cli_docs_test.py; CICD-README, root README, releases README,
tool/release README; CI/CD index, runbook, setup/checklist/preflight, current-rule
pointers in PLAN/VERIFICATION/RC preparation, and this evidence record.
No app behavior/version bump, native signing, Firebase inputs, entitlements,
workflow trigger or publisher changes. No push is performed in this task.

Suggested PR title: `feat(release): main-driven owner CLI and consistent runbooks`.
Base dev, compare feat/lean-release-cli. Review common-counter/pairing,
tag immutability/races, production deny/promotion stop and cancellation semantics.
After branch publication and feature → dev review/merge, review the full dev → main
diff, squash normally, verify the resulting tree and rerun dry-runs. Do not use
ours sync/revert main. Only then request new GO for exact Android/iOS RC tags.
