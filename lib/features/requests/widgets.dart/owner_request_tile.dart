import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/info_tile.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/features/bookings/widgets/show_location_sheet.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/requests/models/request_model.dart';
import 'package:prokat/features/requests/state/request_provider.dart';
import 'package:prokat/features/requests/state/request_utils.dart';
import 'package:prokat/features/requests/widgets.dart/owner_create_offer_sheet.dart';
import 'package:prokat/features/requests/widgets.dart/request_status_badge.dart';
import 'package:prokat/l10n/app_localizations.dart';

bool hasOffer(List<OfferModel> offers) => offers.isNotEmpty;

bool isAccepted(List<OfferModel> offers) =>
    offers.isNotEmpty && offers.first.status.toLowerCase() == "accepted";

enum OwnerRequestUIState { newRequest, viewed, offerSent, hidden, accepted }

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
    final l10n = AppLocalizations.of(context)!;

    // TODO: move to status badge
    final uiState = getOwnerRequestState(request, offers);

    final hasOffers = offers.isNotEmpty;

    final hasActiveOffer = offers
        .where((item) => ["CREATED", "VIEWED"].contains(item.status))
        .isNotEmpty;

    final isAccepted =
        hasOffers && offers.first.status.toLowerCase() == "accepted";

    final minutesLeft = getRemainingMinutes(request.createdAt);

    //
    // ref.read(offersProvider.notifier).selectRequest(request);
    // openResponseSheet(context, request);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Icon
              SizedBox(
                width: 110,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: OptimizedNetworkImage(
                      imageUrl: request.category?.imageUrl ?? "",
                      fit: BoxFit.contain,
                      fallbackIcon: Icons.image,
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge
                    Row(
                      children: [
                        Text(
                          formatRequestTime(request.createdAt.toString()),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),

                        Spacer(),

                        RequestStatusBadge(status: request.status),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Category Name
                    Text(
                      request.category?.name.toUpperCase() ?? "",
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.person_rounded,
                  color: theme.primaryColor,
                  size: 22,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.client?.displayName ??
                          request.client?.phoneNumber ??
                          "No Username",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    Row(
                      children: [
                        const Icon(Icons.star, size: 12, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          '${request.client?.rating ?? 0} • ${request.client?.orderCount ?? 0} orders',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: colorScheme.error,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          "$minutesLeft m left",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InfoTile(
                  label: l10n.location,
                  value: request.location.street,
                  onTap: () => showLocationSheet(context, request.location),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InfoTile(
                  label: l10n.dateAndTime,
                  value: request.requiredOn != null
                      ? DateFormat(
                          'dd MMM yyyy • HH:mm',
                        ).format(request.requiredOn!)
                      : "PENDING",
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// FOOTER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.offeredRate, style: theme.textTheme.labelSmall),
                  Text(
                    formatPrice(request.offeredPrice),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (!hasActiveOffer) ...[
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
                      ref.read(offersProvider.notifier).selectRequest(request);
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
                          ? l10n.viewBooking
                          : (hasOffers ? l10n.viewOffer : l10n.sendOffer),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
