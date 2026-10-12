# Public share ingress (C1)

Persistence and recovery details below describe the C1 baseline. See
[C2 recovery](public-share-c2.md) for the current versioned envelope, logout,
overlay acknowledgement, and OPENED retry behavior.

## Single pipeline

`equipmentShareBootstrapProvider` subscribes to `app_links` before awaiting
`getInitialLink`. Initial links, runtime links, and existing Android Install
Referrer output enter `EquipmentShareIngress`. Startup readiness gates processing.
Pending intent is persisted before resolution; successful resolution stores the
accepted attribution context and the existing durable overlay. Only bootstrap's
overlay consumer calls `router.push('/e/<equipmentId>')`. The router redirect and
`GuestCreateBookingScreen` auth/back-stack behavior are unchanged.

## URLs and identity

- Native ingress: `https://open.prokat.auyltech.kz/e/<22-char-base64url-shareId>`.
  HTTPS, exact host/path, no user info, nonstandard port, extra segment, or fragment.
  Query parameters cannot change the token/target and are discarded.
- `https://prokat.auyltech.kz/e/<shareId>` is always Web and is rejected by Flutter
  native ingress, even if configured as an outgoing legacy share origin.
- Legacy Firebase hosts (`prokat-bfbec.web.app`,
  `prokat-bfbec.firebaseapp.com`) and the existing configured trusted legacy origin
  retain `/e/<equipmentId>?s=<shareId>` semantics. Invalid `s` is omitted without
  invalidating a valid legacy equipment link. Encoded separators cannot become
  equipment routing data.

`EquipmentShareOpen` retains `shareId` as attribution identity. `equipmentId` is
nullable until resolution and then remains internal routing data. `source`
distinguishes `legacyLink`, `appLink`, `installReferrer`, and reserved
`deferredInstall`; `via` preserves the existing analytics/backend transport values.

## Resolver and failure handling

`EquipmentShareResolver` uses the existing `dioProvider` with its mobile
authorization, installation, client metadata, and App Check interceptors.
`GET /equipment-shares/resolve/<shareId>` must return
`{success: true, data: {shareId, equipmentId}}` with the matching token and a valid
backend equipment identifier. Redirects are disabled. Send/receive timeouts are
8 seconds; the complete operation, including interceptor work, is bounded by
10 seconds and cancellation.

- 404/invalid token: unavailable, discard pending intent, no navigation/open event.
- Offline, timeout, 429, 5xx, auth failure, or malformed response: generic temporary
  failure, retain pending context, no navigation/open event.
- Bootstrap shows the existing localized unavailable/retry toast, not technical
  response details. It does not create a loading screen or retry loop.
- Normal startup notifications do not retry the failed generation. Reopening the
  link after the two-second duplicate guard, a new application bootstrap, or an
  explicit `flushPendingUriIfAny(retry: true)` can retry. There is no background
  retry scheduler or new retry screen in C1.

The resolver is historical and does not check listing visibility. The existing
equipment screen's public equipment fetch determines current availability.

## Persistence and races

The pending secure-storage key is unchanged. Legacy v1 JSON and plain-URI values
remain readable. Registry links use v2 JSON with the canonical share-token URI,
`via`, `firstShareBootstrapRun`, and an optional `resolvedEquipmentId`.

Pending operations are serialized on the provider's storage instance. Snapshot
generation tokens prevent stale resolution from completing a newer/cleared
intent. Ingress generations provide latest-wins semantics, suppress old A after B,
and reject results after disposal. Initial-link delivery is discarded if runtime
ingress already advanced the generation. Identical delivery is suppressed during
in-flight processing and for two seconds; this is not global unique-recipient or
permanent event deduplication.

Overlay serialization, conditional claims, `consumeAgain`, and the single push
remain authoritative. The new pending-generation check additionally prevents an
old overlay claim from navigating while a newer share is being resolved.

Accepted context is stored separately as `equipment_share_accepted_open` (with the
existing local prefix in local environments). It survives pending consumption,
normal login/OTP continuation, and restart. `readAcceptedOpen(equipmentId: ...)`
requires the current target to match. Logout/account cleanup clears it along with
pending, overlay, and booking intent. First-touch signup attribution retains its
existing independent 30-day/first-wins policy and successful-OTP cleanup.

Native secure-storage writes are serialized, not transactional across process
death. Crash recovery around accepted-context/overlay/pending completion and
longer-term deduplication policy remain C2 hardening candidates, not exactly-once
guarantees of C1.

## Analytics and ledger

Only a resolved, accepted incoming share invokes `ShareOpenRecorder`. Navigation
does not wait for analytics, ledger, or first-touch storage side effects.

- Registry app ingress: GA `share_link_opened`, `share_id`, `open_via=app_link`,
  and the existing diagnostic `first_share_bootstrap_run`; no equipment `item_id`.
- Legacy analytics retains its existing `item_id`/optional `share_id` contract.
- Backend `OPENED` uses the same shareId, resolved equipmentId, existing
  `APP_LINK`/`INSTALL_REFERRER`, and `clientEventId` write semantics.
- Guest first touch continues through OTP attribution and user-bound `PendingSignUp`
  to existing `SIGNED_UP`/GA `sign_up` behavior.
- Outgoing SharePlus, `SHARED`, and outgoing legacy URLs are unchanged in C1.

`first_share_bootstrap_run` is not an install claim; an OPENED event is not a
unique recipient or proof of share-caused signup.

## Deferred integration and install-referrer boundary

A future adapter supplies only a validated shareId and ingress source, via
`ref.read(equipmentShareBootstrapProvider).acceptShareId(..., via:
ShareOpenVia.deferredInstall)`. This enters the same resolver/pending/overlay flow.
No vendor types, provider SDK, or second navigation implementation is needed.

`deferred_install` is reserved internally. C1 deliberately sends no GA/ledger/
first-touch event for that source: current backend OPENED/OTP contracts accept
only APP_LINK and INSTALL_REFERRER. The eventual deferred phase must explicitly
extend the accepted attribution contract and enable reporting; the architectural
test now verifies the shared downstream path only.

Existing Android referrer handling (`id=<equipmentId>&s=<shareId>` or a full trusted
share URI) is preserved. The new Web direct Google Play CTA contains no share
referrer; C1 does not make that install path restore a share. iOS deferred restore
is also not implemented.

## Phase D handoff and verification limits

Phase D can read target-matched accepted context before
`GuestCreateBookingScreen._createOrder` calls `BookingMutationNotifier.createBooking`.
Attribution TTL/consumption and booking request/schema changes belong to D, not C1.

Unit/widget tests use controlled Dio adapters, mocked app_links/referrer platform
channels, mocked secure storage, and the existing GoRouter harness. They cover
cold/warm/resume, pending/OTP continuation, old persistence, stale async ordering,
resolver errors/timeouts, navigation dedup/back-stack, mobile metadata, and
analytics/ledger compatibility. They do not contact production or prove physical
iOS/Android domain association. DNS, VPS, AASA, assetlinks, manifest/entitlement
changes and physical App/Universal Link checks remain Phase E.
