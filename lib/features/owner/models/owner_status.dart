enum OwnerStatus { online, offline, closed }

OwnerStatus parseOwnerStatus(dynamic value) {
  if (value == null) return OwnerStatus.offline;

  final normalized = value.toString().trim().toLowerCase();

  for (final status in OwnerStatus.values) {
    if (status.name.toLowerCase() == normalized) {
      return status;
    }
  }

  return OwnerStatus.offline;
}
