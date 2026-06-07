import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/chat/state/chat_provider.dart';
import 'package:prokat/features/chat/state/chat_status.dart';

class SendMessageForm extends ConsumerStatefulWidget {
  final ChatStatus chatStatus;

  const SendMessageForm({super.key, required this.chatStatus});

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

    ref.read(chatProvider.notifier).sendMessage(text);
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
    final isSendingAny = ref.watch(
      chatProvider.select((state) => state.isSendingMessage),
    );

    final isWorkCompleted = widget.chatStatus == ChatStatus.workcompleted;
    final isOrderCanceled = widget.chatStatus == ChatStatus.bookingcancelled;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(color: Colors.transparent),
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
                hintStyle: TextStyle(
                  color: const Color.fromARGB(255, 126, 126, 126),
                  fontWeight: FontWeight.w400,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                    color: Color.fromARGB(255, 199, 230, 255),
                    width: 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                    color: Color.fromARGB(255, 163, 214, 255),
                    width: 1,
                  ),
                ),
                fillColor: Color.fromARGB(131, 182, 223, 255),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: isWorkCompleted || isOrderCanceled
                  ? null
                  : _sendMessage,
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  if (isSendingAny)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
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
    );
  }
}
