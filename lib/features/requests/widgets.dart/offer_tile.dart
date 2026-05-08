import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/providers/offers_provider.dart';

class OfferTile extends ConsumerWidget {
  final OfferModel offer;

  const OfferTile({super.key, required this.offer});

  Future<void> _handleUpdate(
    BuildContext context,
    WidgetRef ref,
    String status,
  ) async {
    final notifier = ref.read(offersProvider.notifier);

    final success = await notifier.acceptOffer(offer.id);

    if (success) {
      AppSnackBar.show(context, message: "Offer Updated", isSuccess: true);
    } else {
      AppSnackBar.show(context, message: "Something went wrong", isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHandled = offer.status == "ACCEPTED" || offer.status == "DECLINED";

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Owner / Equipment
          Text(
            offer.equipment?.name ?? "Equipment",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 4),

          /// Price
          Text(
            "${offer.price} ₸ / day",
            style: const TextStyle(
              color: Color(0xFF4E73DF),
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          /// Message
          if (offer.comment != null)
            Text(
              offer.comment ?? "",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),

          const SizedBox(height: 10),

          /// Actions (later: accept / reject)
          Row(
            children: [
              TextButton(
                onPressed: isHandled
                    ? null
                    : () => _handleUpdate(context, ref, "ACCEPTED"),
                child: const Text("ACCEPT"),
              ),
              TextButton(
                onPressed: isHandled
                    ? null
                    : () => _handleUpdate(context, ref, "REJECTED"),
                child: const Text("REJECT"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
