enum OwnerRegistrationStatus {
  incomplete,
  pending,
  changesPending,
  approved,
  rejected,
  changesRejected,
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
    'changes_pending_review' ||
    'changes_pending' => OwnerRegistrationStatus.changesPending,
    'approved' => OwnerRegistrationStatus.approved,
    'rejected' => OwnerRegistrationStatus.rejected,
    'changes_rejected' => OwnerRegistrationStatus.changesRejected,
    'suspended' => OwnerRegistrationStatus.suspended,
    // Unknown statuses must not demote an already-approved owner path.
    _ => OwnerRegistrationStatus.incomplete,
  };
}

/// Already-approved owner cycle UI: map legacy `PENDING_REVIEW` / `REJECTED`
/// (from older admin rejects) onto CHANGES_* banners/tile copy.
OwnerRegistrationStatus? effectiveOwnerBusinessStatus({
  required OwnerRegistrationStatus? status,
  bool? isVerified,
  bool ownerCycle = false,
}) {
  final treatAsOwnerCycle = ownerCycle || isVerified == true;
  if (treatAsOwnerCycle) {
    return switch (status) {
      OwnerRegistrationStatus.pending => OwnerRegistrationStatus.changesPending,
      OwnerRegistrationStatus.rejected =>
        OwnerRegistrationStatus.changesRejected,
      _ => status,
    };
  }
  return status;
}

/// Documents and BUSINESS (company) onboarding are not collected in the app.
/// Approved / incomplete are not call-to-actions on the profile form.
bool shouldShowOwnerProfileStatusBanner(OwnerRegistrationStatus? status) {
  return switch (status) {
    OwnerRegistrationStatus.pending ||
    OwnerRegistrationStatus.changesPending ||
    OwnerRegistrationStatus.rejected ||
    OwnerRegistrationStatus.changesRejected ||
    OwnerRegistrationStatus.suspended => true,
    _ => false,
  };
}

/// First-time `PENDING_REVIEW` and owner `CHANGES_PENDING_REVIEW` stay read-only.
bool isOwnerBusinessProfileLocked(OwnerRegistrationStatus? status) {
  return status == OwnerRegistrationStatus.pending ||
      status == OwnerRegistrationStatus.changesPending;
}
