import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_client_provider.dart';
import 'package:prokat/features/bookings/state/booking_api_service.dart';
import 'package:prokat/features/bookings/state/booking_notifier.dart';
import 'package:prokat/features/bookings/state/booking_state.dart';

final bookingApiProvider = Provider<BookingApiService>((ref) {
  final api = ref.read(apiClientProvider);
  return BookingApiService(api);
});

final bookingProvider = StateNotifierProvider<BookingNotifier, BookingState>((
  ref,
) {
  final api = ref.read(bookingApiProvider);
  return BookingNotifier(api);
});
