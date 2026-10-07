import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/appstatic/providers/legal_documents_provider.dart';
import 'package:prokat/features/appstatic/screens/remote_legal_document_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/widgets/prokat_list_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

class LegalDocumentsScreen extends ConsumerWidget {
  const LegalDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final code = Localizations.localeOf(context).languageCode;
    final documents = ref.watch(legalDocumentsProvider(code));
    final iconColor = theme.colorScheme.onPrimary;
    final iconBgColor = theme.colorScheme.primary.withValues(alpha: 0.2);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: documents.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(legalDocumentsProvider(code)),
              child: Text(l10n.legalDocumentLoadError),
            ),
          ),
          data: (publishedDocuments) {
            final items = publishedDocuments
                .where((document) => document.slug != 'account-deletion')
                .toList();
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                final document = items[index];
                return ProkatListTile(
                  icon: document.slug == 'privacy-policy'
                      ? LucideIcons.shieldCheck
                      : document.slug == 'consent'
                      ? LucideIcons.userRoundCheck
                      : LucideIcons.fileCheck,
                  iconColor: iconColor,
                  iconBgColor: iconBgColor,
                  title: document.title,
                  subtitle: switch (document.slug) {
                    'privacy-policy' => l10n.privacyPolicySubtitle,
                    'user-agreement' => l10n.userAgreementSubtitle,
                    'consent' => l10n.personalDataSharingSubtitle,
                    _ => l10n.legalDocumentsSubtitle,
                  },
                  onTap: () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute<void>(
                      builder: (_) => RemoteLegalDocumentScreen(
                        slug: document.slug,
                        title: document.title,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
