import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/auth/models/user_model.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/auth/providers/authenticated_session_scope.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/layout/main_scaffold.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/models/offer_status.dart';
import 'package:prokat/features/offers/widgets/offer_flow_card.dart';
import 'package:prokat/features/requests/models/request_model.dart';
import 'package:prokat/features/requests/models/request_status.dart';
import 'package:prokat/features/requests/widgets.dart/request_with_offers.dart';
import 'package:prokat/l10n/app_localizations.dart';

import '../user_safety/user_safety_test_support.dart';

class _TestApiClient implements ApiClient {
  @override
  Dio dio = Dio();
}

class _ClientStartup extends AppStartupController {
  _ClientStartup(Ref ref) : super(ref, AppModeStorage()) {
    state = const AppStartupStatus(
      routeState: AppStartupRouteState.client,
      step: AppStartupStep.done,
      progress: 1,
      stepLabel: '',
    );
  }
}

void main() {
  testWidgets(
    'MainScaffold request filters and card state survive actual chat push and Back',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
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
      );
      final offers = [
        _offer('hour-high', 30000),
        _offer('trip', 5000, unit: 'PER_TRIP'),
        _offer('hour-cheap', 22000),
      ];
      final router = GoRouter(
        initialLocation: AppRoutes.clientRequests,
        routes: [
          StatefulShellRoute.indexedStack(
            pageBuilder: (context, state, navigationShell) =>
                NoTransitionPage<void>(
                  key: state.pageKey,
                  child: MainScaffold(navigationShell: navigationShell),
                ),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.clientRequests,
                    builder: (context, state) => ListView(
                      children: [
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 1,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 24),
                          itemBuilder: (context, index) => RequestWithOffers(
                            key: const ValueKey('request-1'),
                            request: request,
                            offers: offers,
                            onCancel: () {},
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  GoRoute(
                    path: AppRoutes.clientChatList,
                    builder: (context, state) => const Text('Chat list'),
                    routes: [
                      GoRoute(
                        path: 'direct/:id',
                        builder: (context, state) =>
                            const Center(child: Text('Test thread')),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(_TestApiClient()),
            authProvider.overrideWith(signedInAuth),
            appStartupProvider.overrideWith(_ClientStartup.new),
            // This test supplies complete DTO fixtures and does not exercise HTTP.
            authenticatedSessionScopeKeyProvider.overrideWithValue(null),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final cardState = tester.state(find.byType(RequestWithOffers));
      final hours = find.widgetWithText(ChoiceChip, 'per hour');
      await tester.ensureVisible(hours);
      await tester.tap(hours);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(FilterChip));
      await tester.tap(find.byType(FilterChip));
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilterChip>(find.byType(FilterChip)).selected,
        isTrue,
      );
      expect(
        tester
            .widgetList<OfferFlowCard>(find.byType(OfferFlowCard))
            .map((card) => card.offer.id),
        ['hour-cheap'],
      );

      // Uses OfferTile's actual chat callback and MainAppBar's actual Back action.
      final chat = find.byTooltip('Chat');
      await tester.ensureVisible(chat);
      await tester.tap(chat);
      await tester.pumpAndSettle();
      expect(find.text('Test thread'), findsOneWidget);
      expect(
        GoRouterState.of(tester.element(find.text('Test thread'))).uri.path,
        '${AppRoutes.clientChatList}/direct/offer-chat',
      );
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        AppRoutes.clientRequests,
      );
      expect(tester.state(find.byType(RequestWithOffers)), same(cardState));
      expect(tester.widget<ChoiceChip>(hours).selected, isTrue);
      expect(
        tester.widget<FilterChip>(find.byType(FilterChip)).selected,
        isTrue,
      );
      expect(
        tester
            .widgetList<OfferFlowCard>(find.byType(OfferFlowCard))
            .map((card) => card.offer.id),
        ['hour-cheap'],
      );
      expect(tester.takeException(), isNull);
    },
  );
}

OfferModel _offer(String id, int price, {String unit = 'PER_HOUR'}) =>
    OfferModel(
      id: id,
      status: OfferStatus.created,
      requestId: 'request-1',
      chatId: 'offer-chat',
      equipmentId: 'equipment-$id',
      price: price,
      priceRate: priceRateOptions.firstWhere((option) => option.value == unit),
      owner: UserModel(firstName: id),
    );
