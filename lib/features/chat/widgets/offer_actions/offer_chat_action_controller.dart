import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
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
      AppToast.show(
        message: AppLocalizations.of(context)!.saved,
        type: AppToastType.success,
      );
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(
        message: e.toString().replaceFirst('Exception: ', ''),
        type: AppToastType.error,
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
      AppToast.show(
        message: AppLocalizations.of(context)!.saved,
        type: AppToastType.success,
      );
    } catch (error) {
      if (!context.mounted) return;
      AppToast.show(
        message: error.toString().replaceFirst('Exception: ', ''),
        type: AppToastType.error,
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
      AppToast.show(
        message: error.toString().replaceFirst('Exception: ', ''),
        type: AppToastType.error,
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
      AppToast.show(
        message: error.toString().replaceFirst('Exception: ', ''),
        type: AppToastType.error,
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
      AppToast.show(
        message: error.toString().replaceFirst('Exception: ', ''),
        type: AppToastType.error,
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
      AppToast.show(
        message: error.toString().replaceFirst('Exception: ', ''),
        type: AppToastType.error,
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
      AppToast.show(
        message: error.toString().replaceFirst('Exception: ', ''),
        type: AppToastType.error,
      );
    }
  }
}
