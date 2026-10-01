import 'account_balance_card.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/base_tile.dart';
import 'package:prokat/features/billing/state/billing_provider.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_provider.dart';
import 'package:prokat/features/owner/models/owner_status.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

const _showHistoryButton = false;

class BalanceTile extends ConsumerStatefulWidget {
  const BalanceTile({super.key});

  @override
  ConsumerState<BalanceTile> createState() => _BalanceTileState();
}

class _BalanceTileState extends ConsumerState<BalanceTile> {
  Timer? _balancePoll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(billingProvider).accountBalance == null) {
        unawaited(ref.read(billingProvider.notifier).getOwnerBalance());
      }
    });
    _balancePoll = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!mounted) return;
      unawaited(
        ref.read(billingProvider.notifier).getOwnerBalance(silent: true),
      );
    });
  }

  @override
  void dispose() {
    _balancePoll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final billingState = ref.watch(billingProvider);
    final ownerOnline =
        ref.watch(ownerProfileProvider).valueOrNull?.onlineStatus ==
        OwnerStatus.online;

    final onlineEquipment = ref.watch(
      ownerEquipmentProvider.select(
        (async) =>
            async.valueOrNull?.items.where((item) => item.isVisible).length ??
            0,
      ),
    );

    final billingActive = ownerOnline && billingState.hasActiveBurn;
    final burnRate = billingActive ? billingState.burnRateMinutesPerHour : 0;
    final hasBalanceError = billingState.errors.containsKey('balance');
    final balanceUnknown = billingState.accountBalance == null;

    // ── Error state (only when we have nothing to show) ──
    if (hasBalanceError && balanceUnknown) {
      return BaseTile(
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.red.shade900,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red.shade400,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.balanceUnavailable,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    billingState.errors['balance']!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppIconButton(
              icon: Icons.refresh,
              onTap: () => ref.read(billingProvider.notifier).getOwnerBalance(),
            ),
          ],
        ),
      );
    }

    // ── Loading / unknown wallet ──
    if (billingState.isBalanceLoading || balanceUnknown) {
      return const BaseTile(
        child: SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AccountBalanceCard(
      minutesRemaining: billingState.minutesRemaining,
      online: ownerOnline,
      equipmentCount: onlineEquipment,
      burnRate: burnRate.toDouble(),
      billingActive: billingActive,
      exhaustionLabel: billingState.formattedExhaustionTime(l10n.localeName),
      onTopUp: () => context.push(AppRoutes.ownerPayment),
      onHistory: _showHistoryButton
          ? () => context.push(AppRoutes.ownerPaymentHistory)
          : null,
    );
  }
}
