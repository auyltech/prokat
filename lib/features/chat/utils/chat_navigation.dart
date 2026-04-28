import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/chat/state/chat_provider.dart';

Future<void> openChatFromLink({
  required BuildContext context,
  required WidgetRef ref,
  required bool isOwner,
  String? bookingId,
  String? requestId,
}) async {
  final notifier = ref.read(chatProvider.notifier);
  final chatId = await notifier.getChatId(
    bookingId: bookingId,
    requestId: requestId,
  );

  if (!context.mounted) {
    return;
  }

  if ((chatId ?? '').isEmpty) {
    final message = ref.read(chatProvider).error ?? 'Unable to open chat';

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    
    return;
  }

  final baseRoute = isOwner ? AppRoutes.ownerChat : AppRoutes.chat;
  context.push('$baseRoute/$chatId');
}
