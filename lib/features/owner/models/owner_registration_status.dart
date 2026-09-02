enum OwnerRegistrationStatus {
  incomplete,
  pending,
  approved,
  rejected,
  suspended,
}

/// Maps `OwnerProfileStatus` from GET /owner/profile (`APPROVED`, `PENDING_REVIEW`, …).
OwnerRegistrationStatus parseOwnerRegistrationStatus(dynamic value) {
  if (value == null) return OwnerRegistrationStatus.incomplete;

  final normalized = value
      .toString()
      .trim()
      .toLowerCase()
      .replaceAll('-', '_')
      .replaceAll(' ', '_');

  return switch (normalized) {
    'incomplete' => OwnerRegistrationStatus.incomplete,
    'pending' || 'pending_review' => OwnerRegistrationStatus.pending,
    'approved' => OwnerRegistrationStatus.approved,
    'rejected' => OwnerRegistrationStatus.rejected,
    'suspended' => OwnerRegistrationStatus.suspended,
    _ => OwnerRegistrationStatus.incomplete,
  };
}

/// Documents and BUSINESS (company) onboarding are not collected in the app.
/// Approved / incomplete are not call-to-actions on the profile form.
bool shouldShowOwnerProfileStatusBanner(OwnerRegistrationStatus? status) {
  return switch (status) {
    OwnerRegistrationStatus.pending ||
    OwnerRegistrationStatus.rejected ||
    OwnerRegistrationStatus.suspended => true,
    _ => false,
  };
}
