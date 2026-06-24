import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:prokat/features/chat/state/chat_provider.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_model.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';
import 'package:prokat/features/requests/state/request_provider.dart';

final offerChatActionControllerProvider = Provider<OfferChatActionController>((
  ref,
) {
  return OfferChatActionController(ref);
});

class OfferChatActionController {
  final Ref ref;

  OfferChatActionController(this.ref);

  Future<void> refreshAfterNegotiation({
    required String chatId,
    required String offerId,
  }) async {
    await ref.read(priceNegotiationProvider.notifier).getPriceNegotiations();
    await ref.read(chatProvider.notifier).reloadChat(chatId);

    final bookingNotifier = ref.read(bookingProvider.notifier);
    final offersNotifier = ref.read(offersProvider.notifier);

    await Future.wait([
      bookingNotifier.getOwnerBookings(),
      bookingNotifier.getClientBookings(),
      offersNotifier.getOwnerOffers(),
      offersNotifier.getClientOffers(),
    ]);
  }

  Future<void> respond({
    required BuildContext context,
    required String chatId,
    required String offerId,
    required String negotiationId,
    required PriceNegotiationResponse response,
  }) async {
    try {
      await ref
          .read(priceNegotiationProvider.notifier)
          .respondToPriceNegotiation(
            negotiationId: negotiationId,
            response: response,
          );
      await refreshAfterNegotiation(chatId: chatId, offerId: offerId);

      if (!context.mounted) return;
      AppSnackBar.show(message: 'Saved', isSuccess: true);
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.show(
        message: e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> cancel({
    required BuildContext context,
    required String chatId,
    required String offerId,
    required String negotiationId,
  }) async {
    try {
      await ref
          .read(priceNegotiationProvider.notifier)
          .cancelPriceNegotiation(negotiationId);
      await refreshAfterNegotiation(chatId: chatId, offerId: offerId);

      if (!context.mounted) return;
      AppSnackBar.show(message: 'Saved', isSuccess: true);
    } catch (error) {
      if (!context.mounted) return;
      AppSnackBar.show(
        message: error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> acceptRequestOffer({
    required BuildContext context,
    required String chatId,
    required String offerId,
  }) async {
    try {
      await ref.read(offersProvider.notifier).acceptOffer(offerId);

      await refreshAfterNegotiation(chatId: chatId, offerId: offerId);
    } catch (error) {
      if (!context.mounted) return;
      AppSnackBar.show(
        message: error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> rejectRequestOffer({
    required BuildContext context,
    required String chatId,
    required String offerId,
  }) async {
    try {
      await ref.read(offersProvider.notifier).rejectOffer(offerId);

      await refreshAfterNegotiation(chatId: chatId, offerId: offerId);
    } catch (error) {
      if (!context.mounted) return;
      AppSnackBar.show(
        message: error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> cancelRequestOffer({
    required BuildContext context,
    required String chatId,
    required String offerId,
  }) async {
    try {
      await ref.read(offersProvider.notifier).cancelOffer(offerId);

      await refreshAfterNegotiation(chatId: chatId, offerId: offerId);
    } catch (error) {
      if (!context.mounted) return;
      AppSnackBar.show(
        message: error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> cancelRequest({
    required BuildContext context,
    required String chatId,
    required String requestId,
  }) async {
    try {
      await ref.read(requestProvider.notifier).cancelRequest(requestId);

      await refreshAfterNegotiation(chatId: chatId, offerId: "");
    } catch (error) {
      if (!context.mounted) return;
      AppSnackBar.show(
        message: error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> cancelOffer({
    required BuildContext context,
    required String chatId,
    required String offerId,
  }) async {
    try {
      await ref.read(offersProvider.notifier).cancelOffer(offerId);

      await refreshAfterNegotiation(chatId: chatId, offerId: "");
    } catch (error) {
      if (!context.mounted) return;
      AppSnackBar.show(
        message: error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }
}
