# Release metadata

Create a draft on Windows: `dart tool/release/release.dart init --version 1.2.3`.
This does not select a commit or create a tag. Edit `ru.txt`, `en.txt`, `kk.txt`
as UTF-8 plain text, each 1–500 characters. After review set `ready: true` in
`release.json`. Commit metadata together with the intended release source.

Schema: `{"schema":1,"version":"1.2.3","ready":true}`. Prepare pubspec.yaml with
X.Y.Z+N in dev, commit the bump and notes, then review/squash dev → main.
The owner CLI reads pubspec at fresh origin/main and derives the tag; CI supplies
Flutter build-name/build-number from that tag and checks pubspec agreement.
The counter is common to both platforms, 1..9999. Same version/build across
platforms requires the same SHA. Retry iOS +20 after common +19 means the next
common release is +21. Store APIs, not Git alone, prove live availability.
Use [the four owner commands](../CICD-README.md); never re-upload accepted builds.
Current publishers do not implement RC-to-production promotion of the same build.

RC and production source commits must both be reachable from freshly fetched
`origin/main`. A valid tag name or cached ref alone cannot authorize a release.
`ready: true` approves the notes for parsing; it does not authorize a tag, CI run,
upload, PR merge or production publishing.

All three source translations are mandatory. Android maps ru→ru-RU,
en→en-US, kk→kk. Apple maps ru→ru, en→en-US/en-GB; Kazakh is preserved in Git,
while App Store uses its English fallback. A future extra store locale must be
added deliberately with a supported code; arbitrary filenames are not uploaded.
Apple notes also become TestFlight "What to Test". Required primary locales
must match these mappings (checked during U2/U3).

Reviewed 1.2.3 metadata is ready. New init drafts remain ready=false and block
publication until all three translations are approved. Ready does not authorize
release or prove cloud/store readiness.
