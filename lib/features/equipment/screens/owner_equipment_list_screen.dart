import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/constants/app_colors.dart' as legacy_colors;
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/companies/company_service.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/categories/widgets/catalog_group_tabs.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_provider.dart';
import 'package:prokat/features/equipment/providers/owner_fleet_groups_provider.dart';
import 'package:prokat/features/equipment/widgets/list/equipment_error_tile.dart';
import 'package:prokat/features/equipment/widgets/owner/owner_equipment_card.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:shimmer/shimmer.dart';

class OwnerEquipmentListScreen extends ConsumerStatefulWidget {
  const OwnerEquipmentListScreen({super.key});

  @override
  ConsumerState<OwnerEquipmentListScreen> createState() =>
      _OwnerEquipmentListScreenState();
}

class _OwnerEquipmentListScreenState
    extends ConsumerState<OwnerEquipmentListScreen>
    with WidgetsBindingObserver {
  Future<void> loadData() async {
    ref.invalidate(companyContextProvider);
    await Future.wait([
      ref.read(ownerEquipmentProvider.notifier).refresh(),
      ref.refresh(ownerFleetGroupsProvider.future),
    ]);
  }

  Widget _companyEntry(AppLocalizations l10n) {
    final memberships =
        ref.watch(companyContextProvider).valueOrNull?.memberships ?? const [];
    if (memberships.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          title: Text(memberships.first.organization.name),
          subtitle: Text(l10n.companyFleet),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppRoutes.companies),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    unawaited(
      Future.microtask(() {
        unawaited(ref.read(ownerEquipmentProvider.notifier).refreshIfStale());
        unawaited(ref.refresh(ownerFleetGroupsProvider.future));
      }),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final equipmentState = ref.watch(ownerEquipmentProvider);
    final fleetGroups =
        ref.watch(ownerFleetGroupsProvider).valueOrNull ?? const [];
    final selectedGroup = coerceCatalogGroup(
      ref.watch(ownerFleetCatalogGroupProvider),
      fleetGroups,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: loadData,
        child: equipmentState.when(
          loading: () => ListView(
            children: [
              ListView.builder(
                itemCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) => Shimmer.fromColors(
                  baseColor: Colors.grey[500]!.withValues(alpha: 0.2),
                  highlightColor: Colors.grey[200]!.withValues(alpha: 0.2),
                  child: Container(
                    height: 140,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),

          error: (error, stackTrace) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              EquipmentErrorTile(onRetry: () => unawaited(loadData())),
            ],
          ),

          data: (query) {
            final items = fleetGroups.length < 2
                ? query.items
                : query.items
                      .where(
                        (item) => item.category?.catalogGroup == selectedGroup,
                      )
                      .toList();

            final hasCompany =
                ref
                    .watch(companyContextProvider)
                    .valueOrNull
                    ?.memberships
                    .isNotEmpty ==
                true;
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _companyEntry(l10n),
                if (hasCompany)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      l10n.companyPersonalFleet,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                if (fleetGroups.length > 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: CatalogGroupTabs(
                      groups: fleetGroups,
                      selected: selectedGroup,
                      onChanged: (group) {
                        ref
                            .read(ownerFleetCatalogGroupProvider.notifier)
                            .select(group);
                      },
                    ),
                  ),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: EmptyStateTile(
                      title: l10n.noEquipmentListed,
                      imageName: 'empty_equipment.png',
                      imageHeight: 168,
                      imageFit: BoxFit.contain,
                      actionButton: AppElevatedButton(
                        title: l10n.add,
                        onTap: () =>
                            context.push(AppRoutes.ownerEquipmentCreate),
                      ),
                    ),
                  )
                else ...[
                  if (query.isRefreshing)
                    const LinearProgressIndicator(minHeight: 2),

                  ListView.separated(
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                      color: legacy_colors.AppColors.teal700,
                    ),
                    itemCount: items.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) =>
                        OwnerEquipmentCard(equipment: items[index]),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
