import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/providers/socket_provider.dart';
import 'package:prokat/core/services/app_socket_service.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/auth/models/auth_session.dart';
import 'package:prokat/features/auth/providers/auth_api_service.dart';
import 'package:prokat/features/auth/providers/auth_notifier.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/auth/providers/auth_secure_storage.dart';
import 'package:prokat/features/auth/providers/auth_state.dart';
import 'package:prokat/features/chat/providers/chat_providers.dart';
import 'package:prokat/features/chat/service/chat_socket_service.dart';
import 'package:prokat/features/notifications/providers/notification_navigation_service_provider.dart';
import 'package:prokat/features/notifications/services/notification_local_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test(
    'logout disconnects the app socket once and clears the pending user route',
    () async {
      late _CountingAppSocket appSocket;
      late _CountingChatSocket chatSocket;
      final storage = _AsyncPendingRouteStorage();
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(_authenticatedAuthNotifier),
          appSocketProvider.overrideWith((ref) {
            appSocket = _CountingAppSocket(ref);
            return appSocket;
          }),
          chatSocketServiceProvider.overrideWith((ref) {
            chatSocket = _CountingChatSocket(ref.watch(appSocketProvider));
            ref.onDispose(chatSocket.dispose);
            return chatSocket;
          }),
          notificationLocalStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      container.read(appStartupProvider);
      container.read(chatSocketServiceProvider);
      expect(storage.pendingRoute, '/chats/user-a');

      await _forceSignedOut(container);

      expect(appSocket.disconnectCalls, 1);
      expect(chatSocket.disposeCalls, 1);
      expect(storage.clearCalls, 1);
      expect(storage.pendingRoute, isNull);
      expect(container.read(authProvider).session, isNull);
    },
  );

  test('overlapping sign-out still disconnects the socket once', () async {
    late _CountingAppSocket appSocket;
    final storage = _AsyncPendingRouteStorage();
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(_authenticatedAuthNotifier),
        appSocketProvider.overrideWith((ref) {
          appSocket = _CountingAppSocket(ref);
          return appSocket;
        }),
        notificationLocalStorageProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(container.dispose);

    container.read(appStartupProvider);
    final first = _forceSignedOut(container);
    final second = _forceSignedOut(container);

    await Future.wait([first, second]);

    expect(appSocket.disconnectCalls, 1);
    expect(storage.clearCalls, 1);
    expect(storage.pendingRoute, isNull);
  });
}

Future<void> _forceSignedOut(ProviderContainer container) {
  final pending = container.read(appStartupProvider.notifier).forceSignedOut();
  return _pumpScheduledFrame().then((_) => pending);
}

Future<void> _pumpScheduledFrame() async {
  await Future<void>.delayed(Duration.zero);
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  binding.handleBeginFrame(Duration.zero);
  binding.handleDrawFrame();
}

AuthNotifier _authenticatedAuthNotifier(Ref ref) {
  return _LocalLogoutAuthNotifier(ref);
}

class _LocalLogoutAuthNotifier extends AuthNotifier {
  _LocalLogoutAuthNotifier(Ref ref)
    : super(ref, AuthApiService(Dio()), AuthSecureStorage()) {
    state = const AuthState(
      session: AuthSession(sessionToken: 'session-user-a'),
    );
  }

  @override
  Future<void> logout() async {
    await clearLocalSession();
  }
}

class _CountingAppSocket extends AppSocketService {
  int disconnectCalls = 0;

  _CountingAppSocket(Ref ref) : super(_UnusedApiClient(), ref);

  @override
  void disconnectSocket() {
    disconnectCalls++;
  }
}

class _CountingChatSocket extends ChatSocketService {
  int disposeCalls = 0;

  _CountingChatSocket(super.appSocket);

  @override
  void dispose() {
    disposeCalls++;
    super.dispose();
  }
}

class _AsyncPendingRouteStorage extends NotificationLocalStorage {
  int clearCalls = 0;
  String? pendingRoute = '/chats/user-a';

  _AsyncPendingRouteStorage() : super(storage: FlutterSecureStorage());

  @override
  Future<String?> readPendingRoute() async => pendingRoute;

  @override
  Future<void> clearPendingRoute() async {
    clearCalls++;
    await Future<void>.delayed(Duration.zero);
    pendingRoute = null;
  }
}

class _UnusedApiClient implements ApiClient {
  @override
  Dio dio = Dio();
}
