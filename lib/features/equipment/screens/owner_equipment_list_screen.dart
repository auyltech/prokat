import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/constants/app_colors.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/equipment/state/equipment_provider.dart';
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
    await ref.read(equipmentProvider.notifier).getOwnerEquipment();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    Future.microtask(() {
      if (ref.read(equipmentProvider).ownerEquipment.isEmpty) {
        loadData();
      }
    });
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
      body: RefreshIndicator(
        onRefresh: () => loadData(),
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (state.isLoading && state.ownerEquipment.isEmpty)
                    _builSkeleton(context)
                  else if (state.ownerEquipment.isEmpty)
                    EmptyStateTile(
                      title: l10n.noEquipmentListed,
                      icon: Icons.inventory_2_outlined,
                    )
                  else
                    ListView.separated(
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        thickness: 1,
                        indent: 16,
                        endIndent: 16,
                        color: AppColors.teal700,
                      ),
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
}
