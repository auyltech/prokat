import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/features/appstatic/screens/main_screen.dart';
import 'package:prokat/l10n/app_localizations.dart';

class _RecoveringApiClient implements ApiClient {
  _RecoveringApiClient()
    : dio = Dio(
        BaseOptions(
          baseUrl: 'https://offline.example.test',
          responseType: ResponseType.json,
          validateStatus: (status) => status != null && status < 600,
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: isOnline ? 200 : 503,
              data: isOnline
                  ? const {'success': true, 'data': <dynamic>[]}
                  : const {'message': 'Backend unavailable'},
            ),
          );
        },
      ),
    );
  }

  bool isOnline = false;

  @override
  Dio dio;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('offline backend shows retry state without crashing', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    final apiClient = _RecoveringApiClient();
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(apiClient)],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MainScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text("Couldn't load equipment"), findsOneWidget);
    expect(find.text('Error loading services'), findsOneWidget);
    expect(find.text('Retry Now'), findsOneWidget);

    apiClient.isOnline = true;
    await tester.tap(find.text('Retry Now'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Retry Now'), findsNothing);
    expect(find.text('Error loading services'), findsNothing);
  });
}
