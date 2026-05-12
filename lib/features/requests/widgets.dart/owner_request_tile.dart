import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/providers/offers_provider.dart';
import 'package:prokat/features/requests/models/request_model.dart';
import 'package:prokat/features/requests/state/request_provider.dart';
import 'package:prokat/features/requests/widgets.dart/owner_create_offer_sheet.dart';

String getOwnerRequestStateLabel(
  RequestModel request,
  List<OfferModel> offers,
) {
  final requestStatus = request.status.toLowerCase();

  if (offers.isEmpty) {
    if (requestStatus == "created") return "New Request";
    if (requestStatus == "viewed") return "Viewed";
    return "Request";
  }

  final offer = offers.first;
  final offerStatus = offer.status.toLowerCase();

  if (offerStatus == "accepted") return "Accepted";
  if (offerStatus == "rejected") return "Rejected";

  return "Offer Sent";
}

bool hasOffer(List<OfferModel> offers) => offers.isNotEmpty;

bool isAccepted(List<OfferModel> offers) =>
    offers.isNotEmpty && offers.first.status.toLowerCase() == "accepted";

enum OwnerRequestUIState {
  newRequest, // request CREATED, no offer
  viewed, // request VIEWED, no offer
  offerSent, // offer exists (CREATED/VIEWED)
  hidden, // hidden locally
  accepted, // offer ACCEPTED
}

OwnerRequestUIState getOwnerRequestState(
  RequestModel request,
  List<OfferModel> offers,
) {
  if (offers.isEmpty) {
    if (request.status == "CREATED") return OwnerRequestUIState.newRequest;
    if (request.status == "VIEWED") return OwnerRequestUIState.viewed;
  }

  final offer = offers.first; // you said 1 offer per request

  if (offer.status == "ACCEPTED") {
    return OwnerRequestUIState.accepted;
  }

  return OwnerRequestUIState.offerSent;
}

class OwnerRequestUIConfig {
  final String label;
  final Color color;

  const OwnerRequestUIConfig({required this.label, required this.color});
}

OwnerRequestUIConfig getOwnerRequestUIConfig(OwnerRequestUIState state) {
  switch (state) {
    case OwnerRequestUIState.newRequest:
      return const OwnerRequestUIConfig(
        label: "NEW REQUEST",
        color: Colors.orange,
      );

    case OwnerRequestUIState.viewed:
      return const OwnerRequestUIConfig(label: "VIEWED", color: Colors.white54);

    case OwnerRequestUIState.offerSent:
      return const OwnerRequestUIConfig(
        label: "OFFER SENT",
        color: Colors.blue,
      );

    case OwnerRequestUIState.accepted:
      return const OwnerRequestUIConfig(label: "ACCEPTED", color: Colors.green);

    case OwnerRequestUIState.hidden:
      return const OwnerRequestUIConfig(label: "HIDDEN", color: Colors.white24);
  }
}

class OwnerRequestTile extends ConsumerWidget {
  final RequestModel request;
  final List<OfferModel> offers;

  const OwnerRequestTile({
    super.key,
    required this.request,
    required this.offers,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final stateLabel = getOwnerRequestStateLabel(request, offers);
    final hasOffer = offers.isNotEmpty;
    final isAccepted =
        hasOffer && offers.first.status.toLowerCase() == "accepted";

    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () {
            ref.read(offersProvider.notifier).selectRequest(request);
            openResponseSheet(context, request);
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// --- HEADER ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          width: 110,
                          height: 64,
                          child: Image.network(
                            request.category?.imageUrl ?? "",
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.category_outlined,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _StatusBadge(
                            label: stateLabel,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 8),
                          // Text(
                          //   "${request.category?.name ?? "Request"} • ${request.capacity}${request.category?.capacityUnit ?? ""}",
                          //   style: theme.textTheme.titleMedium?.copyWith(
                          //     fontWeight: FontWeight.bold,
                          //     letterSpacing: -0.5,
                          //   ),
                          // ),
                          // const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: colorScheme.outline,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  request.location.street,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.outline,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatRequestTime(request.createdAt.toString()),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1, thickness: 0.5),
                ),

                /// --- FOOTER (Price & Actions) ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Offered Rate", style: theme.textTheme.labelSmall),
                        Text(
                          formatPrice(request.offeredRate),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (!hasOffer) ...[
                          IconButton.filledTonal(
                            onPressed: () => ref
                                .read(requestProvider.notifier)
                                .rejectRequest(request.id),
                            icon: const Icon(Icons.close),
                            style: IconButton.styleFrom(
                              backgroundColor: colorScheme.errorContainer,
                              foregroundColor: colorScheme.error,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        ElevatedButton(
                          onPressed: () {
                            ref
                                .read(offersProvider.notifier)
                                .selectRequest(request);
                            openResponseSheet(context, request);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAccepted
                                ? Colors.green
                                : colorScheme.primary,
                            foregroundColor: isAccepted
                                ? Colors.white
                                : colorScheme.onPrimary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            isAccepted
                                ? "View Booking"
                                : (hasOffer ? "View Offer" : "Send Offer"),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
