import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:prokat/core/constants/app_colors.dart';
import 'package:prokat/core/providers/locale_provider.dart';
import 'package:prokat/core/theme/theme_provider.dart';
import 'package:prokat/core/widgets/prokat_list_tile.dart';
import 'package:prokat/features/appstatic/widgets/language_sheet.dart';
import 'package:prokat/features/owner/models/owner_notification_preferences.dart';
import 'package:prokat/features/owner/widgets/owner_notifications_section.dart';
import 'package:prokat/features/user/widgets/delete_account_tile.dart';
import 'package:prokat/features/user/widgets/theme_selection_sheet.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/notifications/providers/push_notification_service_provider.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';

class OwnerSettingsScreen extends ConsumerStatefulWidget {
  const OwnerSettingsScreen({super.key});

  @override
  ConsumerState<OwnerSettingsScreen> createState() =>
      _OwnerSettingsScreenState();
}

class _OwnerSettingsScreenState extends ConsumerState<OwnerSettingsScreen>
    with SingleTickerProviderStateMixin {
  String _themeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => 'System default',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      if (ref.read(ownerRegistrationProvider).ownerProfile == null) {
        await ref.read(ownerRegistrationProvider.notifier).getOwnerProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final locale = ref.watch(localeProvider);
    final language = LocaleNotifier.displayCode(locale);
    final currentMode = ref.watch(themeModeProvider);

    final ownerState = ref.watch(ownerRegistrationProvider);
    final ownerProfile = ownerState.ownerProfile;

    final notificationPreferences =
        ownerProfile?.notificationSettings ??
        const OwnerNotificationPreferences();

    final ownerColor = AppColors.teal800;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ProkatListTile(
              icon: LucideIcons.globe,
              iconColor: ownerColor,
              iconBgColor: ownerColor.withValues(alpha: 0.15),
              title: l10n.appLanguage,
              subtitle: language,
              onTap: () => LanguageSheet.show(context),
            ),

            const SizedBox(height: 20),

            ProkatListTile(
              icon: LucideIcons.palette,
              iconColor: ownerColor,
              iconBgColor: ownerColor.withValues(alpha: 0.15),
              title: 'Application theme',
              subtitle: _themeLabel(currentMode),
              onTap: () async {
                final selectedMode = await ThemeSelectionSheet.show(
                  context,
                  selectedMode: currentMode,
                );

                if (selectedMode == null) return;

                ref.read(themeModeProvider.notifier).setThemeMode(selectedMode);
              },
            ),

            const SizedBox(height: 30),

            if (ownerProfile == null && ownerState.isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              OwnerNotificationsSection(
                initialValue: notificationPreferences,
                onPushAuthorized: () async {
                  final session = ref.read(authProvider).session;

                  if (session == null) return;

                  await ref
                      .read(pushNotificationServiceProvider)
                      .syncCurrentDevice(session: session);
                },
              ),

            const SizedBox(height: 60),

            const DeleteAccountTile(),

            const SizedBox(height: 140),

            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: Text(l10n.loading));
                }

                if (snapshot.hasData) {
                  final packageInfo = snapshot.data!;

                  return Center(
                    child: Text(
                      l10n.versionLabel(
                        packageInfo.version,
                        packageInfo.buildNumber,
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }

                return Center(child: Text(l10n.failedToLoadVersion));
              },
            ),
          ],
        ),
      ),
    );
  }
}
