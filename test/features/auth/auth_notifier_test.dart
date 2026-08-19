import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/user/models/user_profile_model.dart';
import 'package:prokat/features/user/state/client_profile_notifier.dart';
import 'package:prokat/features/user/state/client_profile_provider.dart';

class _StubAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) respond;

  _StubAdapter(this.respond);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => respond(options);

  @override
  void close({bool force = false}) {}
}

Dio _stubDio(
  int statusCode,
  Map<String, dynamic> body, {
  Map<String, List<String>> headers = const {},
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://example.test',
      responseType: ResponseType.json,
      validateStatus: (status) => status != null && status < 600,
    ),
  );
  dio.httpClientAdapter = _StubAdapter(
    (_) => ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        ...headers,
      },
    ),
  );
  return dio;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('successful request persists backend resend cooldown', () async {
    final container = ProviderContainer(
      overrides: [
        dioProvider.overrideWithValue(
          _stubDio(202, {'code': 'OTP_ACCEPTED', 'resendAfterSeconds': 90}),
        ),
      ],
    );
    addTearDown(container.dispose);

    final success = await container
        .read(authProvider.notifier)
        .requestOtp('+77001234567');
    final state = container.read(authProvider);

    expect(success, isTrue);
    expect(state.otpPhone, '+77001234567');
    expect(state.otpCooldownPhone, '+77001234567');
    expect(
      state.otpRetryAt!.difference(DateTime.now()).inSeconds,
      inInclusiveRange(58, 60),
    );
  });

  test('429 remains before OTP state and uses Retry-After', () async {
    final container = ProviderContainer(
      overrides: [
        dioProvider.overrideWithValue(
          _stubDio(
            429,
            {'code': 'RATE_LIMITED', 'message': 'Please try again later'},
            headers: {
              'retry-after': ['45'],
            },
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final success = await container
        .read(authProvider.notifier)
        .requestOtp('+77001234567');
    final state = container.read(authProvider);

    expect(success, isFalse);
    expect(state.otpPhone, isNull);
    expect(state.errorCode, 'RATE_LIMITED');
    expect(state.otpCooldownPhone, '+77001234567');
    expect(
      state.otpRetryAt!.difference(DateTime.now()).inSeconds,
      inInclusiveRange(43, 45),
    );
  });

  test('error body retryAfterSeconds updates the cooldown state', () async {
    final container = ProviderContainer(
      overrides: [
        dioProvider.overrideWithValue(
          _stubDio(429, {
            'code': 'RATE_LIMITED',
            'message': 'Please try again later',
            'retryAfterSeconds': 75,
          }),
        ),
      ],
    );
    addTearDown(container.dispose);

    final success = await container
        .read(authProvider.notifier)
        .requestOtp('+77001234567');
    final state = container.read(authProvider);

    expect(success, isFalse);
    expect(state.otpPhone, isNull);
    expect(state.otpCooldownPhone, '+77001234567');
    expect(
      state.otpRetryAt!.difference(DateTime.now()).inSeconds,
      inInclusiveRange(58, 60),
    );
  });

  test('409 does not create an OTP session', () async {
    final container = ProviderContainer(
      overrides: [
        dioProvider.overrideWithValue(
          _stubDio(409, {'code': 'OTP_ALREADY_ACTIVE', 'message': 'Conflict'}),
        ),
      ],
    );
    addTearDown(container.dispose);

    final success = await container
        .read(authProvider.notifier)
        .requestOtp('+77001234567');
    final state = container.read(authProvider);

    expect(success, isFalse);
    expect(state.otpPhone, isNull);
    expect(state.otpRequestedAt, isNull);
    expect(state.errorCode, 'OTP_ALREADY_ACTIVE');
  });

  test(
    'successful OTP uses the post-auth transition without a full reload',
    () async {
      late _RecordingAppStartupController startupController;
      final container = ProviderContainer(
        overrides: [
          dioProvider.overrideWithValue(
            _stubDio(200, {
              'message': 'Login successful',
              'sessionToken': 'session-token',
              'expires': '2099-01-01T00:00:00.000Z',
              'user': {
                'id': 'user-1',
                'phoneNumber': '+77011234567',
                'role': 'CLIENT',
              },
            }),
          ),
          appStartupProvider.overrideWith((ref) {
            startupController = _RecordingAppStartupController(ref);
            return startupController;
          }),
        ],
      );
      addTearDown(container.dispose);

      final success = await container
          .read(authProvider.notifier)
          .verifyOtp('+77011234567', '000000');

      expect(success, isTrue);
      expect(
        container.read(authProvider).session?.sessionToken,
        'session-token',
      );
      expect(startupController.postAuthTransitions, 1);
      expect(startupController.fullReloads, 0);
    },
  );

  test('post-auth profile loading keeps the OTP route mounted', () async {
    final profileRelease = Completer<UserProfileModel?>();
    final requestedAt = DateTime.now();
    FlutterSecureStorage.setMockInitialValues({
      'otp_session': jsonEncode({
        'phone': '+77011234567',
        'requestedAt': requestedAt.toIso8601String(),
        'retryAt': requestedAt.toIso8601String(),
      }),
    });

    final container = ProviderContainer(
      overrides: [
        dioProvider.overrideWithValue(
          _stubDio(200, {
            'message': 'Login successful',
            'sessionToken': 'session-token',
            'expires': '2099-01-01T00:00:00.000Z',
            'user': {
              'id': 'user-1',
              'phoneNumber': '+77011234567',
              'role': 'CLIENT',
            },
          }),
        ),
        clientProfileProvider.overrideWith(
          () => _ControlledClientProfileNotifier(profileRelease.future),
        ),
      ],
    );
    addTearDown(() {
      if (!profileRelease.isCompleted) profileRelease.complete(null);
      container.dispose();
    });

    final startup = container.read(appStartupProvider.notifier);
    await startup.init();
    expect(
      container.read(appStartupProvider).routeState,
      AppStartupRouteState.otp,
    );

    final routeStates = <AppStartupRouteState>[];
    final subscription = container.listen(
      appStartupProvider.select((status) => status.routeState),
      (_, next) => routeStates.add(next),
    );
    addTearDown(subscription.close);

    final success = await container
        .read(authProvider.notifier)
        .verifyOtp('+77011234567', '000000');
    await Future<void>.delayed(Duration.zero);

    expect(success, isTrue);
    expect(
      container.read(appStartupProvider).routeState,
      AppStartupRouteState.otp,
    );
    expect(routeStates, isNot(contains(AppStartupRouteState.loading)));

    profileRelease.complete(UserProfileModel(role: 'CLIENT'));
    await _waitForRouteState(container, AppStartupRouteState.client);

    expect(routeStates, isNot(contains(AppStartupRouteState.loading)));
  });
}

Future<void> _waitForRouteState(
  ProviderContainer container,
  AppStartupRouteState routeState,
) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    if (container.read(appStartupProvider).routeState == routeState) return;
    await Future<void>.delayed(Duration.zero);
  }
  expect(container.read(appStartupProvider).routeState, routeState);
}

class _ControlledClientProfileNotifier extends ClientProfileNotifier {
  final Future<UserProfileModel?> profile;

  _ControlledClientProfileNotifier(this.profile);

  @override
  Future<UserProfileModel?> build() => profile;
}

class _RecordingAppStartupController extends AppStartupController {
  int fullReloads = 0;
  int postAuthTransitions = 0;

  _RecordingAppStartupController(Ref ref) : super(ref, AppModeStorage());

  @override
  Future<void> reloadApp() async {
    fullReloads++;
  }

  @override
  Future<void> reloadAfterAuthChanged() async {
    postAuthTransitions++;
  }
}
