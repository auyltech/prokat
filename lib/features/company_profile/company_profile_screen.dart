import 'dart:async';

import 'company_scope.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/profile_accent_cta.dart';
import 'package:prokat/core/widgets/prokat_list_tile.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/auth/widgets/logout_button.dart';
import 'package:prokat/features/billing/models/account_balance_model.dart';
import 'package:prokat/features/billing/state/billing_state.dart';
import 'package:prokat/features/notifications/widgets/notification_badge.dart';
import 'package:prokat/features/owner/models/owner_profile_model.dart';
import 'package:prokat/features/owner/models/owner_status.dart';
import 'package:prokat/features/owner/widgets/balance_tile.dart';
import 'package:prokat/features/owner/widgets/owner_profile_header.dart';
import 'package:prokat/features/user/state/client_profile_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

import 'company_profile_api.dart';
import 'company_member_screen.dart';
import 'company_online_card.dart';

class CompanyProfileScreen extends ConsumerWidget {
  final String companyId, companyName;
  const CompanyProfileScreen({
    super.key,
    required this.companyId,
    required this.companyName,
  });
  static const accent = Color(0xff702d45);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final members = ref.watch(companyMembersProvider(companyId));
    return members.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Профиль компании')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(companyProfileError(error)),
              const SizedBox(height: 20),
              AppElevatedButton(
                title: 'Повторить',
                onTap: () => ref.invalidate(companyMembersProvider(companyId)),
              ),
            ],
          ),
        ),
      ),
      data: (data) {
        final self = data['self'] as Map<String, dynamic>;
        final personal = ref.watch(clientProfileProvider).valueOrNull;
        final profile = OwnerProfileModel(
          id: companyId,
          firstName: self['firstName'],
          lastName: self['lastName'],
          profileImageUrl: personal?.profileImageUrl,
          onlineStatus: OwnerStatus.offline,
        );
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(companyMembersProvider(companyId));
              ref.invalidate(companyBalanceProvider(companyId));
              await Future.wait([
                ref.read(companyMembersProvider(companyId).future),
                ref.read(companyBalanceProvider(companyId).future),
              ]);
            },
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 320,
                  automaticallyImplyLeading: false,
                  actions: const [
                    NotificationBadge(color: Colors.white),
                    SizedBox(width: 8),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: OwnerProfileHeader(
                      ownerProfile: profile,
                      gradientColors: const [Color(0xff482133), accent],
                      avatarMode: AppMode.clientMode,
                      showRating: false,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          companyName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 20),
                        ref
                            .watch(companyBalanceProvider(companyId))
                            .when(
                              loading: () => const AppCard(
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              error: (error, stack) => AppCard(
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text('Баланс недоступен'),
                                    ),
                                    IconButton(
                                      onPressed: () => ref.invalidate(
                                        companyBalanceProvider(companyId),
                                      ),
                                      icon: const Icon(LucideIcons.refreshCw),
                                    ),
                                  ],
                                ),
                              ),
                              data: (balance) => BalanceSummaryCard(
                                title: 'Баланс компании',
                                billingState: BillingState(
                                  accountBalance: AccountBalanceModel.fromJson(
                                    balance,
                                  ),
                                ),
                                ownerOnline:
                                    balance['onlineStatus'] == 'ONLINE',
                                onlineEquipment: balance['categoryCount'] ?? 0,
                                onTopUp: () => AppToast.show(
                                  message: l10n.paymentFeatureComingSoon,
                                ),
                              ),
                            ),
                        const SizedBox(height: 20),
                        CompanyOnlineCard(companyId: companyId),
                        const SizedBox(height: 40),
                        ProkatListTile(
                          icon: LucideIcons.briefcase,
                          iconColor: accent,
                          iconBgColor: accent.withValues(alpha: .15),
                          title: 'Ваш профиль',
                          subtitle: self['role'] == 'OWNER'
                              ? 'Руководитель'
                              : 'Диспетчер',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CompanyMemberScreen(
                                companyId: companyId,
                                companyName: companyName,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: ProfileAccentCta(
                    title: 'Выйти из кабинета компании',
                    subtitle: 'Вернуться в профиль клиента',
                    leading: ProfileAccentCta.truckSearch(badgeColor: accent),
                    backgroundColor: accent,
                    onTap: () async {
                      await ref
                          .read(appStartupProvider.notifier)
                          .setClientMode();
                      if (context.mounted) {
                        final exit = ref.read(exitCompanyProvider);
                        if (exit != null) {
                          exit();
                        } else {
                          context.go(AppRoutes.clientProfile);
                        }
                      }
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 40, 16, 40),
                    child: Column(
                      children: [
                        ProkatListTile(
                          icon: LucideIcons.fileText,
                          iconColor: accent,
                          iconBgColor: accent.withValues(alpha: .15),
                          title: l10n.legalDocuments,
                          subtitle: l10n.legalDocumentsSubtitle,
                          onTap: () {
                            final root = ref.read(
                              companyRootNavigationProvider,
                            );
                            if (root != null) {
                              root(AppRoutes.clientDocuments);
                            } else {
                              unawaited(
                                context.push(AppRoutes.clientDocuments),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        ProkatListTile(
                          icon: LucideIcons.settings,
                          iconColor: accent,
                          iconBgColor: accent.withValues(alpha: .15),
                          title: l10n.appSettings,
                          subtitle: l10n.appSettingsSubtitle,
                          onTap: () {
                            final root = ref.read(
                              companyRootNavigationProvider,
                            );
                            if (root != null) {
                              root(AppRoutes.clientSettings);
                            } else {
                              unawaited(context.push(AppRoutes.clientSettings));
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        ProkatListTile(
                          icon: LucideIcons.headset,
                          iconColor: Colors.red,
                          iconBgColor: Colors.red.withValues(alpha: .15),
                          title: l10n.helpSupportTitle,
                          subtitle: l10n.helpSupportSubtitle,
                          onTap: () => context.push(AppRoutes.helpSupport),
                        ),
                        const SizedBox(height: 40),
                        const LogoutButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
