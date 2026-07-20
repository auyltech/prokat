import 'package:flutter/material.dart';

enum GuideIcon { gettingStarted, booking, equipment, payments, safety, account }

IconData guideIcon(GuideIcon icon) {
  switch (icon) {
    case GuideIcon.gettingStarted:
      return Icons.play_circle_outline;
    case GuideIcon.booking:
      return Icons.event_available_outlined;
    case GuideIcon.equipment:
      return Icons.inventory_2_outlined;
    case GuideIcon.payments:
      return Icons.credit_card_outlined;
    case GuideIcon.safety:
      return Icons.shield_outlined;
    case GuideIcon.account:
      return Icons.person_outline;
  }
}
