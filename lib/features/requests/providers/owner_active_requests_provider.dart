import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/requests/models/request_model.dart';
import 'package:prokat/features/requests/state/owner_active_requests_notifier.dart';

final ownerActiveRequestsProvider =
    AsyncNotifierProvider<
      OwnerActiveRequestsNotifier,
      QueryState<RequestModel>
    >(OwnerActiveRequestsNotifier.new);
