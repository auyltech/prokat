import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/input_field.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';
import 'package:prokat/features/equipment/widgets/owner/category_selection_sheet.dart';
import 'package:prokat/features/equipment/widgets/owner/category_selector_tile.dart';
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
  final _cityController = TextEditingController();

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

    setState(() => _loading = true);

    try {
      final result = await ref
          .read(equipmentMutationProvider.notifier)
          .createEquipment({
            "categoryId": category.id,
            "city": _cityController.text.trim(),
            "name": _name.text.trim(),
            "model": _model.text.trim(),
            "plateNumber": _plateNumber.text.trim(),
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
      }),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _model.dispose();
    _plateNumber.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final location = _cityController.text.trim();
    final bool hasLocation = location.isNotEmpty;

    final equipmentState = ref.watch(equipmentMutationProvider);
    final category = equipmentState.category;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(categoriesProvider.notifier).refresh();
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

                    FormField<String>(
                      validator: (_) {
                        if (_cityController.text.trim().isEmpty) {
                          return l10n.cityRequired;
                        }
                        return null;
                      },
                      builder: (state) {
                        final hasError = state.hasError;

                        return GestureDetector(
                          onTap: () async {
                            final selectedCity = await CityPickerSheet.show(
                              context: context,
                              service: CitySelectorService.createequipment,
                            );
                            if (!context.mounted) return;
                            if (selectedCity == null || selectedCity.isEmpty) {
                              return;
                            }

                            setState(() {
                              _cityController.text = selectedCity;
                            });
                            state.didChange(selectedCity);
                          },
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: hasError
                                      ? colorScheme.error.withValues(alpha: 0.2)
                                      : theme.colorScheme.primary.withValues(
                                          alpha: 0.2,
                                        ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.location_pin,
                                  color: hasError
                                      ? colorScheme.error
                                      : hasLocation
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onPrimary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hasLocation
                                          ? catalogCityLabelOf(
                                              ref,
                                              context,
                                              location,
                                            )
                                          : l10n.selectCity,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: hasError
                                                ? colorScheme.error
                                                : hasLocation
                                                ? colorScheme.primary
                                                : colorScheme.onSurface,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    if (state.errorText != null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        state.errorText!,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
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
                    ),

                    const SizedBox(height: 24),

                    PrimaryButton(
                      label: l10n.addEquipment,
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
