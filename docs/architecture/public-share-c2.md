# Public share recovery (C2)

C2 hardens the C1 pipeline; it does not add a second ingress/router or change
outgoing share URLs, booking APIs, domain association, or deferred providers.

## Persistence inventory

Keys below have a `local_` prefix when `Env.isLocal`. All durable records use
`SecureStorageClient.instance` / `FlutterSecureStorage` (Android default options,
iOS Keychain `first_unlock`). Separate key operations are not transactions.

| State | Key | Schema | Writer | Reader | Clear condition |
| --- | --- | --- | --- | --- | --- |
| Pending ingress | `equipment_share_state` | v3 envelope, inner open v1/v2 | `savePendingOpen` | ingress snapshots/flush | atomic accepted commit, permanent resolver failure, newer intent, logout |
| Accepted attribution | same envelope | v3, UUID intent/event ID | `completePendingIfUnchanged` | `readAcceptedOpen(equipmentId: ...)` | replacement, corruption, explicit cleanup/logout; not render or successful OTP |
| Durable overlay | same envelope | `{path, afterAuth}` | accepted commit, `saveOverlay`, auth continuation | bootstrap `consumeOnce` | target observed by router, existing cancelled-auth rules, replacement/logout |
| Guest form | same envelope | existing booking-intent shape | `saveBookingIntent`, with `afterAuth: true` for login | existing guest screen | existing completion/discard rules, newer share/logout |
| OPENED retry + GA claim | same envelope | UUID `intentId == open.clientEventId`, boolean flags | pending allocation, `claimOpenReceipt`, `finishOpenReceipt` | bootstrap recorder/flush | successful acknowledgement, newer intent/logout |
| Privacy revocation | `equipment_share_privacy_epoch` AND envelope epoch | `revision:UUID`; legacy `0`/UUID accepted | logout / quarantine recovery | envelope and first-touch readers | advanced, not deleted at ordinary logout |
| Install-referrer consumed | envelope boolean plus legacy `equipment_share_install_referrer_checked` | boolean / legacy `1` | pending referrer commit, completed empty check | bootstrap capture | preserved across replacement/logout |
| Signup first touch | `equipment_share_first_touch` | v1 plus optional privacy epoch | `ShareOpenRecorder`, `saveIfEmpty` | `AuthNotifier.verifyOtp` | successful OTP, existing 30-day expiry, corruption, explicit logout |
| Old pending/accepted/overlay/form | `equipment_share_pending_uri`, `equipment_share_accepted_open`, `equipment_share_overlay`, `equipment_share_booking_intent` | plain URI, v1/v2, old overlay/form | pre-C2 versions only | one-time migration | delete after canonical commit; canonical presence always takes precedence |
| OTP/session | existing `otp_session`, `otp_cooldown`, `auth_session` | unchanged auth schemas | `AuthSecureStorage` | existing auth/bootstrap | existing auth policy; C2 does not alter it |
| GA pending signup | none | user-bound `PendingSignUpValue` | successful new-user OTP | analytics identity listener | consumed by matching identity; in-memory only, existing best-effort semantics |

No new persistence package/database or arbitrary attribution TTL was added.
Accepted context remains available for Phase D before the existing booking call.
The existing first-touch policy is still first valid guest touch, expiring after
30 days; it is separate from latest-wins navigation attribution.

## Old write order and crash cuts

C1 wrote pending, cleared overlay, resolved, wrote accepted context, wrote overlay,
and deleted pending independently. Bootstrap deleted the overlay before pushing.
OPENED allocated a fresh clientEventId per send. Install Referrer was marked checked
before its pending write. These allowed partial records, lost navigation,
unnecessary resolution/replay, and retries with different event IDs.

C2 allocates a UUID intent/event ID and commits unresolved pending before resolve.
Resolver success replaces ONE envelope with accepted open + overlay + OPENED
receipt + pending=false. Therefore the accepted/overlay/pending-cleanup cuts are
one storage replacement, not three independent writes. Guest form + afterAuth
overlay are also one replacement. A failed guest continuation shows the existing
generic retry toast and does not navigate to login with an unsaved instruction.

## Startup reconciliation

1. Read privacy marker and canonical epoch; use the higher revocation revision.
   This covers either logout write failing even if an older marker already exists.
2. Strictly validate version, types, token, routing ID, source, UUID correlation,
   timestamps, and overlay/form target consistency. Invalid canonical data becomes
   an empty tombstone; do not fall back to stale legacy records.
3. If canonical is absent and no revocation exists, migrate plain URI/v1/v2.
   Legacy pending wins over unrelated old accepted/overlay records. Path-only
   legacy overlays remain usable but cannot prove their shareId, so they are not
   combined with accepted attribution merely because equipment IDs match.
   Likewise, an uncorrelated old form is preserved without attaching the old
   accepted share solely by equipmentId.
4. Unresolved pending waits for existing startup/auth readiness, then resolves
   again safely. Temporary failures retain it; one bootstrap does not loop.
5. Correlated accepted state needs no repeat resolver call. An unacknowledged
   OPENED receipt can retry with its original event ID; navigation never waits.
6. Overlay claim is process-local; durable overlay remains until the router
   observes the target. Death during claim/pre-push/post-decision reconstructs the
   same instruction in a new process. Target observation clears only the overlay,
   not accepted attribution. Later startup notifications do not push it again.

During recovery, an untimestamped initial-platform callback cannot supersede an
existing durable pending/overlay/receipt. Fresh runtime links remain authoritative.
This deliberately favors durable recovery when initial-link freshness cannot be
proven; it does not invent a history queue.

## Races and logout

One provider-owned storage queue serializes native operations. Revision tokens
change when replacement/clear is REQUESTED, not after a delayed write completes.
Snapshot tokens are captured when the read is requested. Ingress generations
reject stale resolver results; queued old writes finish before newer writes, and
stale overlay consumers cannot delete/claim a newer intent.

Logout fences the account generation before any remote push/auth cleanup and
keeps new ingress fenced until session/provider cleanup completes. Queued
old writes precede a monotonic epoch marker and empty tombstone. Either successful
revocation write is enough to reject old accepted/overlay/first-touch data after
restart. Pending resolver results and side-effect callbacks cannot restore it.
Old Install Referrer is not re-consumed after privacy revocation. First-touch
deletion is best-effort; epoch mismatch makes retained bytes non-actionable.

Read failures do not substitute arbitrary/old routing data. Pending-write failure
quarantines old state; accepted commit failure keeps original pending retryable.
Cleanup failures do not escape logout or brick ordinary startup. In-memory
quarantine retries revocation when storage becomes available again.

Durability necessarily requires at least one successful native write/delete:
if ALL storage operations fail and the process dies before storage recovers, no
code can record that a logout happened. Tests cover fail-closed memory behavior
and healthy retry, plus independent marker/tombstone failures across restart;
they do not claim durable erasure in a total-storage-outage-and-process-loss case.
Nor do Dart fixture tests prove physical Keychain/Android power-loss atomicity.

## OPENED and analytics

`intentId` is generated before pending persistence and is retained as
`clientEventId` through resolution, recovery, and resend. Backend's existing
unique clientEventId/P2002 handling acknowledges duplicate OPENED with
`recorded: false`. Both true and false acknowledgements complete the local receipt.
A timeout/invalid acknowledgement leaves it retryable; no infinite retry loop.
Transport is bounded to 10 seconds including interceptor work.

The recovery contract is at-least-once attempt with stable ID + backend dedup,
not guaranteed delivery or exactly-once end-to-end. A newer share can replace an
older unsent receipt (latest-wins, no backlog). Registry GA uses `share_id` and
`open_via=app_link`/`install_referrer`, without equipment `item_id`. Its claim is
persisted before dispatch: recovery avoids repeating GA, but a crash between
claim and dispatch can lose GA. First-touch failure keeps the ledger receipt
retryable even when the backend already acknowledged it. SHARED and SIGNED_UP
contracts remain unchanged. Existing GA signup marker is still in-memory.

Identical actionable delivery reuses the intent across restart. After route
acknowledgement and the two-second window, an intentional later open can allocate
a new ID. Two shareIds targeting the same equipment remain separate intents.

## Deferred and retirement boundaries

A future adapter supplies `shareId` + `ShareOpenVia.deferredInstall` to the SAME
ingress. Before/after-resolution restart retains the source, UUID, attribution,
and overlay. No unsupported deferred GA/ledger/first-touch wire events are enabled.
No vendor URL/SDK is introduced.

Historical backend resolution is not proof of current availability/bookability,
including retired equipment. Existing equipment APIs/screens decide availability.
The public Web domain is still rejected as native ingress. VPS/DNS/AASA/assetlinks
remain Phase E; booking attribution policy remains Phase D.

## Verification approach

`equipment_share_recovery_test.dart` uses durable in-memory bytes with per-native
client crash-before/after-commit and I/O fault injection. Recovery reconstructs
new storage AND ingress instances; the old dead client cannot execute cleanup.
It covers all nine logical crash cuts, resolver/write/logout races, duplicates,
legacy migration/corruption, independently failing logout writes, auth readiness,
guest form/overlay atomicity, referrer consumption, deferred source, and stable
OPENED retries. Real GoRouter/bootstrap widget tests cover delayed initial vs
runtime/durable links, afterAuth restart, one push/ack, and existing back behavior.
Auth tests exercise real OTP continuation against a fake Dio adapter. Recorder/API
tests check payloads and acknowledgement semantics without production networking.
No physical device/domain association, real storage crash, or live backend call
is claimed.

Validation on 2026-10-09: formatting/check of 22 changed Dart files passed;
`flutter analyze --no-pub` reported no issues. Recovery/overlay suites passed
88 tests; focused share/auth/startup/router/analytics/API/booking suites passed
426 tests. Full `flutter test --no-pub` passed 878 tests with one existing
environment-dependent Firebase-services skip. No C2 test was skipped.
