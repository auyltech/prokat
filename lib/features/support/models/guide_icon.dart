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
      return LucideIcons.truck;
    case GuideIcon.createRequest:
    case GuideIcon.booking:
      return LucideIcons.clipboardPlus;
    case GuideIcon.listEquipment:
    case GuideIcon.equipment:
      return LucideIcons.truck;
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
  final action = switch (icon) {
    GuideIcon.findEquipment || GuideIcon.gettingStarted => LucideIcons.search,
    GuideIcon.listEquipment || GuideIcon.equipment => LucideIcons.plus,
    _ => null,
  };
  if (action == null) return Icon(guideIcon(icon), color: color, size: size);
  return SizedBox.square(
    dimension: size + 8,
    child: Stack(
      children: [
        Positioned(
          left: 0,
          top: 0,
          child: Icon(LucideIcons.truck, color: color, size: size),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: badgeBackground ?? color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(action, size: size * 0.54, color: color),
          ),
        ),
      ],
    ),
  );
}
