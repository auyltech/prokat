import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/auth/widgets/logout_button.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
import 'package:prokat/features/user/state/user_profile_provider.dart';
import 'package:prokat/features/user/widgets/become_owner_cta.dart';
import 'package:prokat/features/user/widgets/edit_name_sheet.dart';
import 'package:prokat/features/user/widgets/profile_image_picker.dart';
import 'package:prokat/features/user/widgets/user_profile_tile.dart';
import 'package:prokat/features/user/widgets/display_name.dart';
import 'package:prokat/features/user/widgets/setting_link_tile.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/user/widgets/language_selector_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

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

    Future.microtask(() {
      ref.read(userProfileProvider.notifier).getUserProfile();

      ref.read(ownerRegistrationProvider.notifier).getRegistrationRequest();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(userProfileProvider);
    final profileNotifier = ref.read(userProfileProvider.notifier);

    final topInset = MediaQuery.of(context).padding.top;

    final username = state.userProfile?.username;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // User Profile Header
          Container(
            decoration: BoxDecoration(color: theme.primaryColor),
            padding: EdgeInsets.fromLTRB(20, topInset + 20, 20, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ProfileImagePicker(
                        onImageSelected: (file) async {
                          if (file != null) {
                            await profileNotifier.uploadProfileImage(file);
                          }
                        },
                        initialImageUrl:
                            state.userProfile?.profileImageUrl ?? "",
                      ),

                      const SizedBox(width: 20),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const DisplayName(),

                          Row(
                            children: [
                              const Icon(
                                Icons.star_rate_rounded,
                                size: 30,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                (state.userProfile?.ratingStars ?? 0)
                                    .toStringAsFixed(1),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),

                              const SizedBox(width: 8),
                              Text(
                                "- 0 ${l10n.navOrders}",
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w400,
                                  color: theme.colorScheme.onPrimary.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const LanguageSelectorTile(),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                UserProfileTile(
                  icon: Icons.phone_android_rounded,
                  label: l10n.phoneNumber,
                  value: state.userProfile?.phoneNumber ?? "+7 234 ...",
                  onTap: () {},
                  trailing: const Icon(Icons.edit, color: Colors.white54),
                ),

                const SizedBox(height: 20),

                UserProfileTile(
                  icon: Icons.person,
                  label: l10n.displayName,
                  value: state.userProfile?.displayName ?? l10n.addDisplayName,
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (_) => EditNameSheet(
                      initialName: state.userProfile?.displayName ?? "",
                    ),
                  ),
                  trailing: username == null
                      ? const Icon(Icons.add, color: Colors.white54)
                      : null,
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
          ),
        ],
      ),
    );
  }
}
