import 'package:flutter/material.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/chat/widgets/booking_actions/booking_chat_action_models.dart';
import 'package:prokat/features/chat/widgets/booking_actions/client_chat_action_bar.dart';
import 'package:prokat/features/chat/widgets/booking_actions/owner_chat_action_bar.dart';

class BookingChatActionBar extends StatelessWidget {
  final String chatId;
  final BookingModel booking;
  final BookingChatRole role;

  const BookingChatActionBar({
    super.key,
    required this.chatId,
    required this.booking,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return role == BookingChatRole.owner
        ? OwnerChatActionBar(chatId: chatId, booking: booking)
        : ClientChatActionBar(chatId: chatId, booking: booking);
  }
}
