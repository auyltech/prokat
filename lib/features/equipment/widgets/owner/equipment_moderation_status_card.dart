import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/moderation_status_card.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/l10n/app_localizations.dart';

class EquipmentModerationStatusCard extends StatelessWidget {
  final EquipmentStatus status;
  final String? adminComment;

  const EquipmentModerationStatusCard({
    super.key,
    required this.status,
    this.adminComment,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    switch (status) {
      case EquipmentStatus.created:
        return ModerationStatusCard(
          title: l10n.statusUnderReview,
          subtitle: l10n.statusUnderReviewSubtitle,
          icon: Icons.hourglass_top_rounded,
          color: colors.primary,
        );
      case EquipmentStatus.rejected:
        final comment = adminComment?.trim() ?? '';
        return ModerationStatusCard(
          title: l10n.statusRejected,
          subtitle: comment.isEmpty
              ? l10n.statusRejectedNoComment
              : l10n.statusRejectedReviewHint,
          icon: Icons.error_outline_rounded,
          color: colors.error,
          detail: comment.isEmpty ? null : comment,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
