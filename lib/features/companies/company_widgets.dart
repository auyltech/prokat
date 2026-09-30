import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/prokat_list_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

import 'company_service.dart';

class CompanyProfileTile extends ConsumerWidget {
  const CompanyProfileTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final data = ref.watch(companyContextProvider).valueOrNull;
    final memberships = data?.memberships ?? const [];
    final pending = data?.requests.where((item) => item.isPending).firstOrNull;
    final String title;
    final String subtitle;
    if (memberships.length == 1) {
      title = memberships.first.organization.name;
      subtitle = l10n.companyWorkspace;
    } else if (memberships.isNotEmpty) {
      title = l10n.companyWorkspace;
      subtitle = l10n.companyEntrySubtitle;
    } else if (pending != null) {
      title = pending.name;
      subtitle = l10n.companyApplicationPending;
    } else {
      title = l10n.companyRegister;
      subtitle = l10n.companyEntrySubtitle;
    }
    return ProkatListTile(
      icon: Icons.apartment_rounded,
      iconBgColor: colors.primary.withValues(alpha: 0.12),
      iconColor: colors.primary,
      title: title,
      subtitle: subtitle,
      onTap: () => context.push(AppRoutes.companies),
    );
  }
}

class CompanyNotice extends StatelessWidget {
  final String text;
  final IconData icon;
  const CompanyNotice(this.text, {super.key, this.icon = Icons.info_outline});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class CompanySection extends StatelessWidget {
  final Widget child;
  const CompanySection({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );
}

String companyErrorText(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context)!;
  if (error is CompanyApiException) {
    if (error.statusCode == 409) return l10n.companyConflict;
    if (error.statusCode == 401 || error.statusCode == 403)
      return l10n.companyAccessDenied;
  }
  return l10n.companyActionFailed;
}

void companySnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
