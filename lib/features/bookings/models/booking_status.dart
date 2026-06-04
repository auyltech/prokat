enum BookingStatus {
  draft, // 0
  created, // 1
  confirmed, // 2
  rejected, // 3
  cancelled, // 3
  failed, // 4
  completed, // 5
  reviewed, // 6
}

BookingStatus parseBookingStatus(dynamic value) {
  if (value == null) return BookingStatus.draft;

  final normalized = value.toString().trim().toLowerCase();

  for (final status in BookingStatus.values) {
    if (status.name.toLowerCase() == normalized) {
      return status;
    }
  }
  return BookingStatus.draft;
}
