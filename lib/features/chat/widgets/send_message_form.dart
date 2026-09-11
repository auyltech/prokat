import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/chat/widgets/booking_actions/chat_action_bar.dart';
import 'package:prokat/features/chat/providers/chat_providers.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/state/chat_status_detail.dart';
import 'package:prokat/features/chat/utils/get_chat_status.dart';
import 'package:prokat/features/chat/utils/owner_offline_chat_lock.dart';
import 'package:prokat/features/owner/owner_offline_guard.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class SendMessageForm extends ConsumerStatefulWidget {
  final String chatId;

  final ChatStatusDetail chatStatus;
  final AppMode mode;
  final ChatType type;
  final ChatModel? currentChat;
  final String actionBarTitle;

  const SendMessageForm({
    super.key,
    required this.chatId,
    required this.mode,
    required this.chatStatus,
    this.type = ChatType.direct,
    this.currentChat,
    this.actionBarTitle = '',
  });

  @override
  ConsumerState<SendMessageForm> createState() => _SendMessageFormState();
}

class _SendMessageFormState extends ConsumerState<SendMessageForm> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _goingOnline = false;

  bool _isLockedFor(SendMessageForm target) {
    return isChatInputLocked(
      target.chatStatus,
      threadStatus: target.currentChat?.status,
      chatType: target.type,
    );
  }

  void _dismissKeyboard() {
    _focusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isLockedFor(widget)) {
        _dismissKeyboard();
      }
    });
  }

  @override
  void didUpdateWidget(covariant SendMessageForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nowLocked =
        _isLockedFor(widget) ||
        isDirectBookingOwnerOfflineLock(
          ref: ref,
          mode: widget.mode,
          chat: widget.currentChat,
        );
    final wasLocked =
        _isLockedFor(oldWidget) ||
        isDirectBookingOwnerOfflineLock(
          ref: ref,
          mode: oldWidget.mode,
          chat: oldWidget.currentChat,
        );
    if (nowLocked && !wasLocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _dismissKeyboard();
        }
      });
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }

    unawaited(
      ref.read(chatMessagesProvider(widget.chatId).notifier).sendMessage(text),
    );

    _controller.clear();
  }

  Future<void> _becomeOnlineFromBanner() async {
    if (_goingOnline) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() => _goingOnline = true);
    final preCheck = ownerGoOnlineBlockReason(ref);
    if (preCheck != OwnerGoOnlineBlockReason.none) {
      if (mounted) {
        AppSnackBar.show(
          message: ownerGoOnlineBlockMessage(l10n: l10n, reason: preCheck),
          isError: true,
        );
        setState(() => _goingOnline = false);
      }
      return;
    }

    final ok = await requestOwnerGoOnline(ref);
    if (!mounted) return;

    if (!ok) {
      AppSnackBar.show(
        message: ownerGoOnlineFailureMessage(
          ref: ref,
          l10n: l10n,
          preCheck: OwnerGoOnlineBlockReason.none,
        ),
        isError: true,
      );
    }

    setState(() => _goingOnline = false);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Widget _roundedPanel({required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.80),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.4),
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: child,
        ),
      ),
    );
  }

  Widget _ownerOfflineBanner(AppLocalizations l10n, ThemeData theme) {
    if (widget.mode == AppMode.clientMode) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Text(
          l10n.ownerOfflineChatClientBanner,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.ownerOfflineChatOwnerBanner,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: _goingOnline ? null : _becomeOnlineFromBanner,
            child: _goingOnline
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.becomeOnline),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (widget.mode == AppMode.ownerMode) {
      ref.watch(
        ownerProfileProvider.select((async) => async.valueOrNull?.onlineStatus),
      );
    }

    final messages = ref.watch(chatMessagesProvider(widget.chatId));
    final isSendingAny =
        messages.valueOrNull?.items.any((e) => e.isPending) ?? false;

    final isLocked = _isLockedFor(widget);
    final offlineLocked = isDirectBookingOwnerOfflineLock(
      ref: ref,
      mode: widget.mode,
      chat: widget.currentChat,
    );
    final showActions =
        widget.currentChat != null &&
        chatHasVisibleActions(
          status: widget.chatStatus,
          mode: widget.mode,
          threadStatus: widget.currentChat?.status,
          chatType: widget.type,
        );

    if (isLocked && !showActions) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: const BoxDecoration(color: Colors.transparent),
        child: SafeArea(
          top: false,
          child: Text(
            l10n.chatLocked,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      );
    }

    if (isLocked && showActions) {
      return _roundedPanel(
        child: ChatActionBar(
          currentChat: widget.currentChat!,
          chatStatus: widget.chatStatus,
          mode: widget.mode,
          actionBarTitle: widget.actionBarTitle,
        ),
      );
    }

    if (offlineLocked) {
      return _roundedPanel(child: _ownerOfflineBanner(l10n, theme));
    }

    return _roundedPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showActions) ...[
            ChatActionBar(
              currentChat: widget.currentChat!,
              chatStatus: widget.chatStatus,
              mode: widget.mode,
              actionBarTitle: widget.actionBarTitle,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Divider(
                height: 1,
                thickness: 1,
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.typeMessageHint,
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
                        borderSide: BorderSide(
                          color: theme.dividerColor.withValues(alpha: 0.4),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: theme.dividerColor.withValues(alpha: 0.4),
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
                    onPressed: _sendMessage,
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        if (isSendingAny)
                          const Positioned(
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
          ),
        ],
      ),
    );
  }
}
