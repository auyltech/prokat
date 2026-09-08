import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/features/appstatic/screens/main_screen.dart';
import 'package:prokat/features/catalog/catalog_cache.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/catalog/models/catalog_bundle.dart';
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
          if (!isOnline) {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 503,
                data: const {'message': 'Backend unavailable'},
              ),
            );
            return;
          }

          final path = options.path;
          final Object data;
          if (path.contains('/catalog')) {
            data = {
              'data': {
                'version': 'online',
                'cities': <Map<String, dynamic>>[],
                'categories': <Map<String, dynamic>>[],
                'units': <Map<String, dynamic>>[],
                'specs': <Map<String, dynamic>>[],
                'specOptions': <Map<String, dynamic>>[],
                'categorySpecs': <Map<String, dynamic>>[],
              },
            };
          } else {
            data = const {'success': true, 'data': <dynamic>[]};
          }

          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: data,
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

class _EmptyCatalogCache extends CatalogCache {
  @override
  Future<CatalogCacheEntry?> readDisk() async => null;

  @override
  Future<CatalogBundle> readAsset() async {
    throw const FormatException('No bundled catalog in offline test');
  }

  @override
  Future<void> write(CatalogBundle bundle, {DateTime? fetchedAt}) async {}
}

Future<void> _pumpUntilSettled(WidgetTester tester) async {
  // Shimmer skeletons animate forever, so avoid pumpAndSettle.
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
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
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          catalogCacheProvider.overrideWithValue(_EmptyCatalogCache()),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MainScreen(),
        ),
      ),
    );

    await _pumpUntilSettled(tester);

    expect(tester.takeException(), isNull);
    expect(find.text("Couldn't load equipment"), findsOneWidget);
    expect(find.text('Error loading services'), findsOneWidget);
    expect(find.text('Retry Now'), findsOneWidget);

    apiClient.isOnline = true;
    await tester.tap(find.text('Retry Now'));
    await _pumpUntilSettled(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Retry Now'), findsNothing);
    expect(find.text('Error loading services'), findsNothing);
  });
}
