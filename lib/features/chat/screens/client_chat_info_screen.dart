import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/chat/state/chat_provider.dart';

class ClientChatInfoScreen extends ConsumerWidget {
  final String? chatId;

  const ClientChatInfoScreen({super.key, this.chatId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUserId = ref.watch(authProvider).currentUserId;

    final chatState = ref.watch(chatProvider);

    final chat = chatState.currentChat;

    final String title = (currentUserId != null && chat != null)
        ? chat.displayTitle(currentUserId)
        : "";

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildAvatarSection(theme, title),
                const SizedBox(height: 32),
                _buildInfoSection(theme, 'Context', [
                  _buildListTile(theme, 'Chat ID', chat?.id ?? '-'),
                  _buildListTile(
                    theme,
                    'Booking',
                    (chat?.bookingId ?? '').isNotEmpty
                        ? chat!.bookingId!
                        : 'Not linked',
                  ),
                  _buildListTile(
                    theme,
                    'Request',
                    (chat?.requestId ?? '').isNotEmpty
                        ? chat!.requestId!
                        : 'Not linked',
                  ),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(ThemeData theme, String title) {
    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          child: Text(title.isNotEmpty ? title[0].toUpperCase() : 'C'),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(
    ThemeData theme,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildListTile(ThemeData theme, String title, String value) {
    return ListTile(
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor),
      ),
      trailing: Text(
        value,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
