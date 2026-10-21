# iOS publishing CLI preflight and IPA recovery

## Incident and verified CLI contract

Owner-provided evidence: iOS RC `1.2.3+22`, commit
`576209d5691245e39ccd4d64f81da630a3f93c03`, Codemagic Build #3 passed SwiftPM,
Flutter, IPA/signing, Firebase symbols and Apple GET preflight. The publisher
failed on `--altool-retries 0` during argument parsing, before upload. This task
does not independently inspect that cloud build or contact Apple.

`requirements.txt` pins codemagic-cli-tools **0.70.0**; the same version is
installed in the local release venv and is enforced by `apple_publish.py`.
The installed real parser and offline tests establish:

| Explicit option | Value | Meaning in 0.70.0 |
| --- | --- | --- |
| `--altool-retries` | `1` | One validation attempt and one upload attempt, not an additional upload retry |
| `--api-server-error-retries` | `1` | Stop on the first 5xx response |
| `--api-unauthorized-retries` | `1` | Stop on the first 401 response |

All three types reject `0`. Defaults are 10 / 3 / 3, so removing the options
would be unsafe. The altool loop decrements before its first command; API counters
start at 1 and stop when the configured limit is reached. Tests exercise those
actual SDK loops with mocked commands/HTTP, including a retryable timeout and
401/500/503. No real upload or request is made. Fixing only the first zero would
leave two later parse failures.

Sources: pinned [argument types](https://github.com/codemagic-ci-cd/cli-tools/blob/v0.70.0/src/codemagic/tools/app_store_connect/arguments.py),
[altool loop](https://github.com/codemagic-ci-cd/cli-tools/blob/v0.70.0/src/codemagic/models/altool/altool.py),
[API loop](https://github.com/codemagic-ci-cd/cli-tools/blob/v0.70.0/src/codemagic/apple/app_store_connect/api_session.py).

## Early offline check, not publishing

Both iOS workflows run `python3 -B tool/release/ios_store.py validate-publish`
immediately after installing pinned release requirements, before pub/pod/SwiftPM,
tests and IPA build. Source/tag/SHA/native guards and local Apple auth run first.
Production remains default-deny even for this check; never enable U5 to test it.

The check uses the same `publish_arguments()` as real publishing, the actual
`build/release/context.json`, `TESTFLIGHT_GROUP` and generated Git
`apple-localizations.json`. Only the not-yet-built IPA path is a placeholder.
The actual signed IPA path is checked again immediately before the publisher;
the adapter also validates its own final argv before invoking the CLI.

The SDK's full argument parser validates every generated option and reads the
localization file. This is not grep, `--help`, or a separate example command.
Missing/duplicated attempt options or counts other than 1 block instead of
falling back to defaults. Version drift/missing SDK blocks before build; an
upgrade requires revalidation of both parser semantics and localization adapter.

It never instantiates AppStoreConnect, resolves credential environment defaults,
creates an API client/JWT, launches altool, signs, uploads or writes a snapshot.
Parser stdout/stderr are suppressed; argument values, paths, exception messages
and tracebacks are not replayed. Fixed outcomes:

- `APPLE_PUBLISH_ARGUMENTS_VALID`: offline syntax/policy PASS only.
- `BLOCKED: APPLE_PUBLISH_ARGUMENTS_INVALID`: STOP; inspect generated Git context,
  notes and option compatibility offline, without dumping credentials.
- `BLOCKED: APPLE_PUBLISH_CLI_VERSION_UNSUPPORTED`: STOP; restore the reviewed
  pinned dependency or explicitly review an upgrade, never bypass the guard.

This does not prove signing, credentials, upload permission, Apple availability
or final TestFlight membership. Fresh complete GET checks before build and upload
remain mandatory. Any unknown pre-upload state blocks invocation. Any nonzero
publisher result can mean an already accepted upload: STOP, inspect Apple after
separate authorization, never automatically retry/reupload.

## Artifact strategy: small, explicit compromise

Previously only `build/release/ios-symbols.zip` was selected. Successful Firebase
symbol upload removes that ZIP. Thus `No artifacts were found` after a later
publish failure was expected; it did not mean the IPA was never built.
Changing this YAML cannot recover an unretained IPA from the completed +22 run
or change the source under its existing immutable release tag.

Both iOS release workflows now also select **`build/ios/ipa/*.ipa`**, the same
directory consumed by IPA verification and the single-package publisher. The
signed IPA remains available after success, failure or unknown publishing state.
No IPA is deleted, copied to a second recovery store, or uploaded elsewhere.
The dSYM ZIP keeps its existing failure-only behavior. Android is unchanged.

This intentionally uses the owner's permitted simple fallback instead of
conditional deletion after success. CLI exit 0 is not sufficient confirmation
of the target internal group: the pinned SDK can merely warn when a group is
missing. Pre-upload group checks reduce risk but do not prove post-upload
membership. Safe deletion would add post-publish group/build verification and
eventual-consistency/unknown-state handling, outside this minimal fix. No log
grep or exit-code-only success cleanup is used.

Artifacts use [standard Codemagic retention](https://docs.codemagic.io/billing/pricing/#build-history-and-artifact-storage),
not a cleanup service or new long-term storage. Published limits are Personal
30 days, Team Pay-as-you-go 60 days, Fixed Annual 1 year, Enterprise 1 year by
default. Confirm the actual account plan; this task does not inspect billing or
change retention/access controls. Limit access to signed IPA downloads; retention
does not authorize manual upload. Provider collection on a failed build remains
to be confirmed during an approved cloud run; local tests only prove selection
and preservation of the file. No binary is recoverable if IPA build never finished.

## Next iOS-only RC

After owner-reviewed feature → dev → main integration, separately prepare
`1.2.3+23` (visible version stays 1.2.3) through the normal review/squash process.
Recheck shared tag history and live builds/buildUploads availability with owner
authorization. If 23 is reserved or state is unknown, STOP. Do not move/delete
the existing +22 tag or retry Android +19. Review `prokat-rc-ios -DryRun`, then
obtain a new U4 GO for tag/webhook/build/upload. Production remains disabled.
No bump, tag, cloud run, credential change or publication is authorized by this fix.

Historical claims based on `--help` that zero was safe do not establish parser
acceptance and are superseded by these real-parser/SDK-loop tests. Historical
verification tables are preserved, not rewritten as new evidence.
