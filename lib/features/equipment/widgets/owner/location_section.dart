import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/constants/cities.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/edit_sheet.dart';
import 'package:prokat/core/widgets/section_title.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class LocationSection extends StatefulWidget {
  final Equipment equipment;
  final String? location;
  final WidgetRef ref;

  const LocationSection({
    super.key,
    required this.equipment,
    required this.location,
    required this.ref,
  });

  @override
  State<LocationSection> createState() => _LocationSectionState();
}

class _LocationSectionState extends State<LocationSection> {
  late TextEditingController _cityController;

  bool _isDirty = false;
  bool _isSaving = false;

  Future<void> _handleSave(AppLocalizations l10n) async {
    try {
      final res = await widget.ref
          .read(equipmentMutationProvider.notifier)
          .updateEquipmentLocation(widget.equipment.id, {
            "id": widget.equipment.id,
            "city": _cityController.text.trim(),
          });

      if (mounted && res == true) {
        setState(() {
          _isDirty = false;
          _isSaving = false;
        });

        AppSnackBar.show(message: l10n.equipmentUpdated, isSuccess: true);
      } else {
        setState(() {
          _isDirty = true;
          _isSaving = false;
        });
      }
    } catch (_) {
      setState(() => _isSaving = false);
      if (mounted) {
        AppSnackBar.show(message: l10n.updateFailed, isError: true);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(text: widget.equipment.city);
  }

  void _selectCity(String city) {
    _cityController.text = city;
    if (!_isDirty && city != widget.equipment.city) {
      setState(() => _isDirty = true);
    }
    Navigator.pop(context);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final accent = colorScheme.primary;
    final warning = colorScheme.tertiary;

    // final location = widget.location;
    // final bool hasLocation = location != null && location.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SectionTitle(title: l10n.location),

              _isDirty
                  ? TextButton.icon(
                      onPressed: _isSaving ? null : () => _handleSave(l10n),
                      icon: _isSaving
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Icon(Icons.save_rounded, size: 16),
                      label: Text(l10n.save),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.onPrimary,
                        backgroundColor: accent,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.lock_outline_rounded,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        size: 18,
                      ),
                    ),
            ],
          ),

          // Equipment City
          ValueListenableBuilder(
            valueListenable: _cityController,
            builder: (context, value, child) {
              final bool hasLocation = value.text.isNotEmpty;

              return GestureDetector(
                onTap: () {
                  showEditSheet(
                    context: context,
                    sheet: EditSheet(
                      title: l10n.selectCity,
                      buttonText: "",
                      onSubmit: () => {},
                      child: StatefulBuilder(
                        builder: (context, setLocalState) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 10),
                                ...cities.map(
                                  (city) => ListTile(
                                    title: Text(city),
                                    leading: const Icon(Icons.location_city),
                                    trailing: _cityController.text == city
                                        ? Icon(
                                            Icons.check_circle,
                                            color: accent,
                                          )
                                        : null,
                                    onTap: () => _selectCity(city),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceBright,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasLocation ? Icons.pin_drop : Icons.pin_drop_outlined,
                        color: hasLocation ? accent : warning,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.city,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hasLocation ? value.text : l10n.selectCity,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: hasLocation
                                    ? colorScheme.onSurface
                                    : warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // SizedBox(height: 12),

          /// Equipment Location
          // GestureDetector(
          //   onTap: () => openLocationPickerSheet(
          //     context,
          //     widget.ref,
          //     widget.equipment.id,
          //   ),
          //   child: Container(
          //     padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          //     decoration: BoxDecoration(
          //       color: theme.colorScheme.surfaceBright,
          //       borderRadius: BorderRadius.circular(16),
          //       border: Border.all(
          //         color: colorScheme.outline.withValues(alpha: 0.2),
          //       ),
          //     ),
          //     child: Row(
          //       children: [
          //         Icon(
          //           hasLocation ? Icons.pin_drop : Icons.pin_drop_outlined,
          //           color: hasLocation ? accent : warning,
          //           size: 26,
          //         ),
          //         const SizedBox(width: 12),

          // Expanded(
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Text(
          //         hasLocation ? l10n.currentLocation : l10n.enterLocation,
          //         style: theme.textTheme.labelMedium?.copyWith(
          //           color: theme.primaryColor,
          //         ),
          //       ),
          //       const SizedBox(height: 4),
          //       Text(
          //         hasLocation ? location : l10n.equipmentBaseLocation,
          //         style: theme.textTheme.bodyMedium?.copyWith(
          //           color: hasLocation
          //               ? colorScheme.onSurface
          //               : warning,
          //           fontWeight: FontWeight.w600,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}
