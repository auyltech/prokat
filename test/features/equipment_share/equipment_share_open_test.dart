import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/equipment_share/equipment_share_link.dart';
import 'package:prokat/features/equipment_share/equipment_share_open.dart';

const _shareId = 'AbCdEfGhIjKlMnOpQr_-12';

void main() {
  test('via mappings', () {
    expect(ShareOpenVia.appLink.wire, 'app_link');
    expect(ShareOpenVia.installReferrer.wire, 'install_referrer');
    expect(ShareOpenVia.appLink.api, 'APP_LINK');
    expect(ShareOpenVia.installReferrer.api, 'INSTALL_REFERRER');
  });

  test('json round-trip', () {
    final link = EquipmentShareLink.tryParse(
      Uri.parse('https://prokat-bfbec.web.app/e/eq-1?s=$_shareId'),
    )!;
    final open = EquipmentShareOpen(
      link: link,
      via: ShareOpenVia.installReferrer,
      firstShareBootstrapRun: true,
    );

    final raw = jsonEncode(open.toJson());
    expect(jsonDecode(raw), {
      'v': 1,
      'uri': 'https://prokat-bfbec.web.app/e/eq-1?s=$_shareId',
      'via': 'install_referrer',
      'firstShareBootstrapRun': true,
    });

    final parsed = EquipmentShareOpen.tryParse(raw)!;
    expect(parsed.link.equipmentId, 'eq-1');
    expect(parsed.link.shareId, _shareId);
    expect(parsed.via, ShareOpenVia.installReferrer);
    expect(parsed.firstShareBootstrapRun, isTrue);
  });

  test('json round-trip without share id', () {
    final link = EquipmentShareLink.tryParse(
      Uri.parse('https://prokat-bfbec.web.app/e/eq-2'),
    )!;
    final raw = jsonEncode(
      EquipmentShareOpen(
        link: link,
        via: ShareOpenVia.appLink,
        firstShareBootstrapRun: false,
      ).toJson(),
    );

    final parsed = EquipmentShareOpen.tryParse(raw)!;
    expect(parsed.link.equipmentId, 'eq-2');
    expect(parsed.link.shareId, isNull);
    expect(parsed.via, ShareOpenVia.appLink);
    expect(parsed.firstShareBootstrapRun, isFalse);
  });

  test('legacy plain uri reads as app_link', () {
    final parsed = EquipmentShareOpen.tryParse(
      'https://prokat-bfbec.web.app/e/eq-1',
    )!;

    expect(parsed.link.equipmentId, 'eq-1');
    expect(parsed.link.shareId, isNull);
    expect(parsed.via, ShareOpenVia.appLink);
    expect(parsed.firstShareBootstrapRun, isFalse);
  });

  test('corrupt json returns null', () {
    for (final raw in [
      '',
      '{',
      '{"v":1}',
      '[]',
      '{"v":2,"uri":"https://prokat-bfbec.web.app/e/eq-1","via":"app_link","firstShareBootstrapRun":false}',
      '{"v":1,"uri":"https://prokat-bfbec.web.app/e/eq-1","via":"sms","firstShareBootstrapRun":false}',
      '{"v":1,"uri":"https://prokat-bfbec.web.app/e/eq-1","via":"app_link","firstShareBootstrapRun":"yes"}',
      '{"v":1,"uri":"https://example.com/e/eq-1","via":"app_link","firstShareBootstrapRun":false}',
      'not a link',
    ]) {
      expect(
        () => EquipmentShareOpen.tryParse(raw),
        returnsNormally,
        reason: raw,
      );
      expect(EquipmentShareOpen.tryParse(raw), isNull, reason: raw);
    }
  });

  test('invalid embedded share id is dropped, link kept', () {
    final parsed = EquipmentShareOpen.tryParse(
      '{"v":1,"uri":"https://prokat-bfbec.web.app/e/eq-1?s=bad!","via":"app_link","firstShareBootstrapRun":true}',
    )!;

    expect(parsed.link.equipmentId, 'eq-1');
    expect(parsed.link.shareId, isNull);
    expect(parsed.firstShareBootstrapRun, isTrue);
  });
}
