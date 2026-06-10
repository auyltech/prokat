import 'package:flutter/material.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/billing/models/transaction_model.dart';
import 'package:prokat/l10n/app_localizations.dart';

class OwnerPaymentTile extends StatelessWidget {
  final TransactionModel transaction;

  const OwnerPaymentTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final isTopUp = transaction.type != TransactionType.consumption;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isTopUp
                ? const Color(0xFFF14635).withValues(alpha: 0.1)
                : theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isTopUp
                ? Icons.account_balance_wallet_outlined
                : Icons.handshake_outlined,
            size: 20,
            color: isTopUp
                ? const Color(0xFFF14635)
                : theme.colorScheme.primary,
          ),
        ),
        title: Text(
          transaction.seconds.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          formatDate(date: transaction.createdAt),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "amount",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Text(
                l10n.repeat,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
