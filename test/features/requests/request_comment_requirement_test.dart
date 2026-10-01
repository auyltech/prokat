import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/features/catalog/models/localized_names.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/requests/state/request_comment_requirement.dart';

Category _category({
  String? slug,
  String name = 'Excavators',
  LocalizedNames names = const LocalizedNames(
    en: 'Excavators',
    ru: 'Экскаваторы',
  ),
  CatalogGroup group = CatalogGroup.machinery,
}) {
  return Category(
    id: 'id',
    name: name,
    sortIndex: 0,
    slug: slug,
    names: names,
    catalogGroup: group,
  );
}

void main() {
  test('catch-all categories require a comment', () {
    expect(
      requestCategoryRequiresComment(
        _category(slug: 'eq_type_other_equipment', name: 'Other Equipment'),
      ),
      isTrue,
    );
    expect(
      requestCategoryRequiresComment(
        _category(slug: 'mc_type_other_machinery', name: 'Other machinery'),
      ),
      isTrue,
    );
    expect(
      requestCategoryRequiresComment(
        _category(
          name: 'Другая техника',
          names: const LocalizedNames(ru: 'Другая техника'),
        ),
      ),
      isTrue,
    );
    expect(
      requestCategoryRequiresComment(
        _category(
          name: 'Прочее оборудование',
          names: const LocalizedNames(ru: 'Прочее оборудование'),
          group: CatalogGroup.equipment,
        ),
      ),
      isTrue,
    );
    expect(
      requestCategoryRequiresComment(_category(slug: 'excavators')),
      isFalse,
    );
    expect(
      requestCategoryRequiresComment(
        _category(
          name: 'Оборудование',
          names: const LocalizedNames(ru: 'Оборудование'),
        ),
      ),
      isFalse,
    );
  });
}
