import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/info_tile.dart';
import 'package:prokat/features/bookings/widgets/booking_status_badge.dart';
import 'package:prokat/features/bookings/widgets/show_location_sheet.dart';
import 'package:prokat/features/chat/state/chat_message_model.dart';
import 'package:prokat/features/chat/state/chat_provider.dart';
import 'package:prokat/features/equipment/widgets/sheets/equipment_details_sheet.dart';
import 'package:prokat/l10n/app_localizations.dart';

class BookingMessageBubble extends ConsumerStatefulWidget {
  final ChatMessageModel message;

  const BookingMessageBubble({super.key, required this.message});

  @override
  ConsumerState<BookingMessageBubble> createState() =>
      _BookingMessageBubbleState();
}

class _BookingMessageBubbleState extends ConsumerState<BookingMessageBubble> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final booking = ref.read(chatProvider).currentChat?.booking;

    if (booking == null) return const Text("Failed to load booking");

    final equipment = booking.equipment;
    final location = booking.location;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Row (Order Info Text & Colored Status Badge)
          Row(
            children: [
              Icon(
                Icons.assignment_outlined,
                color: theme.primaryColor,
                size: 22,
              ),
              const SizedBox(width: 6),
              Text(
                "New Order",
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),

              Spacer(),

              BookingStatusBadge(status: booking.status),
            ],
          ),

          const SizedBox(height: 8),

          // 2. Equipment Body (Triggers the external Details Sheet)
          InkWell(
            onTap: () {
              EquipmentDetailsSheet.show(
                context,
                name: equipment?.name,
                model: equipment?.model,
                plateNumber: equipment?.plateNumber,
                imageUrl: equipment?.imageUrl,
                specifications: const [
                  "Vacuum Pump",
                  "Capacity 5000L",
                ], // Optional list configuration
              );
            },
            borderRadius: const BorderRadius.all(Radius.zero),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (equipment?.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      equipment!.imageUrl!,
                      width: 80,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 54,
                        height: 40,
                        color: const Color(0xFFE0E0E0),
                        child: const Icon(
                          Icons.image,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 54,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.image,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        equipment?.name ?? "Unknown Equipment",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        equipment?.model ?? "",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),
              ],
            ),
          ),

          const SizedBox(height: 8),

          //  Location
          if (location != null) ...[
            Row(
              children: [
                Expanded(
                  child: InfoTile(
                    icon: Icons.location_on_outlined,
                    value: booking.location?.street ?? "",
                    onTap: () => showLocationSheet(context, location),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          // Date Time
          Row(
            children: [
              Expanded(
                child: InfoTile(
                  icon: Icons.event_outlined,
                  value: () {
                    if (booking.bookedOn == null) return "TBD";

                    // 1. Format the date part cleanly (e.g., "02 Jun 2026")
                    final dateStr = DateFormat(
                      'dd MMM yyyy',
                    ).format(booking.bookedOn!.toLocal());

                    // 3. Return just the date if no time was specified
                    return dateStr;
                  }(),
                ),
              ),

              if (booking.bookedAt != null) ...[
                const SizedBox(width: 8),

                Expanded(
                  child: InfoTile(
                    icon: Icons.access_time_outlined,
                    value: booking.bookedAt != null
                        ? DateFormat(
                            'HH:mm',
                          ).format(booking.bookedAt!.toLocal())
                        : "",
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          InfoTile(
            value:
                "${formatPrice(booking.price)} ${getPriceRate(booking.priceRate, l10n: l10n)}",
          ),
        ],
      ),
    );
  }
}
