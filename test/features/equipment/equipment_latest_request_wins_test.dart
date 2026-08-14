import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/providers/client_equipment_provider.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart'
    as client_dependencies;
import 'package:prokat/features/equipment/providers/guest_equipment_provider.dart'
    as guest_dependencies;
import 'package:prokat/features/equipment/state/equipment_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  for (final newerCompletesFirst in [true, false]) {
    final completionOrder = newerCompletesFirst
        ? 'newer response completes first'
        : 'older response completes first';

    test('client equipment keeps the latest filters when $completionOrder', () {
      return _verifyClientLatestRequestWins(
        newerCompletesFirst: newerCompletesFirst,
      );
    });

    test('guest equipment keeps the latest filters when $completionOrder', () {
      return _verifyGuestLatestRequestWins(
        newerCompletesFirst: newerCompletesFirst,
      );
    });
  }

  test('client equipment ignores an old page after filters change', () {
    return _verifyClientOldPageIsIgnored();
  });

  test('guest equipment ignores an old page after filters change', () {
    return _verifyGuestOldPageIsIgnored();
  });
}

Future<void> _verifyClientLatestRequestWins({
  required bool newerCompletesFirst,
}) async {
  final service = _ControlledEquipmentService();
  final container = ProviderContainer(
    overrides: [
      client_dependencies.equipmentServiceProvider.overrideWithValue(service),
    ],
  );
  addTearDown(() {
    service.completeAllPending();
    container.dispose();
  });

  final initial = container.read(clientEquipmentProvider.future);
  service.complete(0, 'initial');
  await initial;

  final notifier = container.read(clientEquipmentProvider.notifier);
  final olderSearch = notifier.search(query: 'older');
  await _waitForRequestCount(service, 2);
  final newerSearch = notifier.search(query: 'newer');
  await _waitForRequestCount(service, 3);

  await _completeInSelectedOrder(
    service: service,
    olderSearch: olderSearch,
    newerSearch: newerSearch,
    newerCompletesFirst: newerCompletesFirst,
  );

  final result = container.read(clientEquipmentProvider).requireValue;
  expect(service.queries, [null, 'older', 'newer']);
  expect(notifier.query, 'newer');
  expect(result.items.map((item) => item.id), ['newer']);
  expect(result.isRefreshing, isFalse);
}

Future<void> _verifyGuestLatestRequestWins({
  required bool newerCompletesFirst,
}) async {
  final service = _ControlledEquipmentService();
  final container = ProviderContainer(
    overrides: [
      guest_dependencies.equipmentServiceProvider.overrideWithValue(service),
    ],
  );
  addTearDown(() {
    service.completeAllPending();
    container.dispose();
  });

  final initial = container.read(
    guest_dependencies.guestEquipmentProvider.future,
  );
  service.complete(0, 'initial');
  await initial;

  final notifier = container.read(
    guest_dependencies.guestEquipmentProvider.notifier,
  );
  final olderSearch = notifier.setFilters(query: 'older');
  await _waitForRequestCount(service, 2);
  final newerSearch = notifier.setFilters(query: 'newer');
  await _waitForRequestCount(service, 3);

  await _completeInSelectedOrder(
    service: service,
    olderSearch: olderSearch,
    newerSearch: newerSearch,
    newerCompletesFirst: newerCompletesFirst,
  );

  final result = container
      .read(guest_dependencies.guestEquipmentProvider)
      .requireValue;
  expect(service.queries, [null, 'older', 'newer']);
  expect(notifier.query, 'newer');
  expect(result.items.map((item) => item.id), ['newer']);
  expect(result.isRefreshing, isFalse);
}

Future<void> _verifyClientOldPageIsIgnored() async {
  final service = _ControlledEquipmentService();
  final container = ProviderContainer(
    overrides: [
      client_dependencies.equipmentServiceProvider.overrideWithValue(service),
    ],
  );
  addTearDown(() {
    service.completeAllPending();
    container.dispose();
  });

  final initial = container.read(clientEquipmentProvider.future);
  service.complete(0, 'initial', itemCount: 10);
  await initial;

  final notifier = container.read(clientEquipmentProvider.notifier);
  final oldPage = notifier.loadMore();
  await _waitForRequestCount(service, 2);
  final newSearch = notifier.search(query: 'newer');
  await _waitForRequestCount(service, 3);

  service.complete(2, 'newer');
  await newSearch;
  service.complete(1, 'old-page');
  await oldPage;

  final result = container.read(clientEquipmentProvider).requireValue;
  expect(service.pages, [1, 2, 1]);
  expect(result.items.map((item) => item.id), ['newer']);
  expect(result.isLoadingMore, isFalse);
}

Future<void> _verifyGuestOldPageIsIgnored() async {
  final service = _ControlledEquipmentService();
  final container = ProviderContainer(
    overrides: [
      guest_dependencies.equipmentServiceProvider.overrideWithValue(service),
    ],
  );
  addTearDown(() {
    service.completeAllPending();
    container.dispose();
  });

  final initial = container.read(
    guest_dependencies.guestEquipmentProvider.future,
  );
  service.complete(0, 'initial', itemCount: 10);
  await initial;

  final notifier = container.read(
    guest_dependencies.guestEquipmentProvider.notifier,
  );
  final oldPage = notifier.loadMore();
  await _waitForRequestCount(service, 2);
  final newSearch = notifier.setFilters(query: 'newer');
  await _waitForRequestCount(service, 3);

  service.complete(2, 'newer');
  await newSearch;
  service.complete(1, 'old-page');
  await oldPage;

  final result = container
      .read(guest_dependencies.guestEquipmentProvider)
      .requireValue;
  expect(service.pages, [1, 2, 1]);
  expect(result.items.map((item) => item.id), ['newer']);
  expect(result.isLoadingMore, isFalse);
}

Future<void> _completeInSelectedOrder({
  required _ControlledEquipmentService service,
  required Future<void> olderSearch,
  required Future<void> newerSearch,
  required bool newerCompletesFirst,
}) async {
  if (newerCompletesFirst) {
    service.complete(2, 'newer');
    await newerSearch;
    service.complete(1, 'older');
    await olderSearch;
  } else {
    service.complete(1, 'older');
    await olderSearch;
    service.complete(2, 'newer');
    await newerSearch;
  }
}

Future<void> _waitForRequestCount(
  _ControlledEquipmentService service,
  int count,
) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    if (service.requests.length >= count) return;
    await Future<void>.delayed(Duration.zero);
  }
  expect(service.requests, hasLength(count));
}

class _ControlledEquipmentService extends EquipmentService {
  final List<_PendingEquipmentRequest> requests = [];

  _ControlledEquipmentService() : super(_TestApiClient(Dio()));

  List<String?> get queries =>
      requests.map((request) => request.query).toList();
  List<int> get pages => requests.map((request) => request.page).toList();

  @override
  Future<ApiResponse<List<Equipment>>> getClientEquipment({
    String? categoryId,
    String? query,
    String? city,
    int page = 1,
    int itemsPerPage = 10,
  }) {
    return _enqueue(query, page);
  }

  @override
  Future<ApiResponse<List<Equipment>>> getGuestEquipment({
    required String locale,
    String? categoryId,
    String? query,
    String? city,
    int page = 1,
    int itemsPerPage = 10,
  }) {
    return _enqueue(query, page);
  }

  Future<ApiResponse<List<Equipment>>> _enqueue(String? query, int page) {
    final request = _PendingEquipmentRequest(query, page);
    requests.add(request);
    return request.completer.future;
  }

  void complete(int index, String equipmentId, {int itemCount = 1}) {
    final request = requests[index];
    if (request.completer.isCompleted) return;
    request.completer.complete(
      ApiResponse.success(
        List.generate(
          itemCount,
          (itemIndex) => _equipment(
            itemCount == 1 ? equipmentId : '$equipmentId-$itemIndex',
          ),
        ),
      ),
    );
  }

  void completeAllPending() {
    for (final request in requests) {
      if (!request.completer.isCompleted) {
        request.completer.complete(ApiResponse.success(const []));
      }
    }
  }
}

class _PendingEquipmentRequest {
  final String? query;
  final int page;
  final Completer<ApiResponse<List<Equipment>>> completer = Completer();

  _PendingEquipmentRequest(this.query, this.page);
}

class _TestApiClient implements ApiClient {
  _TestApiClient(this.dio);

  @override
  Dio dio;
}

Equipment _equipment(String id) {
  return Equipment(
    id: id,
    name: id,
    model: 'model',
    capacity: '1',
    capacityUnit: 'unit',
    status: EquipmentStatus.available,
    isVisible: true,
    prices: const [],
  );
}
