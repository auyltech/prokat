import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/constants/app_colors.dart' as legacy_colors;
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
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
    await Future.wait([
      ref.read(ownerEquipmentProvider.notifier).refresh(),
      ref.refresh(ownerFleetGroupsProvider.future),
    ]);
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
    final fetchedGroups = ref.watch(ownerFleetGroupsProvider).valueOrNull;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: equipmentState.when(
        loading: () => RefreshIndicator(
          onRefresh: loadData,
          child: ListView(
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
        ),

        error: (error, stackTrace) => RefreshIndicator(
          onRefresh: loadData,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              EquipmentErrorTile(onRetry: () => unawaited(loadData())),
            ],
          ),
        ),

        data: (query) {
          final fleetGroups = resolveOwnerFleetGroups(
            fetched: fetchedGroups,
            items: query.items,
          );
          final selectedGroup = coerceCatalogGroup(
            ref.watch(ownerFleetCatalogGroupProvider),
            fleetGroups,
          );
          if (fleetGroups.length < 2) {
            return _OwnerFleetPage(
              items: query.items,
              isRefreshing: query.isRefreshing,
              onRefresh: loadData,
            );
          }

          final selectedIndex = fleetGroups.indexOf(selectedGroup);
          return AppTabs(
            initialIndex: selectedIndex < 0 ? 0 : selectedIndex,
            titles: [
              for (final group in fleetGroups) _fleetTabTitle(l10n, group),
            ],
            onChanged: (index) {
              ref
                  .read(ownerFleetCatalogGroupProvider.notifier)
                  .select(fleetGroups[index]);
            },
            children: [
              for (final group in fleetGroups)
                _OwnerFleetPage(
                  key: ValueKey(group),
                  items: query.items
                      .where((item) => item.category?.catalogGroup == group)
                      .toList(),
                  isRefreshing: query.isRefreshing,
                  onRefresh: loadData,
                ),
            ],
          );
        },
      ),
    );
  }
}

String _fleetTabTitle(AppLocalizations l10n, CatalogGroup group) {
  return switch (group) {
    CatalogGroup.machinery => l10n.ownerFleetMachineryTab,
    CatalogGroup.equipment => l10n.ownerFleetEquipmentTab,
  };
}

class _OwnerFleetPage extends StatelessWidget {
  const _OwnerFleetPage({
    super.key,
    required this.items,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final List<Equipment> items;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
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
                  onTap: () => context.push(AppRoutes.ownerEquipmentCreate),
                ),
              ),
            )
          else ...[
            if (isRefreshing) const LinearProgressIndicator(minHeight: 2),
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
      ),
    );
  }
}
