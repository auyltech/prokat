import 'package:flutter/material.dart';

class AboutProkatScreen extends StatelessWidget {
  const AboutProkatScreen({super.key});

  static const _features = [
    _AboutFeature(
      icon: Icons.search_rounded,
      title: 'Easy equipment search',
      description:
          'Find suitable equipment and trusted local service providers.',
    ),
    _AboutFeature(
      icon: Icons.verified_user_outlined,
      title: 'Trusted providers',
      description:
          'Equipment owners and service providers are reviewed before approval.',
    ),
    _AboutFeature(
      icon: Icons.star_outline_rounded,
      title: 'Two-way ratings',
      description:
          'Clients and owners build trust through transparent reviews.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('About Prokat'), centerTitle: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EQUIPMENT RENTAL MADE SIMPLE',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Prokat connects people looking for equipment with trusted local owners and service providers. Search, compare and communicate directly in one simple platform.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            ..._features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _FeatureTile(feature: feature),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.feature});

  final _AboutFeature feature;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(feature.icon, size: 24, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                feature.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                feature.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AboutFeature {
  const _AboutFeature({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
