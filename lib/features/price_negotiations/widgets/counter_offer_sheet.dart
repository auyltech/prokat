import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/utils/max_int_input_formatter.dart';
import 'package:prokat/core/widgets/action_bar_button.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/form_choice.dart';
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
    return await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CounterOfferSheet(
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
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _priceFocus = FocusNode();

  Future<void> onSubmit() async {
    final l10n = AppLocalizations.of(context)!;
    final price = int.tryParse(_priceController.text.trim());

    if (price == null || price <= 0) {
      AppSnackBar.show(message: l10n.enterValidPrice, isError: true);
      return;
    }

    final notifier = ref.read(priceNegotiationMutationProvider.notifier);

    try {
      await notifier.createCounterOffer(
        price: price,
        priceRate: widget.initialPriceRate?.value,
        comment: _commentController.text.trim(),
        type: widget.mode == AppMode.ownerMode
            ? "OWNER_COUNTER"
            : "CLIENT_COUNTER",
        bookingId: widget.bookingId,
        offerId: widget.offerId,
        chatId: widget.chatId,
      );

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
    _priceFocus.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    _commentController.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  String _formattedAmount(int? price) {
    if (price == null || price <= 0) return '— ₸';
    return '${formatPriceNumber(price)} ₸';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(priceNegotiationMutationProvider);
    final unit = widget.initialPriceRate == null
        ? ''
        : getPriceRateLabel(widget.initialPriceRate!, l10n);
    final yourPrice = int.tryParse(_priceController.text.trim());
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomInset),
      child: SingleChildScrollView(
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
              l10n.proposeYourPrice,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _PriceQuoteCard(
                    title: l10n.currentPrice,
                    amount: _formattedAmount(widget.initialPrice),
                    unit: unit,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PriceQuoteCard(
                    title: l10n.yourPrice,
                    amount: _formattedAmount(yourPrice),
                    unit: unit,
                    isEditing: _priceFocus.hasFocus,
                    onTap: () => _priceFocus.requestFocus(),
                    input: TextField(
                      controller: _priceController,
                      focusNode: _priceFocus,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        const MaxIntInputFormatter(_priceMax),
                      ],
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.transparent,
                        height: 1.2,
                      ),
                      cursorColor: theme.colorScheme.primary,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            JobCommentField(
              hint: l10n.requestCommentHint,
              controller: _commentController,
            ),
            const SizedBox(height: 16),
            ActionBarButton(
              label: l10n.sendPriceProposal,
              isEnabled: !state.isSubmitting,
              isLoading: state.isSubmitting,
              onPressed: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceQuoteCard extends StatelessWidget {
  const _PriceQuoteCard({
    required this.title,
    required this.amount,
    required this.unit,
    this.isEditing = false,
    this.onTap,
    this.input,
  });

  final String title;
  final String amount;
  final String unit;
  final bool isEditing;
  final VoidCallback? onTap;
  final Widget? input;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderColor = isEditing
        ? colorScheme.primary
        : colorScheme.outline.withValues(alpha: 0.5);

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: isEditing ? 1.5 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Text(
                    amount,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  if (input != null)
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: input,
                      ),
                    ),
                ],
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  unit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
