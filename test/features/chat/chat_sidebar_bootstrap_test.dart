import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/core/providers/socket_provider.dart';
import 'package:prokat/features/auth/models/auth_session.dart';
import 'package:prokat/features/auth/models/user_model.dart';
import 'package:prokat/features/auth/providers/auth_api_service.dart';
import 'package:prokat/features/auth/providers/auth_notifier.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/auth/providers/auth_secure_storage.dart';
import 'package:prokat/features/auth/providers/auth_state.dart';
import 'package:prokat/features/bookings/models/query_result.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/providers/chat_dependencies.dart';
import 'package:prokat/features/chat/providers/chat_list_providers.dart';
import 'package:prokat/features/chat/providers/chat_sidebar_bootstrap_provider.dart';
import 'package:prokat/features/chat/service/chat_service.dart';

import '../../support/fake_app_socket_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test(
    'sidebar update patches last message on the cached client list',
    () async {
      final chatService = _FakeChatService([
        const ChatModel(id: 'chat-1', newMessagesCount: 0),
        const ChatModel(id: 'chat-2'),
      ]);
      late FakeAppSocketService socket;
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(_authenticatedAuthNotifier),
          chatServiceProvider.overrideWithValue(chatService),
          appSocketProvider.overrideWith((ref) {
            socket = FakeAppSocketService(ref);
            return socket;
          }),
        ],
      );
      addTearDown(container.dispose);

      container.read(chatSidebarBootstrapProvider);
      await container.read(clientChatsProvider.future);
      await _settle();

      socket.emitIncoming('chat:sidebar:update', {
        'chatId': 'chat-1',
        'lastMessage': {
          'id': 'msg-9',
          'senderId': 'user-b',
          'content': 'from sidebar',
          'createdAt': '2026-01-01T12:00:00.000Z',
        },
      });

      final chats = container.read(clientChatsProvider).value!.items;
      expect(chats.first.id, 'chat-1');
      expect(chats.first.lastMessage?.content, 'from sidebar');
      expect(chats.first.newMessagesCount, 1);
      expect(chatService.getClientChatsCalls, 1);
    },
  );

  test(
    'sidebar update for an unknown chat refreshes the cached list',
    () async {
      final chatService = _FakeChatService([const ChatModel(id: 'chat-2')]);
      late FakeAppSocketService socket;
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(_authenticatedAuthNotifier),
          chatServiceProvider.overrideWithValue(chatService),
          appSocketProvider.overrideWith((ref) {
            socket = FakeAppSocketService(ref);
            return socket;
          }),
        ],
      );
      addTearDown(container.dispose);

      container.read(chatSidebarBootstrapProvider);
      await container.read(clientChatsProvider.future);
      chatService.chats = [
        const ChatModel(id: 'chat-1'),
        const ChatModel(id: 'chat-2'),
      ];

      socket.emitIncoming('chat:sidebar:update', {
        'chatId': 'chat-1',
        'lastMessage': {
          'id': 'msg-1',
          'senderId': 'user-b',
          'content': 'new thread',
          'createdAt': '2026-01-01T12:00:00.000Z',
        },
      });
      await _settle();

      expect(chatService.getClientChatsCalls, 2);
      final ids = container
          .read(clientChatsProvider)
          .value!
          .items
          .map((chat) => chat.id)
          .toList();
      expect(ids, contains('chat-1'));
    },
  );
}

AuthNotifier _authenticatedAuthNotifier(Ref ref) {
  return _LocalAuthNotifier(ref);
}

class _LocalAuthNotifier extends AuthNotifier {
  _LocalAuthNotifier(Ref ref)
    : super(ref, AuthApiService(Dio()), AuthSecureStorage()) {
    state = const AuthState(
      session: AuthSession(
        sessionToken: 'session-user-me',
        user: UserModel(id: 'user-me', role: UserRole.client),
      ),
    );
  }
}

class _FakeChatService extends ChatService {
  _FakeChatService(this.chats) : super(_TestApiClient(Dio()));

  List<ChatModel> chats;
  int getClientChatsCalls = 0;

  @override
  Future<ApiResponse<QueryResult<ChatModel>>> getClientChats({
    int page = 1,
    int itemsPerPage = 20,
  }) async {
    getClientChatsCalls++;
    return ApiResponse.success(
      QueryResult(
        items: List<ChatModel>.from(chats),
        page: page,
        itemsPerPage: itemsPerPage,
        count: chats.length,
      ),
    );
  }
}

class _TestApiClient implements ApiClient {
  _TestApiClient(this.dio);

  @override
  Dio dio;
}

Future<void> _settle() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
