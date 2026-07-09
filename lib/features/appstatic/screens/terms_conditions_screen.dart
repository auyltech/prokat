import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  // Dynamically determines the locale code from your existing app localization state
  String _getLocaleAssetPath(BuildContext context) {
    try {
      final localeCode = Localizations.localeOf(context).languageCode;
      // Dynamically falls back to 'en' if the current language file is not yet available
      if (localeCode == 'kz' || localeCode == 'ru') {
        return 'assets/legal/terms_conditions_$localeCode.md';
      }
    } catch (_) {
      // Fallback architecture to ensure the app never crashes
    }
    return 'assets/legal/terms_conditions_en.md';
  }

  Future<String> _loadTermsMarkdown(BuildContext context) async {
    final assetPath = _getLocaleAssetPath(context);
    return await DefaultAssetBundle.of(context).loadString(assetPath);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: FutureBuilder<String>(
          future: _loadTermsMarkdown(context),
          builder: (context, snapshot) {
            // 1. Loading State
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // 2. Error Fallback State
            if (snapshot.hasError) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'Failed to load Terms & Conditions. Please try again later.',
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
