enum OfferStatus {
  created,
  viewed,
  cancelled,
  accepted,
  rejected,
  expired,
  closed,
}

OfferStatus parseOfferStatus(dynamic value) {
  if (value == null) return OfferStatus.closed;

  final normalized = value.toString().trim().toLowerCase();

  for (final status in OfferStatus.values) {
    if (status.name.toLowerCase() == normalized) {
      return status;
    }
  }

  return OfferStatus.closed;
}
