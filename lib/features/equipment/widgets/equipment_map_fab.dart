import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_icon_button.dart';

class EquipmentMapFab extends StatelessWidget {
  const EquipmentMapFab({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 96, // 👈 keeps clear of bottom browse sheet
      child: Hero(
        tag: 'equipment-map-fab',
        child: AppIconButton(
          icon: Icons.add,
          size: AppIconButtonSize.large,
          variant: AppIconButtonVariant.floating,
          tone: AppIconButtonTone.warning,
          onTap: () {
            unawaited(context.push(AppRoutes.clientRequestsCreate));
          },
        ),
      ),
    );
  }
}
