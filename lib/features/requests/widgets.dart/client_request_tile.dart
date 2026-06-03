import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/info_tile.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/features/bookings/widgets/show_location_sheet.dart';
import 'package:prokat/features/requests/models/request_model.dart';
import 'package:prokat/features/requests/state/request_provider.dart';
import 'package:prokat/features/requests/widgets.dart/request_status_badge.dart';
import 'package:prokat/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;

    final request = widget.request;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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

          // Location, Date and Time
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
                  value: () {
                    if (request.requiredOn == null) return "PENDING";

                    // 1. Format the date part cleanly (e.g., "02 Jun 2026")
                    final dateStr = DateFormat(
                      'dd MMM yyyy',
                    ).format(request.requiredOn!.toLocal());

                    // 2. If a specific time exists, format and append it (e.g., "• 14:30")
                    if (request.requiredAt != null) {
                      final timeStr = DateFormat(
                        'HH:mm',
                      ).format(request.requiredAt!.toLocal());
                      return '$dateStr • $timeStr';
                    }

                    // 3. Return just the date if no time was specified
                    return dateStr;
                  }(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Offered Rate and Comment
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InfoTile(
                  label: l10n.offeredRate,
                  value: formatPrice(request.offeredPrice),
                  isHighlighted: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (request.comment != null && request.comment!.isNotEmpty)
            InfoTile(label: l10n.comments, value: request.comment!),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      _showCancelConfirmation(context, ref, request.id, l10n),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.error, width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    l10n.cancelRequestAction,
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
    );
  }
}

void _showCancelConfirmation(
  BuildContext context,
  WidgetRef ref,
  String requestId,
  AppLocalizations l10n,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.cancelRequest),
      content: Text(l10n.cancelRequestContent),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            l10n.no,
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);

            final res = await ref
                .read(requestProvider.notifier)
                .cancelRequest(requestId);

            if (res == true && context.mounted) {
              AppSnackBar.show(
                context,
                message: l10n.requestCancelled,
                isSuccess: true,
              );
            }
          },
          child: Text(
            l10n.yesCancel,
            style: const TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}
