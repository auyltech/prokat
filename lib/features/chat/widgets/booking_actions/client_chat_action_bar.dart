import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/action_bar_button.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/chat/state/chat_status_detail.dart';
import 'package:prokat/features/chat/utils/get_chat_status.dart';
import 'package:prokat/features/chat/widgets/booking_actions/booking_chat_action_controller.dart';
import 'package:prokat/features/requests/models/request_model.dart';
import 'package:prokat/features/reviews/widgets/review_sheet.dart';

class ChatAction {
  final String type; // primary, secondary, overflow
  final String label;

  ChatAction({required this.type, required, required this.label});
}

class ClientChatActionBar extends ConsumerWidget {
  final String chatId;
  final ChatStatusDetail chatStatus;
  final BookingModel booking;
  final RequestModel? request;
  final String? chatOwnerId;
  final String? chatClientId;

  const ClientChatActionBar({
    super.key,
    required this.chatId,
    required this.chatStatus,
    required this.booking,
    this.request,
    this.chatOwnerId,
    this.chatClientId,
  });

  List<ChatAction> getActions({
    required String mode,
    required ChatStatusDetail chatStatus,
  }) {
    if (chatStatus == ChatStatusDetail.bookingcreated) {}

    return [ChatAction(type: "primary", label: "label")];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final submitState = ref.watch(
      bookingChatActionControllerProvider(booking.id),
    );
    final controller = ref.read(
      bookingChatActionControllerProvider(booking.id).notifier,
    );

    final statusText = getChatActionBarTitle(chatStatus);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
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
            statusText,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (chatStatus == ChatStatusDetail.workcompleted) ...[
                Expanded(
                  child: ActionBarButton(
                    label: "Confirm",
                    isEnabled: !submitState.isSubmitting,
                    isLoading: submitState.isSubmitting,
                    onPressed: () async {
                      await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: theme.colorScheme.surface,
                          title: const Text('Confirm completion?'),
                          content: const Text('Confirm the work is completed.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Not yet'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                if (context.mounted) {
                                  Navigator.pop(context, false);
                                }

                                await controller.confirmCompletion(
                                  context: context,
                                  chatId: chatId,
                                  bookingId: booking.id,
                                );
                              },
                              child: const Text('Confirm'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ] else if (chatStatus == ChatStatusDetail.leaveReview) ...[
                Expanded(
                  child: ActionBarButton(
                    label: "Review",
                    isEnabled: !submitState.isSubmitting,
                    isLoading: submitState.isSubmitting,
                    onPressed: () async {
                      final submitted = await showModalBottomSheet<bool>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: theme.colorScheme.surface,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (_) => ReviewSheet(
                          bookingId: booking.id,
                          revieweeId: chatOwnerId ?? "",
                          title: 'Review owner',
                        ),
                      );

                      if (submitted == true) {
                        await controller.refreshAfterReview(
                          chatId: chatId,
                          bookingId: booking.id,
                        );
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
