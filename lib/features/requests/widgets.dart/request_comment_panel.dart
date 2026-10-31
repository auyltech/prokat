import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/l10n/app_localizations.dart';

class RequestCommentPanel extends StatelessWidget {
  const RequestCommentPanel({super.key, required this.comment});
  final String comment;
  @override
  Widget build(BuildContext context) {
    final palette = ProkatFlowPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.messageSquare, size: 16, color: palette.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.comments,
                  style: TextStyle(fontSize: 11, color: palette.secondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            comment.trim(),
            style: TextStyle(fontSize: 14, height: 1.4, color: palette.title),
          ),
        ],
      ),
    );
  }
}
