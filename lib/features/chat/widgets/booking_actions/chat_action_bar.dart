import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/action_bar_button.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/bookings/providers/booking_mutation_provider.dart';
import 'package:prokat/features/bookings/widgets/booking_status_sheet.dart';
import 'package:prokat/features/bookings/widgets/cancel_booking_reason_sheet.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/providers/current_chat_provider.dart';
import 'package:prokat/features/chat/state/chat_status_detail.dart';
import 'package:prokat/features/chat/utils/get_chat_status.dart';
import 'package:prokat/features/price_negotiations/widgets/counter_offer_sheet.dart';
import 'package:prokat/features/requests/providers/request_mutation_provider.dart';
import 'package:prokat/features/reviews/widgets/review_sheet.dart';
import 'package:prokat/l10n/app_localizations.dart';

class ChatActionBar extends ConsumerWidget {
  final ChatModel currentChat;
  final ChatStatusDetail chatStatus;
  final AppMode mode;

  const ChatActionBar({
    super.key,
    required this.currentChat,
    required this.chatStatus,
    required this.mode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final submitState = ref.watch(bookingMutationProvider);

    final actionBarTitle = getChatActionBarTitle(chatStatus);

    final showActionBar = [ChatStatusDetail.workcompleted].contains(chatStatus);

    if (!showActionBar) return SizedBox.shrink();

    final booking = currentChat.booking;
    final request = currentChat.request;
    final chatOwnerId = currentChat.owner?.id;
    final chatClientId = currentChat.client?.id;

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
            actionBarTitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              if (chatStatus == ChatStatusDetail.requestcreated) ...[
                if (mode == AppMode.ownerMode)
                  // Hide request
                  Expanded(
                    child: ActionBarButton.destructive(
                      label: "Hide Request",
                      isEnabled: true,
                      isLoading: false,
                      onPressed: () async {},
                    ),
                  )
                else
                  // Cancel request
                  Expanded(
                    child: ActionBarButton.danger(
                      label: "Cancel Request",
                      isEnabled: true,
                      isLoading: false,
                      onPressed: () async {
                        final result = await ref
                            .read(requestMutationProvider.notifier)
                            .cancelRequest(request?.id ?? "");

                        AppSnackBar.show(
                          message: result.success
                              ? l10n.requestCancelled
                              : "Failed to cancel request",
                          isSuccess: result.success,
                          isError: !result.success,
                        );
                      },
                    ),
                  ),

                const SizedBox(width: 12),
                // Create Counter Offer
                Expanded(
                  child: ActionBarButton.secondary(
                    label: "Counter",
                    isEnabled: true,
                    isLoading: false,
                    onPressed: () async {
                      final offer = currentChat.getActiveOffer();

                      await CounterOfferSheet.show(
                        context,
                        offerId: offer?.id,
                        initialPrice: offer?.price ?? 0,
                        initialPriceRate: (offer?.priceRate)!,
                        mode: mode,
                      );

                      await ref
                          .read(currentChatProvider(currentChat.id).notifier)
                          .refreshAll();
                    },
                  ),
                ),
              ] else if (chatStatus == ChatStatusDetail.requestaccepted) ...[
                // edge case: should have a booking
                // Cancel request
                Expanded(
                  child: ActionBarButton.danger(
                    label: "Cancel Request",
                    isEnabled: true,
                    isLoading: false,
                    onPressed: () async {
                      await ref
                          .read(requestMutationProvider.notifier)
                          .cancelRequest(request?.id ?? "");

                      await ref
                          .read(currentChatProvider("").notifier)
                          .refreshAll();
                    },
                  ),
                ),
              ] else if (chatStatus == ChatStatusDetail.bookingconfirmed) ...[
                if (booking != null)
                  Expanded(
                    child: ActionBarButton.destructive(
                      label: "Reject Order",
                      isEnabled: !submitState.isSubmitting,
                      isLoading:
                          submitState.isSubmitting &&
                          submitState.isActionActive("booking:reject"),
                      onPressed: () async {
                        final decision =
                            await showModalBottomSheet<CancelBookingDecision>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: theme.colorScheme.surface,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              builder: (_) => CancelBookingReasonSheet(
                                booking: booking,
                                useCase: 'owner',
                              ),
                            );

                        if (!context.mounted) return;

                        if (decision == null || decision.confirmed == false) {
                          return;
                        }

                        final reason = decision.reason;

                        if (reason == null || reason.trim().isEmpty) {
                          return;
                        }

                        final result = await ref
                            .read(bookingMutationProvider.notifier)
                            .updateBookingStatus(
                              id: booking.id,
                              status: BookingStatus.rejected,
                              cancelReason: reason,
                            );

                        if (result.success == true) {
                          await ref
                              .read(
                                currentChatProvider(currentChat.id).notifier,
                              )
                              .refreshAll();
                        }
                      },
                    ),
                  ),
                const SizedBox(width: 6),

                // Completed Work
                Expanded(
                  child: ActionBarButton(
                    label: "Complete Work",
                    isEnabled: !submitState.isSubmitting,
                    isLoading:
                        submitState.isSubmitting &&
                        submitState.isActionActive("booking:workstatus"),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: theme.colorScheme.surface,
                          title: const Text('Mark completed?'),
                          content: const Text(
                            'Client will need to confirm completion.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(context, true);

                                await ref
                                    .read(bookingMutationProvider.notifier)
                                    .updateBookingWorkStatus(
                                      id: booking?.id ?? "",
                                      workStatus: WorkStatus.completed,
                                    );
                              },
                              child: const Text('Mark completed'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed != true) return;
                    },
                  ),
                ),

                const SizedBox(width: 6),

                // Update Work Status
                if (booking != null)
                  Expanded(
                    child: ActionBarButton.secondary(
                      label: "Update Status",
                      isEnabled: !submitState.isSubmitting,
                      isLoading:
                          submitState.isSubmitting &&
                          submitState.isActionActive("booking:workstatus"),
                      onPressed: () async {
                        final result = await BookingStatusSheet.show(
                          context,
                          booking: booking,
                        );

                        if (result == true) {
                          await ref
                              .read(
                                currentChatProvider(currentChat.id).notifier,
                              )
                              .refreshAll();
                        }
                      },
                    ),
                  ),
              ] else if (chatStatus == ChatStatusDetail.workcompleted) ...[
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

                                final result = await ref
                                    .read(bookingMutationProvider.notifier)
                                    .updateBookingStatus(
                                      id: booking?.id ?? "",
                                      status: BookingStatus.completed,
                                    );

                                if (result.success) {
                                  await ref
                                      .read(
                                        currentChatProvider(
                                          currentChat.id,
                                        ).notifier,
                                      )
                                      .refreshAll();
                                }
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
                    isLoading:
                        submitState.isSubmitting &&
                        submitState.isActionActive("review:submit"),
                    onPressed: () async {
                      final submitted = await ReviewSheet.show(
                        context,
                        bookingId: booking?.id ?? "",
                        revieweeId:
                            (mode == AppMode.clientMode
                                ? chatOwnerId
                                : chatClientId) ??
                            "",
                        mode: mode,
                      );

                      if (submitted == true) {
                        await ref
                            .read(currentChatProvider(currentChat.id).notifier)
                            .refreshAll();
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
