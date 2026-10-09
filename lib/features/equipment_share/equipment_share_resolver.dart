import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/features/equipment_share/equipment_share_id.dart';
import 'package:prokat/features/equipment_share/equipment_share_link.dart';

enum ShareResolutionStatus { resolved, unavailable, temporary, invalid }

class ShareResolution {
  const ShareResolution(this.status, [this.equipmentId]);
  final ShareResolutionStatus status;
  final String? equipmentId;
}

class EquipmentShareResolver {
  EquipmentShareResolver(this._dio);
  final Dio _dio;

  Future<ShareResolution> resolve(String shareId) async {
    if (!isValidShareId(shareId)) {
      return const ShareResolution(ShareResolutionStatus.invalid);
    }
    final cancellation = CancelToken();
    try {
      final response = await _dio
          .get<Object?>(
            '/equipment-shares/resolve/${Uri.encodeComponent(shareId)}',
            cancelToken: cancellation,
            options: Options(
              sendTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
              followRedirects: false,
              validateStatus: (_) => true,
            ),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 404) {
        return const ShareResolution(ShareResolutionStatus.unavailable);
      }
      if (response.statusCode != 200) {
        return const ShareResolution(ShareResolutionStatus.temporary);
      }
      final body = response.data;
      final data = body is Map && body['success'] == true ? body['data'] : null;
      final id = data is Map ? data['equipmentId'] : null;
      if (data is! Map ||
          data['shareId'] != shareId ||
          id is! String ||
          !EquipmentShareLink.isValidEquipmentId(id)) {
        return const ShareResolution(ShareResolutionStatus.temporary);
      }
      return ShareResolution(ShareResolutionStatus.resolved, id);
    } on TimeoutException {
      cancellation.cancel();
      return const ShareResolution(ShareResolutionStatus.temporary);
    } catch (_) {
      return const ShareResolution(ShareResolutionStatus.temporary);
    }
  }
}

final equipmentShareResolverProvider = Provider<EquipmentShareResolver>(
  (ref) => EquipmentShareResolver(ref.watch(dioProvider)),
);
