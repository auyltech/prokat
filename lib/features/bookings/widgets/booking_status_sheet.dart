import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/bookings/providers/booking_mutation_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class BookingStatusSheet extends ConsumerWidget {
  final BookingModel booking;

  const BookingStatusSheet({super.key, required this.booking});

  static Future<bool> show(
    BuildContext context, {
    required BookingModel booking,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final updated = await AppBottomSheet.show<bool>(
      context,
      title: l10n.updateWorkStatus,
      contentBuilder: (context) => BookingStatusSheet(booking: booking),
    );

    return updated ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(bookingMutationProvider.notifier);

    final currentStatus = booking.workStatus;
    final validStatuses = nextWorkStatuses(currentStatus);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.s04$xs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...validStatuses.map((status) {
            return _StatusTile(
              label: status.sheetLabel(l10n, current: currentStatus),
              isCurrent: status == currentStatus,
              isDanger: status == WorkStatus.stopped,
              onTap: () async {
                final result = await notifier.updateBookingWorkStatus(
                  id: booking.id,
                  workStatus: status,
                );

                final chatId = booking.chatId;
                if ((chatId ?? '').isNotEmpty) {
                  // await chatNotifier.reloadChat(chatId!);
                }

                if (!context.mounted) return;

                Navigator.pop(context, result.success);

                AppToast.show(
                  message: result.success
                      ? l10n.statusUpdated
                      : l10n.failedSaveStatus,
                  type: result.success
                      ? AppToastType.success
                      : AppToastType.error,
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDanger;
  final bool isCurrent;

  const _StatusTile({
    required this.label,
    required this.onTap,
    this.isDanger = false,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color = isDanger
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCurrent
                    ? color.withValues(alpha: 0.3)
                    : color.withValues(alpha: 0.7),
              ),
            ),
            child: Row(
              children: [
                Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: color.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
