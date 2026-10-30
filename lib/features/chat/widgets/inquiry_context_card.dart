import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/catalog/tariff_unit_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/chat/widgets/chat_booking_terms_sheet.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/providers/chat_dependencies.dart';
import 'package:prokat/features/chat/state/post_mutation_cache_coordinator.dart';
import 'package:prokat/l10n/app_localizations.dart';

/// Context for a direct listing discussion, including after it becomes an order.
class InquiryContextCard extends ConsumerStatefulWidget {
  final ChatModel chat;
  final VoidCallback? onSetTerms;
  final AppMode mode;

  const InquiryContextCard({
    super.key,
    required this.chat,
    this.onSetTerms,
    this.mode = AppMode.clientMode,
  });

  @override
  ConsumerState<InquiryContextCard> createState() => _InquiryContextCardState();
}

class _InquiryContextCardState extends ConsumerState<InquiryContextCard> {
  bool _closing = false;

  Future<void> _closeDiscussion() async {
    if (_closing) return;
    final chatId = widget.chat.id;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await AppAlertBottomSheet.show(
      context,
      title: l10n.inquiryCloseQuestion,
      description: l10n.inquiryCloseDescription,
      primaryLabel: l10n.inquiryCloseConfirm,
      secondaryLabel: l10n.cancel,
    );
    if (!mounted || confirmed != true || widget.chat.id != chatId) return;
    setState(() => _closing = true);
    try {
      final result = await ref
          .read(chatServiceProvider)
          .closeEquipmentInquiry(chatId);
      if (!mounted) return;
      await ref
          .read(postMutationCacheCoordinatorProvider)
          .refreshAffectedChats(chatId);
      if (!mounted) return;
      AppToast.show(
        message: result.success
            ? l10n.inquiryClosedStatus
            : l10n.inquiryCloseFailed,
        type: result.success ? AppToastType.success : AppToastType.error,
      );
    } finally {
      if (mounted) setState(() => _closing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = widget.chat;
    final onSetTerms = widget.onSetTerms;
    final equipment = chat.inquiryEquipment;
    final bookedEquipment = chat.booking?.equipment;
    if (equipment == null && bookedEquipment == null) {
      return const SizedBox.shrink();
    }
    final palette = ProkatFlowPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final status = switch (chat.booking?.status) {
      null =>
        chat.bookingId != null
            ? l10n.requestPending
            : chat.status == ChatStatus.active
            ? l10n.inquiryStatus
            : l10n.inquiryClosedStatus,
      BookingStatus.created => l10n.requestPending,
      BookingStatus.confirmed => l10n.orderConfirmed,
      BookingStatus.completed || BookingStatus.reviewed => l10n.orderCompleted,
      BookingStatus.rejected => l10n.requestRejected,
      _ => l10n.orderCancelled,
    };
    final isOpenInquiry =
        chat.inquiryEquipmentId != null &&
        chat.bookingId == null &&
        chat.booking == null &&
        chat.bookingSummary == null &&
        chat.requestId == null &&
        equipment?.companyId == null &&
        chat.status == ChatStatus.active;
    final canSetTerms =
        isOpenInquiry &&
        !_closing &&
        onSetTerms != null &&
        chat.status == ChatStatus.active;
    final canViewTerms = chat.booking != null;
    final statusColor = chat.booking?.status == BookingStatus.confirmed
        ? palette.success
        : chat.booking?.status == BookingStatus.created
        ? palette.primary
        : palette.secondary;
    final booking = chat.booking;
    final date = booking?.bookedOn;
    final time = booking?.bookedAt;
    final schedule = [
      if (date != null) DateFormat.MMMd(l10n.localeName).format(date.toLocal()),
      if (time != null) DateFormat.Hm(l10n.localeName).format(time.toLocal()),
    ].join(' · ');
    final VoidCallback? onOpenContext = canSetTerms
        ? onSetTerms
        : canViewTerms
        ? () => ChatBookingTermsSheet.show(
            context,
            ref,
            chat: chat,
            mode: widget.mode,
          )
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Material(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Semantics(
          key: const ValueKey('inquiry-context-card'),
          container: true,
          button: onOpenContext != null,
          label: canSetTerms
              ? l10n.inquiryCreateOrder
              : canViewTerms
              ? l10n.agreedTermsTitle
              : null,
          onTap: onOpenContext,
          child: InkWell(
            onTap: onOpenContext,
            excludeFromSemantics: true,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: chat.booking?.status == BookingStatus.confirmed
                      ? palette.success.withValues(alpha: .35)
                      : palette.border,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox.square(
                          dimension: 54,
                          child: OptimizedNetworkImage(
                            imageUrl:
                                equipment?.primaryImageUrl ??
                                bookedEquipment?.imageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              equipment?.name ??
                                  bookedEquipment?.name ??
                                  l10n.unknownEquipment,
                              key: const ValueKey('inquiry-context-title'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: palette.title,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              status,
                              key: const ValueKey('inquiry-context-status'),
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                            if (canSetTerms) ...[
                              const SizedBox(height: 3),
                              Text(
                                l10n.inquiryCreateOrder,
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: palette.primary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (canSetTerms || canViewTerms) ...[
                        const SizedBox(width: 4),
                        Icon(
                          LucideIcons.chevronRight,
                          color: palette.primary,
                          size: 20,
                        ),
                      ],
                      if (isOpenInquiry)
                        IconButton(
                          key: const ValueKey('inquiry-close-button'),
                          tooltip: l10n.inquiryCloseAction,
                          onPressed: _closing ? null : _closeDiscussion,
                          icon: _closing
                              ? SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: palette.secondary,
                                  ),
                                )
                              : Icon(
                                  LucideIcons.archive,
                                  color: palette.secondary,
                                  size: 19,
                                ),
                        ),
                    ],
                  ),
                  if (booking != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (schedule.isNotEmpty)
                          _ContextSchedule(text: schedule, palette: palette),
                        Text.rich(
                          TextSpan(
                            text: formatPrice(booking.price),
                            children: [
                              TextSpan(
                                text:
                                    ' ${tariffUnitLabelForUi(code: booking.priceRate.value, languageCode: Localizations.localeOf(context).languageCode, catalog: ref.watch(catalogProvider).valueOrNull, l10n: l10n)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: palette.secondary,
                                ),
                              ),
                            ],
                          ),
                          key: const ValueKey('inquiry-context-price'),
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: palette.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContextSchedule extends StatelessWidget {
  final String text;
  final ProkatFlowPalette palette;

  const _ContextSchedule({required this.text, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.calendarDays, size: 14, color: palette.secondary),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            key: const ValueKey('inquiry-context-schedule'),
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: palette.secondary,
            ),
          ),
        ),
      ],
    );
  }
}
