# Refactoring baseline

This document records the reproducible starting point for tactical mobile
hardening. It is evidence for RF-01, not proof of TO-BE conformance.

## Source provenance

- Branch: `feat/prokat-plans-refactoring`
- Mobile baseline: `2ea3a59`
- Frozen Mobile AS-IS reference: `171f7ba`
- Architecture baseline: `PROKAT-Architecture@d8da8a7`
- Recorded: 2026-08-13

Crashlytics and `equipment_demand` are post-`171f7ba` additions. Their current
behavior must not be inferred from the frozen Mobile AS-IS document.

## Toolchain

- Flutter: `3.41.9`, stable, framework revision `00b0c91f06`
- Dart: `3.11.5`
- Dependency resolution: existing `pubspec.lock`, no dependency upgrades

The project `.metadata` still records its creation/base revision separately.
Changing that metadata or upgrading Flutter is outside RF-01.

## Verified commands

```text
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test
git diff --check
flutter gen-l10n
git diff --exit-code -- lib/l10n
flutter analyze --no-pub --fatal-infos --fatal-warnings
flutter test --no-pub --reporter expanded
flutter test --no-pub --reporter compact
```

Results on the baseline:

- dependency resolution succeeded without changing `pubspec.lock`;
- 489 Dart files required no formatting changes;
- generated localization output had no drift;
- analyzer reported no issues;
- the full suite passed twice with 47 tests and no added skips;
- the working tree remained clean.

## RF-11 lint audit

The first proposed async-safety batch (`unawaited_futures`,
`discarded_futures`, and `avoid_void_async`) produced 203 existing findings
across API, provider lifecycle, UI, and state code. Enabling it would either
break the quality gate or force unrelated behavior domains into one change.

The batch is therefore not enabled. Individual findings may be fixed only in
their owning regression-first work package. The CI instead enforces
zero-noise structural checks now: patch whitespace and generated worktree
drift.

Flutter/Dart analytics cannot update the sandbox user's roaming telemetry file.
This does not affect formatting results, but CI disables analytics explicitly so
the check has no dependency on a user profile.

## Scope boundary

This baseline does not authorize production changes, dependency upgrades,
target API/domain decisions, or edits to `.gitignore`. Every subsequent bug fix
must add a deterministic RED regression first and be independently revertible.
