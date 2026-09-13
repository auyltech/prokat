import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/billing/state/billing_provider.dart';
import 'package:prokat/features/billing/widgets/owner_payment_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

class OwnerPaymentsScreen extends ConsumerStatefulWidget {
  const OwnerPaymentsScreen({super.key});

  @override
  ConsumerState<OwnerPaymentsScreen> createState() =>
      _OwnerPaymentsScreenState();
}

class _OwnerPaymentsScreenState extends ConsumerState<OwnerPaymentsScreen> {
  @override
  void initState() {
    super.initState();

    unawaited(
      Future.microtask(() async {
        await ref.read(billingProvider.notifier).getOwnerTransactions();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final billingState = ref.watch(billingProvider);
    final payments = billingState.transactions;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(billingProvider.notifier).getOwnerTransactions(),
        child: billingState.isTransactionsLoading && payments.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (payments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Text(
                          l10n.noHistoryFound,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: payments.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 2),
                      itemBuilder: (context, index) =>
                          OwnerPaymentTile(transaction: payments[index]),
                    ),
                ],
              ),
      ),
    );
  }
}
