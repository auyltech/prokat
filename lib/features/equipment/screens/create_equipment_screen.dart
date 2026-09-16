import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/utils/kz_plate_mask.dart';
import 'package:prokat/features/equipment/utils/equipment_limits.dart';
import 'package:prokat/core/widgets/ui_kit/toasts/app_toast.dart';
import 'package:prokat/core/widgets/input_field.dart';
import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_elevated_button.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/categories/vacuum_trucks.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';
import 'package:prokat/features/equipment/widgets/owner/category_selection_sheet.dart';
import 'package:prokat/features/equipment/widgets/owner/category_selector_tile.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
import 'package:prokat/features/user/state/client_profile_provider.dart';
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

  Future<void> onSubmit(AppLocalizations l10n) async {
    final isValid = _formKey.currentState?.validate() ?? false;
    final nameOk = _name.text.trim().isNotEmpty;
    final modelOk = _model.text.trim().isNotEmpty;
    final plateOk = sanitizeKzPlate(_plateNumber.text).trim().isNotEmpty;
    if (!isValid || !nameOk || !modelOk || !plateOk) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      return;
    }

    final category = ref.read(equipmentMutationProvider).category;
    if (category == null) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      return;
    }

    await ref.read(ownerProfileProvider.notifier).refreshIfStale();
    if (!mounted) return;

    final city = _selectedCity();
    if (city.isEmpty) {
      AppToast.show(message: l10n.cityRequired, type: AppToastType.error);
      return;
    }

    setState(() => _loading = true);

    try {
      final result = await ref
          .read(equipmentMutationProvider.notifier)
          .createEquipment({
            "categoryId": category.id,
            "city": city,
            "name": _name.text.trim(),
            "model": _model.text.trim(),
            "plateNumber": sanitizeKzPlate(_plateNumber.text).trim(),
          });

      if (result == true && mounted) {
        context.pop();
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

  @override
  void initState() {
    super.initState();

    unawaited(
      Future.microtask(() async {
        await Future.wait([
          ref.read(categoriesProvider.notifier).refreshIfStale(),
          ref.read(ownerProfileProvider.notifier).refreshIfStale(),
        ]);
        if (!mounted) return;
        _selectVacuumCategory();
      }),
    );
  }

  void _selectVacuumCategory() {
    final vacuum = vacuumTrucksCategory(ref.read(catalogProvider).valueOrNull);
    if (vacuum == null) return;
    ref.read(equipmentMutationProvider.notifier).selectCategory(vacuum);
  }

  String _selectedCity() {
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

  @override
  void dispose() {
    _name.dispose();
    _model.dispose();
    _plateNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final equipmentState = ref.watch(equipmentMutationProvider);
    final category = equipmentState.category;
    ref.watch(ownerProfileProvider);
    ref.watch(ownerRegistrationRequestProvider);
    ref.watch(clientProfileProvider);
    ref.watch(locationProvider.select((state) => state.city));
    final accountCity = _selectedCity();

    ref.listen(catalogProvider, (previous, next) {
      final vacuum = vacuumTrucksCategory(next.valueOrNull);
      if (vacuum == null) return;
      ref.read(equipmentMutationProvider.notifier).selectCategory(vacuum);
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(categoriesProvider.notifier).refresh(),
            ref.read(ownerProfileProvider.notifier).refresh(),
          ]);
          if (!mounted) return;
          _selectVacuumCategory();
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                autovalidateMode: _autovalidateMode,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FormField<String>(
                      validator: (_) {
                        if (ref.read(equipmentMutationProvider).category ==
                            null) {
                          return l10n.fieldRequired;
                        }
                        return null;
                      },
                      builder: (state) {
                        return CategorySelectorTile(
                          mode: CategorySheetMode.createEquipment,
                          selectedCategoryId: category?.id,
                          errorText: state.errorText,
                          onChanged: (picked) => state.didChange(picked?.id),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    _AccountCityRow(city: accountCity),

                    const SizedBox(height: 16),

                    InputField(
                      icon: Icons.badge_outlined,
                      label: l10n.equipmentNameLabel,
                      controller: _name,
                      hint: l10n.equipmentNameHint,
                      isRequired: true,
                      requiredHintText: l10n.requiredInParens,
                      showFieldErrors: false,
                      maxLength: ownerEquipmentTextMaxLength,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(
                          ownerEquipmentTextMaxLength,
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    InputField(
                      icon: Icons.view_column_outlined,
                      label: l10n.modelLabel,
                      controller: _model,
                      hint: l10n.modelHint,
                      isRequired: true,
                      requiredHintText: l10n.requiredInParens,
                      showFieldErrors: false,
                      maxLength: ownerEquipmentTextMaxLength,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(
                          ownerEquipmentTextMaxLength,
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    InputField(
                      icon: Icons.mp_outlined,
                      label: l10n.plateNumberLabel,
                      controller: _plateNumber,
                      hint: l10n.plateNumberHint,
                      isRequired: true,
                      requiredHintText: l10n.requiredInParens,
                      showFieldErrors: false,
                      isLast: true,
                      inputFormatters: const [KzPlateInputFormatter()],
                    ),

                    const SizedBox(height: 24),

                    _DraftCreateInfo(
                      title: l10n.draftWillBeCreated,
                      body: l10n.draftNextStepsHint,
                    ),

                    const SizedBox(height: 16),

                    AppElevatedButton(
                      title: l10n.continueAction,
                      isLoading: _loading,
                      onTap: _loading ? null : () => onSubmit(l10n),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountCityRow extends ConsumerWidget {
  final String city;

  const _AccountCityRow({required this.city});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final hasCity = city.trim().isNotEmpty;
    final cityLabel = hasCity
        ? catalogCityLabelOf(ref, context, city)
        : l10n.selectCity;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: hasCity
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceDim,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.location_on_outlined,
            color: hasCity ? Colors.white : Colors.white.withValues(alpha: 0.3),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.city, style: theme.textTheme.labelLarge),
              Text(
                cityLabel,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: hasCity
                      ? null
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
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
          const SizedBox(height: 6),
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
