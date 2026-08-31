import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:prokat/core/providers/locale_provider.dart';
import 'package:prokat/core/theme/theme_provider.dart';
import 'package:prokat/core/widgets/prokat_list_tile.dart';
import 'package:prokat/features/appstatic/widgets/language_sheet.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/notifications/providers/push_notification_service_provider.dart';
import 'package:prokat/features/user/models/client_notification_preferences.dart';
import 'package:prokat/features/user/state/client_profile_provider.dart';
import 'package:prokat/features/user/widgets/client_notifications_section.dart';
import 'package:prokat/features/user/widgets/delete_account_tile.dart';
import 'package:prokat/features/user/widgets/theme_selection_sheet.dart';
import 'package:prokat/l10n/app_localizations.dart';

class ClientSettingsScreen extends ConsumerStatefulWidget {
  const ClientSettingsScreen({super.key});

  @override
  ConsumerState<ClientSettingsScreen> createState() =>
      _ClientSettingsScreenState();
}

class _ClientSettingsScreenState extends ConsumerState<ClientSettingsScreen> {
  String _themeLabel(ThemeMode mode, AppLocalizations l10n) {
    return switch (mode) {
      ThemeMode.system => l10n.themeSystemDefault,
      ThemeMode.light => l10n.themeLight,
      ThemeMode.dark => l10n.themeDark,
    };
  }

  @override
  void initState() {
    super.initState();

    unawaited(
      Future.microtask(() async {
        await ref.read(clientProfileProvider.notifier).refreshIfStale();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final locale = ref.watch(localeProvider);
    final langDisplay = LocaleNotifier.displayCode(locale);
    final currentMode = ref.watch(themeModeProvider);

    final profileAsync = ref.watch(clientProfileProvider);
    final profile = profileAsync.valueOrNull;

    final notificationPreferences =
        profile?.notificationSettings ?? const ClientNotificationPreferences();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ProkatListTile(
              icon: LucideIcons.globe,
              iconColor: theme.colorScheme.onPrimary,
              iconBgColor: theme.colorScheme.primary.withValues(alpha: 0.15),
              title: l10n.appLanguage,
              subtitle: langDisplay,
              onTap: () => LanguageSheet.show(context),
            ),

            const SizedBox(height: 16),

            ProkatListTile(
              icon: LucideIcons.palette,
              iconColor: theme.colorScheme.onPrimary,
              iconBgColor: theme.colorScheme.primary.withValues(alpha: 0.15),
              title: l10n.applicationTheme,
              subtitle: _themeLabel(currentMode, l10n),
              onTap: () async {
                final selectedMode = await ThemeSelectionSheet.show(
                  context,
                  selectedMode: currentMode,
                );

                if (selectedMode == null) return;

                ref.read(themeModeProvider.notifier).setThemeMode(selectedMode);
              },
            ),

            const SizedBox(height: 16),

            if (profile == null && profileAsync.isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ClientNotificationsSection(
                initialValue: notificationPreferences,
                onSave: (preferences) {
                  return ref
                      .read(clientProfileMutationProvider.notifier)
                      .updateClientNotificationSettings(preferences);
                },
                onPushAuthorized: () async {
                  final session = ref.read(authProvider).session;

                  if (session == null) return;

                  await ref
                      .read(pushNotificationServiceProvider)
                      .syncCurrentDevice(session: session);
                },
              ),

            const SizedBox(height: 16),

            ProkatListTile(
              icon: Icons.security_outlined,
              iconBgColor: Colors.grey.withValues(alpha: 0.1),
              iconColor: theme.colorScheme.onPrimary,
              title: l10n.serviceAndSafetyNotices,
              subtitle: l10n.serviceAndSafetyNoticesSubtitle,
              onTap: () {},
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
                  final version = packageInfo.version; // e.g., "1.0.0"
                  final buildNumber = packageInfo.buildNumber; // e.g., "1"

                  return Center(
                    child: Text(
                      l10n.versionLabel(version, buildNumber),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }

                return Text(l10n.failedToLoadVersion);
              },
            ),
          ],
        ),
      ),
    );
  }
}
