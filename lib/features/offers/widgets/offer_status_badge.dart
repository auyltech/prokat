import 'package:flutter/material.dart';
import 'package:prokat/features/offers/models/offer_status.dart';

class OfferStatusBadge extends StatelessWidget {
  final OfferStatus status;

  const OfferStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: status == OfferStatus.accepted
            ? const Color(0xFF2E7D32)
            : status == OfferStatus.created
            ? Colors.blue
            : status == OfferStatus.rejected
            ? const Color(0xFFC62828)
            : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status == OfferStatus.created ? "New Offer" : status.name.toUpperCase(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
