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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Tile
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
                    Text(
                      request.capacity,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              RequestStatusBadge(status: request.status, mode: "client"),
            ],
          ),

          const SizedBox(height: 16),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoTile(
                icon: Icons.map_outlined,
                value: request.location.street,
                onTap: () => showLocationSheet(context, request.location),
              ),

              const SizedBox(
                height: 12,
              ), // Changed from width to height for vertical spacing

              InfoTile(
                icon: Icons.timelapse,
                value: request.requiredOn != null
                    ? DateFormat(
                        'dd MMM yyyy • HH:mm',
                      ).format(request.requiredOn!)
                    : "PENDING",
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (request.comment != null && request.comment!.isNotEmpty)
            InfoTile(label: l10n.comments, value: request.comment!),

          Row(
            children: [
              // Offered Rate and Comment
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

              Spacer(),

              OutlinedButton(
                onPressed: () =>
                    _showCancelConfirmation(context, ref, request.id, l10n),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error, width: 1),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  l10n.cancelRequestAction,
                  style: TextStyle(
                    color: theme.colorScheme.onError,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
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
