import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/features/auth/providers/authenticated_session_scope.dart';
import 'package:prokat/features/bookings/models/query_result.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/models/offer_query.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/offers/state/offers_service.dart';
import 'package:prokat/features/requests/models/request_model.dart';
import 'package:prokat/features/requests/providers/client_active_requests_provider.dart';
import 'package:prokat/features/requests/state/request_provider.dart';
import 'package:prokat/features/requests/state/request_service.dart';
import 'package:prokat/features/workflow/providers/workflow_providers.dart';

void main() {
  test('resync refreshes loaded request and offer lists', () async {
    final requests = _FakeRequestService();
    final offers = _FakeOffersService();
    final container = ProviderContainer(
      overrides: [
        authenticatedSessionScopeKeyProvider.overrideWithValue(
          const AuthenticatedSessionScopeKey.forUser('user-me'),
        ),
        requestServiceProvider.overrideWithValue(requests),
        offersServiceProvider.overrideWithValue(offers),
      ],
    );
    addTearDown(container.dispose);

    await container.read(clientActiveRequestsProvider.future);
    await container.read(clientOffersProvider(const OfferQuery.active()).future);

    expect(requests.getClientRequestsCalls, 1);
    expect(offers.getClientOffersCalls, 1);

    await container
        .read(workflowCacheCoordinatorProvider)
        .resyncAfterReconnect();

    expect(requests.getClientRequestsCalls, 2);
    expect(offers.getClientOffersCalls, 2);
  });

  test('resync skips offer lists that were never loaded', () async {
    final offers = _FakeOffersService();
    final container = ProviderContainer(
      overrides: [
        authenticatedSessionScopeKeyProvider.overrideWithValue(
          const AuthenticatedSessionScopeKey.forUser('user-me'),
        ),
        offersServiceProvider.overrideWithValue(offers),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(workflowCacheCoordinatorProvider)
        .resyncAfterReconnect();

    expect(offers.getClientOffersCalls, 0);
    expect(offers.getOwnerOffersCalls, 0);
  });
}

class _FakeRequestService extends RequestService {
  _FakeRequestService() : super(_TestApiClient(Dio()));

  int getClientRequestsCalls = 0;

  @override
  Future<ApiResponse<QueryResult<RequestModel>>> getClientRequests({
    required int page,
    required int itemsPerPage,
    required String status,
  }) async {
    getClientRequestsCalls++;
    return ApiResponse.success(
      QueryResult(
        items: const [],
        page: page,
        itemsPerPage: itemsPerPage,
        count: 0,
      ),
    );
  }
}

class _FakeOffersService extends OffersService {
  _FakeOffersService() : super(_TestApiClient(Dio()));

  int getClientOffersCalls = 0;
  int getOwnerOffersCalls = 0;

  @override
  Future<ApiResponse<QueryResult<OfferModel>>> getClientOffers({
    required int page,
    required int itemsPerPage,
    OfferListFilter? filter,
    String? requestId,
  }) async {
    getClientOffersCalls++;
    return ApiResponse.success(
      QueryResult(
        items: const [],
        page: page,
        itemsPerPage: itemsPerPage,
        count: 0,
      ),
    );
  }

  @override
  Future<ApiResponse<QueryResult<OfferModel>>> getOwnerOffers({
    required int page,
    required int itemsPerPage,
    OfferListFilter? filter,
    String? requestId,
  }) async {
    getOwnerOffersCalls++;
    return ApiResponse.success(
      QueryResult(
        items: const [],
        page: page,
        itemsPerPage: itemsPerPage,
        count: 0,
      ),
    );
  }
}

class _TestApiClient implements ApiClient {
  _TestApiClient(this.dio);

  @override
  Dio dio;
}
