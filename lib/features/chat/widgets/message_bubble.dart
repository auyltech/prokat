import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/chat/widgets/booking_message_bubble.dart';
import 'package:prokat/features/chat/widgets/negotiation_message_bubble.dart';
import 'package:prokat/features/chat/widgets/offer_message_bubble.dart';
import 'package:prokat/features/chat/widgets/request_message_bubble.dart';

class MessageBubble extends StatefulWidget {
  final ChatMessageModel message;
  final AppMode mode;
  final bool isMe;

  const MessageBubble({
    super.key,
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

    if (service == "REQUEST") {
      return RequestMessageBubble(message: widget.message, mode: widget.mode);
    } else if (service == "OFFER") {
      return OfferMessageBubble(message: widget.message, isMe: widget.isMe);
    } else if (service == "BOOKING") {
      return BookingMessageBubble(message: widget.message, mode: widget.mode);
    } else if (service == "NEGOTIATION") {
      return NegotiationMessageBubble(
        message: widget.message,
        isMe: widget.isMe,
      );
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
                gradient: widget.isMe
                    ? LinearGradient(
                        colors: [
                          const Color.fromARGB(255, 222, 246, 255),
                          const Color.fromARGB(255, 222, 246, 255),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: widget.isMe
                    ? theme.cardColor
                    : theme.dividerColor.withValues(alpha: 0.1),
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
                      widget.message.content,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: widget.isMe
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ),
                  if (widget.isMe)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: _SendStatusIndicator(
                        isPending: widget.message.isPending,
                        isFailed: widget.message.isFailed,
                        color: Colors.black,
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
}

class _SendStatusIndicator extends StatefulWidget {
  final bool isPending;
  final bool isFailed;
  final Color color;

  const _SendStatusIndicator({
    required this.isPending,
    required this.isFailed,
    required this.color,
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
      _controller
        ..reset()
        ..repeat();

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

    return Icon(Icons.check_rounded, size: 16, color: widget.color);
  }
}

class _TimestampRow extends StatelessWidget {
  final bool visible;
  final DateTime? timestamp;
  final Alignment alignment;

  const _TimestampRow({
    required this.visible,
    required this.timestamp,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible || timestamp == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final now = DateTime.now();

    final isToday =
        now.year == timestamp!.year &&
        now.month == timestamp!.month &&
        now.day == timestamp!.day;

    final timeText = isToday
        ? DateFormat.Hm().format(timestamp!)
        : DateFormat('dd MMM • HH:mm').format(timestamp!);

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 2),
        child: Text(
          timeText,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }
}
