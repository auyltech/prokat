import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/equipment_share/equipment_share_install_referrer.dart';

void main() {
  test('reads an equipment id from the Play referrer', () {
    final link = shareLinkFromInstallReferrer('id=eq-1');

    expect(link?.equipmentId, 'eq-1');
    expect(link?.canonical.toString(), 'https://prokat-bfbec.web.app/e/eq-1');
  });

  test('reads a full share URL from the Play referrer', () {
    final link = shareLinkFromInstallReferrer(
      'https://prokat-bfbec.web.app/e/eq-2',
    );

    expect(link?.equipmentId, 'eq-2');
  });

  test('ignores an organic Play referrer', () {
    expect(
      shareLinkFromInstallReferrer('utm_source=google-play&utm_medium=organic'),
      isNull,
    );
    expect(shareLinkFromInstallReferrer(''), isNull);
    expect(shareLinkFromInstallReferrer(null), isNull);
  });

  test('does not open a card again after the referrer was checked', () async {
    var reads = 0;
    final link = await captureShareInstallReferrer(
      wasChecked: () async => true,
      markChecked: () async {},
      readReferrer: () async {
        reads += 1;
        return 'id=eq-1';
      },
    );

    expect(link, isNull);
    expect(reads, 0);
  });

  test('keeps the check pending when Play is unavailable', () async {
    var marked = false;
    final link = await captureShareInstallReferrer(
      wasChecked: () async => false,
      markChecked: () async => marked = true,
      readReferrer: () async =>
          throw PlatformException(code: 'SERVICE_UNAVAILABLE'),
    );

    expect(link, isNull);
    expect(marked, isFalse);
  });

  test(
    'marks a finished check even when the referrer is not a share link',
    () async {
      var marked = false;
      final link = await captureShareInstallReferrer(
        wasChecked: () async => false,
        markChecked: () async => marked = true,
        readReferrer: () async => 'utm_source=google-play&utm_medium=organic',
      );

      expect(link, isNull);
      expect(marked, isTrue);
    },
  );

  test('stores the share link from a successful referrer read', () async {
    var marked = false;
    final link = await captureShareInstallReferrer(
      wasChecked: () async => false,
      markChecked: () async => marked = true,
      readReferrer: () async => 'id=eq-9',
    );

    expect(link?.equipmentId, 'eq-9');
    expect(marked, isTrue);
  });
}
