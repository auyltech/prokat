import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

class SupportUsPage extends StatelessWidget {
  const SupportUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(color: theme.colorScheme.primary),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: theme.colorScheme.onPrimary,
                    ),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Help Us Grow",
                    style: TextStyle(color: theme.colorScheme.onPrimary),
                  ),
                ],
              ),
            ),

            _buildHeroHeader(context),
            const SizedBox(height: 20),
            _buildSection(
              context,
              title: 'The Simple Stuff',
              items: [
                _SupportItem(
                  icon: Icons.star_outline_rounded,
                  color: Colors.amber,
                  title: 'Rate us on the Store',
                  subtitle: '5-star reviews help others find us.',
                  actionText: 'Rate Now',
                  onTap: () => _launchUrl('https://apple.com'),
                ),
                _SupportItem(
                  icon: Icons.share_outlined,
                  color: Colors.blue,
                  title: 'Spread the Word',
                  subtitle: 'Share the app with a friend who needs gear.',
                  actionText: 'Share App',
                  onTap: () {
                    /* Use share_plus package here */
                  },
                ),
              ],
            ),
            _buildSection(
              context,
              title: 'Contribute to the App',
              items: [
                _SupportItem(
                  icon: Icons.bug_report_outlined,
                  color: Colors.orange,
                  title: 'Beta Test & Feedback',
                  subtitle: 'Report bugs or suggest new rental features.',
                  actionText: 'Submit Ideas',
                  onTap: () => _launchUrl('mailto:feedback@yourapp.com'),
                ),
                _SupportItem(
                  icon: Icons.work_outline_rounded,
                  color: Colors.purple,
                  title: 'Join our Team',
                  subtitle: 'We are looking for developers & ops help.',
                  actionText: 'View Careers',
                  onTap: () => _launchUrl('https://yourapp.com'),
                ),
              ],
            ),
            _buildSection(
              context,
              title: 'Fuel the Mission',
              items: [
                _SupportItem(
                  icon: Icons.coffee_outlined,
                  color: Colors.brown,
                  title: 'Buy the Devs a Coffee',
                  subtitle: 'A small tip to keep the servers running.',
                  actionText: 'Donate',
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

  Widget _buildHeroHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const Icon(Icons.favorite, size: 64, color: Colors.white),
          const SizedBox(height: 16),
          const Text(
            'We are building this together',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Our mission is to make equipment accessible to everyone. Here is how you can help us get there.',
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
