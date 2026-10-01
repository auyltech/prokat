import 'company_billing_panel.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/profile_accent_cta.dart';
import 'package:prokat/core/widgets/prokat_list_tile.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/auth/widgets/logout_button.dart';
import 'package:prokat/features/notifications/widgets/notification_badge.dart';
import 'package:prokat/features/user/state/client_profile_provider.dart';
import 'package:prokat/features/user/widgets/client_profile_header.dart';
import 'package:prokat/features/user/widgets/client_rental_preferences_section.dart';
import 'package:prokat/l10n/app_localizations.dart';

import 'company_models.dart';
import 'company_service.dart';

class CompanyProfileScreen extends ConsumerWidget {
  final CompanyMembership membership;
  final VoidCallback onInvite;
  const CompanyProfileScreen({
    super.key,
    required this.membership,
    required this.onInvite,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final user = ref.watch(clientProfileProvider).valueOrNull;
    Widget tile(
      IconData icon,
      String title,
      String subtitle,
      VoidCallback action,
    ) => ProkatListTile(
      icon: icon,
      iconColor: icon == LucideIcons.headset
          ? Colors.red
          : theme.colorScheme.primary,
      iconBgColor:
          (icon == LucideIcons.headset ? Colors.red : theme.colorScheme.primary)
              .withValues(alpha: .15),
      title: title,
      subtitle: subtitle,
      onTap: action,
    );
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(companyContextProvider);
          ref.invalidate(companyBillingProvider(membership.organization.id));
          await ref.read(clientProfileProvider.notifier).refresh();
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 320,
              automaticallyImplyLeading: false,
              elevation: 0,
              backgroundColor: const Color(0xFF472035),
              actions: const [
                NotificationBadge(color: Colors.white),
                SizedBox(width: 16),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: EdgeInsets.zero,
                background: ClientProfileHeader(
                  userProfile: user,
                  gradientColors: const [Color(0xFF472035), Color(0xFF762E47)],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      membership.organization.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: .12,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          membership.canManageProfile
                              ? l.companyManager
                              : l.companyDispatcher,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    if (user?.phoneNumber != null) ...[
                      const SizedBox(height: 8),
                      Text(user!.phoneNumber!),
                    ],
                    const SizedBox(height: 24),
                    CompanyBillingPanel(companyId: membership.organization.id),
                    const SizedBox(height: 24),
                    const ClientRentalPreferencesSection(),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: ProfileAccentCta(
                  backgroundColor: const Color(0xFF472035),
                  leading: const Icon(
                    LucideIcons.logOut,
                    color: Colors.white,
                    size: 40,
                  ),
                  title: l.companyExitCabinet,
                  subtitle: l.companyExitCabinetSubtitle,
                  onTap: () async {
                    await ref.read(appStartupProvider.notifier).setClientMode();
                    if (context.mounted) context.go(AppRoutes.clientProfile);
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    if (membership.canManageProfile) ...[
                      tile(
                        LucideIcons.userPlus,
                        l.companyInviteDispatcher,
                        l.companyInviteDispatcherSubtitle,
                        onInvite,
                      ),
                      const SizedBox(height: 20),
                    ],
                    tile(
                      LucideIcons.heart,
                      l.supportUsTitle,
                      l.donateOrHelp,
                      () => context.push(
                        '/company-cabinet/${membership.organization.id}/profile/support',
                      ),
                    ),
                    const SizedBox(height: 20),
                    tile(
                      LucideIcons.fileText,
                      l.legalDocuments,
                      l.legalDocumentsSubtitle,
                      () => context.push(
                        '/company-cabinet/${membership.organization.id}/profile/documents',
                      ),
                    ),
                    const SizedBox(height: 20),
                    tile(
                      LucideIcons.settings,
                      l.appSettings,
                      l.appSettingsSubtitle,
                      () => context.push(
                        '/company-cabinet/${membership.organization.id}/profile/settings',
                      ),
                    ),
                    const SizedBox(height: 20),
                    tile(
                      LucideIcons.headset,
                      l.helpSupportTitle,
                      l.helpSupportSubtitle,
                      () => context.push(
                        '/company-cabinet/${membership.organization.id}/profile/help',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 40, 16, 60),
                child: LogoutButton(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
