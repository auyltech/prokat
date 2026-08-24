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

const activeRequestStatuses = <RequestStatus>{
  RequestStatus.draft,
  RequestStatus.created,
  RequestStatus.viewed,
  RequestStatus.responded,
  RequestStatus.accepted,
};

const archivedRequestStatuses = <RequestStatus>{
  RequestStatus.cancelled,
  RequestStatus.expired,
};

bool isActiveRequestStatus(RequestStatus status) {
  return activeRequestStatuses.contains(status);
}

bool isArchivedRequestStatus(RequestStatus status) {
  return archivedRequestStatuses.contains(status);
}

enum OwnerRequestState { newRequest, viewed, offerSent, hidden, accepted }
