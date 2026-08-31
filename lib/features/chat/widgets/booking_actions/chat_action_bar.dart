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
  final String actionBarTitle;

  const ChatActionBar({
    super.key,
    required this.currentChat,
    required this.chatStatus,
    required this.mode,
    required this.actionBarTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!chatHasVisibleActions(status: chatStatus, mode: mode)) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final submitState = ref.watch(bookingMutationProvider);
    final booking = currentChat.booking;
    final request = currentChat.request;
    final activeOffer = currentChat.getActiveOffer();
    final chatOwnerId = currentChat.owner?.id;
    final chatClientId = currentChat.client?.id;
    final title = actionBarTitle.trim();
    final requestMutation = ref.read(requestMutationProvider.notifier);
    final bookingMutation = ref.read(bookingMutationProvider.notifier);
    final chatNotifier = ref.read(
      currentChatProvider(currentChat.id).notifier,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const SizedBox(width: 16),
              if (chatStatus == ChatStatusDetail.requestcreated) ...[
                if (mode == AppMode.ownerMode)
                  ActionBarButton.destructive(
                    label: l10n.hideRequest,
                    isEnabled: true,
                    isLoading: false,
                    onPressed: () async {},
                  )
                else
                  ActionBarButton.danger(
                    label: l10n.cancelRequestAction,
                    isEnabled: true,
                    isLoading: false,
                    onPressed: () async {
                      final result = await requestMutation.cancelRequest(
                        request?.id ?? "",
                      );

                      AppSnackBar.show(
                        message: result.success
                            ? l10n.requestCancelled
                            : l10n.failedToCancelRequest,
                        isSuccess: result.success,
                        isError: !result.success,
                      );
                    },
                  ),
                const SizedBox(width: 12),
                ActionBarButton.secondary(
                  label: l10n.counter,
                  isEnabled:
                      activeOffer != null && activeOffer.priceRate != null,
                  isLoading: false,
                  onPressed: () async {
                    final offer = activeOffer;
                    if (offer == null || offer.priceRate == null) return;

                    await CounterOfferSheet.show(
                      context,
                      offerId: offer.id,
                      chatId: currentChat.id,
                      initialPrice: offer.price,
                      initialPriceRate: offer.priceRate,
                      mode: mode,
                    );
                  },
                ),
              ] else if (chatStatus == ChatStatusDetail.bookingconfirmed &&
                  mode == AppMode.ownerMode) ...[
                if (booking != null)
                  ActionBarButton.destructive(
                    label: l10n.rejectOrder,
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
                      if (reason == null || reason.trim().isEmpty) return;

                      final result = await bookingMutation.updateBookingStatus(
                        id: booking.id,
                        status: BookingStatus.rejected,
                        cancelReason: reason,
                      );

                      if (result.success == true) {
                        await chatNotifier.refreshAll();
                      }
                    },
                  ),
                const SizedBox(width: 6),
                ActionBarButton(
                  label: l10n.completeWork,
                  isEnabled: !submitState.isSubmitting,
                  isLoading:
                      submitState.isSubmitting &&
                      submitState.isActionActive("booking:workstatus"),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: theme.colorScheme.surface,
                        title: Text(l10n.markCompletedQuestion),
                        content: Text(l10n.clientConfirmCompletion),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(l10n.cancel),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context, true);
                              await bookingMutation.updateBookingWorkStatus(
                                id: booking?.id ?? "",
                                workStatus: WorkStatus.completed,
                              );
                            },
                            child: Text(l10n.markCompleted),
                          ),
                        ],
                      ),
                    );

                    if (confirmed != true) return;
                  },
                ),
                const SizedBox(width: 6),
                if (booking != null)
                  ActionBarButton.secondary(
                    label: l10n.updateStatus,
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
                        await chatNotifier.refreshAll();
                      }
                    },
                  ),
              ] else if (chatStatus == ChatStatusDetail.confirmcompleted) ...[
                ActionBarButton(
                  label: l10n.confirm,
                  isEnabled: !submitState.isSubmitting,
                  isLoading: submitState.isSubmitting,
                  onPressed: () async {
                    await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: theme.colorScheme.surface,
                        title: Text(l10n.confirmCompletionQuestion),
                        content: Text(l10n.confirmCompletionPrompt),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(l10n.notYet),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              if (context.mounted) {
                                Navigator.pop(context, false);
                              }

                              final result = await bookingMutation
                                  .updateBookingStatus(
                                    id: booking?.id ?? "",
                                    status: BookingStatus.completed,
                                  );

                              if (result.success) {
                                await chatNotifier.refreshAll();
                              }
                            },
                            child: Text(l10n.confirm),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ] else if (chatStatus == ChatStatusDetail.leaveReview) ...[
                ActionBarButton(
                  label: l10n.review,
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
                      await chatNotifier.refreshAll();
                    }
                  },
                ),
              ],
              const SizedBox(width: 16),
            ],
          ),
        ),
      ],
    );
  }
}
