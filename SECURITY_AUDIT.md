# Prokat — security audit (client-focused)

**Scope:** Flutter app (`lib/`), Android/iOS config, repo hygiene.  
**Out of scope:** Full backend / Render / DB review (not in this repo).  
**Method:** Static review (grep + manifest/config reads).  
**Date:** 2026-05-19  

---

## Executive summary

| Severity | Count | Themes |
|----------|-------|--------|
| Critical | 1 | Secret / token material in repo + not gitignored |
| High | 4 | Token duplication; auth/session edge cases; Android release permission gap risk |
| Medium | 6 | Transport for dev builds; logging; deep links; `url_launcher`; iOS privacy strings |
| Low | 5 | Placeholder URLs; dependency hygiene; release signing |

**Top actions before wider distribution or public repo:**

1. Remove **`.env` from version control** (or ensure it contains no secrets) and add **`.env` to `.gitignore`**; rotate any token that was ever committed.  
2. **Stop duplicating Mapbox public token** in Dart + `AndroidManifest.xml` + `.env`; load from **build-time defines** or CI-injected manifest placeholders.  
3. Confirm **Android `INTERNET`** permission is present in **release** merged manifest (see finding H-4).  
4. Tighten **401** handling so cleared sessions cannot keep using the UI with stale auth state.  
5. Add **iOS usage descriptions** for camera/photos/location if not present elsewhere (plist extension / build phases).

---

## Critical

### C-1 — `.env` tracked; Mapbox token in repo

**Finding:** Repository contains **`.env`** with `MAPBOX_TOKEN`. **`.gitignore` does not list `.env`**, so credentials/config are at risk of being committed, forked, and scraped.

**Impact:** Public tokens can be abused (quota burn, Mapbox billing). If other secrets are added to `.env`, impact is worse.

**Remediation:**

- Add `.env` to `.gitignore`; use **`.env.example`** with empty placeholders.  
- If `.env` was ever pushed: **assume compromise**, rotate Mapbox token, audit `git log -- .env`.  
- Prefer **`--dart-define=MAPBOX_TOKEN=...`** or flavor-specific config for CI/local only.

---

## High

### H-1 — Mapbox public token hardcoded in multiple places

**Finding:** Same **Mapbox public token (`pk....`)** appears in at least:

- `lib/setup_mapbox.dart` (`MapboxOptions.setAccessToken(...)`)  
- `android/app/src/main/AndroidManifest.xml` (`com.mapbox.token` meta-data)  
- `.env` (see C-1)

**Impact:** Token is easy to extract from APK/IPA or repo; abuse of free tier / attribution to your Mapbox account.

**Remediation:** Single source of truth at build time; URL restrictions + rotation in Mapbox dashboard; never commit production tokens to public repos.

---

### H-2 — Bearer token attached without null-guard

**Finding:** `ApiInterceptor` sets `Authorization: Bearer $token` when `session != null` but does not verify `sessionToken` is non-null/non-empty.

**Impact:** Possible `Bearer null` or `Bearer ` if session object exists with empty token — odd server behavior, logs, or weak auth edge cases.

**Remediation:** Only set header if `(session.sessionToken?.isNotEmpty ?? false)`.

---

### H-3 — 401 clears storage but app state may stay “logged in”

**Finding:** On `401`, interceptor **clears secure storage** but does not broadcast logout / force `GoRouter` redirect. In-memory Riverpod auth state can desync until restart or next refresh.

**Impact:** User may think they are logged in; subsequent calls fail; rare cross-account confusion if session replaced incorrectly.

**Remediation:** Emit global event or invalidate `authProvider` + `appStartupProvider` and navigate to login (coordinate with refresh notifier).

---

### H-4 — Android `INTERNET` permission may be missing for **release**

**Finding:** `android/app/src/main/AndroidManifest.xml` has **no** `<uses-permission android:name="android.permission.INTERNET"/>`. It appears under **`debug`** and **`profile`** manifests only.

**Impact:** Depending on Gradle manifest merge for **release**, the store build could **lack network permission** (broken app) or merge might still pull permission from a dependency (unreliable). This must be verified on a **release** APK manifest dump.

**Remediation:** Add `INTERNET` to **`src/main/AndroidManifest.xml`** explicitly (Flutter template default).

---

## Medium

### M-1 — Cleartext HTTP for local dev in `Env`

**Finding:** `lib/core/config/env.dart` uses `http://localhost:4000` and `http://10.0.2.2:4000` for non-release local paths.

**Impact:** Fine for emulator loopback; **never** use cleartext for production. Current production path uses `https://prokatbackend.onrender.com` in release — good.

**Remediation:** Document “local only”; optional Android `networkSecurityConfig` cleartext exception scoped to `debug` only.

---

### M-2 — WebSocket auth mirrors REST token

**Finding:** `ChatSocketService` connects to `baseUrl` with `setAuth({'token': resolvedToken})`.

**Impact:** If token leaks via logs or MITM on compromised device, chat is impersonated. Same trust model as REST — acceptable if TLS is enforced server-side and token is short-lived.

**Remediation:** Backend should validate token on connect; rotate on logout; consider shorter-lived WS credentials if threat model requires.

---

### M-3 — Sensitive data in `FlutterSecureStorage` as JSON

**Finding:** Full `AuthSession` (token, user, expires) stored as **JSON string** under one key.

**Impact:** Standard pattern; ensure backend never returns unnecessary PII in session payload that persists on device.

**Remediation:** Minimize user object in session JSON; encrypt-at-rest is OS-provided via Keychain/Keystore.

---

### M-4 — `debugPrint` may leak operational info

**Finding:** e.g. `map_pin_location_screen.dart` logs `Equipment ID`; geocoding failures; avatar errors.

**Impact:** Low in release (stripped); higher in debug builds shared with testers.

**Remediation:** Gate verbose logs behind `kDebugMode` or a `verboseLogging` flag; never log tokens.

---

### M-5 — `url_launcher` usage

**Finding:** `show_location_sheet.dart` / `support_us_screen.dart` open fixed or constructed URLs; `launchUrl` uses `LaunchMode.externalApplication` in some paths.

**Impact:** If any URL were ever built from **untrusted user input** without validation, risk of open redirect / malicious app handoff. Current lat/lon in `dgis://` scheme is structured — keep validation (finite doubles, sane range).

**Remediation:** Prefer `LaunchMode.externalApplication`; validate all dynamic URIs; for `mailto:` ensure no header injection via newlines in user input (if user-controlled).

---

### M-6 — iOS `Info.plist` (snippet) lacks privacy usage keys

**Finding:** Grep over `ios/` found **no** `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSLocationWhenInUseUsageDescription`, etc., in the checked `Info.plist` (app uses `image_picker`, `geolocator`, maps).

**Impact:** **Runtime denial** or **App Store rejection** if keys are missing when APIs are used; not “network security” but **release blocker**.

**Remediation:** Add all required usage strings (and Mapbox’s documented keys if applicable) per Apple guidelines.

---

## Low

### L-1 — Release signing uses debug keys

**Finding:** `android/app/build.gradle.kts` release `signingConfig = signingConfigs.getByName("debug")`.

**Impact:** Not a confidentiality bug; unacceptable for Play production; debug keys are widely known.

**Remediation:** Use release keystore before store submission.

---

### L-2 — Default Android `applicationId` / namespace

**Finding:** `com.example.prokat`.

**Impact:** Naming collision, impersonation confusion; not a direct exploit.

**Remediation:** Unique reverse-DNS id before production.

---

### L-3 — Placeholder / generic external links

**Finding:** `support_us_screen.dart` includes `https://yourapp.com`, `mailto:feedback@yourapp.com`, `https://apple.com`.

**Impact:** Phishing perception if shipped; no direct RCE.

**Remediation:** Replace with real domains or remove until ready.

---

### L-4 — Dio `LogInterceptor` commented out

**Finding:** `api_client.dart` has logging disabled.

**Impact:** Good for accidental token logging in production; if re-enabled, redact `Authorization`.

---

### L-5 — Dependency vulnerabilities

**Finding:** No `dart pub audit` run in this audit.

**Remediation:** Run `dart pub outdated` / GitHub Dependabot or `pub audit` regularly in CI.

---

## Backend / operations (checklist — not verified in repo)

- [ ] **HTTPS only** in production; HSTS; no mixed content.  
- [ ] **Rate limit** `/auth/otp`, login, file upload, chat.  
- [ ] **JWT/session** expiry, refresh rotation, revoke on password change.  
- [ ] **Upload** content-type + size limits; virus scan if user-generated binaries.  
- [ ] **CORS** locked to app origins if browser client exists.  
- [ ] **Secrets** in Render/env, not in client.  
- [ ] **Privacy policy** for PII (phone, location, chat).

---

## Suggested backlog IDs (link to `BACKLOG.md`)

Add security-specific items:

| ID | Title |
|----|--------|
| SEC-01 | Gitignore `.env`, remove from repo history if leaked, rotate Mapbox token |
| SEC-02 | Single-source Mapbox token (dart-define / manifest placeholder) |
| SEC-03 | Guard `Authorization` header when token empty |
| SEC-04 | Global logout on 401 + router reset |
| SEC-05 | Add `INTERNET` to `src/main/AndroidManifest.xml`; verify release merged manifest |
| SEC-06 | iOS privacy usage strings for camera/photos/location/map |
| SEC-07 | CI: `dart pub audit` (or equivalent) on PR |

---

## Sign-off

This audit is **point-in-time** and **not** a penetration test. For production or funding due diligence, engage a third party for **mobile appsec + API + infrastructure** assessment.
