# Release metadata

Operator source for a version is three files only:

```text
releases/X.Y.Z/ru.txt
releases/X.Y.Z/en.txt
releases/X.Y.Z/kk.txt
```

Create a draft on Windows: `dart tool/release/release.dart init --version 1.2.5`.
This does not select a commit or create a tag. Edit the three files as UTF-8
plain text, each 1–500 characters, no BOM, no TODO/REPLACE_ME/PLACEHOLDER.
Commit them together with the `pubspec.yaml` version bump, then review/squash
`dev` → `main`. Do not create or edit `release.json`; leftover copies are ignored
and are not an approval signal.

The owner CLI reads `pubspec.yaml` at fresh `origin/main` and derives the tag;
CI supplies Flutter build-name/build-number from that tag and checks pubspec
agreement. The counter is common to both platforms, 1..9999. Same version/build
across platforms requires the same SHA. Store APIs, not Git alone, prove live
availability. Use [the four owner commands](../CICD-README.md); never re-upload
accepted builds. Current publishers do not implement RC-to-production promotion
of the same build.

RC and production source commits must both be reachable from freshly fetched
`origin/main`. A valid tag name or cached ref alone cannot authorize a release.
Filled notes approve store copy for parsing; they do not authorize a tag, CI run,
upload, PR merge or production publishing.

All three source translations are mandatory. Android maps ru→ru-RU,
en→en-US, kk→kk. Apple maps ru→ru, en→en-US/en-GB; Kazakh is preserved in Git,
while App Store uses its English fallback. A future extra store locale must be
added deliberately with a supported code; arbitrary filenames are not uploaded.
Apple notes also become TestFlight "What to Test". Required primary locales
must match these mappings (checked during U2/U3).
