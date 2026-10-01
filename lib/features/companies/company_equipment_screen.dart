import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_elevated_button.dart';
import 'package:prokat/core/widgets/ui_kit/inputs/app_text_field.dart';
import 'package:prokat/core/widgets/ui_kit/inputs/app_dropdown_field.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/l10n/app_localizations.dart';

import 'company_models.dart';
import 'company_service.dart';
import 'company_widgets.dart';

class CompanyEquipmentScreen extends ConsumerStatefulWidget {
  final String companyId;
  final CompanyFleetItem? item;
  final String? initialCategoryId;
  const CompanyEquipmentScreen({
    super.key,
    required this.companyId,
    this.item,
    this.initialCategoryId,
  });
  @override
  ConsumerState<CompanyEquipmentScreen> createState() =>
      _CompanyEquipmentScreenState();
}

class _CompanyEquipmentScreenState
    extends ConsumerState<CompanyEquipmentScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.item?.name);
  late final _model = TextEditingController(text: widget.item?.model);
  late final _comment = TextEditingController(text: widget.item?.ownerComment);
  late final _price = TextEditingController(
    text: widget.item != null && widget.item!.prices.isNotEmpty
        ? '${widget.item!.prices.first.amount}'
        : '',
  );
  late String _rate = widget.item != null && widget.item!.prices.isNotEmpty
      ? widget.item!.prices.first.rate
      : 'PER_HOUR';
  late String? _categoryId =
      widget.item?.categoryId ?? widget.initialCategoryId;
  late String? _cityId = widget.item?.serviceCityId;
  CatalogGroup? _group;
  String? _savedEquipmentId;
  bool _saving = false;
  bool _details = false;
  late final _plate = TextEditingController(text: widget.item?.plateNumber);
  bool _uploading = false;
  String? _pendingPhoto;
  bool get _editable => widget.item == null || widget.item!.status == 'DRAFT';

  @override
  void dispose() {
    _name.dispose();
    _model.dispose();
    _plate.dispose();
    _comment.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    final item = widget.item;
    if (_uploading) return;
    setState(() => _uploading = true);
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (image == null || !mounted) return;
      if (item == null) {
        setState(() => _pendingPhoto = image.path);
        return;
      }
      await ref
          .read(companyServiceProvider)
          .uploadEquipmentImage(widget.companyId, item.id, image.path);
      ref.invalidate(companyFleetProvider(widget.companyId));
      if (mounted) {
        companySnack(
          context,
          AppLocalizations.of(context)!.companyEquipmentSaved,
        );
      }
    } catch (error) {
      if (mounted) companySnack(context, companyErrorText(context, error));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (_saving ||
        !_editable ||
        !(_form.currentState?.validate() ?? false) ||
        _categoryId == null) {
      return;
    }
    setState(() => _saving = true);
    try {
      final equipmentId = await ref
          .read(companyServiceProvider)
          .saveEquipment(
            widget.companyId,
            item: widget.item,
            equipmentId: _savedEquipmentId,
            name: _name.text,
            model: _model.text,
            plateNumber: _plate.text,
            categoryId: _categoryId!,
            serviceCityId: _cityId,
            ownerComment: _comment.text,
          );
      _savedEquipmentId = equipmentId;
      if (_pendingPhoto != null) {
        await ref
            .read(companyServiceProvider)
            .uploadEquipmentImage(
              widget.companyId,
              equipmentId,
              _pendingPhoto!,
            );
        _pendingPhoto = null;
      }
      final remainingPrices =
          widget.item?.prices.skip(1).toList() ?? <CompanyPrice>[];
      final amountText = _price.text.trim();
      if (amountText.isNotEmpty) {
        final amount = int.parse(amountText);
        await ref.read(companyServiceProvider).setPrices(
          widget.companyId,
          equipmentId,
          [
            CompanyPrice(
              amount: amount,
              rate: _rate,
              label: widget.item?.prices.firstOrNull?.label,
              isStartingFrom:
                  widget.item?.prices.firstOrNull?.isStartingFrom ?? false,
            ),
            ...remainingPrices,
          ],
        );
      } else if (widget.item != null && widget.item!.prices.isNotEmpty) {
        await ref
            .read(companyServiceProvider)
            .setPrices(widget.companyId, equipmentId, remainingPrices);
      }
      if (mounted) {
        companySnack(
          context,
          AppLocalizations.of(context)!.companyEquipmentSaved,
        );
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) companySnack(context, companyErrorText(context, error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final catalog = ref.watch(catalogProvider);
    final locale = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.item == null
              ? l10n.companyAddEquipment
              : l10n.companyEditEquipment,
        ),
      ),
      body: catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              CompanyNotice(l10n.companyLoadFailed),
              TextButton(
                onPressed: () => ref.invalidate(catalogProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (catalog) {
          final originalCategory = catalog.categories
              .where((category) => category.id == _categoryId)
              .firstOrNull;
          final group =
              _group ??
              originalCategory?.catalogGroup ??
              CatalogGroup.machinery;
          final categories = catalog.categories
              .where(
                (category) =>
                    category.catalogGroup == group &&
                    (category.isOwnerVisible || category.id == _categoryId),
              )
              .toList();
          final cities = catalog.cities
              .where(
                (city) =>
                    (city.isVisible && city.acceptsEquipment) ||
                    city.id == _cityId,
              )
              .toList();
          return Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                if (widget.item != null || !_details) ...[
                  CompanyDropdownField<CatalogGroup>(
                    key: ValueKey(group),
                    title: l10n.navEquipment,
                    value: group,
                    options: [
                      DropdownOption(
                        value: CatalogGroup.machinery,
                        label: l10n.catalogGroupMachinery,
                      ),
                      DropdownOption(
                        value: CatalogGroup.equipment,
                        label: l10n.catalogGroupEquipment,
                      ),
                    ],
                    onChanged: !_editable || _saving
                        ? null
                        : (value) => setState(() {
                            _group = value;
                            _categoryId = null;
                          }),
                  ),
                  const SizedBox(height: 20),
                  CompanyDropdownField<String>(
                    key: ValueKey('${group.name}:$_categoryId'),
                    title: l10n.equipmentCategoryLabel,
                    value: categories.any((c) => c.id == _categoryId)
                        ? _categoryId
                        : null,
                    options: [
                      for (final c in categories)
                        DropdownOption(value: c.id, label: c.label(locale)),
                    ],
                    validator: (value) =>
                        value == null ? l10n.companyCategoryRequired : null,
                    onChanged: !_editable || _saving
                        ? null
                        : (value) => setState(() => _categoryId = value),
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    controller: _name,
                    title: l10n.equipmentNameLabel,
                    maxLength: 100,
                    enabled: _editable && !_saving,
                    validator: (value) => (value?.trim().length ?? 0) < 2
                        ? l10n.companyFieldRequired
                        : null,
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    controller: _model,
                    title: l10n.companyModel,
                    maxLength: 100,
                    enabled: _editable && !_saving,
                    validator: (value) => (value?.trim().isEmpty ?? true)
                        ? l10n.companyFieldRequired
                        : null,
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    controller: _plate,
                    title: l10n.companyPlateNumber,
                    maxLength: 30,
                    enabled: _editable && !_saving,
                    validator: (value) =>
                        group == CatalogGroup.machinery &&
                            (value?.trim().isEmpty ?? true)
                        ? l10n.companyFieldRequired
                        : null,
                  ),
                  const SizedBox(height: 24),
                  if (widget.item == null)
                    AppElevatedButton(
                      title: l10n.companyNextStep,
                      onTap: () {
                        if (_form.currentState?.validate() ?? false) {
                          setState(() => _details = true);
                        }
                      },
                    ),
                ],
                if (widget.item != null || _details) ...[
                  if (widget.item == null)
                    TextButton(
                      onPressed: () => setState(() => _details = false),
                      child: Text(l10n.companyBackToBasics),
                    ),
                  CompanyDropdownField<String>(
                    key: ValueKey('city:$_cityId'),
                    title: l10n.city,
                    value: cities.any((c) => c.id == _cityId) ? _cityId : null,
                    options: [
                      for (final c in cities)
                        DropdownOption(value: c.id, label: c.label(locale)),
                    ],
                    onChanged: !_editable || _saving
                        ? null
                        : (value) => setState(() => _cityId = value),
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    controller: _comment,
                    title: l10n.companyComment,
                    maxLength: 1000,
                    maxLines: 4,
                    enabled: _editable && !_saving,
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    controller: _price,
                    title: l10n.companyPrice,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    enabled: _editable && !_saving,
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return null;
                      final amount = int.tryParse(text);
                      if (amount == null || amount < 0 || amount > 100000000) {
                        return l10n.companyAmountInvalid;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  CompanyDropdownField<String>(
                    key: ValueKey(_rate),
                    title: l10n.priceRateLabel,
                    value: _rate,
                    options: [
                      DropdownOption(value: 'PER_HOUR', label: l10n.perHour),
                      DropdownOption(value: 'PER_DAY', label: l10n.perDay),
                      DropdownOption(value: 'PER_TRIP', label: l10n.perTrip),
                      DropdownOption(
                        value: 'PER_CUBIC_METER',
                        label: l10n.perM3,
                      ),
                    ],
                    onChanged: !_editable || _saving
                        ? null
                        : (value) => setState(() => _rate = value),
                  ),
                  ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _uploading ? null : _addPhoto,
                      icon: _uploading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(LucideIcons.camera),
                      label: Text(l10n.companyAddPhoto),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (_editable)
                    AppElevatedButton(
                      title: l10n.save,
                      onTap: _save,
                      isLoading: _saving,
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
