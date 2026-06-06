import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/info_tile.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/features/bookings/widgets/show_location_sheet.dart';
import 'package:prokat/features/chat/state/chat_message_model.dart';
import 'package:prokat/features/chat/state/chat_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class RequestMessageBubble extends ConsumerStatefulWidget {
  final ChatMessageModel message;

  const RequestMessageBubble({super.key, required this.message});

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
      padding: EdgeInsets.all(8),
      // margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color.fromARGB(87, 255, 237, 214),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3F2FD), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Request Label / Icon / Status
          Row(
            children: [
              const Icon(Icons.request_page, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              Text(
                'REQUEST',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.orange,
                ),
              ),
              Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 237, 203),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  getRequestStatus(request.status).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.orange,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

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
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Colors.black
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

          const SizedBox(height: 6),

          InfoTile(
            icon: Icons.pin_drop_rounded,
            color: const Color.fromARGB(64, 255, 237, 214),
            value: request.location.street,
            onTap: () => showLocationSheet(context, request.location),
          ),

          const SizedBox(height: 6),

          InfoTile(
            icon: Icons.timelapse,
            color: const Color.fromARGB(64, 255, 237, 214),
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

          const SizedBox(height: 6),
          // Offered Rate and Comment
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InfoTile(
                  value: formatPrice(request.offeredPrice),
                  isHighlighted: true,
                ),
              ),

              if (request.comment?.isNotEmpty ?? false)
                Expanded(
                  child: InfoTile(
                    label: l10n.comments,
                    value: request.comment!,
                    isHighlighted: true,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
