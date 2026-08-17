import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/categories/state/category_dependencies.dart'
    as dependencies;
import 'package:prokat/features/categories/state/category_provider.dart'
    as providers;

void main() {
  test('categoryServiceProvider has a single provider identity', () {
    expect(
      identical(
        dependencies.categoryServiceProvider,
        providers.categoryServiceProvider,
      ),
      isTrue,
    );
  });
}
