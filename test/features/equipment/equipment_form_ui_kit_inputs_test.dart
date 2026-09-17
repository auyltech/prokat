import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('active equipment forms use only UI kit input fields', () {
    const paths = [
      'lib/features/equipment/screens/create_equipment_screen.dart',
      'lib/features/equipment/widgets/owner/general_info_section.dart',
      'lib/features/equipment/widgets/owner/registration_section.dart',
      'lib/features/equipment/widgets/owner/owner_tariff_card.dart',
      'lib/features/equipment/widgets/owner/owner_equipment_specs.dart',
    ];

    final legacyInput = RegExp(r'(^|[^A-Za-z])InputField\(');
    final rawTextField = RegExp(r'(^|[^A-Za-z])Text(Form)?Field\(');

    for (final path in paths) {
      final source = File(path).readAsStringSync();
      expect(
        source.contains('core/widgets/input_field.dart'),
        isFalse,
        reason: '$path must import inputs through the UI kit barrel',
      );
      expect(
        legacyInput.hasMatch(source),
        isFalse,
        reason: '$path must not use the legacy InputField',
      );
      expect(
        rawTextField.hasMatch(source),
        isFalse,
        reason: '$path must not use raw Flutter text fields',
      );
      expect(
        source.contains('DropdownButton'),
        isFalse,
        reason: '$path must use AppDropdownField',
      );
      expect(
        source.contains('_OutlineDropdown'),
        isFalse,
        reason: '$path must not define a local dropdown',
      );
    }
  });
}
