import 'package:dio/dio.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_helper.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_model.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_response.dart';

class PriceNegotiationService {
  final ApiClient apiClient;

  PriceNegotiationService(this.apiClient);

  Dio get _dio => apiClient.dio;

  Future<List<PriceNegotiation>> getBookingNegotiations(
    String bookingId,
  ) async {
    try {
      final res = await _dio.get('/price-negotiations/booking/$bookingId');

      final data = res.data is Map<String, dynamic> ? res.data['data'] : null;

      if (data is! List) return const [];

      return data
          .whereType<dynamic>()
          .map(
            (e) => PriceNegotiation.fromJson(
              e is Map<String, dynamic>
                  ? e
                  : Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(growable: false);
    } on DioException catch (e) {
      throw Exception(extractBackendMessage(e));
    }
  }

  Future<List<PriceNegotiation>> getOfferNegotiations(String offerId) async {
    try {
      final res = await _dio.get('/price-negotiations/offer/$offerId');
      final data = res.data is Map<String, dynamic> ? res.data['data'] : null;
      if (data is! List) return const [];
      return data
          .whereType<dynamic>()
          .map(
            (e) => PriceNegotiation.fromJson(
              e is Map<String, dynamic>
                  ? e
                  : Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(growable: false);
    } on DioException catch (e) {
      throw Exception(extractBackendMessage(e));
    }
  }

  Future<PriceNegotiation> getPriceNegotiation(String id) async {
    try {
      final res = await _dio.get('/price-negotiations/$id');
      final data = res.data is Map<String, dynamic> ? res.data['data'] : null;
      final json = data is Map<String, dynamic>
          ? data
          : data is Map
          ? Map<String, dynamic>.from(data)
          : null;
      if (json == null) {
        throw Exception('Negotiation not found');
      }
      return PriceNegotiation.fromJson(json);
    } on DioException catch (e) {
      throw Exception(extractBackendMessage(e));
    }
  }

  Future<PriceNegotiation> createPriceNegotiation({
    String? bookingId,
    String? offerId,
    required int price,
    String? priceRate,
    String? comment,
    String? type,
  }) async {
    final hasBooking = (bookingId ?? '').trim().isNotEmpty;
    final hasOffer = (offerId ?? '').trim().isNotEmpty;

    if (hasBooking == hasOffer) {
      throw Exception('Provide either bookingId or offerId');
    }

    try {
      final res = await _dio.post(
        '/price-negotiations',
        data: {
          'type': type,
          if (hasBooking) 'bookingId': bookingId,
          if (hasOffer) 'offerId': offerId,
          'price': price,
          if ((priceRate ?? '').trim().isNotEmpty) 'priceRate': priceRate,
          if ((comment ?? '').trim().isNotEmpty) 'comment': comment,
        },
      );

      final data = res.data is Map<String, dynamic> ? res.data['data'] : null;
      final json = data is Map<String, dynamic>
          ? data
          : data is Map
          ? Map<String, dynamic>.from(data)
          : null;
      if (json == null) {
        throw Exception('Failed to create negotiation');
      }
      return PriceNegotiation.fromJson(json);
    } on DioException catch (e) {
      throw Exception(extractBackendMessage(e));
    }
  }

  Future<PriceNegotiation> respondToPriceNegotiation({
    required String negotiationId,
    required PriceNegotiationResponse response,
  }) async {
    try {
      final res = await _dio.post(
        '/price-negotiations/$negotiationId/respond',
        data: {'action': toBackendPriceNegotiationResponse(response)},
      );

      final data = res.data is Map<String, dynamic> ? res.data['data'] : null;
      final json = data is Map<String, dynamic>
          ? data
          : data is Map
          ? Map<String, dynamic>.from(data)
          : null;
      if (json == null) {
        throw Exception('Failed to respond');
      }
      return PriceNegotiation.fromJson(json);
    } on DioException catch (e) {
      throw Exception(extractBackendMessage(e));
    }
  }

  Future<void> cancelPriceNegotiation(String negotiationId) async {
    try {
      await _dio.delete('/price-negotiations/$negotiationId');
    } on DioException catch (e) {
      throw Exception(extractBackendMessage(e));
    }
  }
}
