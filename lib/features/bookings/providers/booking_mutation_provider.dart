import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/features/bookings/state/booking_mutation_state.dart';
import 'package:prokat/features/bookings/state/booking_service.dart';
import 'package:prokat/features/bookings/state/booking_mutation_notifier.dart';

final bookingApiProvider = Provider<BookingService>((ref) {
  final api = ref.read(apiClientProvider);

  return BookingService(api);
});

final bookingMutationProvider =
    StateNotifierProvider<BookingMutationNotifier, BookingMutationState>((ref) {
      final api = ref.read(bookingApiProvider);

      return BookingMutationNotifier(api: api, ref: ref);
    });
