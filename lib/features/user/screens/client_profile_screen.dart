import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/providers/locale_provider.dart';
import 'package:prokat/features/appstatic/widgets/show_language_sheet.dart';
import 'package:prokat/features/auth/widgets/logout_button.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
import 'package:prokat/features/user/state/user_profile_provider.dart';
import 'package:prokat/features/user/widgets/become_owner_cta.dart';
import 'package:prokat/features/user/widgets/profile_image_picker.dart';
import 'package:prokat/features/user/widgets/user_profile_tile.dart';
import 'package:prokat/features/user/widgets/display_name.dart';
import 'package:prokat/features/user/widgets/setting_link_tile.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/user/widgets/language_selector_tile.dart';
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
    final profileNotifier = ref.read(userProfileProvider.notifier);

    final locale = ref.watch(localeProvider);
    final langDisplay = LocaleNotifier.displayCode(locale);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView(
        padding: EdgeInsets.all(24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ProfileImagePicker(
                onImageSelected: (file) async {
                  if (file != null) {
                    await profileNotifier.uploadProfileImage(file);
                  }
                },
                initialImageUrl: userProfileState.userProfile?.profileImageUrl ?? "",
              ),

              const SizedBox(width: 20),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DisplayName(),

                  // Rating and Orders
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rate_rounded,
                        size: 30,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        (userProfileState.userProfile?.ratingAverage ?? 0).toStringAsFixed(
                          1,
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "- ${userProfileState.userProfile?.ratingCount ?? 0} ratings",
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.secondary.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const LanguageSelectorTile(),

          UserProfileTile(
            icon: Icons.phone_android_rounded,
            label: l10n.phoneNumber,
            value: userProfileState.userProfile?.phoneNumber ?? "+7 234 ...",
            onTap: () {},
            trailing: const Icon(Icons.edit, color: Colors.white54),
          ),

          const SizedBox(height: 20),

          UserProfileTile(
            icon: LucideIcons.globe,
            label: "App Language",
            value: langDisplay,
            onTap: () => showLanguageSheet(context),
          ),

          const SizedBox(height: 20),

          const BecomeOwnerCTA(),

          const SizedBox(height: 20),

          SettingsLinkTile(
            icon: Icons.favorite_outline,
            title: l10n.supportUsTitle,
            subtitle: l10n.donateOrHelp,
            onTap: () => context.push('/support-us'),
          ),

          const SizedBox(height: 20),

          SettingsLinkTile(
            icon: Icons.description_outlined,
            title: l10n.termsConditions,
            onTap: () => context.push('/terms'),
          ),

          const SizedBox(height: 20),

          SettingsLinkTile(
            icon: Icons.help_outline,
            title: l10n.helpSupportTitle,
            subtitle: l10n.helpSupportSubtitle,
            onTap: () => context.push('/help'),
          ),

          const SizedBox(height: 20),

          const LogoutButton(),
        ],
      ),
    );
  }
}
