import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/chat/widgets/booking_actions/booking_chat_action_models.dart';

class BookingChatActionResolver {
  const BookingChatActionResolver();

  BookingChatActionResolution resolve({
    required BookingModel booking,
    required BookingChatRole role,
    required DateTime now,
    NegotiationState? negotiation,
    ReviewState? reviewState,
  }) {
    final status = booking.status.trim().toLowerCase();
    
    final workStatus = booking.workStatus;

    final isFinal = _isFinalBookingStatus(status);

    if (isFinal) {
      return BookingChatActionResolution(
        statusText: _finalStatusText(status),
        primaryAction: null,
      );
    }

    if (status == BookingStatus.created.name) {
      return _resolveCreated(role: role);
    }

    if (status == BookingStatus.confirmed.name) {
      return _resolveConfirmed(role: role, workStatus: workStatus);
    }

    // Unknown / evolving backend status: stay safe.
    return const BookingChatActionResolution(
      statusText: 'Booking status updated',
      primaryAction: null,
    );
  }

  BookingChatActionResolution _resolveCreated({required BookingChatRole role}) {
    if (role == BookingChatRole.owner) {
      return const BookingChatActionResolution(
        statusText: 'New booking request',
        primaryAction: BookingChatActionVm(
          id: BookingChatActionId.acceptBooking,
          label: 'Accept',
          isPrimary: true,
          requiresConfirmDialog: true,
        ),
        secondaryActions: [
          BookingChatActionVm(
            id: BookingChatActionId.rejectBooking,
            label: 'Reject',
            requiresSheet: true,
          ),
        ],
        overflowActions: [
          BookingChatActionVm(
            id: BookingChatActionId.createCounterOffer,
            label: 'Counter',
            isEnabled: true,
            disabledReason: 'Negotiation not implemented',
            requiresSheet: true,
          ),
        ],
      );
    }

    return const BookingChatActionResolution(
      statusText: 'Waiting for owner response',
      primaryAction: BookingChatActionVm(
        id: BookingChatActionId.cancelBooking,
        label: 'Cancel',
        isPrimary: true,
        requiresSheet: true,
      ),
      overflowActions: [
        BookingChatActionVm(
          id: BookingChatActionId.createCounterOffer,
          label: 'Counter offer',
          isEnabled: false,
          disabledReason: 'Negotiation not implemented',
          requiresSheet: true,
        ),
      ],
    );
  }

  BookingChatActionResolution _resolveConfirmed({
    required BookingChatRole role,
    required WorkStatus workStatus,
  }) {
    final isWorkCompleted = workStatus == WorkStatus.completed;

    if (role == BookingChatRole.owner) {
      if (isWorkCompleted) {
        return const BookingChatActionResolution(
          statusText: 'Waiting for client confirmation',
          primaryAction: null,
        );
      }

      return const BookingChatActionResolution(
        statusText: 'Work in progress',
        primaryAction: BookingChatActionVm(
          id: BookingChatActionId.updateWorkStatus,
          label: 'Update status',
          isPrimary: true,
          requiresSheet: true,
        ),
        overflowActions: [
          BookingChatActionVm(
            id: BookingChatActionId.markWorkCompleted,
            label: 'Mark completed',
            requiresConfirmDialog: true,
          ),
        ],
      );
    }

    if (isWorkCompleted) {
      return const BookingChatActionResolution(
        statusText: 'Owner marked work completed',
        primaryAction: BookingChatActionVm(
          id: BookingChatActionId.confirmCompletion,
          label: 'Confirm completion',
          isPrimary: true,
          requiresConfirmDialog: true,
        ),
      );
    }

    return const BookingChatActionResolution(
      statusText: 'Waiting for owner to start work',
      primaryAction: null,
    );
  }

  bool _isFinalBookingStatus(String status) {
    return status == BookingStatus.completed.name ||
        status == BookingStatus.cancelled.name ||
        status == BookingStatus.rejected.name ||
        status == BookingStatus.failed.name;
  }

  String _finalStatusText(String status) {
    if (status == BookingStatus.completed.name) return 'Booking completed';
    if (status == BookingStatus.cancelled.name) return 'Booking cancelled';
    if (status == BookingStatus.rejected.name) return 'Booking rejected';
    if (status == BookingStatus.failed.name) return 'Booking failed';
    return 'Booking closed';
  }
}

