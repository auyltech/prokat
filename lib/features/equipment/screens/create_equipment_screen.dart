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
  final _capacity = TextEditingController();
  final _rentCondition = TextEditingController();
  final _ownerComment = TextEditingController();

  bool _loading = false;

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
        "name": _name.text.trim(),
        "model": _model.text.trim(),
        "plateNumber": "plate",
        "city": "Atyrau",
        "capacity": int.tryParse(_capacity.text.trim()) ?? 0,
        "rentCondition": _rentCondition.text.trim(),
        "ownerComment": _ownerComment.text.trim(),
        "categoryId": category.id,
      });

      if (res == true && mounted) {
        context.pop();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final equipmentState = ref.watch(equipmentProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 2,
            backgroundColor: theme.colorScheme.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => context.pop(),
              color: theme.colorScheme.onPrimary,
            ),
            title: Text(
              "Add Equipment",
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
            centerTitle: false,
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            sliver: SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 1. Category selector
                    CategorySelectorTile(mode: "create_equipment"),

                    const SizedBox(height: 16),

                    /// 2. Form card
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
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
                            label: "UNIT CAPACITY",
                            controller: _capacity,
                            hint: "0",
                            isNumeric: true,
                            suffixText: equipmentState.category?.capacityUnit,
                          ),
                          InputField(
                            label: "RENTAL CONDITIONS",
                            controller: _rentCondition,
                            hint: "Terms of service...",
                          ),
                          InputField(
                            label: "ADMINISTRATIVE COMMENT",
                            controller: _ownerComment,
                            hint: "Internal notes...",
                            isLast: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// 3. Status
                    Center(
                      child: Text(
                        _loading ? "Saving..." : "",
                        style: TextStyle(
                          color: _loading
                              ? colorScheme.primary
                              : colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),

                    _loading ? const SizedBox(height: 16) : SizedBox(),

                    /// 4. Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          disabledBackgroundColor: colorScheme.primary
                              .withValues(alpha: 0.3),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Add",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
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
