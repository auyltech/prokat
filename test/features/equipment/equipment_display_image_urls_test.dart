import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/equipment/models/equipment_image_model.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';

Equipment _equipment({
  String? imageUrl,
  List<EquipmentImage> images = const [],
}) {
  return Equipment(
    id: 'eq-1',
    name: 'Truck',
    model: 'MB',
    status: EquipmentStatus.accepted,
    isVisible: true,
    categoryId: 'cat-1',
    imageUrl: imageUrl,
    images: images,
    prices: const [],
  );
}

void main() {
  group('Equipment.displayImageUrls', () {
    test('falls back to legacy imageUrl', () {
      final equipment = _equipment(imageUrl: 'https://example.com/legacy.jpg');
      expect(equipment.displayImageUrls, ['https://example.com/legacy.jpg']);
      expect(equipment.primaryImageUrl, 'https://example.com/legacy.jpg');
    });

    test('puts primary first, then order', () {
      final equipment = _equipment(
        images: const [
          EquipmentImage(
            id: '2',
            imageUrl: 'https://example.com/2.jpg',
            order: 2,
          ),
          EquipmentImage(
            id: '1',
            imageUrl: 'https://example.com/1.jpg',
            isPrimary: true,
            order: 9,
          ),
          EquipmentImage(
            id: '3',
            imageUrl: 'https://example.com/3.jpg',
            order: 1,
          ),
        ],
      );

      expect(equipment.displayImageUrls, [
        'https://example.com/1.jpg',
        'https://example.com/3.jpg',
        'https://example.com/2.jpg',
      ]);
    });

    test('ignores blank urls', () {
      final equipment = _equipment(
        imageUrl: ' ',
        images: const [
          EquipmentImage(id: 'blank', imageUrl: '  '),
          EquipmentImage(id: 'ok', imageUrl: 'https://example.com/ok.jpg'),
        ],
      );
      expect(equipment.displayImageUrls, ['https://example.com/ok.jpg']);
    });
  });
}
