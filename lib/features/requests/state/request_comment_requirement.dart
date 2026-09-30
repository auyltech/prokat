import 'package:prokat/features/categories/models/category.dart';

/// Catch-all categories where the client must describe the equipment.
const requestCommentRequiredSlugs = <String>{
  'mc_type_other_machinery',
  'eq_type_other_equipment',
};

const _requestCommentRequiredNames = <String>{
  'другая техника',
  'прочее оборудование',
  'other equipment',
  'other machinery',
  'басқа жабдық',
  'басқа техника',
};

bool requestCategoryRequiresComment(Category category) {
  final slug = category.slug?.trim().toLowerCase() ?? '';
  if (requestCommentRequiredSlugs.contains(slug)) return true;

  final labels = <String>[
    category.name,
    category.names.en,
    category.names.ru,
    category.names.kk,
  ];
  for (final label in labels) {
    if (_requestCommentRequiredNames.contains(label.trim().toLowerCase())) {
      return true;
    }
  }
  return false;
}
