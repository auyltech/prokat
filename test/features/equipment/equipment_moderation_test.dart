import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/equipment/models/equipment_image_model.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/utils/equipment_submit_readiness.dart';

Equipment _equipment({
  EquipmentStatus status = EquipmentStatus.draft,
  String name = 'Vacuum truck',
  String model = 'MB',
  String? plateNumber = '123ABC01',
  String? city = 'Almaty',
  String? imageUrl = 'https://example.com/truck.jpg',
  List<EquipmentImage> images = const [],
}) {
  return Equipment(
    id: 'eq-1',
    name: name,
    model: model,
    plateNumber: plateNumber,
    status: status,
    isVisible: true,
    city: city,
    categoryId: 'cat-1',
    imageUrl: imageUrl,
    images: images,
    prices: const [],
  );
}

void main() {
  group('Equipment moderation helpers', () {
    test('draft can be edited and submitted', () {
      final equipment = _equipment();
      expect(equipment.isDraft, isTrue);
      expect(equipment.isPendingReview, isFalse);
      expect(equipment.isRejected, isFalse);
      expect(equipment.isModerated, isFalse);
    });

    test('created is pending review, not draft', () {
      final equipment = _equipment(status: EquipmentStatus.created);
      expect(equipment.isDraft, isFalse);
      expect(equipment.isPendingReview, isTrue);
      expect(equipment.isRejected, isFalse);
      expect(equipment.isModerated, isFalse);
    });

    test('rejected is draft-like for edits, not pending', () {
      final equipment = _equipment(status: EquipmentStatus.rejected);
      expect(equipment.isDraft, isTrue);
      expect(equipment.isPendingReview, isFalse);
      expect(equipment.isRejected, isTrue);
    });

    test('accepted hides photo camera via isDraft', () {
      final equipment = _equipment(status: EquipmentStatus.accepted);
      expect(equipment.isDraft, isFalse);
      expect(equipment.isModerated, isTrue);
    });
  });

  group('OwnerEquipmentReviewUi', () {
    test('draft shows submit when clean and save-all when dirty', () {
      expect(
        OwnerEquipmentReviewUi.from(
          status: EquipmentStatus.draft,
          anyDirty: false,
        ).showSubmitForReview,
        isTrue,
      );
      expect(
        OwnerEquipmentReviewUi.from(
          status: EquipmentStatus.draft,
          anyDirty: true,
        ).showSaveAll,
        isTrue,
      );
      expect(
        OwnerEquipmentReviewUi.from(
          status: EquipmentStatus.draft,
          anyDirty: true,
        ).showSubmitForReview,
        isFalse,
      );
    });

    test('created pending never shows submit or resubmit', () {
      final ui = OwnerEquipmentReviewUi.from(
        status: EquipmentStatus.created,
        anyDirty: true,
      );
      expect(ui.showSaveAll, isFalse);
      expect(ui.showSubmitForReview, isFalse);
      expect(ui.showResubmit, isFalse);
    });

    test('rejected always shows resubmit, never first-submit', () {
      final clean = OwnerEquipmentReviewUi.from(
        status: EquipmentStatus.rejected,
        anyDirty: false,
      );
      final dirty = OwnerEquipmentReviewUi.from(
        status: EquipmentStatus.rejected,
        anyDirty: true,
      );
      expect(clean.showResubmit, isTrue);
      expect(clean.showSubmitForReview, isFalse);
      expect(clean.showSaveAll, isFalse);
      expect(dirty.showResubmit, isTrue);
      expect(dirty.showSaveAll, isFalse);
    });

    test('approved shows save-all when dirty, never resubmit', () {
      final ui = OwnerEquipmentReviewUi.from(
        status: EquipmentStatus.accepted,
        anyDirty: true,
      );
      expect(ui.showSaveAll, isTrue);
      expect(ui.showResubmit, isFalse);
      expect(ui.showSubmitForReview, isFalse);
    });
  });

  group('equipment review fingerprint', () {
    test('changes when an input field changes', () {
      final original = _equipment();
      final edited = original.copyWith(name: 'Updated name');
      expect(
        equipmentReviewFingerprint(original),
        isNot(equipmentReviewFingerprint(edited)),
      );
    });

    test('is ready only with a photo', () {
      final withPhoto = _equipment(
        images: const [
          EquipmentImage(id: 'img-1', imageUrl: 'https://example.com/a.jpg'),
        ],
        imageUrl: null,
      );
      final withoutPhoto = _equipment(imageUrl: null, images: const []);
      expect(equipmentHasImage(withPhoto), isTrue);
      expect(equipmentHasImage(withoutPhoto), isFalse);
      expect(isEquipmentReadyForReview(withoutPhoto), isFalse);
    });
  });
}
