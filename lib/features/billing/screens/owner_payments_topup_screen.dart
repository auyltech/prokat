import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/features/billing/widgets/balance_summary_tile.dart';
import 'package:prokat/features/billing/state/billing_provider.dart';
import 'package:prokat/features/billing/widgets/owner_payment_tile.dart';
import 'package:prokat/features/user/widgets/price_tier_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

class OwnerPaymentsTopupScreen extends ConsumerStatefulWidget {
  const OwnerPaymentsTopupScreen({super.key});

  @override
  ConsumerState<OwnerPaymentsTopupScreen> createState() =>
      _OwnerPaymentsTopupScreenState();
}

class _OwnerPaymentsTopupScreenState
    extends ConsumerState<OwnerPaymentsTopupScreen> {
  String? selectedTierId;

  Future<void> submitTopUpRequest(String? id) async {
    if (id == null) return;

    final result = await ref
        .read(billingProvider.notifier)
        .topUpBalance(id: id);

    AppSnackBar.show(
      message: result ? "Top up added" : "Failed to complete to-up",
      isSuccess: result,
      isError: !result,
    );
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await ref.read(billingProvider.notifier).getPricingTiers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final billingState = ref.watch(billingProvider);
    final priceTiers = ref.watch(billingProvider).pricingTiers;

    final payments = ref.watch(billingProvider).transactions;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(billingProvider.notifier).getPricingTiers();
          await ref.read(billingProvider.notifier).getOwnerTransactions();
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            BalanceSummaryTile(
              isloading: billingState.isBalanceLoading,
              isError: false,
              secondsRemaining:
                  billingState.accountBalance?.secondsRemaining ?? 0,
              hasActiveBurn: false,
              onTap: () {},
            ),
            const SizedBox(height: 16),
            // --- 1. Package Selection ---
            Text(l10n.selectPackage, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
              ),
              itemCount: priceTiers.length,
              itemBuilder: (context, index) {
                return PriceTierTile(
                  isSelected: selectedTierId == priceTiers[index].id,
                  pricingTier: priceTiers[index],
                  onSelect: () {
                    setState(() {
                      selectedTierId = priceTiers[index].id;
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 32),

            // --- 2. Action Buttons ---
            PrimaryButton(
              label: "Submit Top Up Request",
              onPressed: selectedTierId == null || billingState.isSubmitting
                  ? null
                  : () => submitTopUpRequest(selectedTierId!),
              isLoading: billingState.isSubmitting,
            ),

            const SizedBox(height: 40),

            // --- 3. Recent History ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.recentPayments,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(onPressed: () {}, child: Text(l10n.viewAll)),
              ],
            ),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: payments.length,
              itemBuilder: (context, index) =>
                  OwnerPaymentTile(transaction: payments[index]),
            ),
          ],
        ),
      ),
    );
  }
}
