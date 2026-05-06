import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/edit_sheet.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';
import 'package:prokat/features/equipment/widgets/owner/modern_text_field.dart';

Future<void> updateEquipmentDetails(
  BuildContext context,
  WidgetRef ref,
  Equipment equipment,
  TextEditingController nameController,
  TextEditingController modelController,
  TextEditingController capacityController,
  TextEditingController commentController,
  TextEditingController rentConditionController,
) async {
  final id = equipment.id;
  final name = nameController.text.trim();
  final model = modelController.text.trim();
  final capacity = int.tryParse(capacityController.text.trim());
  final ownerComment = commentController.text.trim();
  final rentCondition = rentConditionController.text.trim();

  if (name.isEmpty || capacity == null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Please enter valid values")));
    return;
  }

  try {
    await ref.read(equipmentProvider.notifier).updateEquipment({
      "id": id,
      "name": name,
      "model": model,
      "capacity": capacity,
      "ownerComment": ownerComment,
      "rentCondition": rentCondition,
    });

    if (context.mounted) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Equipment updated successfully")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Failed to update equipment")));
  }
}

void equipmentDetailsSheet(
  BuildContext context,
  WidgetRef ref,
  Equipment equipment,
) {
  final nameController = TextEditingController(text: equipment.name);
  final modelController = TextEditingController(text: equipment.model);
  final capacityController = TextEditingController(
    text: equipment.capacity.toString(),
  );
  final commentController = TextEditingController(
    text: equipment.ownerComment ?? "",
  );
  final rentConditionController = TextEditingController(
    text: equipment.rentCondition,
  );

  showEditSheet(
    context: context,
    sheet: EditSheet(
      title: "Edit Equipment",
      buttonText: "Update Details",
      onSubmit: () => updateEquipmentDetails(
        context,
        ref,
        equipment,
        nameController,
        modelController,
        capacityController,
        commentController,
        rentConditionController,
      ),

      /// The body content
      child: Column(
        children: [
          ModernTextField(
            controller: nameController,
            label: "Name",
            icon: Icons.inventory_2_rounded,
          ),

          // const SizedBox(height: 16),
          ModernTextField(
            controller: modelController,
            label: "Model",
            icon: Icons.label_rounded,
          ),

          // const SizedBox(height: 16),
          ModernTextField(
            controller: capacityController,
            label: "Capacity",
            icon: Icons.straighten_rounded,
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 16),

          ModernTextField(
            controller: commentController,
            label: "Owner Comment",
            icon: Icons.comment_rounded,
            maxLines: 1,
          ),

          // const SizedBox(height: 16),
          ModernTextField(
            controller: rentConditionController,
            label: "Rent Condition",
            icon: Icons.rule_rounded,
            maxLines: 1,
          ),
        ],
      ),
    ),
  );
}
