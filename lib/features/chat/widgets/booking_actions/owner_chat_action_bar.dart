import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/widgets/booking_status_sheet.dart';
import 'package:prokat/features/bookings/widgets/cancel_booking_sheet.dart';
import 'package:prokat/features/chat/widgets/booking_actions/booking_chat_action_controller.dart';
import 'package:prokat/features/chat/widgets/booking_actions/booking_chat_action_models.dart';
import 'package:prokat/features/chat/widgets/booking_actions/booking_chat_action_resolver.dart';

class OwnerChatActionBar extends ConsumerWidget {
  final String chatId;
  final BookingModel booking;

  const OwnerChatActionBar({
    super.key,
    required this.chatId,
    required this.booking,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(bookingChatActionControllerProvider);
    const resolver = BookingChatActionResolver();

    final resolution = resolver.resolve(
      booking: booking,
      role: BookingChatRole.owner,
      now: DateTime.now(),
    );

    if (resolution.primaryAction == null &&
        resolution.secondaryActions.isEmpty &&
        resolution.overflowActions.isEmpty) {
      return _StatusOnlyBar(text: resolution.statusText);
    }

    final primary = resolution.primaryAction;
    final secondary = resolution.secondaryActions;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            resolution.statusText,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (secondary.isNotEmpty)
                Expanded(
                  child: OutlinedButton(
                    onPressed: secondary.first.isEnabled
                        ? () => _runAction(
                              context: context,
                              ref: ref,
                              controller: controller,
                              action: secondary.first,
                            )
                        : null,
                    child: Text(secondary.first.label),
                  ),
                ),
              if (secondary.isNotEmpty && primary != null) const SizedBox(width: 12),
              if (primary != null)
                Expanded(
                  child: ElevatedButton(
                    onPressed: primary.isEnabled
                        ? () => _runAction(
                              context: context,
                              ref: ref,
                              controller: controller,
                              action: primary,
                            )
                        : null,
                    child: Text(primary.label),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _runAction({
    required BuildContext context,
    required WidgetRef ref,
    required BookingChatActionController controller,
    required BookingChatActionVm action,
  }) async {
    final theme = Theme.of(context);

    switch (action.id) {
      case BookingChatActionId.acceptBooking:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            title: const Text('Accept order?'),
            content: const Text('Confirm accepting this booking.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Accept'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        await controller.runAction(
          context: context,
          chatId: chatId,
          bookingId: booking.id,
          actionId: action.id,
        );
        return;
      case BookingChatActionId.rejectBooking:
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: theme.colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) =>
              CancelBookingSheet(booking: booking, useCase: 'owner'),
        );
        return;
      case BookingChatActionId.updateWorkStatus:
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: theme.colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => BookingStatusSheet(booking: booking),
        );
        return;
      case BookingChatActionId.markWorkCompleted:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            title: const Text('Mark completed?'),
            content: const Text('Client will need to confirm completion.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Mark completed'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        await controller.runAction(
          context: context,
          chatId: chatId,
          bookingId: booking.id,
          actionId: action.id,
        );
        return;
      default:
        return;
    }
  }
}
class _StatusOnlyBar extends StatelessWidget {
  final String text;

  const _StatusOnlyBar({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
