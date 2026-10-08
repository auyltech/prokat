import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/analytics/analytics_service.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/features/auth/models/auth_session.dart';
import 'package:prokat/features/auth/models/user_model.dart';
import 'package:prokat/features/auth/providers/auth_api_service.dart';
import 'package:prokat/features/auth/providers/auth_notifier.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/auth/providers/auth_secure_storage.dart';
import 'package:prokat/features/auth/providers/auth_state.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/catalog/models/catalog_bundle.dart';
import 'package:prokat/features/owner/models/registration_request_model.dart';
import 'package:prokat/features/owner/screens/register_owner_screen.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
import 'package:prokat/features/owner/state/owner_registration_request_notifier.dart';
import 'package:prokat/features/owner/state/owner_registration_service.dart';
import 'package:prokat/features/user/models/user_profile_model.dart';
import 'package:prokat/features/user/state/client_profile_notifier.dart';
import 'package:prokat/features/user/state/client_profile_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

import '../../helpers/recording_analytics_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('startable owner form emits owner_application_started', (
    tester,
  ) async {
    final harness = await _pumpOwnerForm(
      tester,
      request: _rejectedRequest,
      createSucceeds: true,
    );

    expect(
      harness.analytics.events.where(
        (event) => event.name == 'owner_application_started',
      ),
      hasLength(1),
    );
  });

  testWidgets('pending owner form does not emit owner_application_started', (
    tester,
  ) async {
    final harness = await _pumpOwnerForm(
      tester,
      request: RegistrationRequestModel(status: 'PENDING'),
      createSucceeds: true,
    );

    expect(
      harness.analytics.events.where(
        (event) => event.name == 'owner_application_started',
      ),
      isEmpty,
    );
    expect(find.text('redirect target'), findsOneWidget);
  });

  testWidgets('successful owner resubmission emits is_resubmit once', (
    tester,
  ) async {
    final harness = await _pumpOwnerForm(
      tester,
      request: _rejectedRequest,
      createSucceeds: true,
    );

    final submit = find.text('Resubmit request');
    await tester.scrollUntilVisible(
      submit,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(submit);
    await tester.pumpAndSettle();

    final events = harness.analytics.events
        .where((event) => event.name == 'owner_application_submitted')
        .toList();
    expect(harness.service.createCalls, 1);
    expect(events, hasLength(1));
    expect(events.single.params, {'is_resubmit': 1});
  });

  testWidgets('failed owner submission emits no submitted event', (
    tester,
  ) async {
    final harness = await _pumpOwnerForm(
      tester,
      request: _rejectedRequest,
      createSucceeds: false,
    );

    final submit = find.text('Resubmit request');
    await tester.scrollUntilVisible(
      submit,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(
      harness.analytics.events.where(
        (event) => event.name == 'owner_application_submitted',
      ),
      isEmpty,
    );
    expect(harness.service.createCalls, 1);
  });
}

final _rejectedRequest = RegistrationRequestModel(
  id: 'request-1',
  firstName: 'Aruzhan',
  lastName: 'Test',
  phoneNumber: '+77001234567',
  city: 'atyrau',
  message: 'Excavator services',
  status: 'REJECTED',
);

class _OwnerHarness {
  const _OwnerHarness(this.analytics, this.service);

  final RecordingAnalyticsClient analytics;
  final _FakeOwnerRegistrationService service;
}

Future<_OwnerHarness> _pumpOwnerForm(
  WidgetTester tester, {
  required RegistrationRequestModel? request,
  required bool createSucceeds,
}) async {
  final analytics = RecordingAnalyticsClient();
  final service = _FakeOwnerRegistrationService(
    request: request,
    createSucceeds: createSucceeds,
  );
  final router = GoRouter(
    initialLocation: '/owner-form',
    routes: [
      GoRoute(
        path: '/owner-form',
        builder: (_, _) => const RegisterOwnerPage(),
      ),
      GoRoute(
        path: '/client/profile',
        builder: (_, _) => const Scaffold(body: Text('redirect target')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        analyticsServiceProvider.overrideWithValue(AnalyticsService(analytics)),
        authProvider.overrideWith(_AuthenticatedAuthNotifier.new),
        clientProfileProvider.overrideWith(_FixedClientProfileNotifier.new),
        ownerRegistrationServiceProvider.overrideWithValue(service),
        ownerRegistrationRequestProvider.overrideWith(
          () => _FixedOwnerRequestNotifier(request),
        ),
        catalogProvider.overrideWith(_EmptyCatalogNotifier.new),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _OwnerHarness(analytics, service);
}

class _AuthenticatedAuthNotifier extends AuthNotifier {
  _AuthenticatedAuthNotifier(Ref ref)
    : super(ref, AuthApiService(Dio()), AuthSecureStorage()) {
    state = const AuthState(
      session: AuthSession(
        sessionToken: 'token',
        user: UserModel(id: 'user-1', role: UserRole.client),
      ),
    );
  }
}

class _FixedClientProfileNotifier extends ClientProfileNotifier {
  @override
  Future<UserProfileModel?> build() async => null;

  @override
  Future<void> refreshIfStale() async {}
}

class _FixedOwnerRequestNotifier extends OwnerRegistrationRequestNotifier {
  _FixedOwnerRequestNotifier(this.value);

  final RegistrationRequestModel? value;

  @override
  Future<RegistrationRequestModel?> build() async => value;

  @override
  Future<void> refresh() async {}

  @override
  Future<void> refreshIfStale() async {}
}

class _EmptyCatalogNotifier extends CatalogNotifier {
  @override
  Future<CatalogBundle> build() async => const CatalogBundle(
    version: 'test',
    cities: [],
    categories: [],
    units: [],
    specs: [],
    specOptions: [],
    categorySpecs: [],
  );
}

class _FakeOwnerRegistrationService extends OwnerRegistrationService {
  _FakeOwnerRegistrationService({
    required this.request,
    required this.createSucceeds,
  }) : super(_TestApiClient(Dio()));

  final RegistrationRequestModel? request;
  final bool createSucceeds;
  int createCalls = 0;

  @override
  Future<RegistrationRequestModel?> getOwnerRegistrationRequest() async =>
      request;

  @override
  Future<bool> createOwnerRegistrationRequest({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? email,
    String? city,
    String? message,
  }) async {
    createCalls += 1;
    return createSucceeds;
  }
}

class _TestApiClient implements ApiClient {
  _TestApiClient(this.dio);

  @override
  Dio dio;
}
