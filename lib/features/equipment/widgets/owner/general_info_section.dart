import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:prokat/features/equipment/providers/owner_equipment_details_provider.dart';
import 'package:prokat/features/equipment/utils/equipment_limits.dart';
import 'package:prokat/features/equipment/utils/vacuum_tariffs.dart';
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
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  late String _city;
  late String _baselineName;
  late String _baselineDescription;
  late String _baselineCity;
  late String _baselineTariffs;
  late List<TariffDraft> _tariffs;
  final Set<String> _deletedPriceIds = {};

  bool _saveAttempted = false;
  bool _isSaving = false;
  String? _nameError;
  String? _cityError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.equipment.name);
    _descriptionController = TextEditingController(
      text: shortDescriptionOf(widget.equipment),
    );
    _city = widget.equipment.city ?? '';
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
    _baselineName = _nameController.text.trim();
    _baselineDescription = _descriptionController.text.trim();
    _baselineCity = _city.trim();
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
    _onChanged();
    _commitIfDirty();
  }

  @override
  void didUpdateWidget(covariant GeneralInfoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDirty && !_isSaving) {
      final next = widget.equipment;
      final prev = oldWidget.equipment;
      if (next.name != prev.name ||
          shortDescriptionOf(next) != shortDescriptionOf(prev) ||
          next.city != prev.city ||
          _priceFingerprint(next) != _priceFingerprint(prev)) {
        if (_nameController.text != next.name) {
          _nameController.text = next.name;
        }
        final nextDescription = shortDescriptionOf(next);
        if (_descriptionController.text != nextDescription) {
          _descriptionController.text = nextDescription;
        }
        _city = next.city ?? '';
        _tariffs = adoptServerTariffs(
          server: _editorTariffs(next),
          local: _tariffs,
        );
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
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  OwnerEquipmentEditorNotifier get _editor {
    return ref.read(ownerEquipmentEditorProvider(widget.equipment.id).notifier);
  }

  List<TariffDraft> _editorTariffs([Equipment? equipment]) {
    final vacuumId = vacuumTrucksCategory(
      ref.read(catalogProvider).valueOrNull,
      forOwner: true,
    )?.id;
    return tariffsForEditor(
      equipment ?? widget.equipment,
      vacuumCategoryId: vacuumId,
    );
  }

  bool get _isCityDirty => _city.trim() != _baselineCity;

  bool get _canEdit => !widget.equipment.isPendingReview;

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
    return _nameController.text.trim() != _baselineName ||
        _descriptionController.text.trim() != _baselineDescription ||
        _isCityDirty ||
        _tariffFingerprint(_tariffs) != _baselineTariffs ||
        _deletedPriceIds.isNotEmpty;
  }

  bool get _hasPricedTariff => _tariffs.any((item) => item.isSavable);

  Future<void> _adoptPersistedTariffs() async {
    Equipment? latest;
    try {
      latest = await ref.read(
        ownerEquipmentDetailsProvider(widget.equipment.id).future,
      );
    } catch (_) {}
    if (!mounted) return;
    _tariffs = adoptServerTariffs(
      server: _editorTariffs(latest ?? widget.equipment),
      local: _tariffs,
    );
  }

  bool get _isComplete {
    return _nameController.text.trim().isNotEmpty &&
        _city.trim().isNotEmpty &&
        _hasPricedTariff;
  }

  void _bind() {
    _editor.bind(
      id: OwnerEquipmentBlockId.general,
      save: ({required bool notify}) => _handleSave(notify: notify),
      validate: _validate,
    );
  }

  void _publish() {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    _bind();
    _editor.reportInfoDraft(
      name: name,
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
    _nameError = _nameController.text.trim().isEmpty ? 'required' : null;
    _cityError = _city.trim().isEmpty ? 'required' : null;
    setState(() {});
    return _nameError == null && _cityError == null && _hasPricedTariff;
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

    final existingCount = _tariffs.where((item) => item.id != null).length;
    var createdThisSave = 0;

    for (final draft in _tariffs) {
      if (!draft.isSavable) continue;
      final label = draft.persistedLabel();
      final unchanged =
          draft.id != null && baseline.contains(draft.fingerprint());
      if (unchanged) continue;
      if (draft.id == null) {
        if (existingCount + createdThisSave >= ownerEquipmentTariffMax) {
          continue;
        }
        createdThisSave++;
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
    if (notify && !_validate()) {
      _publish();
      AppSnackBar.show(message: l10n.pleaseFillMissingInfo);
      return false;
    }

    setState(() => _isSaving = true);
    _publish();

    try {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      _editor.reportInfoDraft(
        name: name,
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
      if (infoOk && _isCityDirty && _city.trim().isNotEmpty) {
        locationOk = await ref
            .read(equipmentMutationProvider.notifier)
            .updateEquipmentLocation(widget.equipment.id, {
              'id': widget.equipment.id,
              'city': _city.trim(),
            });
      }

      final ok = infoOk && locationOk;
      if (!mounted) return ok;

      setState(() => _isSaving = false);

      if (ok) {
        _deletedPriceIds.clear();
        await _adoptPersistedTariffs();
        if (!mounted) return ok;
        setState(() {});
        _captureBaseline();
        if (!_hasPricedTariff && widget.equipment.isVisible) {
          await ref
              .read(equipmentMutationProvider.notifier)
              .toggleEquipmentOnline(widget.equipment.id, false);
        }
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

  void _commitIfDirty() {
    if (!_canEdit || !_isDirty || _isSaving) return;
    unawaited(_handleSave(notify: false));
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
    _commitIfDirty();
  }

  Future<void> _deleteTariff(int index) async {
    if (!_canEdit) return;
    final draft = _tariffs[index];
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
    _publish();
    unawaited(_handleSave(notify: false));
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
      onToggleExpanded: () {
        if (_canEdit && _isDirty) {
          unawaited(_handleSave(notify: false));
        }
        _editor.toggleExpanded(OwnerEquipmentBlockId.general);
      },
      saveLabel: l10n.save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  text: l10n.workCity,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  children: [
                    if (!hasLocation)
                      TextSpan(
                        text: ' ${l10n.requiredInParens}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _canEdit ? _pickCity : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _cityError != null
                          ? colorScheme.error
                          : colorScheme.outline.withValues(alpha: 0.45),
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
                        child: Text(
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
                          ),
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
              if (_cityError != null) ...[
                const SizedBox(height: 6),
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
          const SizedBox(height: 16),
          InputField(
            label: l10n.equipmentNameLabel,
            controller: _nameController,
            onChanged: _onChanged,
            onFocusLost: _commitIfDirty,
            hint: l10n.equipmentNameHint,
            isRequired: true,
            requiredHintText: l10n.requiredInParens,
            showFieldErrors: false,
            boxed: true,
            filled: false,
            readOnly: !_canEdit,
            maxLength: ownerEquipmentTextMaxLength,
            inputFormatters: [
              LengthLimitingTextInputFormatter(ownerEquipmentTextMaxLength),
            ],
          ),
          const SizedBox(height: 16),
          InputField(
            label: l10n.shortDescription,
            controller: _descriptionController,
            onChanged: _onChanged,
            onFocusLost: _commitIfDirty,
            hint: l10n.shortDescriptionHelper,
            hintMaxLines: 3,
            maxLines: 4,
            minLines: 3,
            maxLength: 200,
            boxed: true,
            filled: false,
            readOnly: !_canEdit,
          ),
          const SizedBox(height: 18),
          Text.rich(
            TextSpan(
              text: l10n.tariffs,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              children: [
                if (!_hasPricedTariff)
                  TextSpan(
                    text: ' ${l10n.requiredInParens}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
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
              onCommit: _commitIfDirty,
              onDelete: () => _deleteTariff(index),
            );
          }),
          if (_canEdit && _tariffs.length < ownerEquipmentTariffMax)
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
