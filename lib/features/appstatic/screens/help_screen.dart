import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/section_title.dart';
import 'package:prokat/features/appstatic/widgets/faq_tile.dart';
import 'package:prokat/features/support/data/faq_data.dart';
import 'package:prokat/features/support/data/guides_data.dart';
import 'package:prokat/features/support/widgets/contact_support_sheet.dart';
import 'package:prokat/features/support/widgets/user_guides_section.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:prokat/core/providers/locale_provider.dart';

class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final currentLocale = ref.watch(localeProvider).languageCode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // 1. Persistent Premium Header with Notification Badge
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FAQ Header Title
              Text(
                l10n.frequentlyAskedQuestions,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),

              // Custom FAQ Module Layout
              Column(
                children: faqs.map((faq) {
                  return FaqTile(faq: faq, currentLocale: currentLocale);
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Modular Help Category Cards
              SectionTitle(title: "User Guides"),
              const SizedBox(height: 12),

              UserGuidesSection(guides: guides, currentLocale: currentLocale),
              const SizedBox(height: 24),

              // Support Actions Header Title
              Text(
                l10n.needMoreHelp,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 12),
              // Primary Action Form Button Wrapper
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF004699,
                    ), // Matching image primary blue theme color
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => ContactSupportSheet.show(context),
                  child: Text(
                    l10n.contactSupport,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
