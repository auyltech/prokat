import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/providers/booking_mutation_provider.dart';
import 'package:prokat/features/chat/widgets/booking_actions/booking_chat_action_state.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_model.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_notifier.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

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

  // BookingNotifier get _bookingNotifier => ref.read(bookingProvider.notifier);

  // ChatNotifier get _chatNotifier => ref.read(chatProvider.notifier);

  PriceNegotiationMutationNotifier _priceNegotiationNotifier() {
    return ref.read(priceNegotiationMutationProvider.notifier);
  }

  Future<void> refreshAfterNegotiation({
    required String chatId,
    required String bookingId,
  }) async {
    // The mutation notifier refreshes the exact negotiation and chat caches.
  }

  Future<void> refreshAfterBookingAction({
    required String chatId,
    required String bookingId,
  }) async {
    // Booking mutations coordinate booking and chat cache updates.
  }

  Future<void> refreshAfterReview({
    required String chatId,
    required String bookingId,
  }) async {
    await Future.wait([
      // _chatNotifier.reloadChat(chatId),
      // _bookingNotifier.getOwnerBookings(),
      // _bookingNotifier.getClientBookings(),
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
      action: () async {
        final result = await ref
            .read(bookingMutationProvider.notifier)
            .updateBookingStatus(
              id: bookingId,
              status: BookingStatus.confirmed,
            );

        return result.success;
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
      action: () async {
        final result = await ref
            .read(bookingMutationProvider.notifier)
            .updateBookingStatus(
              id: bookingId,
              status: BookingStatus.rejected,
              cancelReason: reason,
            );

        return result.success;
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
      action: () async {
        final result = await ref
            .read(bookingMutationProvider.notifier)
            .updateBookingStatus(
              id: bookingId,
              status: BookingStatus.cancelled,
              cancelReason: reason,
            );

        return result.success;
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
      action: () async {
        final result = await ref
            .read(bookingMutationProvider.notifier)
            .updateBookingStatus(
              id: bookingId,
              status: BookingStatus.completed,
            );

        return result.success;
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
          bookingId: bookingId,
          type: type,
          price: price,
          priceRate: priceRate.value,
          comment: comment,
          chatId: chatId,
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
        message: AppLocalizations.of(context)!.negotiationIdMissing,
        isError: true,
      );
      return;
    }

    await _run(
      context: context,
      submitId: "price:cancel",
      action: () async {
        await _priceNegotiationNotifier().cancelPriceNegotiation(
          id,
          bookingId: bookingId,
          chatId: chatId,
        );
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
        message: AppLocalizations.of(context)!.negotiationIdMissing,
        isError: true,
      );
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
          bookingId: bookingId,
          chatId: chatId,
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
    String? successMessage,
    String? failureMessage,
  }) async {
    if (state.isSubmitting) return;

    final l10n = AppLocalizations.of(context)!;

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

        AppSnackBar.show(
          message: failureMessage ?? l10n.actionFailed,
          isError: true,
        );
        return;
      }

      await onSuccess();

      state = state.copyWith(isSubmitting: false, submitId: null);

      if (!context.mounted) return;

      AppSnackBar.show(message: successMessage ?? l10n.saved, isSuccess: true);
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
