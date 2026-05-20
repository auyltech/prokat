import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/constants/app_colors.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(
      () => ref.read(equipmentProvider.notifier).getOwnerEquipment(),
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
    final state = ref.watch(equipmentProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: theme.colorScheme.onPrimary,
          ),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.push(AppRoutes.ownerDashboard),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.ownerEquimentCreate),
            icon: Icon(Icons.add, color: theme.colorScheme.onPrimary, size: 24),
            tooltip: l10n.addEquipment,
          ),
        ],
        title: Text(
          l10n.myEquipment,
          style: TextStyle(color: theme.colorScheme.onPrimary),
        ),
        backgroundColor: AppColors.teal700,
        elevation: 0,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusItem(
                        context,
                        label: l10n.online,
                        count: state.ownerEquipment
                            .where(
                              (e) =>
                                  e.status.toLowerCase() == 'available' &&
                                  e.isVisible == true,
                            )
                            .length,
                        color: Colors.greenAccent[700]!,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _buildStatusItem(
                        context,
                        label: l10n.offline,
                        count: state.ownerEquipment
                            .where(
                              (e) =>
                                  e.status.toLowerCase() == 'booked' ||
                                  e.isVisible == false,
                            )
                            .length,
                        color: Colors.redAccent[400]!,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _buildStatusItem(
                        context,
                        label: l10n.repair,
                        count: state.ownerEquipment
                            .where(
                              (e) => e.status.toLowerCase() == 'maintenance',
                            )
                            .length,
                        color: Colors.orangeAccent[700]!,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                if (state.isLoading)
                  _builSkeleton(context)
                else if (state.ownerEquipment.isEmpty)
                  EmptyStateTile(
                    title: l10n.noEquipmentListed,
                    icon: Icons.inventory_2_outlined,
                  )
                else
                  ListView.separated(
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemCount: state.ownerEquipment.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) => OwnerEquipmentCard(
                      equipment: state.ownerEquipment[index],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _builSkeleton(BuildContext context) {
    return ListView.builder(
      itemCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade50,
        child: Container(
          height: 140,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem(
    BuildContext context, {
    required String label,
    required int count,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // The Large Count
          Text(
            count.toString().padLeft(2, '0'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          // The Label
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
