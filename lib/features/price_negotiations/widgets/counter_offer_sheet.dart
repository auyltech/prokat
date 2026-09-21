import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/utils/max_int_input_formatter.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

const _priceMax = 100000;

class CounterOfferSheet extends ConsumerStatefulWidget {
  final String? bookingId;
  final String? offerId;
  final String? chatId;
  final int? initialPrice;
  final PriceRateOption? initialPriceRate;
  final AppMode mode;

  const CounterOfferSheet({
    super.key,
    this.bookingId,
    this.offerId,
    this.chatId,
    this.initialPrice,
    this.initialPriceRate,
    required this.mode,
  });

  static Future<void> show(
    BuildContext context, {
    String? bookingId,
    String? offerId,
    String? chatId,
    int? initialPrice,
    PriceRateOption? initialPriceRate,
    required AppMode mode,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    await AppBottomSheet.show<void>(
      context,
      title: l10n.proposeYourPrice,
      contentBuilder: (context) => CounterOfferSheet(
        bookingId: bookingId,
        offerId: offerId,
        chatId: chatId,
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
  late final TextEditingController _currentPriceController;
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialPrice;
    _currentPriceController = TextEditingController(
      text: initial != null && initial > 0 ? formatPriceNumber(initial) : '',
    );
  }

  @override
  void dispose() {
    _currentPriceController.dispose();
    _priceController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> onSubmit() async {
    final l10n = AppLocalizations.of(context)!;
    final price = int.tryParse(_priceController.text.trim());

    if (price == null || price <= 0) {
      AppToast.show(message: l10n.enterValidPrice, type: AppToastType.error);
      return;
    }

    final notifier = ref.read(priceNegotiationMutationProvider.notifier);

    try {
      await notifier.createCounterOffer(
        price: price,
        priceRate: widget.initialPriceRate?.value,
        comment: _commentController.text.trim(),
        type: widget.mode == AppMode.ownerMode
            ? 'OWNER_COUNTER'
            : 'CLIENT_COUNTER',
        bookingId: widget.bookingId,
        offerId: widget.offerId,
        chatId: widget.chatId,
      );

      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          message: e.toString().replaceFirst('Exception: ', ''),
          type: AppToastType.error,
        );
      }
    }
  }

  Widget _currencyPrefix(BuildContext context) {
    return Text(
      '₸',
      style: AppFonts.body16SemiBold(context)
          .copyWith(color: context.colors.text.secondary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(priceNegotiationMutationProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.s08$sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppDimens.s16$base,
        children: [
          AppTextField(
            title: l10n.currentPrice,
            controller: _currentPriceController,
            readOnly: true,
            hint: '—',
            prefix: _currencyPrefix(context),
          ),
          AppTextField(
            title: l10n.yourPrice,
            controller: _priceController,
            hint: '0',
            isRequired: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              const MaxIntInputFormatter(_priceMax),
            ],
            prefix: _currencyPrefix(context),
          ),
          AppTextArea(
            title: l10n.comments,
            controller: _commentController,
            hint: l10n.requestCommentHint,
            minLines: 2,
            maxLines: 4,
          ),
          AppElevatedButton(
            title: l10n.sendPriceProposal,
            isLoading: state.isSubmitting,
            onTap: state.isSubmitting ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}
