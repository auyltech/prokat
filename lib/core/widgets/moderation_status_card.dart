import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';

/// Status plaque for pending / rejected moderation (equipment, become-owner).
///
/// When [detail] is set (admin comment), it is shown below [subtitle] as a
/// separate inset block — never inlined into the explanation text.
class ModerationStatusCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? detail;

  const ModerationStatusCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final detailText = detail?.trim() ?? '';

    return Container(
      padding: const EdgeInsets.all(AppDimens.s12$md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimens.r16$xl),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: AppDimens.s12$md),
              Expanded(
                child: Text(title, style: AppFonts.body16SemiBold(context)),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.inputHelperGap),
          Text(subtitle, style: AppFonts.caption(context)),
          if (detailText.isNotEmpty) ...[
            const SizedBox(height: AppDimens.s12$md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimens.s12$md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface
                    .withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(AppDimens.r10$base),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Text(detailText, style: AppFonts.body14(context)),
            ),
          ],
        ],
      ),
    );
  }
}
