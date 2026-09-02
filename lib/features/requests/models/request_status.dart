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
};

/// Statuses that occupy the "one active request" create slot.
/// `ACCEPTED` leaves the active list (history later) and does not block a new request.
const occupiesCreateRequestSlotStatuses = <RequestStatus>{
  RequestStatus.draft,
  RequestStatus.created,
  RequestStatus.viewed,
  RequestStatus.responded,
};

bool occupiesCreateRequestSlot(RequestStatus status) {
  return occupiesCreateRequestSlotStatuses.contains(status);
}

const archivedRequestStatuses = <RequestStatus>{
  RequestStatus.accepted,
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
