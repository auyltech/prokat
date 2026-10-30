import 'dart:async';

import 'package:flutter/material.dart';
import 'package:prokat/features/chat/widgets/chat_photo_message.dart';
import 'package:prokat/features/chat/widgets/compact_message_text.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/utils/chat_message_utils.dart';
import 'package:prokat/features/chat/widgets/booking_message_bubble.dart';
import 'package:prokat/features/chat/widgets/negotiation_message_bubble.dart';
import 'package:prokat/features/chat/widgets/offer_message_bubble.dart';
import 'package:prokat/features/chat/widgets/request_message_bubble.dart';

class MessageBubble extends StatefulWidget {
  final ChatModel? currentChat;
  final ChatMessageModel message;
  final AppMode mode;
  final bool isMe;

  const MessageBubble({
    super.key,
    this.currentChat,
    required this.message,
    required this.mode,
    required this.isMe,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _showTimestamp = false;

  void _toggleTimestamp() {
    setState(() {
      _showTimestamp = !_showTimestamp;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // final specialized = switch (widget.message.type) {
    //   // 'BOOKING' => BookingMessageBubble(booking: ,),
    //   'OFFER' => OfferMessageBubble(message: widget.message),
    //   'REQUEST' => RequestMessageBubble(request: widget.message),
    //   _ => null,
    // };

    final service = widget.message.service;
    if (widget.message.type == 'IMAGE') {
      return ChatPhotoMessage(message: widget.message, isMe: widget.isMe);
    }

    if (service == "REQUEST") {
      return RequestMessageBubble(
        currentChat: widget.currentChat,
        message: widget.message,
        mode: widget.mode,
      );
    } else if (isOfferCardMessage(widget.message)) {
      return OfferMessageBubble(
        message: widget.message,
        isMe: widget.isMe,
        mode: widget.mode,
        currentChat: widget.currentChat,
      );
    } else if (service == "BOOKING") {
      return BookingMessageBubble(
        message: widget.message,
        mode: widget.mode,
        currentChat: widget.currentChat,
      );
    } else if (service == "NEGOTIATION") {
      return NegotiationMessageBubble(
        message: widget.message,
        isMe: widget.isMe,
        mode: widget.mode,
      );
    }

    final palette = ProkatFlowScope.maybeOf(context);
    if (palette != null) {
      return _buildFlowMessage(context, palette);
    }

    // if (specialized != null) {
    //   return GestureDetector(
    //     behavior: HitTestBehavior.opaque,
    //     onTap: _toggleTimestamp,
    //     child: Column(
    //       crossAxisAlignment: CrossAxisAlignment.stretch,
    //       children: [
    //         specialized,
    //         _TimestampRow(
    //           visible: _showTimestamp,
    //           timestamp: widget.message.createdAt,
    //           alignment: Alignment.center,
    //         ),
    //       ],
    //     ),
    //   );
    // }

    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleTimestamp,
        child: Column(
          crossAxisAlignment: widget.isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: EdgeInsets.fromLTRB(16, 12, 16, widget.isMe ? 12 : 12),
              decoration: BoxDecoration(
                color: widget.isMe
                    ? theme.colorScheme.surfaceContainerHigh
                    : theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(widget.isMe ? 16 : 4),
                  bottomRight: Radius.circular(widget.isMe ? 4 : 16),
                ),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: widget.isMe ? 20 : 0),
                    child: Text(
                      widget.message.localizedContent(
                        Localizations.localeOf(context).languageCode,
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.3,
                        color: widget.isMe
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (widget.isMe)
                    Positioned(
                      right: -4,
                      bottom: 0,
                      child: _SendStatusIndicator(
                        isPending: widget.message.isPending,
                        isFailed: widget.message.isFailed,
                        color: Colors.blueGrey,
                      ),
                    ),
                ],
              ),
            ),
            _TimestampRow(
              visible: _showTimestamp,
              timestamp: widget.message.createdAt,
              alignment: widget.isMe
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowMessage(BuildContext context, ProkatFlowPalette palette) {
    final theme = Theme.of(context);
    final content = widget.message.localizedContent(
      Localizations.localeOf(context).languageCode,
    );
    // A losing-tender event is a support message, not an offer or status card.
    final isSystemEvent =
        widget.message.type == 'EVENT' &&
        widget.message.meta?['reason'] != 'NOT_SELECTED';
    if (isSystemEvent) {
      return Align(
        alignment: Alignment.center,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleTimestamp,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.86,
            ),
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: palette.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  content,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.4,
                    color: palette.secondary,
                  ),
                ),
                _TimestampRow(
                  visible: _showTimestamp,
                  timestamp: widget.message.createdAt,
                  alignment: Alignment.center,
                  color: palette.secondary,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final textColor = widget.isMe ? Colors.white : palette.title;
    final metadataColor = widget.isMe
        ? Colors.white.withValues(alpha: 0.72)
        : palette.secondary;
    final timestamp = widget.message.createdAt?.toLocal();

    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleTimestamp,
        child: Column(
          crossAxisAlignment: widget.isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.78,
              ),
              padding: const EdgeInsets.fromLTRB(14, 10, 12, 8),
              decoration: BoxDecoration(
                color: widget.isMe ? palette.filledPrimary : palette.surface,
                border: widget.isMe
                    ? null
                    : Border.all(color: palette.border.withValues(alpha: 0.65)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(widget.isMe ? 18 : 5),
                  bottomRight: Radius.circular(widget.isMe ? 5 : 18),
                ),
              ),
              child: CompactMessageText(
                text: content,
                style: (theme.textTheme.bodyMedium ?? const TextStyle())
                    .copyWith(
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                      color: textColor,
                    ),
                metadata: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (timestamp != null)
                      Text(
                        DateFormat.Hm().format(timestamp),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: metadataColor,
                        ),
                      ),
                    if (widget.isMe) ...[
                      const SizedBox(width: 4),
                      _SendStatusIndicator(
                        isPending: widget.message.isPending,
                        isFailed: widget.message.isFailed,
                        color: metadataColor,
                        isRead: widget.message.readAt != null,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _TimestampRow(
              visible: _showTimestamp,
              timestamp: widget.message.createdAt,
              alignment: widget.isMe
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              color: palette.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SendStatusIndicator extends StatefulWidget {
  final bool isPending;
  final bool isFailed;
  final Color color;
  final bool isRead;

  const _SendStatusIndicator({
    required this.isPending,
    required this.isFailed,
    required this.color,
    this.isRead = false,
  });

  @override
  State<_SendStatusIndicator> createState() => _SendStatusIndicatorState();
}

class _SendStatusIndicatorState extends State<_SendStatusIndicator>
    with SingleTickerProviderStateMixin {
  static const int _spinCount = 3;
  late final AnimationController _controller;
  bool _hasFinishedSpins = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _updateAnimation();
  }

  @override
  void didUpdateWidget(covariant _SendStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPending != widget.isPending ||
        oldWidget.isFailed != widget.isFailed) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    if (!mounted) {
      return;
    }

    if (widget.isFailed) {
      _controller.stop();
      _hasFinishedSpins = true;
      return;
    }

    if (widget.isPending) {
      _hasFinishedSpins = false;
      _controller.reset();
      unawaited(_controller.repeat());

      Future<void>.delayed(_controller.duration! * _spinCount, () {
        if (!mounted) {
          return;
        }
        if (!widget.isPending || widget.isFailed) {
          return;
        }
        setState(() {
          _hasFinishedSpins = true;
        });
        _controller.stop();
      });

      return;
    }

    _controller.stop();
    _hasFinishedSpins = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isFailed) {
      return Icon(Icons.error_outline_rounded, size: 16, color: widget.color);
    }

    if (widget.isPending && !_hasFinishedSpins) {
      return RotationTransition(
        turns: _controller,
        child: Icon(Icons.sync_rounded, size: 16, color: widget.color),
      );
    }

    if (widget.isPending) {
      return Icon(Icons.schedule_rounded, size: 16, color: widget.color);
    }

    return Semantics(
      label: widget.isRead
          ? AppLocalizations.of(context)!.chatMessageRead
          : AppLocalizations.of(context)!.chatMessageSent,
      child: Icon(
        widget.isRead ? Icons.done_all_rounded : Icons.check_rounded,
        size: 16,
        color: widget.isRead
            ? ProkatFlowPalette.readReceiptOnPrimary
            : widget.color,
        shadows: widget.isRead
            ? const [Shadow(color: Color(0x5580FFD1), blurRadius: 4)]
            : null,
      ),
    );
  }
}

class _TimestampRow extends StatelessWidget {
  final bool visible;
  final DateTime? timestamp;
  final Alignment alignment;
  final Color? color;

  const _TimestampRow({
    required this.visible,
    required this.timestamp,
    required this.alignment,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible || timestamp == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final now = DateTime.now();
    final localTimestamp = timestamp!.toLocal();

    final isToday =
        now.year == localTimestamp.year &&
        now.month == localTimestamp.month &&
        now.day == localTimestamp.day;

    final timeText = isToday
        ? DateFormat.Hm().format(localTimestamp)
        : DateFormat('dd MMM • HH:mm').format(localTimestamp);

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 2),
        child: Text(
          timeText,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color ?? theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }
}
