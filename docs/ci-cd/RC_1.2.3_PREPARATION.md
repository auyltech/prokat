# PROKAT 1.2.3+19 — U4-B preparation

Historical snapshot, not a current invocation guide. Use [the four Lean CLI
commands](../../CICD-README.md) and a common build counter. Do not replay old
SHA/tag examples; results and commit evidence below remain unchanged.

Date: 2026-10-20. Branch: `feat/tag-only-mobile-release`. This records local
preparation, not U4 GO. No PR merge, release tag, cloud release build, store upload,
certificate/profile creation or production configuration change is authorized.

## Prepared source

- `ecdc750c`: the seven reviewed Export Compliance files; Boolean false for
  Kazakhstan-only availability, France unavailable, standard Dart/BoringSSL TLS.
  Closed SDK limits remain documented in [the audit](APPLE_EXPORT_COMPLIANCE.md).
- `ae63e02c`: every RC/production source must belong to freshly fetched main.
  Missing/unavailable main fails closed even with a cached ref. Shallow history
  is restored first; CI also verifies the real local/remote tag commit and HEAD.
  GitHub checkout has `fetch-depth: 0`; Codemagic restores shallow history and
  fetches main before calling the same guard. Tag patterns/destinations unchanged.
- `releases/1.2.3/`: schema 1, version `1.2.3`, ready notes in RU/EN/KK. Native
  build 19 comes from each platform tag. Pubspec's `1.2.2+18` remains a local
  default; CI overrides build-name/build-number. The metadata test uses the real
  parser/exporter for both `rc/android/v1.2.3+19` and `rc/ios/v1.2.3+19` in a
  temporary directory, without creating those tags or contacting stores.

Notes describe implemented update notifications and public equipment links.
They do not advertise CI/CD, promise a patch-update dialog, mention the future
owner-profile UI, or claim installation/device QA. `ready: true` is metadata
readiness, not owner permission to publish.

## Application scope relative to main

Main is `b481e0c4f0f13dc711b722d8e760b9048966983e` (release 1.2.2+18).
The new application work is `5ef7a216` (isolated local replica configuration) and
`7346fea1` (update policy/Remote Config and canonical public outbound links).
Existing public-share attribution/recovery code is retained. There is no new
owner-profile UI in the tree diff against main. The local replica path is
explicitly gated; it is not the RC production configuration. No unintended new
experimental feature was found in the inspected diff; device QA remains pending.

Dev is `b927dd37f468d189112c3695d55efacfae4a5392`. Its extra quota-error fix is
not yet in feature. It must be retained in the final release; the notes do not
claim it is already in the current feature tree.

## Integration analysis and owner actions

At the inspected refs, the common feature/dev ancestor is
`7346fea1ed9942da5aa1bc6c49c33fcc7a1eab76`.
Dev-only commit: `b927dd37` (13 changed paths). Main-only commit relative to
feature: `b481e0c4`. Feature had 20 CI/tooling/docs/IDE commits at the starting
SHA `0c0108b54d957bb3c3d5ad0bce43f74a7d232ed8`; U4-B adds separate compliance,
guard and metadata/preparation commits.

`git merge-tree --write-tree --name-only` was used only to compute hypothetical
trees; it did not merge branches, create commits, modify the index or checkout.
Feature-only and dev-only changed-path sets do not overlap. Feature -> dev
simulation has no conflicts; all 13 quota-fix paths equal dev's blobs exactly
in the simulated union. A squash merge preserves the fix's content in dev even
though its original SHA need not be an ancestor of a later main squash.

Both current dev -> main and feature -> main simulations report these six
conflicting paths; choosing squash alone does not remove those conflicts:

- `android/app/src/main/AndroidManifest.xml`
- `lib/features/bookings/notifiers/booking_mutation_notifier.dart`
- `lib/features/equipment_share/equipment_share_events_api.dart`
- `lib/features/equipment_share/equipment_share_link.dart`
- `lib/features/equipment_share/equipment_share_open_recorder.dart`
- `test/features/equipment_share/equipment_share_bootstrap_test.dart`

The histories diverged around the released 1.2.2 squash. A commit-count diff is
not a list of new app features; compare trees as well. No automatic rebase,
merge commit, force push, checkout switch or local dev update was performed.

Owner sequence:

1. Open feature -> dev PR, review the full tree diff and tests. Use squash if
   required by branch protection/linear history. Confirm protection settings
   and required checks in GitHub; they were not queried through an authenticated
   API here. Do not merge under U4-B authority alone.
2. After owner-authorized merge, fetch and inspect the resulting dev SHA. Verify
   the quota fix, metadata, main guard, compliance flag and absence of unrelated
   changes; rerun tests against the combined tree, including the quota tests.
   Current local tests run on feature and do not include that dev-only test.
3. Prepare a separate promotion PR into main. Do not blindly merge the whole
   dev history. Either resolve the six content conflicts under owner review,
   or use a separately authorized integration branch based on current main and
   apply only the reviewed main-to-approved-release-tree diff as normal commits.
   The latter avoids historical merge conflicts and supports a linear squash.
   Preserve the reviewed quota fix and existing released behavior; do not apply
   a blanket ours/theirs resolution. Compare the resulting tree to the approved
   release tree and rerun tests before owner approval.
4. After the approved code is in main, record one full main SHA for both tags.
   Refresh store preflights and obtain a new explicit U4 GO. Tags remain forbidden
   until then, regardless of branch push or metadata readiness.

Manual PR URL (GitHub CLI is not authenticated):
https://github.com/auyltech/prokat/compare/dev...feat/tag-only-mobile-release?expand=1

Choose base repository `auyltech/prokat`, base `dev`, compare
`feat/tag-only-mobile-release`. Suggested title:
`Prepare guarded Android/iOS RC delivery and 1.2.3 release metadata`.

Suggested PR body:

> Adds tag-only Android Internal Testing and iOS internal TestFlight delivery,
> requiring the real tagged commit to be reachable from freshly fetched main
> for RC and production. Includes Kazakhstan-only Export Compliance false and
> localized 1.2.3 notes for implemented update prompts/public equipment links.
> Keeps dev's quota-error fix through the reviewed integration; it is absent
> from feature alone. No release refs, uploads or production activation.
>
> Review the validation below. After feature -> dev approval, test the combined
> tree and prepare a separate main promotion PR; historical main conflicts need
> reviewed resolution. This PR does not authorize U4 execution.

## Local validation

Focused Dart release tests: 81 PASS before adding the tracked-metadata test;
tracked RC metadata test: 1 PASS. New source cases cover all four tag contracts,
feature/dev rejection, missing/unreachable main despite cache, fresh main fetch,
shallow history, wrong/dirty source, and annotated/lightweight real tag commits.
Fixture tags exist only in disposable test repositories, not PROKAT/GitHub refs.

Final executed checks on this feature tree:

| Check | Result |
| --- | --- |
| Full Flutter suite, Firebase/push disabled for tests | 1144 PASS, 3 SKIPPED; includes 82 release tests and update-policy tests |
| Flutter analyze, fatal infos/warnings; Dart release analysis | PASS |
| Python release suite, including workflow contracts and 5 IPA verifier tests | 41 PASS |
| Ruby Play policy; Supply SDK and snapshot/error contracts | 22 policy cases PASS; SDK/snapshot checks PASS in offline read-only Docker |
| GitHub Actions actionlint | PASS; local shellcheck/pyflakes disabled |
| Codemagic YAML validation | PASS against the existing cached JSON Schema; no runner execution |
| iOS native lock guard | PASS |
| Plist parse/unique keys/Boolean false | PASS |
| Diff whitespace and staged credential-path/key/token scan | PASS before commits |

Tests make no real store requests. Git fixture repositories and metadata export
directories are temporary; no application worktree or release tag was created.

## Store readiness boundaries

No local Apple/Play credentials are requested. Existing CI integrations provide
them. Android `play.rb preflight` takes a live snapshot before building; publish
repeats it immediately before Supply upload. Codes/tracks and historical floor
are checked; an unknown or already-used number blocks. iOS `ios_store.py
preflight` checks builds, in-flight Build Uploads and the internal group before
building; publish repeats checks before upload. API/pagination errors fail closed.

Availability of build 19 is NOT confirmed by historical maxima (Android 18,
iOS 17). AAB/IPA verification, real signing, CI credential installation, Apple
processing and tester availability remain runtime U4/A5 evidence. Existing
certificates/profiles must be used; no regeneration is authorized.

RC routes remain Play `internal` and TestFlight's existing internal group
`AuylTech Test Team`. Production gates and production Remote Config stay unchanged.
RC uses production API/Firebase: smoke-test mutations affect real data.

Update policy does not invent availability from a minimum/force setting.
Patch/build-only changes are silent; minor is soft, major is hard, and emergency
rules require a supported newer Store version. RC 1.2.3 can be newer than the
public Store; opening App Store is not a TestFlight update. Use deterministic
injected Store/Remote Config tests or separate QA configuration for extra policy
checks, never a global production minimum for an unavailable RC.
