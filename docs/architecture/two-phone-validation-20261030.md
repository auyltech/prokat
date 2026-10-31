# Two-device local validation — 2026-10-30

## Scope and environment

Latest merged redesign/dev code, mobile candidate 1.4.0+28 (`b262bff0` before this session), backend `bca96dc`, web `c2c63d1`. No production deployment, release tag or store upload. Local PostgreSQL replica from 2026-10-29; existing volumes preserved. Prisma reports 55 migrations, database up to date. API 4000, web 3000, MinIO 9000/9001. Fake OTP and automatic-business-job isolation remain enabled; analytics/crash reporting disabled.

Devices: Samsung S22 R3CT60F7MRV (client) and A12 R58R60PHZ9E (owner). Both use the same local profile APK through USB reverse tcp:4000. Only dedicated photo-qa-client / photo-qa-owner fixtures were changed. Local test addresses and owner test minutes were added; no real payments.

## Manual results

- Listing details and chat icon open a discussion without creating a booking (`bookingId == null`). Existing history is retained.
- Client HelloA12 and owner ReplyS22 messages delivered in real time. Read receipts updated on the sending phone.
- Foreground notification banner observed. Real Firebase background push delivered to each device; tapping each notification opened the correct chat/role.
- Client submitted initial terms (18,000 KZT/hour, QA Client Avenue). Booking became CREATED, same chat retained.
- Owner proposed 20,000 KZT/hour, QA Owner Street and changed time. Database retained original conditions until client accepted.
- Client saw old/new conditions and accepted. Booking became CONFIRMED with the agreed price/address/time on both phones. This acceptance confirms the owner's proposed deal; a redundant owner confirmation is not required.
- Owner started work, sent a new QA photograph, marked work performed. Client received the image, opened the full-screen viewer, and confirmed completion. Booking became COMPLETED/workStatus completed and chat CLOSED. History/image remained accessible and review action remained available.
- Test booking: 1b1573c6-c00d-47ec-8a52-b359bc94592b; chat cmvuom25h00005np4keck3cdz.

## Push limitation and fix

Local Firebase service credentials are intentionally dummy. Real FCM was tested by sending only the two local QA devices' queued payloads using the existing Firebase SDK inside the production container; production secrets stayed on that server and no production database records were changed. This verifies actual device FCM delivery/navigation, not normal local-worker authentication with production credentials.

Found initial-send failure could be logged without scheduling a retry. Backend notification.utils now queues non-invalid-token failures (including Firebase initialization failures) in NotificationDelivery for normal retry. Invalid tokens continue to be deactivated. Guarded local integration test verifies persistence, retry scheduling, and active token retention.

## User-requested visual refinements during QA

- Circular neutral attachment button, matching composer control sizing.
- Smaller text-message time lowered toward the bottom edge while staying inline.
- Photo time/receipt overlaid in a dark translucent capsule; no footer for photo-only messages.
- Photo report action remains in full-screen viewer; removed from message thumbnail.
- Removed redundant review heading; kept the review button.

## Bounded checks

Backend TypeScript: passed. Twenty focused notification/scope/photo-policy/booking-terms tests passed. Local push-retry integration test passed. Flutter analyzer for five changed widgets passed; four existing chat layout/model tests passed (including text scales 1x/2x).

## Limits

This is a local two-device critical-path check, not an exhaustive test of all legacy buttons, all languages, payment integration, store signing, production migrations or mixed old/new clients. Previous merged-code checks are recorded in the integration/release documents. No claim of complete production readiness follows from this run alone.

## Final installed visual build

Rebuilt profile APK after the requested visual adjustments (141 seconds); successfully installed on both phones. Visual inspection on S22 confirmed thumbnail timestamp overlay, no report control on thumbnail, a single review button, circular attachment control and inline lower time on short text. A fresh discussion could be started after the completed booking; its Hi message sent without creating another order, and closing that discussion archived it without a booking.

Original device stay-awake settings restored to 0 on both phones; server remains running. Changes are local and unpushed.

APK SHA-256: `76F72AEB42FB419AA2CDFDE705029EE7C04AD03A24C14237028E73CED1CE313A`.

## Follow-up polish and request audience — 2026-10-31

Fleet: one-line ellipsized name/model, plate below, no reserved two-line title gap; moderation/city on opposite sides. Catalog: one-line listing name with compact report control on the same line. Company reports now have an explicit COMPANY target with immutable snapshot and active responsible owner; they do not offer an unrelated user block. Additive migration 20261031001000_company_report_target applied locally (56 migrations), matching backend/web schema and regenerated clients.

Saved-address sheet sizes to content and scrolls when necessary; server orders addresses by creation descending. Chat attachment chooser offers gallery/camera using the existing image picker and the same preview/upload/compression path. Client/owner request comments share a bordered panel. Owner request category images use contain; status/lifetime moved underneath category.

Owner requests now have ALL/MINE feeds with independent pagination across both catalog groups. Exact saved-fleet category matching excludes archived entries, does not require visibility/moderation/ONLINE. New-request notification fanout and bottom pendingRequests use matching categories; allPendingRequests is separate. Existing blocked/self/hidden/expiry/answered rules retained. Legacy requests without categoryScope retain ALL semantics.

Validation: 27 Flutter request/safety tests pass; whole-project analyzer found only one style hint, fixed and the affected service reanalyzed cleanly. Five backend audience/report/count tests pass; backend and web TypeScript checks pass. Actual local HTTP request creation while QA owner OFFLINE produced one matching-category notification and zero for the other category. FCM delivered matching request to A12 in background; Android notification text was observed and tapped. Both test requests remain as clearly labelled local QA examples (3c978740-f74a-4625-a6f3-f41abdb5281f / 4dec2481-ed66-4ac9-bfa9-8de5d2a8542c).

Local administration verified: dedicated QA login issued a valid admin session and /admin returned 200. Use 127.0.0.1:3000/login to avoid the observed localhost connection timeout. Credentials supplied to the user separately; no production admin password changed. All changes remain local and unpushed.

Final APK installed successfully on both phones after follow-up. On A12, All requests showed 3 pending; My categories showed 1 and only the matching CMU request; bottom radar badge showed +1. Visually inspected the complete request card (uncropped category image, stacked state/lifetime, bordered comment) and the owner's actual fleet cards (name/model/plate aligned beside thumbnail, status opposite city). Camera/address final on-device inspection awaited S22 unlock at this checkpoint.

Remaining visual checks completed on A12 in client mode: one saved address sheet wraps to content; catalog name is one line with ellipsis and the report glyph stays on its row. Chat attachment menu shows Gallery/Camera; granted camera permission and observed Samsung camera capture UI, then cancelled without taking/sending a photo. The temporary discussion was closed without a booking. Gallery sending/compression/storage was already verified earlier. Added request/count refresh after fleet mutations to keep a newly added category effective immediately; affected notifier analyzer clean.

Final fleet-cache APK SHA-256: `A1588357AF82EAE4CCCAA55FCD709C196001095898E050C021C1132622123D13`; installed successfully on both devices. A12 returned to owner mode/My categories after checks. Server remains running.

## Final consistency polish and clean accounts — 2026-10-31

Profile accent CTAs now share height, spacing, typography and truck proportions; the find-equipment variant retains its search badge. Listing tariff/rental-condition headings include colons. Catalog flow cards show rental conditions (owner description fallback), not the specification chips. Chat empty/closed copy uses chats instead of correspondence. Inquiry header uses an X close action and Discussion / Confirm terms; initial inquiry terms allow a custom positive price without altering the listing tariff.

History booking cards have a separate compact localized Chat action using the existing role/chat route. The price/action layout adapts to narrow screens and enlarged text. Standard empty-state cards share typography, minimum content height and refresh control; client requests reuse the same component.

Unsent equipment inquiries are excluded from both active chat lists by the backend until a TEXT/IMAGE/LOCATION exists (or a booking/request is linked). Mobile immediate cache upserts follow the same rule. The inquiry record itself is retained/reused, avoiding duplicate threads and preserving normal retention. Existing support/order/request conversations are unaffected.

Validation: 50 focused Flutter widget tests passed; three additional custom initial-price tests passed in RU/KK/EN, including narrow layout and enlarged text. Full flutter analyze: no issues. Backend empty-inquiry local integration plus three navigation-count tests passed. Backend/web TypeScript checks passed. Final profile APK installed successfully on S22 and A12; SHA-256 63A548E654B847F51B1D02A94146E524789878E69F6798683CA42C8699C9BA39. Final on-device visual pass was limited because S22 was on its system lock screen; no further guarded taps were sent.

Admin login form now has a server-action POST fallback before hydration, avoiding native GET submission of credentials. Actual Chrome sign-in and navigation to the pending-equipment moderation list succeeded on http://localhost:3000. Screenshot: artifacts/two-phone-20261030/admin-moderation-final.png. Prefer localhost for the current browser session; the older 127.0.0.1 tab showed a connection error. No production admin credential was changed.

Local cleanup ran only after checking database prokat.environment=local and LOCAL_REPLICA_ENABLED=true. Removed four known QA identities via existing account purge/anonymization policy; their active requests/bookings were cancelled and old equipment archived. Retained business history follows the standard policy. Removed the accidental invalid-hyphen QA admin; kept qa_local_admin. Other mirrored users were untouched.

Created clean local accounts: client +77000000201 (qa_client_20261031), owner +77000000202 (qa_owner_20261031). Local fake OTP 000000. Both active, zero equipment and requests, owner approved/OFFLINE with 600 test minutes. User will sign in and add equipment. Credentials for local QA admin supplied separately. Server remains running; nothing pushed or deployed.

## Review follow-up: order tabs, public labels and system notifications — 2026-10-31

Replaced order-history toolbar actions with the same Active/Archived AppTabs used by chats, for both roles. Existing active/history providers, booking status rules and history Chat actions remain in place. Owner empty-orders refresh uses the shared text-only control. Listing rental text is headed Description; key-spec boxes removed, all visible specs remain in the expansion.

Public owner labels now use first name only. Public owner/equipment DTOs return an empty lastName; registration, moderation and private profile data still retain it. Owner profile header uses its teal gradient rather than client blue.

Unsent equipment inquiry completion is disabled in the UI and rejected by the API without creating an archive event. First text/photo/location enables completion; proposed order terms keep the ordinary booking path. A dedicated client listing-chat route outside StatefulShellRoute preserves the underlying listing when opening a discussion: plain push into the existing shell was found to show a chat header above catalog content and was replaced before handoff.

Offer equipment selection has a reusable thumbnail/name/model/plate picker with same-size rows, ellipsis and repeated selection. Offer rejection is an X beside Accept. Tender chat has a pinned offer context opening existing acceptance/counter-offer actions; offer messages use the common OfferFlowCard. This does not convert tenders into direct equipment inquiries or bypass tender acceptance.

Foreground notifications: socket continues updating data/counters but does not draw a custom banner. Received FCM publishes to the Android/iOS system notification API, deduped by notification id; retry payload id is normalized too. Sound/vibration enabled on the high-importance Android channel, default vibration in Android FCM config and default sound in APNs payload. OS permission, DND and user channel choices remain authoritative.

Verification: full Flutter analyzer clean before final navigation adjustment; 36 targeted regression tests passed (the picker compile fixture was corrected), plus six final picker/offer/system-notification tests passed. Backend TypeScript clean; local empty-inquiry integration confirms no close/event/archive before first message. Both phones received actual FCM QA Firebase notifications with PROKAT in foreground; Android notification records remained in the tray, importance=5, channel sound points to system notification sound and vibrationEnabled=true. Used the existing restricted QA relay (two new local QA recipients only); no Firebase credentials exported and no production database mutation. Local backend deliberately has placeholder Firebase credentials, so automatic local delivery still needs the QA relay; production uses its configured credentials. Devices visually confirmed order tabs/owner archive Chat action, description/spec expansion and teal owner header. Final listing-chat navigation proof recorded below after rebuilt installation.

Final installed build (SHA-256 4F653C835E82B0219506B1EA8D0FFC5F213D162ABDD7374941A80BCA51791F79) installed successfully on S22 and A12. Whole-project analyzer after the standalone route passed; subsequent scoped request-message/InfoTile color analysis passed. On S22, listing-chat renders the real empty discussion, completion button reports enabled=false/clickable=false, and Android Back restores the same open listing with Description and expandable specs. Screenshot final-inquiry-proof.png and XML final-back-listing-proof.xml. No message, offer acceptance or booking mutation was performed for that navigation proof.

Offer chat visually verified on S22: pinned discussion/confirm-terms context, common offer card, Accept + X actions, composer. Fixed legacy request-message white price/icons in FlowScope; legacy non-flow presentation unchanged. New picker reopening/change and system notification sound/vibration unit checks passed.

Temporary local QA FCM relay started for 60 minutes, process 18408, scheduled end 2026-10-31 16:36 Asia/Yekaterinburg. Scope is exactly qa_client_20261031 and qa_owner_20261031, guarded local DB; Firebase sending reuses the existing safe remote SDK helper without exporting credentials or touching the production database. State file artifacts/two-phone-20261030/local-qa-fcm-relay-state.json; helper run-local-qa-fcm.ps1. This is a test-only process, not a committed service or production dependency. Stop it before ending the local test session if needed. Existing user-created QA fleet/requests were preserved. All source changes remain local and unpushed.
