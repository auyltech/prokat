# PROKAT iOS CI/CD — Apple diagnostics and recovery

## Scope and approvals

`ios-apple-diagnostic` / **iOS Apple GET-only diagnostic** checks current Apple
authentication and API reads without signing, building, uploading or submission.
It uses the existing `prokat-app-store` integration and `prokat-ios-release`
group, with isolated raw PEM in owner-managed `PROKAT_ASC_PRIVATE_KEY_PEM`.
No certificate/key/profile is created, replaced or revoked. Production
publishing remains disabled. This document does not authorize a cloud run.

Owner-confirmed incident: Android `1.2.3+19` was accepted into Play Internal;
iOS `1.2.3+20`, tag `rc/ios/v1.2.3+20`, commit
`5a34a3b95d554bc1660c23d58b902b77c5dd2447`, failed before IPA/upload with
`BLOCKED: Apple state UNKNOWN (ValueError)`. A local U3 authentication succeeded;
the Codemagic variable was subsequently re-saved; GitHub Redeliver created no
new build. These are owner-provided facts, not new provider/API observations.

Malformed PEM is a reproduced hypothesis, not a confirmed historical cause.
U3's file input and CI's effective environment may differ. The old catch-all
combined PEM/JWT, HTTP, JSON/schema, pagination, numeric and snapshot failures.
The exact `ValueError` is compatible with PEM loading, JWT signing, malformed
pagination URLs and oversized integer conversion; ordinary JSON decode errors
would have been labelled `JSONDecodeError`, HTTP rejection `HTTPError`.
Success after re-saving proves only the current environment, never the bytes or
failure stage of the original run. Do not restore old credentials to reproduce it.

## Manual Codemagic execution — owner GO required

1. Review and integrate this feature through feature → dev → main using the
   existing Squash and merge process. Record the resulting approved main SHA.
   The diagnostic-only change does not bump `pubspec.yaml` or reserve a build.
2. Before running, the owner must manually add Secret `PROKAT_ASC_PRIVATE_KEY_PEM`
   to existing `prokat-ios-release`, using the original raw PEM text of the same
   API key as the existing issuer/key identifier. No base64, quotes or references.
   Inspect variable **names and scopes**, not secret contents, for duplicates at
   app/team/API levels. Leave existing `APP_STORE_CONNECT_*`, integration and
   signing unchanged. No API/UI launch overrides. Confirm production is disabled;
   do not modify Secrets during the diagnostic itself.
3. In the existing PROKAT Codemagic application choose **Start new build**,
   select branch **main**, and workflow **iOS Apple GET-only diagnostic**
   (`ios-apple-diagnostic`). Do not select a release workflow or a tag. Confirm
   the intended main SHA; if main advanced beyond the approved source, STOP.
4. After explicit owner GO, launch once. Source guards require `CM_BRANCH=main`,
   `CM_REPO_SLUG=auyltech/prokat`, `CM_PULL_REQUEST=false`, `CM_TRIGGER_SOURCE=api`,
   empty `CM_TAG`, and checkout HEAD equal to `CM_COMMIT`. A mismatch stops
   before Python dependency installation. Do not manufacture provider variables.
5. Read the fixed diagnostic codes. Keep the build URL, public commit SHA,
   time and codes; do not export environment, JWT, key material or API bodies.
   Any failure is STOP, with no automatic retry, credential repair or release.

The workflow has a five-minute timeout on the already-used `mac_mini_m2`.
It does not select or invoke Flutter, Xcode, CocoaPods or SwiftPM. Linux is
technically sufficient for these Python operations, but its account/billing
availability is not assumed. The venv contains pinned packages only; it is not
a credential or response artifact. There are no artifact or publishing sections.

## Commands and environment contract

The workflow runs, inside its ephemeral isolated venv:

```text
python3 -B tool/release/apple_diagnostic.py check --build 20
```

Offline authentication entry points, used early in release scripts:

```text
python3 -B tool/release/apple_diagnostic.py auth --channel rc
python3 -B tool/release/apple_diagnostic.py auth --channel production
```

Do not run these with real local credentials without separate approval.
There are no credential/file/URL/app/publish CLI options. `check --build N`
accepts only integer `1..9999`; the checked-in manual workflow intentionally
targets `20`. To diagnose a separately approved `21` candidate, review an explicit
workflow command change to `--build 21` and its matching assertion in
`tool/release/config_test.py`; do not inject unreviewed script overrides.

Required variables: `APP_STORE_CONNECT_ISSUER_ID` (UUID structure),
`APP_STORE_CONNECT_KEY_IDENTIFIER` (10 ASCII letters/digits),
`PROKAT_ASC_PRIVATE_KEY_PEM` (raw unencrypted PKCS#8 PEM), `APP_STORE_APP_ID`
(positive ASCII decimal, up to 20 digits), `IOS_HISTORICAL_MAX_BUILD` (0..9999,
no leading zeros). RC also requires `TESTFLIGHT_GROUP`, without surrounding
whitespace; production auth does not require a TestFlight group.
`check` fixes app ID `6817078475`, bundle `com.auyltech.prokat`, and group
`AuylTech Test Team`. It verifies primary locale against the existing RU/EN mapping.

The PEM must have real LF or CRLF and exact PRIVATE KEY boundaries, with no BOM,
quotes, Markdown fences or `@file:`/`@env:` wrappers. Literal escaped newlines and
base64-of-PEM are rejected, not repaired. A loadable private EC P-256 key and an
ES256 JWT are required. Key/JWT data and fingerprints are never logged.

Python's early auth, diagnostic, legacy access and release preflight read the
private key only from `PROKAT_ASC_PRIVATE_KEY_PEM`: **no fallback** to
`APP_STORE_CONNECT_PRIVATE_KEY`, including when the new variable is missing,
empty or invalid. The existing issuer and key identifier remain shared and must
correspond to that PEM. A missing/empty new variable fails before key/JWT/HTTP:

```text
BLOCKED: APPLE_ENV_MISSING stage=environment variable=PROKAT_ASC_PRIVATE_KEY_PEM
```

Codemagic CLI can interpret `@file:` in its own authentication variable; PyJWT
expects PEM material. These are separate input contracts. No generic file reader
is implemented: a trusted Codemagic path boundary was not established. Python
never opens a reference, expands `@env:`, strips wrappers, copies credentials to
another environment variable, or writes PEM/JWT to disk. Do not replace/rename
`APP_STORE_CONNECT_PRIVATE_KEY` or make the CLI use the new variable. Existing
integration/CLI publishing/signing remain on their previous credentials.

## Diagnostic output and allowed action

Success lines have `APPLE_DIAG: <CODE> stage=<STAGE>`. Failure has
`BLOCKED: <CODE> stage=<STAGE>` with optional allowlisted `reason` / `variable`.
Values, HTTP headers/bodies, original exception messages and tracebacks are absent.
Failure exits 1; success exits 0. After failure no final success is printed.

| Failure code | Meaning / allowed next action |
| --- | --- |
| `APPLE_SOURCE_CONTEXT_INVALID` | Wrong manual/main/checkout context. Inspect public build settings; do not override CM variables |
| `APPLE_DEPENDENCY_SETUP_FAILED` | Minimal venv/package setup failed. Review runner/package availability offline; no credential change |
| `APPLE_DIAGNOSTIC_USAGE` | Unsupported CLI. Use only documented commands |
| `APPLE_ENV_MISSING` | Named required variable absent. Owner reviews names/scopes; no inferred permission to save a Secret |
| `APPLE_ENV_INVALID` | Structural contract or fixed diagnostic app/group mismatch. Owner reviews configuration; never print the value |
| `APPLE_PEM_INVALID` | PEM format/load failure. Fixed reason distinguishes escaped newlines, individual wrapper categories and format/load failures; any correction requires owner approval |
| `APPLE_KEY_UNSUPPORTED` | Not private EC P-256. Owner verifies existing key identity; do not create a replacement |
| `APPLE_JWT_FAILED` | JWT failed after key checks. Inspect pinned library/runtime behavior using synthetic inputs |
| `APPLE_AUTH_REJECTED` | HTTP 401. Owner reviews matching issuer/key, activation and runner time; no automatic key rotation |
| `APPLE_ACCESS_FORBIDDEN` | HTTP 403. Owner reviews access to the named stage; do not treat inaccessible collections as empty |
| `APPLE_API_REJECTED` | Other 4xx. Review endpoint compatibility/availability with sanitized evidence |
| `APPLE_API_UNAVAILABLE` | 429/5xx, transport/TLS/timeout or overall deadline. State remains UNKNOWN; no blind release retry |
| `APPLE_RESPONSE_INVALID` | Invalid JSON/resource schema. Reproduce with sanitized synthetic fixtures before changing the client |
| `APPLE_PAGINATION_FAILED` | Redirect/unsafe URL/filter change/cycle/page limit/duplicate/incomplete result. Investigate the client contract; no upload |
| `APPLE_APP_MISMATCH` | App ID/bundle/locale contract differs. Owner reconciles identity/mapping before further action |
| `APPLE_GROUP_INVALID` | Internal group missing, ambiguous or external. Owner inspects the existing group; no parallel group creation |
| `APPLE_BUILD_ALREADY_USED` | Build exists in builds or uploads, in any state. Inspect accepted/in-flight build; never upload the same number blindly |
| `APPLE_BUILD_NOT_INCREASING` | Number is not above live history/floor. Plan a new shared number through review |
| `APPLE_STATE_INVALID` | Unsupported build-number format/state. Inspect and add a reviewed policy; do not assume availability |
| `APPLE_REVIEW_SUBMISSION_OPEN` | A review submission is not COMPLETE. Resolve it in App Store Connect before another submission |
| `APPLE_VERSION_IN_FLIGHT` | A version field is in review, processing, or waiting for release. Do not rename or replace it |
| `APPLE_VERSION_STATE_UNSUPPORTED` | A version field is outside the pipeline categories. State is UNKNOWN |
| `APPLE_VERSION_STATE_MISMATCH` | The two version fields disagree. State is UNKNOWN; no correspondence between the fields is assumed |
| `APPLE_VERSION_CONFLICT` | More than one editable version, or the editable version string is not the tag version |
| `APPLE_VERSION_NOT_INCREASING` | A finished version is not older than the tag version |
| `APPLE_SUBMISSION_GUARD_FAILED` | A local guard rejected the operation before the App Store mutation was sent. No automatic retry |
| `APPLE_SUBMISSION_OUTCOME_UNKNOWN` | A version, submission, item, or confirm request was invoked and its result could not be verified. The request may have been processed by Apple; check the live state before any retry. Outcome is UNKNOWN. No automatic retry |
| `APPLE_SUBMISSION_ITEMS_CHANGED` | Submission items changed before confirm. Confirm was not sent |
| `APPLE_SUBMISSION_ITEMS_CHANGED_AFTER_CONFIRM` | Items after confirm were not the single expected item. Confirm is not atomic; no automatic cancellation |
| `APPLE_DIAGNOSTIC_INTERNAL_ERROR` | Unexpected error safely suppressed. Reproduce offline; do not enable raw exception logging |

Stages are fixed: `environment`, `pem`, `key`, `jwt`, `api`, `app`, `builds`,
`uploads`, `groups`, `build`, `usage`, `runtime`, `snapshot`, `versions`, `submissions`.
Reasons are fixed: `format`, `escaped_newline`, `newline_missing`, `leading_quote`,
`leading_backtick`, `bom`, `file_reference`, `env_reference`, `load_failed`,
`key_type`, `curve`, `unexpected`, `http_4xx`, `rate_limit`,
`server_error`, `timeout`, `transport`, `json`, `schema`, `unsafe_url`, `redirect`,
`cycle`, `page_limit`, `incomplete`, `duplicate_resource`.

Successful milestones: `APPLE_ENV_VALID`, `APPLE_PEM_VALID` (structural check),
`APPLE_KEY_VALID` (load/type/curve), `APPLE_JWT_CREATED`, `APPLE_APP_VERIFIED`,
`APPLE_BUILDS_READ`, `APPLE_UPLOADS_READ`, `APPLE_GROUP_VERIFIED`.
`auth` ends with `APPLE_AUTH_MATERIAL_VALID`: it proves no network access.
`check` ends with `APPLE_STATE_VALID`: all GETs and target-number policy passed
at that instant. Neither proves signing, upload permissions, tester availability
or authorization to publish.

## Historical wrapper evidence and current environment isolation

The owner reports two real diagnostic runs ending with
`APPLE_PEM_INVALID stage=pem reason=wrapper`, while the local .p8 has correct
boundaries and real newlines. With the implementation that emitted that reason,
this proves the effective CI string started with one of the checked wrapper
prefixes. It does not identify which one, prove key corruption, or identify the
environment source. The raw string was rejected before key loading/JWT/HTTP.

Latest owner-provided observation: main
`24c7010c71bd1e29b0ea7b5cecaf5b256c77cfc0`, diagnostic build
`6ad85f8b454d2506f7abb5a1`, `APPLE_ENV_VALID`, then
`APPLE_PEM_INVALID stage=pem reason=file_reference`. This establishes a
representation mismatch in the old Python contract, not a corrupt .p8 or the
source that supplied the reference. The owner chose namespace isolation instead
of a universal file reader because no trusted path boundary was confirmed.

The closed wrapper categories below now describe input errors in
`PROKAT_ASC_PRIVATE_KEY_PEM`, not an inspection of the CLI's private-key variable:

| Reason | Meaning / next inspection |
| --- | --- |
| `leading_quote` | Leading single or double quote. Owner checks whether shell/.env/JSON quoting was saved literally; no quote character is logged |
| `leading_backtick` | Leading backtick. Owner checks Markdown/code-block copying; no original characters are logged |
| `bom` | Leading Unicode BOM. Owner checks the source encoding/copying path; the local file and CI value need not match |
| `file_reference` | A file reference was put in the raw-PEM-only Python variable; owner reviews its setup. Path is never logged or opened; a reference in the old CLI variable is ignored by Python |
| `env_reference` | An env reference was put in the raw-PEM-only Python variable; owner reviews its setup. Target variable is never logged or resolved |

The existing escaped-newline check runs first; combined defects still report
`escaped_newline`. Otherwise classification uses the original leading prefix,
without trimming, unquoting, decoding, dereferencing or automatic fallback.
Each wrapper still exits 1 before PEM/JWT/HTTP and reveals no value, length,
fingerprint or traceback. Multiple wrappers reveal only the first classification.

Repository-confirmed configuration: all three iOS workflows reference the same
`prokat-app-store` integration and import only `prokat-ios-release`. They do not
assign either private-key variable in YAML vars, export them in scripts, or
write them through `CM_ENV`. `inputs.dart` does not produce Apple credentials.
Earlier setup instructions requested three same-named Apple variables in the
group, creating a potential overlap with integration-provided authentication.
Current Python setup requires the separate `PROKAT_ASC_PRIVATE_KEY_PEM` name;
issuer and key identifier keep their existing names. No new variable mapping,
CLI override or workflow architecture change is needed in YAML.
The pinned Codemagic CLI supports file/environment reference syntax in its
argument parser; our raw-PEM reader deliberately does not. This capability does
not prove the integration injects such a reference into this particular variable.

Not inspected: actual Codemagic application/team variable inventories, launch
overrides and the integration's effective representation/precedence. A source
collision is therefore a hypothesis, not a proven cause. Published precedence
for user variables is API > application > global/team; among imported groups at
the same level the last group wins. That rule alone does not establish where
integration injection falls. A second differently named imported group is not
present in this YAML; application/global definitions under the same group name,
API overrides or provider integration injection remain possible.

Owner may inspect **names, scopes and launch settings only** for the isolated PEM
and existing Apple variables in application variables, team/global variables,
`prokat-ios-release`, the selected integration and any build overrides. The new
name avoids the known CLI variable, but is not immune to app/team/API duplicates
of its own name. Inventory only: do not reveal, re-save, rename or delete values.
Repeated failure after re-saving a group Secret does not prove it was selected.
Actual inventories and integration precedence remain unverified; isolation does
not retroactively establish a provider override or the initial ValueError cause.

Next short diagnostic, after separate owner approval:

1. Review/integrate this small change through the existing feature → dev → main
   process; record the resulting approved main SHA. No version bump or tag.
2. Owner manually adds only `PROKAT_ASC_PRIVATE_KEY_PEM` as a Secret in the existing
   `prokat-ios-release`, with original raw PEM from the same existing .p8 (real
   line breaks, no wrapper). Keep old Secrets, integration, group and workflow
   unchanged. Verify matching issuer/key identifier and absence of duplicates
   by names/scopes; do not regenerate keys or print/copy values into logs/chat.
3. Authorize one manual `ios-apple-diagnostic` run from that main SHA. The current
   command remains `check --build 20`: if the new Secret is missing/invalid it stops before
   HTTP; if auth succeeds it continues with the documented GET-only checks.
   This run therefore needs GET approval too. For an auth-only run without any
   Apple network access, separately review changing only its final command to
   `auth --channel rc` and the corresponding workflow test; that change is not
   part of this environment-isolation patch. Never use a release workflow.
4. Record only fixed diagnostic status lines (including any failure category),
   build URL and public SHA. Do not print the prefix, reference target or value.
5. STOP. Use the category plus scope inventory to agree the next corrective
   action; do not automatically repair wrappers, read references, replace keys,
   remove integration or retry the release. Do not interpret auth success as
   permission for upload. Success still does not establish
   the cause of the original +20 ValueError.

## GET safety and release compatibility

### BuildUpload response contract

The owner reports diagnostic #4 at commit `bca435c` passed environment, PEM,
EC/JWT, app and builds, then failed with
`APPLE_RESPONSE_INVALID stage=uploads reason=schema`. A reproduced client defect:
the old `validate_resources(uploads, ("cfBundleVersion", "state"), "uploads")`
required a string `attributes.state`, while Apple's BuildUpload uses an object:

```json
{
  "type": "buildUploads",
  "id": "synthetic-upload",
  "attributes": {
    "cfBundleVersion": "18",
    "state": {"state": "COMPLETE", "errors": [], "warnings": [], "infos": []}
  }
}
```

Official sources: [BuildUpload.Attributes](https://developer.apple.com/documentation/appstoreconnectapi/buildupload/attributes-data.dictionary),
[BuildUpload.Attributes.State](https://developer.apple.com/documentation/appstoreconnectapi/buildupload/attributes-data.dictionary/state-data.dictionary),
[BuildUploadState](https://developer.apple.com/documentation/appstoreconnectapi/builduploadstate),
[StateDetail](https://developer.apple.com/documentation/appstoreconnectapi/statedetail).
Public Apple documentation JSON was inspected without credentials; no App Store
Connect account API was called.

`validate_build_uploads()` is separate from the unchanged string validator for
other resources. It requires a string `cfBundleVersion` accepted by the existing
build-number parser, an object `state`, and a nested string `state.state` in
`AWAITING_UPLOAD`, `PROCESSING`, `FAILED`, `COMPLETE`. Missing fields, flat string
states, unknown statuses/structures and invalid build numbers fail closed with
`APPLE_RESPONSE_INVALID stage=uploads reason=schema`. Apple's optional fields
are not treated as evidence of complete store state when absent: the client
still requires build number and status for release decisions.

Optional `errors`, `warnings`, `infos` must be arrays of StateDetail objects with
only optional string `code`/`description` fields. They may be absent or empty;
unknown members or malformed values block. Their text is never logged or saved.
After validation, in-memory release state and `apple-state.json` keep the prior
compact shape: `attributes.cfBundleVersion` plus a flat string `attributes.state`.
The API response is not mutated. Diagnostics still write no snapshot.

FAILED uploads are not ignored: every upload continues to reserve its number
and contribute to the historical maximum. An upload of 20 in any documented
state blocks 20; a higher upload blocks a non-increasing candidate. No retry,
pagination, historical floor or release/publishing guard was relaxed.

Red/green evidence: the synthetic nested-state diagnostic test failed on the
original client with exactly the reported uploads/schema error, while a separate
`all_pages()` control accepted that envelope. Both pass after the fix. Tests also
prove earlier envelope failures (invalid `links`, absent resource ID or malformed
`meta.paging`) produce the same uploads/schema code before attribute validation.
Thus the defect is proven, but the actual #4 response was not captured/queried;
the log line alone cannot rule out an independent envelope problem in that run.

Local schema-fix verification: 88 Python release tests PASS, including empty,
multiple and paginated uploads, all documented statuses, malformed state/details,
missing/invalid build numbers, occupied 20 and FAILED-number policy. Both RC and
production preflight preserve the compact snapshot without StateDetail leaks;
invalid/occupied uploads block the real release orchestration before publisher.
Flutter release regression: 118 PASS. Cached YAML/schema and all workflow Bash
syntax checks: PASS. Staged credential scan is part of the final local handoff;
none of these local checks execute Codemagic or account API requests.

After approved feature → dev → main integration, record the resulting main SHA
and request separate GO for one manual `ios-apple-diagnostic` / `check --build 20`
run. No Secret, signing, version, tag or publisher change is needed for this
schema fix. Keep the existing isolated PEM Secret. A new failure remains STOP;
green diagnostics do not authorize a release or establish build availability
outside the instant of those reads.

Read app → every builds page → every buildUploads page → every betaGroups page.
Only explicit GET requests, no body, retries or redirects. URLs must use HTTPS
and exactly `api.appstoreconnect.apple.com`; pagination keeps the original
collection path and app/platform filters. Cycles, duplicate IDs, malformed lists,
inconsistent totals and early termination fail closed. Each collection is capped
at 100 pages, each request at 15 seconds, with a shared 90-second HTTP budget.
Unsupported/forbidden buildUploads is UNKNOWN, never an empty history.

Availability requires target > historical floor and all observed build tuples,
with no matching builds/uploads. Failed, expired or processing records still
reserve numbers. Absence of `20` alone is insufficient when `21` or `20.1` exists.

`ios_store.py` shares auth/read/policy functions, but only its ordinary release
`preflight`/legacy `access` wrapper writes and prints `apple-state.json`.
Do not use legacy `access` as a no-write diagnostic. Early auth runs after the
existing source guard and before pub/pod/SwiftPM/tests. The release preflight
before IPA and its fresh recheck before upload remain mandatory. SDK provisioning
may already occur before release scripts, so early auth does not avoid all setup.

## Recovery decision: existing +20 or a new +21

**A — supported +20 retry:** first obtain current diagnostic success and fresh
Apple state, evidence that no upload happened, and provider confirmation that a
supported retry/replay preserves the original tag webhook context and uses the
current `prokat-ios-release` values (not a historical environment snapshot).
Required tag `rc/ios/v1.2.3+20`, full commit `5a34a3b95d554bc1660c23d58b902b77c5dd2447`,
matching native `CM_TAG`/`CM_COMMIT`, repository and non-PR context. All source,
main ancestry, tag/pubspec/history and live-store guards must run unchanged.
Later release tags can make +20 fail the common counter guard.

Selecting a tag manually in UI/API does not prove tag-webhook context. GitHub
Redeliver retains the original delivery ID, so deduplication is plausible but
must be confirmed from GitHub delivery and Codemagic Webhooks Results. Do not
forge delivery IDs or CM variables. The CLI deliberately rejects existing tags;
`prokat-rc-ios` is not an existing-tag replay command. If provider support or
context preservation is unproven, STOP and use B after separate approval.

**B — new release candidate:** required if release source changes are needed or
safe replay is unavailable. After owner approval, bump only the shared build to
`1.2.3+21` through feature → dev → main, using Squash and merge. Keep visible
version `1.2.3`; existing `releases/1.2.3` metadata/notes need no change unless
release content changed. Check both platforms' current tag/history and live
Apple availability; if 21 is reserved, STOP for a new decision. Review a diagnostic
command targeting 21, then `prokat-rc-ios -DryRun`; after explicit U4 GO use only
`prokat-rc-ios` for the approved main SHA. Android +19 stays accepted; do not
repeat Android. Production publishing stays disabled. After reserving 21, update
the next-common-release example/test to a build above 21.

Never delete, move or force-update +20. It identifies the original immutable
source; new main diagnostics do not change the code under that tag. A diagnostic-only
commit can keep build 20; a new release candidate needs its own approved number/tag.

## Local verification and acceptance

Use synthetic keys only and mocked in-memory Apple responses:

```text
python -B -m unittest discover -s tool/release -p '*_test.py'
flutter test --no-pub test/release --reporter expanded
git diff --check
```

Also validate Codemagic YAML against the existing schema and release workflow
contracts. Tests cover malformed PEM, JWT/HTTP/pagination/state errors, fixed
output and sentinels, no file writes, no publisher/subprocess calls, manual-only
diagnostics and unchanged release guards. No local test grants real API access.

Environment-isolation verification (local, 2026-10-21): 78 Python release tests
and 118 Flutter release tests passed; cached Codemagic YAML schema and all Bash
scripts passed validation. Synthetic tests reject missing/empty isolated PEM
even with a valid old CLI PEM, reject references without fallback or file reads,
and prove publisher is not invoked on auth failure or unknown Apple state.
The original YAML, publisher, signing/source guards, version and release metadata
are unchanged. No real credentials, cloud build or Apple request was used; actual
Secret setup and end-to-end GET verification remain owner actions.

Ready for an RC attempt requires diagnostic success, an approved recovery branch,
valid existing signing prerequisites and explicit U4 GO for tag/SHA/build.
Delivered to testers additionally requires verified IPA, Apple acceptance and
processing, group availability, installation and smoke tests. Diagnostic green
alone is never delivery. Stop after review/tests; merging, cloud diagnostics,
credential changes and release execution each require their own authorization.

Provider references: [CM variables](https://docs.codemagic.io/yaml-basic-configuration/environment-variables/),
[environment precedence](https://docs.codemagic.io/yaml-basic-configuration/configuring-environment-variables/),
[Builds API](https://docs.codemagic.io/rest-api/builds/),
[GitHub redelivery identity](https://docs.github.com/en/webhooks/using-webhooks/best-practices-for-using-webhooks).
