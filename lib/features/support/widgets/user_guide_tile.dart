import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/features/support/models/guide_icon.dart';
import 'package:prokat/features/support/models/user_guide.dart';

class UserGuideTile extends StatelessWidget {
  const UserGuideTile({
    super.key,
    required this.guide,
    required this.locale,
    this.onTap,
  });

  final UserGuide guide;
  final String locale;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = guide.translation(locale);
    final flow = ProkatFlowScope.maybeOf(context);

    return Card(
      elevation: flow == null ? null : 0,
      color: flow?.surface,
      shape: flow == null
          ? null
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.r16$xl),
              side: BorderSide(color: flow.border),
            ),
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      flow?.primarySoft ?? theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
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
                      tr.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      tr.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            flow?.secondary ??
                            theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Icon(
                flow == null
                    ? Icons.arrow_forward_ios_rounded
                    : LucideIcons.chevronRight,
                size: 16,
                color: flow?.secondary ?? theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
