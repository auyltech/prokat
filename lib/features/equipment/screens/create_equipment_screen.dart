import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/utils/kz_plate_mask.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/input_field.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/categories/vacuum_trucks.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';
import 'package:prokat/features/equipment/widgets/owner/category_selection_sheet.dart';
import 'package:prokat/features/equipment/widgets/owner/category_selector_tile.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
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
    if (!isValid) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      return;
    }

    final category = ref.read(equipmentMutationProvider).category;
    if (category == null) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      return;
    }

    final city = _selectedCity();
    if (city.isEmpty) {
      AppSnackBar.show(message: l10n.cityRequired, isError: true);
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
        AppSnackBar.show(message: l10n.equipmentAdded, isSuccess: true);
      } else if (mounted) {
        AppSnackBar.show(message: l10n.couldNotAddEquipment, isError: true);
      }
    } catch (error) {
      if (mounted) {
        AppSnackBar.show(message: l10n.somethingWentWrong, isError: true);
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
        await ref.read(categoriesProvider.notifier).refreshIfStale();
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
    final sessionCity = (ref.read(locationProvider).city ?? '').trim();
    if (sessionCity.isNotEmpty) return sessionCity;
    return (ref.read(clientProfileProvider).userProfile?.city ?? '').trim();
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

    ref.listen(catalogProvider, (previous, next) {
      final vacuum = vacuumTrucksCategory(next.valueOrNull);
      if (vacuum == null) return;
      ref.read(equipmentMutationProvider.notifier).selectCategory(vacuum);
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(categoriesProvider.notifier).refresh();
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

                    InputField(
                      icon: Icons.badge_outlined,
                      label: l10n.equipmentNameLabel,
                      controller: _name,
                      hint: l10n.equipmentNameHint,
                      isRequired: true,
                    ),

                    const SizedBox(height: 8),

                    InputField(
                      icon: Icons.view_column_outlined,
                      label: l10n.modelLabel,
                      controller: _model,
                      hint: l10n.modelHint,
                      isRequired: true,
                    ),

                    const SizedBox(height: 8),

                    InputField(
                      icon: Icons.mp_outlined,
                      label: l10n.plateNumberLabel,
                      controller: _plateNumber,
                      hint: l10n.plateNumberHint,
                      isRequired: true,
                      isLast: true,
                      inputFormatters: const [KzPlateInputFormatter()],
                    ),

                    const SizedBox(height: 24),

                    _DraftCreateInfo(
                      title: l10n.draftWillBeCreated,
                      body: l10n.draftNextStepsHint,
                    ),

                    const SizedBox(height: 16),

                    PrimaryButton(
                      label: l10n.continueAction,
                      isLoading: _loading,
                      onPressed: _loading ? null : () => onSubmit(l10n),
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
