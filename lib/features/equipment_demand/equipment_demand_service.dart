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
    final allowOther = data['allowOther'] == true;
    DemandOtherOption? other;
    if (allowOther && data['other'] is Map) {
      other = DemandOtherOption.fromJson(data['other']);
    }
    return DemandForm(
      campaignId: campaignId,
      allowOther: allowOther,
      other: other,
      options: (data['options'] as List)
          .map(DemandOption.fromJson)
          .toList(growable: false),
    );
  }

  Future<void> submit({
    required String clientSubmissionId,
    required String campaignId,
    required List<Map<String, Object>> selections,
    required List<String> cityIds,
    String? otherProvideText,
    String? otherRentText,
  }) async {
    final other = <String, String>{};
    if (otherProvideText != null && otherProvideText.isNotEmpty) {
      other['provideText'] = otherProvideText;
    }
    if (otherRentText != null && otherRentText.isNotEmpty) {
      other['rentText'] = otherRentText;
    }

    final response = await apiClient.dio.post(
      '/equipment-demand/responses',
      data: {
        'clientSubmissionId': clientSubmissionId,
        'campaignId': campaignId,
        'selections': selections,
        'cityIds': cityIds,
        if (other.isNotEmpty) 'other': other,
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
