import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:prokat/features/chat/state/chat_provider.dart';
import 'package:prokat/features/offers/providers/offers_provider.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_response.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';

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
    await ref.read(priceNegotiationByOfferProvider(offerId).notifier).refresh();
    await ref.read(chatProvider.notifier).reloadChat(chatId);

    final bookingNotifier = ref.read(bookingProvider.notifier);
    final offersNotifier = ref.read(offersProvider.notifier);

    await Future.wait([
      bookingNotifier.getOwnerBookings(),
      bookingNotifier.getUserBookings(),
      offersNotifier.getOwnerOffers(),
      offersNotifier.getUserOffers(),
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
          .read(priceNegotiationByOfferProvider(offerId).notifier)
          .respond(negotiationId: negotiationId, response: response);
      await refreshAfterNegotiation(chatId: chatId, offerId: offerId);

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

  Future<void> cancel({
    required BuildContext context,
    required String chatId,
    required String offerId,
    required String negotiationId,
  }) async {
    try {
      await ref
          .read(priceNegotiationByOfferProvider(offerId).notifier)
          .cancelNegotiation(negotiationId);
      await refreshAfterNegotiation(chatId: chatId, offerId: offerId);

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
}

