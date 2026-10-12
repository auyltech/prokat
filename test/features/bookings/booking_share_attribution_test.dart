import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/features/bookings/providers/booking_mutation_provider.dart';
import 'package:prokat/features/bookings/state/booking_service.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/equipment_share/equipment_share_open.dart';
import 'package:prokat/features/equipment_share/equipment_share_link.dart';
import 'package:prokat/features/equipment_share/equipment_share_storage.dart';
import 'package:prokat/features/locations/models/location_model.dart';

class _TestApiClient implements ApiClient {
  _TestApiClient(this.dio);

  @override
  Dio dio;
}

class _ShareStorage extends EquipmentShareStorage {
  _ShareStorage(this.context) : super();

  final ({EquipmentShareOpen open, DateTime receivedAt})? context;
  bool consumed = false;

  @override
  Future<({EquipmentShareOpen open, DateTime receivedAt})?>
  readAcceptedOpenContext({required String equipmentId}) async {
    if (context?.open.link.equipmentId != equipmentId) return null;
    return context;
  }

  @override
  Future<bool> consumeAcceptedBookingAttribution({
    required String equipmentId,
    required String shareId,
  }) async {
    consumed = true;
    return true;
  }
}

Equipment _equipment({String? companyId}) => Equipment(
  id: 'equipment-1',
  companyId: companyId,
  name: 'Truck',
  model: 'T',
  status: EquipmentStatus.available,
  isVisible: true,
  prices: const [],
);

LocationModel _location() => LocationModel(
  id: 'location-1',
  service: 'ADDRESS',
  street: 'Street',
  city: 'Almaty',
  country: 'KZ',
  longitude: 76.9,
  latitude: 43.2,
);

ProviderContainer _container({
  required _ShareStorage storage,
  required Map<String, dynamic> response,
  int statusCode = 201,
  List<Object?>? requestBodies,
}) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        requestBodies?.add(options.data);
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: statusCode,
            data: response,
          ),
        );
      },
    ),
  );
  return ProviderContainer(
    overrides: [
      bookingServiceProvider.overrideWithValue(
        BookingService(_TestApiClient(dio)),
      ),
      equipmentShareStorageProvider.overrideWithValue(storage),
    ],
  );
}

void _selectRequired(ProviderContainer container, {String? companyId}) {
  final notifier = container.read(bookingMutationProvider.notifier);
  notifier.selectEquipment(_equipment(companyId: companyId));
  notifier.selectPriceEntry(
    PriceEntry(id: 'price-1', price: 1000, priceRate: priceRateOptions[2]),
  );
  notifier.selectLocation(_location());
  notifier.setDateAndTime(
    date: DateTime.now().add(const Duration(days: 1)),
    time: DateTime.now().add(const Duration(days: 1)),
  );
}

void main() {
  const shareId = 'AbCdEfGhIjKlMnOpQrSt_-';
  final accepted = EquipmentShareOpen(
    link: EquipmentShareLink.fromShareId(shareId)
        .withEquipmentId('equipment-1'),
    via: ShareOpenVia.appLink,
    firstShareBootstrapRun: false,
  );

  test(
    'matching accepted context is sent and consumed after success',
    () async {
      final storage = _ShareStorage((
        open: accepted,
        receivedAt: DateTime.now().toUtc(),
      ));
      final requests = <Object?>[];
      final container = _container(
        storage: storage,
        response: {'success': true, 'data': null},
        requestBodies: requests,
      );
      addTearDown(container.dispose);
      _selectRequired(container);

      final result = await container
          .read(bookingMutationProvider.notifier)
          .createBooking();

      expect(result.success, isTrue);
      expect((requests.single as Map)['shareId'], shareId);
      expect(storage.consumed, isTrue);
    },
  );

  test('context for another equipment or an old context is not sent', () async {
    final old = _ShareStorage((
      open: accepted,
      receivedAt: DateTime.now().toUtc().subtract(const Duration(days: 31)),
    ));
    final requests = <Object?>[];
    final container = _container(
      storage: old,
      response: {'success': true, 'data': null},
      requestBodies: requests,
    );
    addTearDown(container.dispose);
    _selectRequired(container);

    final result = await container
        .read(bookingMutationProvider.notifier)
        .createBooking();

    expect(result.success, isTrue);
    expect((requests.single as Map).containsKey('shareId'), isFalse);
    expect(old.consumed, isFalse);
  });

  test(
    'company booking does not consume equipment-share attribution',
    () async {
      final storage = _ShareStorage((
        open: accepted,
        receivedAt: DateTime.now().toUtc(),
      ));
      final requests = <Object?>[];
      final container = _container(
        storage: storage,
        response: {'success': true, 'data': null},
        requestBodies: requests,
      );
      addTearDown(container.dispose);
      _selectRequired(container, companyId: 'company-1');

      final result = await container
          .read(bookingMutationProvider.notifier)
          .createBooking(companyId: 'company-1');

      expect(result.success, isTrue);
      expect((requests.single as Map).containsKey('shareId'), isFalse);
      expect(storage.consumed, isFalse);
    },
  );

  test('failed booking keeps the accepted attribution for retry', () async {
    final storage = _ShareStorage((
      open: accepted,
      receivedAt: DateTime.now().toUtc(),
    ));
    final requests = <Object?>[];
    final container = _container(
      storage: storage,
      response: {'success': false, 'error': 'temporary'},
      statusCode: 500,
      requestBodies: requests,
    );
    addTearDown(container.dispose);
    _selectRequired(container);

    final result = await container
        .read(bookingMutationProvider.notifier)
        .createBooking();

    expect(result.success, isFalse);
    expect((requests.single as Map)['shareId'], shareId);
    expect(storage.consumed, isFalse);
  });
}
