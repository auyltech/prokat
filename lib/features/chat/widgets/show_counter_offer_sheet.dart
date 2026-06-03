import 'package:flutter/material.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/features/price_negotiations/widgets/counter_offer_sheet.dart';

Future<void> showCounterOfferSheet({
  required BuildContext context,
  required String chatId,
  required String bookingId,
  String? offerId,
  required int initialPrice,
  required PriceRateOption initialPriceRate,
  required String counterType,
}) async {
  final theme = Theme.of(context);

  await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: theme.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return CounterOfferSheet(
        bookingId: bookingId,
        offerId: offerId,
        initialPrice: initialPrice,
        initialPriceRate: initialPriceRate.value,
        counterType: counterType,
      );
    },
  );
}
