import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/utils/localized_city.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/edit_sheet.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/core/widgets/input_field.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_editor_provider.dart';
import 'package:prokat/features/equipment/state/owner_equipment_editor_notifier.dart';
import 'package:prokat/features/equipment/state/owner_equipment_editor_state.dart';
import 'package:prokat/features/equipment/utils/equipment_submit_readiness.dart';
import 'package:prokat/features/equipment/widgets/online_toggle.dart';
import 'package:prokat/features/equipment/widgets/owner/equipment_editor_section.dart';
import 'package:prokat/features/equipment/widgets/owner/price_entry_sheet.dart';
import 'package:prokat/features/equipment/widgets/owner/price_entry_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

class GeneralInfoSection extends ConsumerStatefulWidget {
  final Equipment equipment;

  const GeneralInfoSection({super.key, required this.equipment});

  @override
  ConsumerState<GeneralInfoSection> createState() => _GeneralInfoSectionState();
}

class _GeneralInfoSectionState extends ConsumerState<GeneralInfoSection> {
  late TextEditingController _nameController;
  late TextEditingController _commentController;
  late TextEditingController _rentConditionController;

  late String _city;
  late EquipmentStatus _tempStatus;
  late String _baselineName;
  late String _baselineComment;
  late String _baselineRent;
  late String _baselineCity;
  late EquipmentStatus _baselineStatus;

  bool _saveAttempted = false;
  bool _isSaving = false;
  String? _nameError;
  String? _cityError;

  static const _maxRates = 3;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.equipment.name);
    _commentController = TextEditingController(
      text: widget.equipment.ownerComment ?? '',
    );
    _rentConditionController = TextEditingController(
      text: widget.equipment.rentCondition ?? '',
    );
    _city = widget.equipment.city ?? '';
    _tempStatus = widget.equipment.status;
    _captureBaseline();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _publish();
    });
  }

  void _captureBaseline() {
    _baselineName = _nameController.text.trim();
    _baselineComment = _commentController.text.trim();
    _baselineRent = _rentConditionController.text.trim();
    _baselineCity = _city.trim();
    _baselineStatus = _tempStatus;
  }

  @override
  void didUpdateWidget(covariant GeneralInfoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDirty) {
      final next = widget.equipment;
      final prev = oldWidget.equipment;
      if (next.name != prev.name ||
          (next.ownerComment ?? '') != (prev.ownerComment ?? '') ||
          (next.rentCondition ?? '') != (prev.rentCondition ?? '') ||
          next.city != prev.city ||
          next.status != prev.status) {
        _nameController.text = next.name;
        _commentController.text = next.ownerComment ?? '';
        _rentConditionController.text = next.rentCondition ?? '';
        _city = next.city ?? '';
        _tempStatus = next.status;
        _captureBaseline();
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _publish();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commentController.dispose();
    _rentConditionController.dispose();
    super.dispose();
  }

  OwnerEquipmentEditorNotifier get _editor {
    return ref.read(ownerEquipmentEditorProvider(widget.equipment.id).notifier);
  }

  bool get _isCityDirty => _city.trim() != _baselineCity;

  bool get _isStatusDirty =>
      widget.equipment.isModerated && _tempStatus != _baselineStatus;

  bool get _isDirty {
    return _nameController.text.trim() != _baselineName ||
        _commentController.text.trim() != _baselineComment ||
        _rentConditionController.text.trim() != _baselineRent ||
        _isCityDirty ||
        _isStatusDirty;
  }

  bool get _isComplete {
    return _nameController.text.trim().isNotEmpty &&
        _city.trim().isNotEmpty &&
        equipmentHasPrice(widget.equipment);
  }

  void _bind() {
    _editor.bind(
      id: OwnerEquipmentBlockId.general,
      save: ({required bool notify}) => _handleSave(notify: notify),
      validate: _validate,
    );
  }

  void _publish() {
    _bind();
    _editor.reportInfoDraft(
      name: _nameController.text.trim(),
      ownerComment: _commentController.text.trim(),
      rentCondition: _rentConditionController.text.trim(),
    );
    _editor.report(
      id: OwnerEquipmentBlockId.general,
      isDirty: _isDirty,
      isSaving: _isSaving,
      indicator: blockIndicatorFor(
        complete: _isComplete,
        saveAttempted: _saveAttempted,
      ),
    );
  }

  bool _validate() {
    _saveAttempted = true;
    _nameError = _nameController.text.trim().isEmpty ? 'required' : null;
    _cityError = _city.trim().isEmpty ? 'required' : null;
    setState(() {});
    return _nameError == null &&
        _cityError == null &&
        equipmentHasPrice(widget.equipment);
  }

  Future<bool> _handleSave({required bool notify}) async {
    final l10n = AppLocalizations.of(context)!;
    if (_isSaving) return false;
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
        name: _nameController.text.trim(),
        ownerComment: _commentController.text.trim(),
        rentCondition: _rentConditionController.text.trim(),
      );
      final infoOk = await ref
          .read(equipmentMutationProvider.notifier)
          .updateEquipment(_editor.mergedInfoPayload(widget.equipment));

      var locationOk = true;
      if (infoOk && _isCityDirty) {
        locationOk = await ref
            .read(equipmentMutationProvider.notifier)
            .updateEquipmentLocation(widget.equipment.id, {
              'id': widget.equipment.id,
              'city': _city.trim(),
            });
      }

      var statusOk = true;
      if (infoOk && locationOk && _isStatusDirty) {
        statusOk = await ref
            .read(equipmentMutationProvider.notifier)
            .updateEquipmentStatus(widget.equipment.id, _tempStatus);
      }

      final ok = infoOk && locationOk && statusOk;
      if (!mounted) return ok;

      setState(() => _isSaving = false);

      if (ok) {
        _captureBaseline();
        _editor.markSaved(
          OwnerEquipmentBlockId.general,
          indicator: blockIndicatorFor(
            complete: _isComplete,
            saveAttempted: _saveAttempted,
          ),
        );
        if (notify) {
          AppSnackBar.show(message: l10n.equipmentUpdated, isSuccess: true);
        }
      } else if (notify) {
        AppSnackBar.show(message: l10n.couldNotSaveEquipment, isError: true);
        _publish();
      } else {
        _publish();
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
    if (_saveAttempted) _validate();
    setState(() {});
    _publish();
  }

  Future<void> _pickCity() async {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).languageCode;
    final catalog = ref.read(catalogProvider).valueOrNull;
    final cityKeys = catalogCityKeys(catalog);

    showEditSheet(
      context: context,
      sheet: EditSheet(
        title: l10n.selectCity,
        buttonText: '',
        onSubmit: () {},
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            ...cityKeys.map(
              (city) => ListTile(
                title: Text(
                  catalogCityLabel(
                    city: city,
                    languageCode: locale,
                    catalog: catalog,
                    fallback: (value) => localizedCityName(value, l10n),
                  ),
                ),
                leading: const Icon(Icons.location_city),
                trailing: isSameCity(_city, city)
                    ? Icon(Icons.check_circle, color: colorScheme.primary)
                    : null,
                onTap: () {
                  _city = city;
                  Navigator.pop(context);
                  _onChanged();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePrice(PriceEntry entry) async {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.deletePriceEntry),
          content: Text(l10n.deletePriceEntryConfirmation),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    final result = await ref
        .read(equipmentMutationProvider.notifier)
        .deletePriceEntry(entry, widget.equipment.id);

    if (!mounted) return;
    AppSnackBar.show(
      message: result ? l10n.priceEntryDeleted : l10n.failedToDeletePriceEntry,
      isSuccess: result,
      isError: !result,
    );
    _publish();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final catalog = ref.watch(catalogProvider).valueOrNull;

    _bind();

    final editor = ref.watch(ownerEquipmentEditorProvider(widget.equipment.id));
    final view = editor.block(OwnerEquipmentBlockId.general);
    final prices = widget.equipment.prices;
    final canAddMore = prices.length < _maxRates;
    final hasLocation = _city.trim().isNotEmpty;

    return EquipmentEditorSection(
      title: l10n.generalInformation,
      indicator: view.indicator,
      expanded: view.isExpanded,
      onToggleExpanded: () =>
          _editor.toggleExpanded(OwnerEquipmentBlockId.general),
      saveLabel: l10n.save,
      showSave: _isDirty,
      saveEnabled: _isDirty && !_isSaving,
      saveLoading: _isSaving,
      onSave: () => _handleSave(notify: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.equipment.isModerated) ...[
            Text(l10n.availableForRent, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            if (widget.equipment.status == EquipmentStatus.available ||
                widget.equipment.status == EquipmentStatus.accepted)
              OnlineToggle(
                id: widget.equipment.id,
                isVisible: widget.equipment.isVisible,
              ),
            const SizedBox(height: 12),
            Text(l10n.operatingStatus, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    [
                      EquipmentStatus.available,
                      EquipmentStatus.booked,
                      EquipmentStatus.maintenance,
                    ].map((status) {
                      final isSelected = _tempStatus == status;
                      final isWarning = status == EquipmentStatus.maintenance;
                      final activeColor = isWarning
                          ? colorScheme.error
                          : colorScheme.primary;
                      final label = switch (status) {
                        EquipmentStatus.available => l10n.available,
                        EquipmentStatus.booked => l10n.booked,
                        EquipmentStatus.maintenance => l10n.maintenance,
                        _ => status.name,
                      };

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(label),
                          onSelected: (_) {
                            setState(() => _tempStatus = status);
                            _onChanged();
                          },
                          selectedColor: activeColor.withValues(alpha: 0.16),
                          side: BorderSide(
                            color: isSelected
                                ? activeColor
                                : colorScheme.outlineVariant,
                          ),
                          labelStyle: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? activeColor
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          InputField(
            label: 'Название',
            controller: _nameController,
            onChanged: _onChanged,
            hint: l10n.equipmentNameHint,
            isRequired: true,
            errorText: _nameError == null ? null : l10n.fieldRequired,
          ),
          const SizedBox(height: 12),
          InputField(
            label: l10n.rentCondition,
            controller: _rentConditionController,
            onChanged: _onChanged,
            hint: l10n.fullLoadOnly,
          ),
          const SizedBox(height: 12),
          InputField(
            label: l10n.commentNotes,
            controller: _commentController,
            onChanged: _onChanged,
            hint: l10n.ownerCommentHint,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickCity,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _cityError != null
                      ? colorScheme.error
                      : colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasLocation ? Icons.pin_drop : Icons.pin_drop_outlined,
                    color: hasLocation
                        ? colorScheme.primary
                        : colorScheme.tertiary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.city,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasLocation
                              ? catalogCityLabel(
                                  city: _city,
                                  languageCode: locale,
                                  catalog: catalog,
                                  fallback: (city) =>
                                      localizedCityName(city, l10n),
                                )
                              : l10n.selectCity,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: hasLocation
                                ? colorScheme.onSurface
                                : colorScheme.tertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_cityError != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            l10n.fieldRequired,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.prices,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: canAddMore
                    ? () async {
                        await PriceEntrySheet.show(
                          context,
                          equipmentId: widget.equipment.id,
                        );
                        if (mounted) _publish();
                      }
                    : null,
                icon: Icon(
                  canAddMore ? Icons.add : Icons.check,
                  color: canAddMore
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (prices.isEmpty)
            EmptyStateTile(
              icon: Icons.payments_outlined,
              title: l10n.noPricesListed,
              color: colorScheme.error,
            )
          else
            Column(
              children: prices
                  .map(
                    (entry) => PriceEntryTile(
                      priceEntry: entry,
                      onEdit: () async {
                        await PriceEntrySheet.show(
                          context,
                          equipmentId: widget.equipment.id,
                          priceEntry: entry,
                        );
                        if (mounted) _publish();
                      },
                      onDelete: () => _deletePrice(entry),
                    ),
                  )
                  .toList(),
            ),
          if (!canAddMore)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.allRatingOptionsListed,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
