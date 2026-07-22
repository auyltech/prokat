import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  String _getLocaleAssetPath(BuildContext context) {
    try {
      final localeCode = Localizations.localeOf(context).languageCode;
      print(localeCode);
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
    return Scaffold(
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
                    'Error loading document. Please try again later.',
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
