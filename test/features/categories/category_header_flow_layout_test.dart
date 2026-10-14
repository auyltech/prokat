import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/core/widgets/app_category_info.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/categories/state/browse_group_session.dart';
import 'package:prokat/features/categories/state/categories_notifier.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/categories/widgets/category_header_card.dart';
import 'package:prokat/features/categories/widgets/category_picker_sheet.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';
import 'package:prokat/features/equipment/state/equipment_service.dart';
import 'package:prokat/l10n/app_localizations.dart';

const _category = Category(
  id: 'machinery-1',
  name: 'Excavators with a very long category name',
  sortIndex: 1,
);

const _lateCategory = Category(
  id: 'machinery-7',
  name: 'Drilling rigs',
  sortIndex: 7,
);
const _catalogCategories = [
  _category,
  Category(id: 'machinery-2', name: 'Bulldozers', sortIndex: 2),
  Category(id: 'machinery-3', name: 'Dump trucks', sortIndex: 3),
  Category(id: 'machinery-4', name: 'Motor graders', sortIndex: 4),
  Category(id: 'machinery-5', name: 'Cranes', sortIndex: 5),
  Category(id: 'machinery-6', name: 'Forklifts', sortIndex: 6),
  _lateCategory,
  Category(
    id: 'equipment-1',
    name: 'Generators',
    sortIndex: 8,
    catalogGroup: CatalogGroup.equipment,
  ),
];

class _Categories extends CategoriesNotifier {
  @override
  Future<QueryState<Category>> build() async =>
      const QueryState(items: _catalogCategories, itemsPerPage: 8, count: 8);
}

class _UnusedEquipmentService implements EquipmentService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        categoriesProvider.overrideWith(_Categories.new),
        equipmentServiceProvider.overrideWithValue(_UnusedEquipmentService()),
      ],
    );
    addTearDown(container.dispose);
    final sessions = container.read(browseGroupSessionsProvider.notifier);
    sessions.ensure(CatalogGroup.machinery);
    sessions.setQuery('loader');
    container
        .read(browseCatalogGroupProvider.notifier)
        .select(CatalogGroup.equipment);
    sessions.ensure(CatalogGroup.equipment);
    sessions.setQuery('drill');
    container
        .read(browseCatalogGroupProvider.notifier)
        .select(CatalogGroup.machinery);
    return container;
  }

  Future<void> pumpHeader(
    WidgetTester tester,
    ProviderContainer container, {
    bool flow = true,
    double textScale = 1,
    bool dark = false,
  }) async {
    const header = CategoryHeaderCard(group: CatalogGroup.machinery);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (flow)
                  ProkatFlowScope(
                    palette: dark
                        ? ProkatFlowPalette.dark
                        : ProkatFlowPalette.light,
                    child: header,
                  )
                else
                  header,
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void expectSelectedAtStart(WidgetTester tester, String title) {
    final strip = find.byType(SingleChildScrollView);
    final viewport = tester.getRect(strip);
    final label = find.descendant(of: strip, matching: find.text(title));
    final labelRect = tester.getRect(label);
    expect(tester.widget<SingleChildScrollView>(strip).controller!.offset, 0);
    expect(labelRect.left, closeTo(viewport.left + 16, 0.01));
    expect(labelRect.left, lessThan(viewport.right));
    expect(labelRect.right, greaterThan(viewport.left));
    final chip = tester
        .widgetList<Semantics>(
          find.descendant(of: strip, matching: find.byType(Semantics)),
        )
        .singleWhere((widget) => widget.properties.label == title);
    expect(chip.properties.selected, isTrue);
  }

  for (final dark in [false, true]) {
    testWidgets(
      'scoped header stays usable at 320px and text scale 2, dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final container = makeContainer();
        container
            .read(selectedBrowseCategoryProvider.notifier)
            .select(_category);
        await pumpHeader(tester, container, textScale: 2, dark: dark);

        expect(tester.takeException(), isNull);
        expect(find.byType(TextField).hitTestable(), findsOneWidget);
        expect(find.byType(AppCategoryInfo), findsNothing);
        expect(find.byType(AspectRatio), findsNothing);
        final picker = find.byTooltip('Select category: ${_category.name}');
        expect(picker.hitTestable(), findsOneWidget);
        expect(
          tester.getRect(find.byType(TextField)).right,
          lessThan(tester.getRect(picker).left),
        );
        final strip = find.byType(SingleChildScrollView);
        expect(
          tester.widget<SingleChildScrollView>(strip).scrollDirection,
          Axis.horizontal,
        );
        expect(
          tester.getRect(strip).top,
          greaterThan(tester.getRect(find.byType(TextField)).bottom),
        );

        await tester.tap(find.byTooltip('Clear search'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(TextField).hitTestable(), findsOneWidget);
        expect(find.byTooltip('Clear search'), findsNothing);
        final sessions = container.read(browseGroupSessionsProvider.notifier);
        expect(sessions.peek(CatalogGroup.machinery)?.query, '');
        expect(sessions.peek(CatalogGroup.equipment)?.query, 'drill');
        expect(container.read(searchEquipmentProvider).query, '');
      },
    );
  }

  testWidgets(
    'scoped picker keeps selection and clears only the active query',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = makeContainer();
      await pumpHeader(tester, container, textScale: 2);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
            .controller!
            .offset,
        greaterThan(0),
      );
      Future<void> scrollPickerTo(String title, double delta) async {
        await tester.scrollUntilVisible(
          find.descendant(
            of: find.byType(DraggableScrollableSheet),
            matching: find.text(title),
          ),
          delta,
          scrollable: find.descendant(
            of: find.byType(DraggableScrollableSheet),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.pumpAndSettle();
      }

      await tester.tap(find.byTooltip('Select category: All categories'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ProkatFlowScope), findsNWidgets(2));
      expect(find.text('All categories'), findsNWidgets(2));
      await scrollPickerTo(_lateCategory.name, 160);
      final sheetCategory = find.descendant(
        of: find.byType(DraggableScrollableSheet),
        matching: find.text(_lateCategory.name),
      );
      final thumbnail = find
          .descendant(
            of: find.byType(DraggableScrollableSheet),
            matching: find.byType(AspectRatio),
          )
          .first;
      final size = tester.getSize(thumbnail);
      expect(size.width / size.height, closeTo(4 / 3, 0.001));
      await tester.tap(sheetCategory);
      await tester.pumpAndSettle();

      expect(
        container.read(selectedBrowseCategoryProvider)?.id,
        _lateCategory.id,
      );
      final sessions = container.read(browseGroupSessionsProvider.notifier);
      expect(sessions.peek(CatalogGroup.machinery)?.query, '');
      expect(sessions.peek(CatalogGroup.equipment)?.query, 'drill');
      expect(find.byType(TextField).hitTestable(), findsOneWidget);
      expectSelectedAtStart(tester, _lateCategory.name);

      await tester.tap(
        find.byTooltip('Select category: ${_lateCategory.name}'),
      );
      await tester.pumpAndSettle();
      await scrollPickerTo(_lateCategory.name, 160);
      final selected = tester
          .widgetList<Semantics>(
            find.descendant(
              of: find.byType(DraggableScrollableSheet),
              matching: find.byType(Semantics),
            ),
          )
          .where((widget) => widget.properties.label == _lateCategory.name);
      expect(selected.single.properties.selected, isTrue);
      await scrollPickerTo('All categories', -160);
      await tester.tap(
        find.descendant(
          of: find.byType(DraggableScrollableSheet),
          matching: find.text('All categories'),
        ),
      );
      await tester.pumpAndSettle();
      expect(container.read(selectedBrowseCategoryProvider), isNull);
    },
  );

  testWidgets(
    'quick chips select, reset, and retain an additional picked category',
    (tester) async {
      final container = makeContainer();
      await pumpHeader(tester, container);
      expect(find.text('Generators'), findsNothing);
      expect(find.text(_lateCategory.name), findsNothing);

      await tester.ensureVisible(find.text('Bulldozers'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bulldozers'));
      await tester.pumpAndSettle();
      expect(container.read(selectedBrowseCategoryProvider)?.id, 'machinery-2');
      final sessions = container.read(browseGroupSessionsProvider.notifier);
      expect(sessions.peek(CatalogGroup.machinery)?.query, '');
      expect(sessions.peek(CatalogGroup.equipment)?.query, 'drill');
      final selectedChip = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .singleWhere((widget) => widget.properties.label == 'Bulldozers');
      expect(selectedChip.properties.selected, isTrue);
      expectSelectedAtStart(tester, 'Bulldozers');

      await tester.ensureVisible(find.text('All categories'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('All categories'));
      await tester.pumpAndSettle();
      expect(container.read(selectedBrowseCategoryProvider), isNull);

      container
          .read(selectedBrowseCategoryProvider.notifier)
          .select(_lateCategory);
      await tester.pumpAndSettle();
      expect(find.text(_lateCategory.name), findsOneWidget);
      expectSelectedAtStart(tester, _lateCategory.name);
      expect(find.text(_lateCategory.name).hitTestable(), findsOneWidget);
      await tester.tap(find.text(_lateCategory.name));
      await tester.pumpAndSettle();
      expect(container.read(selectedBrowseCategoryProvider), isNull);
      expect(sessions.peek(CatalogGroup.equipment)?.query, 'drill');
    },
  );

  testWidgets(
    'unscoped header retains expandable search and category details',
    (tester) async {
      await pumpHeader(tester, makeContainer(), flow: false);
      expect(tester.takeException(), isNull);
      expect(find.byType(AppCategoryInfo), findsOneWidget);
      expect(find.byType(TextField).hitTestable(), findsNothing);
      await tester.tap(find.byTooltip('Search'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField).hitTestable(), findsOneWidget);
    },
  );

  testWidgets('picker still supports mutation flows without the all option', (
    tester,
  ) async {
    CategoryPickerResult? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await CategoryPickerSheet.show(
                  context,
                  categories: [_category],
                  group: CatalogGroup.machinery,
                  selectedId: _category.id,
                  includeAllOption: false,
                );
              },
              child: const Text('Open picker'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open picker'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('All categories'), findsNothing);
    await tester.tap(find.text(_category.name));
    await tester.pumpAndSettle();
    expect(result?.category?.id, _category.id);
    expect(result?.isAll, isFalse);
  });
}
