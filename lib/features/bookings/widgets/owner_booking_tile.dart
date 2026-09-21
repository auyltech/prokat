import 'dart:async';

import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/info_tile.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/providers/booking_mutation_provider.dart';
import 'package:prokat/features/bookings/widgets/booking_status_badge.dart';
import 'package:prokat/features/bookings/widgets/cancel_booking_sheet.dart';
import 'package:prokat/features/bookings/widgets/show_location_sheet.dart';
import 'package:prokat/features/equipment/widgets/equipment_info_tile.dart';
import 'package:prokat/features/owner/owner_offline_guard.dart';
import 'package:prokat/features/reviews/widgets/review_sheet.dart';
import 'package:prokat/features/user/widgets/user_info_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class OwnerBookingTile extends ConsumerWidget {
  final BookingModel booking;

  const OwnerBookingTile({super.key, required this.booking});

  Future<void> handleAccept(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    if (!await ensureOwnerOnline(
      context,
      ref,
      message: l10n.ownerOfflineMustBeOnlineToAcceptOrder,
    )) {
      return;
    }
    if (!context.mounted) return;

    final confirmed = await AppAlertBottomSheet.show(
      context,
      title: l10n.acceptOrderQuestion,
      description: l10n.acceptOrderConfirmation,
      primaryLabel: l10n.confirm,
      secondaryLabel: l10n.cancel,
    );

    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(bookingMutationProvider.notifier)
        .updateBookingStatus(id: booking.id, status: BookingStatus.confirmed);
    if (!context.mounted) return;
    AppToast.show(
      message: result.success
          ? l10n.orderConfirmed
          : ownerOfflineActionErrorMessage(
              l10n: l10n,
              errorCode: result.errorCode,
              fallback: l10n.failedToConfirmOrder,
            ),
      type: result.success ? AppToastType.success : AppToastType.error,
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

    final confirmed = await AppAlertBottomSheet.show(
      context,
      title: modalTitle,
      description: modalText,
      primaryLabel: submitButton,
      secondaryLabel: l10n.no,
      isDestructivePrimary: true,
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

      AppToast.show(
        message: result.success
            ? l10n.orderCancelled
            : l10n.failedToCancelOrder,
        type: result.success ? AppToastType.success : AppToastType.error,
      );

      return;
    }

    // Open step option modal form sheet past strict time restriction window
    if (context.mounted) {
      unawaited(
        CancelBookingSheet.show(
          context,
          booking: booking,
          mode: AppMode.ownerMode,
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
                      AppIconButton(
                        icon: LucideIcons.x,
                        tone: AppIconButtonTone.destructive,
                        onTap: () => unawaited(
                          _handleCancel(
                            context,
                            ref,
                            theme,
                            booking.status == BookingStatus.created,
                          ),
                        ),
                      ),

                    AppIconButton(
                      icon: LucideIcons.messageCircle,
                      tone: AppIconButtonTone.primary,
                      onTap: () {
                        unawaited(
                          context.push(
                            '${AppRoutes.ownerChatList}/direct/${booking.chatId}',
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 8),
                  ],
                  if (booking.status == BookingStatus.created) ...[
                    // Accept Order
                    AppIconButton(
                      icon: LucideIcons.check,
                      tone: AppIconButtonTone.success,
                      onTap: () =>
                          ref.watch(bookingMutationProvider).isSubmitting
                          ? null
                          : unawaited(handleAccept(context, ref)),
                      tooltip: l10n.acceptOrder,
                    ),
                  ] else if (canReview) ...[
                    AppLabelButton(
                      title: l10n.submitReview,
                      onTap: () async {
                        await ReviewSheet.show(
                          context,
                          bookingId: booking.id,
                          revieweeId: booking.client?.id ?? "",
                          mode: AppMode.ownerMode,
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
