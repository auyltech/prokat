import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/catalog/models/catalog_bundle.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/categories/state/browse_group_session.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/equipment/state/equipment_mutation_state.dart';
import 'package:prokat/features/requests/state/request_state.dart';

void main() {
  test('CatalogGroup.fromApi falls back to machinery', () {
    expect(CatalogGroup.fromApi(null), CatalogGroup.machinery);
    expect(CatalogGroup.fromApi(''), CatalogGroup.machinery);
    expect(CatalogGroup.fromApi('unknown'), CatalogGroup.machinery);
    expect(CatalogGroup.fromApi('EQUIPMENT'), CatalogGroup.equipment);
    expect(CatalogGroup.fromApi('machinery'), CatalogGroup.machinery);
  });

  test('CatalogCategory parses descriptions and missing catalogGroup', () {
    final category = CatalogCategory.fromJson({
      'id': 'c1',
      'slug': 'vacuum_trucks',
      'names': {'ru': 'Вакуумные'},
      'descriptions': {
        'ru': 'Машины для откачки',
        'en': 'Vacuum trucks',
        'kk': 'Вакуумдық машиналар',
      },
      'sortIndex': 1,
      'isUserVisible': true,
      'isOwnerVisible': true,
    });
    expect(category.catalogGroup, CatalogGroup.machinery);
    expect(category.description('ru'), 'Машины для откачки');
    expect(category.description('en'), 'Vacuum trucks');
  });

  test('CatalogCategory tolerates missing descriptions', () {
    final category = CatalogCategory.fromJson({
      'id': 'c1',
      'slug': 'vacuum_trucks',
      'names': {'ru': 'Вакуумные'},
      'sortIndex': 1,
      'isUserVisible': true,
      'isOwnerVisible': true,
    });
    expect(category.descriptions.isEmpty, isTrue);
    expect(category.description('ru'), '');
  });

  test('Category.fromCatalog keeps descriptions', () {
    final catalog = CatalogCategory.fromJson({
      'id': 'c1',
      'slug': 'pumps',
      'names': {'en': 'Pumps', 'ru': 'Насосы'},
      'descriptions': {'ru': 'Водяные насосы'},
      'catalogGroup': 'EQUIPMENT',
      'sortIndex': 2,
      'isUserVisible': true,
      'isOwnerVisible': true,
    });
    final category = Category.fromCatalog(catalog);
    expect(category.catalogGroup, CatalogGroup.equipment);
    expect(category.localizedDescription('ru'), 'Водяные насосы');
  });

  test('userVisibleCatalogGroups hides empty equipment tab', () {
    final bundle = CatalogBundle.fromJson({
      'version': 't',
      'categories': [
        {
          'id': 'm1',
          'slug': 'vacuum_trucks',
          'names': {'ru': 'Вакуумные'},
          'isUserVisible': true,
          'isOwnerVisible': true,
          'catalogGroup': 'MACHINERY',
        },
        {
          'id': 'e1',
          'slug': 'eq_type_compressor',
          'names': {'ru': 'Компрессор'},
          'isUserVisible': false,
          'isOwnerVisible': false,
          'catalogGroup': 'EQUIPMENT',
        },
      ],
    });

    expect(userVisibleCatalogGroups(bundle), [CatalogGroup.machinery]);
    expect(bundle.hasUserVisibleEquipment, isFalse);
  });

  test('browse keeps selection per group', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const machinery = Category(
      id: 'm1',
      name: 'Machinery',
      sortIndex: 1,
      catalogGroup: CatalogGroup.machinery,
    );
    const equipment = Category(
      id: 'e1',
      name: 'Equipment',
      sortIndex: 1,
      catalogGroup: CatalogGroup.equipment,
    );

    container
        .read(browseCatalogGroupProvider.notifier)
        .select(CatalogGroup.machinery);
    container.read(selectedBrowseCategoryProvider.notifier).select(machinery);
    expect(container.read(selectedBrowseCategoryProvider)?.id, 'm1');

    container
        .read(browseCatalogGroupProvider.notifier)
        .select(CatalogGroup.equipment);
    expect(container.read(selectedBrowseCategoryProvider), isNull);

    container.read(selectedBrowseCategoryProvider.notifier).select(equipment);
    expect(container.read(selectedBrowseCategoryProvider)?.id, 'e1');

    container
        .read(browseCatalogGroupProvider.notifier)
        .select(CatalogGroup.machinery);
    expect(container.read(selectedBrowseCategoryProvider)?.id, 'm1');
  });

  test('browse group sessions are lazy and sticky', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final sessions = container.read(browseGroupSessionsProvider.notifier);

    expect(sessions.isInitialized(CatalogGroup.machinery), isFalse);
    expect(sessions.isInitialized(CatalogGroup.equipment), isFalse);

    sessions.ensure(CatalogGroup.machinery);
    sessions.setQuery('crane');
    sessions.setSearchExpanded(true);

    expect(sessions.isInitialized(CatalogGroup.machinery), isTrue);
    expect(sessions.isInitialized(CatalogGroup.equipment), isFalse);
    expect(container.read(currentBrowseGroupSessionProvider).query, 'crane');
    expect(
      container.read(currentBrowseGroupSessionProvider).searchExpanded,
      isTrue,
    );

    container
        .read(browseCatalogGroupProvider.notifier)
        .select(CatalogGroup.equipment);
    sessions.ensure(CatalogGroup.equipment);
    expect(container.read(currentBrowseGroupSessionProvider).query, '');
    expect(
      container.read(currentBrowseGroupSessionProvider).searchExpanded,
      isFalse,
    );

    sessions.setQuery('pump');
    container
        .read(browseCatalogGroupProvider.notifier)
        .select(CatalogGroup.machinery);
    expect(container.read(currentBrowseGroupSessionProvider).query, 'crane');
    expect(
      container.read(currentBrowseGroupSessionProvider).searchExpanded,
      isTrue,
    );
    expect(
      container
          .read(browseGroupSessionsProvider)[CatalogGroup.equipment]
          ?.query,
      'pump',
    );
  });

  test('mutation group is independent from browse selection', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const machinery = Category(
      id: 'm1',
      name: 'Machinery',
      sortIndex: 1,
      catalogGroup: CatalogGroup.machinery,
    );

    container.read(selectedBrowseCategoryProvider.notifier).select(machinery);
    container
        .read(mutationCatalogGroupProvider.notifier)
        .select(CatalogGroup.equipment);

    expect(
      container.read(mutationCatalogGroupProvider),
      CatalogGroup.equipment,
    );
    expect(container.read(selectedBrowseCategoryProvider)?.id, 'm1');
  });

  test('request and equipment mutation can clear category', () {
    const category = Category(
      id: 'm1',
      name: 'Machinery',
      sortIndex: 1,
      catalogGroup: CatalogGroup.machinery,
    );

    final requestState = RequestState(
      selectedCategory: category,
      categoryId: category.id,
    ).copyWith(clearSelectedCategory: true);
    expect(requestState.selectedCategory, isNull);
    expect(requestState.categoryId, isNull);

    final equipmentState = const EquipmentMutationState(category: category)
        .copyWith(category: null);
    expect(equipmentState.category, isNull);
  });
}
