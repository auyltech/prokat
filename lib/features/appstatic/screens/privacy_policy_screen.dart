import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  // Future function to load the local markdown file string
  Future<String> _loadPrivacyPolicy(BuildContext context) async {
    // Tip: Later when adding language switching, replace 'en' with your language code variable
    // e.g., 'assets/legal/${currentLocale.languageCode}/privacy_policy.md'
    return await DefaultAssetBundle.of(
      context,
    ).loadString('assets/legal/privacy_policy_en.md');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<String>(
          future: _loadPrivacyPolicy(context),
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
