import 'package:dio/dio.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_helper.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/core/errors/api_exception.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_model.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_query.dart';
import 'package:prokat/features/bookings/models/query_result.dart';

class PriceNegotiationService {
  final ApiClient apiClient;

  PriceNegotiationService(this.apiClient);

  Dio get _dio => apiClient.dio;

  Future<ApiResponse<QueryResult<PriceNegotiation>>> getPriceNegotiations({
    required PriceNegotiationQuery query,
    required int page,
  }) async {
    try {
      final isBooking = query.bookingId != null;
      final offerId = query.offerId?.trim() ?? '';
      final path = isBooking
          ? '/price-negotiations/booking'
          : '/price-negotiations/offer/$offerId';
      final response = await _dio.get(
        path,
        queryParameters: {
          'page': page,
          'itemsPerPage': query.itemsPerPage,
          if (isBooking) 'bookingId': query.bookingId,
          if (query.filter != null) 'status': query.filter!.apiValue,
        },
      );

      return handleApiResponse<QueryResult<PriceNegotiation>>(
        response: response,
        parser: (data) {
          final payload = data is Map<String, dynamic> && data['data'] is Map
              ? Map<String, dynamic>.from(data['data'] as Map)
              : Map<String, dynamic>.from(data as Map);
          final itemsJson = payload['items'] ?? payload['data'];

          if (itemsJson is! List) {
            throw const FormatException("Expected price negotiation list");
          }

          final items = itemsJson.map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException("Invalid price negotiation item");
            }

            return PriceNegotiation.fromJson(item);
          }).toList();

          return QueryResult(
            items: items,
            page: (payload['page'] as num?)?.toInt() ?? page,
            itemsPerPage:
                (payload['itemsPerPage'] as num?)?.toInt() ??
                query.itemsPerPage,
            count: (payload['count'] as num?)?.toInt() ?? items.length,
          );
        },
        fallbackMessage: "Failed to load price negotiations",
      );
    } on DioException catch (error) {
      final exception = ApiException.fromDio(error);

      return ApiResponse.failure(
        message: exception.message.isNotEmpty
            ? exception.message
            : "Request failed",
        error: (exception.data ?? error).toString(),
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
          'priceRate': priceRate,
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
        error: (exception.data ?? error).toString(),
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
        error: (exception.data ?? error).toString(),
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
        error: (exception.data ?? error).toString(),
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
