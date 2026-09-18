import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:prokat/core/utils/kz_plate_mask.dart';
import 'package:prokat/features/equipment/utils/equipment_limits.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_editor_provider.dart';
import 'package:prokat/features/equipment/state/owner_equipment_editor_notifier.dart';
import 'package:prokat/features/equipment/state/owner_equipment_editor_state.dart';
import 'package:prokat/features/equipment/widgets/owner/equipment_editor_section.dart';
import 'package:prokat/l10n/app_localizations.dart';

class RegistrationSection extends ConsumerStatefulWidget {
  final Equipment equipment;

  const RegistrationSection({super.key, required this.equipment});

  @override
  ConsumerState<RegistrationSection> createState() =>
      _RegistrationSectionState();
}

class _RegistrationSectionState extends ConsumerState<RegistrationSection> {
  late TextEditingController _modelController;
  late TextEditingController _plateController;
  late String _baselineModel;
  late String _baselinePlate;

  bool _saveAttempted = false;
  bool _isSaving = false;
  String? _modelError;
  String? _plateError;

  bool get _canEdit => widget.equipment.isDraft;

  @override
  void initState() {
    super.initState();
    _modelController = TextEditingController(text: widget.equipment.model);
    _plateController = TextEditingController(
      text: widget.equipment.plateNumber ?? '',
    );
    _captureBaseline();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _publish();
    });
  }

  void _captureBaseline() {
    _baselineModel = _modelController.text.trim();
    _baselinePlate = _plateController.text.trim();
  }

  @override
  void didUpdateWidget(covariant RegistrationSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isDirty || _isSaving) return;
    if (widget.equipment.model != oldWidget.equipment.model ||
        widget.equipment.plateNumber != oldWidget.equipment.plateNumber) {
      _setControllerText(_modelController, widget.equipment.model);
      _setControllerText(_plateController, widget.equipment.plateNumber ?? '');
      _captureBaseline();
    }
  }

  void _setControllerText(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.text = value;
  }

  @override
  void dispose() {
    _modelController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  OwnerEquipmentEditorNotifier get _editor {
    return ref.read(ownerEquipmentEditorProvider(widget.equipment.id).notifier);
  }

  bool get _isDirty {
    return _modelController.text.trim() != _baselineModel ||
        _plateController.text.trim() != _baselinePlate;
  }

  bool get _isComplete {
    return _modelController.text.trim().isNotEmpty &&
        _plateController.text.trim().isNotEmpty;
  }

  bool get _hasValidationErrors => _modelError != null || _plateError != null;

  void _bind() {
    _editor.bind(
      id: OwnerEquipmentBlockId.registration,
      save: ({required bool notify}) => _handleSave(notify: notify),
      validate: _validate,
    );
  }

  void _publish() {
    _bind();
    _editor.reportInfoDraft(
      model: _modelController.text.trim(),
      plateNumber: _plateController.text.trim(),
    );
    _editor.report(
      id: OwnerEquipmentBlockId.registration,
      isDirty: _canEdit && _isDirty,
      isSaving: _isSaving,
      indicator: blockIndicatorFor(
        complete: _isComplete,
        hasValidationErrors: _hasValidationErrors,
      ),
    );
  }

  bool _validate() {
    _saveAttempted = true;
    _validateModelField();
    _validatePlateField();
    setState(() {});
    return _modelError == null && _plateError == null;
  }

  void _validateModelField() {
    _modelError = _modelController.text.trim().isEmpty ? 'required' : null;
  }

  void _validatePlateField() {
    _plateError = _plateController.text.trim().isEmpty ? 'required' : null;
  }

  Future<bool> _handleSave({required bool notify}) async {
    final l10n = AppLocalizations.of(context)!;
    if (!_canEdit || _isSaving) return false;
    if (!_validate()) {
      _publish();
      if (notify) {
        AppToast.show(message: l10n.pleaseFillMissingInfo);
      }
      return false;
    }

    setState(() => _isSaving = true);
    _publish();

    try {
      _editor.reportInfoDraft(
        model: _modelController.text.trim(),
        plateNumber: _plateController.text.trim(),
      );
      final ok = await ref
          .read(equipmentMutationProvider.notifier)
          .updateEquipment(_editor.mergedInfoPayload(widget.equipment));

      if (!mounted) return ok;
      setState(() => _isSaving = false);

      if (ok) {
        _captureBaseline();
        _editor.markSaved(
          OwnerEquipmentBlockId.registration,
          indicator: blockIndicatorFor(
            complete: _isComplete,
            hasValidationErrors: _hasValidationErrors,
          ),
        );
        if (notify) {
          AppToast.show(
            message: l10n.equipmentUpdated,
            type: AppToastType.success,
          );
        }
      } else {
        _publish();
        if (notify) {
          AppToast.show(
            message: l10n.couldNotSaveEquipment,
            type: AppToastType.error,
          );
        }
      }
      return ok;
    } catch (_) {
      if (!mounted) return false;
      setState(() => _isSaving = false);
      _publish();
      if (notify) {
        AppToast.show(
          message: l10n.somethingWentWrong,
          type: AppToastType.error,
        );
      }
      return false;
    }
  }

  void _onChanged() {
    if (!_canEdit) return;
    if (_modelError != null || _plateError != null || _saveAttempted) {
      _validateModelField();
      _validatePlateField();
    }
    setState(() {});
    _publish();
  }

  void _commitIfDirty() {
    if (!_canEdit || !_isDirty || _isSaving) return;
    unawaited(_handleSave(notify: false));
  }

  void _onModelFocusLost() {
    if (!_canEdit) return;
    setState(_validateModelField);
    _publish();
    if (_modelError != null) return;
    _commitIfDirty();
  }

  void _onPlateFocusLost() {
    if (!_canEdit) return;
    setState(_validatePlateField);
    _publish();
    if (_plateError != null) return;
    _commitIfDirty();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    _bind();

    final view = ref
        .watch(ownerEquipmentEditorProvider(widget.equipment.id))
        .block(OwnerEquipmentBlockId.registration);

    return EquipmentEditorSection(
      title: l10n.equipmentData,
      indicator: view.indicator,
      expanded: view.isExpanded,
      onToggleExpanded: () {
        if (_canEdit && _isDirty) {
          unawaited(_handleSave(notify: false));
        }
        _editor.toggleExpanded(OwnerEquipmentBlockId.registration);
      },
      saveLabel: l10n.save,
      child: Column(
        spacing: AppDimens.s16$base,
        children: [
          AppTextField(
            title: l10n.modelLabel,
            isRequired: true,
            controller: _modelController,
            onChanged: (_) => _onChanged(),
            onFocusLost: _onModelFocusLost,
            hint: l10n.modelHint,
            readOnly: !_canEdit,
            errorText: _modelError == null ? null : l10n.cannotBeEmpty,
            maxLength: ownerEquipmentTextMaxLength,
            inputFormatters: [
              LengthLimitingTextInputFormatter(ownerEquipmentTextMaxLength),
            ],
          ),
          AppTextField(
            title: l10n.plateNumberLabel,
            isRequired: true,
            controller: _plateController,
            onChanged: (_) => _onChanged(),
            onFocusLost: _onPlateFocusLost,
            hint: l10n.plateNumberHint,
            textInputAction: TextInputAction.done,
            readOnly: !_canEdit,
            errorText: _plateError == null ? null : l10n.cannotBeEmpty,
            inputFormatters: const [KzPlateInputFormatter()],
          ),
        ],
      ),
    );
  }
}
