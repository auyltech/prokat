import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/core/theme/app_fonts.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/widgets/booking_status_badge.dart';
import 'package:prokat/features/bookings/widgets/show_location_sheet.dart';
import 'package:prokat/features/equipment/widgets/equipment_details_sheet.dart';
import 'package:prokat/l10n/app_localizations.dart';

/// Shared presentation for client/owner active orders and history.
/// Actions are supplied by the existing tiles; this widget never mutates orders.
class BookingFlowCard extends StatelessWidget {
  const BookingFlowCard({
    super.key,
    this.tariffUnitLabel,
    required this.booking,
    required this.counterpart,
    required this.priceLabel,
    required this.actions,
  });

  final BookingModel booking;
  final Widget counterpart;
  final String priceLabel;
  final List<Widget> actions;

  final String? tariffUnitLabel;

  @override
  Widget build(BuildContext context) {
    final palette = ProkatFlowPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final equipment = booking.equipment;
    final location = booking.location;
    final hasComment = booking.comment?.isNotEmpty == true;
    return Container(
      key: const ValueKey('booking-flow-card'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(AppDimens.s16$base),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppDimens.r20$xxl),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          counterpart,
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: BookingStatusBadge(status: booking.status),
          ),
          const SizedBox(height: 16),
          if (booking.companyId != null)
            _BookingDetail(
              label: l10n.bookingOrderCommentTitle,
              value: hasComment
                  ? booking.comment!
                  : l10n.bookingOrderCommentEmpty,
              icon: LucideIcons.messageSquare,
            )
          else if (equipment != null)
            InkWell(
              borderRadius: BorderRadius.circular(AppDimens.r12$lg),
              onTap: () => EquipmentDetailsSheet.show(
                context,
                name: equipment.name,
                model: equipment.model,
                plateNumber: equipment.plateNumber,
                imageUrl: equipment.imageUrl,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimens.r12$lg),
                    child: SizedBox.square(
                      dimension: 64,
                      child: OptimizedNetworkImage(
                        imageUrl: equipment.imageUrl,
                        fit: BoxFit.cover,
                        fallbackIcon: LucideIcons.truck,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          equipment.name ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.body16SemiBold(context)
                              .copyWith(color: palette.title),
                        ),
                        if (equipment.model?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            equipment.model!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.body14(context)
                                .copyWith(color: palette.secondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          _BookingDetail(
            label: l10n.location,
            value:
                location?.streetLine(
                  Localizations.localeOf(context).languageCode,
                ) ??
                '',
            icon: LucideIcons.mapPin,
            onTap: location == null
                ? null
                : () => showLocationSheet(context, location),
          ),
          const SizedBox(height: 8),
          _BookingDetail(
            label: l10n.dateAndTime,
            value: formatDateTime(
              booking.bookedOn,
              booking.bookedAt,
              locale: l10n.localeName,
            ),
            icon: LucideIcons.calendarDays,
          ),
          if (hasComment && booking.companyId == null) ...[
            const SizedBox(height: 8),
            _BookingDetail(
              label: l10n.comments,
              value: booking.comment!,
              icon: LucideIcons.messageSquare,
            ),
          ],
          const SizedBox(height: 16),
          Text(
            priceLabel,
            style: AppFonts.caption(context).copyWith(color: palette.secondary),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              text: formatPrice(booking.price),
              children: [
                TextSpan(
                  text:
                      ' ${(tariffUnitLabel ?? getPriceRate(booking.priceRate, l10n: l10n))}',
                  style: AppFonts.body14SemiBold(context)
                      .copyWith(color: palette.secondary),
                ),
              ],
            ),
            key: const ValueKey('booking-flow-price'),
            style: AppFonts.price(context).copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: palette.primary,
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}

class _BookingDetail extends StatelessWidget {
  const _BookingDetail({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = ProkatFlowPalette.of(context);
    return Material(
      color: palette.background,
      borderRadius: BorderRadius.circular(AppDimens.r12$lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: palette.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppFonts.caption(context)
                          .copyWith(color: palette.secondary),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: AppFonts.body14SemiBold(context)
                          .copyWith(color: palette.title),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
