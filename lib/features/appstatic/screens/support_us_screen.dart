import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/l10n/app_localizations.dart';

class SupportUsPage extends StatelessWidget {
  const SupportUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: Text(
          l10n.helpUsGrow,
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
          padding: EdgeInsets.zero,
          children: [
            _buildHeroHeader(context, l10n),
            const SizedBox(height: 12),
            _buildSection(
              context,
              title: l10n.theSimpleStuff,
              items: [
                _SupportItem(
                  icon: Icons.star_outline_rounded,
                  color: Colors.amber,
                  title: l10n.rateOnStore,
                  subtitle: l10n.starReviewsHint,
                  actionText: l10n.rateNow,
                  onTap: () => _launchUrl('https://apple.com'),
                ),
                _SupportItem(
                  icon: Icons.share_outlined,
                  color: Colors.blue,
                  title: l10n.spreadTheWord,
                  subtitle: l10n.shareAppHint,
                  actionText: l10n.shareApp,
                  onTap: () {},
                ),
              ],
            ),
            _buildSection(
              context,
              title: l10n.contributeToApp,
              items: [
                _SupportItem(
                  icon: Icons.bug_report_outlined,
                  color: Colors.orange,
                  title: l10n.betaTestFeedback,
                  subtitle: l10n.reportBugsHint,
                  actionText: l10n.submitIdeas,
                  onTap: () => _launchUrl('mailto:feedback@yourapp.com'),
                ),
                _SupportItem(
                  icon: Icons.work_outline_rounded,
                  color: Colors.purple,
                  title: l10n.joinOurTeam,
                  subtitle: l10n.lookingForDevelopers,
                  actionText: l10n.viewCareers,
                  onTap: () => _launchUrl('https://yourapp.com'),
                ),
              ],
            ),
            _buildSection(
              context,
              title: l10n.fuelTheMission,
              items: [
                _SupportItem(
                  icon: Icons.coffee_outlined,
                  color: Colors.brown,
                  title: l10n.buyDevsACoffee,
                  subtitle: l10n.tipToKeepServersHint,
                  actionText: l10n.donate,
                  onTap: () => _launchUrl('https://buymeacoffee.com'),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const Icon(Icons.favorite, size: 64, color: Colors.white),
          const SizedBox(height: 16),
          Text(
            l10n.buildingTogether,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.missionStatement,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> items,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          ...items,
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) throw 'Could not launch $url';
  }
}

class _SupportItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String actionText;
  final VoidCallback onTap;

  const _SupportItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceBright,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onTap, child: Text(actionText)),
          ],
        ),
      ),
    );
  }
}
