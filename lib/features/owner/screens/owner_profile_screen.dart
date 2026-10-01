import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/constants/app_colors.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/prokat_list_tile.dart';
import 'package:prokat/features/auth/widgets/logout_button.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/billing/state/billing_provider.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/features/bookings/providers/owner_active_bookings_provider.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_provider.dart';
import 'package:prokat/features/notifications/widgets/notification_badge.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
import 'package:prokat/features/owner/widgets/balance_tile.dart';
import 'package:prokat/features/owner/widgets/owner_business_preferences.dart';
import 'package:prokat/features/owner/widgets/owner_profile_header.dart';
import 'package:prokat/features/owner/widgets/rent_an_equipment_tile.dart';
import 'package:prokat/features/user/widgets/owner_stat_card.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class OwnerProfileScreen extends ConsumerStatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  ConsumerState<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends ConsumerState<OwnerProfileScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(
      Future.microtask(() async {
        await Future.wait([
          ref.read(ownerProfileProvider.notifier).refreshIfStale(),
          ref.read(ownerRegistrationRequestProvider.notifier).refreshIfStale(),
          ref.read(ownerEquipmentProvider.notifier).refreshIfStale(),
          ref.read(ownerActiveBookingsProvider.notifier).refreshIfStale(),
        ]);
        if (!mounted) return;

        if (ref.read(billingProvider).accountBalance == null) {
          await ref.read(billingProvider.notifier).getOwnerBalance();
          if (!mounted) return;
        }

        await ref.read(billingProvider.notifier).getVolumeDiscounts();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final ownerProfile = ref.watch(ownerProfileProvider).valueOrNull;
    final equipmentItems =
        ref.watch(ownerEquipmentProvider).valueOrNull?.items ?? const [];
    final activeOrders =
        ref.watch(ownerActiveBookingsProvider).valueOrNull?.count ?? 0;
    final completedOrders = ownerProfile?.orderCount ?? 0;

    final itemsByGroup = {
      for (final group in CatalogGroup.values)
        group: equipmentItems.where((item) => _groupOf(item) == group).toList(),
    };
    final fleetGroups = [
      for (final group in CatalogGroup.values)
        if (itemsByGroup[group]!.isNotEmpty) group,
    ];
    final fleetCards = [
      for (final group
          in fleetGroups.isEmpty ? const [CatalogGroup.machinery] : fleetGroups)
        _fleetCard(context, l10n, group, itemsByGroup[group]!),
    ];
    final ordersCard = OwnerStatCard(
      icon: LucideIcons.scrollText,
      title: l10n.navOrders,
      firstLabel: l10n.statActive,
      firstValue: activeOrders.toString(),
      secondLabel: l10n.statCompleted,
      secondValue: completedOrders.toString(),
      onTap: () => context.go(AppRoutes.ownerBookings),
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(ownerProfileProvider.notifier).refresh(),
            ref.read(ownerRegistrationRequestProvider.notifier).refresh(),
            ref.read(ownerEquipmentProvider.notifier).refresh(),
            ref.read(ownerActiveBookingsProvider.notifier).refresh(),
            ref.read(billingProvider.notifier).getOwnerBalance(),
            ref.read(billingProvider.notifier).getVolumeDiscounts(),
          ]);
        },
        child: CustomScrollView(
          slivers: [
            // Owner Profile
            SliverAppBar(
              expandedHeight: 320,
              pinned: false,
              elevation: 0,
              backgroundColor: const Color.fromARGB(255, 240, 240, 240),
              automaticallyImplyLeading: false,
              actions: const [
                NotificationBadge(color: Colors.white),
                SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: OwnerProfileHeader(ownerProfile: ownerProfile),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                child: Column(
                  children: [
                    if (fleetCards.length == 1)
                      _StatRow(cards: [fleetCards.single, ordersCard])
                    else ...[
                      _StatRow(cards: fleetCards),
                      const SizedBox(height: AppDimens.statCardGap),
                      ordersCard,
                    ],

                    const SizedBox(height: 20),

                    const BalanceTile(),

                    const SizedBox(height: 20),

                    const OwnerBusinessPreferencesSection(),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: RentAnEquipmentTile()),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 40),
                child: Column(
                  children: [
                    // TODO(Vadim): hided
                    // ProkatListTile(
                    //   icon: LucideIcons.heart,
                    //   iconBgColor: AppColors.teal800.withValues(alpha: 0.15),
                    //   iconColor: AppColors.teal800,
                    //   title: l10n.supportUsTitle,
                    //   subtitle: l10n.donateOrHelp,
                    //   onTap: () => context.push(AppRoutes.supportUs),
                    // ),
                    // const SizedBox(height: 20),

                    ProkatListTile(
                      icon: LucideIcons.fileText,
                      iconBgColor: AppColors.teal800.withValues(alpha: 0.15),
                      iconColor: AppColors.teal800,
                      title: l10n.legalDocuments,
                      subtitle: l10n.legalDocumentsSubtitle,
                      onTap: () => context.push(AppRoutes.ownerDocuments),
                    ),
                    const SizedBox(height: 20),

                    ProkatListTile(
                      icon: LucideIcons.settings,
                      iconBgColor: AppColors.teal800.withValues(alpha: 0.15),
                      iconColor: AppColors.teal800,
                      title: l10n.appSettings,
                      subtitle: l10n.appSettingsSubtitle,
                      onTap: () => context.push(AppRoutes.ownerSettings),
                    ),
                    const SizedBox(height: 20),

                    ProkatListTile(
                      icon: LucideIcons.headset,
                      iconColor: Colors.red,
                      iconBgColor: Colors.red.withValues(alpha: 0.15),
                      title: l10n.helpSupportTitle,
                      subtitle: l10n.helpSupportSubtitle,
                      onTap: () => context.push(AppRoutes.helpSupport),
                    ),
                  ],
                ),
              ),
            ),

            const SliverFillRemaining(
              hasScrollBody: false, // Prevents nested inner scrollbars
              fillOverscroll: true,
              child: Padding(
                padding: EdgeInsets.only(
                  top: 40,
                  bottom: 60,
                  left: 16,
                  right: 16,
                ),
                child: LogoutButton(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fleetCard(
    BuildContext context,
    AppLocalizations l10n,
    CatalogGroup group,
    List<Equipment> items,
  ) {
    return OwnerStatCard(
      icon: switch (group) {
        CatalogGroup.machinery => LucideIcons.truck,
        CatalogGroup.equipment => LucideIcons.package,
      },
      title: switch (group) {
        CatalogGroup.machinery => l10n.catalogGroupMachinery,
        CatalogGroup.equipment => l10n.catalogGroupEquipment,
      },
      firstLabel: l10n.statTotal,
      firstValue: items.length.toString(),
      secondLabel: l10n.statOnline,
      secondValue: items.where((item) => item.isVisible).length.toString(),
      onTap: () {
        ref.read(ownerFleetCatalogGroupProvider.notifier).select(group);
        context.go(AppRoutes.ownerEquipment);
      },
    );
  }
}

CatalogGroup _groupOf(Equipment item) =>
    item.category?.catalogGroup ?? CatalogGroup.machinery;

class _StatRow extends StatelessWidget {
  const _StatRow({required this.cards});

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppDimens.statCardGap,
        children: [for (final card in cards) Expanded(child: card)],
      ),
    );
  }
}
