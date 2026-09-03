import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/prokat_list_tile.dart';
import 'package:prokat/features/auth/widgets/logout_button.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/notifications/widgets/notification_badge.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
import 'package:prokat/features/user/state/client_profile_provider.dart';
import 'package:prokat/features/user/widgets/become_owner_cta.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/user/widgets/client_profile_header.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/features/user/widgets/client_rental_preferences_section.dart';

class ClientProfileScreen extends ConsumerStatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  ConsumerState<ClientProfileScreen> createState() =>
      _ClientProfileScreenState();
}

class _ClientProfileScreenState extends ConsumerState<ClientProfileScreen> {
  @override
  void initState() {
    super.initState();

    unawaited(
      Future.microtask(() async {
        await ref.read(clientProfileProvider.notifier).refreshIfStale();

        await ref
            .read(ownerRegistrationRequestProvider.notifier)
            .refreshIfStale();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final userProfileAsync = ref.watch(clientProfileProvider);
    final userProfile = userProfileAsync.valueOrNull;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(clientProfileProvider.notifier).refresh(),
            ref.read(ownerRegistrationRequestProvider.notifier).refresh(),
            ref.read(categoriesProvider.notifier).refresh(),
          ]);
        },
        child: CustomScrollView(
          slivers: [
            // User Profile
            SliverAppBar(
              backgroundColor: theme.colorScheme.primary,
              expandedHeight: 400,
              actions: const [
                NotificationBadge(color: Colors.white),
                SizedBox(width: 16),
              ],
              // Removes default constraints and back button spacing padding from the title area
              primary: true,
              flexibleSpace: FlexibleSpaceBar(
                // 1. Reset titlePadding so the background layout fills the entire width
                titlePadding: EdgeInsets.zero,
                // 2. Move your full-width UI block into the background property
                background: ClientProfileHeader(userProfile: userProfile),
              ),
            ),

            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    SizedBox(height: 40),
                    ClientRentalPreferencesSection(),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: BecomeOwnerCTA(),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // TODO(Vadim): Пока слишком сырое
                    // ProkatListTile(
                    //   icon: Icons.favorite_outline,
                    //   iconColor: theme.colorScheme.onPrimary,
                    //   iconBgColor: theme.colorScheme.primary.withValues(
                    //     alpha: 0.2,
                    //   ),
                    //   title: l10n.supportUsTitle,
                    //   subtitle: l10n.donateOrHelp,
                    //   onTap: () => context.push(AppRoutes.supportUs),
                    // ),
                    // const SizedBox(height: 20),

                    ProkatListTile(
                      icon: LucideIcons.scrollText,
                      iconColor: theme.colorScheme.onPrimary,
                      iconBgColor: theme.colorScheme.primary.withValues(
                        alpha: 0.2,
                      ),
                      title: l10n.legalDocuments,
                      subtitle: l10n.legalDocumentsSubtitle,
                      onTap: () => context.push(AppRoutes.clientDocuments),
                    ),

                    const SizedBox(height: 20),

                    ProkatListTile(
                      icon: LucideIcons.settings,
                      iconColor: theme.colorScheme.onPrimary,
                      iconBgColor: theme.colorScheme.primary.withValues(
                        alpha: 0.2,
                      ),
                      title: l10n.appSettings,
                      subtitle: l10n.appSettingsSubtitle,
                      onTap: () => context.push(AppRoutes.clientSettings),
                    ),

                    const SizedBox(height: 20),

                    ProkatListTile(
                      icon: LucideIcons.lifeBuoy,
                      iconColor: Colors.red,
                      iconBgColor: Colors.red.withValues(alpha: 0.15),
                      title: l10n.helpSupportTitle,
                      subtitle: l10n.helpSupportSubtitle,
                      onTap: () => context.push(AppRoutes.helpSupport),
                    ),

                    const SizedBox(height: 40),
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
}
