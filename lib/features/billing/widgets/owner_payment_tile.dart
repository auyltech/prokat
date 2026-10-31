import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/billing/models/time_breakdown.dart';
import 'package:prokat/features/billing/models/transaction_model.dart';
import 'package:prokat/l10n/app_localizations.dart';

class OwnerPaymentTile extends StatelessWidget {
  final TransactionModel transaction;

  const OwnerPaymentTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flow = ProkatFlowScope.maybeOf(context);
    final l10n = AppLocalizations.of(context)!;

    final isTopUp = transaction.type == TransactionType.topup;
    final isConsumption = transaction.type == TransactionType.consumption;
    final isGift = transaction.type == TransactionType.freecredit;

    return Card(
      elevation: 0,
      color: flow?.surface ?? theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: flow?.border ?? theme.dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isTopUp
                ? Colors.green[50]
                : isConsumption
                ? Colors.red[50]
                : isGift
                ? const Color(0xFFF3E8FF)
                : Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            isTopUp
                ? LucideIcons.wallet
                : isConsumption
                ? LucideIcons.receiptText
                : isGift
                ? LucideIcons.gift
                : LucideIcons.creditCard,
            size: 24,
            color: isTopUp
                ? Colors.green[800]
                : isConsumption
                ? Colors.red[600]
                : isGift
                ? const Color(0xFF7C3AED)
                : Colors.grey[800],
          ),
        ),
        title: Text(
          getTimeString(transaction.seconds, l10n),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          isGift
              ? '${l10n.transactionGift} · ${formatDateTime(transaction.createdAt, transaction.createdAt, locale: l10n.localeName)}'
              : formatDateTime(
                  transaction.createdAt,
                  transaction.createdAt,
                  locale: l10n.localeName,
                ),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: transaction.type == TransactionType.topup
            ? AppLabelButton(
                title: l10n.repeat,
                onTap: () {},
                variant: AppLabelButtonVariant.text,
              )
            : null,
      ),
    );
  }
}
