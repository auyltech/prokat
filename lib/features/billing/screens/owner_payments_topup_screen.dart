import 'dart:async';

import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_label_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/constants/app_colors.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/ui_kit/toasts/app_toast.dart';
import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_elevated_button.dart';
import 'package:prokat/features/billing/models/time_breakdown.dart';
import 'package:prokat/features/billing/state/billing_provider.dart';
import 'package:prokat/features/billing/utils/billing_display.dart';
import 'package:prokat/features/billing/widgets/owner_payment_tile.dart';
import 'package:prokat/features/billing/widgets/price_tier_tile.dart';
import 'package:prokat/features/billing/widgets/volume_discount_tile.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_provider.dart';
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

  void submitTopUpRequest(String? id) {
    if (id == null) return;
    final l10n = AppLocalizations.of(context)!;

    AppToast.show(message: l10n.paymentFeatureComingSoon);
  }

  @override
  void initState() {
    super.initState();

    unawaited(
      Future.microtask(() async {
        await ref.read(billingProvider.notifier).loadDashboard();
        await ref.read(ownerEquipmentProvider.notifier).refresh();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final billingState = ref.watch(billingProvider);
    final priceTiers = sortedTopUpPackages(billingState.pricingTiers);
    final volumeDiscountItems = [...billingState.volumeDiscounts]
      ..sort((a, b) => a.onlineCount.compareTo(b.onlineCount));
    final payments = billingState.transactions;
    final recentPayments = payments.take(10).toList();

    final onlineEquipment = ref.watch(
      ownerEquipmentProvider.select(
        (async) =>
            async.valueOrNull?.items.where((item) => item.isVisible).length ??
            0,
      ),
    );
    final estimateCount = estimateOnlineCount(onlineEquipment);
    final remainingTime = getCompactTimeString(
      billingState.remainingWallClockSeconds(onlineCount: estimateCount),
      l10n,
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(billingProvider.notifier).loadDashboard();
          await ref.read(ownerEquipmentProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                children: [
                  Text(
                    l10n.remainingTime,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${formatPriceNumber(billingState.minutesRemaining)} ${l10n.minutesUnit}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.teal800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      l10n.remainingAtOnlineEquipment(
                        remainingTime,
                        estimateCount,
                      ),
                      maxLines: 1,
                      softWrap: false,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(l10n.selectPackage, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            if (billingState.isTiersLoading && priceTiers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.35,
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

            const SizedBox(height: 24),

            AppElevatedButton(
              title: l10n.submitTopUpRequest,
              onTap: selectedTierId == null || billingState.isSubmitting
                  ? null
                  : () => submitTopUpRequest(selectedTierId!),
              isLoading: billingState.isSubmitting,
            ),

            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.minuteConsumption,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Badge(
                  label: Text(l10n.save15Percent),
                  backgroundColor: Colors.green,
                  textColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (billingState.isDiscountsLoading && volumeDiscountItems.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ...List.generate(volumeDiscountItems.length, (index) {
                return VolumeDiscountTile(
                  volumeCase: volumeDiscountItems[index],
                  isHighlighted: index == volumeDiscountItems.length - 1,
                );
              }),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.operationHistory,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppLabelButton(
                  title: l10n.viewAll,
                  onTap: () => context.push(AppRoutes.ownerPaymentHistory),
                  variant: AppLabelButtonVariant.text,
                ),
              ],
            ),
            if (recentPayments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  l10n.noHistoryFound,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentPayments.length,
                itemBuilder: (context, index) =>
                    OwnerPaymentTile(transaction: recentPayments[index]),
              ),
          ],
        ),
      ),
    );
  }
}
