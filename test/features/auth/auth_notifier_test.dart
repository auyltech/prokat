import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/analytics/analytics_identity.dart';
import 'package:prokat/core/analytics/analytics_service.dart';
import 'package:prokat/core/analytics/pending_sign_up.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/equipment_share/equipment_share_first_touch.dart';
import 'package:prokat/features/equipment_share/equipment_share_open.dart';
import 'package:prokat/features/user/models/user_profile_model.dart';
import 'package:prokat/features/user/state/client_profile_notifier.dart';
import 'package:prokat/features/user/state/client_profile_provider.dart';

import '../../helpers/recording_analytics_client.dart';

class _StubAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) respond;
  final void Function(RequestOptions options)? onRequest;

  _StubAdapter(this.respond, {this.onRequest});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    onRequest?.call(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

Dio _stubDio(
  int statusCode,
  Map<String, dynamic> body, {
  Map<String, List<String>> headers = const {},
  void Function(RequestOptions options)? onRequest,
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
    onRequest: onRequest,
  );
  return dio;
}

class _ThrowingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    throw DioException.connectionTimeout(
      timeout: const Duration(seconds: 1),
      requestOptions: options,
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _throwingDio() {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
  dio.httpClientAdapter = _ThrowingAdapter();
  return dio;
}

class _ThrowingFirstTouchStore extends EquipmentShareFirstTouchStore {
  @override
  Future<FirstTouchAttribution?> readValid({DateTime? now}) {
    throw StateError('secure storage unavailable');
  }
}

const _shareId = 'AbCdEfGhIjKlMnOpQr_-12';
final _touchTime = DateTime.utc(2026, 10, 6, 12);

FirstTouchAttribution _touch({String? shareId = _shareId}) =>
    FirstTouchAttribution(
      shareId: shareId,
      equipmentId: 'eq-1',
      via: ShareOpenVia.installReferrer,
      firstShareBootstrapRun: true,
      receivedAt: _touchTime,
    );

Future<void> _seedTouch({String? shareId = _shareId}) =>
    EquipmentShareFirstTouchStore(now: () => _touchTime)
        .saveIfEmpty(_touch(shareId: shareId));

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

  group('first-touch OTP attribution', () {
    ProviderContainer containerWith(
      Dio dio, {
      EquipmentShareFirstTouchStore? firstTouchStore,
    }) {
      final container = ProviderContainer(
        overrides: [
          dioProvider.overrideWithValue(dio),
          appStartupProvider.overrideWith(_RecordingAppStartupController.new),
          if (firstTouchStore != null)
            equipmentShareFirstTouchStoreProvider.overrideWithValue(
              firstTouchStore,
            ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('verify sends attribution', () async {
      await _seedTouch();
      RequestOptions? request;
      final container = containerWith(
        _stubDio(200, {
          ..._otpBody,
          'isNewUser': false,
        }, onRequest: (value) => request = value),
      );

      expect(
        await container
            .read(authProvider.notifier)
            .verifyOtp('+77011234567', '000000'),
        isTrue,
      );

      expect((request!.data as Map)['attribution'], {
        'shareId': _shareId,
        'equipmentId': 'eq-1',
        'openVia': 'INSTALL_REFERRER',
        'firstShareBootstrapRun': true,
        'firstTouchAt': '2026-10-06T12:00:00.000Z',
      });
    });

    test('verify without attribution omits the key', () async {
      RequestOptions? request;
      final container = containerWith(
        _stubDio(200, {
          ..._otpBody,
          'isNewUser': false,
        }, onRequest: (value) => request = value),
      );

      expect(
        await container
            .read(authProvider.notifier)
            .verifyOtp('+77011234567', '000000'),
        isTrue,
      );

      expect((request!.data as Map).containsKey('attribution'), isFalse);
    });

    test('successful new-user verify clears attribution', () async {
      await _seedTouch();
      final container = containerWith(
        _stubDio(200, {..._otpBody, 'isNewUser': true}),
      );

      expect(
        await container
            .read(authProvider.notifier)
            .verifyOtp('+77011234567', '000000'),
        isTrue,
      );
      await _settleAnalytics();

      expect(await EquipmentShareFirstTouchStore().readValid(), isNull);
    });

    test('successful existing-user verify clears attribution', () async {
      await _seedTouch();
      final container = containerWith(
        _stubDio(200, {..._otpBody, 'isNewUser': false}),
      );

      expect(
        await container
            .read(authProvider.notifier)
            .verifyOtp('+77011234567', '000000'),
        isTrue,
      );
      await _settleAnalytics();

      expect(await EquipmentShareFirstTouchStore().readValid(), isNull);
    });

    test('failed verify keeps attribution', () async {
      await _seedTouch();
      final container = containerWith(
        _stubDio(400, {'code': 'INVALID_OTP', 'message': 'Invalid OTP'}),
      );

      expect(
        await container
            .read(authProvider.notifier)
            .verifyOtp('+77011234567', '000000'),
        isFalse,
      );

      expect(
        (await EquipmentShareFirstTouchStore().readValid())?.shareId,
        _shareId,
      );
    });

    test('timeout keeps attribution', () async {
      await _seedTouch();
      final container = containerWith(_throwingDio());

      expect(
        await container
            .read(authProvider.notifier)
            .verifyOtp('+77011234567', '000000'),
        isFalse,
      );

      expect(
        (await EquipmentShareFirstTouchStore().readValid())?.shareId,
        _shareId,
      );
    });

    test('attribution storage failure does not break login', () async {
      final container = containerWith(
        _stubDio(200, {..._otpBody, 'isNewUser': false}),
        firstTouchStore: _ThrowingFirstTouchStore(),
      );

      expect(
        await container
            .read(authProvider.notifier)
            .verifyOtp('+77011234567', '000000'),
        isTrue,
      );
      expect(container.read(authProvider).currentUserId, 'user-1');
    });
  });

  group('sign_up analytics', () {
    Future<ProviderContainer> verifyWith(
      Map<String, dynamic> body, {
      required RecordingAnalyticsClient client,
      bool identityListener = true,
      FirstTouchAttribution? firstTouch,
    }) async {
      if (firstTouch != null) {
        await EquipmentShareFirstTouchStore(now: () => firstTouch.receivedAt)
            .saveIfEmpty(firstTouch);
      }
      final container = ProviderContainer(
        overrides: [
          dioProvider.overrideWithValue(_stubDio(200, body)),
          analyticsServiceProvider.overrideWithValue(AnalyticsService(client)),
          appStartupProvider.overrideWith(_RecordingAppStartupController.new),
          clientProfileProvider.overrideWith(
            () => _ControlledClientProfileNotifier(Future.value(null)),
          ),
        ],
      );
      addTearDown(container.dispose);
      if (identityListener) {
        container.read(analyticsIdentityBootstrapProvider);
        await _settleAnalytics();
      }

      final success = await container
          .read(authProvider.notifier)
          .verifyOtp('+77011234567', '000000');
      await _settleAnalytics();

      expect(success, isTrue);
      expect(
        container.read(authProvider).session?.sessionToken,
        'session-token',
      );
      return container;
    }

    test('verifyOtp marks pending sign_up for the new user only', () async {
      final client = RecordingAnalyticsClient();
      final container = await verifyWith(
        {..._otpBody, 'isNewUser': true},
        client: client,
        identityListener: false,
      );

      expect(client.events, isEmpty);
      final pending = container.read(pendingSignUpProvider);
      expect(pending.consume('user-2'), isNull);
      final value = pending.consume('user-1');
      expect(value?.userId, 'user-1');
      expect(value?.shareId, isNull);
      expect(pending.consume('user-1'), isNull);
    });

    test('verifyOtp logs sign_up for new user', () async {
      final client = RecordingAnalyticsClient();
      await verifyWith({..._otpBody, 'isNewUser': true}, client: client);

      expect(client.events, hasLength(1));
      expect(client.events.single.name, 'sign_up');
      expect(client.events.single.params, {'method': 'phone_otp'});
    });

    test('new attributed user sign_up carries share_id', () async {
      final client = RecordingAnalyticsClient();
      await verifyWith(
        {..._otpBody, 'isNewUser': true},
        client: client,
        firstTouch: _touch(),
      );

      expect(client.events, hasLength(1));
      expect(client.events.single.name, 'sign_up');
      expect(client.events.single.params, {
        'method': 'phone_otp',
        'share_id': _shareId,
      });
    });

    test('verifyOtp does not log sign_up for existing user', () async {
      final client = RecordingAnalyticsClient();
      final container = await verifyWith(
        {..._otpBody, 'isNewUser': false},
        client: client,
        firstTouch: _touch(),
      );

      expect(client.events, isEmpty);
      expect(client.userIds.last, 'user-1');
      expect(container.read(pendingSignUpProvider).consume('user-1'), isNull);
    });

    test('verifyOtp without isNewUser field does not log sign_up', () async {
      final client = RecordingAnalyticsClient();
      final container = await verifyWith(_otpBody, client: client);

      expect(client.events, isEmpty);
      expect(container.read(pendingSignUpProvider).consume('user-1'), isNull);
    });

    test('identity reaches analytics before sign_up', () async {
      final client = _OrderedAnalyticsClient();
      await verifyWith({..._otpBody, 'isNewUser': true}, client: client);

      expect(client.order, [
        'setUserId:null',
        'setUserProperty:user_role=null',
        'setUserId:user-1',
        'setUserProperty:user_role=client',
        'logEvent:sign_up',
      ]);
    });

    test('attributed identity reaches analytics before sign_up', () async {
      final client = _OrderedAnalyticsClient();
      await verifyWith(
        {..._otpBody, 'isNewUser': true},
        client: client,
        firstTouch: _touch(),
      );

      expect(client.order, [
        'setUserId:null',
        'setUserProperty:user_role=null',
        'setUserId:user-1',
        'setUserProperty:user_role=client',
        'logEvent:sign_up:share_id=$_shareId',
      ]);
    });

    test('analytics client failure does not break login', () async {
      await verifyWith({
        ..._otpBody,
        'isNewUser': true,
      }, client: RecordingAnalyticsClient(throwOnCall: true));
    });
  });
}

Future<void> _settleAnalytics() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

const _otpBody = <String, dynamic>{
  'message': 'Login successful',
  'sessionToken': 'session-token',
  'expires': '2099-01-01T00:00:00.000Z',
  'user': {'id': 'user-1', 'phoneNumber': '+77011234567', 'role': 'CLIENT'},
};

class _OrderedAnalyticsClient extends RecordingAnalyticsClient {
  final order = <String>[];

  @override
  Future<void> logEvent(String name, Map<String, Object> params) async {
    final shareId = params['share_id'];
    order.add(
      shareId == null ? 'logEvent:$name' : 'logEvent:$name:share_id=$shareId',
    );
    await super.logEvent(name, params);
  }

  @override
  Future<void> setUserId(String? id) async {
    order.add('setUserId:$id');
    await super.setUserId(id);
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    order.add('setUserProperty:$name=$value');
    await super.setUserProperty(name, value);
  }
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
