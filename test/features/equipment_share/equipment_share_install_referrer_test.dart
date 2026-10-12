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

  group('share id matrix', () {
    const shareId = 'AbCdEfGhIjKlMnOpQr_-12';

    test('id only has no share id', () {
      final link = shareLinkFromInstallReferrer('id=eq-1');
      expect(link?.equipmentId, 'eq-1');
      expect(link?.shareId, isNull);
    });

    test('id with valid s keeps share id', () {
      final link = shareLinkFromInstallReferrer('id=eq-1&s=$shareId');
      expect(link?.equipmentId, 'eq-1');
      expect(link?.shareId, shareId);
      expect(
        link?.uri.toString(),
        'https://prokat-bfbec.web.app/e/eq-1?s=$shareId',
      );
      expect(link?.canonical.toString(), 'https://prokat-bfbec.web.app/e/eq-1');
    });

    test('invalid s is dropped', () {
      final link = shareLinkFromInstallReferrer('id=eq-1&s=bad!');
      expect(link?.equipmentId, 'eq-1');
      expect(link?.shareId, isNull);
    });

    test('full new referrer with utm keeps id and share id', () {
      final link = shareLinkFromInstallReferrer(
        'id=eq-1&s=$shareId&utm_source=prokat_share&utm_medium=referral'
        '&utm_campaign=equipment_share',
      );
      expect(link?.equipmentId, 'eq-1');
      expect(link?.shareId, shareId);
    });

    test('unrelated params before id', () {
      expect(
        shareLinkFromInstallReferrer('foo=bar&id=eq-2')?.equipmentId,
        'eq-2',
      );
    });

    test('organic, empty and blank id are null', () {
      expect(
        shareLinkFromInstallReferrer(
          'utm_source=google-play&utm_medium=organic',
        ),
        isNull,
      );
      expect(shareLinkFromInstallReferrer(''), isNull);
      expect(shareLinkFromInstallReferrer(null), isNull);
      expect(shareLinkFromInstallReferrer('id='), isNull);
    });

    test('encoded slash id is rejected', () {
      expect(shareLinkFromInstallReferrer('id=a%2Fb'), isNull);
    });

    test('malformed encoding is null without throwing', () {
      expect(() => shareLinkFromInstallReferrer('%E0%A4%A'), returnsNormally);
      expect(shareLinkFromInstallReferrer('%E0%A4%A'), isNull);
    });

    test('full URL keeps share id', () {
      final link = shareLinkFromInstallReferrer(
        'https://prokat-bfbec.web.app/e/eq-3?s=$shareId',
      );
      expect(link?.equipmentId, 'eq-3');
      expect(link?.shareId, shareId);
    });
  });

  test(
    'valid referrer is not consumed before caller durably stores it',
    () async {
      var marked = false;
      final link = await captureShareInstallReferrer(
        wasChecked: () async => false,
        markChecked: () async => marked = true,
        readReferrer: () async => 'id=eq-9',
      );

      expect(link?.equipmentId, 'eq-9');
      expect(marked, isFalse);
    },
  );
}
