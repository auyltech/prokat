import 'package:dio/dio.dart';
import 'package:prokat/core/api/api_client.dart';

import 'equipment_demand_models.dart';

class EquipmentDemandService {
  final ApiClient apiClient;
  const EquipmentDemandService(this.apiClient);

  Future<DemandConfig> getConfig() async {
    final response = await apiClient.dio.get('/equipment-demand/config');
    if ((response.statusCode ?? 500) >= 300) {
      return const DemandConfig.disabled();
    }
    final body = response.data;
    return DemandConfig.fromJson(body is Map ? body['data'] : null);
  }

  Future<DemandForm> getForm(String campaignId, String locale) async {
    final response = await apiClient.dio.get(
      '/equipment-demand/options',
      queryParameters: {
        'campaignId': campaignId,
        'locale': locale.toUpperCase(),
      },
    );
    _throwIfFailed(response);
    final data = response.data is Map ? response.data['data'] : null;
    if (data is! Map || data['options'] is! List) {
      throw const FormatException('Invalid demand form');
    }
    return DemandForm(
      campaignId: campaignId,
      options: (data['options'] as List)
          .map(DemandOption.fromJson)
          .toList(growable: false),
    );
  }

  Future<void> submit({
    required String clientSubmissionId,
    required String campaignId,
    required String city,
    required List<String> optionIds,
    String? otherText,
  }) async {
    final response = await apiClient.dio.post(
      '/equipment-demand/responses',
      data: {
        'clientSubmissionId': clientSubmissionId,
        'campaignId': campaignId,
        'city': city,
        'optionIds': optionIds,
        'otherText': otherText,
      },
    );
    _throwIfFailed(response);
  }

  void _throwIfFailed(Response<dynamic> response) {
    if ((response.statusCode ?? 500) < 300) return;
    final body = response.data;
    final error = body is Map ? body['error'] : null;
    throw DemandApiException(
      error is Map && error['message'] is String
          ? error['message'] as String
          : 'Request failed',
      code: error is Map && error['code'] is String
          ? error['code'] as String
          : null,
    );
  }
}
