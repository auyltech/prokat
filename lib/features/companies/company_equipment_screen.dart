import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_elevated_button.dart';
import 'package:prokat/core/widgets/ui_kit/inputs/app_text_field.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/l10n/app_localizations.dart';

import 'company_models.dart';
import 'company_service.dart';
import 'company_widgets.dart';

class CompanyEquipmentScreen extends ConsumerStatefulWidget {
  final String companyId;
  final CompanyFleetItem? item;
  const CompanyEquipmentScreen({super.key, required this.companyId, this.item});
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
  late String? _categoryId = widget.item?.categoryId;
  late String? _cityId = widget.item?.serviceCityId;
  CatalogGroup? _group;
  bool _saving = false;
  bool get _editable =>
      widget.item == null ||
      ['DRAFT', 'REJECTED'].contains(widget.item!.status);

  @override
  void dispose() {
    _name.dispose();
    _model.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving ||
        !_editable ||
        !(_form.currentState?.validate() ?? false) ||
        _categoryId == null)
      return;
    setState(() => _saving = true);
    try {
      await ref
          .read(companyServiceProvider)
          .saveEquipment(
            widget.companyId,
            item: widget.item,
            name: _name.text,
            model: _model.text,
            categoryId: _categoryId!,
            serviceCityId: _cityId,
            ownerComment: _comment.text,
          );
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
                CompanyNotice(
                  _editable
                      ? l10n.companyDraftHint
                      : l10n.companyCategoryChangeHint,
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<CatalogGroup>(
                  key: ValueKey(group),
                  initialValue: group,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.navEquipment,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: CatalogGroup.machinery,
                      child: Text(l10n.catalogGroupMachinery),
                    ),
                    DropdownMenuItem(
                      value: CatalogGroup.equipment,
                      child: Text(l10n.catalogGroupEquipment),
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
                DropdownButtonFormField<String>(
                  key: ValueKey('${group.name}:$_categoryId'),
                  initialValue:
                      categories.any((entry) => entry.id == _categoryId)
                      ? _categoryId
                      : null,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.equipmentCategoryLabel,
                    border: const OutlineInputBorder(),
                  ),
                  items: categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category.id,
                          child: Text(
                            category.label(locale),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: !_editable || _saving
                      ? null
                      : (value) => setState(() => _categoryId = value),
                  validator: (value) =>
                      value == null ? l10n.companyCategoryRequired : null,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _name,
                  title: l10n.equipmentNameLabel,
                  maxLength: 100,
                  enabled: _editable && !_saving,
                  validator: (value) => (value?.trim().isEmpty ?? true)
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
                DropdownButtonFormField<String>(
                  initialValue: cities.any((entry) => entry.id == _cityId)
                      ? _cityId
                      : null,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.city,
                    border: const OutlineInputBorder(),
                  ),
                  items: cities
                      .map(
                        (city) => DropdownMenuItem(
                          value: city.id,
                          child: Text(city.label(locale)),
                        ),
                      )
                      .toList(),
                  onChanged: !_editable || _saving
                      ? null
                      : (value) => setState(() => _cityId = value),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _comment,
                  title: l10n.companyComment,
                  maxLength: 250,
                  maxLines: 4,
                  enabled: _editable && !_saving,
                ),
                const SizedBox(height: 24),
                if (_editable)
                  AppElevatedButton(
                    title: l10n.save,
                    onTap: _save,
                    isLoading: _saving,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
