import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/companies/company_orders_screen.dart';
import 'package:prokat/features/companies/company_order_state.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';

void main() {
  testWidgets(
    'company chats exclude untouched inquiries and show last message',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            companyInquiryListProvider.overrideWith(
              (ref, companyId) async => [
                {
                  'id': 'untouched',
                  'clientName': 'Без переписки',
                  'status': 'NEW',
                  'hasChat': false,
                  'startsAt': '2026-10-02T09:00:00Z',
                },
                {
                  'id': 'discussion',
                  'clientName': 'Заказчик',
                  'status': 'PROPOSED',
                  'hasChat': true,
                  'lastMessage': 'Приедем к десяти',
                  'startsAt': '2026-10-02T09:00:00Z',
                },
              ],
            ),
          ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
            locale: Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: const CompanyOrdersScreen(companyId: 'company', chatsOnly: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Без переписки'), findsNothing);
      expect(find.text('Заказчик'), findsOneWidget);
      expect(find.text('Приедем к десяти'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
