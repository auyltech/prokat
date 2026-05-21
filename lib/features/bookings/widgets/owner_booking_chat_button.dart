import 'package:flutter/material.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:go_router/go_router.dart';

class OwnerBookingChatButton extends StatelessWidget {
  final BookingModel booking;
  
  const OwnerBookingChatButton({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return IconButton(
      onPressed: () {
        context.push('${AppRoutes.ownerChat}/${booking.chatId}');
      },
      tooltip: 'Message Renter',
      icon: Icon(Icons.chat_bubble_outline_rounded, color: colorScheme.primary),
      style: IconButton.styleFrom(
        // Matching soft background tint highlight
        backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.15),
        padding: const EdgeInsets.all(10),
        minimumSize: const Size(44, 44),
        maximumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

