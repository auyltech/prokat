import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';

class CompanyProfileApi {
  final Dio dio;
  CompanyProfileApi(this.dio);
  Future<dynamic> request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final response = await dio.request(
      '/company-profile$path',
      data: body,
      options: Options(method: method),
    );
    if (response.statusCode == null ||
        response.statusCode! >= 400 ||
        response.data is! Map) {
      final data = response.data;
      final message = data is Map
          ? (data['error'] is Map ? data['error']['message'] : data['message'])
          : null;
      throw Exception(
        message ?? 'Не удалось выполнить действие. Повторите попытку.',
      );
    }
    return response.data['data'];
  }
}

final companyProfileApiProvider = Provider(
  (ref) => CompanyProfileApi(ref.watch(dioProvider)),
);
final companyAccessProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  ref.watch(authProvider.select((a) => a.currentUserId));
  return Map<String, dynamic>.from(
    await ref.watch(companyProfileApiProvider).request('/me'),
  );
});
final companyMembersProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, id) async {
      ref.watch(authProvider.select((a) => a.currentUserId));
      return Map<String, dynamic>.from(
        await ref.watch(companyProfileApiProvider).request('/$id/members'),
      );
    });
final companyBalanceProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, id) async {
      ref.watch(authProvider.select((a) => a.currentUserId));
      return Map<String, dynamic>.from(
        await ref.watch(companyProfileApiProvider).request('/$id/balance'),
      );
    });
final companyDashboardProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, id) async {
      ref.watch(authProvider.select((a) => a.currentUserId));
      return Map<String, dynamic>.from(
        await ref.watch(companyProfileApiProvider).request('/$id/dashboard'),
      );
    });
String companyProfileError(Object e) =>
    e.toString().replaceFirst('Exception: ', '');
