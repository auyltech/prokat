import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/providers/locale_provider.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/appstatic/widgets/language_sheet.dart';
import 'package:prokat/features/auth/widgets/logout_button.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
import 'package:prokat/features/user/state/user_profile_provider.dart';
import 'package:prokat/features/user/widgets/become_owner_cta.dart';
import 'package:prokat/features/user/widgets/profile_image_picker.dart';
import 'package:prokat/features/user/widgets/user_profile_tile.dart';
import 'package:prokat/features/user/widgets/display_name.dart';
import 'package:prokat/features/user/widgets/setting_link_tile.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';

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

    Future.microtask(() async {
      await ref.read(userProfileProvider.notifier).getUserProfile();
      await ref
          .read(ownerRegistrationProvider.notifier)
          .getRegistrationRequest();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final userProfileState = ref.watch(userProfileProvider);

    final locale = ref.watch(localeProvider);
    final langDisplay = LocaleNotifier.displayCode(locale);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(userProfileProvider.notifier).getUserProfile();
            await ref
                .read(ownerRegistrationProvider.notifier)
                .getRegistrationRequest();
          },
          child: CustomScrollView(
            slivers: [
              // User Profile
              SliverAppBar(
                backgroundColor: const Color.fromARGB(255, 240, 240, 240),
                expandedHeight: 400,
                // Removes default constraints and back button spacing padding from the title area
                primary: true,
                flexibleSpace: FlexibleSpaceBar(
                  // 1. Reset titlePadding so the background layout fills the entire width
                  titlePadding: EdgeInsets.zero,
                  // 2. Move your full-width UI block into the background property
                  background: Container(
                    width: double.infinity,
                    // margin: EdgeInsets.symmetric(vertical: 24, horizontal: 12),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      // borderRadius: const BorderRadius.all(Radius.circular(28)),
                    ),
                    // SafeArea prevents content from clipping into the status bar notch
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ProfileImagePicker(
                            initialImageUrl:
                                userProfileState.userProfile?.profileImageUrl ??
                                "",
                          ),

                          SizedBox(height: 12),

                          const DisplayName(),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.star_rate_rounded,
                                size: 30,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                (userProfileState.userProfile?.ratingAverage ??
                                        0)
                                    .toStringAsFixed(1),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),

                              const SizedBox(width: 8),

                              Text(
                                "- ${userProfileState.userProfile?.orderCount ?? 0} orders",
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w400,
                                  color: theme.colorScheme.onPrimary.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      UserProfileTile(
                        icon: Icons.phone_android_rounded,
                        iconColor: theme.primaryColor,
                        iconBgColor: theme.primaryColor.withValues(alpha: 0.15),
                        label: l10n.phoneNumber,
                        value:
                            userProfileState.userProfile?.phoneNumber ??
                            "+7 234 ...",
                        onTap: () {},
                        trailing: const Icon(Icons.edit, color: Colors.white54),
                      ),

                      const SizedBox(height: 20),

                      UserProfileTile(
                        icon: LucideIcons.globe,
                        iconColor: theme.primaryColor,
                        iconBgColor: theme.primaryColor.withValues(alpha: 0.15),
                        label: l10n.appLanguage,
                        value: langDisplay,
                        onTap: () => LanguageSheet.show(context),
                      ),

                      const SizedBox(height: 20),

                      const BecomeOwnerCTA(),

                      const SizedBox(height: 20),

                      SettingsLinkTile(
                        icon: Icons.favorite_outline,
                        iconColor: theme.primaryColor,
                        iconBgColor: theme.primaryColor.withValues(alpha: 0.15),
                        title: l10n.supportUsTitle,
                        subtitle: l10n.donateOrHelp,
                        onTap: () => context.push(AppRoutes.supportUs),
                      ),

                      const SizedBox(height: 20),

                      SettingsLinkTile(
                        icon: LucideIcons.shieldCheck,
                        iconColor: theme.primaryColor,
                        iconBgColor: theme.primaryColor.withValues(alpha: 0.15),
                        title: l10n.privacyPolicy,
                        onTap: () => context.push(AppRoutes.privacyPolicy),
                      ),

                      const SizedBox(height: 20),

                      SettingsLinkTile(
                        icon: LucideIcons.fileSignature,
                        iconColor: theme.primaryColor,
                        iconBgColor: theme.primaryColor.withValues(alpha: 0.15),
                        title: l10n.termsConditions,
                        onTap: () => context.push(AppRoutes.termsConditions),
                      ),

                      const SizedBox(height: 20),

                      SettingsLinkTile(
                        icon: LucideIcons.lifeBuoy,
                        iconColor: Colors.red,
                        iconBgColor: Colors.red.withValues(alpha: 0.15),
                        title: l10n.helpSupportTitle,
                        subtitle: l10n.helpSupportSubtitle,
                        onTap: () => context.push(AppRoutes.helpSupport),
                      ),

                      const SizedBox(height: 20),

                      SettingsLinkTile(
                        icon: LucideIcons.settings,
                        iconColor: theme.primaryColor,
                        iconBgColor: theme.primaryColor.withValues(alpha: 0.15),
                        title: l10n.appSettings,
                        subtitle: l10n.appSettingsSubtitle,
                        onTap: () => context.push(AppRoutes.clientSettings),
                      ),

                      const SizedBox(height: 40),
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
            ],
          ),
        ),
      ),
    );
  }
}
