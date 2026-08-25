import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/chat/providers/current_chat_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class OwnerChatInfoScreen extends ConsumerWidget {
  final String chatId;

  const OwnerChatInfoScreen({super.key, required this.chatId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = ref.watch(authProvider).currentUserId ?? "";

    final chatAsync = ref.watch(currentChatProvider(chatId));
    return chatAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),

      error: (_, _) => Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(child: Text(l10n.failedToLoadChat)),
      ),

      data: (chat) {
        final title = chat?.displayTitle(
          currentUserId,
          ownerFallback: l10n.nameNotSpecified,
          clientFallback: l10n.nameNotSpecified,
        );

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildInfoSection(theme, l10n.chatSection, [
                      _buildListTile(theme, l10n.participant, title ?? ""),
                      _buildListTile(theme, l10n.chatId, chat?.id ?? ""),
                      _buildListTile(
                        theme,
                        l10n.booking,
                        (chat?.bookingId ?? '').isNotEmpty
                            ? chat?.bookingId ?? ""
                            : l10n.notLinked,
                      ),
                      _buildListTile(
                        theme,
                        l10n.requestLabel,
                        (chat?.requestId ?? '').isNotEmpty
                            ? chat?.requestId ?? ""
                            : l10n.notLinked,
                      ),
                    ]),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Widget _buildInfoSection(ThemeData theme, String title, List<Widget> children) {
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
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
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
