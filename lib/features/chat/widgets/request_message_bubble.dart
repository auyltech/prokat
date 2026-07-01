import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/info_tile.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/features/bookings/widgets/show_location_sheet.dart';
import 'package:prokat/features/chat/state/chat_message_model.dart';
import 'package:prokat/features/chat/state/chat_provider.dart';
import 'package:prokat/features/requests/widgets.dart/request_status_badge.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class RequestMessageBubble extends ConsumerStatefulWidget {
  final ChatMessageModel message;
  final String mode;

  const RequestMessageBubble({
    super.key,
    required this.message,
    required this.mode,
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

    // final messageRequest = switch (widget.message.meta) {
    //   Map<String, dynamic> meta => RequestModel.fromJson(meta),
    //   _ => null,
    // };

    // if (messageRequest == null) return const SizedBox.shrink();

    final request = ref.read(chatProvider).currentChat?.request;

    if (request == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
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
                color: theme.primaryColor,
                size: 26,
              ),
              const SizedBox(width: 8),
              Text(
                'New Request',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
              Spacer(),

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
                        color: Colors.black,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.propane_outlined, color: Colors.grey[900]),
                        SizedBox(width: 4),
                        Text(
                          '${request.capacity} M3',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.cable_outlined, color: Colors.grey[900]),
                        SizedBox(width: 4),
                        Text(
                          '${10} M',
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
            label: "Location",
            value: request.location.street,
            onTap: () => showLocationSheet(context, request.location),
          ),

          const SizedBox(height: 8),

          // Date Time
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: InfoTile.secondary(
                  icon: Icons.event_outlined,
                  label: "Date",
                  value: () {
                    if (request.requiredOn == null) return "PENDING";

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
                  label: "Time",
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

          const SizedBox(height: 8),

          // Offered Rate and Comment
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
                  color: const Color(0xFF0D47A1),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          if (request.comment?.isNotEmpty ?? false)
            InfoTile.secondary(label: l10n.comments, value: request.comment!),
        ],
      ),
    );
  }
}
