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

## RC +23 investigation and hardening

Owner-provided RC `1.2.3+23`, tag `rc/ios/v1.2.3+23`, SHA
`9b3326a28c357b959bcaac26090a271dd2c8cf32`, build `6ad891306a1999f83b1b953e`
failed after one SwiftPM attempt with exit 74 and `non-retryable error`.
The actual xcodebuild cause is **unknown**: the previous helper captured stdout
and stderr in memory but neither printed nor persisted the cause. The 4m25s
duration is the whole dependency step, not measured resolver time.

Offline forensics reproduced false negatives: URL words/numbers (`signature`,
`/403/`), an extra benign footer after the resolver summary and alternative
network wording. These are classifier defects, not proof of what happened in
that cloud run. Earlier +22 resolving/building/signing/symbols success and the
now-passing publishing argument check do not establish the +23 root cause.
There is no evidence here to change CocoaPods configuration, SDK versions,
dependency URLs or locks. No cloud build/Apple API/SDK download was run locally.

This hardening adds diagnostics and only the reviewed classifier fixes below.
The existing tag-only RC, production default-deny, publishing CLI, artifact
retention, signing, Firebase and manual Apple workflow are unchanged.

## Retry classification

Maximum three attempts, sequentially: attempt 1; wait 15 seconds; attempt 2;
wait 45 seconds; attempt 3. A successful earlier attempt stops the loop.

The current allowlist requires **both exit 74 and a recognized package-download
failure** with a known network symptom: request/operation timeout or `Timeout
was reached`, connection
reset/interruption/closure, DNS/host-resolution failure, unreachable/offline
network, recognized Foundation network codes, or explicit HTTP 429/502/503/504.
The reported reCAPTCHA log is covered by a synthetic fixture.

The alternative DNS/offline messages `A server with the specified hostname could
not be found` and `The Internet connection appears to be offline`, and reviewed
Foundation `NSURLErrorDomain error -1001/-1003/...` forms, still require the
download context. A bare timeout/network warning or HTTP number is insufficient.

Classification receives the full original captured output, **not** the printable
tail. Internal semantic normalization removes terminal controls and replaces
complete scheme URLs with a marker before pattern matching: `signature` in a
URL is not a signature error and `/403/` is not a response. Actual HTTP 403 or
signature text outside the URL remains blocking anywhere in the output.

Only the exact known footer `Writing error result bundle to /.../*.xcresult`
(also a double-quoted absolute path) is harmless after the summary. Its dynamic
path supplies neither positive network evidence nor permanent-error evidence.
Unknown footers, extra error text and other suffixes are not ignored.

Exit 74 alone is insufficient. Other exit codes (even with timeout-like text)
are not retried. Known permanent errors override network matches: manifest
syntax/tools-version, incompatible/missing versions, locked-resolution problems,
checksum, SDK signature/certificate, authentication/401/403/404 and project,
workspace or scheme configuration failures. Unknown errors, unknown error lines
mixed into the resolver summary, and logs too large for reliable classification
fail without retry. New message forms need reviewed fixtures; the helper does
not guess from a bare HTTP number or from unrelated network warnings. HTTP 500,
unknown `statusCode: 503` forms, generic network errors and unsupported exit codes
remain non-retryable. `non-retryable` means **not authorized by this allowlist**,
not that a permanent root cause has been proven.

Logs show fixed messages, for example:

```text
SwiftPM resolution attempt 1/3
SWIFTPM_FAILURE attempt=1/3 child_exit=74 retry=yes reason=TRANSIENT_DOWNLOAD_TIMEOUT
SWIFTPM_DIAGNOSTIC_TAIL stream=combined projection=allowlisted
xcodebuild: error: Could not resolve package dependencies
Dependency download location: [URL_REDACTED]
[DOWNLOAD_TIMEOUT_TEXT_REDACTED]
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

## Safe diagnostics contract

Every failed attempt reports `SWIFTPM_FAILURE` with attempt, actual child exit
code, planned retry decision and one fixed reason. On the third transient
failure the reason remains transient but `retry=no`: the attempt limit wins.
`child_exit=NONE` means no child status is available (for example spawn failure).
`attempt=0/3` means no attempt started. Signal child codes stay negative in this
field; the helper's returned shell status still maps to 128 + signal. A lock
failure can report `child_exit=0` but returns 1: guard failure overrides success.

| Fixed reason | Meaning / response |
| --- | --- |
| `TRANSIENT_DOWNLOAD_TIMEOUT` | Reviewed dependency timeout; retry only while budget/attempts permit |
| `TRANSIENT_NETWORK_ERROR` | Reviewed connection/DNS/offline/HTTP download error; same bounded policy |
| `PERMANENT_RESOLUTION_ERROR` | Recognized blocking manifest/version/checksum/signature/access/configuration error |
| `MIXED_ERROR` | Network evidence plus permanent or unclassified diagnostic output; STOP |
| `UNCLASSIFIED_OUTPUT` | No sufficient recognized download/network evidence; STOP, not a proven permanent cause |
| `OUTPUT_LIMIT_EXCEEDED` | More than 2,097,152 captured characters, the unchanged classification cap; STOP |
| `LOCK_GUARD_FAILED` | Missing/non-regular/drifted locked input or failed HEAD lookup; STOP |
| `PROCESS_TIMEOUT` | Helper's 600-second timeout, not a retryable download timeout |
| `SPAWN_FAILED` | OS could not start xcodebuild; no exception/path dump |
| `INTERNAL_ERROR` | Unexpected helper failure or invalid timer/CI context; fail closed |
| `UNSUPPORTED_EXIT_CODE` | An exit other than reviewed 74, without a more specific blocking reason |
| `TIME_BUDGET_EXHAUSTED` | Do not sleep/start another full attempt; prior time counts |
| `INTERRUPTED` | Stop, return 130; no retry |

The diagnostic tail is a **lossy allowlisted projection**, not arbitrary text
passed through a blacklist. It examines at most the last 8,192 characters and
20 lines, emitting only fixed ASCII messages/markers, at most 20 lines / 8 KiB.
It can show resolver summary, redacted download location/result-bundle footer,
timeout/network markers and manifest/version/checksum/signature/access/config
error categories. Unknown text becomes `[UNCLASSIFIED_LINE_REDACTED]`.
It never copies source substrings, URL/query/credentials, absolute paths,
headers, JWT, PEM or tokens, even if an unknown secret format is present.
Terminal controls cannot reach output. It does not inspect/dump environment
values or print exception bodies/tracebacks. Partial output from the process
timeout is kept only in memory for this projection, never used to authorize retry.
No raw log, credentials or new artifact is written. The full captured output is
still held in memory as before; the classification cap is not a subprocess RAM cap.

Projection may hide details needed for a complete root cause. In that case STOP
for a reviewed additional safe pattern/offline investigation; never enable a raw
dump or broaden retry to all exit 74. A `retry=yes` decision is planned, not a
guarantee that another attempt will start: time/locks are checked again after sleep.

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

## Owner response and next +24 candidate

After final network FAIL, STOP and retain the build URL, source SHA, attempt
messages and exit status. Confirm the failed step and absence of IPA/upload;
an unknown outcome at a later upload stage needs separate Apple-state recovery.
Keep the structured reason and projected tail, not credentials or raw logs.
For manifest/version/checksum/signature/mixed/unknown failures investigate that
stage offline; do not replace locks/configuration based on exit 74 alone.
For spawn/internal/lock/budget failures fix that specific boundary first.
Do not delete/move +23, run the full workflow repeatedly, regenerate locks,
change mirrors/SDK versions or clear all caches to force progress. A new
classifier pattern or permanent failure needs offline evidence and review.

This source fix cannot change code under the existing immutable +23 tag. After
owner-reviewed feature → dev → main integration using the normal Squash and
merge process, prepare an **iOS-only `1.2.3+24`** candidate in a separately
approved change: bump shared build in pubspec, retain visible version 1.2.3,
reuse existing version notes unless release content changed, and recheck both
platforms' tag history and live Apple availability. If 24 is reserved, STOP for
another owner decision. Review `prokat-rc-ios -DryRun` against the resulting main
SHA; only after U4 GO use `prokat-rc-ios`. No Android retry; production remains
default-deny. This task does not bump/tag/build/upload +24. No manual Codemagic
settings/Secrets/retention change is needed; only the reviewed source integration.

## Local validation

`swiftpm_resolve_test.py` uses fake runners, monotonic clocks/sleep and synthetic
logs; only disposable lock/timer fixtures are written. No xcodebuild or actual
SDK download is needed. Tests cover attempts/backoffs/original exit codes,
permanent/unknown/mixed failures, 503, lock drift/missing files, time exhaustion,
process-group cleanup, structured reasons, URL collisions, known/unknown footers,
alternative network messages, bounded projection and secret sentinel redaction.
They also preserve the exact hardcoded resolver and absence of publishing commands.
Workflow tests preserve RC/production tag/SHA/U5 gates and identical resolver
placement. Run the complete Python release suite, Flutter release regression,
cached YAML/schema validation, Bash syntax, diff whitespace and credential scan.

See [native dependency history](IOS_DEPENDENCIES.md),
[release recovery](RELEASE_RUNBOOK.md) and [owner commands](../../CICD-README.md).
