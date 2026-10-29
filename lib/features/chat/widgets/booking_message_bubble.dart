import 'dart:async';

import 'package:flutter/material.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/info_tile.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/bookings/providers/booking_mutation_provider.dart';
import 'package:prokat/features/bookings/widgets/booking_status_badge.dart';
import 'package:prokat/features/bookings/widgets/cancel_booking_sheet.dart';
import 'package:prokat/features/bookings/widgets/show_location_sheet.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/equipment/widgets/equipment_details_sheet.dart';
import 'package:prokat/features/owner/owner_offline_guard.dart';
import 'package:prokat/features/chat/utils/owner_offline_chat_lock.dart';
import 'package:prokat/features/price_negotiations/widgets/counter_offer_sheet.dart';
import 'package:prokat/features/price_negotiations/widgets/booking_terms_proposal_sheet.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_query.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class BookingMessageBubble extends ConsumerStatefulWidget {
  final AppMode mode;
  final ChatMessageModel message;
  final ChatModel? currentChat;

  const BookingMessageBubble({
    super.key,
    required this.message,
    required this.mode,
    this.currentChat,
  });

  @override
  ConsumerState<BookingMessageBubble> createState() =>
      _BookingMessageBubbleState();
}

class _BookingMessageBubbleState extends ConsumerState<BookingMessageBubble> {
  bool _isOfflineLockedForBubble() {
    return isDirectBookingOwnerOfflineLock(
      ref: ref,
      mode: widget.mode,
      chat: widget.currentChat,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final booking = widget.currentChat?.booking;

    if (booking == null) {
      return Text(l10n.errorLoadingBooking);
    }

    final equipment = booking.equipment;
    final location = booking.location;
    final palette = ProkatFlowScope.maybeOf(context);
    if (palette != null) {
      return _buildFlowCard(context, booking, l10n, palette);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Row (Order Info Text & Colored Status Badge)
          Row(
            children: [
              Icon(
                Icons.assignment_outlined,
                color: theme.colorScheme.onPrimary,
                size: 22,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.newOrder,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),

              const Spacer(),

              BookingStatusBadge(status: booking.status),
            ],
          ),

          const SizedBox(height: 8),

          // 2. Equipment Body (Triggers the external Details Sheet)
          InkWell(
            onTap: () {
              EquipmentDetailsSheet.show(
                context,
                name: equipment?.name,
                model: equipment?.model,
                plateNumber: equipment?.plateNumber,
                imageUrl: equipment?.imageUrl,
              );
            },
            borderRadius: const BorderRadius.all(Radius.zero),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (equipment?.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: OptimizedNetworkImage(
                      imageUrl: equipment!.imageUrl,
                      width: 80,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: 54,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.image,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        equipment?.name ?? l10n.unknownEquipment,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        equipment?.model ?? "",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),
              ],
            ),
          ),

          const SizedBox(height: 8),

          if (location != null) ...[
            InfoTile(
              icon: Icons.location_on_outlined,
              // label: "Location",
              value:
                  booking.location?.streetLine(
                    Localizations.localeOf(context).languageCode,
                  ) ??
                  "",
              onTap: () => showLocationSheet(context, location),
            ),
            const SizedBox(height: 8),
          ],

          //  Location
          Row(
            children: [
              // Date Time
              InfoTile(
                icon: Icons.event_outlined,
                // label: "Date & time",
                value: () {
                  if (booking.bookedOn == null) return "TBD";

                  // 1. Format the date part cleanly (e.g., "02 Jun 2026")
                  final dateStr = DateFormat('dd MMM yyyy')
                      .format(booking.bookedOn!.toLocal());

                  // 3. Return just the date if no time was specified
                  return dateStr;
                }(),
              ),

              if (booking.bookedAt != null) ...[
                const SizedBox(width: 8),

                InfoTile(
                  icon: Icons.access_time_outlined,
                  value: booking.bookedAt != null
                      ? DateFormat('HH:mm').format(booking.bookedAt!.toLocal())
                      : "",
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              InfoTile(
                icon: LucideIcons.filePenLine,
                // label: l10n.price,
                value:
                    "${formatPrice(booking.price)} ${getPriceRate(booking.priceRate, l10n: l10n)}",
              ),

              const Spacer(),

              // Cancel Order
              if ([
                    BookingStatus.created,
                    BookingStatus.confirmed,
                  ].contains(booking.status) &&
                  booking.workStatus != WorkStatus.completed) ...[
                if (ref
                        .watch(bookingMutationProvider)
                        .isActionActive("booking:${booking.id}:cancel") ||
                    ref
                        .watch(bookingMutationProvider)
                        .isActionActive("booking:${booking.id}:reject"))
                  const SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                  )
                else
                  AppIconButton(
                    icon: LucideIcons.x,
                    tone: AppIconButtonTone.destructive,
                    onTap: () => _cancelBooking(context, booking),
                  ),
              ],

              // Create Price Negotiation
              if (booking.status == BookingStatus.created &&
                  !(widget.mode == AppMode.clientMode &&
                      _isOfflineLockedForBubble())) ...[
                if (ref
                    .watch(bookingMutationProvider)
                    .isActionActive("price:create"))
                  const SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                  )
                else
                  AppIconButton(
                    icon: LucideIcons.filePenLine,
                    tone: AppIconButtonTone.primary,
                    onTap: () => _counterOffer(context, booking, l10n),
                  ),
              ],

              // Update Work Status
              if (widget.mode == AppMode.ownerMode &&
                  booking.status == BookingStatus.created) ...[
                if (ref
                    .watch(bookingMutationProvider)
                    .isActionActive(
                      "booking:${booking.id}:update:${BookingStatus.confirmed}",
                    ))
                  const SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                  )
                else
                  AppIconButton(
                    icon: LucideIcons.check,
                    tone: AppIconButtonTone.success,
                    onTap: () => _acceptBooking(context, booking, l10n),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlowCard(
    BuildContext context,
    BookingModel booking,
    AppLocalizations l10n,
    ProkatFlowPalette palette,
  ) {
    final theme = Theme.of(context);
    final equipment = booking.equipment;
    final location = booking.location;
    final languageCode = Localizations.localeOf(context).languageCode;
    final address = location?.streetLine(languageCode) ?? '';
    final isPending = booking.status == BookingStatus.created;
    final statusColor = switch (booking.status) {
      BookingStatus.created => palette.primary,
      BookingStatus.confirmed => palette.success,
      BookingStatus.completed || BookingStatus.reviewed => palette.primary,
      BookingStatus.cancelled ||
      BookingStatus.rejected ||
      BookingStatus.failed => theme.colorScheme.error,
      BookingStatus.draft => palette.secondary,
    };
    final date = booking.bookedOn == null
        ? l10n.dateNotSet
        : DateFormat.yMMMd(languageCode).format(booking.bookedOn!.toLocal());
    final schedule = booking.bookedAt == null
        ? date
        : '$date · ${DateFormat.Hm().format(booking.bookedAt!.toLocal())}';
    final actions = _flowActions(context, booking, l10n, palette);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: palette.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.assignment_outlined,
                  size: 18,
                  color: palette.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPending ? l10n.requestOwnerTitle : l10n.orderUnit,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.title,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isPending
                          ? l10n.requestPending
                          : getBookingStatus(booking.status, l10n: l10n),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Tooltip(
            message: l10n.equipmentDetails,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => EquipmentDetailsSheet.show(
                  context,
                  name: equipment?.name,
                  model: equipment?.model,
                  plateNumber: equipment?.plateNumber,
                  imageUrl: equipment?.imageUrl,
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: equipment?.imageUrl?.isNotEmpty == true
                          ? OptimizedNetworkImage(
                              imageUrl: equipment!.imageUrl,
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 52,
                              height: 52,
                              color: palette.background,
                              child: Icon(
                                Icons.local_shipping_outlined,
                                size: 24,
                                color: palette.secondary,
                              ),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            equipment?.name ?? l10n.unknownEquipment,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: palette.title,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                          if (equipment?.model?.isNotEmpty == true) ...[
                            const SizedBox(height: 2),
                            Text(
                              equipment!.model!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: palette.secondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: palette.secondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: palette.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _FlowBookingDetail(
                  palette: palette,
                  icon: Icons.event_outlined,
                  value: schedule,
                ),
                if (location != null)
                  _FlowBookingDetail(
                    palette: palette,
                    icon: Icons.location_on_outlined,
                    value: address,
                    onTap: () => showLocationSheet(context, location),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatPrice(booking.price),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: palette.title,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      getPriceRate(booking.priceRate, l10n: l10n),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(width: 8),
                Wrap(spacing: 6, children: actions),
              ],
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _flowActions(
    BuildContext context,
    BookingModel booking,
    AppLocalizations l10n,
    ProkatFlowPalette palette,
  ) {
    final negotiationQuery = priceNegotiationQueryFor(bookingId: booking.id);
    final hasPendingProposal =
        negotiationQuery != null &&
        (ref
                .watch(priceNegotiationsProvider(negotiationQuery))
                .valueOrNull
                ?.items
                .any((item) => item.isPending) ??
            false);
    final canCancel =
        [
          BookingStatus.created,
          BookingStatus.confirmed,
        ].contains(booking.status) &&
        booking.workStatus != WorkStatus.completed;
    final canNegotiate =
        booking.status == BookingStatus.created &&
        !hasPendingProposal &&
        widget.currentChat?.blockState?.isBlocked != true &&
        !(widget.mode == AppMode.clientMode && _isOfflineLockedForBubble());
    final canAccept =
        widget.mode == AppMode.ownerMode &&
        !hasPendingProposal &&
        booking.status == BookingStatus.created;
    if (!canCancel && !canNegotiate && !canAccept) return const [];

    final mutation = ref.watch(bookingMutationProvider);
    return [
      if (canCancel)
        _FlowBookingAction(
          label:
              widget.mode == AppMode.ownerMode &&
                  booking.status == BookingStatus.created
              ? l10n.rejectOrder
              : l10n.cancelBooking,
          icon: LucideIcons.x,
          color: Theme.of(context).colorScheme.error,
          surface: palette.surface,
          loading:
              mutation.isActionActive('booking:${booking.id}:cancel') ||
              mutation.isActionActive('booking:${booking.id}:reject'),
          onPressed: () => _cancelBooking(context, booking),
        ),
      if (canNegotiate)
        _FlowBookingAction(
          label: BookingTermsProposalSheet.canPropose(booking)
              ? l10n.proposeOrderTerms
              : l10n.proposeYourPrice,
          icon: LucideIcons.filePenLine,
          color: palette.primary,
          surface: palette.surface,
          loading: mutation.isActionActive('price:create'),
          onPressed: () => _counterOffer(context, booking, l10n),
        ),
      if (canAccept)
        _FlowBookingAction(
          label: l10n.acceptOrder,
          icon: LucideIcons.check,
          color: palette.primary,
          surface: palette.primarySoft,
          loading: mutation.isActionActive(
            'booking:${booking.id}:update:${BookingStatus.confirmed}',
          ),
          onPressed: () => _acceptBooking(context, booking, l10n),
        ),
    ];
  }

  void _cancelBooking(BuildContext context, BookingModel booking) {
    unawaited(
      CancelBookingSheet.show(context, booking: booking, mode: widget.mode),
    );
  }

  Future<void> _counterOffer(
    BuildContext context,
    BookingModel booking,
    AppLocalizations l10n,
  ) async {
    if (widget.mode == AppMode.ownerMode) {
      final online = await ensureOwnerOnline(
        context,
        ref,
        message: l10n.ownerOfflineMustBeOnlineToBargain,
      );
      if (!online || !context.mounted) return;
    }

    if (BookingTermsProposalSheet.canPropose(booking)) {
      await BookingTermsProposalSheet.show(
        context,
        booking: booking,
        mode: widget.mode,
        chatId: widget.message.chatId,
      );
      return;
    }
    await CounterOfferSheet.show(
      context,
      bookingId: booking.id,
      chatId: widget.message.chatId,
      initialPrice: booking.price,
      initialPriceRate: booking.priceRate,
      mode: widget.mode,
    );
  }

  Future<void> _acceptBooking(
    BuildContext context,
    BookingModel booking,
    AppLocalizations l10n,
  ) async {
    final online = await ensureOwnerOnline(
      context,
      ref,
      message: l10n.ownerOfflineMustBeOnlineToAcceptOrder,
    );
    if (!online || !context.mounted) return;

    final confirmed = await AppAlertBottomSheet.show(
      context,
      title: l10n.acceptOrderQuestion,
      description: l10n.acceptOrderConfirmation,
      primaryLabel: l10n.accept,
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
}

class _FlowBookingDetail extends StatelessWidget {
  final ProkatFlowPalette palette;
  final IconData icon;
  final String value;
  final VoidCallback? onTap;

  const _FlowBookingDetail({
    required this.palette,
    required this.icon,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 17, color: palette.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(height: 1.4, color: palette.title),
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: palette.secondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FlowBookingAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color surface;
  final bool loading;
  final VoidCallback onPressed;

  const _FlowBookingAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.surface,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      enabled: !loading,
      child: Tooltip(
        message: label,
        child: Material(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: loading ? null : onPressed,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: loading
                  ? SizedBox.square(
                      dimension: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : Icon(icon, size: 21, color: color),
            ),
          ),
        ),
      ),
    );
  }
}
