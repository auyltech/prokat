import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/requests/models/request_model.dart';
import 'package:prokat/features/requests/models/request_status.dart';
import 'package:prokat/features/requests/state/request_provider.dart';
import 'package:prokat/features/requests/state/request_service.dart';
import 'package:prokat/features/requests/widgets.dart/client_request_tile.dart';
import 'package:prokat/features/requests/widgets.dart/request_status_badge.dart';
import 'package:prokat/l10n/app_localizations.dart';

class _TestApiClient implements ApiClient {
  _TestApiClient(this.dio);

  @override
  Dio dio;
}

void main() {
  final calls = <RequestOptions>[];
  late Dio dio;

  setUp(() {
    calls.clear();
    dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          calls.add(options);
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{'message': 'ok'},
            ),
          );
        },
      ),
    );
  });

  RequestModel request({
    RequestStatus status = RequestStatus.created,
    int price = 0,
    PriceRateOption? rate,
    bool date = false,
  }) => RequestModel(
    id: 'request-1',
    status: status,
    category: const Category(
      id: 'category-1',
      name: 'Excavators and earthmoving machinery for a narrow screen',
      sortIndex: 0,
    ),
    capacity: '22 tonnes of machinery capacity',
    offeredPrice: price,
    offeredPriceRate: rate,
    comment: 'Excavate the foundation and remove the soil from the entrance.',
    requiredOn: date ? DateTime(2026, 10, 22) : null,
    requiredAt: date ? DateTime(2026, 10, 22, 9, 30) : null,
    createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
  );

  Future<void> pumpCard(
    WidgetTester tester,
    RequestModel model, {
    bool flow = true,
    bool dark = false,
    double textScale = 1,
    int? offerCount,
  }) async {
    final card = ClientRequestTile(request: model, offerCount: offerCount);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          requestServiceProvider.overrideWithValue(
            RequestService(_TestApiClient(dio)),
          ),
        ],
        child: MaterialApp(
          theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: flow
                      ? ProkatFlowScope(
                          palette: dark
                              ? ProkatFlowPalette.dark
                              : ProkatFlowPalette.light,
                          child: card,
                        )
                      : card,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  for (final dark in [false, true]) {
    testWidgets(
      'null address and date remain usable at large text (${dark ? 'dark' : 'light'})',
      (tester) async {
        tester.view.physicalSize = const Size(320, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await pumpCard(
          tester,
          request(),
          dark: dark,
          textScale: 2,
          offerCount: 3,
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Unknown location'), findsOneWidget);
        expect(find.text('Date not set'), findsOneWidget);
        expect(find.text('3 offers'), findsOneWidget);
        expect(find.text('from owner', findRichText: true), findsOneWidget);
        expect(find.byTooltip('Cancel Request'), findsOneWidget);

        final location = find.text('Unknown location');
        await tester.ensureVisible(location);
        await tester.tap(location);
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(calls, isEmpty);
      },
    );
  }

  testWidgets(
    'closing the cancellation confirmation leaves the request intact',
    (tester) async {
      await pumpCard(tester, request(date: true));
      final cancel = find.byTooltip('Cancel Request');
      await tester.ensureVisible(cancel);
      await tester.tap(cancel);
      await tester.pumpAndSettle();

      expect(find.text('Cancel Request?'), findsOneWidget);
      expect(calls, isEmpty);
      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();
      expect(find.text('Cancel Request?'), findsNothing);
      expect(find.byTooltip('Cancel Request'), findsOneWidget);
      expect(calls, isEmpty);
    },
  );

  testWidgets(
    'handled and expired requests keep their summary without cancellation',
    (tester) async {
      for (final status in [
        RequestStatus.accepted,
        RequestStatus.cancelled,
        RequestStatus.expired,
      ]) {
        await pumpCard(tester, request(status: status));
        expect(tester.takeException(), isNull);
        expect(find.byTooltip('Cancel Request'), findsNothing);
        expect(find.text('from owner', findRichText: true), findsOneWidget);
        expect(find.textContaining('left'), findsNothing);
      }
    },
  );

  testWidgets(
    'viewed requests use a localized status and retain cancellation',
    (tester) async {
      await pumpCard(tester, request(status: RequestStatus.viewed));
      expect(find.text('Viewed'), findsOneWidget);
      expect(find.text('viewed'), findsNothing);
      expect(find.byTooltip('Cancel Request'), findsOneWidget);
    },
  );

  testWidgets('budget shows a rate only when the DTO actually provides one', (
    tester,
  ) async {
    await pumpCard(tester, request(price: 25000));
    expect(find.text('Your budget'), findsOneWidget);
    expect(find.text('₸ 25 000', findRichText: true), findsOneWidget);
    expect(find.textContaining('/ trip', findRichText: true), findsNothing);

    await pumpCard(
      tester,
      request(price: 25000, rate: parseRateOption('PER_HOUR')),
    );
    expect(find.text('₸ 25 000 / hour', findRichText: true), findsOneWidget);
  });

  testWidgets(
    'summary leaves room for offers without duplicating their status',
    (tester) async {
      tester.view.physicalSize = const Size(411, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final compact = RequestModel(
        id: 'compact-request',
        status: RequestStatus.responded,
        category: const Category(
          id: 'excavators',
          name: 'Excavators',
          sortIndex: 0,
        ),
        capacity: '22 t',
        offeredPrice: 25000,
        requiredOn: DateTime(2026, 10, 22),
        requiredAt: DateTime(2026, 10, 22, 9, 30),
        createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
      );
      await pumpCard(tester, compact, offerCount: 3);
      expect(tester.takeException(), isNull);
      expect(find.text('3 offers'), findsOneWidget);
      expect(find.text('Offers Received'), findsNothing);
      expect(find.byTooltip('Cancel Request'), findsOneWidget);
      expect(
        tester.getSize(find.byType(ClientRequestTile)).height,
        lessThan(240),
      );

      await pumpCard(
        tester,
        compact.copyWith(
          comment: 'Excavate the foundation and remove the soil.',
        ),
        offerCount: 3,
      );
      expect(tester.takeException(), isNull);
      expect(
        find.text('Excavate the foundation and remove the soil.'),
        findsOneWidget,
      );
      expect(
        tester.getSize(find.byType(ClientRequestTile)).height,
        lessThan(290),
      );
    },
  );

  testWidgets(
    'legacy presentation remains available outside the refreshed scope',
    (tester) async {
      await pumpCard(tester, request(date: true), flow: false);
      expect(tester.takeException(), isNull);
      expect(find.byType(RequestStatusBadge), findsOneWidget);
      expect(find.text('Offered rate'), findsOneWidget);
      expect(find.text('Your budget'), findsNothing);
    },
  );
}
