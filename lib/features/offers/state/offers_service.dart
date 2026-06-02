import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:dio/dio.dart';

class OffersService {
  final ApiClient apiClient;

  OffersService(this.apiClient);

  Dio get _dio => apiClient.dio;

  Future<List<OfferModel>> getUserOffers() async {
    try {
      final res = await _dio.get('/offers');

      return (res.data['data'] as List)
          .map((e) => OfferModel.fromJson(e))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<OfferModel>> getOwnerOffers() async {
    try {
      print("get_owner_offers");
      final res = await _dio.get('/offers/owner');

      return (res.data['data'] as List)
          .map((e) => OfferModel.fromJson(e))
          .toList();
    } catch (e) {
      print(e);
      return [];
    }
  }

  Future<OfferModel?> createOffer({
    required String requestId,
    required String equipmentId,
    required int price,
    required String priceRate,
    String? comment,
  }) async {
    try {
      final res = await _dio.post(
        '/offers',
        data: {
          "requestId": requestId,
          "equipmentId": equipmentId,
          "price": price,
          "priceRate": priceRate,
          "comment": comment,
        },
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return OfferModel.fromJson(res.data['data']);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<OfferModel?> updateOffer({
    required String id,
    required String equipmentId,
    required int price,
    required String priceRate,
    String? comment,
  }) async {
    try {
      final res = await _dio.patch(
        '/offers/$id',
        data: {
          "id": id,
          "equipmentId": equipmentId,
          "price": price,
          "priceRate": priceRate,
          "comment": comment,
        },
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return OfferModel.fromJson(res.data['data']);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<OfferModel?> updateOfferStatus({
    required String id,
    required String status,
  }) async {
    try {
      final res = await _dio.patch(
        '/offers/$id/status',
        data: {"id": id, "status": status},
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return OfferModel.fromJson(res.data['data']);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<OfferModel?> acceptOffer({required String id}) async {
    try {
      final res = await _dio.post('/offers/$id/accept', data: {"id": id});

      if (res.statusCode == 200 || res.statusCode == 201) {
        return OfferModel.fromJson(res.data['data']);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<OfferModel?> rejectOffer({required String id}) async {
    try {
      final res = await _dio.post('/offers/$id/reject', data: {"id": id});

      if (res.statusCode == 200 || res.statusCode == 201) {
        return OfferModel.fromJson(res.data['data']);
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
