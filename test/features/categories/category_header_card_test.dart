import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/l10n/app_localizations.dart';

void main() {
  testWidgets('all-categories header copy is localized', (tester) async {
    late AppLocalizations l10n;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context)!;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(l10n.allCategories, 'Все категории');
    expect(l10n.allCategoriesMachineryDescription, isNotEmpty);
    expect(l10n.allCategoriesEquipmentDescription, isNotEmpty);
    expect(l10n.categoryFilters, 'Фильтры');
    expect(l10n.selectCategory, 'Выбрать категорию');
  });
}
