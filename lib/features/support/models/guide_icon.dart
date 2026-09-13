import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum GuideIcon {
  findEquipment,
  createRequest,
  listEquipment,
  orderChat,
  safetyHelp,
  gettingStarted,
  booking,
  equipment,
  payments,
  safety,
  account,
}

const _guideIconSize = 26.0;

IconData guideIcon(GuideIcon icon) {
  switch (icon) {
    case GuideIcon.findEquipment:
    case GuideIcon.gettingStarted:
      return LucideIcons.packageSearch;
    case GuideIcon.createRequest:
    case GuideIcon.booking:
      return LucideIcons.clipboardPlus;
    case GuideIcon.listEquipment:
    case GuideIcon.equipment:
      return LucideIcons.packagePlus;
    case GuideIcon.orderChat:
    case GuideIcon.payments:
      return LucideIcons.messagesSquare;
    case GuideIcon.safetyHelp:
    case GuideIcon.safety:
      return LucideIcons.shieldCheck;
    case GuideIcon.account:
      return LucideIcons.user;
  }
}

Widget guideIconWidget(
  GuideIcon icon, {
  required Color color,
  Color? badgeBackground,
  double size = _guideIconSize,
}) {
  return Icon(guideIcon(icon), color: color, size: size);
}
