import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/edit_sheet.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';
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
    AppToast.show(
      message: l10n.pleaseEnterValidValues,
      type: AppToastType.error,
    );
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

      AppToast.show(
        message: l10n.equipmentUpdatedSuccessfully,
        type: AppToastType.success,
      );
    }
  } catch (e) {
    if (context.mounted) {
      AppToast.show(
        message: l10n.failedToUpdateEquipment,
        type: AppToastType.error,
      );
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
        spacing: AppDimens.s16$base,
        children: [
          AppTextField(
            controller: nameController,
            title: l10n.name,
            hint: l10n.name,
            prefix: const Icon(Icons.inventory_2_rounded),
          ),
          AppTextField(
            controller: modelController,
            title: l10n.model,
            hint: l10n.model,
            prefix: const Icon(Icons.label_rounded),
          ),
          AppTextField(
            controller: commentController,
            title: l10n.ownerComment,
            hint: l10n.ownerComment,
            prefix: const Icon(Icons.comment_rounded),
          ),
          AppTextField(
            controller: rentConditionController,
            title: l10n.rentCondition,
            hint: l10n.rentCondition,
            prefix: const Icon(Icons.rule_rounded),
          ),
        ],
      ),
    ),
  );
}
