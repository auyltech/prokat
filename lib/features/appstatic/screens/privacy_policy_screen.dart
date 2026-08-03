import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/providers/locale_provider.dart';
import 'package:prokat/features/appstatic/widgets/language_sheet.dart';
import 'package:prokat/l10n/app_localizations.dart';

class PrivacyPolicyScreen extends ConsumerStatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  ConsumerState<PrivacyPolicyScreen> createState() =>
      _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends ConsumerState<PrivacyPolicyScreen> {
  String _getLocaleAssetPath(BuildContext context) {
    try {
      final localeCode = Localizations.localeOf(context).languageCode;

      // Dynamically falls back to 'en' if the current language file is not yet available
      if (localeCode == 'kk' || localeCode == 'ru') {
        return 'assets/legal/privacy_policy_$localeCode.md';
      }
    } catch (_) {
      // Fallback architecture to ensure the app never crashes
    }
    return 'assets/legal/privacy_policy_en.md';
  }

  Future<String> _loadMarkdown(BuildContext context) async {
    final assetPath = _getLocaleAssetPath(context);
    return await DefaultAssetBundle.of(context).loadString(assetPath);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final locale = ref.watch(localeProvider);
    final langDisplay = LocaleNotifier.displayCode(locale);

    return Scaffold(
      appBar: AppBar(
        title: Text("Data Processing"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () async {
            if (GoRouter.of(context).canPop()) {
              context.pop();
            }
          },
        ),
        actions: [
          GestureDetector(
            onTap: () => LanguageSheet.show(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(40),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white30),
              ),
              child: Text(
                langDisplay,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
        actionsPadding: EdgeInsets.only(right: 8),
      ),
      body: SafeArea(
        child: FutureBuilder<String>(
          future: _loadMarkdown(context),
          builder: (context, snapshot) {
            // 1. Loading State
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // 2. Error State (e.g., file typo or missing asset declaration)
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    AppLocalizations.of(context)!.legalDocumentLoadError,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              );
            }

            // 3. Success State - Render the Markdown text nicely
            return Markdown(
              data: snapshot.data ?? '',
              selectable: true,
              padding: const EdgeInsets.all(16.0),
              styleSheet: MarkdownStyleSheet(
                h1: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                h2: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  // marginTop: 16.0,
                ),
                p: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.5),
                listBullet: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            );
          },
        ),
      ),
    );
  }
}
