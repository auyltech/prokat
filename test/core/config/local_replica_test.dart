import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/config/env.dart';
import 'package:prokat/features/equipment_share/equipment_share_link.dart';

void main() {
  const id = 'AbCdEfGhIjKlMnOpQrSt_-';
  final local = Env.isLocal;
  test('local registry links preserve their token and origin', () {
    expect(Env.publicEquipmentShareUrl(id), 'http://localhost:3000/e/$id');
    for (final url in [
      'http://localhost:3000/e/$id',
      'prokat-local://app/e/$id',
    ]) {
      final link = EquipmentShareLink.tryParse(Uri.parse(url))!;
      expect(link.isRegistryLink, isTrue);
      expect(link.equipmentId, isNull);
      expect(link.shareId, id);
      expect(link.uri.toString(), url);
    }
  }, skip: !local);
  test(
    'local registry rejects foreign origins, malformed tokens and credentials',
    () {
      for (final url in [
        'http://localhost:3001/e/$id',
        'http://foreign.invalid:3000/e/$id',
        'http://user@localhost:3000/e/$id',
        'prokat-local://foreign/e/$id',
        'prokat-local://app/e/invalid',
        'prokat-local://app/e/$id?s=$id',
      ]) {
        expect(EquipmentShareLink.tryParse(Uri.parse(url)), isNull);
      }
    },
    skip: !local,
  );
  test(
    'local mode cannot enable analytics, crash reporting or attribution',
    () {
      expect(Env.analyticsCollectionEnabled, isFalse);
      expect(Env.crashReportingEnabled, isFalse);
      expect(Env.shareAnalyticsEnabled, isFalse);
      expect(Env.pushNotificationsEnabled, isTrue);
    },
    skip: !local,
  );
}
