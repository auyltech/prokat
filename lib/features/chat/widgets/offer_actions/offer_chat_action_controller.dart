import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_model.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';
import 'package:prokat/features/requests/providers/request_mutation_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

final offerChatActionControllerProvider = Provider<OfferChatActionController>((
  ref,
) {
  return OfferChatActionController(ref);
});

class OfferChatActionController {
  final Ref ref;

  OfferChatActionController(this.ref);

  Future<void> respond({
    required BuildContext context,
    required String chatId,
    required String offerId,
    required String negotiationId,
    required PriceNegotiationResponse response,
  }) async {
    try {
      await ref
          .read(priceNegotiationMutationProvider.notifier)
          .respondToPriceNegotiation(
            negotiationId: negotiationId,
            response: response,
            offerId: offerId,
            chatId: chatId,
          );
      if (!context.mounted) return;
      AppSnackBar.show(
        message: AppLocalizations.of(context)!.saved,
        isSuccess: true,
      );
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
          .read(priceNegotiationMutationProvider.notifier)
          .cancelPriceNegotiation(
            negotiationId,
            offerId: offerId,
            chatId: chatId,
          );
      if (!context.mounted) return;
      AppSnackBar.show(
        message: AppLocalizations.of(context)!.saved,
        isSuccess: true,
      );
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
    String? requestId,
  }) async {
    try {
      await ref
          .read(offerMutationProvider.notifier)
          .acceptOffer(offerId, chatId: chatId, requestId: requestId);
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
    String? requestId,
  }) async {
    try {
      await ref
          .read(offerMutationProvider.notifier)
          .rejectOffer(offerId, chatId: chatId, requestId: requestId);
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
    String? requestId,
  }) async {
    try {
      await ref
          .read(offerMutationProvider.notifier)
          .cancelOffer(offerId, chatId: chatId, requestId: requestId);
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
      await ref.read(requestMutationProvider.notifier).cancelRequest(requestId);
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
    String? requestId,
  }) async {
    try {
      await ref
          .read(offerMutationProvider.notifier)
          .cancelOffer(offerId, chatId: chatId, requestId: requestId);
    } catch (error) {
      if (!context.mounted) return;
      AppSnackBar.show(
        message: error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }
}
