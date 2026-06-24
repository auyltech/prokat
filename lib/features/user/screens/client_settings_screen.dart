import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/base_tile.dart';
import 'package:prokat/core/widgets/section_title.dart';
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // SECTION: PREFERENCES
            SectionTitle(title: "Application Settings"),

            const SizedBox(height: 8),

            _SettingsSwitchTile(
              icon: Icons.notifications_none_rounded,
              title: l10n.pushNotifications,
              subtitle: l10n.bookingAlerts,
              value: true,
              onChanged: (val) {},
            ),

            const SizedBox(height: 16),

            _SettingsSwitchTile(
              icon: Icons.fingerprint_rounded,
              iconColor: Colors.black,
              iconBgColor: Colors.black.withValues(alpha: 0.08),
              title: l10n.biometricLogin,
              subtitle: l10n.secureAccess,
              value: false,
              onChanged: (val) {},
            ),

            const SizedBox(height: 20),

            DeleteAccountTile(),

            const SizedBox(height: 140),

            const Center(child: Text("Version 1.0.4")),
          ],
        ),
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final Color? iconBgColor;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    this.iconBgColor,
    this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BaseTile(
      // decoration: BoxDecoration(
      //   color: theme.colorScheme.surface,
      //   borderRadius: BorderRadius.circular(14),
      //   border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      // ),
      padding: EdgeInsets.all(0),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color:
                iconBgColor ??
                theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 32,
            color: iconColor ?? theme.colorScheme.primary,
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFF4E73DF),
        ),
      ),
    );
  }
}
