import 'package:flutter/material.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_status.dart';
import 'package:prokat/l10n/app_localizations.dart';

class PriceNegotiationStatusBadge extends StatelessWidget {
  final PriceNegotiationStatus status;

  const PriceNegotiationStatusBadge({super.key, required this.status});

  Color get color {
    switch (status) {
      case PriceNegotiationStatus.created:
        return Colors.orange;
      case PriceNegotiationStatus.accepted:
        return const Color.fromARGB(255, 0, 121, 4);
      case PriceNegotiationStatus.rejected:
        return const Color.fromARGB(255, 179, 0, 0);
      case PriceNegotiationStatus.cancelled:
      case PriceNegotiationStatus.closed:
      case PriceNegotiationStatus.expired:
      case PriceNegotiationStatus.unknown:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        getPriceNegotiationStatus(status, l10n: l10n),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
