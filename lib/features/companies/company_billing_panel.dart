import 'package:prokat/features/user/widgets/owner_stat_card.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/features/owner/widgets/account_balance_card.dart';
import 'package:prokat/features/owner/widgets/account_status_card.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prokat/core/widgets/base_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

import 'company_service.dart';

class CompanyBillingPanel extends ConsumerStatefulWidget {
  final String companyId;
  const CompanyBillingPanel({super.key, required this.companyId});
  @override
  ConsumerState<CompanyBillingPanel> createState() =>
      _CompanyBillingPanelState();
}

class _CompanyBillingPanelState extends ConsumerState<CompanyBillingPanel> {
  Timer? timer;
  bool changing = false;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed)
        ref.invalidate(companyBillingProvider(widget.companyId));
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> toggle(bool value) async {
    setState(() => changing = true);
    try {
      await ref.read(companyServiceProvider).setOnline(widget.companyId, value);
      ref.invalidate(companyBillingProvider(widget.companyId));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is CompanyApiException && e.message != null
                  ? e.message!
                  : AppLocalizations.of(context)!.companyBillingFailed,
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => changing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return ref
        .watch(companyBillingProvider(widget.companyId))
        .when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, _) => BaseTile(
            child: Material(
              type: MaterialType.transparency,
              child: ListTile(
                title: Text(l.balanceUnavailable),
                trailing: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () =>
                      ref.invalidate(companyBillingProvider(widget.companyId)),
                ),
              ),
            ),
          ),
          data: (data) {
            final seconds = (data['secondsRemaining'] as num).toDouble();
            final online = data['online'] == true;
            final rate = (data['burnRateMinutesPerHour'] as num).toDouble();
            final end = DateTime.tryParse('${data['estimatedExhaustionAt']}')
                ?.toLocal();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OwnerStatCard(
                        icon: LucideIcons.truck,
                        title: l.navEquipment,
                        firstLabel: l.statTotal,
                        firstValue:
                            '${data['fleetTotalCount'] ?? data['fleetCount'] ?? 0}',
                        secondLabel: l.statOnline,
                        secondValue: online
                            ? '${data['fleetCount'] ?? 0}'
                            : '0',
                        onTap: () => context.go(
                          '/company-cabinet/${widget.companyId}/fleet',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OwnerStatCard(
                        icon: LucideIcons.package,
                        title: l.navOrders,
                        firstLabel: l.statActive,
                        firstValue: '${data['activeOrders'] ?? 0}',
                        secondLabel: l.statCompleted,
                        secondValue: '${data['completedOrders'] ?? 0}',
                        onTap: () => context.go(
                          '/company-cabinet/${widget.companyId}/orders',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                AccountBalanceCard(
                  title: l.companyBalance,
                  zeroBalanceText: l.cannotGoOnlineWithZeroBalance,
                  minutesRemaining: (seconds / 60).floor(),
                  online: online,
                  equipmentCount: (data['fleetCount'] as num? ?? 0).toInt(),
                  burnRate: rate,
                  billingActive: online && rate > 0,
                  exhaustionLabel: end == null
                      ? null
                      : DateFormat('d MMM, HH:mm', l.localeName).format(end),
                  onTopUp: () =>
                      AppToast.show(message: l.paymentFeatureComingSoon),
                ),
                const SizedBox(height: 20),
                AccountStatusCard(
                  activeColor: Theme.of(context).colorScheme.primary,
                  online: online,
                  changing: changing,
                  title: online ? l.companyOnline : l.companyOffline,
                  onChanged: toggle,
                ),
              ],
            );
          },
        );
  }
}
