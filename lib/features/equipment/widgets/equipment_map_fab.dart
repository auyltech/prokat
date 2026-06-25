import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';

class EquipmentMapFab extends StatelessWidget {
  const EquipmentMapFab({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 96, // 👈 keeps clear of bottom browse sheet
      child: FloatingActionButton(
        heroTag: 'equipment-map-fab',
        backgroundColor: Colors.orange,
        onPressed: () {
          context.push(AppRoutes.clientRequestsCreate);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
