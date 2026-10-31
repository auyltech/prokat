import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/equipment/models/equipment_summary_model.dart';
import 'package:prokat/features/offers/widgets/offer_equipment_picker.dart';

import '../user_safety/user_safety_test_support.dart';

void main() {
  testWidgets(
    'equipment picker can be reopened and changed with compact previews',
    (tester) async {
      final first = EquipmentSummaryModel(
        id: 'one',
        name: 'Truck one',
        model: 'Model A',
        plateNumber: '111 AAA',
      );
      final second = EquipmentSummaryModel(
        id: 'two',
        name: 'Truck two',
        model: 'Model B',
        plateNumber: '222 BBB',
      );
      EquipmentSummaryModel? selected;
      await tester.pumpWidget(
        testApp(
          overrides: [],
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, update) => OfferEquipmentPicker(
                value: selected,
                options: [first, second],
                onChanged: (value) => update(() => selected = value),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(find.text('Model A'), findsOneWidget);
      expect(find.text('111 AAA'), findsOneWidget);
      await tester.tap(find.text('Truck one'));
      await tester.pumpAndSettle();
      expect(selected?.id, 'one');
      await tester.tap(find.text('Truck one'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Truck two'));
      await tester.pumpAndSettle();
      expect(selected?.id, 'two');
      expect(tester.takeException(), isNull);
    },
  );
}
