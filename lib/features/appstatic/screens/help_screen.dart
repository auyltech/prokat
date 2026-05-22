import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/core/widgets/section_title.dart';
import 'package:prokat/l10n/app_localizations.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final faqs = [
      {"q": l10n.faq1Q, "a": l10n.faq1A},
      {"q": l10n.faq2Q, "a": l10n.faq2A},
      {"q": l10n.faq3Q, "a": l10n.faq3A},
      {"q": l10n.faq4Q, "a": l10n.faq4A},
      {"q": l10n.faq5Q, "a": l10n.faq5A},
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: Text(
          l10n.helpSupportTitle,
          style: TextStyle(color: theme.colorScheme.onPrimary),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: theme.colorScheme.onPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        backgroundColor: theme.primaryColor,
      ),
      body: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionTitle(title: l10n.frequentlyAskedQuestions),

                  _buildFAQ(faqs),

                  const SizedBox(height: 12),

                  SectionTitle(title: l10n.needMoreHelp),

                  _buildHelpOptions(context, theme, l10n),

                  PrimaryButton(
                    label: l10n.contactSupport,
                    onPressed: () => _openSupport(context, l10n),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQ(List<Map<String, String>> faqs) {
    return Column(
      children: faqs.map((faq) {
        return ExpansionTile(
          title: Text(faq["q"]!),
          children: [
            Padding(padding: const EdgeInsets.all(12), child: Text(faq["a"]!)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildHelpOptions(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Column(
      children: [
        _helpTile(
          theme: theme,
          icon: Icons.book_outlined,
          title: l10n.usingProkat,
          subtitle: l10n.learnHowPlatformWorks,
          onTap: () {},
        ),
        _helpTile(
          theme: theme,
          icon: Icons.payment_outlined,
          title: l10n.paymentsAndPricing,
          subtitle: l10n.feesPayoutsBilling,
          onTap: () {},
        ),
        _helpTile(
          theme: theme,
          icon: Icons.security_outlined,
          title: l10n.safetyAndTrust,
          subtitle: l10n.guidelinesAndPolicies,
          onTap: () {},
        ),
        _helpTile(
          theme: theme,
          icon: Icons.person_outline,
          title: l10n.accountHelp,
          subtitle: l10n.loginProfileSettings,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _helpTile({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.colorScheme.surfaceBright,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _openSupport(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.contactSupport,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: Text(l10n.emailSupport),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: Text(l10n.liveChat),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: Text(l10n.callUs),
                onTap: () {},
              ),
            ],
          ),
        );
      },
    );
  }
}
