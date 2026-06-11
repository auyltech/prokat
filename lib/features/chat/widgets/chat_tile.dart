import 'package:flutter/material.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/chat/state/chat_model.dart';
import 'package:prokat/features/chat/utils/get_chat_status.dart';

class ChatTile extends StatelessWidget {
  final ChatModel chat; // Replace with your ChatModel type
  final String currentUserId;
  final VoidCallback onTap;

  const ChatTile({
    super.key,
    required this.chat,
    required this.onTap,
    required this.currentUserId,
  });

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status.trim().toUpperCase()) {
      case 'ACCEPTED':
      case 'CONFIRMED':
      case 'COMPLETED': // Added completed status from your screenshot
        return Colors.green.shade600;
      case 'REJECTED':
      case 'CANCELLED':
        return Colors.red.shade600;
      case 'PENDING':
      case 'CREATED': // Added created status from your screenshot
        return Colors.orange.shade700;
      default:
        return theme.colorScheme.secondary;
    }
  }

  String _formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return '';
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final avatarUrl = chat.displayImageUrl(currentUserId: currentUserId);

    final title = chat.displayTitle(currentUserId);

    final preview = chat.lastMessage?.content ?? 'No messages yet';

    final timestamp = _formatTimestamp(
      chat.lastMessage?.createdAt ?? chat.updatedAt,
    );

    final unreadCount = chat.newMessagesCount ?? 0;

    final summary = chat.bookingSummary;

    final chatStatus = getChatStatus(
      bookingStatus: parseBookingStatus(chat.bookingSummary?.status),
      workStatus: parseWorkStatus(chat.bookingSummary),
    );

    final chatStatusLabel = getChatStatusLabel(chatStatus);

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: theme.cardColor),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Avatar Section
                  CircleAvatar(
                    radius: 24, // Optimized sizing
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage: (avatarUrl ?? '').isNotEmpty
                        ? NetworkImage(avatarUrl!)
                        : null,
                    child: (avatarUrl ?? '').isEmpty
                        ? Text(
                            title.isNotEmpty ? title[0].toUpperCase() : 'C',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),

                  // 2. Main Content & Message Preview Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Row that keeps message text and badge cleanly aligned
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                preview,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: unreadCount > 0
                                      ? theme.textTheme.bodyLarge?.color
                                      : theme.hintColor,
                                  fontWeight: unreadCount > 0
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),

                            // Clean, inline Unread Badge
                            if (unreadCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(
                                    12,
                                  ), // Dynamic pill shape
                                ),
                                child: Text(
                                  '$unreadCount',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 3. Right Status & Time Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (summary != null && summary.status.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              summary.status,
                              theme,
                            ).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _getStatusColor(
                                summary.status,
                                theme,
                              ).withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            chatStatusLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: _getStatusColor(summary.status, theme),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              fontSize: 10,
                            ),
                          ),
                        ),

                      Text(
                        timestamp,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.hintColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Clean separator line matching standard chat lists
            Padding(
              padding: const EdgeInsets.only(left: 78, right: 16),
              child: Divider(
                height: 1,
                thickness: 0.5,
                color: theme.dividerColor.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// String _formatTimestamp(DateTime? dateTime) {
//   if (dateTime == null) {
//     return '';
//   }

//   final now = DateTime.now();
//   if (now.difference(dateTime).inDays == 0) {
//     return DateFormat.Hm().format(dateTime);
//   }

//   if (now.difference(dateTime).inDays < 7) {
//     return DateFormat.E().format(dateTime);
//   }

//   return DateFormat('dd MMM').format(dateTime);
// }
