import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/edit_sheet.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';
import 'package:prokat/features/equipment/widgets/owner/modern_text_field.dart';
import 'package:prokat/l10n/app_localizations.dart';

Future<void> updateEquipmentDetails(
  BuildContext context,
  WidgetRef ref,
  Equipment equipment,
  TextEditingController nameController,
  TextEditingController modelController,
  TextEditingController commentController,
  TextEditingController rentConditionController,
) async {
  final l10n = AppLocalizations.of(context)!;
  final id = equipment.id;
  final name = nameController.text.trim();
  final model = modelController.text.trim();
  final ownerComment = commentController.text.trim();
  final rentCondition = rentConditionController.text.trim();

  if (name.isEmpty) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.pleaseEnterValidValues)));
    return;
  }

  try {
    await ref.read(equipmentMutationProvider.notifier).updateEquipment({
      "id": id,
      "name": name,
      "model": model,
      "ownerComment": ownerComment,
      "rentCondition": rentCondition,
    });

    if (context.mounted) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.equipmentUpdatedSuccessfully)),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.failedToUpdateEquipment)));
    }
  }
}

void equipmentDetailsSheet(
  BuildContext context,
  WidgetRef ref,
  Equipment equipment,
) {
  final l10n = AppLocalizations.of(context)!;
  final nameController = TextEditingController(text: equipment.name);
  final modelController = TextEditingController(text: equipment.model);
  final commentController = TextEditingController(
    text: equipment.ownerComment ?? "",
  );
  final rentConditionController = TextEditingController(
    text: equipment.rentCondition,
  );

  showEditSheet(
    context: context,
    sheet: EditSheet(
      title: l10n.editEquipment,
      buttonText: l10n.updateDetails,
      onSubmit: () => updateEquipmentDetails(
        context,
        ref,
        equipment,
        nameController,
        modelController,
        commentController,
        rentConditionController,
      ),

      child: Column(
        children: [
          ModernTextField(
            controller: nameController,
            label: l10n.name,
            icon: Icons.inventory_2_rounded,
          ),
          ModernTextField(
            controller: modelController,
            label: l10n.model,
            icon: Icons.label_rounded,
          ),
          const SizedBox(height: 16),
          ModernTextField(
            controller: commentController,
            label: l10n.ownerComment,
            icon: Icons.comment_rounded,
            maxLines: 1,
          ),
          ModernTextField(
            controller: rentConditionController,
            label: l10n.rentCondition,
            icon: Icons.rule_rounded,
            maxLines: 1,
          ),
        ],
      ),
    ),
  );
}
