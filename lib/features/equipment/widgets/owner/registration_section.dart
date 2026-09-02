import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/input_field.dart';
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
    if (_isDirty) return;
    if (widget.equipment.model != oldWidget.equipment.model ||
        widget.equipment.plateNumber != oldWidget.equipment.plateNumber) {
      _modelController.text = widget.equipment.model;
      _plateController.text = widget.equipment.plateNumber ?? '';
      _captureBaseline();
    }
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
        saveAttempted: _saveAttempted,
      ),
    );
  }

  bool _validate() {
    _saveAttempted = true;
    _modelError = _modelController.text.trim().isEmpty ? 'required' : null;
    _plateError = _plateController.text.trim().isEmpty ? 'required' : null;
    setState(() {});
    return _modelError == null && _plateError == null;
  }

  Future<bool> _handleSave({required bool notify}) async {
    final l10n = AppLocalizations.of(context)!;
    if (!_canEdit || _isSaving) return false;
    if (!_validate()) {
      _publish();
      if (notify) {
        AppSnackBar.show(message: l10n.pleaseFillMissingInfo);
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
            saveAttempted: _saveAttempted,
          ),
        );
        if (notify) {
          AppSnackBar.show(message: l10n.equipmentUpdated, isSuccess: true);
        }
      } else {
        _publish();
        if (notify) {
          AppSnackBar.show(message: l10n.couldNotSaveEquipment, isError: true);
        }
      }
      return ok;
    } catch (_) {
      if (!mounted) return false;
      setState(() => _isSaving = false);
      _publish();
      if (notify) {
        AppSnackBar.show(message: l10n.somethingWentWrong, isError: true);
      }
      return false;
    }
  }

  void _onChanged() {
    if (!_canEdit) return;
    if (_saveAttempted) _validate();
    setState(() {});
    _publish();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    _bind();

    final view = ref
        .watch(ownerEquipmentEditorProvider(widget.equipment.id))
        .block(OwnerEquipmentBlockId.registration);

    return EquipmentEditorSection(
      title: l10n.registrationData,
      indicator: view.indicator,
      expanded: view.isExpanded,
      onToggleExpanded: () =>
          _editor.toggleExpanded(OwnerEquipmentBlockId.registration),
      saveLabel: l10n.save,
      showSave: _canEdit && _isDirty,
      saveEnabled: _canEdit && _isDirty && !_isSaving,
      saveLoading: _isSaving,
      onSave: () => _handleSave(notify: true),
      child: Column(
        children: [
          InputField(
            label: l10n.model,
            controller: _modelController,
            onChanged: _onChanged,
            hint: l10n.modelHint,
            isRequired: true,
            readOnly: !_canEdit,
            errorText: _modelError == null ? null : l10n.fieldRequired,
          ),
          const SizedBox(height: 12),
          InputField(
            label: l10n.plateNumberLabel,
            controller: _plateController,
            onChanged: _onChanged,
            hint: l10n.plateNumberHint,
            isRequired: true,
            isLast: true,
            readOnly: !_canEdit,
            errorText: _plateError == null ? null : l10n.fieldRequired,
          ),
        ],
      ),
    );
  }
}
