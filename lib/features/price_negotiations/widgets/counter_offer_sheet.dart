import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/widgets/action_bar_button.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';

class CounterOfferSheet extends ConsumerStatefulWidget {
  final String? bookingId;
  final String? offerId;
  final int initialPrice;
  final String? initialPriceRate;
  final String mode;

  const CounterOfferSheet({
    super.key,
    this.bookingId,
    this.offerId,
    required this.initialPrice,
    this.initialPriceRate,
    required this.mode,
  });

  @override
  ConsumerState<CounterOfferSheet> createState() => _CounterOfferSheetState();
}

class _CounterOfferSheetState extends ConsumerState<CounterOfferSheet> {
  late final TextEditingController _priceController;
  final TextEditingController _commentController = TextEditingController();
  String? _priceRate;

  Future<void> onSubmit() async {
    final price = int.tryParse(_priceController.text.trim());

    if (price == null || price <= 0) {
      AppSnackBar.show(context, message: 'Enter a valid price', isError: true);
      return;
    }

    final notifier = ref.read(priceNegotiationProvider.notifier);

    try {
      // use booking notifier to create counter offer
      await notifier.createCounterOffer(
        price: price,
        priceRate: _priceRate,
        comment: _commentController.text.trim(),
        type: widget.mode == "owner" ? "OWNER_COUNTER" : "CLIENT_COUNTER",
        bookingId: widget.bookingId,
        offerId: widget.offerId,
      );

      // use chat notifier to create counter offer
      // await controller.createCounterOffer(
      //   context: context,
      //   chatId: chatId,
      //   bookingId: booking.id,
      //   price: booking.price,
      //   priceRate: booking.priceRate as PriceRateOption,
      //   comment: "comment",
      //   type: "OWNER_COUNTER",
      // );

      // await controller.refreshAfterNegotiation(
      //   chatId: chatId,
      //   bookingId: booking.id,
      // );

      if (mounted && context.canPop()) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted && context.canPop()) {
        AppSnackBar.show(
          context,
          message: e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.initialPrice.toString(),
    );
    _priceRate = widget.initialPriceRate;
  }

  @override
  void dispose() {
    _priceController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final state = ref.watch(priceNegotiationProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16 + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Counter offer',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Price',
              suffixText: 'KZT',
            ),
          ),
          const SizedBox(height: 12),

          if (((_priceRate ?? '').trim()).isNotEmpty)
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Rate'),
              child: Text(_priceRate ?? ''),
            ),

          const SizedBox(height: 12),

          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Comment (optional)'),
          ),

          const SizedBox(height: 16),

          ActionBarButton(
            label: "Send",
            isEnabled: !state.isSubmitting,
            isLoading: state.isSubmitting,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}
