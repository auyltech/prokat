import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/features/support/models/guide_icon.dart';
import 'package:prokat/features/support/models/user_guide.dart';
import 'package:prokat/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final flow = ProkatFlowScope.maybeOf(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        spacing: 16,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color:
                      flow?.primarySoft ?? theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: guideIconWidget(
                  guide.icon,
                  color: flow?.primary ?? theme.colorScheme.onPrimary,
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
                  ],
                ),
              ),
            ],
          ),
          if (translation.content.trim().isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _GuideChip(
                  icon: Icons.schedule_outlined,
                  label: l10n.minutesRead(_readingTime(translation.content)),
                ),
                _GuideChip(
                  icon: Icons.menu_book_outlined,
                  label: switch (guide.category) {
                    'FIND_AND_ORDER' => l10n.navCatalog,
                    'CREATE_REQUEST' => l10n.createRequest,
                    'LISTING' => l10n.addEquipment,
                    'ORDER_CHAT' => l10n.chatSection,
                    'SAFETY' => l10n.safetyAndRules,
                    _ => guide.category,
                  },
                ),
              ],
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
    final flow = ProkatFlowScope.maybeOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: flow?.primarySoft ?? theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(child: Text(label, style: theme.textTheme.labelMedium)),
        ],
      ),
    );
  }
}
