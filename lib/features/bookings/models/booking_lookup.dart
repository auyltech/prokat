class BookingLookup {
  final String bookingId;
  final bool isOwner;

  const BookingLookup({required this.bookingId, required this.isOwner});

  @override
  bool operator ==(Object other) {
    return other is BookingLookup &&
        other.bookingId == bookingId &&
        other.isOwner == isOwner;
  }

  @override
  int get hashCode => Object.hash(bookingId, isOwner);
}
