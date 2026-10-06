import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_icon_button.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/user_safety/models/report_target.dart';
import 'package:prokat/features/user_safety/widgets/ugc_actions_sheet.dart';
import 'package:prokat/l10n/app_localizations.dart';

/// ⋮ on another user's content. Hidden for guests and for own content.
class UgcMoreButton extends ConsumerWidget {
  const UgcMoreButton({
    super.key,
    required this.counterpartUserId,
    required this.counterpartName,
    required this.reportTarget,
    this.chatId,
    this.isBlockedByMe = false,
    this.onBlocked,
    this.variant = AppIconButtonVariant.soft,
  });

  final String? counterpartUserId;
  final String counterpartName;
  final ReportTarget reportTarget;
  final String? chatId;
  final bool isBlockedByMe;
  final VoidCallback? onBlocked;
  final AppIconButtonVariant variant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(
      authProvider.select((state) => state.session?.user?.id),
    );
    final targetId = counterpartUserId?.trim() ?? '';
    if (currentUserId == null ||
        targetId.isEmpty ||
        targetId == currentUserId) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    return AppIconButton(
      key: const ValueKey('ugc-more-button'),
      icon: LucideIcons.ellipsisVertical,
      variant: variant,
      tooltip: l10n.reportAction,
      onTap: () => UgcActionsSheet.show(
        context,
        ref,
        counterpartUserId: targetId,
        title: counterpartName.trim().isEmpty
            ? l10n.reportAction
            : counterpartName.trim(),
        reportTarget: reportTarget,
        chatId: chatId,
        isBlockedByMe: isBlockedByMe,
        onBlocked: onBlocked,
      ),
    );
  }
}
