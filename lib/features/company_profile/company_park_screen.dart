import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/equipment/models/equipment_image_model.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_provider.dart';
import 'package:prokat/features/equipment/screens/create_equipment_screen.dart';
import 'package:prokat/features/equipment/widgets/owner/owner_equipment_card.dart';
import 'package:prokat/features/equipment/widgets/owner/owner_equipment_image_header.dart';
import 'package:prokat/features/notifications/widgets/notification_badge.dart';

import 'company_profile_api.dart';
import 'company_information_screen.dart';
import 'company_workspace.dart';

class CompanyParkScreen extends ConsumerWidget {
  final String companyId;
  const CompanyParkScreen({super.key, required this.companyId});
  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(companyDashboardProvider(companyId));
    await ref.read(companyDashboardProvider(companyId).future);
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: ProkatAppBar(
            title: const Text('Добавить технику'),
            onBack: () => Navigator.of(context).pop(),
            actions: const [NotificationBadge()],
          ),
          body: const CreateEquipmentScreen(),
        ),
      ),
    );
    await _refresh(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: ProkatAppBar(
      title: const Text('Техника компании'),
      actions: [
        AppIconButton(onTap: () => _add(context, ref), icon: Icons.add),
        const NotificationBadge(),
      ],
    ),
    body: ref
        .watch(companyDashboardProvider(companyId))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: AppElevatedButton(
              title: 'Повторить',
              onTap: () => _refresh(ref),
            ),
          ),
          data: (data) {
            final company = data['company'] as Map;
            final categories = data['categories'] as List;
            Future<void> information() async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CompanyInformationScreen(
                    companyId: companyId,
                    dashboard: data,
                  ),
                ),
              );
              await _refresh(ref);
            }

            return RefreshIndicator(
              onRefresh: () => _refresh(ref),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InkWell(
                          onTap: information,
                          child: Stack(
                            children: [
                              OwnerEquipmentImageHeader(
                                equipmentId: companyId,
                                images: (company['images'] as List)
                                    .map(
                                      (i) => EquipmentImage.fromJson(
                                        Map<String, dynamic>.from(i),
                                      ),
                                    )
                                    .toList(),
                                legacyImageUrl: null,
                                emptyText: "Фотографии компании",
                                canEditImages: false,
                              ),
                              Positioned(
                                top: 12,
                                left: 12,
                                right: 12,
                                child: Row(
                                  children: [
                                    _CardBadge(
                                      label: company['isVisible'] == true
                                          ? 'Показывается'
                                          : 'Скрыто',
                                      color: company['isVisible'] == true
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: _CardBadge(
                                          label: catalogCityLabelOf(
                                            ref,
                                            context,
                                            company['city'],
                                          ),
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    AppIconButton(
                                      icon: LucideIcons.share2,
                                      variant: AppIconButtonVariant.soft,
                                      onTap: () =>
                                          shareCompany(context, ref, data),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      (company['advertisingName'] as String)
                                              .isEmpty
                                          ? company['name']
                                          : company['advertisingName'],
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 22,
                                  ),
                                  Text(
                                    (company['ratingAverage'] as num)
                                        .toStringAsFixed(1),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _CountsRow(
                                left:
                                    'Категорий техники ${data['machinery']['categories']}',
                                right:
                                    'Категорий оборудования ${data['equipment']['categories']}',
                              ),
                              const SizedBox(height: 8),
                              _CountsRow(
                                left:
                                    'Диспетчеров онлайн ${data['dispatchers']['online']}',
                                right:
                                    'Диспетчеров офлайн ${data['dispatchers']['offline']}',
                              ),
                              const SizedBox(height: 20),
                              AppElevatedButton(
                                title: 'Информация',
                                onTap: information,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (categories.isEmpty)
                    EmptyStateTile(
                      title: 'Техника ещё не добавлена',
                      compact: true,
                      imageName: 'empty_equipment.png',
                      imageHeight: 72,
                      imageFit: BoxFit.contain,
                      actionButton: AppElevatedButton(
                        title: 'Добавить',
                        onTap: () => _add(context, ref),
                      ),
                    ),
                  for (final group in categories)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        child: InkWell(
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CompanyCategoryScreen(
                                  categoryId: group['category']['id'],
                                  title: _categoryLabel(
                                    ref,
                                    context,
                                    group['category'],
                                  ),
                                ),
                              ),
                            );
                            await _refresh(ref);
                          },
                          child: Row(
                            children: [
                              SizedBox(
                                width: 72,
                                height: 64,
                                child: OptimizedNetworkImage(
                                  imageUrl:
                                      group['category']['image']?['imageUrl'] ??
                                      '',
                                  fit: BoxFit.contain,
                                  fallbackIcon: LucideIcons.truck,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _categoryLabel(
                                        ref,
                                        context,
                                        group['category'],
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Всего ${group['total']} · Показывается ${group['showing']} · Свободно ${group['available']}',
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
  );
}

String _categoryLabel(WidgetRef ref, BuildContext context, Map category) =>
    ref
        .watch(catalogProvider)
        .valueOrNull
        ?.categoryById(category['id'])
        ?.label(Localizations.localeOf(context).languageCode) ??
    category['name']?.toString() ??
    'Категория';

class _CardBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _CardBadge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    ),
  );
}

class _CountsRow extends StatelessWidget {
  final String left, right;
  const _CountsRow({required this.left, required this.right});
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: Text(left)),
      const SizedBox(width: 12),
      Expanded(child: Text(right)),
    ],
  );
}

class CompanyCategoryScreen extends ConsumerWidget {
  final String categoryId, title;
  const CompanyCategoryScreen({
    super.key,
    required this.categoryId,
    required this.title,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: ProkatAppBar(
      title: Text(title),
      onBack: () => Navigator.of(context).pop(),
      actions: const [NotificationBadge()],
    ),
    body: ref
        .watch(ownerEquipmentProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: AppElevatedButton(
              title: 'Повторить',
              onTap: () => ref.read(ownerEquipmentProvider.notifier).refresh(),
            ),
          ),
          data: (query) => RefreshIndicator(
            onRefresh: () =>
                ref.read(ownerEquipmentProvider.notifier).refresh(),
            child: ListView(
              children: [
                for (final unit in query.items.where(
                  (u) => u.categoryId == categoryId,
                ))
                  OwnerEquipmentCard(
                    equipment: unit,
                    showShare: false,
                    onOpen: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              CompanyEquipmentDetailsPage(id: unit.id),
                        ),
                      );
                      await ref.read(ownerEquipmentProvider.notifier).refresh();
                    },
                  ),
              ],
            ),
          ),
        ),
  );
}
