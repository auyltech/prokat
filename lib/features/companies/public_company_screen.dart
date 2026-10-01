import 'company_orders_screen.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_elevated_button.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

import 'company_booking_screen.dart';
import 'company_service.dart';
import 'company_widgets.dart';

class PublicCompaniesScreen extends ConsumerWidget {
  const PublicCompaniesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final companies = ref.watch(publicCompaniesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.companyCatalogTitle),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CompanyOrdersScreen()),
            ),
            tooltip: l10n.companyMyInquiries,
            icon: const Icon(LucideIcons.messageCircle400),
          ),
        ],
      ),
      body: companies.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              CompanyNotice(l10n.companyLoadFailed),
              TextButton(
                onPressed: () => ref.invalidate(publicCompaniesProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [CompanyNotice(l10n.companyPublicEmpty)],
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              for (final company in items)
                CompanySection(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: OptimizedNetworkImage(
                        imageUrl: company.logoUrl,
                        width: 56,
                        height: 56,
                        fallbackIcon: LucideIcons.building2,
                      ),
                    ),
                    title: Text(company.name),
                    subtitle: Text(
                      [
                        if (company.city.isNotEmpty) company.city,
                        l10n.companyAvailability(company.total, company.busy),
                      ].join('\n'),
                    ),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            PublicCompanyScreen(companyId: company.id),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class PublicCompanyScreen extends ConsumerWidget {
  final String companyId;
  const PublicCompanyScreen({super.key, required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final card = ref.watch(publicCompanyProvider(companyId));
    final catalog = ref.watch(catalogProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.companyWorkspace)),
      body: card.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              CompanyNotice(l10n.companyLoadFailed),
              TextButton(
                onPressed: () =>
                    ref.invalidate(publicCompanyProvider(companyId)),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (park) {
          final priced = park.items.where((item) => item.prices.isNotEmpty);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              CompanySection(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: PageView(
                          children: [
                            OptimizedNetworkImage(
                              imageUrl: park.company.logoUrl,
                              width: double.infinity,
                              height: 200,
                              fallbackIcon: LucideIcons.building2,
                            ),
                            for (final url in park.company.photoUrls)
                              OptimizedNetworkImage(
                                imageUrl: url,
                                width: double.infinity,
                                height: 200,
                                fallbackIcon: LucideIcons.building2,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                park.company.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              if (park.company.city.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(park.company.city),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (park.company.description.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(park.company.description),
                    ],
                  ],
                ),
              ),
              Text(
                l10n.companyTariffs,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (priced.isEmpty)
                CompanyNotice(l10n.companyTariffsEmpty)
              else
                for (final item in priced)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${item.name}: ${item.prices.map((price) => companyPriceText(l10n, price)).join(', ')}',
                    ),
                  ),
              const SizedBox(height: 16),
              AppElevatedButton(
                title: l10n.companySendRequest,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CompanyBookingScreen(companyId: companyId),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              for (final group in park.groups.where(
                (group) => group.categories.isNotEmpty,
              )) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    group.id == 'EQUIPMENT'
                        ? l10n.catalogGroupEquipment
                        : l10n.catalogGroupMachinery,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                for (final category in group.categories)
                  CompanySection(
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PublicCompanyCategoryScreen(
                            companyId: companyId,
                            categoryId: category.id,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: OptimizedNetworkImage(
                              imageUrl: catalog?.categories
                                  .where((entry) => entry.id == category.id)
                                  .firstOrNull
                                  ?.imageUrl,
                              width: 56,
                              height: 48,
                              fallbackIcon: LucideIcons.wrench,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(category.label(locale)),
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
                          const Icon(LucideIcons.chevronRight),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class PublicCompanyCategoryScreen extends ConsumerWidget {
  final String companyId;
  final String categoryId;
  const PublicCompanyCategoryScreen({
    super.key,
    required this.companyId,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final card = ref.watch(publicCompanyProvider(companyId));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.companyFleet)),
      body: card.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => CompanyNotice(l10n.companyLoadFailed),
        data: (park) {
          final category = park.groups
              .expand((group) => group.categories)
              .where((item) => item.id == categoryId)
              .firstOrNull;
          if (category == null) return CompanyNotice(l10n.companyFleetEmpty);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              Text(
                category.label(locale),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(l10n.companyAvailability(category.total, category.busy)),
              const SizedBox(height: 12),
              for (final item in category.items)
                CompanySection(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Checkbox(
                      value: ref
                          .watch(companySelectionProvider(companyId))
                          .contains(item.id),
                      onChanged: (checked) {
                        final current = {
                          ...ref.read(companySelectionProvider(companyId)),
                        };
                        if (checked == true) {
                          current.add(item.id);
                        } else {
                          current.remove(item.id);
                        }
                        ref
                                .read(
                                  companySelectionProvider(companyId).notifier,
                                )
                                .state =
                            current;
                      },
                    ),
                    title: Text(
                      item.name,
                      style: TextStyle(
                        color: item.status == 'BOOKED'
                            ? Theme.of(context).disabledColor
                            : null,
                      ),
                    ),
                    subtitle: Text(
                      [
                        if (item.model.isNotEmpty) item.model,
                        if (item.status == 'BOOKED') l10n.companyBusy,
                        if (item.prices.isNotEmpty)
                          item.prices
                              .map((price) => companyPriceText(l10n, price))
                              .join(', '),
                      ].join('\n'),
                    ),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PublicCompanyMachineScreen(
                          companyId: companyId,
                          equipmentId: item.id,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class PublicCompanyMachineScreen extends ConsumerWidget {
  final String companyId;
  final String equipmentId;
  const PublicCompanyMachineScreen({
    super.key,
    required this.companyId,
    required this.equipmentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final card = ref.watch(publicCompanyProvider(companyId));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.companyFleet)),
      body: card.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => CompanyNotice(l10n.companyLoadFailed),
        data: (park) {
          final item = park.items
              .where((entry) => entry.id == equipmentId)
              .firstOrNull;
          if (item == null) return CompanyNotice(l10n.companyLoadFailed);
          final busy = item.status == 'BOOKED';
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              if (item.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: OptimizedNetworkImage(
                    imageUrl: item.imageUrl,
                    height: 220,
                    fallbackIcon: LucideIcons.truck400,
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                item.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: busy ? Theme.of(context).disabledColor : null,
                ),
              ),
              if (busy) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.companyBusy,
                  style: TextStyle(color: Theme.of(context).disabledColor),
                ),
              ],
              if (item.model.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('${l10n.companyModel}: ${item.model}'),
              ],
              if (item.ownerComment.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(item.ownerComment),
              ],
              const SizedBox(height: 16),
              Text(
                l10n.companyTariffs,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (item.prices.isEmpty)
                CompanyNotice(l10n.companyTariffsEmpty)
              else
                for (final price in item.prices)
                  Text(companyPriceText(l10n, price)),
            ],
          );
        },
      ),
    );
  }
}
