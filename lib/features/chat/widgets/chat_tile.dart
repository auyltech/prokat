import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/media/media_image_provider.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/utils/get_chat_status.dart';
import 'package:prokat/l10n/app_localizations.dart';

class ChatTile extends ConsumerWidget {
  final ChatModel chat;
  final String currentUserId;
  final AppMode mode;
  final VoidCallback onTap;

  const ChatTile({
    super.key,
    required this.chat,
    required this.onTap,
    required this.currentUserId,
    required this.mode,
  });

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status.trim().toUpperCase()) {
      case 'ACCEPTED':
      case 'CONFIRMED':
      case 'COMPLETED':
        return Colors.green.shade600;
      case 'REJECTED':
      case 'CANCELLED':
        return Colors.red.shade600;
      case 'PENDING':
      case 'CREATED':
        return Colors.orange.shade700;
      default:
        return theme.colorScheme.secondary;
    }
  }

  String _formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return '';
    final local = dateTime.toLocal();
    return "${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final flow = ProkatFlowScope.maybeOf(context);
    final l10n = AppLocalizations.of(context)!;

    final avatarUrl = chat.displayImageUrl(currentUserId: currentUserId);

    final title = chat.type == ChatType.direct
        ? chat.displayTitle(
            currentUserId,
            ownerFallback: l10n.nameNotSpecified,
            clientFallback: l10n.nameNotSpecified,
          )
        : chat.type == ChatType.support
        ? l10n.support
        : chat.type == ChatType.workflow
        ? l10n.support
        : l10n.announcements;

    final preview =
        chat.lastMessage?.localizedContent(
          Localizations.localeOf(context).languageCode,
        ) ??
        l10n.noMessagesYet;

    final timestamp = _formatTimestamp(
      chat.lastMessage?.createdAt ?? chat.updatedAt,
    );

    final unreadCount = chat.newMessagesCount ?? 0;
    final fullInquiryName = chat.inquiryEquipment?.name.trim() ?? '';
    final inquiryName = fullInquiryName.isNotEmpty
        ? fullInquiryName
        : chat.inquiryEquipmentName?.trim() ?? '';

    final summary = chat.bookingSummary;

    final chatStatus = getChatConfig(chat: chat, l10n: l10n, mode: mode);
    final statusLabel = chatStatus.statusLabel.trim();
    final showStatusBadge =
        statusLabel.isNotEmpty &&
        ((summary != null && summary.status.isNotEmpty) ||
            chat.inquiryEquipmentId != null);

    return InkWell(
      onTap: onTap,
      borderRadius: flow == null ? null : BorderRadius.circular(20),
      child: Container(
        margin: flow == null ? null : const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: flow?.surface ?? theme.cardColor,
          borderRadius: flow == null ? null : BorderRadius.circular(20),
          border: flow == null ? null : Border.all(color: flow.border),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        flow?.primarySoft ?? theme.colorScheme.primaryContainer,
                    backgroundImage: (avatarUrl ?? '').isNotEmpty
                        ? mediaImageProvider(ref, avatarUrl)
                        : null,
                    onBackgroundImageError: (avatarUrl ?? '').isNotEmpty
                        ? ignoreMediaImageLoadError
                        : null,
                    child: (avatarUrl ?? '').isEmpty
                        ? Text(
                            title.isNotEmpty ? title[0].toUpperCase() : 'C',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color:
                                  flow?.primary ??
                                  theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: title == l10n.nameNotSpecified
                                      ? FontWeight.w400
                                      : FontWeight.bold,
                                  fontSize: 16,
                                  color: title == l10n.nameNotSpecified
                                      ? theme.colorScheme.onSurface.withValues(
                                          alpha: 0.55,
                                        )
                                      : flow?.title,
                                ),
                              ),
                            ),
                            if (showStatusBadge && flow == null) ...[
                              const SizedBox(width: 8),
                              _StatusBadge(
                                label: statusLabel,
                                color: _getStatusColor(
                                  summary?.status ?? chat.status.name,
                                  theme,
                                ),
                                theme: theme,
                              ),
                            ],
                            if (flow != null && timestamp.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                timestamp,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: flow.secondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (inquiryName.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            inquiryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: flow?.secondary,
                            ),
                          ),
                        ],
                        if (flow != null && showStatusBadge) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: _StatusBadge(
                              label: statusLabel,
                              color:
                                  summary?.status.toUpperCase() == 'CONFIRMED'
                                  ? flow.success
                                  : summary?.status.toUpperCase() ==
                                            'CANCELLED' ||
                                        summary?.status.toUpperCase() ==
                                            'REJECTED'
                                  ? theme.colorScheme.error
                                  : flow.secondary,
                              theme: theme,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                preview,
                                maxLines: flow == null ? 1 : 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: unreadCount > 0
                                      ? flow?.title ??
                                            theme.textTheme.bodyLarge?.color
                                      : flow?.secondary ?? theme.hintColor,
                                  fontWeight: unreadCount > 0
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (unreadCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      flow?.filledPrimary ??
                                      theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  flow != null && unreadCount > 99
                                      ? '99+'
                                      : '$unreadCount',
                                  semanticsLabel: '$unreadCount',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                            if (flow == null && timestamp.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                timestamp,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.hintColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (flow == null)
              Divider(
                height: 1,
                thickness: 0.5,
                indent: 16,
                endIndent: 16,
                color: theme.dividerColor.withValues(alpha: 0.4),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final ThemeData theme;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final flow = ProkatFlowScope.maybeOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(flow == null ? 4 : 10),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Text(
        label,
        maxLines: flow == null ? 1 : null,
        overflow: flow == null ? TextOverflow.ellipsis : TextOverflow.visible,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          letterSpacing: flow == null ? 0.5 : 0,
          fontSize: flow == null ? 10 : 12,
        ),
      ),
    );
  }
}
