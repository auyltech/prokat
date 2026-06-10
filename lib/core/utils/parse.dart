String parseString(dynamic value, {required String fieldName}) {
  if (value == null) {
    throw FormatException(
      "Expected non-null String for field '$fieldName', received null",
    );
  }
  final stringValue = value.toString().trim();
  if (stringValue.isEmpty) {
    throw FormatException("Field '$fieldName' is an empty string");
  }
  return stringValue;
}

int parseInt(dynamic value, {required String fieldName}) {
  if (value is int) return value;
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw FormatException(
    "Expected non-null Int for field '$fieldName', received: $value",
  );
}

int? parseNullableInt(dynamic value) {
  if (value == null) return null;

  if (value is int) return value;

  if (value is String) {
    return int.tryParse(value);
  }

  return null;
}

DateTime parseDateTime(dynamic value, {required String fieldName}) {
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return parsed.toLocal(); // Maintain timezone consistency
    }
  }

  throw FormatException(
    "Expected valid ISO8601 Date string for '$fieldName', received: $value",
  );
}

DateTime? parseNullableDate(dynamic value) {
  if (value == null) return null;

  try {
    // Already a DateTime
    if (value is DateTime) return value;

    // ISO string or other string formats
    if (value is String) {
      if (value.trim().isEmpty) return null;
      return DateTime.tryParse(value);
    }

    // Unix timestamp (seconds or milliseconds)
    if (value is int) {
      // Detect seconds vs milliseconds
      if (value > 1000000000000) {
        // milliseconds
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else {
        // seconds
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
    }

    // Double timestamp (rare but possible)
    if (value is double) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
  } catch (_) {
    // swallow any unexpected parsing errors
  }

  return null;
}

bool parseBoolean(dynamic value) {
  if (value == null) return false;

  try {
    if (value.toString().trim().toLowerCase() == "true") {
      return true;
    }
    return false;
  } catch (_) {
    return false;
  }
}
