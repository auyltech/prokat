enum OwnerRegistrationStatus { incomplete, pending, approved, rejected }

OwnerRegistrationStatus parseOwnerRegistrationStatus(dynamic value) {
  if (value == null) return OwnerRegistrationStatus.incomplete;

  final normalized = value.toString().trim().toLowerCase();

  for (final status in OwnerRegistrationStatus.values) {
    if (status.name.toLowerCase() == normalized) {
      return status;
    }
  }

  return OwnerRegistrationStatus.incomplete;
}
