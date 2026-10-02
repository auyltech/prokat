import 'dart:async';

import 'package:prokat/features/equipment/providers/equipment_dependencies.dart';
import 'package:prokat/features/company_profile/company_workspace.dart';
import 'package:prokat/features/company_profile/company_profile_api.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/utils/kz_plate_mask.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/categories/widgets/catalog_group_tabs.dart';
import 'package:prokat/features/categories/widgets/category_picker_sheet.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';
import 'package:prokat/features/equipment/utils/equipment_limits.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
import 'package:prokat/features/user/state/client_profile_provider.dart';
import 'package:prokat/features/user/widgets/city_picker_sheet.dart';
import 'package:prokat/l10n/app_localizations.dart';

class CreateEquipmentScreen extends ConsumerStatefulWidget {
  const CreateEquipmentScreen({super.key});

  @override
  ConsumerState<CreateEquipmentScreen> createState() =>
      _CreateEquipmentScreenState();
}

class _CreateEquipmentScreenState extends ConsumerState<CreateEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _model = TextEditingController();
  final _plateNumber = TextEditingController();

  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  bool _loading = false;
  String _city = '';
  bool _citySeeded = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(_onFieldsChanged);
    _model.addListener(_onFieldsChanged);
    _plateNumber.addListener(_onFieldsChanged);

    unawaited(
      Future.microtask(() async {
        await Future.wait([
          ref.read(categoriesProvider.notifier).refreshIfStale(),
          if (ref.read(equipmentServiceProvider).companyId == null)
            ref.read(ownerProfileProvider.notifier).refreshIfStale(),
        ]);
        if (!mounted) return;
        _seedCityIfNeeded();
        setState(() {});
      }),
    );
  }

  void _onFieldsChanged() {
    if (mounted) setState(() {});
  }

  void _seedCityIfNeeded() {
    if (_citySeeded) return;
    final seed = _accountCity();
    if (seed.isEmpty) return;
    _city = seed;
    _citySeeded = true;
  }

  String _accountCity() {
    final service = ref.read(equipmentServiceProvider);
    if (service.companyId != null) {
      return ref
                  .read(companyDashboardProvider(service.companyId!))
                  .valueOrNull?['company']?['city']
              as String? ??
          service.companyCity ??
          '';
    }
    final ownerCity = (ref.read(ownerProfileProvider).valueOrNull?.city ?? '')
        .trim();
    if (ownerCity.isNotEmpty) return ownerCity;

    final requestCity =
        (ref.read(ownerRegistrationRequestProvider).valueOrNull?.city ?? '')
            .trim();
    if (requestCity.isNotEmpty) return requestCity;

    final clientCity = (ref.read(clientProfileProvider).userProfile?.city ?? '')
        .trim();
    if (clientCity.isNotEmpty) return clientCity;

    return (ref.read(locationProvider).city ?? '').trim();
  }

  Future<Category?> _openCategorySheet() async {
    final catalog = ref.read(catalogProvider).valueOrNull;
    final groupTabs = ownerVisibleCatalogGroups(catalog);
    final group = coerceCatalogGroup(
      ref.read(mutationCatalogGroupProvider),
      groupTabs,
    );
    final categories =
        catalog?.ownerCategoriesFor(group).map(Category.fromCatalog).toList() ??
        const [];
    final selectedId = ref.read(equipmentMutationProvider).category?.id;

    final picked = await CategoryPickerSheet.show(
      context,
      categories: categories,
      group: group,
      selectedId: selectedId,
      includeAllOption: false,
    );
    if (!mounted || picked == null || picked.isAll) return null;
    return picked.category;
  }

  Future<String?> _openCitySheet() async {
    final selected = await CityPickerSheet.show(
      context: context,
      service: CitySelectorService.createequipment,
      highlightedCity: _city,
    );
    if (!mounted || selected == null || selected.trim().isEmpty) return null;
    return selected.trim();
  }

  Future<void> onSubmit(AppLocalizations l10n) async {
    final isValid = _formKey.currentState?.validate() ?? false;
    final nameOk = _name.text.trim().isNotEmpty;
    final modelOk = _model.text.trim().isNotEmpty;
    final category = ref.read(equipmentMutationProvider).category;
    final plateRequired = !_isEquipmentGroup;
    final plateOk =
        !plateRequired || sanitizeKzPlate(_plateNumber.text).trim().isNotEmpty;
    final city = _city.trim();

    if (!isValid ||
        !nameOk ||
        !modelOk ||
        !plateOk ||
        category == null ||
        city.isEmpty) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      if (city.isEmpty) {
        AppToast.show(message: l10n.cityRequired, type: AppToastType.error);
      }
      return;
    }

    setState(() => _loading = true);

    try {
      final plate = sanitizeKzPlate(_plateNumber.text).trim();
      final result = await ref
          .read(equipmentMutationProvider.notifier)
          .createEquipment({
            "categoryId": category.id,
            "city": city,
            "name": _name.text.trim(),
            "model": _model.text.trim(),
            if (plateRequired && plate.isNotEmpty) "plateNumber": plate,
          });

      if (result == true && mounted) {
        final service = ref.read(equipmentServiceProvider);
        if (service.companyId != null &&
            service.lastCreatedEquipmentId != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => CompanyEquipmentDetailsPage(
                id: service.lastCreatedEquipmentId!,
              ),
            ),
          );
        } else {
          context.pop();
        }
        AppToast.show(message: l10n.equipmentAdded, type: AppToastType.success);
      } else if (mounted) {
        AppToast.show(
          message: l10n.couldNotAddEquipment,
          type: AppToastType.error,
        );
      }
    } catch (error) {
      if (mounted) {
        AppToast.show(
          message: l10n.somethingWentWrong,
          type: AppToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _isEquipmentGroup {
    final catalog = ref.read(catalogProvider).valueOrNull;
    final group = coerceCatalogGroup(
      ref.read(mutationCatalogGroupProvider),
      ownerVisibleCatalogGroups(catalog),
    );
    return group == CatalogGroup.equipment;
  }

  @override
  void dispose() {
    _name.removeListener(_onFieldsChanged);
    _model.removeListener(_onFieldsChanged);
    _plateNumber.removeListener(_onFieldsChanged);
    _name.dispose();
    _model.dispose();
    _plateNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = l10n.localeName;

    final equipmentState = ref.watch(equipmentMutationProvider);
    final category = equipmentState.category;
    final catalog = ref.watch(catalogProvider).valueOrNull;
    final groupTabs = ownerVisibleCatalogGroups(catalog);
    final mutationGroup = coerceCatalogGroup(
      ref.watch(mutationCatalogGroupProvider),
      groupTabs,
    );

    if (ref.watch(equipmentServiceProvider).companyId == null) {
      ref.watch(ownerProfileProvider);
      ref.watch(ownerRegistrationRequestProvider);
    }
    ref.watch(clientProfileProvider);
    ref.watch(locationProvider.select((state) => state.city));
    _seedCityIfNeeded();

    final plateRequired = mutationGroup != CatalogGroup.equipment;
    final cityOk = _city.trim().isNotEmpty;
    final canContinue =
        category != null &&
        cityOk &&
        _name.text.trim().isNotEmpty &&
        _model.text.trim().isNotEmpty &&
        (!plateRequired ||
            sanitizeKzPlate(_plateNumber.text).trim().isNotEmpty) &&
        !_loading;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(categoriesProvider.notifier).refresh(),
            if (ref.read(equipmentServiceProvider).companyId == null)
              ref.read(ownerProfileProvider.notifier).refresh(),
          ]);
          if (!mounted) return;
          if (!_citySeeded) {
            _seedCityIfNeeded();
            setState(() {});
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Form(
              key: _formKey,
              autovalidateMode: _autovalidateMode,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CatalogGroupTabs(
                    groups: groupTabs,
                    selected: mutationGroup,
                    onChanged: (group) {
                      ref
                          .read(mutationCatalogGroupProvider.notifier)
                          .select(group);
                      ref
                          .read(equipmentMutationProvider.notifier)
                          .clearCategory();
                    },
                  ),
                  if (groupTabs.length > 1)
                    const SizedBox(height: AppDimens.s12$md),
                  AppDropdownField<Category>(
                    title: mutationGroup == CatalogGroup.equipment
                        ? l10n.equipmentCatalogCategoryLabel
                        : l10n.equipmentCategoryLabel,
                    hint: l10n.pleaseSelectCategory,
                    isRequired: true,
                    sheetTitle: l10n.selectCategory,
                    value: category,
                    selectedLabel: category?.localizedName(locale),
                    openCustomSheet: _openCategorySheet,
                    onChanged: (picked) {
                      ref
                          .read(equipmentMutationProvider.notifier)
                          .selectCategory(picked);
                    },
                  ),
                  const SizedBox(height: AppDimens.s16$base),
                  if (ref.watch(equipmentServiceProvider).companyId == null)
                    AppDropdownField<String>(
                      title: l10n.city,
                      hint: l10n.selectCity,
                      isRequired: true,
                      sheetTitle: l10n.selectCity,
                      value: cityOk ? _city : null,
                      selectedLabel: cityOk
                          ? catalogCityLabelOf(ref, context, _city)
                          : null,
                      openCustomSheet: _openCitySheet,
                      onChanged: (picked) {
                        setState(() {
                          _city = picked.trim();
                          _citySeeded = true;
                        });
                      },
                    ),
                  const SizedBox(height: AppDimens.s16$base),
                  AppTextField(
                    title: mutationGroup == CatalogGroup.equipment
                        ? l10n.equipmentCatalogNameLabel
                        : l10n.equipmentNameLabel,
                    isRequired: true,
                    controller: _name,
                    hint: mutationGroup == CatalogGroup.equipment
                        ? l10n.equipmentCatalogNameHint
                        : l10n.equipmentNameHint,
                    maxLength: ownerEquipmentTextMaxLength,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(
                        ownerEquipmentTextMaxLength,
                      ),
                    ],
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? l10n.fieldRequired
                        : null,
                  ),
                  const SizedBox(height: AppDimens.s16$base),
                  AppTextField(
                    title: l10n.modelLabel,
                    isRequired: true,
                    controller: _model,
                    hint: mutationGroup == CatalogGroup.equipment
                        ? l10n.equipmentCatalogModelHint
                        : l10n.modelHint,
                    maxLength: ownerEquipmentTextMaxLength,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(
                        ownerEquipmentTextMaxLength,
                      ),
                    ],
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? l10n.fieldRequired
                        : null,
                  ),
                  AppReveal(
                    visible: plateRequired,
                    child: ExcludeFocus(
                      excluding: !plateRequired,
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppDimens.s16$base),
                        child: AppTextField(
                          title: l10n.plateNumberLabel,
                          isRequired: true,
                          controller: _plateNumber,
                          hint: l10n.plateNumberHint,
                          textInputAction: TextInputAction.done,
                          inputFormatters: const [KzPlateInputFormatter()],
                          validator: (value) =>
                              plateRequired &&
                                  sanitizeKzPlate(value ?? '').isEmpty
                              ? l10n.fieldRequired
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.s24$xl),
                  if (ref.watch(equipmentServiceProvider).companyId == null)
                    _DraftCreateInfo(
                      title: l10n.draftWillBeCreated,
                      body: l10n.draftNextStepsHint,
                    ),
                  const SizedBox(height: AppDimens.s16$base),
                  AppElevatedButton(
                    title: l10n.continueAction,
                    isLoading: _loading,
                    onTap: canContinue ? () => onSubmit(l10n) : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftCreateInfo extends StatelessWidget {
  final String title;
  final String body;

  const _DraftCreateInfo({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.s16$base),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimens.s12$md),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppDimens.s08$sm),
          Text(
            body,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.75),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
