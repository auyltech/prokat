import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/action_button.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/info_tile.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/bookings/providers/booking_mutation_provider.dart';
import 'package:prokat/features/bookings/widgets/booking_status_badge.dart';
import 'package:prokat/features/bookings/widgets/cancel_booking_sheet.dart';
import 'package:prokat/features/bookings/widgets/show_location_sheet.dart';
import 'package:prokat/features/equipment/widgets/equipment_info_tile.dart';
import 'package:prokat/features/reviews/widgets/review_sheet.dart';
import 'package:prokat/features/user/widgets/user_info_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class OwnerBookingTile extends ConsumerWidget {
  final BookingModel booking;

  const OwnerBookingTile({super.key, required this.booking});

  void handleAccept(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    unawaited(
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(l10n.acceptOrderQuestion),
            content: Text(l10n.acceptOrderConfirmation),
            actions: [
              TextButton(
                onPressed: () {
                  if (context.mounted && context.canPop()) {
                    context.pop();
                  }
                },
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () async {
                  if (context.mounted && context.canPop()) {
                    context.pop();
                  }
                  await ref
                      .read(bookingMutationProvider.notifier)
                      .updateBookingStatus(
                        id: booking.id,
                        status: BookingStatus.confirmed,
                      );
                },
                child: Text(
                  l10n.confirm,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleCancel(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    bool isCreatedStatus,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(bookingMutationProvider.notifier);

    final modalTitle = isCreatedStatus ? l10n.rejectOrder : l10n.cancelBooking;
    final modalText = isCreatedStatus
        ? l10n.rejectOrderQuestion
        : l10n.cancelOrderQuestion;
    final submitButton = isCreatedStatus ? l10n.yesReject : l10n.yesCancel;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(modalTitle, style: theme.textTheme.titleLarge),
        content: Text(modalText, style: theme.textTheme.bodyMedium),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context, false),
            style: ElevatedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              elevation: 0,
            ),
            child: Text(l10n.no),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              elevation: 0,
            ),
            child: Text(submitButton),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Time restriction check implementation
    final createdAt = booking.createdAt ?? DateTime.now();
    final now = DateTime.now();
    const cancelWindowMinutes = 10;
    final difference = now.difference(createdAt).inMinutes;

    if (difference < cancelWindowMinutes) {
      final result = await notifier.updateBookingStatus(
        id: booking.id,
        status: BookingStatus.cancelled,
      );

      // Closes the active dialog context framework safely
      if (context.mounted && context.canPop()) {
        context.pop();
      }

      AppSnackBar.show(
        message: result.success
            ? l10n.orderCancelled
            : l10n.failedToCancelOrder,
        isSuccess: result.success,
        isError: !result.success,
      );

      return;
    }

    // Open step option modal form sheet past strict time restriction window
    if (context.mounted) {
      unawaited(
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: theme.colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) =>
              CancelBookingSheet(booking: booking, mode: AppMode.ownerMode),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final canReview =
        booking.status == BookingStatus.completed &&
        !(booking.myReviewId != null && booking.myReviewId?.isNotEmpty == true);

    final isSubmittingCancel = ref
        .watch(bookingMutationProvider)
        .isActionActive("booking:update:${booking.id}");

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 1.0),
        ),
      ),
      child: Column(
        children: [
          // Client Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: UserInfoTile(user: booking.client)),

              BookingStatusBadge(status: booking.status),
            ],
          ),

          const SizedBox(height: 16),

          EquipmentInfoTile(equipment: booking.equipment),

          const SizedBox(height: 16),

          // Location, Date & Time
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InfoTile(
                  label: l10n.location,
                  value:
                      booking.location?.streetLine(
                        Localizations.localeOf(context).languageCode,
                      ) ??
                      "",
                  onTap: () {
                    final location = booking.location;

                    location == null
                        ? null
                        : showLocationSheet(context, location);
                  },
                  icon: Icons.map_outlined,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: InfoTile(
                  icon: Icons.timelapse,
                  label: l10n.dateAndTime,
                  value: formatDateTime(
                    booking.bookedOn,
                    booking.bookedAt,
                    locale: l10n.localeName,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (booking.comment != null && booking.comment!.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: InfoTile(
                    label: l10n.comments,
                    value: booking.comment!,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
          ],

          // SECTION 4: Financial Value & Direct Call-to-Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InfoTile.ghost(
                label: l10n.price,
                value: formatPrice(booking.price),
              ),

              const Spacer(),

              Row(
                children: [
                  if (booking.status == BookingStatus.created ||
                      booking.status == BookingStatus.confirmed) ...[
                    if (isSubmittingCancel) ...[
                      const SizedBox(
                        height: 25,
                        width: 25,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ] else
                      IconButton(
                        onPressed: () => _handleCancel(
                          context,
                          ref,
                          theme,
                          booking.status == BookingStatus.created,
                        ),
                        icon: Icon(
                          LucideIcons.x,
                          size: 25,
                          color: theme.colorScheme.error,
                        ),
                      ),

                    IconButton(
                      onPressed: () {
                        unawaited(
                          context.push(
                            '${AppRoutes.ownerChatList}/direct/${booking.chatId}',
                          ),
                        );
                      },
                      icon: Icon(
                        LucideIcons.messageCircle,
                        size: 25,
                        color: theme.colorScheme.primary,
                      ),
                    ),

                    const SizedBox(width: 8),
                  ],
                  if (booking.status == BookingStatus.created) ...[
                    // Accept Order
                    IconButton(
                      onPressed: () =>
                          ref.watch(bookingMutationProvider).isSubmitting
                          ? null
                          : handleAccept(context, ref, theme),
                      tooltip: l10n.acceptOrder,
                      icon: Icon(
                        LucideIcons.check,
                        size: 25,
                        color: Colors.green[800],
                      ),
                    ),
                  ] else if (booking.status == BookingStatus.confirmed) ...[
                    ActionButton(
                      label: l10n.completeWork,
                      isLoading: ref
                          .watch(bookingMutationProvider)
                          .isActionActive("booking:workstatus:${booking.id}"),
                      onPressed: () async {
                        await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: theme.colorScheme.surface,
                            title: Text(l10n.markCompletedQuestion),
                            content: Text(l10n.clientConfirmCompletion),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  if (context.mounted && context.canPop()) {
                                    context.pop();
                                  }
                                },
                                child: Text(l10n.cancel),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  if (context.canPop()) {
                                    context.pop();
                                  }

                                  final result = await ref
                                      .read(bookingMutationProvider.notifier)
                                      .updateBookingWorkStatus(
                                        id: booking.id,
                                        workStatus: WorkStatus.completed,
                                      );

                                  AppSnackBar.show(
                                    message: result.message,
                                    isSuccess: result.success,
                                    isError: !result.success,
                                  );
                                },
                                child: Text(l10n.markCompleted),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ] else if (canReview) ...[
                    ActionButton(
                      label: l10n.submitReview,
                      onPressed: () async {
                        await showModalBottomSheet<bool>(
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
                            revieweeId: booking.client?.id ?? "",
                            title: l10n.reviewClient,
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
