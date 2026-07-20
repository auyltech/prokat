import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/chat/providers/chat_providers.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/state/chat_status_detail.dart';
import 'dart:ui';

class SendMessageForm extends ConsumerStatefulWidget {
  final String chatId;

  final ChatStatusDetail chatStatus;
  final AppMode mode;
  final ChatType type;

  const SendMessageForm({
    super.key,
    required this.chatId,
    required this.mode,
    required this.chatStatus,
    this.type = ChatType.direct,
  });

  @override
  ConsumerState<SendMessageForm> createState() => _SendMessageFormState();
}

class _SendMessageFormState extends ConsumerState<SendMessageForm> {
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }

    ref.read(chatMessagesProvider(widget.chatId).notifier).sendMessage(text);

    // if (widget.type == ChatType.support) {
    //   ref.read(chatProvider.notifier).sendSupportMessage(text, widget.mode);
    // } else {
    //   ref.read(chatProvider.notifier).sendMessage(text);
    // }

    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final messages = ref.watch(chatMessagesProvider(widget.chatId));
    final isSendingAny =
        messages.valueOrNull?.items.any((e) => e.isPending) ?? false;

    final isWorkCompleted = widget.chatStatus == ChatStatusDetail.workcompleted;
    final isOrderCanceled =
        widget.chatStatus == ChatStatusDetail.bookingcancelled;
    final isReviewed = widget.chatStatus == ChatStatusDetail.bookingreviewed;

    if (isWorkCompleted || isOrderCanceled || isReviewed) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(color: Colors.transparent),
        child: SafeArea(
          top: false,
          child: Text(
            'Chat locked',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      );
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor.withValues(alpha: 0.80),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(
                        color: Color.fromARGB(255, 0, 70, 128),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: const TextStyle(
                          color: Color.fromARGB(255, 126, 126, 126),
                          fontWeight: FontWeight.w400,
                        ),
                        filled: true,
                        fillColor: theme.scaffoldBackgroundColor.withValues(
                          alpha: 0.85,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.4,
                            ),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Material(
                    color: theme.colorScheme.primary,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: IconButton(
                      onPressed: isWorkCompleted || isOrderCanceled
                          ? null
                          : _sendMessage,
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),

                          if (isSendingAny)
                            Positioned(
                              right: -4,
                              top: -4,
                              child: SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
