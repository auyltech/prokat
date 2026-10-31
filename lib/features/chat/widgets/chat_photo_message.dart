import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/features/auth/providers/authenticated_session_scope.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/user_safety/models/report_target.dart';
import 'package:prokat/features/user_safety/widgets/report_sheet.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

final chatPhotoBytesProvider = FutureProvider.autoDispose
    .family<Uint8List, String>((ref, key) async {
      final scope = ref.watch(authenticatedSessionScopeKeyProvider);
      if (scope == null ||
          !RegExp(r'^[0-9a-f-]{36}/(thumb|photo)$').hasMatch(key)) {
        throw StateError('Photo unavailable');
      }
      final cancel = CancelToken();
      ref.onDispose(cancel.cancel);
      final response = await ref
          .read(apiClientProvider)
          .dio
          .get<List<int>>(
            '/chats/photos/$key',
            options: Options(responseType: ResponseType.bytes),
            cancelToken: cancel,
          );
      return Uint8List.fromList(response.data!);
    });

class ChatPhotoMessage extends ConsumerWidget {
  const ChatPhotoMessage({
    super.key,
    required this.message,
    required this.isMe,
  });
  final ChatMessageModel message;
  final bool isMe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = ProkatFlowPalette.of(context);
    final raw = message.meta?['attachment'];
    final id = raw is Map ? raw['id']?.toString() : null;
    final timestamp = message.createdAt?.toLocal();
    Future<void> report() => ReportSheet.show(
      context,
      ref,
      target: ReportTarget(ReportTargetType.chatMessage, message.id),
      counterpartUserId: message.senderId,
      chatId: message.chatId,
    );
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .78,
        ),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isMe ? palette.filledPrimary : palette.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: l10n.chatPhoto,
              button: id != null,
              child: GestureDetector(
                onTap: id == null
                    ? null
                    : () => Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _PhotoViewer(
                            id: id,
                            onReport: isMe ? null : report,
                          ),
                        ),
                      ),
                child: SizedBox(
                  width: 260,
                  height: 200,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (id == null)
                        Center(child: Text(l10n.chatPhotoUnavailable))
                      else
                        _PhotoImage(
                          id: id,
                          variant: 'thumb',
                          fit: BoxFit.cover,
                        ),
                      PositionedDirectional(
                        end: 7,
                        bottom: 7,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: .48),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (timestamp != null)
                                  Text(
                                    DateFormat.Hm().format(timestamp),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      height: 1.1,
                                      color: Colors.white,
                                    ),
                                  ),
                                if (isMe) ...[
                                  const SizedBox(width: 4),
                                  Semantics(
                                    label: message.readAt != null
                                        ? l10n.chatMessageRead
                                        : l10n.chatMessageSent,
                                    child: Icon(
                                      message.readAt != null
                                          ? LucideIcons.checkCheck
                                          : LucideIcons.check,
                                      size: 13,
                                      color: message.readAt != null
                                          ? ProkatFlowPalette
                                                .readReceiptOnPrimary
                                          : Colors.white,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (message.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(
                  message.content,
                  style: TextStyle(color: isMe ? Colors.white : palette.title),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PhotoImage extends ConsumerWidget {
  const _PhotoImage({
    required this.id,
    required this.variant,
    required this.fit,
  });
  final String id;
  final String variant;
  final BoxFit fit;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(chatPhotoBytesProvider('$id/$variant'))
      .when(
        data: (bytes) => Image.memory(bytes, fit: fit, gaplessPlayback: false),
        loading: () => const Center(
          child: SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.imageOff),
              TextButton(
                onPressed: () =>
                    ref.invalidate(chatPhotoBytesProvider('$id/$variant')),
                child: Text(AppLocalizations.of(context)!.retry),
              ),
            ],
          ),
        ),
      );
}

class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({required this.id, this.onReport});
  final String id;
  final VoidCallback? onReport;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: Theme.of(context).textTheme.titleLarge
          ?.copyWith(color: Colors.white),
      title: Text(AppLocalizations.of(context)!.chatPhoto),
      actions: [
        if (onReport != null)
          IconButton(
            tooltip: AppLocalizations.of(context)!.reportAction,
            onPressed: onReport,
            icon: const Icon(LucideIcons.ellipsisVertical),
          ),
      ],
    ),
    body: Center(
      child: InteractiveViewer(
        minScale: 1,
        maxScale: 5,
        child: _PhotoImage(id: id, variant: 'photo', fit: BoxFit.contain),
      ),
    ),
  );
}
