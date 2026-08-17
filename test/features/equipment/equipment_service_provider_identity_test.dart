import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart'
    as client_dependencies;
import 'package:prokat/features/equipment/providers/guest_equipment_provider.dart'
    as guest_dependencies;

void main() {
  test('equipmentServiceProvider has a single provider identity', () {
    expect(
      identical(
        client_dependencies.equipmentServiceProvider,
        guest_dependencies.equipmentServiceProvider,
      ),
      isTrue,
    );
  });
}
