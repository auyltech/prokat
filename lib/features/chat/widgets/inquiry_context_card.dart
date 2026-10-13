import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/l10n/app_localizations.dart';

/// Context for a direct listing discussion, including after it becomes an order.
class InquiryContextCard extends StatelessWidget {
  final ChatModel chat;
  final VoidCallback? onSetTerms;

  const InquiryContextCard({super.key, required this.chat, this.onSetTerms});

  @override
  Widget build(BuildContext context) {
    final equipment = chat.inquiryEquipment;
    if (equipment == null) return const SizedBox.shrink();
    final palette = ProkatFlowPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final status = switch (chat.booking?.status) {
      null => l10n.inquiryStatus,
      BookingStatus.created => l10n.requestPending,
      BookingStatus.confirmed => l10n.orderConfirmed,
      BookingStatus.completed || BookingStatus.reviewed => l10n.orderCompleted,
      _ => l10n.orderCancelled,
    };
    final canSetTerms =
        chat.booking == null &&
        onSetTerms != null &&
        chat.status == ChatStatus.active;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Material(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: canSetTerms ? onSetTerms : null,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: palette.border),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox.square(
                    dimension: 54,
                    child: OptimizedNetworkImage(
                      imageUrl: equipment.primaryImageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        equipment.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: palette.title,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        canSetTerms
                            ? '$status · ${l10n.inquiryCreateOrder}'
                            : status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: canSetTerms
                              ? palette.primary
                              : palette.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canSetTerms) ...[
                  const SizedBox(width: 4),
                  Icon(
                    LucideIcons.chevronRight,
                    color: palette.primary,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
