import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/billing/state/billing_provider.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_provider.dart';
import 'package:prokat/features/owner/models/owner_status.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
import 'package:prokat/features/owner/state/owner_registration_service.dart';
import 'package:prokat/l10n/app_localizations.dart';

import '../../../core/widgets/base_tile.dart';

class OwnerStatusTile extends ConsumerStatefulWidget {
  const OwnerStatusTile({super.key});

  @override
  ConsumerState<OwnerStatusTile> createState() => _OwnerStatusTileState();
}

class _OwnerStatusTileState extends ConsumerState<OwnerStatusTile> {
  bool _forcingOffline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_goOfflineIfNoCredit());
    });
  }

  Future<void> _goOfflineIfNoCredit() async {
    if (_forcingOffline) return;

    final billing = ref.read(billingProvider);
    if (!billing.isOutOfPaidMinutes) return;

    final currentStatus = ref
        .read(ownerProfileProvider)
        .valueOrNull
        ?.onlineStatus;
    if (currentStatus != OwnerStatus.online) return;

    _forcingOffline = true;
    try {
      await ref
          .read(ownerRegistrationMutationProvider.notifier)
          .updateOwnerStatus(ownerStatus: OwnerStatus.offline);
    } finally {
      _forcingOffline = false;
    }
  }

  Future<void> _onToggleMethod(bool turnOnline) async {
    final l10n = AppLocalizations.of(context)!;
    final billing = ref.read(billingProvider);

    if (turnOnline && billing.isOutOfPaidMinutes) {
      AppSnackBar.show(
        message: l10n.cannotGoOnlineWithZeroBalance,
        isError: true,
      );
      setState(() {});
      return;
    }

    final onlineEquipmentCount = ref
        .read(ownerEquipmentProvider.notifier)
        .onlineEquipmentCount;
    if (turnOnline && onlineEquipmentCount == 0) {
      AppSnackBar.show(
        message: l10n.cannotGoOnlineWithoutOnlineEquipment,
        isError: true,
      );
      setState(() {});
      return;
    }

    final newStatus = turnOnline ? OwnerStatus.online : OwnerStatus.offline;

    final result = await ref
        .read(ownerRegistrationMutationProvider.notifier)
        .updateOwnerStatus(ownerStatus: newStatus);

    if (!mounted) return;
    final errorCode = ref.read(ownerRegistrationMutationProvider).errorCode;
    final failedZeroBalance =
        !result && turnOnline && errorCode == ownerOnlineZeroBalanceCode;
    final failedNoEquipment =
        !result && turnOnline && errorCode == ownerOnlineNoEquipmentCode;

    AppSnackBar.show(
      message: result
          ? (turnOnline ? l10n.youAreNowOnline : l10n.youAreNowOffline)
          : (failedZeroBalance
                ? l10n.cannotGoOnlineWithZeroBalance
                : failedNoEquipment
                ? l10n.cannotGoOnlineWithoutOnlineEquipment
                : l10n.failedToggleStatus),
      isSuccess: result,
      isError: !result,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    ref.listen(billingProvider, (previous, next) {
      unawaited(_goOfflineIfNoCredit());
    });

    final currentStatus = ref
        .watch(ownerProfileProvider)
        .valueOrNull
        ?.onlineStatus;
    final isOutOfPaidMinutes = ref.watch(
      billingProvider.select((state) => state.isOutOfPaidMinutes),
    );

    final isOnline = currentStatus == OwnerStatus.online && !isOutOfPaidMinutes;

    return BaseTile(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          radius: 6,
          backgroundColor: isOnline ? Colors.green : Colors.grey,
        ),
        title: Text(
          isOnline ? l10n.youAreOnline : l10n.youAreOffline,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          isOnline ? l10n.readyToAcceptOrders : l10n.notAcceptingOrders,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        trailing: Switch.adaptive(
          value: isOnline,
          activeThumbColor: const Color(0xFF0F5A56),
          onChanged: ref.watch(ownerRegistrationMutationProvider).isLoading
              ? null
              : _onToggleMethod,
        ),
      ),
    );
  }
}
