import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/features/billing/models/account_balance_model.dart';
import 'package:prokat/features/billing/state/billing_state.dart';
import 'package:prokat/features/owner/widgets/balance_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'shared wallet panel renders company funds without accessing a personal billing provider',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var topups = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BalanceSummaryCard(
              title: 'Баланс компании',
              billingState: BillingState(
                accountBalance: AccountBalanceModel(secondsRemaining: 600000),
              ),
              ownerOnline: false,
              onlineEquipment: 0,
              onTopUp: () => topups++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Баланс компании'), findsOneWidget);
      expect(find.text('10000'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.add_rounded));
      expect(topups, 1);
    },
  );
}
