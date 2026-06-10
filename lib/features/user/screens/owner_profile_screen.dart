import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/constants/app_colors.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/auth/widgets/logout_button.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/billing/state/billing_provider.dart';
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
      ref.read(ownerRegistrationProvider.notifier).getOwnerProfile();
      ref.read(ownerRegistrationProvider.notifier).getRegistrationRequest();
      ref.read(billingProvider.notifier).getOwnerBalance();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ownerProfileState = ref.watch(ownerRegistrationProvider);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 240, 240, 240),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(ownerRegistrationProvider.notifier).getOwnerProfile();
          ref.read(billingProvider.notifier).getOwnerBalance();
        },
        child: CustomScrollView(
          slivers: [
            // ── 1. Collapsible Header ──
            SliverAppBar(
              expandedHeight: 190,
              pinned: true,
              elevation: 0,
              backgroundColor: AppColors.teal800,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                collapseMode: CollapseMode.parallax,
                title: const DisplayName(),
                titlePadding: const EdgeInsets.only(bottom: 16),
                background: ProfileImagePicker(
                  initialImageUrl:
                      ownerProfileState.ownerProfile?.profileImageUrl ?? "",
                ),
              ),
              // bottom: PreferredSize(
              //   preferredSize: const Size.fromHeight(20.0),
              //   child: Padding(
              //     padding: const EdgeInsets.symmetric(
              //       vertical: 12,
              //       horizontal: 16,
              //     ),
              //     child: ,
              //   ),
              // ),
            ),

            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                child: Column(
                  children: [
                    _StatsRow(ownerProfileState: ownerProfileState),
                    const SizedBox(height: 10),

                    const BalanceTile(),
                    const SizedBox(height: 14),

                    _MenuSection(l10n: l10n),
                    const SizedBox(height: 14),

                    const RentAnEquipmentTile(),
                    const SizedBox(height: 10),

                    const LogoutButton(),

                    SizedBox(height: 130),
                  ],
                ),
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.teal800,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      // Keep status bar area tinted correctly
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Avatar ──
            ProfileImagePicker(
              initialImageUrl:
                  ownerProfileState.ownerProfile?.profileImageUrl ?? "",
            ),

            // const SizedBox(height: 10),

            // ── Name ──
            // const DisplayName(),
            // const SizedBox(height: 6),

            // ── Rating + orders row ──
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   children: [
            //     const Icon(
            //       LucideIcons.star,
            //       size: 14,
            //       color: Color(0xFFF5C842),
            //     ),
            //     const SizedBox(width: 4),
            //     Text(
            //       (ownerProfileState.ownerProfile?.ratingAverage ?? 0)
            //           .toStringAsFixed(1),
            //       style: const TextStyle(
            //         color: Colors.white,
            //         fontWeight: FontWeight.w500,
            //         fontSize: 14,
            //       ),
            //     ),
            //     const SizedBox(width: 12),
            //     Text(
            //       "${ownerProfileState.ownerProfile?.ratingCount ?? 0} ratings",
            //       style: TextStyle(
            //         color: Colors.white.withValues(alpha: 0.75),
            //         fontSize: 14,
            //       ),
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final OwnerRegistrationState ownerProfileState;
  const _StatsRow({required this.ownerProfileState});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: "66,240", // wire up from billingProvider
            label: "Minutes balance",
            valueColor: theme.colorScheme.primary,
            icon: LucideIcons.clock,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: "${ownerProfileState.ownerProfile?.orderCount ?? 0}",
            label: "Total orders",
            valueColor: const Color(0xFF185FA5),
            icon: LucideIcons.package,
          ),
        ),
      ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(
                icon,
                size: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
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
