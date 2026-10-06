import 'package:dio/dio.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_helper.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/core/constants/api_routes.dart';
import 'package:prokat/core/mutation/mutation_model.dart';
import 'package:prokat/features/user_safety/models/blocked_user.dart';
import 'package:prokat/features/user_safety/models/report_reason.dart';
import 'package:prokat/features/user_safety/models/report_target.dart';

abstract interface class UserSafetyApi {
  Future<ApiResponse<List<BlockedUser>>> getBlockedUsers({
    required int page,
    required int itemsPerPage,
  });

  Future<MutationResponse> blockUser(String userId);

  Future<MutationResponse> unblockUser(String userId);

  Future<MutationResponse> createReport({
    required ReportTarget target,
    required ReportReason reason,
    String? comment,
  });
}

class UserSafetyService implements UserSafetyApi {
  UserSafetyService(this.apiClient);

  final ApiClient apiClient;

  Dio get _dio => apiClient.dio;

  @override
  Future<ApiResponse<List<BlockedUser>>> getBlockedUsers({
    required int page,
    required int itemsPerPage,
  }) async {
    try {
      final response = await _dio.get(
        ApiRoutes.userBlocks,
        queryParameters: {'page': page, 'itemsPerPage': itemsPerPage},
      );
      return handleApiResponse<List<BlockedUser>>(
        response: response,
        parser: (data) {
          final items = data is Map ? data['data'] : null;
          if (items is! List) {
            throw const FormatException('Expected blocked users list');
          }
          return items
              .whereType<Map<String, dynamic>>()
              .map(BlockedUser.fromJson)
              .toList();
        },
        fallbackMessage: 'Failed to load blocked users',
      );
    } on DioException catch (error) {
      return handleDioException(error);
    } catch (error) {
      return handleUnknownException(error);
    }
  }

  @override
  Future<MutationResponse> blockUser(String userId) {
    return _mutate(
      () => _dio.post(ApiRoutes.userBlocks, data: {'userId': userId}),
    );
  }

  @override
  Future<MutationResponse> unblockUser(String userId) {
    return _mutate(
      () =>
          _dio.delete('${ApiRoutes.userBlocks}/${Uri.encodeComponent(userId)}'),
    );
  }

  @override
  Future<MutationResponse> createReport({
    required ReportTarget target,
    required ReportReason reason,
    String? comment,
  }) {
    final trimmed = comment?.trim();
    return _mutate(
      () => _dio.post(
        ApiRoutes.reports,
        data: {
          'targetType': target.type.apiValue,
          'targetId': target.targetId,
          'reason': reason.apiValue,
          if (trimmed != null && trimmed.isNotEmpty) 'comment': trimmed,
        },
      ),
    );
  }

  Future<MutationResponse> _mutate(Future<Response> Function() request) async {
    try {
      final response = await request();
      final result = handleEmptyApiResponse(response: response);
      return MutationResponse(
        success: result.success,
        message: result.message,
        errorCode: result.errorCode,
      );
    } on DioException catch (error) {
      final result = handleDioException<void>(error);
      return MutationResponse(
        success: false,
        message: result.message,
        errorCode: result.errorCode,
      );
    } catch (error) {
      return MutationResponse(success: false, message: error.toString());
    }
  }
}
