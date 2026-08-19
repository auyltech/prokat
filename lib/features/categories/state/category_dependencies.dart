import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/features/categories/state/category_service.dart';

final categoryServiceProvider = Provider<CategoryService>((ref) {
  return CategoryService(ref.watch(apiClientProvider));
});
