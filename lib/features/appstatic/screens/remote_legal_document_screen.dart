import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/providers/locale_provider.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/appstatic/providers/legal_documents_provider.dart';
import 'package:prokat/features/appstatic/widgets/language_sheet.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class RemoteLegalDocumentScreen extends ConsumerWidget {
  const RemoteLegalDocumentScreen({
    super.key,
    required this.slug,
    required this.title,
  });
  final String slug;
  final String title;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final code = Localizations.localeOf(context).languageCode;
    final documents = ref.watch(legalDocumentsProvider(code));
    final titles = documents.asData?.value
        .where((document) => document.slug == slug)
        .map((document) => document.title)
        .toList();
    final currentTitle = titles != null && titles.isNotEmpty
        ? titles.first
        : title;
    return Scaffold(
      appBar: AppBar(
        title: Text(currentTitle),
        actions: [
          AppLabelButton(
            title: LocaleNotifier.displayCode(locale),
            onTap: () => LanguageSheet.show(context),
            variant: AppLabelButtonVariant.soft,
          ),
        ],
        actionsPadding: const EdgeInsets.only(right: 8),
      ),
      body: SafeArea(
        child: documents.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(legalDocumentsProvider(code)),
              child: Text(AppLocalizations.of(context)!.legalDocumentLoadError),
            ),
          ),
          data: (items) {
            final matches = items.where((item) => item.slug == slug);
            if (matches.isEmpty) {
              return Center(
                child: Text(
                  AppLocalizations.of(context)!.legalDocumentLoadError,
                ),
              );
            }
            final document = matches.first;
            return Markdown(
              data: '# ${document.title}\n\n${document.body}',
              onTapLink: (text, href, _) async {
                final uri = Uri.tryParse(href ?? '');
                if (uri == null) return;
                final internal =
                    !uri.hasScheme ||
                    (uri.scheme == 'https' && uri.host == 'prokat.auyltech.kz');
                if (internal &&
                    uri.pathSegments.length == 2 &&
                    uri.pathSegments.first == 'legal-documents') {
                  final targetSlug = uri.pathSegments.last;
                  if (targetSlug == slug) return;
                  await Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute<void>(
                      builder: (_) => RemoteLegalDocumentScreen(
                        slug: targetSlug,
                        title: text,
                      ),
                    ),
                  );
                } else if (uri.scheme == 'https' || uri.scheme == 'mailto') {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              selectable: true,
              padding: const EdgeInsets.all(20),
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                  .copyWith(
                    p: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(height: 1.6),
                  ),
            );
          },
        ),
      ),
    );
  }
}
