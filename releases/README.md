# Release metadata

Create a draft on Windows: `dart tool/release/release.dart init --version 1.2.3`.
This does not select a commit or create a tag. Edit `ru.txt`, `en.txt`, `kk.txt`
as UTF-8 plain text, each 1–500 characters. After review set `ready: true` in
`release.json`. Commit metadata together with the intended release source.

Schema: `{"schema":1,"version":"1.2.3","ready":true}`. Build numbers are
platform-specific and come only from tags. The pubspec version remains a local
development default; CI supplies Flutter build-name and build-number explicitly.

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

No sample release is marked ready; an empty draft must block publication.
