import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/constants/app_colors.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/auth/widgets/logout_button.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/billing/state/billing_provider.dart';
import 'package:prokat/features/equipment/state/equipment_provider.dart';
import 'package:prokat/features/notifications/widgets/notification_badge.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
import 'package:prokat/features/owner/state/owner_registration_state.dart';
import 'package:prokat/features/user/widgets/balance_tile.dart';
import 'package:prokat/features/user/widgets/rent_an_equipment_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:prokat/features/user/widgets/display_name.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prokat/features/user/widgets/profile_image_picker.dart';

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
      if (ref.read(ownerRegistrationProvider).ownerProfile == null) {
        ref.read(ownerRegistrationProvider.notifier).getOwnerProfile();
      }

      if (ref.read(ownerRegistrationProvider).registrationRequest == null) {
        ref.read(ownerRegistrationProvider.notifier).getRegistrationRequest();
      }

      if (ref.read(billingProvider).accountBalance == null) {
        ref.read(billingProvider.notifier).getOwnerBalance();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final ownerProfileState = ref.watch(ownerRegistrationProvider);
    final ownerEquipmentCount = ref
        .watch(equipmentProvider)
        .ownerEquipment
        .length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color.fromARGB(255, 240, 240, 240),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(ownerRegistrationProvider.notifier).getOwnerProfile();
          ref.read(billingProvider.notifier).getOwnerBalance();
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              elevation: 0,
              floating: true,
              backgroundColor:
                  AppColors.teal800, // Keeps teal background fixed at the top
              iconTheme: const IconThemeData(color: Colors.white),
              centerTitle: false,
              title: Text(
                'Owner Profile',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(icon: const NotificationBadge(), onPressed: () {}),
                const SizedBox(width: 8),
              ],
            ),

            SliverAppBar(
              expandedHeight: 200,
              pinned: false,
              elevation: 0,
              // Match the overall scaffold background so the corners look seamlessly cut out
              backgroundColor: const Color.fromARGB(255, 240, 240, 240),
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: _ProfileHeader(
                  ownerProfileState: ownerProfileState,
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            value: ownerEquipmentCount
                                .toString(), // wire up from billingProvider
                            label: "Equipment",
                            valueColor: theme.colorScheme.primary,
                            icon: LucideIcons.truck,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            value:
                                "${ownerProfileState.ownerProfile?.orderCount ?? 0}",
                            label: "Orders",
                            valueColor: const Color(0xFF185FA5),
                            icon: LucideIcons.package,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    const BalanceTile(),
                    const SizedBox(height: 14),

                    _MenuSection(l10n: l10n),
                    const SizedBox(height: 14),

                    const RentAnEquipmentTile(),
                  ],
                ),
              ),
            ),

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

            // const SliverToBoxAdapter(
            //   child: SafeArea(top: false, child: SizedBox(height: 130)),
            // ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final OwnerRegistrationState ownerProfileState;
  const _ProfileHeader({required this.ownerProfileState});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.teal800,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      // Keep status bar area tinted correctly
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Avatar ──
          ProfileImagePicker(
            initialImageUrl:
                ownerProfileState.ownerProfile?.profileImageUrl ?? "",
          ),

          const SizedBox(height: 10),

          // ── Name ──
          const DisplayName(),

          // ── Rating + orders row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star_rate_rounded,
                size: 25,
                color: Color(0xFFF5C842),
              ),
              const SizedBox(width: 4),
              Text(
                (ownerProfileState.ownerProfile?.ratingAverage ?? 0)
                    .toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              // const SizedBox(width: 12),
              // Text(
              //   "${ownerProfileState.ownerProfile?.ratingCount ?? 0} ratings",
              //   style: TextStyle(
              //     color: Colors.white.withValues(alpha: 0.75),
              //     fontSize: 14,
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;
  final IconData icon;

  const _StatCard({
    required this.value,
    required this.label,
    required this.valueColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 32,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),

          const SizedBox(width: 8),

          Spacer(),

          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: valueColor,
              fontSize: 30,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Menu items ──

class _MenuSection extends StatelessWidget {
  final AppLocalizations l10n;
  const _MenuSection({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MenuItem(
          iconData: Icons.assignment_turned_in_outlined,
          iconBgColor: const Color(0xFFE1F5EE),
          iconColor: const Color(0xFF0D5F5C),
          label: l10n.registrationStatus,
          subtitle: "Fully verified · Expires 2025",
          onTap: () => context.push(AppRoutes.ownerRegistration),
        ),
        const SizedBox(height: 10),
        _MenuItem(
          iconData: Icons.settings_outlined,
          iconBgColor: const Color(0xFFE6F1FB),
          iconColor: const Color(0xFF185FA5),
          label: l10n.appSettings,
          subtitle: l10n.appSettingsSubtitle,
          onTap: () => context.push(AppRoutes.ownerSettings),
        ),
        const SizedBox(height: 10),
        _MenuItem(
          iconData: Icons.help_outline,
          iconBgColor: const Color(0xFFF1EFE8),
          iconColor: const Color(0xFF5F5E5A),
          label: l10n.helpSupportTitle,
          subtitle: l10n.helpFaqsSubtitle,
          onTap: () => context.push(AppRoutes.helpSupport),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData iconData;
  final Color iconBgColor;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.iconData,
    required this.iconBgColor,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
