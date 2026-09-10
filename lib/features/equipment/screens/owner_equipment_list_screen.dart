import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/constants/app_colors.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_provider.dart';
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
    await ref.read(ownerEquipmentProvider.notifier).refresh();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    unawaited(
      Future.microtask(() {
        unawaited(ref.read(ownerEquipmentProvider.notifier).refreshIfStale());
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
              EmptyStateTile(
                imageName: 'empty_error.png',
                title: l10n.errorLoadingEquipment,
                subtitle: error.toString(),
              ),
            ],
          ),

          data: (query) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (query.items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: EmptyStateTile(
                      title: l10n.noEquipmentListed,
                      imageName: 'empty_equipment.png',
                      imageHeight: 168,
                      imageFit: BoxFit.contain,
                      actionButton: PrimaryButton(
                        label: l10n.add,
                        onPressed: () =>
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
                      color: AppColors.teal700,
                    ),
                    itemCount: query.items.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) =>
                        OwnerEquipmentCard(equipment: query.items[index]),
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
