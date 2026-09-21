import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/features/auth/providers/authenticated_session_scope.dart';
import 'package:prokat/features/bookings/models/query_result.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/models/offer_query.dart';
import 'package:prokat/features/offers/models/offer_status.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/offers/state/offers_service.dart';
import 'package:prokat/features/requests/models/request_model.dart';
import 'package:prokat/features/requests/models/request_status.dart';
import 'package:prokat/features/requests/providers/owner_active_requests_provider.dart';
import 'package:prokat/features/requests/providers/owner_pending_requests_count_provider.dart';
import 'package:prokat/features/requests/state/request_provider.dart';
import 'package:prokat/features/requests/state/request_service.dart';

class _UnusedClient implements ApiClient {
  @override
  Dio dio = Dio();
}

RequestModel _request(
  String id, {
  RequestStatus status = RequestStatus.created,
  Duration age = Duration.zero,
}) {
  return RequestModel(
    id: id,
    status: status,
    capacity: '',
    offeredPrice: 0,
    createdAt: DateTime.now().subtract(age),
  );
}

OfferModel _offer(String requestId, OfferStatus status) {
  return OfferModel(
    id: 'offer-$requestId',
    status: status,
    requestId: requestId,
    chatId: 'chat-$requestId',
    equipmentId: 'equipment-1',
    price: 10000,
  );
}

class _Requests extends RequestService {
  _Requests(this.items) : super(_UnusedClient());

  final List<RequestModel> items;

  @override
  Future<ApiResponse<QueryResult<RequestModel>>> getOwnerRequests({
    required int page,
    required int itemsPerPage,
    required String status,
  }) async {
    return ApiResponse.success(
      QueryResult(
        items: items,
        page: page,
        itemsPerPage: itemsPerPage,
        count: items.length,
      ),
    );
  }
}

class _Offers extends OffersService {
  _Offers(this.items) : super(_UnusedClient());

  final List<OfferModel> items;

  @override
  Future<ApiResponse<QueryResult<OfferModel>>> getOwnerOffers({
    required int page,
    required int itemsPerPage,
    OfferListFilter? filter,
    String? requestId,
  }) async {
    return ApiResponse.success(
      QueryResult(
        items: items,
        page: page,
        itemsPerPage: itemsPerPage,
        count: items.length,
      ),
    );
  }
}

ProviderContainer _container({
  required List<RequestModel> requests,
  required List<OfferModel> offers,
}) {
  final container = ProviderContainer(
    overrides: [
      authenticatedSessionScopeKeyProvider.overrideWithValue(
        const AuthenticatedSessionScopeKey.forUser('owner'),
      ),
      requestServiceProvider.overrideWithValue(_Requests(requests)),
      offersServiceProvider.overrideWithValue(_Offers(offers)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<int> _count(ProviderContainer container) async {
  await container.read(ownerActiveRequestsProvider.future);
  await container.read(ownerOffersProvider(const OfferQuery.active()).future);
  return container.read(ownerPendingRequestsCountProvider);
}

void main() {
  test('counts only tenders the owner has not answered yet', () async {
    final container = _container(
      requests: [_request('r1'), _request('r2'), _request('r3')],
      offers: [_offer('r2', OfferStatus.created)],
    );

    expect(await _count(container), 2);
  });

  test('expired and archived tenders never reach the badge', () async {
    final container = _container(
      requests: [
        _request('r1'),
        _request('r2', age: const Duration(hours: 25)),
        _request('r3', status: RequestStatus.cancelled),
        _request('r4', status: RequestStatus.accepted),
      ],
      offers: const [],
    );

    expect(await _count(container), 1);
  });

  test('badge drops a tender the moment it leaves the feed', () async {
    final container = _container(
      requests: [_request('r1'), _request('r2')],
      offers: const [],
    );
    expect(await _count(container), 2);

    // A hidden ("rejected") tender is gone from the next feed payload.
    container
        .read(ownerActiveRequestsProvider.notifier)
        .state = AsyncData(
      container.read(ownerActiveRequestsProvider).requireValue.copyWith(
        items: [_request('r1')],
        count: 1,
      ),
    );

    expect(container.read(ownerPendingRequestsCountProvider), 1);
  });
}
