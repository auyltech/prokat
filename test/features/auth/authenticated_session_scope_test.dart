import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/features/auth/models/auth_session.dart';
import 'package:prokat/features/auth/models/user_model.dart';
import 'package:prokat/features/auth/providers/auth_api_service.dart';
import 'package:prokat/features/auth/providers/authenticated_session_scope.dart';
import 'package:prokat/features/auth/providers/auth_notifier.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/auth/providers/auth_secure_storage.dart';
import 'package:prokat/features/auth/providers/auth_state.dart';
import 'package:prokat/features/chat/providers/chat_providers.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/chat/service/chat_socket_service.dart';
import 'package:prokat/features/chat/service/chat_service.dart';
import 'package:prokat/features/bookings/models/query_result.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/offers/models/offer_query.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/offers/state/offers_service.dart';
import 'package:prokat/features/user/state/client_profile_provider.dart';
import 'package:prokat/features/user/models/user_profile_model.dart';
import 'package:prokat/features/user/state/client_profile_service.dart';

class _TestApiClient implements ApiClient {
  _TestApiClient(this.dio);

  @override
  Dio dio;
}

void main() {
  test('session scope follows user identity without exposing tokens', () {
    late _MutableAuthNotifier auth;
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) {
          auth = _MutableAuthNotifier(ref);
          return auth;
        }),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(authenticatedSessionScopeKeyProvider), isNull);

    auth.setSession(_session(userId: ' user-a ', token: 'token-a'));
    const userA = AuthenticatedSessionScopeKey.forUser('user-a', generation: 1);
    expect(container.read(authenticatedSessionScopeKeyProvider), userA);

    auth.setSession(_session(userId: 'user-a', token: 'rotated-token-a'));
    expect(container.read(authenticatedSessionScopeKeyProvider), userA);

    auth.setSession(null);
    expect(container.read(authenticatedSessionScopeKeyProvider), isNull);

    auth.setSession(_session(userId: 'user-a', token: 'new-login-token-a'));
    final userANewLogin = container.read(authenticatedSessionScopeKeyProvider);
    expect(userANewLogin, isNot(userA));

    auth.setSession(_session(userId: 'user-b', token: 'token-b'));
    expect(
      container.read(authenticatedSessionScopeKeyProvider),
      const AuthenticatedSessionScopeKey.forUser('user-b', generation: 3),
    );

    auth.setSession(const AuthSession(sessionToken: 'fallback-secret'));
    final fallback = container.read(authenticatedSessionScopeKeyProvider);
    expect(
      fallback,
      const AuthenticatedSessionScopeKey.forSessionToken(
        'fallback-secret',
        generation: 4,
      ),
    );
    expect(fallback.toString(), isNot(contains('fallback-secret')));
  });

  test('profile scope clears on logout and reloads for user B', () async {
    const userA = AuthenticatedSessionScopeKey.forUser('user-a');
    const userB = AuthenticatedSessionScopeKey.forUser('user-b');
    final testSession = StateProvider<AuthenticatedSessionScopeKey?>(
      (ref) => userA,
    );
    var responseName = 'A';
    var calls = 0;
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          calls++;
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'data': {'firstName': responseName, 'role': 'CLIENT'},
              },
            ),
          );
        },
      ),
    );
    final container = ProviderContainer(
      overrides: [
        authenticatedSessionScopeKeyProvider.overrideWith(
          (ref) => ref.watch(testSession),
        ),
        clientProfileServiceProvider.overrideWithValue(
          ClientProfileService(_TestApiClient(dio)),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      (await container.read(clientProfileProvider.future))?.firstName,
      'A',
    );
    expect(calls, 1);

    container.read(testSession.notifier).state = null;
    await _settle();

    expect(await container.read(clientProfileProvider.future), isNull);
    expect(calls, 1, reason: 'guest rebuild must not call /user/profile');

    responseName = 'B';
    container.read(testSession.notifier).state = userB;
    await _settle();

    expect(
      (await container.read(clientProfileProvider.future))?.firstName,
      'B',
    );
    expect(calls, 2);
  });

  test('guest profile refresh never calls the protected API', () async {
    final service = _CountingClientProfileService();
    final container = ProviderContainer(
      overrides: [
        authenticatedSessionScopeKeyProvider.overrideWithValue(null),
        clientProfileServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(clientProfileProvider.future), isNull);
    await container.read(clientProfileProvider.notifier).refresh();

    expect(service.calls, 0);
    expect(container.read(clientProfileProvider).value, isNull);
  });

  test('late user A profile cannot overwrite user B state', () async {
    const userA = AuthenticatedSessionScopeKey.forUser('user-a');
    const userB = AuthenticatedSessionScopeKey.forUser('user-b');
    final testSession = StateProvider<AuthenticatedSessionScopeKey?>(
      (ref) => userA,
    );
    final service = _ControlledClientProfileService();
    final container = ProviderContainer(
      overrides: [
        authenticatedSessionScopeKeyProvider.overrideWith(
          (ref) => ref.watch(testSession),
        ),
        clientProfileServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    final subscription = container.listen(
      clientProfileProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    final userAFuture = container.read(clientProfileProvider.future);
    await service.waitForCalls(1);

    container.read(testSession.notifier).state = null;
    await _settle();
    expect(await container.read(clientProfileProvider.future), isNull);

    container.read(testSession.notifier).state = userB;
    await service.waitForCalls(2);
    service.complete(1, _profile('B'));
    expect(
      (await container.read(clientProfileProvider.future))?.firstName,
      'B',
    );
    expect(container.read(locationProvider).city, 'city-B');

    service.complete(0, _profile('A'));
    await userAFuture;
    await _settle();

    expect(container.read(clientProfileProvider).value?.firstName, 'B');
    expect(container.read(locationProvider).city, 'city-B');
  });

  test('guest chat operations stay local without opening a socket', () async {
    var apiCalls = 0;
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          apiCalls++;
          handler.reject(
            DioException(requestOptions: options, message: 'unexpected call'),
          );
        },
      ),
    );
    final container = ProviderContainer(
      overrides: [
        authenticatedSessionScopeKeyProvider.overrideWithValue(null),
        chatServiceProvider.overrideWithValue(ChatService(_TestApiClient(dio))),
      ],
    );
    addTearDown(container.dispose);
    final messages = chatMessagesProvider('chat-1');

    expect((await container.read(messages.future)).items, isEmpty);
    await container.read(messages.notifier).refresh();
    await container.read(messages.notifier).refreshIfStale();
    await container.read(messages.notifier).loadMore();
    expect(await container.read(messages.notifier).sendMessage('hello'), false);

    expect(apiCalls, 0);
  });

  test(
    'realtime message is buffered while a new session loads chat history',
    () async {
      const userB = AuthenticatedSessionScopeKey.forUser('user-b');
      final testSession = StateProvider<AuthenticatedSessionScopeKey?>(
        (ref) => null,
      );
      final chatService = _ControlledChatService();
      final socket = _FakeChatSocketService();
      final container = ProviderContainer(
        overrides: [
          authenticatedSessionScopeKeyProvider.overrideWith(
            (ref) => ref.watch(testSession),
          ),
          chatServiceProvider.overrideWithValue(chatService),
          chatSocketServiceProvider.overrideWithValue(socket),
        ],
      );
      addTearDown(container.dispose);
      final messages = chatMessagesProvider('chat-1');
      final subscription = container.listen(
        messages,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      expect((await container.read(messages.future)).items, isEmpty);
      expect(socket.joinCalls, 0);

      container.read(testSession.notifier).state = userB;
      await socket.waitForJoinCalls(1);
      await chatService.waitForRequests(1);

      socket.emit(
        const ChatMessageModel(
          id: 'message-b',
          chatId: 'chat-1',
          senderId: 'user-b',
          content: 'hello from realtime',
        ),
      );
      chatService.completeEmpty(0);

      final loaded = await container.read(messages.future);
      expect(loaded.items.map((message) => message.id), contains('message-b'));
    },
  );

  test('family query never fetches as guest and is scoped per user', () async {
    const userA = AuthenticatedSessionScopeKey.forUser('user-a');
    const userB = AuthenticatedSessionScopeKey.forUser('user-b');
    final testSession = StateProvider<AuthenticatedSessionScopeKey?>(
      (ref) => null,
    );
    var responseOwner = 'A';
    var calls = 0;
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          calls++;
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'data': {
                  'items': [_offer('offer-$responseOwner')],
                  'page': 1,
                  'itemsPerPage': 20,
                  'count': 1,
                },
              },
            ),
          );
        },
      ),
    );
    final container = ProviderContainer(
      overrides: [
        authenticatedSessionScopeKeyProvider.overrideWith(
          (ref) => ref.watch(testSession),
        ),
        offersServiceProvider.overrideWithValue(
          OffersService(_TestApiClient(dio)),
        ),
      ],
    );
    addTearDown(container.dispose);
    const query = OfferQuery.active();

    expect(
      (await container.read(clientOffersProvider(query).future)).items,
      isEmpty,
    );
    await container.read(clientOffersProvider(query).notifier).refresh();
    await container.read(clientOffersProvider(query).notifier).refreshIfStale();
    await container.read(clientOffersProvider(query).notifier).loadMore();
    container.invalidate(clientOffersProvider);
    expect(
      (await container.read(clientOffersProvider(query).future)).items,
      isEmpty,
    );
    expect(calls, 0, reason: 'guest query operations must remain local');

    container.read(testSession.notifier).state = userA;
    await _settle();
    expect(
      (await container.read(clientOffersProvider(query).future))
          .items
          .single
          .id,
      'offer-A',
    );

    container.read(testSession.notifier).state = null;
    await _settle();
    expect(
      (await container.read(clientOffersProvider(query).future)).items,
      isEmpty,
    );
    expect(calls, 1);

    responseOwner = 'B';
    container.read(testSession.notifier).state = userB;
    await _settle();
    expect(
      (await container.read(clientOffersProvider(query).future))
          .items
          .single
          .id,
      'offer-B',
    );
    expect(calls, 2);
  });
}

AuthSession _session({required String userId, required String token}) {
  return AuthSession(
    sessionToken: token,
    user: UserModel(id: userId, role: UserRole.client),
  );
}

UserProfileModel _profile(String owner) {
  return UserProfileModel(firstName: owner, city: 'city-$owner');
}

class _MutableAuthNotifier extends AuthNotifier {
  _MutableAuthNotifier(Ref ref)
    : super(ref, AuthApiService(Dio()), AuthSecureStorage());

  void setSession(AuthSession? session) {
    state = AuthState(session: session);
  }
}

class _CountingClientProfileService extends ClientProfileService {
  _CountingClientProfileService() : super(_TestApiClient(Dio()));

  int calls = 0;

  @override
  Future<UserProfileModel?> getUserProfile() async {
    calls++;
    return _profile('unexpected');
  }
}

class _ControlledClientProfileService extends ClientProfileService {
  _ControlledClientProfileService() : super(_TestApiClient(Dio()));

  final List<Completer<UserProfileModel?>> _requests = [];

  @override
  Future<UserProfileModel?> getUserProfile() {
    final request = Completer<UserProfileModel?>();
    _requests.add(request);
    return request.future;
  }

  Future<void> waitForCalls(int count) async {
    for (var attempt = 0; attempt < 20; attempt++) {
      if (_requests.length >= count) return;
      await Future<void>.delayed(Duration.zero);
    }
    expect(_requests.length, count);
  }

  void complete(int index, UserProfileModel profile) {
    _requests[index].complete(profile);
  }
}

class _ControlledChatService extends ChatService {
  _ControlledChatService() : super(_TestApiClient(Dio()));

  final List<Completer<ApiResponse<QueryResult<ChatMessageModel>>>> _requests =
      [];

  @override
  Future<ApiResponse<QueryResult<ChatMessageModel>>> getMessages({
    required String chatId,
    int page = 1,
    int itemsPerPage = 50,
  }) {
    final request = Completer<ApiResponse<QueryResult<ChatMessageModel>>>();
    _requests.add(request);
    return request.future;
  }

  Future<void> waitForRequests(int count) async {
    for (var attempt = 0; attempt < 20; attempt++) {
      if (_requests.length >= count) return;
      await Future<void>.delayed(Duration.zero);
    }
    expect(_requests.length, count);
  }

  void completeEmpty(int index) {
    _requests[index].complete(
      ApiResponse.success(
        const QueryResult<ChatMessageModel>(
          items: [],
          page: 1,
          itemsPerPage: 50,
          count: 0,
        ),
      ),
    );
  }
}

class _FakeChatSocketService implements ChatSocketService {
  void Function(ChatMessageModel)? _handler;
  int joinCalls = 0;

  @override
  Future<void> joinChat(String chatId) async {
    joinCalls++;
  }

  @override
  Future<void> leaveChat(String chatId) async {}

  @override
  void Function() onNewMessage(void Function(ChatMessageModel) handler) {
    _handler = handler;
    return () {
      if (identical(_handler, handler)) _handler = null;
    };
  }

  void emit(ChatMessageModel message) => _handler?.call(message);

  Future<void> waitForJoinCalls(int count) async {
    for (var attempt = 0; attempt < 20; attempt++) {
      if (joinCalls >= count) return;
      await Future<void>.delayed(Duration.zero);
    }
    expect(joinCalls, count);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _offer(String id) => {
  'id': id,
  'status': 'CREATED',
  'requestId': 'request-1',
  'chatId': 'chat-1',
  'equipmentId': 'equipment-1',
  'price': 100,
  'createdAt': '2026-01-01T00:00:00.000Z',
};

Future<void> _settle() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
