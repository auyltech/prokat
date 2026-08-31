import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/info_tile.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/bookings/widgets/show_location_sheet.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/requests/models/request_status.dart';
import 'package:prokat/features/requests/providers/request_mutation_provider.dart';
import 'package:prokat/features/requests/widgets.dart/request_status_badge.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class RequestMessageBubble extends ConsumerStatefulWidget {
  final ChatModel? currentChat;
  final ChatMessageModel message;
  final AppMode mode;

  const RequestMessageBubble({
    super.key,
    required this.message,
    required this.mode,
    this.currentChat,
  });

  @override
  ConsumerState<RequestMessageBubble> createState() =>
      _RequestMessageBubbleState();
}

class _RequestMessageBubbleState extends ConsumerState<RequestMessageBubble> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final request = widget.currentChat?.request;

    if (request == null) return Text(l10n.errorLoadingRequest);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Request Label / Icon / Status
          Row(
            children: [
              Icon(
                Icons.request_page_outlined,
                color: theme.colorScheme.onPrimary,
                size: 26,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.newRequest,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),

              RequestStatusBadge(status: request.status, mode: widget.mode),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              SizedBox(
                width: 90,
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.propane_outlined,
                          color: theme.colorScheme.onPrimary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${request.capacity} ${l10n.unitCubicMeters}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.cable_outlined,
                          color: theme.colorScheme.onPrimary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${10} ${l10n.unitMeters}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Location
          InfoTile.secondary(
            icon: Icons.location_on_outlined,
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
          ),

          const SizedBox(height: 8),

          // Date Time
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: InfoTile.secondary(
                  icon: Icons.event_outlined,
                  label: l10n.date,
                  value: () {
                    if (request.requiredOn == null) return l10n.pending;

                    // 1. Format the date part cleanly (e.g., "02 Jun 2026")
                    final dateStr = DateFormat(
                      'dd MMM yyyy',
                    ).format(request.requiredOn!.toLocal());

                    // 3. Return just the date if no time was specified
                    return dateStr;
                  }(),
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: InfoTile.secondary(
                  icon: Icons.access_time_outlined,
                  label: l10n.time,
                  value: () {
                    // 2. If a specific time exists, format and append it (e.g., "14:30")
                    if (request.requiredAt != null) {
                      final timeStr = DateFormat(
                        'HH:mm',
                      ).format(request.requiredAt!.toLocal());
                      return timeStr;
                    }

                    return "";
                  }(),
                ),
              ),
            ],
          ),

          if (request.comment?.isNotEmpty ?? false)
            InfoTile.secondary(label: l10n.comments, value: request.comment!),

          const SizedBox(height: 8),

          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.offeredRate.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey,
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    "${formatPrice(request.offeredPrice)} ${getPriceRate(request.offeredPriceRate, l10n: l10n)}",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              if (widget.mode == AppMode.clientMode &&
                  [
                    RequestStatus.created,
                    RequestStatus.responded,
                  ].contains(request.status)) ...[
                if (ref
                    .watch(requestMutationProvider)
                    .isActionActive("request:${request.id}:cancel"))
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
                    onPressed: () =>
                        _showCancelConfirmation(context, ref, request.id, l10n),
                    icon: Icon(
                      LucideIcons.x,
                      size: 25,
                      color: theme.colorScheme.error,
                    ),
                  ),
              ],
            ],
          ),
          // Offered Rate and Comment
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
  unawaited(
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
                  .read(requestMutationProvider.notifier)
                  .cancelRequest(requestId);

              AppSnackBar.show(
                message: result.success
                    ? l10n.requestCancelled
                    : l10n.failedToCancelRequest,
                isSuccess: result.success,
                isError: !result.success,
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
    ),
  );
}
