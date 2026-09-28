import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/equipment_share/equipment_share_link.dart';

void main() {
  test('accepts a trusted https equipment link', () {
    final link = EquipmentShareLink.tryParse(
      Uri.parse('https://prokat-bfbec.web.app/e/eq-1'),
    );

    expect(link?.equipmentId, 'eq-1');
    expect(link?.canonical.toString(), 'https://prokat-bfbec.web.app/e/eq-1');
  });

  test('ignores other hosts, schemes and paths', () {
    expect(
      EquipmentShareLink.tryParse(
        Uri.parse('http://prokat-bfbec.web.app/e/eq-1'),
      ),
      isNull,
    );
    expect(
      EquipmentShareLink.tryParse(Uri.parse('https://example.com/e/eq-1')),
      isNull,
    );
    expect(
      EquipmentShareLink.tryParse(Uri.parse('https://prokat-bfbec.web.app/e')),
      isNull,
    );
    expect(
      EquipmentShareLink.tryParse(
        Uri.parse('https://prokat-bfbec.web.app/e/eq-1/extra'),
      ),
      isNull,
    );
    expect(
      EquipmentShareLink.tryParse(
        Uri.parse('https://prokat-bfbec.firebaseapp.com/catalog/eq-1'),
      ),
      isNull,
    );
  });
}
