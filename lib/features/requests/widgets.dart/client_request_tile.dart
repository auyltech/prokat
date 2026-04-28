import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/bookings/widgets/owner_booking_tile.dart';
import 'package:prokat/features/bookings/widgets/show_location_sheet.dart';
import 'package:prokat/features/requests/models/request_model.dart';
import 'package:prokat/features/requests/state/request_provider.dart';
import 'package:prokat/features/requests/widgets.dart/request_status_badge.dart';

class ClientRequestTile extends ConsumerStatefulWidget {
  final RequestModel request;

  const ClientRequestTile({super.key, required this.request});

  @override
  ConsumerState<ClientRequestTile> createState() => _ClientRequestTileState();
}

class _ClientRequestTileState extends ConsumerState<ClientRequestTile> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final request = widget.request;

    final displayMessage = "";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(color: theme.colorScheme.secondary, width: 2),
        borderRadius: BorderRadius.circular(16),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withValues(alpha: 0.3),
        //     blurRadius: 4,
        //     offset: const Offset(0, 6),
        //   ),
        // ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tile Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(13),
                topRight: Radius.circular(13),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  getRequestStatus(request.status),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  displayMessage,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 1. Top Row: Capacity & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 130, // Fixed width
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            request.category?.imageUrl ?? "",
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.image),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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

                    RequestStatusBadge(status: request.status),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: InfoTile(
                        label: 'Location',
                        value: request.location.street,
                        onTap: () =>
                            showLocationSheet(context, request.location),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InfoTile(
                        label: 'Date & time',
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

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: InfoTile(
                        label: 'Capacity',
                        value:
                            "${request.capacity} ${request.category?.capacityUnit}",
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InfoTile(
                        label: 'Offered rate',
                        value: formatPrice(request.offeredRate),
                        isHighlighted: true,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Comment Tile (Full Width - No Expanded wrapper)
                if (request.comment != null && request.comment!.isNotEmpty)
                  InfoTile(label: 'Comment', value: request.comment!),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            _showCancelConfirmation(context, ref, request.id),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: theme.colorScheme.error,
                            width: 1,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          "Cancel Request",
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _showCancelConfirmation(
  BuildContext context,
  WidgetRef ref,
  String requestId,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Cancel Request?"),
      content: const Text(
        "Are you sure you want to cancel this request? This action cannot be undone.",
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "NO",
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context); // Close dialog first

            final res = await ref
                .read(requestProvider.notifier)
                .cancelRequest(requestId);

            if (res == true && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Request cancelled successfully")),
              );
            }
          },
          child: const Text(
            "YES, CANCEL",
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}
