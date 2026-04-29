import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/chat/state/chat_provider.dart';

class OwnerChatInfoScreen extends ConsumerWidget {
  final String? chatId;

  const OwnerChatInfoScreen({super.key, this.chatId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final chatState = ref.watch(chatProvider);
    final chat = chatState.currentChat?.id == chatId
        ? chatState.currentChat
        : chatState.conversations
              .where((item) => item.id == chatId)
              .firstOrNull;
    final title = chat?.displayTitle(chatState.currentUserId ?? "") ?? 'Chat';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: theme.colorScheme.primary,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: theme.colorScheme.onPrimary,
              ),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Order Details',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildInfoSection(theme, 'Chat', [
                  _buildListTile(theme, 'Participant', title),
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

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
