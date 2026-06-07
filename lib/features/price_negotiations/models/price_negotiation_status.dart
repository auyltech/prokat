enum PriceNegotiationStatus {
  created,
  accepted,
  rejected,
  cancelled,
  expired,
  unknown,
}

PriceNegotiationStatus parsePriceNegotiationStatus(String? raw) {
  final value = (raw ?? '').trim().toUpperCase();
  switch (value) {
    case 'CREATED':
      return PriceNegotiationStatus.created;
    case 'ACCEPTED':
      return PriceNegotiationStatus.accepted;
    case 'REJECTED':
      return PriceNegotiationStatus.rejected;
    case 'CANCELLED':
      return PriceNegotiationStatus.cancelled;
    case 'EXPIRED':
      return PriceNegotiationStatus.expired;
    default:
      return PriceNegotiationStatus.unknown;
  }
}
