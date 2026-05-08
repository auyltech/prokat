import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/constants/cities.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/edit_sheet.dart';
import 'package:prokat/core/widgets/section_title.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';
import 'package:prokat/features/equipment/widgets/owner/open_location_picker_sheet.dart';

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

  Future<void> _handleSave() async {
    try {
      final res = await widget.ref
          .read(equipmentProvider.notifier)
          .updateEquipmentLocation(widget.equipment.id, {
            "id": widget.equipment.id,
            "city": _cityController.text.trim(),
          });

      if (mounted && res == true) {
        setState(() {
          _isDirty = false;
          _isSaving = false;
        });

        AppSnackBar.show(
          context,
          message: "Equipment Updated",
          isSuccess: true,
        );
      } else {
        setState(() {
          _isDirty = true;
          _isSaving = false;
        });
      }
    } catch (_) {
      setState(() => _isSaving = false);
      AppSnackBar.show(context, message: "Update Failed", isError: true);
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
    Navigator.pop(context); // Close the sheet
    setState(() {}); // Refresh the UI (icons/colors)
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final accent = colorScheme.primary;
    final warning = colorScheme.tertiary;

    final location = widget.location;
    final bool hasLocation = location != null && location.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SectionTitle(title: "Location"),

              _isDirty
                  ? TextButton.icon(
                      onPressed: _isSaving ? null : _handleSave,
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
                      label: const Text("Save"),
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
              // Check if the text is not empty to determine 'hasLocation'
              final bool hasLocation = value.text.isNotEmpty;

              return GestureDetector(
                onTap: () {
                  // Logic: If list has 1 value, take it. Otherwise, take the first.
                  // final String defaultCity = cities.length == 1
                  //     ? cities.first
                  //     : cities[0];

                  showEditSheet(
                    context: context,
                    sheet: EditSheet(
                      title: "Select City",
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
                              "City",
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hasLocation
                                  ? value.text
                                  : "Select City", // Fallback text
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

          SizedBox(height: 12),

          /// Equipment Location
          GestureDetector(
            onTap: () => openLocationPickerSheet(
              context,
              widget.ref,
              widget.equipment.id,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
                          hasLocation ? "Current Location" : "Enter Location",
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasLocation ? location : "Equipment base location",
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
          ),
        ],
      ),
    );
  }
}
