import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/requests/models/request_model.dart';
import 'package:prokat/features/requests/state/client_active_requests_notifier.dart';

final clientActiveRequestsProvider =
    AsyncNotifierProvider<
      ClientActiveRequestsNotifier,
      QueryState<RequestModel>
    >(ClientActiveRequestsNotifier.new);
