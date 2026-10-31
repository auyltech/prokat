import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/layout/reveal_client_orders_after_tender_accept.dart';

void main() {
  Future<GoRouter> pumpRoutes(
    WidgetTester tester, {
    String initial = AppRoutes.clientRequests,
  }) async {
    final router = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(
          path: AppRoutes.clientRequests,
          builder: (context, state) => Scaffold(
            body: Column(
              children: [
                TextButton(
                  onPressed: () =>
                      TenderAcceptNavigation.capture(context)
                          .revealClientOrders(chatId: 'offer-chat'),
                  child: const Text('Accept from list'),
                ),
                TextButton(
                  onPressed: () =>
                      TenderAcceptNavigation.capture(context)
                          .revealClientOrders(),
                  child: const Text('Legacy accept'),
                ),
                TextButton(
                  onPressed: () =>
                      unawaited(context.push('/client/chat/direct/offer-chat')),
                  child: const Text('Open chat'),
                ),
              ],
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.clientOrders,
          builder: (context, state) => const Scaffold(body: Text('Orders')),
        ),
        GoRoute(
          path: '/client/chat/direct/:id',
          builder: (context, state) => Scaffold(
            body: Column(
              children: [
                Text('Chat: ${state.pathParameters['id']!}'),
                TextButton(
                  onPressed: () =>
                      TenderAcceptNavigation.capture(context)
                          .revealClientOrders(chatId: 'wrong-chat'),
                  child: const Text('Accept in chat'),
                ),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Back from chat'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('accept from list opens that chat and returns to orders', (
    tester,
  ) async {
    await pumpRoutes(tester);
    await tester.tap(find.text('Accept from list'));
    await tester.pumpAndSettle();
    expect(find.text('Chat: offer-chat'), findsOneWidget);
    await tester.tap(find.text('Back from chat'));
    await tester.pumpAndSettle();
    expect(find.text('Orders'), findsOneWidget);
  });

  testWidgets('accept within request chat preserves the current thread', (
    tester,
  ) async {
    await pumpRoutes(tester);
    await tester.tap(find.text('Open chat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accept in chat'));
    await tester.pumpAndSettle();
    expect(find.text('Chat: offer-chat'), findsOneWidget);
    expect(find.text('Chat: wrong-chat'), findsNothing);
    await tester.tap(find.text('Back from chat'));
    await tester.pumpAndSettle();
    expect(find.text('Orders'), findsOneWidget);
  });

  testWidgets('legacy callers still reveal orders without a new chat', (
    tester,
  ) async {
    await pumpRoutes(tester);
    await tester.tap(find.text('Legacy accept'));
    await tester.pumpAndSettle();
    expect(find.text('Orders'), findsOneWidget);
  });
}
