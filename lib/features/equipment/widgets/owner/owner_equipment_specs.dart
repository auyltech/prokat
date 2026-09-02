import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/input_field.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/catalog/models/catalog_bundle.dart';
import 'package:prokat/features/catalog/models/catalog_spec_type.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/models/equipment_spec.dart';
import 'package:prokat/features/equipment/models/equipment_spec_value_input.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_editor_provider.dart';
import 'package:prokat/features/equipment/state/owner_equipment_editor_notifier.dart';
import 'package:prokat/features/equipment/state/owner_equipment_editor_state.dart';
import 'package:prokat/features/equipment/widgets/owner/equipment_editor_section.dart';
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
  final Map<String, bool> _boolByKey = {};
  final Map<String, List<String>> _optionsByKey = {};

  List<EquipmentSpec> _sortedSpecs = const [];

  bool _isDirty = false;
  bool _isSaving = false;
  bool _saveAttempted = false;

  bool _didInit = false;

  bool get _canEdit => widget.equipment.isDraft;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    _rebuildControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _publish();
    });
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
        if ((a.numberValue ?? 0) != (b.numberValue ?? 0)) return true;
        if (a.boolValue != b.boolValue) return true;
        if ((a.textValue ?? '') != (b.textValue ?? '')) return true;
        if ((a.specId ?? '') != (b.specId ?? '')) return true;
        if (!_sameIds(a.optionIds, b.optionIds)) return true;
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
        _saveAttempted = false;
        _errorsByKey.clear();
      });
      _publish();
    }
  }

  void _rebuildControllers() {
    _sortedSpecs = [...(widget.equipment.specs ?? const <EquipmentSpec>[])]
      ..sort((a, b) => (a.sortIndex ?? 0).compareTo(b.sortIndex ?? 0));

    for (var i = 0; i < _sortedSpecs.length; i++) {
      final spec = _sortedSpecs[i];
      final key = _controllerKey(spec, i);
      final catalog = ref.read(catalogProvider).valueOrNull;
      final catalogSpec = catalog?.specById(spec.specId);
      final type = spec.resolvedType(catalogSpec);
      final normalized = _currentWireValue(spec, catalog, type);
      _originalValuesByKey[key] = normalized;

      if (type == CatalogSpecType.boolean) {
        _boolByKey[key] = spec.boolValue ?? normalized == 'true';
      } else if (type == CatalogSpecType.select ||
          type == CatalogSpecType.multiSelect) {
        _optionsByKey[key] = [...spec.optionIds];
      } else {
        _controllersByKey[key] = TextEditingController(
          text: spec.numberValue?.toString() ?? spec.textValue ?? '',
        );
      }
    }
  }

  String _controllerKey(EquipmentSpec spec, int index) {
    return '${spec.id}::$index';
  }

  String _currentWireValue(
    EquipmentSpec spec,
    CatalogBundle? catalog,
    CatalogSpecType type, {
    String? key,
  }) {
    final draftKey = key ?? '';
    if (type == CatalogSpecType.boolean) {
      final value = _boolByKey[draftKey] ?? spec.boolValue;
      if (value == null) return '';
      return value ? 'true' : 'false';
    }
    if (type == CatalogSpecType.select || type == CatalogSpecType.multiSelect) {
      final ids = _optionsByKey[draftKey] ?? spec.optionIds;
      final slugs = ids
          .map((id) => catalog?.optionById(id)?.slug ?? id)
          .where((item) => item.isNotEmpty)
          .toList();
      return slugs.join(',');
    }
    final controller = _controllersByKey[draftKey];
    if (controller != null) return controller.text.trim();
    if (spec.numberValue != null) return spec.numberValue.toString();
    return (spec.textValue ?? '').trim();
  }

  OwnerEquipmentEditorNotifier get _editor {
    return ref.read(ownerEquipmentEditorProvider(widget.equipment.id).notifier);
  }

  bool get _isComplete {
    if (_sortedSpecs.isEmpty) return true;
    final catalog = ref.read(catalogProvider).valueOrNull;
    for (var i = 0; i < _sortedSpecs.length; i++) {
      final spec = _sortedSpecs[i];
      if (spec.isRequired != true) continue;
      final key = _controllerKey(spec, i);
      final type = spec.resolvedType(catalog?.specById(spec.specId));
      if (!type.isKnown) continue;
      if (_currentWireValue(spec, catalog, type, key: key).isEmpty) {
        return false;
      }
    }
    return true;
  }

  void _bind() {
    _editor.bind(
      id: OwnerEquipmentBlockId.specs,
      save: ({required bool notify}) => _handleSave(notify: notify),
      validate: () {
        final valid = _validate();
        setState(() {});
        return valid;
      },
    );
  }

  void _publish() {
    _bind();
    _editor.report(
      id: OwnerEquipmentBlockId.specs,
      isDirty: _canEdit && _isDirty,
      isSaving: _isSaving,
      indicator: blockIndicatorFor(
        complete: _isComplete,
        saveAttempted: _saveAttempted,
      ),
    );
  }

  void _onFieldChanged() {
    if (!_canEdit) return;
    final dirty = _computeIsDirty();
    if (_saveAttempted) _validate();
    setState(() => _isDirty = dirty);
    _publish();
  }

  bool _computeIsDirty() {
    final catalog = ref.read(catalogProvider).valueOrNull;
    for (var i = 0; i < _sortedSpecs.length; i++) {
      final spec = _sortedSpecs[i];
      final key = _controllerKey(spec, i);
      final type = spec.resolvedType(catalog?.specById(spec.specId));
      if (!type.isKnown) continue;
      final current = _currentWireValue(spec, catalog, type, key: key);
      final original = _originalValuesByKey[key] ?? '';
      if (current != original) return true;
    }
    return false;
  }

  bool _validate() {
    _saveAttempted = true;
    _errorsByKey.clear();
    final catalog = ref.read(catalogProvider).valueOrNull;
    var ok = true;

    for (var i = 0; i < _sortedSpecs.length; i++) {
      final spec = _sortedSpecs[i];
      final key = _controllerKey(spec, i);
      final type = spec.resolvedType(catalog?.specById(spec.specId));
      if (!type.isKnown) continue;

      final isRequired = spec.isRequired == true;
      final value = _currentWireValue(spec, catalog, type, key: key);

      if (isRequired && value.isEmpty) {
        _errorsByKey[key] = 'required';
        ok = false;
        continue;
      }

      if (type == CatalogSpecType.number &&
          value.isNotEmpty &&
          num.tryParse(value.replaceAll(',', '.')) == null) {
        _errorsByKey[key] = 'invalidNumber';
        ok = false;
        continue;
      }

      _errorsByKey[key] = null;
    }

    return ok;
  }

  Future<bool> _handleSave({required bool notify}) async {
    final l10n = AppLocalizations.of(context)!;
    if (!_canEdit || !_isDirty || _isSaving) return false;

    final valid = _validate();
    if (!valid) {
      setState(() {});
      _publish();
      if (notify) {
        AppSnackBar.show(message: l10n.pleaseFillMissingInfo);
      }
      return false;
    }

    setState(() => _isSaving = true);
    _publish();
    final catalog = ref.read(catalogProvider).valueOrNull;
    final payload = <EquipmentSpecValueInput>[];

    for (var i = 0; i < _sortedSpecs.length; i++) {
      final spec = _sortedSpecs[i];
      final key = _controllerKey(spec, i);
      final type = spec.resolvedType(catalog?.specById(spec.specId));
      if (!type.isKnown) continue;
      final registryId = spec.specId ?? spec.id;
      if (registryId.isEmpty) continue;

      if (type == CatalogSpecType.boolean) {
        payload.add(
          EquipmentSpecValueInput(
            specId: registryId,
            boolValue: _boolByKey[key] ?? spec.boolValue,
          ),
        );
      } else if (type == CatalogSpecType.select ||
          type == CatalogSpecType.multiSelect) {
        payload.add(
          EquipmentSpecValueInput(
            specId: registryId,
            optionIds: _optionsByKey[key] ?? spec.optionIds,
          ),
        );
      } else if (type == CatalogSpecType.number) {
        final raw = _controllersByKey[key]?.text.trim() ?? '';
        payload.add(
          EquipmentSpecValueInput(
            specId: registryId,
            numberValue: raw.isEmpty
                ? null
                : double.tryParse(raw.replaceAll(',', '.')),
          ),
        );
      } else {
        final raw = _controllersByKey[key]?.text.trim() ?? '';
        payload.add(
          EquipmentSpecValueInput(
            specId: registryId,
            textValue: raw.isEmpty ? null : raw,
          ),
        );
      }
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
          final type = spec.resolvedType(catalog?.specById(spec.specId));
          if (!type.isKnown) continue;
          _originalValuesByKey[key] = _currentWireValue(
            spec,
            catalog,
            type,
            key: key,
          );
        }

        setState(() {
          _isDirty = false;
          _isSaving = false;
          _errorsByKey.clear();
        });
        _editor.markSaved(
          OwnerEquipmentBlockId.specs,
          indicator: blockIndicatorFor(
            complete: _isComplete,
            saveAttempted: _saveAttempted,
          ),
        );
      } else {
        setState(() => _isSaving = false);
        _publish();
      }

      if (notify) {
        AppSnackBar.show(
          message: result ? l10n.equipmentUpdated : l10n.updateFailed,
          isSuccess: result,
          isError: !result,
        );
      }
      return result;
    } catch (_) {
      setState(() => _isSaving = false);
      _publish();
      if (notify) {
        AppSnackBar.show(message: l10n.updateFailed, isError: true);
      }
      return false;
    }
  }

  void _disposeControllers() {
    for (final c in _controllersByKey.values) {
      c.dispose();
    }
    _controllersByKey.clear();
    _originalValuesByKey.clear();
    _boolByKey.clear();
    _optionsByKey.clear();
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
    final locale = Localizations.localeOf(context).languageCode;
    final catalog = ref.watch(catalogProvider).valueOrNull;
    final colorScheme = theme.colorScheme;
    final ghostGray = colorScheme.onSurfaceVariant;

    _bind();

    final hasSpecs = _sortedSpecs.isNotEmpty;
    final view = ref
        .watch(ownerEquipmentEditorProvider(widget.equipment.id))
        .block(OwnerEquipmentBlockId.specs);

    Widget specFields() {
      if (!hasSpecs) {
        return Text(
          l10n.noSpecsConfigured,
          style: theme.textTheme.bodyMedium?.copyWith(color: ghostGray),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(_sortedSpecs.length, (i) {
          final spec = _sortedSpecs[i];
          final key = _controllerKey(spec, i);
          final catalogSpec = catalog?.specById(spec.specId);
          final type = spec.resolvedType(catalogSpec);
          if (!type.isKnown) {
            return const SizedBox.shrink();
          }

          final errorKey = _errorsByKey[key];
          final String? errorText = errorKey == 'required'
              ? l10n.required
              : errorKey == 'invalidNumber'
              ? l10n.invalidNumber
              : null;
          final label = spec.displayName(locale);
          final unit = catalogSpec == null
              ? spec.unit
              : catalog?.unitById(catalogSpec.unitId)?.symbol(locale) ??
                    spec.unit;
          final isRequired = spec.isRequired == true;

          if (type == CatalogSpecType.boolean) {
            return SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(label),
              value: _boolByKey[key] ?? false,
              onChanged: !_canEdit
                  ? null
                  : (value) {
                      _boolByKey[key] = value;
                      _onFieldChanged();
                    },
            );
          }

          if (type == CatalogSpecType.select) {
            final options = catalogSpec == null
                ? const <CatalogSpecOption>[]
                : catalog!.optionsForSpec(catalogSpec.id);
            final selected = (_optionsByKey[key] ?? spec.optionIds)
                .where((id) => id.isNotEmpty)
                .firstOrNull;
            final optionIds = options.map((option) => option.id).toSet();
            final dropdownValue =
                selected != null && optionIds.contains(selected)
                ? selected
                : null;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: label,
                  errorText: errorText,
                  filled: !_canEdit,
                  fillColor: !_canEdit
                      ? colorScheme.surfaceContainerHighest
                      : null,
                  border: const OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: dropdownValue,
                    hint: Text(label),
                    items: options
                        .map(
                          (option) => DropdownMenuItem(
                            value: option.id,
                            child: Text(option.label(locale)),
                          ),
                        )
                        .toList(),
                    onChanged: !_canEdit
                        ? null
                        : (value) {
                            _optionsByKey[key] = value == null ? [] : [value];
                            _onFieldChanged();
                          },
                  ),
                ),
              ),
            );
          }

          if (type == CatalogSpecType.multiSelect) {
            final options = catalogSpec == null
                ? const <CatalogSpecOption>[]
                : catalog!.optionsForSpec(catalogSpec.id);
            final selected = {...(_optionsByKey[key] ?? spec.optionIds)};
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.labelLarge),
                  Wrap(
                    spacing: 8,
                    children: options.map((option) {
                      final isSelected = selected.contains(option.id);
                      return FilterChip(
                        label: Text(option.label(locale)),
                        selected: isSelected,
                        onSelected: !_canEdit
                            ? null
                            : (next) {
                                if (next) {
                                  selected.add(option.id);
                                } else {
                                  selected.remove(option.id);
                                }
                                _optionsByKey[key] = selected.toList();
                                _onFieldChanged();
                              },
                      );
                    }).toList(),
                  ),
                  if (errorText != null)
                    Text(
                      errorText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                ],
              ),
            );
          }

          final controller = _controllersByKey[key];
          if (controller == null) return const SizedBox.shrink();

          return InputField(
            label: label,
            controller: controller,
            hint: label,
            isRequired: isRequired && !spec.hasFilledValue,
            suffixText: unit.trim().isEmpty ? null : unit.trim(),
            onChanged: _onFieldChanged,
            isNumeric: type == CatalogSpecType.number,
            errorText: errorText,
            readOnly: !_canEdit,
          );
        }),
      );
    }

    return EquipmentEditorSection(
      title: l10n.technicalSpecs,
      indicator: view.indicator,
      expanded: view.isExpanded,
      onToggleExpanded: () =>
          _editor.toggleExpanded(OwnerEquipmentBlockId.specs),
      saveLabel: l10n.save,
      showSave: _canEdit && _isDirty,
      saveEnabled: _canEdit && _isDirty && !_isSaving,
      saveLoading: _isSaving,
      onSave: () => _handleSave(notify: true),
      child: specFields(),
    );
  }
}

bool _sameIds(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) return false;
  }
  return true;
}
