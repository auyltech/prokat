import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/features/locations/state/location_notifier.dart';
import 'package:prokat/features/locations/state/location_service.dart';

void main() {
  LocationModel pin({String? id}) {
    return LocationModel(
      id: id,
      service: 'ADDRESS',
      street: 'Сатыбалдиева',
      city: 'Атырау',
      country: 'Казахстан',
      houseNumber: '10',
      latitude: 47.1,
      longitude: 51.9,
    );
  }

  test(
    'POST success then refresh GET error still keeps the created id',
    () async {
      final api = _FakeLocationService(
        created: pin(id: 'loc-created'),
        refreshFails: true,
      );
      final provider = Provider<LocationNotifier>(
        (ref) => LocationNotifier(api, ref),
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(provider);

      final ok = await notifier.createLocation(pin(), 'guest_share');

      expect(ok, isTrue);
      expect(api.createCalls, 1);
      expect(api.getCalls, 1);
      expect(notifier.state.selectedAddress?.id, 'loc-created');
      expect(api.createCalls, 1);
    },
  );

  test('ensure waits for in-flight get and coalesces HTTP', () async {
    final api = _FakeLocationService(created: pin(id: 'x'), delayMs: 40);
    final provider = Provider<LocationNotifier>(
      (ref) => LocationNotifier(api, ref),
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(provider);

    final first = notifier.getClientLocations();
    final second = notifier.ensureClientLocations();
    await Future.wait([first, second]);

    expect(api.getCalls, 1);
    expect(await notifier.ensureClientLocations(), isTrue);
    expect(api.getCalls, 1);
  });

  test('ensure treats fetch error as not empty', () async {
    final api = _FakeLocationService(created: pin(id: 'x'), refreshFails: true);
    final provider = Provider<LocationNotifier>(
      (ref) => LocationNotifier(api, ref),
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(provider);

    await notifier.getClientLocations();
    expect(await notifier.ensureClientLocations(), isFalse);
  });
}

class _TestApiClient implements ApiClient {
  _TestApiClient(this.dio);

  @override
  Dio dio;
}

class _FakeLocationService extends LocationService {
  _FakeLocationService({
    required this.created,
    this.refreshFails = false,
    this.delayMs = 0,
  }) : super(_TestApiClient(Dio()));

  final LocationModel created;
  final bool refreshFails;
  final int delayMs;
  int createCalls = 0;
  int getCalls = 0;

  @override
  Future<ApiResponse<List<LocationModel>>> getClientLocations({
    String? mode,
  }) async {
    getCalls += 1;
    if (delayMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: delayMs));
    }
    if (refreshFails) {
      return ApiResponse.failure(message: 'network');
    }
    return ApiResponse.success(const <LocationModel>[]);
  }

  @override
  Future<ApiResponse<LocationModel?>> createLocation(
    LocationModel location,
  ) async {
    createCalls += 1;
    return ApiResponse.success(created);
  }
}
