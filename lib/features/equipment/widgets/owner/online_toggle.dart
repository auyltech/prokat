import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/state/equipment_provider.dart';

class OnlineToggle extends ConsumerWidget {
  final String id;
  final bool isVisible;

  const OnlineToggle({super.key, required this.id, required this.isVisible});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubmitting =
        ref.watch(equipmentProvider).isSubmitting &&
        ref.watch(equipmentProvider).actionId == "equipment:status:$id";

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isSubmitting) CircularProgressIndicator(),

        Text(
          isVisible ? "ONLINE" : "OFFLINE",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isVisible
                ? const Color.fromARGB(255, 0, 160, 5)
                : const Color.fromARGB(255, 218, 0, 0),
          ),
        ),

        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: isVisible,
            activeThumbColor: const Color(0xFF4E73DF),
            onChanged: (val) async {
              await ref
                  .read(equipmentProvider.notifier)
                  .updateVisibilityStatus(id, val, EquipmentStatus.available);
            },
          ),
        ),
      ],
    );
  }
}
