import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/providers/locale_provider.dart';
import 'package:prokat/features/appstatic/widgets/language_sheet.dart';
import 'package:prokat/l10n/app_localizations.dart';

class UserAgreementScreen extends ConsumerStatefulWidget {
  const UserAgreementScreen({super.key});

  @override
  ConsumerState<UserAgreementScreen> createState() =>
      _UserAgreementScreenState();
}

class _UserAgreementScreenState extends ConsumerState<UserAgreementScreen> {
  // Dynamically determines the locale code from your existing app localization state
  String _getLocaleAssetPath(BuildContext context) {
    try {
      final localeCode = Localizations.localeOf(context).languageCode;
      // Dynamically falls back to 'en' if the current language file is not yet available
      if (localeCode == 'kk' || localeCode == 'ru') {
        return 'assets/legal/user_agreement_$localeCode.md';
      }
    } catch (_) {
      // Fallback architecture to ensure the app never crashes
    }
    return 'assets/legal/user_agreement_en.md';
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
      backgroundColor: theme.scaffoldBackgroundColor,
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

            // 2. Error Fallback State
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    AppLocalizations.of(context)!.termsLoadError,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            // 3. Document Content Display State
            return Markdown(
              data: snapshot.data ?? '',
              selectable: true,
              padding: const EdgeInsets.all(20.0),
              styleSheet: MarkdownStyleSheet(
                // Formats your Main Header (# Legal Stuff)
                h1: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                // Formats your Sections (## 1. Rental Eligibility)
                h2: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                // Formats the Standard Paragraph Text Content
                p: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                // Replaces your old custom _buildLegalSection summary container styling perfectly
                blockquote: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                blockquotePadding: const EdgeInsets.all(12.0),
                blockquoteDecoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(color: Colors.blue.shade400, width: 4),
                  ),
                ),
                // Formats your bottom horizontal divider line (---)
                // hr: Divider(color: theme.dividerColor, height: 40),
              ),
            );
          },
        ),
      ),
    );
  }
}
