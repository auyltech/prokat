import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/page_header.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/l10n/app_localizations.dart';

class UserSettingsScreen extends ConsumerStatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  ConsumerState<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends ConsumerState<UserSettingsScreen> {
  late AppLocalizations _l10n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
  }

  void _handleLogout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authProvider.notifier).logout();

      if (context.mounted) context.push('/search/map');
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.show(context, message: _l10n.logoutFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const bgColor = Color(0xFF121417);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(title: l10n.navSettings),

              const SizedBox(height: 20),

              // SECTION: PREFERENCES
              _SettingsSectionHeader(title: l10n.preferences),

              _SettingsSwitchTile(
                icon: Icons.notifications_none_rounded,
                title: l10n.pushNotifications,
                subtitle: l10n.bookingAlerts,
                value: true,
                onChanged: (val) {},
              ),
              _SettingsSwitchTile(
                icon: Icons.fingerprint_rounded,
                title: l10n.biometricLogin,
                subtitle: l10n.secureAccess,
                value: false,
                onChanged: (val) {},
              ),

              const SizedBox(height: 24),

              // SECTION: SUPPORT
              _SettingsSectionHeader(title: l10n.supportSection),
              _SettingsActionTile(
                icon: Icons.help_outline_rounded,
                title: l10n.helpCenter,
                onTap: () {},
              ),
              _SettingsActionTile(
                icon: Icons.description_outlined,
                title: l10n.termsOfService,
                onTap: () {},
              ),

              const SizedBox(height: 32),

              // SECTION: ACCOUNT ACTIONS
              _SettingsSectionHeader(title: l10n.accountSection),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    _DangerActionBtn(
                      label: l10n.logout,
                      icon: Icons.logout_rounded,
                      color: Colors.white.withValues(alpha: 0.7),
                      onPressed: () => _handleLogout(context, ref),
                    ),
                    const SizedBox(height: 12),
                    _DangerActionBtn(
                      label: l10n.deleteAccount,
                      icon: Icons.delete_forever_outlined,
                      color: Colors.redAccent.withValues(alpha: 0.8),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              const Center(
                child: Text(
                  "Version 1.0.4 (Build 22)",
                  style: TextStyle(
                    color: Color(0x33FFFFFF),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSectionHeader extends StatelessWidget {
  final String title;
  const _SettingsSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2125),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF4E73DF)),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 12,
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

class _SettingsActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2125),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Colors.white.withValues(alpha: 0.6)),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}

class _DangerActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _DangerActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.2)),
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
