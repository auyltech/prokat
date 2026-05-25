import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/chat/widgets/booking_actions/booking_chat_action_models.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_state.dart';
import 'package:prokat/features/reviews/state/review_state.dart';

class BookingChatActionResolver {
  const BookingChatActionResolver();

  BookingChatActionResolution resolve({
    required BookingModel booking,
    required BookingChatRole role,
    required DateTime now,
    PriceNegotiationState? negotiation,
    ReviewState? reviewState,
    String? currentUserId,
    String? chatOwnerId,
    String? chatClientId,
  }) {
    final status = booking.status.trim().toLowerCase();
    final workStatus = booking.workStatus;

    // when reviewed, chat is locked, until archived
    if (status == 'reviewed') {
      return const BookingChatActionResolution(
        statusText: 'Reviews submitted',
        primaryAction: null,
      );
    }

    // when client and owner confirm completed, allow review
    if (status == BookingStatus.completed.name) {
      return _resolveCompleted(
        role: role,
        booking: booking,
        reviewState: reviewState,
        chatOwnerId: chatOwnerId,
        chatClientId: chatClientId,
      );
    }

    // when order is cancelled / rejected / failed
    final isFinal = _isFinalBookingStatus(status);
    if (isFinal) {
      return BookingChatActionResolution(
        statusText: _finalStatusText(status),
        primaryAction: null,
      );
    }

    // When order is created / pending confirmation
    if (status == BookingStatus.created.name) {
      return _resolveCreated(
        role: role,
        negotiation: negotiation,
        currentUserId: currentUserId,
      );
    }

    // when order is confirmed (work in process)
    if (status == BookingStatus.confirmed.name) {
      return _resolveConfirmed(role: role, workStatus: workStatus);
    }

    // Unknown / evolving backend status: stay safe.
    return const BookingChatActionResolution(
      statusText: 'Booking status updated',
      primaryAction: null,
    );
  }

  BookingChatActionResolution _resolveCompleted({
    required BookingChatRole role,
    required BookingModel booking,
    ReviewState? reviewState,
    String? chatOwnerId,
    String? chatClientId,
  }) {
    final hasSubmitted =
        reviewState?.hasSubmitted == true || booking.myReviewId != null;

    final revieweeId = role == BookingChatRole.owner
        ? ((booking.renter?.id ?? '').trim().isNotEmpty
              ? booking.renter?.id
              : chatClientId)
        : ((booking.equipment?.ownerId ?? '').trim().isNotEmpty
              ? booking.equipment?.ownerId
              : chatOwnerId);

    if (!hasSubmitted && (revieweeId ?? '').trim().isNotEmpty) {
      return BookingChatActionResolution(
        statusText: 'Booking completed',
        primaryAction: BookingChatActionVm(
          id: BookingChatActionId.leaveReview,
          label: role == BookingChatRole.owner
              ? 'Review client'
              : 'Review owner',
          isPrimary: true,
          requiresSheet: true,
          payloadId: revieweeId,
        ),
      );
    }

    return BookingChatActionResolution(
      statusText: hasSubmitted ? 'Review submitted' : 'Booking completed',
      primaryAction: null,
    );
  }

  BookingChatActionResolution _resolveCreated({
    required BookingChatRole role,
    PriceNegotiationState? negotiation,
    String? currentUserId,
  }) {
    final pending = negotiation?.latestPending;
    final pendingId = (pending?.id ?? '').trim();

    final userId = (currentUserId ?? '').trim();
    final isPendingFromMe =
        pendingId.isNotEmpty &&
        userId.isNotEmpty &&
        (pending?.senderId ?? '').trim() == userId;

    if (pendingId.isNotEmpty) {
      if (isPendingFromMe) {
        return BookingChatActionResolution(
          statusText: 'Waiting for response',
          primaryAction: BookingChatActionVm(
            id: BookingChatActionId.cancelCounterOffer,
            label: 'Cancel counter',
            isPrimary: true,
            requiresConfirmDialog: true,
            payloadId: pendingId,
          ),
        );
      }

      return BookingChatActionResolution(
        statusText: 'New counter offer',
        primaryAction: BookingChatActionVm(
          id: BookingChatActionId.acceptCounterOffer,
          label: 'Accept',
          isPrimary: true,
          requiresConfirmDialog: true,
          payloadId: pendingId,
        ),
        secondaryActions: [
          BookingChatActionVm(
            id: BookingChatActionId.rejectCounterOffer,
            label: 'Reject',
            requiresConfirmDialog: true,
            payloadId: pendingId,
          ),
        ],
        overflowActions: const [
          BookingChatActionVm(
            id: BookingChatActionId.createCounterOffer,
            label: 'Counter',
            requiresSheet: true,
          ),
        ],
      );
    }

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
          isEnabled: true,
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
    return status == BookingStatus.cancelled.name ||
        status == BookingStatus.rejected.name ||
        status == BookingStatus.failed.name;
  }

  String _finalStatusText(String status) {
    if (status == BookingStatus.cancelled.name) return 'Booking cancelled';
    if (status == BookingStatus.rejected.name) return 'Booking rejected';
    if (status == BookingStatus.failed.name) return 'Booking failed';
    return 'Booking closed';
  }
}
