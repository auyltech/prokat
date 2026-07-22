import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:prokat/core/widgets/section_title.dart';
import 'package:prokat/features/user/widgets/delete_account_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

class OwnerSettingsScreen extends StatelessWidget {
  const OwnerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(title: l10n.notifications),
                _card([
                  _switchTile(l10n.newBookingRequests, true, (v) {}),
                  _switchTile(l10n.messages, true, (v) {}),
                  _switchTile(l10n.reminders, true, (v) {}),
                ]),

                const SizedBox(height: 16),

                SectionTitle(title: l10n.safetyAndRules),
                _card([
                  _tile(l10n.cancellationPolicy, l10n.moderate, () {}),
                  _tile(l10n.damagePolicy, l10n.standardCoverage, () {}),
                ]),

                const SizedBox(height: 20),

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
        ],
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Card(child: Column(children: children));
  }

  Widget _switchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _tile(String title, String value, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      subtitle: Text(value),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
