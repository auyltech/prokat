import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/section_title.dart';
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

                const SizedBox(height: 16),

                SectionTitle(title: l10n.dangerZone),
                _card([
                  _dangerTile(l10n.deactivateAccount, () {}),
                  _dangerTile(l10n.deleteAccount, () {}),
                ]),
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

  Widget _dangerTile(String title, VoidCallback onTap) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.red)),
      onTap: onTap,
    );
  }
}
