import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('migrated feature sheets do not call showModalBottomSheet directly', () {
    const paths = [
      'lib/core/widgets/job_schedule_section.dart',
      'lib/features/bookings/widgets/show_location_sheet.dart',
      'lib/features/locations/widgets/select_address_sheet.dart',
      'lib/features/user/widgets/city_picker_sheet.dart',
      'lib/features/appstatic/widgets/language_sheet.dart',
      'lib/features/user/widgets/theme_selection_sheet.dart',
      'lib/features/equipment/widgets/equipment_details_sheet.dart',
      'lib/features/price_negotiations/widgets/counter_offer_sheet.dart',
      'lib/features/bookings/widgets/booking_status_sheet.dart',
      'lib/features/bookings/widgets/cancel_booking_sheet.dart',
      'lib/features/bookings/widgets/cancel_booking_reason_sheet.dart',
      'lib/features/reviews/widgets/review_sheet.dart',
      'lib/features/equipment/widgets/owner/equipment_image_actions_sheet.dart',
    ];

    for (final path in paths) {
      final source = File(path).readAsStringSync();
      expect(
        source.contains('showModalBottomSheet'),
        isFalse,
        reason: '$path must use AppBottomSheet',
      );
    }
  });

  test('variable-length pickers use scrollable AppBottomSheet', () {
    const paths = [
      'lib/features/locations/widgets/select_address_sheet.dart',
      'lib/features/user/widgets/city_picker_sheet.dart',
    ];

    for (final path in paths) {
      final source = File(path).readAsStringSync();
      expect(
        source.contains('AppBottomSheet.showScrollable'),
        isTrue,
        reason: '$path must support a variable-length list',
      );
    }
  });

  test('fixed-content sheets use non-draggable AppBottomSheet', () {
    const paths = [
      'lib/features/appstatic/widgets/language_sheet.dart',
      'lib/features/user/widgets/theme_selection_sheet.dart',
      'lib/features/equipment/widgets/equipment_details_sheet.dart',
      'lib/features/price_negotiations/widgets/counter_offer_sheet.dart',
      'lib/features/bookings/widgets/booking_status_sheet.dart',
      'lib/features/bookings/widgets/cancel_booking_sheet.dart',
      'lib/features/bookings/widgets/cancel_booking_reason_sheet.dart',
      'lib/features/reviews/widgets/review_sheet.dart',
      'lib/features/equipment/widgets/owner/equipment_image_actions_sheet.dart',
    ];

    for (final path in paths) {
      final source = File(path).readAsStringSync();
      expect(
        source.contains('AppBottomSheet.show<'),
        isTrue,
        reason: '$path must use the fixed-content AppBottomSheet',
      );
      expect(source.contains('AppBottomSheet.showScrollable'), isFalse);
    }
  });
}
