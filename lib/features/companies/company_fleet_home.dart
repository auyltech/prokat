import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/l10n/app_localizations.dart';

import 'company_screen.dart';
import 'company_service.dart';
import 'company_widgets.dart';
import 'company_workspace_screen.dart';

class CompanyFleetHome extends ConsumerWidget {
  const CompanyFleetHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final companies = ref.watch(companyContextProvider);
    return companies.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CompanyNotice(l10n.companyLoadFailed),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => ref.invalidate(companyContextProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
      data: (data) {
        if (data.memberships.isEmpty) return const CompanyScreen();
        if (data.memberships.length == 1) {
          return CompanyWorkspaceScreen(
            companyId: data.memberships.first.organization.id,
            showCatalogLink: true,
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text(l10n.companyWorkspace)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              for (final membership in data.memberships)
                CompanySection(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(membership.organization.name),
                    subtitle: Text(l10n.companyFleet),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CompanyWorkspaceScreen(
                          companyId: membership.organization.id,
                          showCatalogLink: true,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
