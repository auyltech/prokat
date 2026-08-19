import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/equipment/providers/equipment_dependencies.dart'
    as dependencies;
import 'package:prokat/features/equipment/providers/equipment_provider.dart'
    as providers;
import 'package:prokat/features/equipment/providers/guest_equipment_provider.dart'
    as guest_providers;

void main() {
  test('equipmentServiceProvider has a single provider identity', () {
    expect(
      identical(
        dependencies.equipmentServiceProvider,
        providers.equipmentServiceProvider,
      ),
      isTrue,
    );
    expect(
      identical(
        dependencies.equipmentServiceProvider,
        guest_providers.equipmentServiceProvider,
      ),
      isTrue,
    );
  });
}
