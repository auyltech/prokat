import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/equipment_share/equipment_share_link.dart';

void main() {
  group('registry app-open links', () {
    const token = 'AbCdEfGhIjKlMnOpQr_-12';
    test(
      'exact HTTPS app-open URL contains attribution, not an equipment ID',
      () {
        final link = EquipmentShareLink.tryParse(
          Uri.parse('https://open.prokat.auyltech.kz/e/$token'),
        )!;
        expect(link.shareId, token);
        expect(link.equipmentId, isNull);
        expect(link.isRegistryLink, isTrue);
      },
    );
    test('queries cannot override token or target', () {
      final link = EquipmentShareLink.tryParse(
        Uri.parse(
          'https://open.prokat.auyltech.kz/e/$token?s=other&equipmentId=evil&redirect=https://evil.test',
        ),
      )!;
      expect(link.shareId, token);
      expect(link.equipmentId, isNull);
      expect(link.uri.toString(), 'https://open.prokat.auyltech.kz/e/$token');
    });
    for (final url in [
      'http://open.prokat.auyltech.kz/e/$token',
      'https://open.prokat.auyltech.kz.evil.test/e/$token',
      'https://evil.test/e/$token',
      'https://prokat.auyltech.kz/e/$token',
      'https://open.prokat.auyltech.kz/e/short',
      'https://open.prokat.auyltech.kz/e/${token}x',
      'https://open.prokat.auyltech.kz/e/$token/extra',
      'https://open.prokat.auyltech.kz/e/$token/',
      'https://open.prokat.auyltech.kz//e/$token',
      'https://open.prokat.auyltech.kz/e/$token%2Fextra',
      'https://open.prokat.auyltech.kz/e/%252F$token',
      'https://open.prokat.auyltech.kz:444/e/$token',
      'https://user@open.prokat.auyltech.kz/e/$token',
      'https://open.prokat.auyltech.kz/e/$token#other',
    ]) {
      test('rejects $url', () {
        expect(EquipmentShareLink.tryParse(Uri.parse(url)), isNull);
      });
    }
    test('legacy firebaseapp alias remains accepted', () {
      final link = EquipmentShareLink.tryParse(
        Uri.parse('https://prokat-bfbec.firebaseapp.com/e/eq-1?s=$token'),
      )!;
      expect(link.equipmentId, 'eq-1');
      expect(link.shareId, token);
    });
    test('legacy encoded path separators never become routing data', () {
      for (final id in ['eq%2Fother', '%252Fprivate', 'eq%20private']) {
        expect(
          EquipmentShareLink.tryParse(
            Uri.parse('https://prokat-bfbec.web.app/e/$id?s=$token'),
          ),
          isNull,
        );
      }
    });
  });
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

  group('share id', () {
    const shareId = 'AbCdEfGhIjKlMnOpQr_-12';

    test('keeps share id from query', () {
      final link = EquipmentShareLink.tryParse(
        Uri.parse('https://prokat-bfbec.web.app/e/eq-1?s=$shareId'),
      );

      expect(link?.equipmentId, 'eq-1');
      expect(link?.shareId, shareId);
    });

    test('drops invalid share id', () {
      for (final bad in [
        'bad!',
        'a',
        '${shareId}x',
        'AbCdEfGhIjKlMnOpQrSt==',
      ]) {
        final link = EquipmentShareLink.tryParse(
          Uri.parse(
            'https://prokat-bfbec.web.app/e/eq-1?s=${Uri.encodeQueryComponent(bad)}',
          ),
        );
        expect(link?.equipmentId, 'eq-1');
        expect(link?.shareId, isNull);
      }
    });

    test('canonical has no query', () {
      final link = EquipmentShareLink.tryParse(
        Uri.parse('https://prokat-bfbec.web.app/e/eq-1?s=$shareId&x=1'),
      );

      expect(link?.canonical.toString(), 'https://prokat-bfbec.web.app/e/eq-1');
      expect(link?.canonical.hasQuery, isFalse);
    });

    test('uri contains share id', () {
      final link = EquipmentShareLink.tryParse(
        Uri.parse('https://prokat-bfbec.web.app/e/eq-1?s=$shareId'),
      );

      expect(
        link?.uri.toString(),
        'https://prokat-bfbec.web.app/e/eq-1?s=$shareId',
      );
    });

    test('uri round-trips share id', () {
      final link = EquipmentShareLink.tryParse(
        Uri.parse('https://prokat-bfbec.web.app/e/eq-1?s=$shareId'),
      )!;
      final again = EquipmentShareLink.tryParse(link.uri)!;

      expect(again.equipmentId, 'eq-1');
      expect(again.shareId, shareId);
      expect(again.canonical, link.canonical);
    });

    test('old link without query still parses', () {
      final link = EquipmentShareLink.tryParse(
        Uri.parse('https://prokat-bfbec.web.app/e/eq-1'),
      );

      expect(link?.equipmentId, 'eq-1');
      expect(link?.shareId, isNull);
      expect(link?.uri, link?.canonical);
    });

    test('malformed query does not throw', () {
      final uri = Uri.parse('https://prokat-bfbec.web.app/e/eq-1?s=%E0%A4');
      late final EquipmentShareLink? link;

      expect(() => link = EquipmentShareLink.tryParse(uri), returnsNormally);
      expect(link?.equipmentId, 'eq-1');
      expect(link?.shareId, isNull);
    });
  });
}
