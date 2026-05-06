import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/widgets/input_field.dart';
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            content: Text("Equipment Added!"),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            content: Text("Could not add equipment"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text("SYSTEM ERROR: ${e.toString().toUpperCase()}"),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectCity(String city) {
    _cityController.text = city;

    Navigator.pop(context); // Close the sheet
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final location = _cityController.text.trim();
    final bool hasLocation = location.isNotEmpty;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: theme.colorScheme.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
              color: theme.colorScheme.onPrimary,
            ),
            title: Text(
              "Add Equipment",
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            sliver: SliverToBoxAdapter(
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
                                      onTap: () => _selectCity(city),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },

                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.25),
                          ),
                        ),

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
                    ),

                    const SizedBox(height: 16),

                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // City Selector Button/Field
                          // InkWell(
                          //   onTap: _showCityPicker,
                          //   child: IgnorePointer(
                          //     child: InputField(
                          //       label: "CITY",
                          //       controller: _cityController,
                          //       hint: "Select City",
                          //       // suffixIcon: const Icon(
                          //       //   Icons.location_city_rounded,
                          //       // ),
                          //     ),
                          //   ),
                          // ),
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
                        ],
                      ),
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
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
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
          ),
        ],
      ),
    );
  }
}
