class OwnerProfilePendingChange {
  final String field;
  final String from;
  final String to;

  const OwnerProfilePendingChange({
    required this.field,
    required this.from,
    required this.to,
  });

  factory OwnerProfilePendingChange.fromJson(Map<String, dynamic> json) {
    return OwnerProfilePendingChange(
      field: json['field']?.toString() ?? '',
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'field': field, 'from': from, 'to': to};
}

List<OwnerProfilePendingChange> parseOwnerProfilePendingChanges(dynamic raw) {
  if (raw is! List) return const [];
  final result = <OwnerProfilePendingChange>[];
  for (final item in raw) {
    if (item is Map) {
      final change = OwnerProfilePendingChange.fromJson(
        Map<String, dynamic>.from(item),
      );
      if (change.field.trim().isEmpty) continue;
      result.add(change);
    }
  }
  return result;
}
