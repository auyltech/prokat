import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/constants/app_colors.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/prokat_list_tile.dart';
import 'package:prokat/features/auth/widgets/logout_button.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/billing/state/billing_provider.dart';
import 'package:prokat/features/bookings/providers/owner_active_bookings_provider.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_provider.dart';
import 'package:prokat/features/notifications/widgets/notification_badge.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
import 'package:prokat/features/owner/widgets/balance_tile.dart';
import 'package:prokat/features/owner/widgets/owner_business_preferences.dart';
import 'package:prokat/features/owner/widgets/owner_profile_header.dart';
import 'package:prokat/features/owner/widgets/rent_an_equipment_tile.dart';
import 'package:prokat/features/user/widgets/owner_stat_card.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';

class OwnerProfileScreen extends ConsumerStatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  ConsumerState<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends ConsumerState<OwnerProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await Future.wait([
        ref.read(ownerProfileProvider.notifier).refreshIfStale(),
        ref.read(ownerRegistrationRequestProvider.notifier).refreshIfStale(),
        ref.read(ownerEquipmentProvider.notifier).refreshIfStale(),
        ref.read(ownerActiveBookingsProvider.notifier).refreshIfStale(),
      ]);
      if (!mounted) return;

      if (ref.read(billingProvider).accountBalance == null) {
        ref.read(billingProvider.notifier).getOwnerBalance();
      }

      ref.read(billingProvider.notifier).getVolumeDiscounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final ownerProfile = ref.watch(ownerProfileProvider).valueOrNull;
    final ownerEquipmentCount =
        ref.watch(ownerEquipmentProvider).value?.items.length ?? 0;

    final activeOrders =
        ref.watch(ownerActiveBookingsProvider).value?.count ?? 0;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(ownerProfileProvider.notifier).refresh(),
            ref.read(ownerRegistrationRequestProvider.notifier).refresh(),
            ref.read(ownerEquipmentProvider.notifier).refresh(),
            ref.read(ownerActiveBookingsProvider.notifier).refresh(),
          ]);
          ref.read(billingProvider.notifier).getOwnerBalance();
          ref.read(billingProvider.notifier).getVolumeDiscounts();
        },
        child: CustomScrollView(
          slivers: [
            // Owner Profile
            SliverAppBar(
              expandedHeight: 400,
              pinned: false,
              elevation: 0,
              backgroundColor: const Color.fromARGB(255, 240, 240, 240),
              automaticallyImplyLeading: false,
              actions: [
                NotificationBadge(color: Colors.white),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: OwnerProfileHeader(ownerProfile: ownerProfile),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 40),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OwnerStatCard(
                            value: ownerEquipmentCount
                                .toString(), // wire up from billingProvider
                            label: l10n.navEquipment,
                            valueColor: theme.colorScheme.primary,
                            icon: LucideIcons.truck,
                          ),
                        ),

                        const SizedBox(width: 10),
                        Expanded(
                          child: OwnerStatCard(
                            value: activeOrders.toString(),
                            label: l10n.ordersUnit,
                            valueColor: theme.colorScheme.primary,
                            icon: LucideIcons.package,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    const BalanceTile(),

                    const SizedBox(height: 20),

                    const OwnerBusinessPreferencesSection(),

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
                      icon: LucideIcons.lifeBuoy,
                      iconColor: Colors.red,
                      iconBgColor: Colors.red.withValues(alpha: 0.15),
                      title: l10n.helpSupportTitle,
                      subtitle: l10n.helpFaqsSubtitle,
                      onTap: () => context.push(AppRoutes.helpSupport),
                    ),

                    const SizedBox(height: 22),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(child: const RentAnEquipmentTile()),

            SliverFillRemaining(
              hasScrollBody: false, // Prevents nested inner scrollbars
              fillOverscroll: true,
              child: Padding(
                padding: EdgeInsets.only(
                  top: 40,
                  bottom: 60,
                  left: 16,
                  right: 16,
                ),
                child: const LogoutButton(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
