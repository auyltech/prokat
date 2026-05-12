import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/constants/app_colors.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/input_field.dart';
import 'package:prokat/core/widgets/page_header.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';
import 'package:prokat/features/equipment/widgets/owner/category_selector_tile.dart';

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
  final List<String> _cities = [
    "Almaty",
    "Astana",
    "Atyrau",
    "Shymkent",
    "Aktau",
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final equipmentState = ref.watch(equipmentProvider);
      final category = equipmentState.category;

      if (category == null) {
        return;
      }

      final res = await ref.read(equipmentProvider.notifier).createEquipment({
        "categoryId": category.id,
        "city": _cityController.text.trim(),
        "name": _name.text.trim(),
        "model": _model.text.trim(),
        "plateNumber": _plateNumber.text.trim(),
      });

      if (res == true && mounted) {
        context.pop();

        AppSnackBar.show(context, message: "Equipment Added", isSuccess: true);
      } else {
        AppSnackBar.show(
          context,
          message: "Could not add equipment",
          isError: true,
        );
      }
    } catch (e) {
      AppSnackBar.show(context, message: "Something went wrong", isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final location = _cityController.text.trim();
    final bool hasLocation = location.isNotEmpty;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: ListView(
        children: [
          PageHeader(
            title: "Add Equipment",
            primaryColor: AppColors.teal700,
            showBack: true,
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CategorySelectorTile(mode: "create_equipment"),

                  const SizedBox(height: 16),

                  // City Selector
                  GestureDetector(
                    onTap: () {
                      // Logic: If list has 1 value, take it. Otherwise, take the first.
                      // final String defaultCity = cities.length == 1
                      //     ? cities.first
                      //     : cities[0];

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
                                  "Select City",
                                  style: theme.textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 10),
                                ..._cities.map(
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

                                      Navigator.pop(context); // Close the sheet
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
                            color: hasLocation
                                ? theme.colorScheme.primary.withValues(
                                    alpha: 0.2,
                                  )
                                : theme.colorScheme.primary.withValues(
                                    alpha: 0.2,
                                  ),
                            shape: BoxShape.circle,
                          ),

                          child: Icon(
                            hasLocation
                                ? Icons.pin_drop
                                : Icons.pin_drop_outlined,
                            color: hasLocation
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
                              // Text(
                              //   "City",
                              //   style: theme.textTheme.labelMedium
                              //       ?.copyWith(color: theme.primaryColor),
                              // ),
                              // const SizedBox(height: 4),
                              Text(
                                hasLocation
                                    ? location
                                    : "Select City", // Fallback text
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: hasLocation
                                      ? colorScheme.primary
                                      : colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  InputField(
                    label: "EQUIPMENT NAME",
                    controller: _name,
                    hint: "e.g. Septic Truck",
                    validator: (v) => v!.isEmpty ? "REQUIRED" : null,
                  ),

                  InputField(
                    label: "MODEL",
                    controller: _model,
                    hint: "e.g. KAMAZ-65115",
                  ),
                  InputField(
                    label: "PLATE NUMBER",
                    controller: _plateNumber,
                    hint: "e.g. 777 ABC 01",
                    isLast: true,
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _loading
                          ? null
                          : _submit, // Add your _submit logic
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Add Equipment",
                              style: TextStyle(fontWeight: FontWeight.bold),
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
