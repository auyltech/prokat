import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_elevated_button.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

import 'company_equipment_screen.dart';
import 'company_models.dart';
import 'company_service.dart';
import 'company_widgets.dart';

class CompanyCategoryScreen extends ConsumerWidget {
  final String companyId;
  final String categoryId;
  const CompanyCategoryScreen({
    super.key,
    required this.companyId,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final fleet = ref.watch(companyFleetProvider(companyId));
    final catalog = ref.watch(catalogProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.companyFleet,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: fleet.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              CompanyNotice(l10n.companyLoadFailed),
              TextButton(
                onPressed: () =>
                    ref.invalidate(companyFleetProvider(companyId)),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (park) {
          final category = park.groups
              .expand((group) => group.categories)
              .where((item) => item.id == categoryId)
              .firstOrNull;
          if (category == null) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                CompanyNotice(l10n.companyFleetEmpty),
                const SizedBox(height: 16),
                AppElevatedButton(
                  title: l10n.companyAddEquipment,
                  onTap: () => _openEditor(context, ref),
                  prefix: const Icon(LucideIcons.plus),
                ),
              ],
            );
          }
          final imageUrl = catalog?.categories
              .where((entry) => entry.id == category.id)
              .firstOrNull
              ?.imageUrl;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: OptimizedNetworkImage(
                      imageUrl: imageUrl,
                      width: 64,
                      height: 56,
                      fallbackIcon: LucideIcons.wrench,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.label(locale),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.companyAvailability(
                            category.total,
                            category.busy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppElevatedButton(
                title: l10n.companyAddEquipment,
                onTap: () => _openEditor(context, ref, categoryId: category.id),
                prefix: const Icon(LucideIcons.plus),
              ),
              const SizedBox(height: 12),
              for (final item in category.items)
                CompanySection(
                  child: Column(
                    children: [
                      Material(
                        type: MaterialType.transparency,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: OptimizedNetworkImage(
                              imageUrl: item.imageUrl,
                              width: 56,
                              height: 48,
                              fallbackIcon: LucideIcons.truck400,
                            ),
                          ),
                          title: Text(item.name),
                          subtitle: Text(
                            [
                              if (item.model.isNotEmpty) item.model,
                              companyEquipmentStatus(l10n, item),
                              if (item.prices.isNotEmpty)
                                item.prices
                                    .map(
                                      (price) => companyPriceText(l10n, price),
                                    )
                                    .join(', '),
                            ].join('\n'),
                          ),
                          trailing: const Icon(LucideIcons.chevronRight),
                          onTap: () => _openEditor(context, ref, item: item),
                        ),
                      ),
                      Material(
                        type: MaterialType.transparency,
                        child: SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            item.busy ? l10n.companyBusy : l10n.companyFree,
                          ),
                          value: !item.busy,
                          onChanged: (free) async {
                            try {
                              await ref
                                  .read(companyServiceProvider)
                                  .availability(companyId, item.id, !free);
                              ref.invalidate(companyFleetProvider(companyId));
                            } catch (e) {
                              if (context.mounted) {
                                companySnack(
                                  context,
                                  companyErrorText(context, e),
                                );
                              }
                            }
                          },
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: Icon(
                            LucideIcons.trash2,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          label: Text(
                            l10n.delete,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(l10n.companyRemoveEquipment),
                                content: Text(item.name),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text(l10n.cancel),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text(l10n.delete),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed != true) return;
                            try {
                              await ref
                                  .read(companyServiceProvider)
                                  .archive(companyId, item.id);
                              ref.invalidate(companyFleetProvider(companyId));
                              ref.invalidate(companyBillingProvider(companyId));
                            } catch (e) {
                              if (context.mounted) {
                                companySnack(
                                  context,
                                  companyErrorText(context, e),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    CompanyFleetItem? item,
    String? categoryId,
  }) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CompanyEquipmentScreen(
          companyId: companyId,
          item: item,
          initialCategoryId: categoryId,
        ),
      ),
    );
    if (updated == true) ref.invalidate(companyFleetProvider(companyId));
  }
}
