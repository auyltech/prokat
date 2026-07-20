import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';
import 'package:prokat/features/requests/providers/request_mutation_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

enum CategorySheetMode {
  createRequest,
  createBooking,
  createEquipment,
  editEquipment,
}

class CategorySelectionSheet extends ConsumerWidget {
  final CategorySheetMode service;
  const CategorySelectionSheet({super.key, required this.service});

  static Future<Category?> show(
    BuildContext context, {
    required CategorySheetMode service,
  }) async {
    return await showModalBottomSheet<Category?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CategorySelectionSheet(service: service),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final categories = ref.watch(categoriesProvider).categories;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          Text(l10n.selectService, style: theme.textTheme.titleLarge),

          const SizedBox(height: 16),

          // List the categories
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 4,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.construction_rounded,
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      size: 20,
                    ),
                  ),
                  title: Text(category.name, style: theme.textTheme.bodyLarge),
                  onTap: () {
                    if (service == CategorySheetMode.createRequest) {
                      // Update the Request Notifier
                      ref
                          .read(requestMutationProvider.notifier)
                          .selectCategory(category);
                    } else if (service == CategorySheetMode.createEquipment ||
                        service == CategorySheetMode.editEquipment) {
                      ref
                          .read(equipmentMutationProvider.notifier)
                          .selectCategory(category);
                    }

                    // Close the sheet and return the category to the form
                    Navigator.pop(context, category);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
