import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/owner/models/owner_status.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class OwnerStatusTile extends ConsumerStatefulWidget {
  const OwnerStatusTile({super.key});

  @override
  ConsumerState<OwnerStatusTile> createState() => _OwnerStatusTileState();
}

class _OwnerStatusTileState extends ConsumerState<OwnerStatusTile> {
  Future<void> _onToggleMethod(bool turnOnline) async {
    final newStatus = turnOnline ? OwnerStatus.online : OwnerStatus.offline;

    final result = await ref
        .read(ownerRegistrationMutationProvider.notifier)
        .updateOwnerStatus(ownerStatus: newStatus);

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    AppSnackBar.show(
      message: result
          ? (turnOnline ? l10n.youAreNowOnline : l10n.youAreNowOffline)
          : l10n.failedToggleStatus,
      isSuccess: result,
      isError: !result,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final currentStatus = ref
        .watch(ownerProfileProvider)
        .valueOrNull
        ?.onlineStatus;

    final isOnline = currentStatus == OwnerStatus.online;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400),
      ),
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
          activeThumbColor: const Color(
            0xFF0F5A56,
          ), // Matches your app's green theme
          onChanged: ref.watch(ownerRegistrationMutationProvider).isLoading
              ? null
              : _onToggleMethod,
        ),
      ),
    );
  }
}
