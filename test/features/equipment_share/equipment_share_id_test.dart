import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/equipment_share/equipment_share_id.dart';

void main() {
  group('share id', () {
    test('generates 22 url-safe chars', () {
      for (var i = 0; i < 100; i++) {
        final id = generateShareId();
        expect(id, hasLength(22));
        expect(id, matches(RegExp(r'^[A-Za-z0-9_-]{22}$')));
        expect(id, isNot(contains('=')));
        expect(isValidShareId(id), isTrue);
      }
    });

    test('ids are unique across 1000 calls', () {
      final ids = {for (var i = 0; i < 1000; i++) generateShareId()};
      expect(ids, hasLength(1000));
    });

    test('rejects null and empty', () {
      expect(isValidShareId(null), isFalse);
      expect(isValidShareId(''), isFalse);
    });

    test('rejects 21 chars', () {
      expect(isValidShareId('a' * 21), isFalse);
    });

    test('rejects 23 chars', () {
      expect(isValidShareId('a' * 23), isFalse);
    });

    test('rejects padding', () {
      expect(isValidShareId('AbCdEfGhIjKlMnOpQrSt=='), isFalse);
      expect(isValidShareId('AbCdEfGhIjKlMnOpQrStU='), isFalse);
    });

    test('rejects non url-safe chars', () {
      expect(isValidShareId('AbCdEfGhIjKlMnOpQrSt+/'), isFalse);
      expect(isValidShareId('AbCdEfGhIjKlMnOpQrSt!a'), isFalse);
    });
  });

  group('share method', () {
    test('maps android whatsapp component', () {
      expect(
        shareMethodFromRaw('com.whatsapp/com.whatsapp.contact.ContactPicker'),
        'whatsapp',
      );
    });

    test('maps telegram ios bundle', () {
      expect(shareMethodFromRaw('ph.telegra.Telegraph.Share'), 'telegram');
    });

    test('maps instagram', () {
      expect(
        shareMethodFromRaw('com.burbn.instagram.shareextension'),
        'instagram',
      );
    });

    test('maps ios copy activity', () {
      expect(
        shareMethodFromRaw('com.apple.UIKit.activity.CopyToPasteboard'),
        'copy',
      );
    });

    test('empty raw is unknown', () {
      expect(shareMethodFromRaw(''), 'unknown');
    });

    test('unknown app is other', () {
      expect(shareMethodFromRaw('com.example.mail/.ComposeActivity'), 'other');
    });
  });
}
