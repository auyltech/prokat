import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:prokat/features/chat/state/chat_provider.dart';
import 'package:prokat/features/chat/widgets/booking_actions/booking_chat_action_models.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_response.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';

final bookingChatActionControllerProvider =
    Provider<BookingChatActionController>((ref) {
      return BookingChatActionController(ref);
    });

class BookingChatActionController {
  final Ref ref;

  BookingChatActionController(this.ref);

  Future<void> refreshAfterNegotiation({
    required String chatId,
    required String bookingId,
  }) async {
    await ref
        .read(priceNegotiationByBookingProvider(bookingId).notifier)
        .refresh();
    await ref.read(chatProvider.notifier).reloadChat(chatId);

    final bookingNotifier = ref.read(bookingProvider.notifier);
    await Future.wait([
      bookingNotifier.getOwnerBookings(),
      bookingNotifier.getUserBookings(),
    ]);
  }

  Future<void> refreshAfterReview({
    required String chatId,
    required String bookingId,
  }) async {
    await ref.read(chatProvider.notifier).reloadChat(chatId);

    final bookingNotifier = ref.read(bookingProvider.notifier);
    await Future.wait([
      bookingNotifier.getOwnerBookings(),
      bookingNotifier.getUserBookings(),
    ]);
  }

  Future<void> runAction({
    required BuildContext context,
    required String chatId,
    required String bookingId,
    required BookingChatActionId actionId,
    WorkStatus? workStatus,
    String? reason,
    String? payloadId,
  }) async {
    final bookingNotifier = ref.read(bookingProvider.notifier);
    final chatNotifier = ref.read(chatProvider.notifier);

    try {
      final ok = await switch (actionId) {
        BookingChatActionId.acceptBooking =>
          bookingNotifier.updateBookingStatus(
            id: bookingId,
            status: BookingStatus.confirmed.name,
          ),

        BookingChatActionId.rejectBooking =>
          bookingNotifier.updateBookingStatus(
            id: bookingId,
            status: BookingStatus.rejected.name,
            workStatus: reason,
          ),

        BookingChatActionId.cancelBooking =>
          bookingNotifier.updateBookingStatus(
            id: bookingId,
            status: BookingStatus.cancelled.name,
            workStatus: reason,
          ),

        BookingChatActionId.updateWorkStatus =>
          bookingNotifier.updateBookingWorkStatus(
            id: bookingId,
            workStatus: (workStatus ?? WorkStatus.pending).name,
          ),

        BookingChatActionId.markWorkCompleted =>
          bookingNotifier.updateBookingWorkStatus(
            id: bookingId,
            workStatus: WorkStatus.completed.name,
          ),

        BookingChatActionId.confirmCompletion =>
          bookingNotifier.updateBookingStatus(
            id: bookingId,
            status: BookingStatus.completed.name,
          ),

        BookingChatActionId.acceptCounterOffer => _respondToNegotiation(
          bookingId: bookingId,
          negotiationId: payloadId,
          response: PriceNegotiationResponse.accept,
        ),

        BookingChatActionId.rejectCounterOffer => _respondToNegotiation(
          bookingId: bookingId,
          negotiationId: payloadId,
          response: PriceNegotiationResponse.reject,
        ),

        BookingChatActionId.cancelCounterOffer => _cancelNegotiation(
          bookingId: bookingId,
          negotiationId: payloadId,
        ),

        _ => Future<bool>.value(false),
      };

      if (ok != true) {
        AppSnackBar.show(context, message: 'Action failed', isError: true);
        return;
      }

      await chatNotifier.reloadChat(chatId);

      await Future.wait([
        bookingNotifier.getOwnerBookings(),
        bookingNotifier.getUserBookings(),
        ref
            .read(priceNegotiationByBookingProvider(bookingId).notifier)
            .refresh(),
      ]);

      if (!context.mounted) return;
      AppSnackBar.show(context, message: 'Saved', isSuccess: true);
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.show(
        context,
        message: e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<bool> _respondToNegotiation({
    required String bookingId,
    required String? negotiationId,
    required PriceNegotiationResponse response,
  }) async {
    final id = (negotiationId ?? '').trim();
    if (id.isEmpty) return false;
    await ref
        .read(priceNegotiationByBookingProvider(bookingId).notifier)
        .respond(negotiationId: id, response: response);
    return true;
  }

  Future<bool> _cancelNegotiation({
    required String bookingId,
    required String? negotiationId,
  }) async {
    final id = (negotiationId ?? '').trim();
    if (id.isEmpty) return false;
    await ref
        .read(priceNegotiationByBookingProvider(bookingId).notifier)
        .cancel(id);
    return true;
  }
}
