import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:prokat/features/chat/state/chat_provider.dart';
import 'package:prokat/features/chat/widgets/booking_actions/booking_chat_action_models.dart';

final bookingChatActionControllerProvider =
    Provider<BookingChatActionController>((ref) {
      return BookingChatActionController(ref);
    });

class BookingChatActionController {
  final Ref ref;

  BookingChatActionController(this.ref);

  Future<void> runAction({
    required BuildContext context,
    required String chatId,
    required String bookingId,
    required BookingChatActionId actionId,
    WorkStatus? workStatus,
    String? reason,
  }) async {
    final bookingNotifier = ref.read(bookingProvider.notifier);
    final chatNotifier = ref.read(chatProvider.notifier);

    try {
      final ok = await switch (actionId) {
        BookingChatActionId.acceptBooking =>
          bookingNotifier.updateBookingStatus(
            id: bookingId,
            status: BookingStatus.confirmed.name,
          ),

        BookingChatActionId.rejectBooking =>
          bookingNotifier.updateBookingStatus(
            id: bookingId,
            status: BookingStatus.rejected.name,
            workStatus: reason,
          ),

        BookingChatActionId.cancelBooking =>
          bookingNotifier.updateBookingStatus(
            id: bookingId,
            status: BookingStatus.cancelled.name,
            workStatus: reason,
          ),

        BookingChatActionId.updateWorkStatus =>
          bookingNotifier.updateBookingWorkStatus(
            id: bookingId,
            workStatus: (workStatus ?? WorkStatus.pending).name,
          ),

        BookingChatActionId.markWorkCompleted =>
          bookingNotifier.updateBookingWorkStatus(
            id: bookingId,
            workStatus: WorkStatus.completed.name,
          ),

        BookingChatActionId.confirmCompletion =>
          bookingNotifier.updateBookingStatus(
            id: bookingId,
            status: BookingStatus.completed.name,
          ),
          
        _ => Future<bool>.value(false),
      };

      if (ok != true) {
        AppSnackBar.show(context, message: 'Action failed', isError: true);
        return;
      }

      await chatNotifier.reloadChat(chatId);

      if (!context.mounted) return;
      AppSnackBar.show(context, message: 'Saved', isSuccess: true);
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.show(
        context,
        message: e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }
}
