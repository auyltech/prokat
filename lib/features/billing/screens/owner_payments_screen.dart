import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/billing/widgets/active_equipment_tile.dart';
import 'package:prokat/features/billing/state/billing_provider.dart';
import 'package:prokat/features/billing/models/time_breakdown.dart';
import 'package:prokat/features/billing/widgets/consumption_chart.dart';
import 'package:prokat/features/billing/widgets/owner_payment_tile.dart';
import 'package:prokat/features/billing/widgets/volume_discount_tile.dart';
import 'package:prokat/features/billing/widgets/top_up_cta_tile.dart';
import 'package:prokat/features/equipment/state/equipment_provider.dart';
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

    Future.microtask(() async {
      await ref.read(billingProvider.notifier).getPricingTiers();
      await ref.read(billingProvider.notifier).getVolumeDiscounts();
      await ref.read(billingProvider.notifier).getOwnerTransactions();
      await ref.read(equipmentProvider.notifier).getOwnerEquipment();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final billingState = ref.watch(billingProvider);

    final secondsRemaining = billingState.accountBalance?.secondsRemaining ?? 0;
    final humanReadableTime = getTimeString(secondsRemaining);

    final onlineEquipment = ref.watch(equipmentProvider).onlineEquipmentCount;
    final volumeDiscountItems = billingState.volumeDiscounts;

    final dailyCost = billingState.getDailyCost(onlineEquipment);
    final timeForOnlineEquipment = getTimeString(
      billingState.getReminaingSeconds(onlineEquipment),
    );

    final payments = ref.watch(billingProvider).transactions;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(billingProvider.notifier).getVolumeDiscounts();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(billingState.getReminaingSeconds(onlineEquipment).toString()),
            // Main Balance Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Text(l10n.totalBalance, style: theme.textTheme.labelLarge),

                  const SizedBox(height: 8),

                  Text(
                    humanReadableTime,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),

                  const Divider(height: 32),

                  Text(
                    "≈ $timeForOnlineEquipment for $onlineEquipment equipment",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            ActiveEquipmentTile(
              equipmentCount: onlineEquipment,
              dailyCost: dailyCost,
            ),

            const SizedBox(height: 16),
            TopUpCtaTile(),

            const SizedBox(height: 16),
            Container(
              height: 300, // Set your fixed height here
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.billingTiers,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Badge(
                        label: Text(l10n.save15Percent),
                        backgroundColor: Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Expanded makes the list fill the remaining fixed height of the container
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets
                          .zero, // Removes default top/bottom ListView padding
                      itemCount: volumeDiscountItems.length,
                      itemBuilder: (context, index) {
                        // Using the tile we built in the previous step
                        return VolumeDiscountTile(
                          volumeCase: volumeDiscountItems[index],
                          isHighlighted:
                              index ==
                              volumeDiscountItems.length -
                                  1, // Highlight the best option (e.g., first item)
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // TODO: Fix Consumption Chart
            ConsumptionChart(),

            const SizedBox(height: 16),

            Text(
              l10n.paymentHistory,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: payments.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  OwnerPaymentTile(transaction: payments[index]),
            ),
          ],
        ),
      ),
    );
  }
}
