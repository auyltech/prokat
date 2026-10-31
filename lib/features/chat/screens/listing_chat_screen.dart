import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/chat/screens/client_chat_screen.dart';
import 'package:prokat/features/chat/widgets/chat_header_tile.dart';
import 'package:prokat/features/notifications/widgets/notification_badge.dart';
import 'package:prokat/features/user_safety/widgets/chat_safety_menu_button.dart';
import 'package:prokat/l10n/app_localizations.dart';

/// A chat above the listing navigator, so closing it restores the same listing.
class ListingChatScreen extends ConsumerWidget {
  const ListingChatScreen({super.key, required this.chatId});
  final String chatId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authProvider).session?.user?.id ?? '';
    final palette = ProkatFlowPalette.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.surface,
        foregroundColor: palette.title,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        centerTitle: false,
        leading: IconButton(
          tooltip: AppLocalizations.of(context)!.back,
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () => context.pop(),
        ),
        title: ChatHeaderTile(chatId: chatId, currentUserId: userId),
        actions: [
          ChatSafetyMenuButton(chatId: chatId, currentUserId: userId),
          const NotificationBadge(),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: palette.border),
        ),
      ),
      body: ClientChatScreen(chatId: chatId),
    );
  }
}
