// features/equipment/widgets/sheets/equipment_preview_sheet.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';

class EquipmentPreviewSheet extends StatelessWidget {
  final Equipment equipment;
  final VoidCallback onClose;

  const EquipmentPreviewSheet({
    super.key,
    required this.equipment,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                equipment.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(equipment.model),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/booking/${equipment.id}',
                        );
                      },
                      child: const Text('Book'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {
                      context.push(AppRoutes.clientRequestsCreate);
                    },
                    child: const Text('Request'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
