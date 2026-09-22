import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/features/auth/providers/authenticated_session_scope.dart';
import 'package:prokat/features/bookings/models/query_result.dart';
import 'package:prokat/features/requests/models/request_model.dart';
import 'package:prokat/features/requests/providers/owner_active_requests_provider.dart';
import 'package:prokat/features/requests/state/request_provider.dart';
import 'package:prokat/features/requests/state/request_service.dart';

class UnusedClient implements ApiClient {
  @override
  Dio dio = Dio();
}

class Requests extends RequestService {
  Requests() : super(UnusedClient());
  final gate = Completer<void>();
  int calls = 0;
  @override
  Future<ApiResponse<QueryResult<RequestModel>>> getOwnerRequests({
    required int page,
    required int itemsPerPage,
    required String status,
  }) async {
    final call = ++calls;
    if (call == 1) await gate.future;
    return ApiResponse.success(
      QueryResult(
        items: const [],
        page: page,
        itemsPerPage: itemsPerPage,
        count: call - 1,
      ),
    );
  }
}

void main() {
  test(
    'arrival while first page loads fetches again instead of losing event',
    () async {
      final api = Requests();
      final container = ProviderContainer(
        overrides: [
          authenticatedSessionScopeKeyProvider.overrideWithValue(
            const AuthenticatedSessionScopeKey.forUser('owner'),
          ),
          requestServiceProvider.overrideWithValue(api),
        ],
      );
      addTearDown(container.dispose);
      final initial = container.read(ownerActiveRequestsProvider.future);
      final arrival = container
          .read(ownerActiveRequestsProvider.notifier)
          .refreshForNewRequest();
      api.gate.complete();
      await initial;
      await arrival;
      expect(api.calls, 2);
      expect(container.read(ownerActiveRequestsProvider).valueOrNull?.count, 1);
    },
  );
}
