import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/ui_kit/toasts/app_toast.dart';
import 'package:prokat/core/widgets/info_tile.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/core/widgets/ui_kit/sheets/app_alert_bottom_sheet.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/bookings/widgets/show_location_sheet.dart';
import 'package:prokat/features/requests/models/request_model.dart';
import 'package:prokat/features/requests/state/request_lifetime.dart';
import 'package:prokat/features/requests/providers/request_mutation_provider.dart';
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
                    if (hasVisibleRequestCapacity(request.capacity))
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

              RequestStatusBadge(
                status: request.status,
                mode: AppMode.clientMode,
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
                  value:
                      request.location?.streetLine(
                        Localizations.localeOf(context).languageCode,
                      ) ??
                      l10n.unknownLocation,
                  onTap: () {
                    final location = request.location;
                    if (location == null) return;

                    showLocationSheet(context, location);
                  },
                  icon: Icons.map_outlined,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: InfoTile(
                  icon: Icons.timelapse,
                  label: l10n.dateAndTime,
                  value: formatDateTime(
                    request.requiredOn,
                    request.requiredAt,
                    locale: l10n.localeName,
                  ),
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
                    formatRequestOfferedPrice(
                      request.offeredPrice,
                      waitOwnerLabel: l10n.requestWaitOwnerPrice,
                    ),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              if (ref
                  .watch(requestMutationProvider)
                  .isActionActive("request:$id:cancel"))
                const SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                  ),
                )
              else
                IconButton(
                  onPressed: () => unawaited(
                    _showCancelConfirmation(context, ref, request.id, l10n),
                  ),
                  icon: Icon(
                    LucideIcons.x,
                    size: 25,
                    color: theme.colorScheme.error,
                  ),
                ),

              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _showCancelConfirmation(
  BuildContext context,
  WidgetRef ref,
  String requestId,
  AppLocalizations l10n,
) async {
  final confirmed = await AppAlertBottomSheet.show(
    context,
    title: l10n.cancelRequest,
    description: l10n.cancelRequestContent,
    primaryLabel: l10n.yesCancel,
    secondaryLabel: l10n.no,
    isDestructivePrimary: true,
  );

  if (confirmed != true) return;

  final result = await ref
      .read(requestMutationProvider.notifier)
      .cancelRequest(requestId);

  AppToast.show(
    message: result.success
        ? l10n.requestCancelled
        : l10n.failedToCancelRequest,
    type: result.success ? AppToastType.success : AppToastType.error,
  );
}
