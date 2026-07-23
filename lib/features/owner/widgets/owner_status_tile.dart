import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/owner/models/owner_status.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';

class OwnerStatusTile extends ConsumerStatefulWidget {
  const OwnerStatusTile({super.key});

  @override
  ConsumerState<OwnerStatusTile> createState() => _OwnerStatusTileState();
}

class _OwnerStatusTileState extends ConsumerState<OwnerStatusTile> {
  Future<void> _onToggleMethod(bool turnOnline) async {
    final newStatus = turnOnline ? OwnerStatus.online : OwnerStatus.offline;

    final result = await ref
        .read(ownerRegistrationProvider.notifier)
        .updateOwnerStatus(ownerStatus: newStatus);

    AppSnackBar.show(
      message: result
          ? "You are now ${newStatus.name}"
          : "Failed to toggle status",
      isSuccess: result,
      isError: !result,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentStatus = ref
        .watch(ownerRegistrationProvider)
        .ownerProfile
        ?.onlineStatus;

    final isOnline = currentStatus == OwnerStatus.online;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 6,
          backgroundColor: isOnline ? Colors.green : Colors.grey,
        ),
        title: Text(
          isOnline ? 'You are Online' : 'You are Offline',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          isOnline ? 'Ready to accept orders' : 'Not accepting orders',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        trailing: Switch.adaptive(
          value: isOnline,
          activeThumbColor: const Color(
            0xFF0F5A56,
          ), // Matches your app's green theme
          onChanged: ref.watch(ownerRegistrationProvider).isLoading
              ? null
              : _onToggleMethod,
        ),
      ),
    );
  }
}
