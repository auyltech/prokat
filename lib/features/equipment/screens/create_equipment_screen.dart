import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/constants/cities.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/input_field.dart';
import 'package:prokat/features/equipment/state/equipment_provider.dart';
import 'package:prokat/features/equipment/widgets/owner/category_selector_tile.dart';
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

  bool _loading = false;

  Future<void> onSubmit(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final equipmentState = ref.watch(equipmentProvider);
      final category = equipmentState.category;

      if (category == null) return;

      final result = await ref
          .read(equipmentProvider.notifier)
          .createEquipment({
            "categoryId": category.id,
            "city": _cityController.text.trim(),
            "name": _name.text.trim(),
            "model": _model.text.trim(),
            "plateNumber": _plateNumber.text.trim(),
          });

      if (result == true && mounted) {
        context.pop();
        AppSnackBar.show(
          context,
          message: l10n.equipmentAdded,
          isSuccess: true,
        );
      } else if (mounted) {
        AppSnackBar.show(
          context,
          message: l10n.couldNotAddEquipment,
          isError: true,
        );
      }
    } catch (error) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: l10n.somethingWentWrong,
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final location = _cityController.text.trim();
    final bool hasLocation = location.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CategorySelectorTile(mode: "create_equipment"),

                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (context) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l10n.selectCity,
                                  style: theme.textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 10),
                                ...cities.map(
                                  (city) => ListTile(
                                    title: Text(city),
                                    leading: const Icon(Icons.location_city),
                                    trailing: _cityController.text == city
                                        ? Icon(
                                            Icons.check_circle,
                                            color: theme.colorScheme.primary,
                                          )
                                        : null,
                                    onTap: () {
                                      _cityController.text = city;
                                      Navigator.pop(context);
                                      setState(() {});
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.2,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.location_pin,
                            color: hasLocation
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onPrimary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            hasLocation ? location : l10n.selectCity,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: hasLocation
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  InputField(
                    icon: Icons.badge_outlined,
                    label: l10n.equipmentNameLabel,
                    controller: _name,
                    hint: l10n.equipmentNameHint,
                    validator: (v) => v!.isEmpty ? l10n.required : null,
                  ),

                  const SizedBox(height: 8),
                  InputField(
                    icon: Icons.view_column_outlined,
                    label: l10n.modelLabel,
                    controller: _model,
                    hint: l10n.modelHint,
                  ),
                  const SizedBox(height: 8),
                  InputField(
                    icon: Icons.mp_outlined,
                    label: l10n.plateNumberLabel,
                    controller: _plateNumber,
                    hint: l10n.plateNumberHint,
                    isLast: true,
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _loading ? null : () => onSubmit(l10n),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              l10n.addEquipment,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
