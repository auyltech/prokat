# Company prototype: Flutter handoff

Branch: `admin-panel-dispatch`. No commit, push, APK build or phone installation.

## Implemented

- Company entry in client and owner profiles; authenticated `/companies` route.
- BIN (12 digits) + name application through `POST /companies/requests`.
- Real pending / approved / rejected request states and administrator comment from `GET /companies/me`; refresh and error handling.
- Personal user identity remains unchanged. Memberships provide separate company workspaces; employees accept invitations using their own authenticated account.
- Workspace with company name, BIN, short description and authenticated company photo. OWNER can edit name/description and upload logo. MANAGER can work with the fleet.
- Fleet grouped by API catalog groups and categories with total / shown / busy counts; localized category labels and existing category images.
- Add/edit hidden company drafts using company-specific API endpoints, current catalog, model, name, city and description. No reuse of private owner's equipment mutation endpoints.
- Russian, Kazakh and English strings; localization files regenerated.
- Requests with HTTP errors cannot silently become an empty fleet or successful save. User change invalidates cached context/fleet/photo via auth provider dependencies.

## Files

`lib/features/companies/`: company_models.dart, company_service.dart, company_widgets.dart, company_screen.dart, company_workspace_screen.dart, company_equipment_screen.dart.

Route additions: `lib/core/router/app_routes.dart`, `app_router.dart`. Entries: client_profile_screen.dart and owner_profile_screen.dart. Strings: `lib/l10n/app_{ru,kk,en}.arb` and generated localization Dart files.

## Verification

- `gen-l10n` completed.
- `dart format` completed for all changed Dart source files.
- `git diff --check` passed.
- Narrow Dart analysis finished with exit 0: no errors/warnings; four informational curly-brace style hints.
- No phone or server E2E verification in this turn. Backend migration and actual authorization responses must be tested before calling the flow ready.

## Deliberately unfinished

- Company public search cards and public fleet; equipment multi-selection and requests; company chat/order execution; common billing/minutes.
- Fleet publishing, moderation submission, equipment images/specs/tariffs. New company equipment remains hidden DRAFT because private booking and billing rules are not company-aware yet.
- Member invitation creation/revocation UI on mobile (invitation acceptance is implemented; administration is via web).
- Notification/deep-link handling for company request decisions; status currently refreshes on screen refresh.
- BIN checksum validation and company registry verification: input only checks 12 digits; approval stays manual.
- Fleet/company onboarding UX still requires on-device review. Saving errors are visible but server-specific error codes use generic localized messages except conflict/access errors.
- Equipment photo URLs are now authenticated company routes. Their current shared network-image widget needs to be replaced with authenticated loading (the company logo already uses authenticated Dio). Category images use the existing catalog media loader correctly.

Existing modified platform `generated_plugin_registrant` / `generated_plugins.cmake` files were not edited or reverted.
