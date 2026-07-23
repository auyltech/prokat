import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:prokat/core/providers/locale_provider.dart';
import 'package:prokat/core/widgets/prokat_list_tile.dart';
import 'package:prokat/features/appstatic/widgets/language_sheet.dart';
import 'package:prokat/features/user/widgets/client_notifications_preferences.dart';
import 'package:prokat/features/user/widgets/delete_account_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

class ClientSettingsScreen extends ConsumerStatefulWidget {
  const ClientSettingsScreen({super.key});

  @override
  ConsumerState<ClientSettingsScreen> createState() =>
      _ClientSettingsScreenState();
}

class _ClientSettingsScreenState extends ConsumerState<ClientSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final locale = ref.watch(localeProvider);
    final langDisplay = LocaleNotifier.displayCode(locale);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ProkatListTile(
              icon: LucideIcons.globe,
              iconColor: theme.primaryColor,
              iconBgColor: theme.primaryColor.withValues(alpha: 0.15),
              title: l10n.appLanguage,
              subtitle: langDisplay,
              onTap: () => LanguageSheet.show(context),
            ),

            const SizedBox(height: 16),

            ClientNotificationsSection(
              initialValue: const ClientNotificationPreferences(),
              onSave: (preferences) async {
                // Replace with your notification-preferences API/provider.
                // Return false when saving fails.
                return true;
              },
            ),

            const SizedBox(height: 16),

            ProkatListTile(
              icon: Icons.security_outlined,
              iconBgColor: Colors.black12,
              iconColor: Colors.black,
              title: 'Service and safety notices',
              subtitle: 'Account, security and important platform alerts',
              onTap: () {},
            ),

            const SizedBox(height: 60),

            DeleteAccountTile(),

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
