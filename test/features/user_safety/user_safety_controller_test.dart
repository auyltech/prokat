import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/auth/models/user_model.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/providers/client_equipment_provider.dart';
import 'package:prokat/features/equipment/state/client_equipment_notifier.dart';
import 'package:prokat/features/requests/models/request_model.dart';
import 'package:prokat/features/requests/models/request_status.dart';
import 'package:prokat/features/requests/providers/owner_active_requests_provider.dart';
import 'package:prokat/features/requests/state/owner_active_requests_notifier.dart';
import 'package:prokat/features/user_safety/models/report_reason.dart';
import 'package:prokat/features/user_safety/models/report_target.dart';
import 'package:prokat/features/user_safety/state/user_safety_providers.dart';

import 'user_safety_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  ProviderContainer makeContainer(FakeUserSafetyApi api) {
    final container = ProviderContainer(
      overrides: [
        ...userSafetyOverrides(api),
        clientEquipmentProvider.overrideWith(_FakeClientEquipmentNotifier.new),
        ownerActiveRequestsProvider.overrideWith(
          _FakeOwnerActiveRequestsNotifier.new,
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('block removes the owner from loaded catalog lists only', () async {
    final api = FakeUserSafetyApi();
    final container = makeContainer(api);
    await container.read(
      clientEquipmentProvider(CatalogGroup.machinery).future,
    );

    final response = await container
        .read(userSafetyControllerProvider)
        .blockUser('owner-b');

    expect(response.success, isTrue);
    expect(api.blockCalls, ['owner-b']);
    final list = container
        .read(clientEquipmentProvider(CatalogGroup.machinery))
        .requireValue;
    expect(list.items.map((item) => item.id), ['eq-a']);
    expect(list.count, 1);
    expect(
      container.exists(clientEquipmentProvider(CatalogGroup.equipment)),
      isFalse,
    );
  });

  test('block removes the client from loaded owner request feeds', () async {
    final api = FakeUserSafetyApi();
    final container = makeContainer(api);
    await container.read(
      ownerActiveRequestsProvider(CatalogGroup.machinery).future,
    );

    await container.read(userSafetyControllerProvider).blockUser('client-b');

    final feed = container
        .read(ownerActiveRequestsProvider(CatalogGroup.machinery))
        .requireValue;
    expect(feed.items.map((item) => item.id), ['req-a']);
  });

  test('failed block leaves every list untouched', () async {
    final api = FakeUserSafetyApi()..failBlock = true;
    final container = makeContainer(api);
    await container.read(
      clientEquipmentProvider(CatalogGroup.machinery).future,
    );

    final response = await container
        .read(userSafetyControllerProvider)
        .blockUser('owner-b');

    expect(response.success, isFalse);
    expect(
      container
          .read(clientEquipmentProvider(CatalogGroup.machinery))
          .requireValue
          .items,
      hasLength(2),
    );
  });

  test('unblock drops the user from the blocked list locally', () async {
    final api = FakeUserSafetyApi(
      blocked: [blockedUser('user-b'), blockedUser('user-c')],
    );
    final container = makeContainer(api);
    await container.read(blockedUsersProvider.future);

    await container.read(userSafetyControllerProvider).unblockUser('user-b');

    expect(api.unblockCalls, ['user-b']);
    expect(
      container
          .read(blockedUsersProvider)
          .requireValue
          .items
          .map((item) => item.userId),
      ['user-c'],
    );
  });

  test('report never blocks', () async {
    final api = FakeUserSafetyApi();
    final container = makeContainer(api);

    final response = await container
        .read(userSafetyControllerProvider)
        .report(
          const ReportTarget(ReportTargetType.equipment, 'eq-b'),
          ReportReason.spam,
          'spam text',
        );

    expect(response.success, isTrue);
    expect(api.reportCalls.single.$1.targetId, 'eq-b');
    expect(api.reportCalls.single.$2, ReportReason.spam);
    expect(api.blockCalls, isEmpty);
  });
}

Equipment _equipment(String id, String ownerId) {
  return Equipment(
    id: id,
    name: 'Excavator',
    model: 'X',
    status: EquipmentStatus.available,
    isVisible: true,
    prices: const [],
    owner: UserModel(id: ownerId),
  );
}

class _FakeClientEquipmentNotifier extends ClientEquipmentNotifier {
  @override
  Future<QueryState<Equipment>> build(CatalogGroup arg) async {
    return QueryState(
      items: [_equipment('eq-a', 'owner-a'), _equipment('eq-b', 'owner-b')],
      itemsPerPage: 20,
      count: 2,
    );
  }

  @override
  Future<void> refresh() async {}
}

class _FakeOwnerActiveRequestsNotifier extends OwnerActiveRequestsNotifier {
  @override
  Future<QueryState<RequestModel>> build(CatalogGroup arg) async {
    return QueryState(
      items: [_request('req-a', 'client-a'), _request('req-b', 'client-b')],
      itemsPerPage: 20,
      count: 2,
    );
  }

  @override
  Future<void> refresh() async {}
}

RequestModel _request(String id, String clientId) {
  return RequestModel(
    id: id,
    status: RequestStatus.created,
    capacity: '',
    offeredPrice: 0,
    client: UserModel(id: clientId),
  );
}
