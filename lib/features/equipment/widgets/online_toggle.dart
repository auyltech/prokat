import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';

class OnlineToggle extends ConsumerWidget {
  final String id;
  final bool isVisible;

  const OnlineToggle({super.key, required this.id, required this.isVisible});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionId = "equipment:update:$id:status";

    final isSubmitting = ref
        .watch(equipmentMutationProvider.notifier)
        .isActionActive(actionId);

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
              final result = await ref
                  .read(equipmentMutationProvider.notifier)
                  .toggleEquipmentOnline(id, val);

              if (context.mounted) {
                AppSnackBar.show(
                  message: result
                      ? "Equipment is now ${!isVisible ? "online" : "offline"}"
                      : "Failed to toggle ${!isVisible ? "online" : "offline"}",
                  isSuccess: result,
                  isError: !result,
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
