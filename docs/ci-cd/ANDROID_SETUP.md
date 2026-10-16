# U2 — Android readiness and exact account inputs

Updated 2026-10-16. Independent code preparation is complete; actual Play
authentication, upload-key match and signed AAB remain NOT VERIFIED.
No CI build, API probe, upload or publication is authorized by this document.

## Initial least privilege

In Play Console → **Users and permissions → Invite new user**, use a dedicated
service-account email. **App permissions → Add app → PROKAT** only; package must
be `com.auyltech.prokat`. Grant exactly these initial app permissions:

- **View app information (read-only)**.
- **Release apps to testing tracks**.

Do not grant account-wide permissions, Admin, Finance, Manage orders, Manage
store presence or Release to production. The testing-release permission already
covers notes for non-production releases. This pipeline does not change listing
text/images/pricing/tester lists. The owner configures the Internal tester group
once in the console, so CI does not need **Manage testing tracks and edit tester
lists**. If the API returns 403, diagnose the exact request before widening rights.

Google does **not** expose an Internal-only permission: testing-release rights
cover Internal/Open/Closed. The service account cannot publish production without
the separate production permission. RC's destination is additionally fixed to
`internal` by the tag parser and Play policy; no caller-selected track parameter.
Residual risk: a credential holder could use another client to modify other
testing tracks. Do not describe this as an IAM-level Internal-only restriction.

Source: [Google permission definitions](https://support.google.com/googleplay/android-developer/answer/9844686?hl=en).

## Existing upload-key verification (no private-key export)

1. Play Console → PROKAT → **Protected with Play → Play Store distribution →
   Go to Play app signing** (older UI: Test and release → App integrity → App
   signing). Download the PUBLIC
   certificate from **Upload key certificate**, not App signing key certificate.
   The latter signs installed Play APKs and is used for App Links, not CI upload.
2. Keep the existing keystore and its backup. Do not reset/rotate/recreate it.
   From a Windows terminal in this repository run:

   ```powershell
   python tool/release/verify_upload_key.py --keystore .\android\app\upload-keystore.jks --alias 'EXISTING_ALIAS' --play-certificate 'C:\secure\upload_cert.der'
   ```

   Enter the existing store password only at the hidden prompt. Do not put it
   in the command, shell history, a screenshot or chat. The script uses an
   ephemeral child environment for keytool authentication, captures its output,
   exports only the public certificate into a temporary directory, and verifies
   that the alias is a PrivateKeyEntry. It compares full public DER certificate
   bytes and outputs only the public SHA256 on success. PEM certificates also work.
3. If the downloaded file is unavailable, the script also accepts
   `--expected-sha256 'PUBLIC_UPLOAD_SHA256'`, copied from the same Play section.
   Prefer the downloaded public certificate to avoid transcription mistakes.
4. Mismatch/wrong alias/password → BLOCKED; do not change any key or try a
   replacement upload. Report the non-secret error classification. This check
   does not verify the private key's separate keyPassword or app signing
   fingerprint; actual signing is verified on the authorized RC.
5. Set the resulting fingerprint as the GitHub Variable below. CI independently
   checks the restored keystore **before** building and the signed AAB afterwards.

## Exact GitHub configuration

Use [PROKAT → Settings → Secrets and variables → Actions](https://github.com/auyltech/prokat/settings/secrets/actions).
Repository-level Secrets/Variables suffice; no paid environment approval feature
is assumed. There are **7 required secrets and 2 required variables for RC**:

| Type | Exact name | Source / validation | Temporary local copy |
| --- | --- | --- | --- |
| Secret | `ANDROID_KEYSTORE_BASE64` | Base64 of the existing keystore verified above | Keep the original and protected backup; remove only an extra staging copy |
| Secret | `ANDROID_KEYSTORE_PASSWORD` | Existing store password | Password manager; no plaintext file/history |
| Secret | `ANDROID_KEY_ALIAS` | Verified PrivateKeyEntry alias | Not a private key; retain with signing record |
| Secret | `ANDROID_KEY_PASSWORD` | Existing key password (may equal store password) | Password manager; no change/reset |
| Secret | `PLAY_SERVICE_ACCOUNT_JSON_BASE64` | JSON key of dedicated app-scoped `prokat-play-ci` | Keep until the access probe; then delete staging copy after secure backup |
| Secret | `GOOGLE_SERVICES_JSON_BASE64` | Firebase prokat-bfbec → Android com.auyltech.prokat → google-services.json | Download copy can be deleted after setup |
| Secret | `MAPBOX_PUBLIC_TOKEN` | Existing public runtime `pk.*` token | No private `sk.*` download token; delete staging text |
| Variable | `ANDROID_UPLOAD_CERT_SHA256` | Public Upload certificate fingerprint verified above | Public value; 64 hex, optional colons |
| Variable | `PLAY_HISTORICAL_MAX_BUILD` | Highest ever-used Play versionCode, including drafts/testing/inactive, 0 only for confirmed empty history | Record the confirmed integer; never guess from pubspec |

`PRODUCTION_PUBLISHING_ENABLED` is an **optional future Secret**: absent/false
until A5 success and explicit U5. Do not set true or grant production permission.
No other Android signing/API input is needed. Package, endpoint/features, Flutter,
JDK, Gradle/AGP and Supply versions are already in Git.

Base64 file → clipboard, without terminal output:

```powershell
Set-Clipboard -Value ([Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path 'C:\secure\play-ci.json'))))
# Paste directly into the corresponding GitHub Secret, then clear the clipboard:
Set-Clipboard -Value ''
```

Repeat with the existing keystore and Firebase JSON for their matching secrets.
Base64 is not encryption. Never send these values to the agent/chat.

## Cloud/API and store readiness

1. Reuse a Cloud project, or create an ordinary no-billing project. Enable
   [Google Play Android Developer API](https://console.cloud.google.com/apis/library/androidpublisher.googleapis.com).
   Linking the Play developer account to the Cloud project is no longer required.
2. **IAM & Admin → Service Accounts → Create service account** (`prokat-play-ci`).
   Leave project Owner/Editor roles empty. Create JSON key under **Keys → Add key**
   only if organization policy allows it; do not weaken a policy to obtain one.
3. Invite that service-account email to the selected Play app with the two
   permissions above. Do not follow Billing API examples granting financial rights:
   this pipeline uses the Publishing API, not purchase/subscription management.
4. Confirm actual production version, highest historical versionCode, package,
   primary locale (`ru-RU`, `en-US` or `kk`) and Internal tester group/opt-in link.
   Configure tester emails/Google group as the owner. Do not roll out a release.
5. Check onboarding/agreements/policy declarations and existing track state. If
   the first app upload must be performed through the UI, report it; it still
   requires explicit U4 permission. Do not create/upload an initial binary at U2.
6. Read Managed publishing state and report it; do not change production settings.
   Review/managed-publishing state can delay actual availability even after commit.

## Non-publishing API probe (after U2 account setup)

The prepared `play_access.rb` does not require a tag, signing key, AAB or CI run.
It reads bundles/APKs/tracks/app details through a **temporary edit**, then deletes
that edit. It never uploads, updates a track, validates or commits an edit. Thus
it is not a strictly read-only HTTP operation; use the dedicated service account
with no concurrent console edits. Unknown API/abort state fails closed.

After setup, the owner may give the agent only the local path of the temporary
JSON (not its contents) for this specific diagnostic, or run the command locally.
With Ruby 3.3 and the locked dependencies installed:

```powershell
$env:BUNDLE_GEMFILE = "$PWD\tool\release\Gemfile"
bundle exec ruby tool/release/play_access.rb --credentials 'C:\secure\play-ci.json'
```

On this Windows machine the agent also has the previously validated local Linux
Ruby container/cache and can prepare the same command with the JSON mounted
read-only; no credential installation in an image is needed. No probe has been
executed against Play yet. Success proves app read access and temporary-edit
cleanup, **not** upload rights or readiness for production. Those require U4/A5.
The snapshot is not a full historical ledger: compare with the owner-confirmed
history floor and do not infer that an old versionCode is reusable.

Sources: [Publishing API setup](https://developers.google.com/android-publisher/getting_started),
[current Play signing navigation](https://support.google.com/googleplay/android-developer/answer/9842756?hl=EN-GB).

## Return to the agent

Report package, current version, confirmed maximum, primary locale, public
fingerprint MATCH/MISMATCH, tester-group readiness, Managed publishing state,
granted permission names and created Secret/Variable names. Do not send values
of secrets. U1 billing/privacy/Personal eligibility can remain pending while
preparing accounts, but must be resolved before any actual CI build permission.
