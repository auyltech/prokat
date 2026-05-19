---
name: flutter-implement-json-serialization
description: Create Flutter/Dart model classes with manual `fromJson`/`toJson` using `dart:convert`, including defensive parsing and mapping JSON keys to class properties (no codegen).
---

# Manual JSON serialization (Flutter)

Use this skill when implementing simple DTO/model classes by hand (no `json_serializable`) and wiring them into services/providers.

## Core guidelines

- Import `dart:convert` for `jsonDecode` / `jsonEncode` when needed (often Dio already gives `Map`/`List`).
- Keep model classes plain: `final` fields, `const` constructor, `factory Model.fromJson(Map<String, dynamic> json)`, and `Map<String, dynamic> toJson()`.
- Parse defensively:
  - Treat incoming types as untrusted (`dynamic`); cast explicitly.
  - Handle `null` and missing keys intentionally.
  - Prefer `FormatException` (or a project-standard exception) when payload shape is invalid.
- Keep API/network code out of widgets. Parse in `services/` and expose state via Riverpod `providers/`.
- For large payloads, offload decoding/mapping to an isolate via `compute()`.
- Preserve backend error messages (for Dio errors): don’t replace with generic text unless there is no message.

## Workflow: implementing a serializable model

1. Create the model in `lib/features/<feature>/models/` (or the closest existing feature folder).
2. Add `fromJson`:
   - Accept `Map<String, dynamic>`.
   - Extract and cast each field.
   - Validate required fields; throw on invalid shape.
3. Add `toJson`:
   - Return `Map<String, dynamic>` using backend field names.
4. Add a small unit test covering round-trip `toJson` → `fromJson` in `test/`.
5. Run `dart format .` and `flutter analyze`.

## Workflow: fetching + parsing JSON (Dio-oriented)

1. Execute request in a service (Dio).
2. Validate success:
   - If the endpoint uses non-2xx for errors, let Dio throw and surface the backend message.
3. Decide strategy:
   - Small object/list: parse synchronously.
   - Large list: map in `compute()` (top-level function required).
4. Decode/map:
   - If `response.data` is already a `Map`/`List`, cast and map.
   - If `response.data` is a `String`, `jsonDecode` then cast.

## Examples

### Model implementation (pattern matching)

```dart
class User {
  final int id;
  final String name;
  final String email;

  const User({
    required this.id,
    required this.name,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'id': int id,
        'name': String name,
        'email': String email,
      } =>
        User(id: id, name: name, email: email),
      _ => throw const FormatException('Failed to load User.'),
    };
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
      };
}
```

### Background parsing (large payload)

```dart
import 'package:flutter/foundation.dart';

List<User> parseUsers(List<dynamic> data) {
  final list = data.cast<Map<String, dynamic>>();
  return list.map(User.fromJson).toList();
}

Future<List<User>> mapUsersInBackground(List<dynamic> data) {
  return compute(parseUsers, data);
}
```

