import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
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
import 'package:prokat/features/equipment/utils/equipment_submit_readiness.dart';
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

    if (!hasSpecsChanged()) return;
    if (_isDirty || _isSaving) return;

    if (_sameSpecIdentities(oldSpecs, newSpecs)) {
      _syncOriginalsFromWidget();
      return;
    }

    _disposeControllers();
    _rebuildControllers();
    _isDirty = false;
    _isSaving = false;
    _saveAttempted = false;
    _errorsByKey.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _publish();
    });
  }

  bool _sameSpecIdentities(
    List<EquipmentSpec> left,
    List<EquipmentSpec> right,
  ) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (left[i].id != right[i].id) return false;
      if ((left[i].specId ?? '') != (right[i].specId ?? '')) return false;
      if ((left[i].inputType ?? '') != (right[i].inputType ?? '')) return false;
      if ((left[i].sortIndex ?? 0) != (right[i].sortIndex ?? 0)) return false;
    }
    return true;
  }

  void _syncOriginalsFromWidget() {
    final catalog = ref.read(catalogProvider).valueOrNull;
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
  }

  void _rebuildControllers() {
    final catalog = ref.read(catalogProvider).valueOrNull;
    _sortedSpecs = [...(widget.equipment.specs ?? const <EquipmentSpec>[])]
      ..sort((a, b) {
        final aPump = _isPumpPowerSpec(a, catalog?.specById(a.specId)) ? 1 : 0;
        final bPump = _isPumpPowerSpec(b, catalog?.specById(b.specId)) ? 1 : 0;
        if (aPump != bPump) return aPump.compareTo(bPump);
        return (a.sortIndex ?? 0).compareTo(b.sortIndex ?? 0);
      });

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
      if (!equipmentSpecIsRequired(spec)) continue;
      final key = _controllerKey(spec, i);
      final type = spec.resolvedType(catalog?.specById(spec.specId));
      if (!type.isKnown) continue;
      if (_currentWireValue(spec, catalog, type, key: key).isEmpty) {
        return false;
      }
    }
    return true;
  }

  bool get _hasValidationErrors =>
      _errorsByKey.values.any((error) => error != null && error.isNotEmpty);

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
        hasValidationErrors: _hasValidationErrors,
      ),
    );
  }

  void _onFieldChanged() {
    if (!_canEdit) return;
    final dirty = _computeIsDirty();
    if (_hasValidationErrors || _saveAttempted) _validate();
    setState(() => _isDirty = dirty);
    _publish();
  }

  void _commitIfDirty() {
    if (!_canEdit || !_isDirty || _isSaving) return;
    unawaited(_handleSave(notify: false));
  }

  void _onTextFocusLost(String key, {required bool isRequired}) {
    if (!_canEdit) return;
    if (isRequired) {
      final raw = _controllersByKey[key]?.text.trim() ?? '';
      setState(() {
        if (raw.isEmpty) {
          _errorsByKey[key] = 'required';
        } else if (_errorsByKey[key] == 'required') {
          _errorsByKey[key] = null;
        }
      });
      _publish();
      if (raw.isEmpty) return;
    }
    _commitIfDirty();
  }

  void _onDiscreteChanged() {
    _onFieldChanged();
    _commitIfDirty();
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

      final isRequired = equipmentSpecIsRequired(spec);
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
        AppToast.show(message: l10n.pleaseFillMissingInfo);
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
            hasValidationErrors: _hasValidationErrors,
          ),
        );
      } else {
        setState(() => _isSaving = false);
        _publish();
      }

      if (notify) {
        AppToast.show(
          message: result ? l10n.equipmentUpdated : l10n.updateFailed,
          type: result ? AppToastType.success : AppToastType.error,
        );
      }
      return result;
    } catch (_) {
      setState(() => _isSaving = false);
      _publish();
      if (notify) {
        AppToast.show(message: l10n.updateFailed, type: AppToastType.error);
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
          style: AppFonts.body14(context).copyWith(color: ghostGray),
        );
      }

      final fields = <Widget>[];
      for (var i = 0; i < _sortedSpecs.length; i++) {
        final spec = _sortedSpecs[i];
        final key = _controllerKey(spec, i);
        final catalogSpec = catalog?.specById(spec.specId);
        final type = spec.resolvedType(catalogSpec);
        if (!type.isKnown) continue;

        final errorKey = _errorsByKey[key];
        final String? errorText = switch (errorKey) {
          'required' => l10n.cannotBeEmpty,
          'invalidNumber' => l10n.invalidNumber,
          _ => null,
        };
        final label = spec.displayName(locale);
        final unit = catalogSpec == null
            ? spec.unit
            : catalog?.unitById(catalogSpec.unitId)?.symbol(locale) ??
                  spec.unit;
        final isRequired = equipmentSpecIsRequired(spec);

        if (type == CatalogSpecType.boolean) {
          fields.add(
            Row(
              children: [
                Expanded(child: Text(label, style: AppFonts.headingS(context))),
                AppSwitch(
                  value: _boolByKey[key] ?? false,
                  enabled: _canEdit,
                  onChanged: (value) {
                    _boolByKey[key] = value;
                    _onDiscreteChanged();
                  },
                ),
              ],
            ),
          );
          continue;
        }

        if (type == CatalogSpecType.select) {
          final options = catalogSpec == null
              ? const <CatalogSpecOption>[]
              : catalog!.optionsForSpec(catalogSpec.id);
          final selected = (_optionsByKey[key] ?? spec.optionIds)
              .where((id) => id.isNotEmpty)
              .firstOrNull;
          final optionIds = options.map((option) => option.id).toSet();
          final dropdownValue = selected != null && optionIds.contains(selected)
              ? selected
              : null;
          fields.add(
            AppDropdownField<String>(
              title: label,
              isRequired: isRequired,
              hint: label,
              sheetTitle: label,
              value: dropdownValue,
              enabled: _canEdit,
              readOnly: !_canEdit,
              errorText: errorText,
              options: options
                  .map(
                    (option) => DropdownOption(
                      value: option.id,
                      label: option.label(locale),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                _optionsByKey[key] = [value];
                _onDiscreteChanged();
              },
            ),
          );
          continue;
        }

        if (type == CatalogSpecType.multiSelect) {
          final options = catalogSpec == null
              ? const <CatalogSpecOption>[]
              : catalog!.optionsForSpec(catalogSpec.id);
          final selected = {...(_optionsByKey[key] ?? spec.optionIds)};
          fields.add(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppDimens.inputLabelGap,
              children: [
                Text.rich(
                  TextSpan(
                    text: label,
                    style: AppFonts.headingS(context),
                    children: [
                      if (isRequired && _canEdit)
                        TextSpan(
                          text: ' *',
                          style: AppFonts.headingS(context)
                              .copyWith(color: context.colors.text.error),
                        ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: AppDimens.s08$sm,
                  runSpacing: AppDimens.s08$sm,
                  children: options.map((option) {
                    final isSelected = selected.contains(option.id);
                    return AppLabelButton(
                      title: option.label(locale),
                      onTap: !_canEdit
                          ? null
                          : () {
                              if (isSelected) {
                                selected.remove(option.id);
                              } else {
                                selected.add(option.id);
                              }
                              _optionsByKey[key] = selected.toList();
                              _onDiscreteChanged();
                            },
                      variant: isSelected
                          ? AppLabelButtonVariant.filled
                          : AppLabelButtonVariant.outlined,
                      tone: AppLabelButtonTone.primary,
                    );
                  }).toList(),
                ),
                if (errorText != null)
                  Text(
                    errorText,
                    style: AppFonts.caption(context)
                        .copyWith(color: context.colors.text.error),
                  ),
              ],
            ),
          );
          continue;
        }

        final controller = _controllersByKey[key];
        if (controller == null) continue;

        final unitText = unit.trim();
        final fieldLabel = unitText.isEmpty ? label : '$label, $unitText';
        fields.add(
          AppTextField(
            title: fieldLabel,
            isRequired: isRequired,
            controller: controller,
            hint: '',
            onChanged: (_) => _onFieldChanged(),
            onFocusLost: () => _onTextFocusLost(key, isRequired: isRequired),
            keyboardType: type == CatalogSpecType.number
                ? const TextInputType.numberWithOptions(decimal: true)
                : null,
            errorText: errorText,
            readOnly: !_canEdit,
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppDimens.s16$base,
        children: fields,
      );
    }

    return EquipmentEditorSection(
      title: l10n.technicalSpecs,
      indicator: view.indicator,
      expanded: view.isExpanded,
      onToggleExpanded: () {
        if (_canEdit && _isDirty) {
          unawaited(_handleSave(notify: false));
        }
        _editor.toggleExpanded(OwnerEquipmentBlockId.specs);
      },
      saveLabel: l10n.save,
      child: specFields(),
    );
  }
}

bool _isPumpPowerSpec(EquipmentSpec spec, CatalogSpec? catalogSpec) {
  final key = spec.key.trim().toLowerCase();
  final slug = (catalogSpec?.slug ?? '').trim().toLowerCase();
  return key == 'pump_power' || slug == 'pump_power';
}

bool _sameIds(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) return false;
  }
  return true;
}
