import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/prokat_list_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

class LegalDocumentsScreen extends StatelessWidget {
  const LegalDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final iconColor = theme.colorScheme.onPrimary;
    final iconBgColor = theme.colorScheme.primary.withValues(alpha: 0.2);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ProkatListTile(
              icon: LucideIcons.shieldCheck,
              iconColor: iconColor,
              iconBgColor: iconBgColor,
              title: l10n.privacyPolicy,
              subtitle: l10n.privacyPolicySubtitle,
              onTap: () => context.push(AppRoutes.privacyPolicy),
            ),
            const SizedBox(height: 20),
            ProkatListTile(
              icon: LucideIcons.fileSignature,
              iconColor: iconColor,
              iconBgColor: iconBgColor,
              title: l10n.userAgreement,
              subtitle: l10n.userAgreementSubtitle,
              onTap: () => context.push(AppRoutes.userAgreement),
            ),
            const SizedBox(height: 20),
            ProkatListTile(
              icon: LucideIcons.text,
              iconColor: iconColor,
              iconBgColor: iconBgColor,
              title: l10n.userConsent,
              subtitle: l10n.personalDataSharingSubtitle,
              onTap: () => context.push(AppRoutes.personalDataConsent),
            ),
          ],
        ),
      ),
    );
  }
}
