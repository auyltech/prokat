import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/catalog/models/catalog_bundle.dart';
import 'package:prokat/features/company_profile/company_access_screen.dart';
import 'package:prokat/features/company_profile/company_profile_api.dart';
import 'package:prokat/l10n/app_localizations.dart';

class _TestCatalog extends CatalogNotifier {
  @override
  Future<CatalogBundle> build() async =>
      CatalogBundle.fromJson({'version': 'test'});
}

void main() {
  testWidgets('approved entry shows company name and direct-entry caption', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          companyAccessProvider.overrideWith(
            (ref) async => {
              'memberships': [
                {
                  'companyId': 'company',
                  'company': {'status': 'APPROVED', 'name': 'Ковши и лебёдки'},
                },
              ],
              'invitations': [],
            },
          ),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const Scaffold(body: CompanyEntryTile()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Перейти в профиль компании'), findsOneWidget);
    expect(find.text('Ковши и лебёдки'), findsOneWidget);
    expect(find.text('Разместите услуги вашей компании здесь'), findsNothing);
  });

  testWidgets('invitation is separated from company registration', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          companyAccessProvider.overrideWith(
            (ref) async => {
              'memberships': [],
              'invitations': [
                {
                  'id': 'invite',
                  'company': {'id': 'company', 'name': 'Компания'},
                },
              ],
            },
          ),
          catalogProvider.overrideWith(_TestCatalog.new),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CompanyAccessScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Присоединиться'), findsOneWidget);
    expect(find.byType(Form), findsNothing);
    expect(find.text('Отправить заявку'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'invalid application keeps field errors without reloading access',
    (tester) async {
      var loads = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            companyAccessProvider.overrideWith((ref) async {
              loads++;
              return {'memberships': [], 'invitations': []};
            }),
            catalogProvider.overrideWith(_TestCatalog.new),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            locale: const Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const CompanyAccessScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final submit = find.widgetWithText(AppElevatedButton, 'Отправить заявку');
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(loads, 1);
      expect(find.text('Выберите город'), findsWidgets);
      expect(find.text('Введите 12 цифр БИН'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
