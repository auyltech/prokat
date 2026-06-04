enum RequestStatus {
  draft,
  created,
  viewed,
  responded,
  accepted,
  cancelled,
  expired,
}

RequestStatus parseRequestStatus(dynamic value) {
  if (value == null) return RequestStatus.draft;

  final normalized = value.toString().trim().toLowerCase();

  for (final status in RequestStatus.values) {
    if (status.name.toLowerCase() == normalized) {
      return status;
    }
  }
  return RequestStatus.draft;
}

enum OwnerRequestState { newRequest, viewed, offerSent, hidden, accepted }
