import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/bookings/state/booking_notifier.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:prokat/features/chat/state/chat_notifier.dart';
import 'package:prokat/features/chat/state/chat_provider.dart';
import 'package:prokat/features/chat/widgets/booking_actions/booking_chat_action_state.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_model.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_notifier.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';

final bookingChatActionControllerProvider =
    StateNotifierProvider.family<
      BookingChatActionController,
      BookingChatActionState,
      String
    >((ref, bookingId) {
      return BookingChatActionController(ref: ref, bookingId: bookingId);
    });

class BookingChatActionController
    extends StateNotifier<BookingChatActionState> {
  final Ref ref;
  final String bookingId;

  BookingChatActionController({required this.ref, required this.bookingId})
    : super(const BookingChatActionState());

  BookingNotifier get _bookingNotifier => ref.read(bookingProvider.notifier);

  ChatNotifier get _chatNotifier => ref.read(chatProvider.notifier);

  PriceNegotiationNotifier _priceNegotiationNotifier(String bookingId) {
    return ref.read(priceNegotiationProvider.notifier);
  }

  Future<void> refreshAfterNegotiation({
    required String chatId,
    required String bookingId,
  }) async {
    await Future.wait([
      _priceNegotiationNotifier(bookingId).getPriceNegotiations(),
      _chatNotifier.reloadChat(chatId),
      _bookingNotifier.getOwnerBookings(),
      _bookingNotifier.getUserBookings(),
    ]);
  }

  Future<void> refreshAfterBookingAction({
    required String chatId,
    required String bookingId,
  }) async {
    await Future.wait([
      _chatNotifier.reloadChat(chatId),
      _bookingNotifier.getOwnerBookings(),
      _bookingNotifier.getUserBookings(),
      _priceNegotiationNotifier(bookingId).getPriceNegotiations(),
    ]);
  }

  Future<void> refreshAfterReview({
    required String chatId,
    required String bookingId,
  }) async {
    await Future.wait([
      _chatNotifier.reloadChat(chatId),
      _bookingNotifier.getOwnerBookings(),
      _bookingNotifier.getUserBookings(),
    ]);
  }

  Future<void> acceptBooking({
    required BuildContext context,
    required String chatId,
    required String bookingId,
  }) async {
    await _run(
      context: context,
      action: () {
        return _bookingNotifier.updateBookingStatus(
          id: bookingId,
          status: BookingStatus.confirmed.name,
        );
      },
      onSuccess: () {
        return refreshAfterBookingAction(chatId: chatId, bookingId: bookingId);
      },
    );
  }

  Future<void> rejectBooking({
    required BuildContext context,
    required String chatId,
    required String bookingId,
    String? reason,
  }) async {
    await _run(
      context: context,
      action: () {
        return _bookingNotifier.updateBookingStatus(
          id: bookingId,
          status: BookingStatus.rejected.name,
          workStatus: reason,
        );
      },
      onSuccess: () {
        return refreshAfterBookingAction(chatId: chatId, bookingId: bookingId);
      },
    );
  }

  Future<void> cancelBooking({
    required BuildContext context,
    required String chatId,
    required String bookingId,
    String? reason,
  }) async {
    await _run(
      context: context,
      action: () {
        return _bookingNotifier.updateBookingStatus(
          id: bookingId,
          status: BookingStatus.cancelled.name,
          workStatus: reason,
        );
      },
      onSuccess: () {
        return refreshAfterBookingAction(chatId: chatId, bookingId: bookingId);
      },
    );
  }

  Future<void> updateWorkStatus({
    required BuildContext context,
    required String chatId,
    required String bookingId,
    required WorkStatus workStatus,
  }) async {
    await _run(
      context: context,
      action: () {
        return _bookingNotifier.updateBookingWorkStatus(
          id: bookingId,
          workStatus: workStatus.name,
        );
      },
      onSuccess: () {
        return refreshAfterBookingAction(chatId: chatId, bookingId: bookingId);
      },
    );
  }

  Future<void> markWorkCompleted({
    required BuildContext context,
    required String chatId,
    required String bookingId,
  }) async {
    await updateWorkStatus(
      context: context,
      chatId: chatId,
      bookingId: bookingId,
      workStatus: WorkStatus.completed,
    );
  }

  Future<void> confirmCompletion({
    required BuildContext context,
    required String chatId,
    required String bookingId,
  }) async {
    await _run(
      context: context,
      action: () {
        return _bookingNotifier.updateBookingStatus(
          id: bookingId,
          status: BookingStatus.completed.name,
        );
      },
      onSuccess: () {
        return refreshAfterBookingAction(chatId: chatId, bookingId: bookingId);
      },
    );
  }

  Future<void> createCounterOffer({
    required BuildContext context,
    required String chatId,
    required String bookingId,
    required int price,
    required PriceRateOption priceRate,
    required String type,
    String? comment,
  }) async {
    await _run(
      context: context,
      action: () async {
        await _priceNegotiationNotifier(bookingId).createCounterOffer(
          type: type,
          price: price,
          priceRate: priceRate.value,
          comment: comment,
        );

        return true;
      },
      onSuccess: () {
        return refreshAfterNegotiation(chatId: chatId, bookingId: bookingId);
      },
      successMessage: 'Counter offer sent',
    );
  }

  Future<void> acceptCounterOffer({
    required BuildContext context,
    required String chatId,
    required String bookingId,
    required String negotiationId,
  }) async {
    await _respondToNegotiation(
      context: context,
      chatId: chatId,
      bookingId: bookingId,
      negotiationId: negotiationId,
      response: PriceNegotiationResponse.accept,
    );
  }

  Future<void> rejectCounterOffer({
    required BuildContext context,
    required String chatId,
    required String bookingId,
    required String negotiationId,
  }) async {
    await _respondToNegotiation(
      context: context,
      chatId: chatId,
      bookingId: bookingId,
      negotiationId: negotiationId,
      response: PriceNegotiationResponse.reject,
    );
  }

  Future<void> cancelNegotiation({
    required BuildContext context,
    required String chatId,
    required String bookingId,
    required String negotiationId,
  }) async {
    final id = negotiationId.trim();

    if (id.isEmpty) {
      AppSnackBar.show(
        context,
        message: 'Negotiation id is missing',
        isError: true,
      );
      return;
    }

    await _run(
      context: context,
      action: () async {
        await _priceNegotiationNotifier(bookingId).cancelNegotiation(id);
        return true;
      },
      onSuccess: () {
        return refreshAfterNegotiation(chatId: chatId, bookingId: bookingId);
      },
    );
  }

  Future<void> _respondToNegotiation({
    required BuildContext context,
    required String chatId,
    required String bookingId,
    required String negotiationId,
    required PriceNegotiationResponse response,
  }) async {
    final id = negotiationId.trim();

    if (id.isEmpty) {
      AppSnackBar.show(
        context,
        message: 'Negotiation id is missing',
        isError: true,
      );
      return;
    }

    await _run(
      context: context,
      action: () async {
        await _priceNegotiationNotifier(
          bookingId,
        ).respond(negotiationId: id, response: response);

        return true;
      },
      onSuccess: () {
        return refreshAfterNegotiation(chatId: chatId, bookingId: bookingId);
      },
    );
  }

  Future<void> _run({
    required BuildContext context,
    required Future<bool> Function() action,
    required Future<void> Function() onSuccess,
    String successMessage = 'Saved',
    String failureMessage = 'Action failed',
  }) async {
    if (state.isSubmitting) return;

    try {
      state = state.copyWith(isSubmitting: true, error: null);
      final ok = await action();

      if (ok != true) {
        state = state.copyWith(isSubmitting: false);
        if (!context.mounted) return;

        AppSnackBar.show(context, message: failureMessage, isError: true);
        return;
      }

      await onSuccess();

      state = state.copyWith(isSubmitting: false);
      if (!context.mounted) return;

      AppSnackBar.show(context, message: successMessage, isSuccess: true);
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isSubmitting: false, error: message);
      if (!context.mounted) return;

      AppSnackBar.show(context, message: message, isError: true);
    }
  }
}
