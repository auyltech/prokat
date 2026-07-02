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

  PriceNegotiationNotifier _priceNegotiationNotifier() {
    return ref.read(priceNegotiationProvider.notifier);
  }

  Future<void> refreshAfterNegotiation({
    required String chatId,
    required String bookingId,
  }) async {
    await Future.wait([
      _priceNegotiationNotifier().getPriceNegotiations(),
      _chatNotifier.reloadChat(chatId),
      _bookingNotifier.getOwnerBookings(),
      _bookingNotifier.getClientBookings(),
    ]);
  }

  Future<void> refreshAfterBookingAction({
    required String chatId,
    required String bookingId,
  }) async {
    await Future.wait([
      _chatNotifier.reloadChat(chatId),
      _bookingNotifier.getOwnerBookings(),
      _bookingNotifier.getClientBookings(),
      _priceNegotiationNotifier().getPriceNegotiations(),
    ]);
  }

  Future<void> refreshAfterReview({
    required String chatId,
    required String bookingId,
  }) async {
    await Future.wait([
      _chatNotifier.reloadChat(chatId),
      _bookingNotifier.getOwnerBookings(),
      _bookingNotifier.getClientBookings(),
    ]);
  }

  Future<void> acceptBooking({
    required BuildContext context,
    required String chatId,
    required String bookingId,
  }) async {
    await _run(
      context: context,
      submitId: "booking:accept",
      action: () {
        return _bookingNotifier.updateBookingStatus(
          id: bookingId,
          status: BookingStatus.confirmed,
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
      submitId: "booking:reject",
      action: () {
        return _bookingNotifier.updateBookingStatus(
          id: bookingId,
          status: BookingStatus.rejected,
          cancelReason: reason,
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
      submitId: "booking:cancel",
      action: () {
        return _bookingNotifier.updateBookingStatus(
          id: bookingId,
          status: BookingStatus.cancelled,
          cancelReason: reason,
        );
      },
      onSuccess: () {
        return refreshAfterBookingAction(chatId: chatId, bookingId: bookingId);
      },
    );
  }

  Future<void> confirmCompletion({
    required BuildContext context,
    required String chatId,
    required String bookingId,
  }) async {
    await _run(
      context: context,
      submitId: "booking:status",
      action: () {
        return _bookingNotifier.updateBookingStatus(
          id: bookingId,
          status: BookingStatus.completed,
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
      submitId: "price:create",
      action: () async {
        await _priceNegotiationNotifier().createCounterOffer(
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
      AppSnackBar.show(message: 'Negotiation id is missing', isError: true);
      return;
    }

    await _run(
      context: context,
      submitId: "price:cancel",
      action: () async {
        await _priceNegotiationNotifier().cancelPriceNegotiation(id);
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
      AppSnackBar.show(message: 'Negotiation id is missing', isError: true);
      return;
    }

    await _run(
      context: context,
      submitId: response == PriceNegotiationResponse.accept
          ? "price:accept"
          : "price:reject",
      action: () async {
        await _priceNegotiationNotifier().respondToPriceNegotiation(
          negotiationId: id,
          response: response,
        );

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
    String? submitId,
    String successMessage = 'Saved',
    String failureMessage = 'Action failed',
  }) async {
    if (state.isSubmitting) return;

    try {
      state = state.copyWith(
        isSubmitting: true,
        submitId: submitId,
        error: null,
      );
      final ok = await action();

      if (ok != true) {
        state = state.copyWith(isSubmitting: false);
        if (!context.mounted) return;

        AppSnackBar.show(message: failureMessage, isError: true);
        return;
      }

      await onSuccess();

      state = state.copyWith(isSubmitting: false, submitId: null);

      if (!context.mounted) return;

      AppSnackBar.show(message: successMessage, isSuccess: true);
    } catch (error) {
      // TODO: remove error message
      final message = error.toString().replaceFirst('Exception: ', '');

      state = state.copyWith(
        isSubmitting: false,
        error: message,
        submitId: null,
      );
      if (!context.mounted) return;

      AppSnackBar.show(message: message, isError: true);
    }
  }
}
