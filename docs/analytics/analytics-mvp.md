# Analytics MVP semantics

This document describes the analytics behavior implemented at mobile HEAD
`39d149dd1dc1fddbd5ddd90e6388b5330f409108`, together with the corresponding
share landing and backend ledger implementation. It is a description of
observable implemented behavior, not a target design.

## Firebase Analytics and landing events

All mobile writes are best-effort: analytics failures are swallowed and do not
change the product flow. Optional parameters are omitted when their value is
unknown. Boolean event parameters are sent as `1` or `0`.

| Event | Producer | Exact trigger | Parameters | Meaning | Not meaning | Source of truth | Example |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `sign_up` | Flutter app | A successful OTP verification returns `isNewUser=true`; after that user's Firebase identity and `user_role` have been applied, the user-bound pending sign-up is consumed. | `method=phone_otp`; optional `share_id` from a still-valid first touch. | The backend created a user during this OTP verify. | Not every OTP verification or login; not proof of an attributed install. | `lib/features/auth/providers/auth_notifier.dart`, `lib/core/analytics/analytics_identity.dart`, backend `auth.controller.ts` | `sign_up {method: phone_otp, share_id: AbCd..._-}` |
| `owner_application_started` | Flutter app | Once per `RegisterOwnerPage` instance, after current-account data is loaded and the application is startable: there is no request or the request is rejected. | None. | A user reached a usable owner-application form. | Not a submitted application; not necessarily the first lifetime visit. | `lib/features/owner/screens/register_owner_screen.dart`, `lib/core/analytics/supply_analytics_rules.dart` | `owner_application_started {}` |
| `owner_application_submitted` | Flutter app | `createOwnerRegistrationRequest` returns success. | `is_resubmit=0|1`; `1` when the prior request was rejected. | The backend accepted creation/resubmission of an owner application. | Not approval and not merely tapping submit. | `lib/features/owner/screens/register_owner_screen.dart` | `owner_application_submitted {is_resubmit: 1}` |
| `equipment_creation_started` | Flutter app | Once in the post-frame callback of each `CreateEquipmentScreen` instance. | Optional `is_first_equipment=0|1`; omitted when the current owner-equipment query is not loaded. | The create-equipment screen started. | Not a saved draft or completed form; `is_first_equipment` is based on currently available list state. | `lib/features/equipment/screens/create_equipment_screen.dart`, `lib/core/analytics/supply_analytics_rules.dart` | `equipment_creation_started {is_first_equipment: 1}` |
| `equipment_draft_created` | Flutter app | The create-equipment mutation returns `true`. | `category_id`; `catalog_group=machinery|equipment`; optional `is_first_equipment=0|1`. | An equipment draft was successfully created. | Not submitted for review, approved, or published. | `lib/features/equipment/screens/create_equipment_screen.dart` | `equipment_draft_created {category_id: excavators, catalog_group: machinery, is_first_equipment: 0}` |
| `equipment_submit_blocked` | Flutter app | A review submission attempt is stopped because dirty-field save validation is invalid, the latest equipment has no image, or the latest equipment is otherwise not review-ready. | `reason=photo_missing|fields_incomplete`. | Client-side readiness prevented this review submission attempt. | Not a backend rejection, transport failure, or count of unique equipment. | `lib/features/equipment/screens/owner_equipment_detail_screen.dart`, `lib/core/analytics/supply_analytics_rules.dart` | `equipment_submit_blocked {reason: photo_missing}` |
| `equipment_submitted_for_review` | Flutter app | Updating equipment status to `CREATED` returns success after readiness checks. | `is_resubmit=0|1`; optional `category_id`; optional `catalog_group=machinery|equipment`. | The review-submission status update succeeded. | Not moderation approval or publication. | `lib/features/equipment/screens/owner_equipment_detail_screen.dart` | `equipment_submitted_for_review {is_resubmit: 1, category_id: excavators, catalog_group: machinery}` |
| `share` | Flutter app | `SharePlus` returns `ShareResultStatus.success`. | `content_type=equipment`; `item_id`; `share_id`; `method=whatsapp|telegram|instagram|copy|other|unknown`. | **share = system share flow reported success, NOT message delivered.** | Not delivery, reading, a unique recipient, or an authenticated backend ledger write. | `lib/features/equipment_share/equipment_share_service.dart`, `equipment_share_result.dart`, `equipment_share_id.dart` | `share {content_type: equipment, item_id: eq-1, share_id: AbCd..._-, method: whatsapp}` |
| `share_link_opened` | Flutter app | An accepted App Link or Android Install Referrer share link is recorded when startup is ready (or its pending record is flushed), before the equipment overlay is written. | `item_id`; optional `share_id`; `open_via=app_link|install_referrer`; `first_share_bootstrap_run=0|1`. | **share_link_opened = share carrier reached app or landing, NOT unique recipient.** In this row it reached the app. | Not proof of a new install, first app open, unique person, or successful equipment load. | `lib/features/equipment_share/equipment_share_bootstrap.dart`, `equipment_share_open_recorder.dart` | `share_link_opened {item_id: eq-1, share_id: AbCd..._-, open_via: install_referrer, first_share_bootstrap_run: 1}` |
| `share_link_opened` | Firebase-hosted landing | A landing page with a non-empty `/e/<equipmentId>` path executes its analytics script. | `item_id`; `open_via=web_landing`; optional valid `share_id`. | **share_link_opened = share carrier reached app or landing, NOT unique recipient.** In this row it reached the web landing. | Not an installed-app App Link open: the landing cannot see App Link opens handled inside the installed app. Not proof the store link was clicked. | `share-hosting/public/e/index.html` | `share_link_opened {item_id: eq-1, share_id: AbCd..._-, open_via: web_landing}` |
| `store_link_clicked` | Firebase-hosted landing | The user clicks the Android Play link rendered by a valid equipment landing. | `item_id`; optional valid `share_id`; `transport_type=beacon`. | A click on the landing's Play link was reported. | Not a store page load, install, first open, or iOS attribution. | `share-hosting/public/e/index.html` | `store_link_clicked {item_id: eq-1, share_id: AbCd..._-, transport_type: beacon}` |
| `screen_view` | Flutter app / Firebase Analytics | GoRouter notifies a transition to a mapped route template and its mapped screen name differs from the last reported mapped screen. | Firebase `screen_name` and `screen_class`, both set to the same mapped value. | A mapped logical app screen became current. | Not every route: unmapped routes are not reported. Not a count of unique users or screen instances. | `lib/core/analytics/screen_tracking.dart`, `firebase_analytics_client.dart` | `screen_view {screen_name: owner_equipment_detail, screen_class: owner_equipment_detail}` |

Implemented `screen_name` values are `guest_main`, `client_search`,
`client_profile`, `become_owner`, `owner_profile`,
`owner_business_profile`, `owner_equipment_list`, `owner_equipment_create`, and
`owner_equipment_detail`. Route parameters are not included in the name.

## Identity and collection policy

`user_role` is a Firebase user property, not an event parameter. For an
authenticated user it is `owner` when either the JWT owner flag is true or the
normalized profile role is `owner`/`admin`; otherwise it is `client`. For a
guest, both Firebase user ID and `user_role` are cleared. Identity applications
are serialized, and `sign_up` is sent only after the new user's identity has
been set.

Mobile analytics collection is enabled only when Firebase services are enabled
and either:

- `APP_ENV=production` and the build is not a debug build; or
- the compile-time boolean `ANALYTICS_FORCE_COLLECTION=true`.

`ANALYTICS_FORCE_COLLECTION` therefore enables collection in debug/local builds
and also in production debug builds, but it does not override
`ENABLE_FIREBASE_SERVICES=false`. When Firebase services are disabled, the app
uses a no-op analytics client. The hosted landing has its own GA tag and does
not read the mobile `APP_ENV`, `ENABLE_FIREBASE_SERVICES`, or
`ANALYTICS_FORCE_COLLECTION` flags. Its `debug_analytics=1` query parameter sets
GA `debug_mode`; it does not define the mobile collection policy.

## Share and first-touch semantics

`share_id` is an opaque, unpadded, 22-character base64url value generated from
16 random bytes immediately before each system share flow. It identifies one
share act/carrier lineage, not a user or recipient. A forward keeps the same
`share_id` because the existing URL is forwarded unchanged. Therefore one
share is not one recipient: the same link and `share_id` can reach or be opened
by multiple recipients, browsers, and installations.

The app accepts a valid `share_id` through App Links and Android Install
Referrer. Invalid or absent values are treated as no `share_id` while the
equipment link may remain valid. The web landing carries the same valid value
into the Play referrer.

For an unauthenticated accepted share open, the app stores the first valid
first-touch record in secure storage. A non-expired record wins over later
opens. The first-touch TTL is 30 days; expired records are deleted and can be
replaced. A successful OTP verification clears the stored first touch whether
the user is new or existing. Only a newly created user causes `sign_up` and,
when the submitted attribution passes backend validation, backend `SIGNED_UP`.
The backend independently enforces the same 30-day TTL and rejects a
`firstTouchAt` more than five minutes in the future.

`first_share_bootstrap_run` = first share-bootstrap run of that installation,
NOT first app open, NOT new user, NOT proof of a new install. Concretely, the
share link was handled while the Android Install Referrer checked marker was
still unset.

New install evidence requires **Firebase `first_open` plus either GA
`share_link_opened(open_via=install_referrer)` or backend `OPENED` with
`openVia=INSTALL_REFERRER`**. Backend `OPENED` alone does not prove a new
install. No single custom flag or event is sufficient.
iOS install attribution is not implemented. iOS App Links can produce app-link
opens, but there is no iOS install-referrer equivalent in this implementation.

## Backend `EquipmentShareEvent` ledger

The backend table is an append-only product ledger distinct from Firebase
Analytics. Mobile event POSTs include a generated UUID `clientEventId`; its
unique constraint makes a repeated POST idempotent. Mobile writes are
best-effort and are not retried. `installationId`, when present, is stored only
as a domain-separated hash.

| Event | Producer | Exact trigger | Parameters | Meaning | Not meaning | Source of truth | Example |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `SHARED` | Authenticated Flutter app → backend | After `SharePlus` reports success, independently of the Firebase `share` write; the client sends it only if authenticated, and the backend requires authentication. | `clientEventId`; required `shareId`, `equipmentId`; optional `method`; backend-derived `userId`; optional `installationHash`; `createdAt`. | An authenticated system share flow reported success and the ledger insert won idempotency. | Not message delivery, recipient identity, link open, or one recipient. | Mobile `equipment_share_result.dart`, `equipment_share_events_api.dart`; backend `equipmentShare.service.ts`, Prisma `equipment-share.prisma` | `SHARED {shareId: AbCd..._-, equipmentId: eq-1, method: whatsapp}` |
| `OPENED` | Flutter app → backend | The same accepted in-app share open recording that emits mobile `share_link_opened`; sent for authenticated and guest clients. | `clientEventId`; optional `shareId`; `equipmentId`; `openVia=APP_LINK|INSTALL_REFERRER`; `firstShareBootstrapRun`; optional backend-derived `userId` and `installationHash`; `createdAt`. | The share carrier reached the app via an accepted App Link or Android Install Referrer. | Not a web-landing view, unique recipient, new install, first app open, or successful equipment fetch. | Mobile `equipment_share_open_recorder.dart`, `equipment_share_events_api.dart`; backend `equipmentShare.service.ts` | `OPENED {equipmentId: eq-1, shareId: AbCd..._-, openVia: INSTALL_REFERRER, firstShareBootstrapRun: true}` |
| `SIGNED_UP` | OTP backend | OTP verification created a new user and the submitted first-touch attribution passed shape, 30-day TTL, and future-time checks; recording is best-effort and must not fail login. | Optional `shareId`; `equipmentId`; new `userId`; optional `installationHash`; `openVia=APP_LINK|INSTALL_REFERRER`; `firstShareBootstrapRun`; `firstTouchAt`; `createdAt`; `clientEventId=null`. | The backend created a user during this OTP verify with accepted first-touch metadata. | Not an existing-user login, Firebase event delivery, proof of installation, or proof that the attributed link caused the signup. | Backend `auth.controller.ts`, `equipmentShare.service.ts`, Prisma `equipment-share.prisma` | `SIGNED_UP {userId: user-1, equipmentId: eq-1, shareId: AbCd..._-, openVia: APP_LINK}` |

The landing does not write backend `OPENED`; it only writes GA events. Likewise,
an App Link resolved directly into an installed app does not execute the
landing, so landing analytics cannot observe that open.

## Future booking attribution

Booking attribution is a future inference only. A future analysis could infer
a relationship by joining existing share/open/signup evidence with later
booking facts under an explicitly defined model and uncertainty rules. The
current implementation does not record a share reference on a booking, does
not establish a causal booking conversion, and must not add or assume
`Booking.shareId`.
