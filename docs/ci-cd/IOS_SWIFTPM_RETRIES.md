# iOS SwiftPM network retries

## Incident and scope

Owner-provided evidence: iOS RC `1.2.3+21`, tag `rc/ios/v1.2.3+21`, commit
`42db9138873253a5a4e5b59efbe9e71f5ecb60ef`, Codemagic build
`6ad871a0064e933257c9cd67`, failed in **Resolve locked dependencies and record tools**.
The step lasted 3m42s. `xcodebuild -resolvePackageDependencies` failed downloading
the pinned reCAPTCHA Enterprise 18.9.1 binary from dl.google.com with
`downloadError("The request timed out.")`, followed by resolver exit 74.
This is evidence of a transient network failure, not SDK incompatibility.
The 3m42s is the whole dependency step, not a measured isolated resolve duration.
Source/auth passed; no IPA or TestFlight upload was produced by this attempt.
Earlier Apple GET-only diagnostics passed at `81273a77`; Android +19 remains
accepted in Play Internal. These are owner-provided provider facts, not new runs.

Only the shared SwiftPM operation in `codemagic.yaml` is replaced by
`python3 -B tool/release/swiftpm_resolve.py resolve`. Both `ios-rc` and
`ios-production` use the same YAML anchor. pip, Flutter pub, CocoaPods, tests,
IPA build, signing, Firebase symbols, Apple reads and publishing are not retried.
The manual Apple diagnostic workflow is unchanged. No manual Codemagic settings,
Secrets, SDK versions, signing identities or new dependency/cache configuration
are needed after approved integration.

## Retry classification

Maximum three attempts, sequentially: attempt 1; wait 15 seconds; attempt 2;
wait 45 seconds; attempt 3. A successful earlier attempt stops the loop.

The current allowlist requires **both exit 74 and a recognized package-download
failure** with a known network symptom: request/operation timeout, connection
reset/interruption/closure, DNS/host-resolution failure, unreachable/offline
network, recognized Foundation network codes, or explicit HTTP 429/502/503/504.
The reported reCAPTCHA log is covered by a synthetic fixture.

Exit 74 alone is insufficient. Other exit codes (even with timeout-like text)
are not retried. Known permanent errors override network matches: manifest
syntax/tools-version, incompatible/missing versions, locked-resolution problems,
checksum, SDK signature/certificate, authentication/401/403/404 and project,
workspace or scheme configuration failures. Unknown errors, unknown error lines
mixed into the resolver summary, and logs too large for reliable classification
fail without retry. New message forms need reviewed fixtures; the helper does
not guess from a bare HTTP number or from unrelated network warnings.

Logs show fixed messages, for example:

```text
SwiftPM resolution attempt 1/3
Transient network download failure
Retrying after 15 seconds
SwiftPM resolution attempt 2/3
SwiftPM dependencies resolved successfully
```

Other outcomes: `SwiftPM resolution failed: non-retryable error`, `retry limit
reached`, `insufficient time budget`, `time budget exhausted`, or `resolver time
limit exceeded`. Lock failure is `BLOCKED: SWIFTPM_LOCK_GUARD_FAILED`.
Raw command output is captured in memory for classification and never replayed
or saved as an artifact: it may contain credential-bearing URLs. No environment
dump, headers, Secrets, subprocess exception bodies or tracebacks are printed.
There is no `tee` pipeline; the xcodebuild return code is captured directly.

## Lock and checksum protections

The helper reads the committed HEAD versions of these four files through local
`git show` and compares exact bytes, including before the first attempt:

- `pubspec.lock`
- `ios/Podfile.lock`
- `ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved`
- `ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`

Missing, symlinked, non-regular or changed files block. Comparison repeats after
every command outcome, before sleeping/retrying and after backoff before the next
attempt. Even successful resolution fails if a lock drifted. A dirty input is
not accepted as a new baseline. The existing post-resolve `git diff --exit-code`,
native graph/revision/toolchain validation and post-IPA lock checks remain.

The sole runnable SDK command is the original strict xcodebuild resolver:
`-resolvePackageDependencies -workspace ios/Runner.xcworkspace -scheme Runner
-clonedSourcePackagesDirPath <checkout>/build/release/SourcePackages
-onlyUsePackageVersionsFromResolvedFile`. Native artifact checksum/signature
verification remains Xcode/SwiftPM's responsibility and is not disabled.
There is no package update, lock regeneration/deletion, URL substitution,
whole-cache purge, automatic migration or version change. Both resolved files
continue to pin reCAPTCHA 18.9.1 and its existing revision.

## Time budget and exit status

Each attempt has a **10-minute** process timeout, substantially longer than the
observed whole 3m42s dependency step. An outer timeout is not evidence of a
transient SDK error and is not retried based on partial output. On macOS the
resolver starts a separate process group: TERM, up to 5 seconds, then KILL with
up to another 5 seconds to reap it before any next operation.

Total helper budget: **32 minutes**, including local HEAD inspection, all
attempts, 15/45-second backoffs and process cleanup. A monotonic clock counts
time already spent; a new attempt requires the full 600 + 10-second allowance.
Insufficient budget stops before sleeping or starting another attempt. Three
attempts each as long as the observed entire step would take 12m06s including
backoffs; this is an estimate, not a measured provider result.

At the first release script (after the nonempty tag check), `swiftpm_resolve.py
start` records public build ID, commit and monotonic start in
`build/release/swiftpm-clock.json`. It is tied to this build/commit, cannot be
reinitialized, is not an artifact, and contains no credentials. Resolve also
enforces a **60-minute dependency-phase deadline from that first script**, so
slow prior source/auth/pub/pod steps reduce its budget. Missing/stale/future
clock context blocks; it cannot silently reset the budget. This reserves
30 minutes of the unchanged 90-minute workflow limit *from the first script*.
VM provisioning/SDK setup before scripts is not observable through this marker;
Codemagic's actual 90-minute hard limit is authoritative and may stop earlier.
No undocumented provider start-time variable or external API is assumed.

On the third transient failure, a permanent/unknown failure or insufficient
retry budget, preserve the last command's exit code (74 for the incident).
Signal exits map to shell status 128 + signal. An imposed process timeout is
124. No command started / late success after budget exhaustion is 75; lock or
invalid context/internal failures are 1. Guard failures take priority over a
command's original code. No retry can reach publishing by itself.

## Owner response and next +22 candidate

After final network FAIL, STOP and retain the build URL, source SHA, attempt
messages and exit status. Confirm the failed step and absence of IPA/upload;
an unknown outcome at a later upload stage needs separate Apple-state recovery.
Do not delete/move +21, run the full workflow repeatedly, regenerate locks,
change mirrors/SDK versions or clear all caches to force progress. A new
classifier pattern or permanent failure needs offline evidence and review.

This source fix cannot change code under the existing immutable +21 tag. After
owner-reviewed feature → dev → main integration using the normal Squash and
merge process, prepare an **iOS-only `1.2.3+22`** candidate in a separately
approved change: bump shared build in pubspec, retain visible version 1.2.3,
reuse existing version notes unless release content changed, and recheck both
platforms' tag history and live Apple availability. If 22 is reserved, STOP for
another owner decision. Review `prokat-rc-ios -DryRun` against the resulting main
SHA; only after U4 GO use `prokat-rc-ios`. No Android retry; production remains
default-deny. This task does not bump/tag/build/upload +22.

## Local validation

`swiftpm_resolve_test.py` uses fake runners, monotonic clocks/sleep and synthetic
logs; only disposable lock/timer fixtures are written. No xcodebuild or actual
SDK download is needed. Tests cover attempts/backoffs/original exit codes,
permanent/unknown/mixed failures, 503, lock drift/missing files, time exhaustion,
process-group cleanup, fixed output and absence of publishing commands.
Workflow tests preserve RC/production tag/SHA/U5 gates and identical resolver
placement. Run the complete Python release suite, Flutter release regression,
cached YAML/schema validation, Bash syntax, diff whitespace and credential scan.

See [native dependency history](IOS_DEPENDENCIES.md),
[release recovery](RELEASE_RUNBOOK.md) and [owner commands](../../CICD-README.md).
