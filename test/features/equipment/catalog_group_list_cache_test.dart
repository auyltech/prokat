import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/state/catalog_group_list_cache.dart';

void main() {
  test('CatalogGroupListCache restores matching group snapshot', () {
    final cache = CatalogGroupListCache();
    const machinery = AsyncData(
      QueryState<Equipment>(items: [], itemsPerPage: 10, count: 0),
    );
    const equipment = AsyncData(
      QueryState<Equipment>(items: [], itemsPerPage: 10, count: 3),
    );

    cache.save(
      catalogGroup: 'MACHINERY',
      query: 'crane',
      city: 'atyrau',
      categoryId: null,
      spec: const [],
      value: machinery,
    );
    cache.save(
      catalogGroup: 'EQUIPMENT',
      query: '',
      city: 'atyrau',
      categoryId: 'e1',
      spec: const [],
      value: equipment,
    );

    expect(
      cache.restoreIfMatch(
        catalogGroup: 'MACHINERY',
        query: 'crane',
        city: 'atyrau',
        categoryId: null,
        spec: const [],
      ),
      machinery,
    );
    expect(
      cache.restoreIfMatch(
        catalogGroup: 'EQUIPMENT',
        query: '',
        city: 'atyrau',
        categoryId: 'e1',
        spec: const [],
      ),
      equipment,
    );
    expect(
      cache.restoreIfMatch(
        catalogGroup: 'MACHINERY',
        query: 'other',
        city: 'atyrau',
        categoryId: null,
        spec: const [],
      ),
      isNull,
    );
    expect(cache.has('EQUIPMENT'), isTrue);
    expect(cache.has('UNKNOWN'), isFalse);
  });
}
