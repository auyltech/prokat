enum PriceNegotiationStatus {
  pending,
  accepted,
  rejected,
  cancelled,
  expired,
  unknown,
}

PriceNegotiationStatus parsePriceNegotiationStatus(String? raw) {
  final value = (raw ?? '').trim().toUpperCase();
  switch (value) {
    case 'PENDING':
      return PriceNegotiationStatus.pending;
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

