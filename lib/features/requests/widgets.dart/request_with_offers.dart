import 'package:flutter/material.dart';
import 'package:prokat/features/offers/widgets/offer_tile.dart';
import 'package:prokat/features/requests/widgets.dart/client_request_tile.dart';

class RequestWithOffers extends StatefulWidget {
  final dynamic request;
  final List<dynamic> offers;
  final VoidCallback onCancel;

  const RequestWithOffers({
    super.key,
    required this.request,
    required this.offers,
    required this.onCancel,
  });

  @override
  State<RequestWithOffers> createState() => _RequestWithOffersState();
}

class _RequestWithOffersState extends State<RequestWithOffers> {
  bool expanded = true;

  @override
  Widget build(BuildContext context) {
    final hasOffers = widget.offers.isNotEmpty;

    final pendingOffers = widget.offers.where(
      (item) => ["CREATED"].contains(item.status),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 🔹 MAIN REQUEST TILE
        ClientRequestTile(request: widget.request),

        if (hasOffers) ...[
          const SizedBox(height: 8),

          /// 🔹 HEADER (badge + expand)
          GestureDetector(
            onTap: () => setState(() => expanded = !expanded),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4E73DF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${widget.offers.length} offer${widget.offers.length > 1 ? 's' : ''}",
                    style: const TextStyle(
                      color: Color(0xFF4E73DF),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.white54,
                ),
              ],
            ),
          ),

          /// 🔹 OFFERS LIST
          if (expanded) ...[
            const SizedBox(height: 8),
            ...pendingOffers.map(
              (offer) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OfferTile(offer: offer),
              ),
            ),
          ],
        ],
      ],
    );
  }
}
