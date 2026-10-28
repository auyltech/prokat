# iOS publishing CLI preflight and IPA recovery

## RC +24 accepted: Automatic Distribution, not manual assignment

Owner-confirmed technical delivery: `1.2.3+24`, tag `rc/ios/v1.2.3+24`, SHA
`07926a7dc9dcd5c8467717423130abc65ddba294`, Codemagic build
`6ad89bb56a1999f83b1bcc0f`, Apple Build ID `63457530-f596-4ed5-bf9c-be8d9a0a6c8c`.
IPA validation/upload succeeded, processing is VALID, internal state is
IN_BETA_TESTING, and AuylTech Test Team has access with three testers. IPA is
retained in Codemagic Artifacts. Physical-iPhone testing is not an acceptance
requirement for this CI/CD fix; these Apple states/group access establish
technical internal delivery, not production publication or app smoke-test quality.

The historical job remains FAILED because CLI `--beta-group` attempted an
additional manual assignment after the successful upload. Apple rejects that
operation for this Automatic Distribution group. [Codemagic discussion](https://github.com/orgs/codemagic-ci-cd/discussions/2488)
suggests Manual Distribution for explicit CLI assignment; PROKAT deliberately
keeps Automatic Distribution and removes the conflicting assignment instead.
Do not rebuild/reupload +24 to repaint the old job green, move its tag, or change
the group's settings. This task has not contacted the live Apple API.

### RC command and pre-upload contract

`publish_arguments()` still enables package validation and explicit attempt
counts 1/1/1. RC keeps `--beta-build-localizations @file:<Git-generated notes>`
but **does not pass `--beta-group` or `--testflight`**. Production argv, YAML,
default-deny gate, signing, SwiftPM and IPA retention remain unchanged.

In pinned CLI 0.70.0, `--testflight` means **external Beta App Review**, calling
`create_beta_app_review_submission`; it is not a switch to make internal builds
available. Upload plus localized What to Test invokes the metadata path without
manual group assignment or external review. The real-parser/SDK-options tests
assert these distinctions; accidental RC group/review arguments are rejected.
See [CLI publish options](https://github.com/codemagic-ci-cd/cli-tools/blob/v0.70.0/src/codemagic/tools/app_store_connect/arguments.py)
and [post-upload action](https://github.com/codemagic-ci-cd/cli-tools/blob/v0.70.0/src/codemagic/tools/app_store_connect/actions/publish_action.py).

The ordinary RC preflight, before build and again immediately before upload,
requires exact Apple app `6817078475`, bundle `com.auyltech.prokat`, exact group
name `AuylTech Test Team`, exactly one matching group, `isInternalGroup=true`
and `hasAccessToAllBuilds=true`. Missing/false/non-boolean mode, missing/duplicate/
external group or wrong target blocks before upload. It pins the group ID in the
ordinary diagnostic snapshot's optional public `automatic_group_id` field.
Production snapshots/behavior and the standalone Apple diagnostic are unchanged.

### GET-only confirmation after one successful publisher call

CLI exit 0 is necessary but no longer sufficient for RC success. A nonzero CLI
result stays failed and **never** enters success confirmation. After CLI success,
the Python client uses fresh in-memory auth and only documented GET endpoints:

| Read | Required evidence |
| --- | --- |
| `/v1/apps/{app}/betaGroups` | Same unique automatic internal group and pinned ID, rechecked on each poll |
| `/v1/betaGroups/{group}/app` | Exact app ID and bundle |
| `/v1/builds` | Exact app/build-number/prerelease-version/IOS filters; exactly one match, never latest |
| `/v1/builds/{build}` | Pin that Apple Build ID for subsequent polls; exact number, VALID, not expired |
| `/v1/builds/{build}/app` | Exact app ID and bundle for that build |
| `/v1/builds/{build}/preReleaseVersion` | Exact user-visible version and IOS |
| `/v1/builds/{build}/buildBetaDetail` | `internalBuildState=IN_BETA_TESTING` |
| `/v1/betaGroups/{group}/relationships/builds` | Full paginated relationship includes that exact Build ID |

The [official OpenAPI](https://developer.apple.com/sample-code/app-store-connect/app-store-connect-openapi-specification.zip)
defines the group→build GET and build→app/version/beta-detail GETs; it does not
define a GET `/v1/builds/{id}/betaGroups`. Do not invent that endpoint or infer
membership solely from the all-builds flag. [Apple group relationships](https://developer.apple.com/documentation/appstoreconnectapi/get-v1-betagroups-_id_-relationships-builds)
are required as positive association evidence. [Apple internal-testing help](https://developer.apple.com/help/app-store-connect/test-a-beta-version/add-internal-testers/)
documents automatic versus manual distribution. Live representation of implicit
Automatic Distribution access has not been exercised here. If Apple does not
expose positive association in this relationship, fail unconfirmed and investigate
GET evidence separately; do not silently fall back to the flag or send assignment POSTs.

Wait at most **20 minutes / 61 poll slots**, 20-second intervals, counting GET
time against one monotonic deadline. Each HTTP request is at most 15 seconds and
clamped to remaining time. Only a valid empty discovery result, PROCESSING,
READY_FOR_BETA_TESTING or a valid not-yet-present association permits another
GET poll. Wrong identity/schema, invalid/expired processing, changed group mode,
401/403/429/5xx, transport or pagination errors fail immediately. Unknown errors
are not retried. No POST/upload is retried by this wait. Late success cannot
pass after the deadline. The unchanged 90-minute workflow hard limit still wins.

Fixed outcomes:

- `TESTFLIGHT_INTERNAL_DISTRIBUTION_CONFIRMED`: all exact-build criteria passed;
  RC may finish successfully without a physical-phone acceptance gate.
- `TESTFLIGHT_DISTRIBUTION_PENDING attempt=N/61`: eligible for another bounded GET.
- `TESTFLIGHT_CONFIRMATION_CHECK_FAILED code=... stage=...`: sanitized API failure;
  no response body, credentials, JWT, headers or raw exception is printed.
- `BLOCKED: TESTFLIGHT_DISTRIBUTION_UNCONFIRMED`: upload may already be accepted;
  retain IPA and STOP. This is not permission to rerun upload or change group mode.

On UNKNOWN, inspect the exact Apple Build ID, version/number, processing/beta
detail and group relationship after separate owner authorization. Metadata-only
recovery of an accepted build is a separate owner operation. Existing preflight
continues to reject an already used build number. There is no new recovery
publisher, snapshot cache, group mutation, raw API artifact or retention change.

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
conditional deletion after success. CLI exit 0 alone is not sufficient: the
pinned SDK can merely warn when a group is missing. RC now has the GET-only
confirmation above, but artifact retention deliberately remains the reviewed
simple policy on every outcome. No log grep or success cleanup is introduced.

Artifacts use [standard Codemagic retention](https://docs.codemagic.io/billing/pricing/#build-history-and-artifact-storage),
not a cleanup service or new long-term storage. Published limits are Personal
30 days, Team Pay-as-you-go 60 days, Fixed Annual 1 year, Enterprise 1 year by
default. Confirm the actual account plan; this task does not inspect billing or
change retention/access controls. Limit access to signed IPA downloads; retention
does not authorize manual upload. Provider collection on a failed build remains
to be confirmed during an approved cloud run; local tests only prove selection
and preservation of the file. No binary is recoverable if IPA build never finished.

## Next iOS-only RC

RC `1.2.3+24` is already accepted; no new upload is needed for its delivery.
Integrate this fix through owner-reviewed feature → dev → main. Use it for the
next **ordinary** iOS RC when release content warrants one, for example `1.2.3+25`
if still available, through the normal review/squash process.
Recheck shared tag history and live builds/buildUploads availability with owner
authorization. If the candidate is reserved or state is unknown, STOP. Do not move/delete
the existing +24 tag or retry Android +19. Review `prokat-rc-ios -DryRun`, then
obtain a new U4 GO for tag/webhook/build/upload. Production remains disabled.
No bump, tag, cloud run, credential change or publication is authorized by this fix.

Historical claims based on `--help` that zero was safe do not establish parser
acceptance and are superseded by these real-parser/SDK-loop tests. Historical
verification tables are preserved, not rewritten as new evidence.
