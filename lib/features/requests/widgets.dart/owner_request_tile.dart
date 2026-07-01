import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/info_tile.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/features/bookings/widgets/show_location_sheet.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/models/offer_status.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/offers/widgets/view_offer_sheet.dart';
import 'package:prokat/features/requests/models/request_model.dart';
import 'package:prokat/features/requests/state/request_provider.dart';
import 'package:prokat/features/requests/state/request_utils.dart';
import 'package:prokat/features/requests/widgets.dart/request_status_badge.dart';
import 'package:prokat/features/user/widgets/user_info_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

bool hasOffer(List<OfferModel> offers) => offers.isNotEmpty;

bool isAccepted(List<OfferModel> offers) =>
    offers.isNotEmpty && offers.first.status == OfferStatus.accepted;

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
    final l10n = AppLocalizations.of(context)!;

    final requestState = getOwnerRequestState(request, offers);

    final offersNotifier = ref.read(offersProvider.notifier);

    final activeOffer = offersNotifier
        .getActiveOffers(request.id, "owner")
        .firstOrNull;

    final minutesLeft = getRemainingMinutes(request.createdAt);

    return Container(
      decoration: BoxDecoration(color: theme.cardColor),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserInfoTile(user: request.client),

              const SizedBox(width: 16),
              const Spacer(),

              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RequestStatusBadge(
                    status: request.status,
                    requestState: requestState,
                    mode: "owner",
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

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

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Name
                  Text(
                    request.category?.name.toUpperCase() ?? "",
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),

                  Text(
                    request.capacity,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),

              Spacer(),

              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 20,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 2),

                  Text(
                    minutesLeft > 0
                        ? "$minutesLeft m left"
                        : formatRequestTime(request.createdAt.toString()),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: minutesLeft > 0
                          ? theme.primaryColor
                          : theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
                  onTap: () {
                    final location = request.location;

                    showLocationSheet(context, location);
                  },
                  icon: Icons.map_outlined,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: InfoTile(
                  icon: Icons.timelapse,
                  label: "Date & Time",
                  value: formatDateTime(request.requiredOn, request.requiredAt),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

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
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              Row(
                children: [
                  if (activeOffer != null) ...[
                    // Go To Chat
                    IconButton(
                      onPressed: () {
                        context.push(
                          '${AppRoutes.clientChatList}/direct/${activeOffer.chatId}',
                        );
                      },
                      icon: Icon(
                        LucideIcons.messageCircle,
                        size: 25,
                        color: theme.primaryColor,
                      ),
                    ),

                    const SizedBox(width: 8),

                    // View Offer
                    IconButton(
                      onPressed: () => openViewOfferSheet(
                        context: context,
                        offer: activeOffer,
                        onCancel: () async {
                          final result = await ref
                              .read(offersProvider.notifier)
                              .cancelOffer(activeOffer.id);

                          AppSnackBar.show(
                            message: result.message,
                            isSuccess: result.success,
                            isError: !result.success,
                          );
                        },
                      ),
                      icon: Icon(
                        LucideIcons.scrollText,
                        size: 25,
                        color: Colors.blue[800],
                      ),
                    ),
                  ] else ...[
                    // Reject Request (set as viewed for this owner)
                    IconButton(
                      onPressed: () async {
                        final result = await ref
                            .read(requestProvider.notifier)
                            .viewRequest(request.id);

                        if (context.mounted) {
                          AppSnackBar.show(
                            message: result
                                ? "Request Viewed"
                                : "Failed to save",
                            isSuccess: result,
                            isError: !result,
                          );
                        }
                      },
                      icon: Icon(
                        LucideIcons.x,
                        size: 25,
                        color: theme.colorScheme.error,
                      ),
                    ),

                    // Send Offer
                    IconButton(
                      onPressed: () {
                        ref
                            .read(offersProvider.notifier)
                            .selectRequest(request);

                        context.push('${AppRoutes.ownerRequests}/send-offer');
                      },
                      icon: Icon(
                        LucideIcons.send,
                        size: 25,
                        color: Colors.green[800],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
