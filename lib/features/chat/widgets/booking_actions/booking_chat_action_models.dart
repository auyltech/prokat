import 'package:prokat/features/bookings/models/booking_model.dart';

enum BookingChatRole { owner, client }

enum BookingChatActionId {
  acceptBooking,
  rejectBooking,
  cancelBooking,

  createCounterOffer,
  acceptCounterOffer,
  rejectCounterOffer,
  cancelCounterOffer,

  updateWorkStatus,
  markWorkCompleted,

  confirmCompletion,
  
  leaveReview,
}

class BookingChatActionVm {
  final BookingChatActionId id;
  final String label;
  final bool isPrimary;
  final bool isEnabled;
  final String? disabledReason;
  final bool requiresSheet;
  final bool requiresConfirmDialog;
  final String? payloadId;

  const BookingChatActionVm({
    required this.id,
    required this.label,
    this.isPrimary = false,
    this.isEnabled = true,
    this.disabledReason,
    this.requiresSheet = false,
    this.requiresConfirmDialog = false,
    this.payloadId,
  });
}

class BookingChatActionResolution {
  final String statusText;
  final BookingChatActionVm? primaryAction;
  final List<BookingChatActionVm> secondaryActions;
  final List<BookingChatActionVm> overflowActions;

  const BookingChatActionResolution({
    required this.statusText,
    this.primaryAction,
    this.secondaryActions = const [],
    this.overflowActions = const [],
  });
}

String normalizeBookingStatus(BookingModel booking) {
  return booking.status.trim().toLowerCase();
}
