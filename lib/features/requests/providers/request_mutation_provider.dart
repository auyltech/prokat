import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:prokat/features/requests/state/request_mutation_notifier.dart';
import 'package:prokat/features/requests/state/request_provider.dart';
import 'package:prokat/features/requests/state/request_state.dart';

final requestMutationProvider =
    StateNotifierProvider<RequestMutationNotifier, RequestState>((ref) {
      final api = ref.read(requestServiceProvider);

      return RequestMutationNotifier(api: api, ref: ref);
    });
