import 'package:dio/dio.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_helper.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/core/errors/api_exception.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_model.dart';

class PriceNegotiationService {
  final ApiClient apiClient;

  PriceNegotiationService(this.apiClient);

  Dio get _dio => apiClient.dio;

  Future<ApiResponse<List<PriceNegotiation>>> getPriceNegotiations() async {
    try {
      final response = await _dio.get('/price-negotiations/booking');

      return handleApiResponse<List<PriceNegotiation>>(
        response: response,
        parser: (data) {
          if (data is! List) {
            throw FormatException("Expected price negotiation list");
          }

          return data.map((item) {
            if (item is! Map<String, dynamic>) {
              throw FormatException("Invalid price negotiation item");
            }

            return PriceNegotiation.fromJson(item);
          }).toList();
        },
        fallbackMessage: "Failed to load price negotiations",
      );
    } on DioException catch (error) {
      final exception = ApiException.fromDio(error);

      return ApiResponse.failure(
        message: exception.message.isNotEmpty
            ? exception.message
            : "Request failed",
        error: exception.data ?? error,
        statusCode: exception.statusCode,
      );
    } catch (e) {
      return ApiResponse.failure(
        message: "Unexpected error",
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<void>> createPriceNegotiation({
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
      final response = await _dio.post(
        hasOffer ? '/price-negotiations/offer' : '/price-negotiations',
        data: {
          'type': type,
          if (hasBooking) 'bookingId': bookingId,
          if (hasOffer) 'offerId': offerId,
          'price': price,
          'priceRate': 'PER_TRIP',
          // if ((priceRate ?? '').trim().isNotEmpty) 'priceRate': priceRate,
          if ((comment ?? '').trim().isNotEmpty) 'comment': comment,
        },
      );

      return handleEmptyApiResponse(
        response: response,
        fallbackMessage: "Counter Offer Sent",
      );
    } on DioException catch (error) {
      final exception = ApiException.fromDio(error);

      return ApiResponse.failure(
        message: exception.message.isNotEmpty
            ? exception.message
            : "Request failed",
        error: exception.data ?? error,
        statusCode: exception.statusCode,
      );
    } catch (e) {
      return ApiResponse.failure(
        message: "Unexpected error",
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<void>> respondToPriceNegotiation({
    required String negotiationId,
    required PriceNegotiationResponse decision,
  }) async {
    try {
      final response = await _dio.post(
        '/price-negotiations/$negotiationId/respond',
        data: {
          'action': decision == PriceNegotiationResponse.accept
              ? "ACCEPT"
              : "REJECT",
        },
      );

      return handleEmptyApiResponse(
        response: response,
        fallbackMessage: "Counter Offer Responded",
      );
    } on DioException catch (error) {
      final exception = ApiException.fromDio(error);

      return ApiResponse.failure(
        message: exception.message.isNotEmpty
            ? exception.message
            : "Request failed",
        error: exception.data ?? error,
        statusCode: exception.statusCode,
      );
    } catch (e) {
      return ApiResponse.failure(
        message: "Unexpected error",
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<void>> cancelPriceNegotiation(String negotiationId) async {
    try {
      final response = await _dio.delete('/price-negotiations/$negotiationId');

      return handleEmptyApiResponse(
        response: response,
        fallbackMessage: "Counter Offer Cancelled",
      );
    } on DioException catch (error) {
      final exception = ApiException.fromDio(error);

      return ApiResponse.failure(
        message: exception.message.isNotEmpty
            ? exception.message
            : "Request failed",
        error: exception.data ?? error,
        statusCode: exception.statusCode,
      );
    } catch (e) {
      return ApiResponse.failure(
        message: "Unexpected error",
        error: e.toString(),
      );
    }
  }
}
