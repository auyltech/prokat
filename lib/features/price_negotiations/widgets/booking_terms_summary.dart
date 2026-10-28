import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/l10n/app_localizations.dart';

class BookingTermsSummary extends StatelessWidget {
  final String title;
  final int price;
  final PriceRateOption? priceRate;
  final DateTime? bookedOn;
  final DateTime? bookedAt;
  final LocationModel? location;
  final bool highlighted;

  const BookingTermsSummary({
    super.key,
    required this.title,
    required this.price,
    required this.priceRate,
    required this.bookedOn,
    required this.bookedAt,
    required this.location,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ProkatFlowPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final date = bookedOn == null
        ? l10n.dateNotSet
        : DateFormat.yMMMd(l10n.localeName).format(bookedOn!.toLocal());
    final schedule = bookedAt == null
        ? date
        : '$date · ${DateFormat.Hm(l10n.localeName).format(bookedAt!.toLocal())}';
    final address = location == null
        ? ''
        : [
            location!.streetLine(l10n.localeName),
            location!.labelCity(l10n.localeName),
          ].where((part) => part.isNotEmpty).join(', ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlighted ? palette.primarySoft : palette.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: palette.secondary, fontSize: 12)),
          const SizedBox(height: 6),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            children: [
              Text(
                formatPrice(price),
                style: TextStyle(
                  color: highlighted ? palette.primary : palette.title,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              Text(
                getPriceRate(priceRate, l10n: l10n),
                style: TextStyle(color: palette.secondary, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _Detail(icon: LucideIcons.calendarDays, text: schedule),
          if (address.isNotEmpty) ...[
            const SizedBox(height: 8),
            _Detail(icon: LucideIcons.mapPin, text: address),
          ],
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Detail({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    final palette = ProkatFlowPalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 17, color: palette.secondary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: palette.title, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
