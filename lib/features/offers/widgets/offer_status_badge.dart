import 'package:flutter/material.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/offers/models/offer_status.dart';
import 'package:prokat/l10n/app_localizations.dart';

class OfferStatusBadge extends StatelessWidget {
  final OfferStatus status;

  const OfferStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 120, minHeight: 34),

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: status == OfferStatus.accepted
              ? const Color(0xFF2E7D32)
              : status == OfferStatus.created
              ? Colors.blue
              : status == OfferStatus.rejected
              ? const Color(0xFFC62828)
              : const Color(0xFFFFEBEE),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              getOfferStatus(status, l10n: l10n),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              textWidthBasis: TextWidthBasis.longestLine,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
