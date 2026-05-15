import 'package:prokat/features/bookings/models/booking_model.dart';

enum BookingChatRole { owner, client }

enum BookingChatActionId {
  acceptBooking,
  rejectBooking,
  cancelBooking,
  createCounterOffer,
  acceptCounterOffer,
  rejectCounterOffer,
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

  const BookingChatActionVm({
    required this.id,
    required this.label,
    this.isPrimary = false,
    this.isEnabled = true,
    this.disabledReason,
    this.requiresSheet = false,
    this.requiresConfirmDialog = false,
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

/// Placeholder until backend negotiation model is wired into booking/chat payloads.
class NegotiationState {
  const NegotiationState();
}

/// Placeholder until rating/review endpoints and state are implemented on mobile.
class ReviewState {
  const ReviewState();
}

String normalizeBookingStatus(BookingModel booking) {
  return booking.status.trim().toLowerCase();
}

