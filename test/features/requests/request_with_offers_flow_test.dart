import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/features/auth/models/user_model.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/models/offer_status.dart';
import 'package:prokat/features/offers/offer_price_selection.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/offers/state/offers_service.dart';
import 'package:prokat/features/offers/widgets/offer_flow_card.dart';
import 'package:prokat/features/requests/models/request_model.dart';
import 'package:prokat/features/requests/models/request_status.dart';
import 'package:prokat/features/requests/state/request_provider.dart';
import 'package:prokat/features/requests/state/request_service.dart';
import 'package:prokat/features/requests/widgets.dart/request_with_offers.dart';
import 'package:prokat/l10n/app_localizations.dart';

class _TestApiClient implements ApiClient {
  @override
  Dio dio = Dio();
}

class _OfferPage {
  final List<OfferModel> offers;
  final bool complete;
  final bool loading;
  const _OfferPage(this.offers, {this.complete = false, this.loading = false});
}

void main() {
  testWidgets(
    'actual controls require complete pages and matching units, preserve ties and API order',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = _TestApiClient();
      var loadCalls = 0;
      final high = _offer('hour-high', 30000);
      final tieFirst = _offer('hour-first', 22000);
      final tieSecond = _offer('hour-second', 22000);
      final trip = _offer('trip', 5000, unit: 'PER_TRIP');
      final page = ValueNotifier(_OfferPage([high, tieFirst]));
      addTearDown(page.dispose);
      final request = RequestModel(
        id: 'request-1',
        status: RequestStatus.created,
        category: const Category(
          id: 'category',
          name: 'Excavators',
          sortIndex: 0,
        ),
        capacity: '',
        offeredPrice: 0,
        createdAt: DateTime.now(),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            offersServiceProvider.overrideWithValue(OffersService(api)),
            requestServiceProvider.overrideWithValue(RequestService(api)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: Scaffold(
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: ProkatFlowScope(
                      palette: ProkatFlowPalette.light,
                      child: ValueListenableBuilder<_OfferPage>(
                        valueListenable: page,
                        builder: (context, value, _) => RequestWithOffers(
                          key: const ValueKey('request-1'),
                          request: request,
                          offers: value.offers,
                          offersComplete: value.complete,
                          offersLoading: value.loading,
                          onLoadAllOffers: () => loadCalls++,
                          onCancel: () {},
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);

      FilterChip bestControl() =>
          tester.widget<FilterChip>(find.byType(FilterChip));
      DropdownButtonFormField<OfferPriceOrder> sortControl() =>
          tester.widget(find.byType(DropdownButtonFormField<OfferPriceOrder>));
      List<String> visibleIds() => tester
          .widgetList<OfferFlowCard>(find.byType(OfferFlowCard))
          .map((card) => card.offer.id)
          .toList();

      // A single shared unit alone cannot prove a best price on a partial page.
      expect(bestControl().onSelected, isNull);
      expect(sortControl().onChanged, isNull);
      final load = find.widgetWithText(TextButton, 'Load all offers');
      await tester.ensureVisible(load);
      await tester.tap(load);
      await tester.pump();
      expect(loadCalls, 1);
      page.value = _OfferPage([high, tieFirst], loading: true);
      await tester.pump();
      expect(tester.widget<TextButton>(load).onPressed, isNull);
      await tester.tap(load);
      expect(loadCalls, 1);

      // Once every page is available, hour and trip prices still cannot mix.
      final apiOrder = [high, trip, tieFirst, tieSecond];
      page.value = _OfferPage(apiOrder, complete: true);
      await tester.pump();
      expect(bestControl().onSelected, isNull);
      expect(sortControl().onChanged, isNull);
      expect(visibleIds(), ['hour-high', 'trip', 'hour-first', 'hour-second']);
      final hours = find.widgetWithText(ChoiceChip, 'per hour');
      await tester.ensureVisible(hours);
      await tester.tap(hours);
      await tester.pump();
      expect(bestControl().onSelected, isNotNull);
      expect(sortControl().onChanged, isNotNull);
      expect(visibleIds(), ['hour-high', 'hour-first', 'hour-second']);
      await tester.ensureVisible(find.byType(FilterChip));
      await tester.tap(find.byType(FilterChip));
      await tester.pump();
      expect(visibleIds(), ['hour-first', 'hour-second']);

      final arrival = _offer('hour-arrival', 18000);
      page.value = _OfferPage([...apiOrder, arrival], complete: true);
      await tester.pump();
      expect(visibleIds(), ['hour-arrival']);

      // Choosing All units restores the incoming order, not an invented mixed sort.
      final all = find.widgetWithText(ChoiceChip, 'All units');
      await tester.ensureVisible(all);
      await tester.tap(all);
      await tester.pump();
      expect(visibleIds(), [
        'hour-high',
        'trip',
        'hour-first',
        'hour-second',
        'hour-arrival',
      ]);
      expect(apiOrder.map((offer) => offer.id), [
        'hour-high',
        'trip',
        'hour-first',
        'hour-second',
      ]);

      // A live removal must not strand unknown-unit offers behind a hidden filter.
      final unknown = _offer('unknown-unit', 1000, unit: null);
      page.value = _OfferPage([...apiOrder, unknown], complete: true);
      await tester.pump();
      await tester.ensureVisible(hours);
      await tester.tap(hours);
      await tester.pump();
      expect(visibleIds(), ['hour-high', 'hour-first', 'hour-second']);
      page.value = _OfferPage([
        high,
        tieFirst,
        tieSecond,
        unknown,
      ], complete: true);
      await tester.pump();
      expect(visibleIds(), ['hour-high', 'hour-first', 'hour-second']);
      expect(all, findsOneWidget);
      await tester.ensureVisible(all);
      await tester.tap(all);
      await tester.pump();
      expect(visibleIds(), [
        'hour-high',
        'hour-first',
        'hour-second',
        'unknown-unit',
      ]);
      expect(tester.takeException(), isNull);
    },
  );
}

OfferModel _offer(String id, int price, {String? unit = 'PER_HOUR'}) =>
    OfferModel(
      id: id,
      status: OfferStatus.created,
      requestId: 'request-1',
      chatId: '',
      equipmentId: 'equipment-$id',
      price: price,
      priceRate: unit == null
          ? null
          : priceRateOptions.firstWhere((option) => option.value == unit),
      owner: UserModel(firstName: id),
    );
