# Prokat — engineering & product backlog

Consolidated from codebase review, routing/API audit, user-test readiness notes, and monetization/CJM discussion.  
Priorities: **P0** = ship blocker for credible tests, **P1** = high value / trust / support load, **P2** = quality & maintainability, **P3** = nice-to-have / cleanup.

---

## ✅ Completed

| Date | Area | Work done |
|------|------|-----------|
| 2026-05-20 | i18n | **Full app translation EN/RU/KK** — all user-visible strings replaced with `AppLocalizations` keys across every screen and widget. 33 new ARB keys added. `flutter analyze` clean. |
| 2026-05-20 | Bug fix | **`create_booking_screen.dart`**: `_buildCenteredFallback` returned `SliverFillRemaining` inside a `ListView` (runtime crash) — replaced with `SizedBox`. |
| 2026-05-20 | Bug fix | **`client_bookings_section.dart`**: removed empty dead block `if (completed.isNotEmpty) {}`. |
| 2026-05-20 | Bug fix | **`equipment_city_selector.dart`**: deprecated `desiredAccuracy` param replaced with `LocationSettings(accuracy: ...)`. |
| 2026-05-20 | Analyze | **`flutter analyze`** passes with 0 issues. |
| 2026-05-20 | P0-01 | **`/categories` route** added to `GoRouter` → `CategoriesScreen`. |
| 2026-05-20 | P0-02 | **Verified fixed** — `selectAddress` already patches `ApiRoutes.userAddress` correctly. |
| 2026-05-20 | P0-03 | **Verified fixed** — `updateEquipment` already sends `categoryId` (no typo in current code). |

---

## P0 — Correctness & ship blockers

✅ All P0 items resolved.

---

## P1 — User tests, UX clarity, reliability

| ID | Area | Finding | Suggested work |
|----|------|-----------|----------------|
| P1-01 | UX | **Cold start / backend hosting**: currently local testing only. When production server is provisioned, address cold start UX (Render sleep or equivalent). | User-visible “server starting” banner + **Retry**; upgrade to always-on tier before real user tests. **Deferred — waiting on server.** |
| P1-02 | UX | **Sidebar “Search”** → `searchMap`; **bottom nav “Search”** → `searchList` — same label, different destinations. | Rename (“Map” / “List”) or unify default + secondary entry. |
| P1-03 | Product | **Counter-offer** (`CounterOfferSheet`): button only pops sheet; **TODO: no API**. | Wire to backend contract or **hide / “Coming soon”** until implemented. |
| P1-04 | Onboarding | Guest vs logged-in value prop not spelled out in-product. | Short copy: browse as guest → sign in to book / chat / favorites (single screen or tooltip). |
| P1-05 | CJM / Testing | Three mental models: **guest browse**, **book specific equipment**, **post request / offers** — easy to mis-report as bugs. | **One-pager tester script** with paths A/B + owner path; include sidebar vs bottom search note. |
| P1-06 | Monetization copy | **Minutes + KZT** wallet concept can confuse (“what do minutes buy?”). | Single-sentence value prop + FAQ (metering, pause, timezone); if payments still mock, label **Beta / simulated billing**. |
| P1-07 | Owner payments | **`OwnerPaymentsScreen` / top-up`**: mock balances, packages, history — not real API in reviewed flow. | Either integrate real billing API or add clear **“Demo data”** banner to avoid false trust during tests. |
| P1-08 | Observability | No crash/session reporting called out in review. | Add **Crashlytics** or **Sentry** + build/version on support/about for tester reports. |
| P1-09 | Backend | Inconsistent error payloads / silent failures make support hard. | Standardize `{ data, message, errors }` + HTTP codes; document for app `extractBackendMessage` alignment. |
| P1-10 | Backend | Abuse risk on OTP, chat, uploads during open tests. | Rate limits + basic upload size/type validation server-side. |
| P1-11 | Backend / Media | Large origin images → bandwidth + slow lists (client mitigated with `OptimizedNetworkImage`). | **Thumbnails** (e.g. 400–600px list, ~1280 detail) + store originals server-side. |

---

## P1 — Security & session

| ID | Area | Finding | Suggested work |
|----|------|-----------|----------------|
| P1-12 | Secrets | **Mapbox access token** hardcoded in `lib/setup_mapbox.dart`. | Move to `--dart-define` / flavors / CI secrets; rotate if repo was or will be public. |
| P1-13 | Secrets | **`.env`** present in repo tree — ensure no secrets committed; prefer `.env.example` + docs. | Audit git history; gitignore secrets; document env vars. |
| P1-14 | Auth UX | **401** in `ApiInterceptor` clears storage but does not centrally route to login — risk of stale UI. | Global auth listener / `GoRouter` refresh forcing login when session cleared. |

---

## P2 — Architecture & maintainability

| ID | Area | Finding | Suggested work |
|----|------|-----------|----------------|
| P2-01 | API layer | **`BaseRepository`** exists; most services duplicate try/catch + `extractBackendMessage`. | Gradually unify error handling / typed results. |
| P2-02 | Router | **`ownerEquiment` typo** in `AppRoutes` (propagates). | Rename with deprecation shim if deep links exist. |
| P2-03 | Router | **`/equipment/:id`** and **`/equipment/:id/book`** both build **`CreateBookingScreen`** — redundant. | Consolidate or document intentional shortcut. |
| P2-04 | Router | **`/orders/:id`** uses **`bookingId` query param** instead of path param — surprising for API-like URLs. | Align path param with `bookingId` or document in router + tests. |
| P2-05 | Startup | **`AppStartupController`**: commented TODO on **duplicate init** / microtask. | Verify single init path; remove dead code; avoid double category/profile fetch. |
| P2-06 | Dependencies | **`hive` / `hive_flutter`** in `pubspec` but **unused** in `lib/`. | Remove or implement offline cache (categories, last search). |
| P2-07 | Dead code | **`owner_booking_card.dart`**, **`user_equipment_tile.dart`**: comments **TODO DELETE**. `owner_booking_card.dart` translated but still in codebase. | Delete if unused; grep references first. |
| P2-08 | Stub | **`MapLocationService`**: only `fakeLat` / `fakeLng` — placeholder. | Implement real helper or delete to prevent misuse. |
| P2-09 | Chat | **`chat_navigation.dart`**: TODO remove. | Inline or delete obsolete helper. |
| P2-10 | Routes | **`AppRoutes.ownerEquimentMap`**: “Screen not implemented” TODO. | Implement or remove from docs/nav. |
| P2-11 | Client refactor | **`AppRoutes.clientMain`**: TODO move client pages under `/client`. | Optional URL migration + redirects (breaking change — plan). |

---

## P2 — Booking / offers / requests (product completeness)

| ID | Area | Finding | Suggested work |
|----|------|-----------|----------------|
| P2-12 | Offers | **`OffersService`** + notifiers exist — ensure **all owner/client surfaces** for offers match backend and are reachable in CJM. | QA matrix: create offer → update → accept; map screens. |
| P2-13 | Bookings | **`createBooking`** returns success without parsing returned entity if API sends one. | Parse `data` if needed for immediate UI (confirmation id, etc.). |

---

## P3 — Quality, docs, polish

| ID | Area | Finding | Suggested work |
|----|------|-----------|----------------|
| P3-01 | Tests | Only default **`test/widget_test.dart`** — minimal safety net. | Add smoke tests for auth redirect + one booking/equipment flow; optional integration. |
| P3-02 | README | Default Flutter **README** — no runbook. | Document: Flutter version, `Env` / `runMode`, backend URL, Mapbox setup, Android/iOS notes, `flutter analyze` / `format`. |
| P3-03 | Naming | **`heatlth_check_screen.dart`** typo. | Rename file + imports to `health_check_screen`. |
| P3-04 | Copy | **`AuthApiService.loginWithCredentials`** success path message says **“Account created successfully”** (wrong for login). | Fix user-facing strings per action. |
| P3-05 | Images (from `report.md`) | **Mandatory 4:3 crop** on equipment photos — product risk for gallery vs cover-only. | Decide policy; document; adjust `ImageCropper` scope if needed. |
| P3-06 | Images | Shimmer / blur on high-DPR devices — verify after `OptimizedNetworkImage` rollout. | Visual QA checklist (light/dark). |
| P3-07 | CI / local | `report.md`: **`dart format` / `flutter analyze`** — `flutter analyze` now clean ✅; `dart format` pass still pending. | Add pre-merge checklist or CI job. |

---

## P3 — External / business (tracking only)

| ID | Area | Finding | Suggested work |
|----|------|-----------|----------------|
| P3-08 | Compliance | **Google DUNS** ~2 weeks — may affect certain **org / merchant** flows, not typical **closed** TestFlight / Play internal testing. | Run closed user tests on tracks that don’t require DUNS; align public listing / billing with DUNS arrival. |
| P3-09 | Tooling | **Cursor Hobby (Free)** limits **IDE AI** (Agent + Tab completions), not app users. | For heavy agent sprint, monitor Cursor usage dashboard; optional short **Pro** window — unrelated to Prokat hosting free tier. |

---

## Appendix — reference locations (quick grep anchors)

| Topic | Location hints |
|-------|------------------|
| Router / guards | `lib/core/router/app_router.dart`, `app_routes.dart` |
| Startup / roles | `lib/features/appstartup/app_startup_provider.dart` |
| Env / API base | `lib/core/config/env.dart`, `lib/core/api/api_client.dart` |
| Interceptor / 401 | `lib/core/api/api_interceptor.dart` |
| Profile bug | `lib/features/user/state/user_profile_service.dart` (`selectAddress`) |
| Equipment typo | `lib/features/equipment/state/equipment_service.dart` (`updateEquipment`) |
| Categories route | `lib/features/categories/screens/categories_screen.dart` + router |
| Sidebar | `lib/features/navigation/sidebar/sidebar_drawer.dart` |
| Counter-offer | `lib/features/bookings/widgets/counter_offer_sheet.dart` |
| Mapbox token | `lib/setup_mapbox.dart` |
| Owner payments UI | `lib/features/user/screens/owner_payments_screen.dart`, `owner_payments_topup_screen.dart` |
| Image performance report | `report.md` (repo root) |

---

## Suggested first sprint (user-test oriented)

1. P0-01, P0-02, P0-03  
2. P1-01, P1-02, P1-03 (or hide), P1-04, P1-05  
3. P1-08 + P1-06/P1-07 as appropriate for honesty with testers  
4. P1-12 (token) before any public repo widen  

_Then_ pick P1-09–P1-11 and P2 items by capacity.

---

## Security backlog (from `SECURITY_AUDIT.md`)

| ID | Priority | Title |
|----|----------|--------|
| SEC-01 | P0 | Gitignore `.env`, purge from git history if ever pushed, rotate Mapbox token |
| SEC-02 | P0 | Single source for Mapbox token (no triple copy in Dart / manifest / `.env`) |
| SEC-03 | P1 | Only set `Authorization: Bearer` when `sessionToken` is non-empty |
| SEC-04 | P1 | On HTTP 401: invalidate auth state + navigate to login (avoid desync) |
| SEC-05 | P1 | Add `INTERNET` to `android/app/src/main/AndroidManifest.xml`; verify release APK manifest |
| SEC-06 | P1 | Add iOS usage descriptions (camera, photo library, location, map SDK as required) |
| SEC-07 | P2 | CI: dependency / supply-chain audit (`dart pub audit` or Dependabot) |
| SEC-08 | P2 | Replace placeholder URLs/emails in `support_us_screen.dart` before production |
| SEC-09 | P2 | Release signing: move off `debug` signingConfig for Play store builds |

---

*Last updated: 2026-05-20 — all P0 items resolved; translation complete; `flutter analyze` clean. Local testing phase — backend server migration deferred.*
