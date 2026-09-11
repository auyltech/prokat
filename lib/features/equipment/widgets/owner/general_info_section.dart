import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/utils/localized_city.dart';
import 'package:prokat/features/categories/vacuum_trucks.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/input_field.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_editor_provider.dart';
import 'package:prokat/features/equipment/state/owner_equipment_editor_notifier.dart';
import 'package:prokat/features/equipment/state/owner_equipment_editor_state.dart';
import 'package:prokat/features/equipment/utils/vacuum_tariffs.dart';
import 'package:prokat/features/equipment/widgets/online_toggle.dart';
import 'package:prokat/features/equipment/widgets/owner/equipment_editor_section.dart';
import 'package:prokat/features/equipment/widgets/owner/owner_tariff_card.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
import 'package:prokat/features/user/widgets/city_picker_sheet.dart';
import 'package:prokat/l10n/app_localizations.dart';

class GeneralInfoSection extends ConsumerStatefulWidget {
  final Equipment equipment;

  const GeneralInfoSection({super.key, required this.equipment});

  @override
  ConsumerState<GeneralInfoSection> createState() => _GeneralInfoSectionState();
}

class _GeneralInfoSectionState extends ConsumerState<GeneralInfoSection> {
  late TextEditingController _descriptionController;

  late String _city;
  late EquipmentStatus _tempStatus;
  late String _baselineDescription;
  late String _baselineCity;
  late EquipmentStatus _baselineStatus;
  late String _baselineTariffs;
  late List<TariffDraft> _tariffs;
  final Set<String> _deletedPriceIds = {};

  bool _saveAttempted = false;
  bool _isSaving = false;
  String? _cityError;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: shortDescriptionOf(widget.equipment),
    );
    _city = widget.equipment.city ?? '';
    _tempStatus = widget.equipment.status;
    _tariffs = _editorTariffs();
    _captureBaseline();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _prefillCityIfNeeded();
      final next = _editorTariffs();
      if (_tariffFingerprint(next) != _tariffFingerprint(_tariffs)) {
        setState(() {
          _tariffs = next;
          if (!_isDirty) _captureBaseline();
        });
      }
      _publish();
    });
  }

  void _captureBaseline() {
    _baselineDescription = _descriptionController.text.trim();
    _baselineCity = _city.trim();
    _baselineStatus = _tempStatus;
    _baselineTariffs = _tariffFingerprint(_tariffs);
  }

  void _prefillCityIfNeeded() {
    if (_city.trim().isNotEmpty) return;
    final profileCity = (ref.read(ownerProfileProvider).valueOrNull?.city ?? '')
        .trim();
    final sessionCity = (ref.read(locationProvider).city ?? '').trim();
    final next = profileCity.isNotEmpty ? profileCity : sessionCity;
    if (next.isEmpty) return;
    setState(() => _city = next);
  }

  @override
  void didUpdateWidget(covariant GeneralInfoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDirty) {
      final next = widget.equipment;
      final prev = oldWidget.equipment;
      if (shortDescriptionOf(next) != shortDescriptionOf(prev) ||
          next.city != prev.city ||
          next.status != prev.status ||
          _priceFingerprint(next) != _priceFingerprint(prev)) {
        _descriptionController.text = shortDescriptionOf(next);
        _city = next.city ?? '';
        _tempStatus = next.status;
        _tariffs = _editorTariffs(next);
        _deletedPriceIds.clear();
        _captureBaseline();
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _publish();
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  OwnerEquipmentEditorNotifier get _editor {
    return ref.read(ownerEquipmentEditorProvider(widget.equipment.id).notifier);
  }

  List<TariffDraft> _editorTariffs([Equipment? equipment]) {
    final vacuumId = vacuumTrucksCategory(ref.read(catalogProvider).valueOrNull)
        ?.id;
    return tariffsForEditor(
      equipment ?? widget.equipment,
      vacuumCategoryId: vacuumId,
    );
  }

  bool get _isCityDirty => _city.trim() != _baselineCity;

  bool get _canEdit => !widget.equipment.isPendingReview;

  bool get _isStatusDirty =>
      widget.equipment.isModerated && _tempStatus != _baselineStatus;

  String _tariffFingerprint(List<TariffDraft> items) {
    return items.map((item) => item.fingerprint()).join('\n');
  }

  String _priceFingerprint(Equipment equipment) {
    return equipment.prices
        .map(
          (entry) =>
              '${entry.id}:${entry.price}:${entry.priceRate.value}:${entry.label ?? ''}:${entry.isStartingFrom}',
        )
        .join(',');
  }

  bool get _isDirty {
    return _descriptionController.text.trim() != _baselineDescription ||
        _isCityDirty ||
        _isStatusDirty ||
        _tariffFingerprint(_tariffs) != _baselineTariffs ||
        _deletedPriceIds.isNotEmpty;
  }

  bool get _hasPricedTariff => _tariffs.any((item) => item.hasPrice);

  bool get _isComplete {
    return _city.trim().isNotEmpty && _hasPricedTariff;
  }

  void _bind() {
    _editor.bind(
      id: OwnerEquipmentBlockId.general,
      save: ({required bool notify}) => _handleSave(notify: notify),
      validate: _validate,
    );
  }

  void _publish() {
    final description = _descriptionController.text.trim();
    _bind();
    _editor.reportInfoDraft(
      ownerComment: description,
      rentCondition: description,
    );
    _editor.report(
      id: OwnerEquipmentBlockId.general,
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
    _cityError = _city.trim().isEmpty ? 'required' : null;
    setState(() {});
    return _cityError == null && _hasPricedTariff;
  }

  Future<bool> _persistTariffs() async {
    final notifier = ref.read(equipmentMutationProvider.notifier);
    final equipmentId = widget.equipment.id;

    final baseline = _baselineTariffs.split('\n').toSet();

    for (final id in _deletedPriceIds) {
      final ok = await notifier.deletePriceEntry(
        PriceEntry(id: id, price: 1, priceRate: priceRateOptions.first),
        equipmentId,
      );
      if (!ok) return false;
    }

    for (final draft in _tariffs) {
      if (!draft.isSavable) continue;
      final label = draft.persistedLabel();
      final unchanged =
          draft.id != null && baseline.contains(draft.fingerprint());
      if (unchanged) continue;
      if (draft.id == null) {
        final result = await notifier.createPriceEntry(
          price: draft.price!,
          priceRate: draft.priceRate,
          equipmentId: equipmentId,
          label: label,
          isStartingFrom: draft.isStartingFrom,
        );
        if (!result.success) return false;
      } else {
        final result = await notifier.updatePriceEntry(
          PriceEntry(
            id: draft.id!,
            price: draft.price!,
            priceRate: draft.priceRate,
            label: label,
            isStartingFrom: draft.isStartingFrom,
          ),
          equipmentId,
        );
        if (!result.success) return false;
      }
    }
    return true;
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
      final description = _descriptionController.text.trim();
      _editor.reportInfoDraft(
        ownerComment: description,
        rentCondition: description,
      );

      final tariffsOk = await _persistTariffs();
      if (!tariffsOk) {
        if (!mounted) return false;
        setState(() => _isSaving = false);
        _publish();
        if (notify) {
          AppSnackBar.show(message: l10n.couldNotSaveEquipment, isError: true);
        }
        return false;
      }

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
        _deletedPriceIds.clear();
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
    if (!_canEdit) return;
    if (_saveAttempted) _validate();
    setState(() {});
    _publish();
  }

  Future<void> _pickCity() async {
    if (!_canEdit) return;
    final selected = await CityPickerSheet.show(
      context: context,
      service: CitySelectorService.createequipment,
      highlightedCity: _city,
    );
    if (selected == null || selected.isEmpty) return;
    _city = selected;
    _onChanged();
  }

  Future<void> _deleteTariff(int index) async {
    if (!_canEdit) return;
    final draft = _tariffs[index];
    if (draft.isPreset) return;
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
    if (draft.id != null) {
      _deletedPriceIds.add(draft.id!);
    }
    setState(() => _tariffs.removeAt(index));
    _onChanged();
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
    final hasLocation = _city.trim().isNotEmpty;

    return EquipmentEditorSection(
      title: l10n.forClients,
      indicator: view.indicator,
      expanded: view.isExpanded,
      onToggleExpanded: () =>
          _editor.toggleExpanded(OwnerEquipmentBlockId.general),
      saveLabel: l10n.save,
      showSave: _canEdit && _isDirty,
      saveEnabled: _canEdit && _isDirty && !_isSaving,
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
          GestureDetector(
            onTap: _canEdit ? _pickCity : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
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
                    hasLocation
                        ? Icons.location_on
                        : Icons.location_on_outlined,
                    color: hasLocation
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.workCity,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.62,
                            ),
                            fontWeight: FontWeight.w600,
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
                                : colorScheme.onSurface.withValues(alpha: 0.5),
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
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          InputField(
            label: l10n.shortDescription,
            controller: _descriptionController,
            onChanged: _onChanged,
            hint: l10n.shortDescriptionHint,
            helperText: l10n.shortDescriptionHelper,
            hintMaxLines: 3,
            maxLines: 4,
            minLines: 3,
            maxLength: 200,
            boxed: true,
            readOnly: !_canEdit,
          ),
          const SizedBox(height: 18),
          Text(
            l10n.tariffs,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(_tariffs.length, (index) {
            final draft = _tariffs[index];
            return OwnerTariffCard(
              draft: draft,
              canEdit: _canEdit,
              onChanged: (next) {
                setState(() => _tariffs[index] = next);
                _onChanged();
              },
              onDelete: draft.isPreset ? null : () => _deleteTariff(index),
            );
          }),
          if (_canEdit)
            TextButton.icon(
              onPressed: () {
                setState(() => _tariffs.add(TariffDraft.custom()));
                _onChanged();
              },
              icon: Icon(Icons.add, color: colorScheme.primary),
              label: Text(
                l10n.addTariff,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
