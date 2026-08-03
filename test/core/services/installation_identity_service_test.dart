import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/services/installation_identity_service.dart';

class _MemoryInstallationIdStore implements InstallationIdStore {
  String? value;
  int writes = 0;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async {
    this.value = value;
    writes++;
  }
}

void main() {
  test('creates and reuses one UUIDv4 installation ID', () async {
    final store = _MemoryInstallationIdStore();
    final firstService = InstallationIdentityService(
      store: store,
      isSupportedPlatform: () => true,
    );

    final first = await firstService.getOrCreate();
    final second = await firstService.getOrCreate();
    final restored = await InstallationIdentityService(
      store: store,
      isSupportedPlatform: () => true,
    ).getOrCreate();

    expect(first, isNotNull);
    expect(
      first,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(second, first);
    expect(restored, first);
    expect(store.writes, 1);
  });

  test('does not create an installation ID on unsupported platforms', () async {
    final store = _MemoryInstallationIdStore();
    final service = InstallationIdentityService(
      store: store,
      isSupportedPlatform: () => false,
    );

    expect(await service.getOrCreate(), isNull);
    expect(store.writes, 0);
  });
}
