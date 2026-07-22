import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/widgets/action_bar_button.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/bookings/widgets/price_rate_selector.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';

class CounterOfferSheet extends ConsumerStatefulWidget {
  final String? bookingId;
  final String? offerId;
  final int? initialPrice;
  final PriceRateOption? initialPriceRate;
  final AppMode mode;

  const CounterOfferSheet({
    super.key,
    this.bookingId,
    this.offerId,
    this.initialPrice,
    this.initialPriceRate,
    required this.mode,
  });

  static Future<void> show(
    BuildContext context, {
    String? bookingId,
    String? offerId,
    int? initialPrice,
    PriceRateOption? initialPriceRate,
    required AppMode mode,
  }) async {
    return await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CounterOfferSheet(
        bookingId: bookingId,
        offerId: offerId,
        initialPrice: initialPrice,
        initialPriceRate: initialPriceRate,
        mode: mode,
      ),
    );
  }

  @override
  ConsumerState<CounterOfferSheet> createState() => _CounterOfferSheetState();
}

class _CounterOfferSheetState extends ConsumerState<CounterOfferSheet> {
  late final TextEditingController _priceController;
  final TextEditingController _commentController = TextEditingController();
  PriceRateOption? _priceRate;

  Future<void> onSubmit() async {
    final price = int.tryParse(_priceController.text.trim());

    if (price == null || price <= 0) {
      AppSnackBar.show(message: 'Enter a valid price', isError: true);
      return;
    }

    final notifier = ref.read(priceNegotiationProvider.notifier);

    try {
      // use booking notifier to create counter offer
      await notifier.createCounterOffer(
        price: price,
        priceRate: _priceRate?.value,
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
      padding: const EdgeInsets.only(bottom: 24, top: 12, left: 24, right: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

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

          PriceRateSelector(
            initialValue: _priceRate,
            onChanged: (newRate) {
              setState(() {
                _priceRate = newRate;
              });
            },
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
