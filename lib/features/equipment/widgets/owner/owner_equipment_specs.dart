import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/custom_icon_button.dart';
import 'package:prokat/core/widgets/input_field.dart';
import 'package:prokat/core/widgets/section_title.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/models/equipment_spec.dart';
import 'package:prokat/features/equipment/models/equipment_spec_update_input.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

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
        _errorsByKey[key] = 'required';
        ok = false;
        continue;
      }

      if (type == 'NUMBER' && value.isNotEmpty && num.tryParse(value) == null) {
        _errorsByKey[key] = 'invalidNumber';
        ok = false;
        continue;
      }

      _errorsByKey[key] = null;
    }

    return ok;
  }

  Future<void> _handleSave(AppLocalizations l10n) async {
    if (!_isDirty || _isSaving) return;

    final valid = _validate();

    if (!valid) {
      setState(() {});
      AppSnackBar.show(message: l10n.pleaseFillMissingInfo);
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
      final result = await ref
          .read(equipmentMutationProvider.notifier)
          .updateEquipmentSpecs(
            equipmentId: widget.equipment.id,
            specs: payload,
          );

      if (result) {
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
      } else {
        setState(() => _isSaving = false);
      }

      AppSnackBar.show(
        message: result ? l10n.equipmentUpdated : l10n.updateFailed,
        isSuccess: result,
        isError: !result,
      );
    } catch (_) {
      setState(() => _isSaving = false);
      AppSnackBar.show(message: l10n.updateFailed, isError: true);
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
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = theme.colorScheme;

    final ghostGray = colorScheme.onSurface.withValues(alpha: 0.6);

    final hasSpecs = _sortedSpecs.isNotEmpty;
    final canSave =
        hasSpecs &&
        widget.equipment.isDraft &&
        _isDirty &&
        !_isSaving &&
        !_hasErrors();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: SectionTitle(title: l10n.technicalSpecs)),

            CustomIconButton(
              onPressed: canSave ? () => _handleSave(l10n) : null,
              icon: _isDirty ? Icons.save_rounded : Icons.lock_outline_rounded,
              iconColor: _isDirty
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
          ],
        ),

        SizedBox(height: 8),

        if (!hasSpecs)
          Text(
            l10n.noSpecsConfigured,
            style: theme.textTheme.bodyMedium?.copyWith(color: ghostGray),
          )
        else
          ...List.generate(_sortedSpecs.length, (i) {
            final spec = _sortedSpecs[i];
            final key = _controllerKey(spec, i);
            final controller = _controllersByKey[key];

            if (controller == null) return const SizedBox.shrink();

            final type = (spec.inputType ?? 'TEXT').toUpperCase();
            final errorKey = _errorsByKey[key];
            final String? errorText = errorKey == 'required'
                ? l10n.required
                : errorKey == 'invalidNumber'
                ? l10n.invalidNumber
                : null;

            final label = spec.name.trim().isNotEmpty
                ? spec.name.trim()
                : (spec.key.trim().isNotEmpty ? spec.key.trim() : 'Spec');

            final isRequired = spec.isRequired == true;

            return InputField(
              label: label,
              controller: controller,
              hint: label,
              isRequired:
                  isRequired &&
                  (spec.value == null || spec.value?.isEmpty != false),
              suffixText: spec.unit.trim().isEmpty ? null : spec.unit.trim(),
              onChanged: _onFieldChanged,
              isNumeric: type == "number",
              errorText: errorText,
            );
          }),
      ],
    );
  }
}
