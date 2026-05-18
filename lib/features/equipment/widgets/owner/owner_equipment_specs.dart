import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/section_title.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/models/equipment_spec.dart';
import 'package:prokat/features/equipment/models/equipment_spec_update_input.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';

class OwnerEquipmentSpecs extends ConsumerStatefulWidget {
  final Equipment equipment;

  const OwnerEquipmentSpecs({super.key, required this.equipment});

  @override
  ConsumerState<OwnerEquipmentSpecs> createState() =>
      _OwnerEquipmentSpecsState();
}

class _OwnerEquipmentSpecsState extends ConsumerState<OwnerEquipmentSpecs> {
  final Map<String, TextEditingController> _controllersByKey = {};
  final Map<String, String> _originalValuesByKey = {};
  final Map<String, String?> _errorsByKey = {};

  List<EquipmentSpec> _sortedSpecs = const [];

  bool _isDirty = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _rebuildControllers();
  }

  @override
  void didUpdateWidget(covariant OwnerEquipmentSpecs oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldSpecs = oldWidget.equipment.specs ?? const <EquipmentSpec>[];
    final newSpecs = widget.equipment.specs ?? const <EquipmentSpec>[];

    bool hasSpecsChanged() {
      if (oldWidget.equipment.id != widget.equipment.id) return true;
      if (oldSpecs.length != newSpecs.length) return true;
      for (var i = 0; i < oldSpecs.length; i++) {
        final a = oldSpecs[i];
        final b = newSpecs[i];
        if (a.id != b.id) return true;
        if ((a.value ?? '') != (b.value ?? '')) return true;
        if ((a.inputType ?? '') != (b.inputType ?? '')) return true;
        if ((a.isRequired ?? false) != (b.isRequired ?? false)) return true;
        if ((a.sortIndex ?? 0) != (b.sortIndex ?? 0)) return true;
      }
      return false;
    }

    if (hasSpecsChanged()) {
      _disposeControllers();
      _rebuildControllers();
      setState(() {
        _isDirty = false;
        _isSaving = false;
        _errorsByKey.clear();
      });
    }
  }

  void _rebuildControllers() {
    _sortedSpecs = [...(widget.equipment.specs ?? const <EquipmentSpec>[])]
      ..sort((a, b) => (a.sortIndex ?? 0).compareTo(b.sortIndex ?? 0));

    for (var i = 0; i < _sortedSpecs.length; i++) {
      final spec = _sortedSpecs[i];
      final key = _controllerKey(spec, i);

      final normalized = _normalizeValue(spec.value, inputType: spec.inputType);
      _originalValuesByKey[key] = normalized;

      _controllersByKey[key] = TextEditingController(text: normalized);
    }
  }

  String _controllerKey(EquipmentSpec spec, int index) {
    // Defensive: allow duplicates by appending index.
    return '${spec.id}::$index';
  }

  String _normalizeValue(String? value, {String? inputType}) {
    final type = (inputType ?? '').toUpperCase();
    final v = (value ?? '').trim();
    if (type == 'BOOLEAN') {
      if (v == '1') return 'true';
      if (v == '0') return 'false';
      if (v.toLowerCase() == 'true') return 'true';
      if (v.toLowerCase() == 'false') return 'false';
      return '';
    }
    return v;
  }

  void _onFieldChanged() {
    final dirty = _computeIsDirty();
    final valid = _validate();

    setState(() {
      _isDirty = dirty;
      // Keep save disabled if invalid; actual button logic uses _hasErrors.
      if (valid) {
        // no-op; _errorsByKey already updated.
      }
    });
  }

  bool _computeIsDirty() {
    for (var i = 0; i < _sortedSpecs.length; i++) {
      final spec = _sortedSpecs[i];
      final key = _controllerKey(spec, i);
      final controller = _controllersByKey[key];
      if (controller == null) continue;

      final current = _normalizeValue(
        controller.text,
        inputType: spec.inputType,
      );
      final original = _originalValuesByKey[key] ?? '';
      if (current != original) return true;
    }
    return false;
  }

  bool _hasErrors() => _errorsByKey.values.any((e) => e != null);

  bool _validate() {
    _errorsByKey.clear();

    bool ok = true;
    for (var i = 0; i < _sortedSpecs.length; i++) {
      final spec = _sortedSpecs[i];
      final key = _controllerKey(spec, i);
      final controller = _controllersByKey[key];
      if (controller == null) continue;

      final isRequired = spec.isRequired == true;
      final type = (spec.inputType ?? '').toUpperCase();
      final value = _normalizeValue(controller.text, inputType: spec.inputType);

      if (isRequired && value.isEmpty) {
        _errorsByKey[key] = 'Required';
        ok = false;
        continue;
      }

      if (type == 'NUMBER' && value.isNotEmpty && num.tryParse(value) == null) {
        _errorsByKey[key] = 'Invalid number';
        ok = false;
        continue;
      }

      _errorsByKey[key] = null;
    }

    return ok;
  }

  Future<void> _handleSave() async {
    if (!_isDirty || _isSaving) return;

    final valid = _validate();
    if (!valid) {
      setState(() {});

      AppSnackBar.show(context, message: "Please provide missing information");

      return;
    }

    setState(() => _isSaving = true);

    final payload = <EquipmentSpecUpdateInput>[];
    for (var i = 0; i < _sortedSpecs.length; i++) {
      final spec = _sortedSpecs[i];
      final key = _controllerKey(spec, i);
      final controller = _controllersByKey[key];
      if (controller == null) continue;

      payload.add(
        EquipmentSpecUpdateInput(
          specId: spec.id,
          categorySpecId: spec.id,
          value: _normalizeValue(controller.text, inputType: spec.inputType),
        ),
      );
    }

    try {
      final ok = await ref
          .read(equipmentProvider.notifier)
          .updateEquipmentSpecs({
            "equipmentId": widget.equipment.id,
            "specs": payload,
          });

      if (!mounted) return;

      if (ok) {
        for (var i = 0; i < _sortedSpecs.length; i++) {
          final spec = _sortedSpecs[i];
          final key = _controllerKey(spec, i);
          final controller = _controllersByKey[key];
          if (controller == null) continue;
          _originalValuesByKey[key] = _normalizeValue(
            controller.text,
            inputType: spec.inputType,
          );
        }

        setState(() {
          _isDirty = false;
          _isSaving = false;
          _errorsByKey.clear();
        });

        AppSnackBar.show(
          context,
          message: "Equipment Updated",
          isSuccess: true,
        );
      } else {
        setState(() => _isSaving = false);

        AppSnackBar.show(context, message: "Update Failed", isError: true);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);

      AppSnackBar.show(context, message: "Update Failed", isError: true);
    }
  }

  void _disposeControllers() {
    for (final c in _controllersByKey.values) {
      c.dispose();
    }
    _controllersByKey.clear();
    _originalValuesByKey.clear();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final accent = colorScheme.primary;
    final ghostGray = colorScheme.onSurface.withValues(alpha: 0.6);

    final hasSpecs = _sortedSpecs.isNotEmpty;
    final canSave = hasSpecs && _isDirty && !_isSaving && !_hasErrors();

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
            children: [
              SectionTitle(title: "Technical Specs"),

              _isDirty
                  ? TextButton.icon(
                      onPressed: canSave ? _handleSave : null,
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
                      label: const Text('Save'),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.onPrimary,
                        backgroundColor: canSave ? accent : ghostGray,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
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

          // Text(
          //   'Update equipment specs. Some specs may be visible to clients.',
          //   style: theme.textTheme.labelSmall,
          // ),
          // const SizedBox(height: 12),
          if (!hasSpecs)
            Text(
              'No specs configured for this equipment yet.',
              style: theme.textTheme.bodyMedium?.copyWith(color: ghostGray),
            )
          else
            ...List.generate(_sortedSpecs.length, (i) {
              final spec = _sortedSpecs[i];
              final key = _controllerKey(spec, i);
              final controller = _controllersByKey[key];

              if (controller == null) return const SizedBox.shrink();

              final type = (spec.inputType ?? 'TEXT').toUpperCase();
              final error = _errorsByKey[key];

              final label = spec.name.trim().isNotEmpty
                  ? spec.name.trim()
                  : (spec.key.trim().isNotEmpty ? spec.key.trim() : 'Spec');

              final isRequired = spec.isRequired == true;

              return Padding(
                padding: EdgeInsets.only(
                  bottom: i == _sortedSpecs.length - 1 ? 0 : 12,
                ),
                child: _SpecField(
                  label: label,
                  isRequired: isRequired,
                  unit: spec.unit.trim().isEmpty ? null : spec.unit.trim(),
                  inputType: type,
                  controller: controller,
                  errorText: error,
                  onChanged: _onFieldChanged,
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _SpecField extends StatelessWidget {
  final String label;
  final bool isRequired;
  final String? unit;
  final String inputType;
  final TextEditingController controller;
  final String? errorText;
  final VoidCallback onChanged;

  const _SpecField({
    required this.label,
    required this.isRequired,
    required this.unit,
    required this.inputType,
    required this.controller,
    required this.errorText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final ghostGray = colorScheme.onSurface.withValues(alpha: 0.6);
    final accent = colorScheme.primary;

    Widget input;
    if (inputType == 'BOOLEAN') {
      final current = controller.text.trim().toLowerCase() == 'true';
      input = Switch(
        value: current,
        onChanged: (v) {
          controller.text = v ? 'true' : 'false';
          onChanged();
        },
      );
    } else if (inputType == 'SELECT') {
      input = TextFormField(
        controller: controller,
        enabled: false,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: InputBorder.none,
          hintText: 'Not supported yet',
          hintStyle: TextStyle(color: ghostGray.withValues(alpha: 0.5)),
        ),
      );
    } else {
      final isNumeric = inputType == 'NUMBER';
      input = TextFormField(
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
          hintText: isNumeric ? '0' : null,
          hintStyle: TextStyle(color: ghostGray.withValues(alpha: 0.4)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceBright,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label.toUpperCase(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                  if (isRequired)
                    Text(
                      ' *',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              Row(
                children: [
                  Expanded(child: input),
                  if (unit != null)
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
                        unit!,
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
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
