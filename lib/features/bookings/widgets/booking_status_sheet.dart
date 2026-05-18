import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:prokat/features/chat/state/chat_provider.dart';

class BookingStatusSheet extends ConsumerWidget {
  final BookingModel booking;

  const BookingStatusSheet({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(bookingProvider.notifier);
    final chatNotifier = ref.read(chatProvider.notifier);

    final currentStatus = booking.workStatus; //booking.workStatus;
    final isStarted = currentStatus.level >= WorkStatus.started.level;

    final availableStatuses = isStarted
        ? [WorkStatus.stopped, WorkStatus.completed, WorkStatus.cancelled]
        : [
            WorkStatus.onMyWay,
            WorkStatus.onSite,
            WorkStatus.started,
            WorkStatus.postponed,
          ];

    final validStatuses = availableStatuses
        .where((s) => canTransition(currentStatus, s))
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Text("Update Work Status", style: theme.textTheme.titleMedium),

            const SizedBox(height: 16),

            ...validStatuses.map((status) {
              return _StatusTile(
                status: status,
                isCurrent: status == currentStatus,
                isDanger:
                    status == WorkStatus.cancelled ||
                    status == WorkStatus.stopped,
                onTap: () async {
                  // Update backend & send notification to client
                  final res = await notifier.updateBookingWorkStatus(
                    id: booking.id,
                    workStatus: status.name,
                  );

                  final chatId = booking.chatId;
                  if ((chatId ?? '').isNotEmpty) {
                    await chatNotifier.reloadChat(chatId!);
                  }

                  if (!context.mounted) return;

                  // 3. Close sheet
                  Navigator.pop(context);

                  if (res) {
                    AppSnackBar.show(
                      context,
                      message: "Status updated",
                      isSuccess: true,
                    );
                  } else {
                    AppSnackBar.show(
                      context,
                      message: "Failed to save status",
                      isError: true,
                    );
                  }
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  final WorkStatus status;
  final VoidCallback onTap;
  final bool isDanger;
  final bool isCurrent;

  const _StatusTile({
    required this.status,
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent
                ? color.withValues(alpha: 0.3)
                : color.withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(status.label, style: theme.textTheme.bodyMedium),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: color.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
