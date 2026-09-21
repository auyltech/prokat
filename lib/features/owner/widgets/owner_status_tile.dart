import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/billing/state/billing_provider.dart';
import 'package:prokat/features/owner/models/owner_status.dart';
import 'package:prokat/features/owner/owner_offline_guard.dart';
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
          .updateOwnerStatus(ownerStatus: OwnerStatus.offline, notify: false);
    } finally {
      _forcingOffline = false;
    }
  }

  Future<void> _onToggleMethod(bool turnOnline) async {
    final l10n = AppLocalizations.of(context)!;

    if (turnOnline) {
      final block = ownerGoOnlineBlockReason(ref);
      if (block != OwnerGoOnlineBlockReason.none) {
        AppToast.show(
          message: ownerGoOnlineBlockMessage(l10n: l10n, reason: block),
          type: AppToastType.error,
        );
        setState(() {});
        return;
      }
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

    if (result) return;

    AppToast.show(
      message: failedZeroBalance
          ? l10n.cannotGoOnlineWithZeroBalance
          : failedNoEquipment
          ? l10n.cannotGoOnlineWithoutOnlineEquipment
          : l10n.failedToggleStatus,
      type: AppToastType.error,
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
    final hasProfile = ref.watch(ownerProfileProvider).valueOrNull != null;
    final isOutOfPaidMinutes = ref.watch(
      billingProvider.select((state) => state.isOutOfPaidMinutes),
    );
    final hasKnownBalance = ref.watch(
      billingProvider.select((state) => state.accountBalance != null),
    );

    final isOnline =
        currentStatus == OwnerStatus.online &&
        hasKnownBalance &&
        !isOutOfPaidMinutes;

    return BaseTile(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
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
          if (!isOnline && hasProfile)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                l10n.ownerOfflineMustBeOnlineToAccept,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}
