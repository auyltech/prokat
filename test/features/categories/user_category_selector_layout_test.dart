import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/categories/state/categories_notifier.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/categories/widgets/user_category_selector.dart';
import 'package:prokat/features/equipment_demand/equipment_demand_models.dart';
import 'package:prokat/features/equipment_demand/equipment_demand_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class _TestCategoriesNotifier extends CategoriesNotifier {
  @override
  Future<QueryState<Category>> build() async => const QueryState(
    items: [Category(id: 'category-1', name: 'Excavators', sortIndex: 1)],
    itemsPerPage: 1,
    count: 1,
  );
}

class _TestDemandConfigNotifier extends DemandConfigNotifier {
  @override
  Future<DemandConfig> build() async => const DemandConfig.disabled();
}

void main() {
  testWidgets('category row has finite height inside a vertical ListView', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoriesProvider.overrideWith(_TestCategoriesNotifier.new),
          demandConfigProvider.overrideWith(_TestDemandConfigNotifier.new),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: const [UserCategorySelector(mode: 'search')],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(UserCategorySelector)).height, 132);
  });
}
