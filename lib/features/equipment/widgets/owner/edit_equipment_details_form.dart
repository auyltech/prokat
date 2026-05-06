import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  
  late TextEditingController _capacityController;
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
    _capacityController = TextEditingController(
      text: widget.equipment.capacity.toString(),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final name = _nameController.text.trim();
    final capacity = int.tryParse(_capacityController.text.trim());

    if (name.isEmpty || capacity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Invalid input data"),
          backgroundColor: colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final res = await widget.ref
          .read(equipmentProvider.notifier)
          .updateEquipment({
            "id": widget.equipment.id,
            "name": name,
            "model": _modelController.text.trim(),
            "capacity": capacity,
            "ownerComment": _commentController.text.trim(),
            "rentCondition": _rentConditionController.text.trim(),
            "categoryId": _selectedCategory?.id,
          });

      if (mounted && res == true) {
        setState(() {
          _isDirty = false;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Equipment Updated"),
            backgroundColor: colorScheme.primary,
          ),
        );
      } else {
        setState(() {
          _isDirty = true;
          _isSaving = false;
        });
      }
    } catch (_) {
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Update Failed"),
          backgroundColor: colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final accent = colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("INFORMATION", style: theme.textTheme.titleLarge),

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
          _ThemedInputField(
            label: "Name",
            controller: _nameController,
            onChanged: _onChanged,
          ),

          SizedBox(height: 12),

          _ThemedInputField(
            label: "Model",
            controller: _modelController,
            onChanged: _onChanged,
          ),
          SizedBox(height: 12),
          _ThemedInputField(
            label: "Plate Number",
            controller: _plateNumberController,
            onChanged: _onChanged,
          ),
          SizedBox(height: 12),
          _ThemedInputField(
            label: "Capacity",
            controller: _capacityController,
            onChanged: _onChanged,
            isNumeric: true,
            suffixText: _selectedCategory?.capacityUnit,
          ),
          SizedBox(height: 12),
          _ThemedInputField(
            label: "Rent Condition",
            controller: _rentConditionController,
            onChanged: _onChanged,
            hintText: "Full load only...",
          ),
          SizedBox(height: 12),
          _ThemedInputField(
            label: "Comments",
            controller: _commentController,
            onChanged: _onChanged,
            isLast: true,
            hintText: "15M Hose",
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ThemedInputField extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final bool isNumeric;
  final bool isLast;
  final String? suffixText;

  const _ThemedInputField({
    required this.label,
    this.hintText,
    required this.controller,
    required this.onChanged,
    this.isNumeric = false,
    this.isLast = false,
    this.suffixText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final ghostGray = colorScheme.onSurface.withValues(alpha: 0.6);
    final accent = colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.primaryColor,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  onChanged: (_) => onChanged(),
                  keyboardType: isNumeric
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.text,
                  cursorColor: accent,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: ghostGray.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),

              if (suffixText != null)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    suffixText!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
