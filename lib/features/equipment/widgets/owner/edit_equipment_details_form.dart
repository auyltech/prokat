import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/input_field.dart';
import 'package:prokat/core/widgets/section_title.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';

class EditEquipmentDetailsForm extends StatefulWidget {
  final Equipment equipment;
  final WidgetRef ref;

  const EditEquipmentDetailsForm({
    super.key,
    required this.equipment,
    required this.ref,
  });

  @override
  State<EditEquipmentDetailsForm> createState() =>
      _EditEquipmentDetailsFormState();
}

class _EditEquipmentDetailsFormState extends State<EditEquipmentDetailsForm> {
  late TextEditingController _nameController;
  late TextEditingController _modelController;
  late TextEditingController _plateNumberController;
  late TextEditingController _commentController;
  late TextEditingController _rentConditionController;

  Category? _selectedCategory;
  bool _isDirty = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.equipment.name);
    _modelController = TextEditingController(text: widget.equipment.model);
    _plateNumberController = TextEditingController(
      text: widget.equipment.plateNumber,
    );
    _commentController = TextEditingController(
      text: widget.equipment.ownerComment ?? "",
    );
    _rentConditionController = TextEditingController(
      text: widget.equipment.rentCondition,
    );
  }

  void _onChanged() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();

    setState(() => _isSaving = true);

    try {
      final res = await widget.ref
          .read(equipmentProvider.notifier)
          .updateEquipment({
            "id": widget.equipment.id,
            "name": name,
            "model": _modelController.text.trim(),
            "plateNumber": _plateNumberController.text.trim(),
            "ownerComment": _commentController.text.trim(),
            "rentCondition": _rentConditionController.text.trim(),
            "categoryId": _selectedCategory?.id,
          });

      if (mounted && res == true) {
        setState(() {
          _isDirty = false;
          _isSaving = false;
        });

        AppSnackBar.show(
          context,
          message: "Equipment Updated",
          isSuccess: true,
        );
      } else {
        AppSnackBar.show(
          context,
          message: "Could not save equipment",
          isError: true,
        );

        setState(() {
          _isDirty = true;
          _isSaving = false;
        });
      }
    } catch (_) {
      setState(() => _isSaving = false);

      AppSnackBar.show(
        context,
        message: "Something went wrong!",
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final accent = colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(0),
      // decoration: BoxDecoration(
      //   color: theme.cardColor,
      //   borderRadius: BorderRadius.circular(20),
      //   border: Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
      // ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Text("INFORMATION", style: theme.textTheme.titleLarge),
              SectionTitle(title: "Information"),

              _isDirty
                  ? TextButton.icon(
                      onPressed: _isSaving ? null : _handleSave,
                      icon: _isSaving
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Icon(Icons.save_rounded, size: 16),
                      label: const Text("Save"),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.onPrimary,
                        backgroundColor: accent,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.lock_outline_rounded,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        size: 18,
                      ),
                    ),
            ],
          ),

          SizedBox(height: 12),

          // SizedBox(height: 12),
          InputField(
            label: "Name",
            controller: _nameController,
            onChanged: _onChanged,
            hint: "",
          ),

          SizedBox(height: 12),

          InputField(
            label: "Model",
            controller: _modelController,
            onChanged: _onChanged,
            hint: "",
          ),

          SizedBox(height: 12),

          InputField(
            label: "Plate Number",
            controller: _plateNumberController,
            onChanged: _onChanged,
            hint: "",
          ),

          SizedBox(height: 12),

          InputField(
            label: "Rent Condition",
            controller: _rentConditionController,
            onChanged: _onChanged,
            hint: "Full load only...",
          ),

          SizedBox(height: 12),
          InputField(
            label: "Comment / Notes",
            controller: _commentController,
            onChanged: _onChanged,
            hint: "15M Hose",
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
