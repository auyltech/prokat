import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/bookings/models/query_result.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/chat/providers/chat_providers.dart';
import 'package:prokat/features/chat/service/chat_send_rejected.dart';
import 'package:prokat/features/chat/service/chat_service.dart';
import 'package:prokat/features/chat/service/chat_socket_service.dart';
import 'package:prokat/features/user_safety/user_safety_error_message.dart';

import '../user_safety/user_safety_test_support.dart';

const _history = ChatMessageModel(
  id: 'message-1',
  chatId: 'chat-1',
  senderId: 'user-other',
  content: 'Hello',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'app_locale': 'ru'});
  });

  test(
    'CONTENT_NOT_ALLOWED ack marks only the new message failed and keeps the thread usable',
    () async {
      final socket = _RejectingChatSocketService();
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(signedInAuth),
          chatServiceProvider.overrideWithValue(_HistoryChatService()),
          chatSocketServiceProvider.overrideWithValue(socket),
        ],
      );
      addTearDown(container.dispose);
      final messages = chatMessagesProvider('chat-1');
      final subscription = container.listen(messages, (_, _) {});
      addTearDown(subscription.close);
      await container.read(messages.future);

      socket.rejectWith = contentNotAllowedErrorCode;
      final sent = await container
          .read(messages.notifier)
          .sendMessage('prohibited text');

      expect(sent, isFalse);
      final items = container.read(messages).requireValue.items;
      expect(items.map((item) => item.id), contains('message-1'));
      final rejected = items.singleWhere(
        (item) => item.content == 'prohibited text',
      );
      expect(rejected.isFailed, isTrue);
      expect(rejected.isPending, isFalse);
      expect(items.where((item) => item.isFailed), hasLength(1));

      socket.rejectWith = null;
      expect(
        await container.read(messages.notifier).sendMessage('normal text'),
        isTrue,
      );
      expect(socket.sent, ['prohibited text', 'normal text']);
    },
  );
}

class _TestApiClient implements ApiClient {
  _TestApiClient(this.dio);

  @override
  Dio dio;
}

class _HistoryChatService extends ChatService {
  _HistoryChatService() : super(_TestApiClient(Dio()));

  @override
  Future<ApiResponse<QueryResult<ChatMessageModel>>> getMessages({
    required String chatId,
    int page = 1,
    int itemsPerPage = 50,
  }) async {
    return ApiResponse.success(
      const QueryResult<ChatMessageModel>(
        items: [_history],
        page: 1,
        itemsPerPage: 50,
        count: 1,
      ),
    );
  }
}

class _RejectingChatSocketService implements ChatSocketService {
  String? rejectWith;
  final List<String> sent = [];

  @override
  Future<void> joinChat(String chatId) async {}

  @override
  Future<void> leaveChat(String chatId) async {}

  @override
  void Function() onNewMessage(void Function(ChatMessageModel) handler) {
    return () {};
  }

  @override
  Future<ChatMessageModel?> sendMessage({
    required String chatId,
    required String message,
    required String type,
    String? clientTempId,
  }) async {
    sent.add(message);
    final code = rejectWith;
    if (code != null) {
      throw ChatSendRejected(
        code,
        'The text contains content that is not allowed',
      );
    }
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
