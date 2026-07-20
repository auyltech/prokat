import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:prokat/features/support/models/guide_icon.dart';
import 'package:prokat/features/support/models/user_guide.dart';

class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({
    super.key,
    required this.guide,
    required this.currentLocale,
  });

  final UserGuide guide;
  final String currentLocale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = guide.translation(currentLocale);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _GuideHeader(guide: guide, translation: tr),

            const Divider(height: 1),

            Expanded(
              child: Markdown(
                padding: const EdgeInsets.all(20),
                data: tr.content,
                selectable: true,
                styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                  h1: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  h2: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  p: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                  listBullet: theme.textTheme.bodyLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideHeader extends StatelessWidget {
  const _GuideHeader({required this.guide, required this.translation});

  final UserGuide guide;
  final UserGuideTranslation translation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              guideIcon(guide.icon),
              color: theme.colorScheme.primary,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  translation.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  translation.summary,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    _GuideChip(
                      icon: Icons.schedule_outlined,
                      label: '${_readingTime(translation.content)} min read',
                    ),
                    const SizedBox(width: 8),
                    _GuideChip(
                      icon: Icons.menu_book_outlined,
                      label: guide.category,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _readingTime(String markdown) {
    final words = markdown.split(RegExp(r'\s+')).length;
    return (words / 200).ceil().clamp(1, 99);
  }
}

class _GuideChip extends StatelessWidget {
  const _GuideChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}
