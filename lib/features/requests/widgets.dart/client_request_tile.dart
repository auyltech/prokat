import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
    final id = request.id;

    return Container(
      decoration: BoxDecoration(color: theme.cardColor),
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

              if (ref
                  .watch(requestProvider)
                  .isActionActive("request:$id:cancel"))
                SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                  ),
                )
              else
                IconButton(
                  onPressed: () =>
                      _showCancelConfirmation(context, ref, request.id, l10n),
                  icon: Icon(
                    LucideIcons.x,
                    size: 25,
                    color: theme.colorScheme.error,
                  ),
                ),

              SizedBox(width: 12),
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

            final result = await ref
                .read(requestProvider.notifier)
                .cancelRequest(requestId);

            AppSnackBar.show(
              message: result
                  ? l10n.requestCancelled
                  : "Failed to cancel request",
              isSuccess: result,
              isError: !result,
            );
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
