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
import 'package:prokat/features/chat/models/chat_list_filter.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/providers/chat_dependencies.dart';
import 'package:prokat/features/chat/providers/chat_list_providers.dart';
import 'package:prokat/features/chat/service/chat_service.dart';
import 'package:prokat/features/workflow/providers/workflow_bootstrap_provider.dart';

import '../../support/fake_app_socket_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('reconnect resyncs chat lists after the first connect', () async {
    final chatService = _FakeChatService([const ChatModel(id: 'chat-1')]);
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

    container.read(workflowBootstrapProvider);
    await container.read(clientChatsProvider.future);
    await _settle();

    final callsAfterStart = chatService.getClientChatsCalls;
    expect(callsAfterStart, 1);

    socket.simulateReconnect();
    await _settle();
    await Future<void>.delayed(const Duration(milliseconds: 500));

    expect(chatService.getClientChatsCalls, greaterThan(callsAfterStart));
  });
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
    ChatListFilter filter = ChatListFilter.active,
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
