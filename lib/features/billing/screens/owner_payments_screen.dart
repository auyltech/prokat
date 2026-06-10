import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/billing/widgets/active_equipment_tile.dart';
import 'package:prokat/features/billing/state/billing_provider.dart';
import 'package:prokat/features/billing/models/time_breakdown.dart';
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final billingState = ref.watch(billingProvider);

    final secondsRemaining = billingState.accountBalance?.secondsRemaining ?? 0;
    final humanReadableTime = getTimeBreakDown(secondsRemaining);

    final onlineEquipment = ref.watch(equipmentProvider).onlineEquipmentCount;

    final volumeDiscountItems = billingState.volumeDiscounts;

    final pricePerEquipment = 50;
    final dailyCost = onlineEquipment * pricePerEquipment;

    final List<int> weeklyConsumption = [120, 150, 80, 200, 180, 450, 310];

    final payments = ref.watch(billingProvider).transactions;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(billingProvider.notifier).getVolumeDiscounts();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                    "${(secondsRemaining / 60).toStringAsFixed(0)} Min",
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),

                  const Divider(height: 32),

                  Text(
                    "≈ $humanReadableTime for $onlineEquipment equipment",
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
                              0, // Highlight the best option (e.g., first item)
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _consumptionChart(context, l10n, weeklyConsumption),

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

Widget _consumptionChart(
  BuildContext context,
  AppLocalizations l10n,
  List<int> weeklyData,
) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  final maxUsage = weeklyData
      .reduce((a, b) => a > b ? a : b)
      .clamp(1, double.infinity);

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.usageTrend,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              l10n.last7Days,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 120,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(weeklyData.length, (index) {
              final val = weeklyData[index];
              final percentage = val / maxUsage;

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 12,
                    height: 80 * percentage,
                    decoration: BoxDecoration(
                      color: index == weeklyData.length - 1
                          ? colorScheme.primary
                          : colorScheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    days[index],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: index == weeklyData.length - 1
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    ),
  );
}
