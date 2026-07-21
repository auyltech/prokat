import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/notifiers/current_chat_notifier.dart';

final currentChatProvider =
    AsyncNotifierProvider.family<CurrentChatNotifier, ChatModel?, String>(
      CurrentChatNotifier.new,
    );
