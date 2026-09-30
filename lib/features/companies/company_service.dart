import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';

import 'company_models.dart';

class CompanyApiException implements Exception {
  final int? statusCode;
  final String code;
  const CompanyApiException(this.statusCode, this.code);
}

class CompanyService {
  final Dio dio;
  CompanyService(this.dio);

  // ApiClient accepts 4xx/5xx responses: never turn an error into an empty park
  // or a successful registration.
  Map<String, dynamic> _data(Response<dynamic> response) {
    final body = response.data;
    if ((response.statusCode ?? 500) >= 400 || body is! Map) {
      final error = body is Map ? body['error'] : null;
      throw CompanyApiException(
        response.statusCode,
        error is Map
            ? '${error['code'] ?? ''}'
            : body is Map
            ? '${body['code'] ?? ''}'
            : '',
      );
    }
    final data = body['data'] ?? body;
    if (data is! Map) throw const CompanyApiException(null, 'INVALID_RESPONSE');
    return Map<String, dynamic>.from(data);
  }

  Future<CompanyContext> me() async =>
      CompanyContext.fromJson(_data(await dio.get('/companies/me')));
  Future<void> apply({required String name, required String bin}) async {
    _data(
      await dio.post(
        '/companies/requests',
        data: {'name': name.trim(), 'bin': bin.trim()},
      ),
    );
  }

  Future<void> acceptInvitation(String id) async {
    _data(
      await dio.post(
        '/companies/invitations/${Uri.encodeComponent(id)}/accept',
      ),
    );
  }

  Future<CompanyFleet> fleet(String companyId) async => CompanyFleet.fromJson(
    _data(await dio.get('/companies/${Uri.encodeComponent(companyId)}/fleet')),
  );
  Future<void> updateProfile(
    String id, {
    required String name,
    required String description,
  }) async {
    _data(
      await dio.patch(
        '/companies/${Uri.encodeComponent(id)}',
        data: {'name': name.trim(), 'description': description.trim()},
      ),
    );
  }

  Future<Uint8List?> logo(String id) async {
    final response = await dio.get<List<int>>(
      '/companies/${Uri.encodeComponent(id)}/logo',
      options: Options(responseType: ResponseType.bytes),
    );
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200 || response.data == null) {
      throw CompanyApiException(response.statusCode, 'LOGO_UNAVAILABLE');
    }
    return Uint8List.fromList(response.data!);
  }

  Future<void> uploadLogo(String id, String path) async {
    _data(
      await dio.post(
        '/companies/${Uri.encodeComponent(id)}/logo',
        data: FormData.fromMap({'logo': await MultipartFile.fromFile(path)}),
      ),
    );
  }

  Future<void> saveEquipment(
    String companyId, {
    CompanyFleetItem? item,
    required String name,
    required String model,
    required String categoryId,
    String? serviceCityId,
    required String ownerComment,
  }) async {
    final path = '/companies/${Uri.encodeComponent(companyId)}/fleet';
    final data = {
      'name': name.trim(),
      'model': model.trim(),
      'categoryId': categoryId,
      if (serviceCityId != null && serviceCityId.isNotEmpty)
        'serviceCityId': serviceCityId,
      'ownerComment': ownerComment.trim(),
    };
    _data(
      item == null
          ? await dio.post(path, data: data)
          : await dio.patch(
              '$path/${Uri.encodeComponent(item.id)}',
              data: data,
            ),
    );
  }
}

final companyServiceProvider = Provider(
  (ref) => CompanyService(ref.watch(dioProvider)),
);

final companyContextProvider = FutureProvider.autoDispose<CompanyContext>((
  ref,
) async {
  final userId = ref.watch(authProvider.select((state) => state.currentUserId));
  if (userId == null) return const CompanyContext();
  return ref.watch(companyServiceProvider).me();
});

final companyFleetProvider = FutureProvider.autoDispose
    .family<CompanyFleet, String>((ref, id) async {
      final userId = ref.watch(
        authProvider.select((state) => state.currentUserId),
      );
      if (userId == null) throw const CompanyApiException(401, 'UNAUTHORIZED');
      return ref.watch(companyServiceProvider).fleet(id);
    });

final companyLogoProvider = FutureProvider.autoDispose
    .family<Uint8List?, String>((ref, id) async {
      final userId = ref.watch(
        authProvider.select((state) => state.currentUserId),
      );
      if (userId == null) return null;
      return ref.watch(companyServiceProvider).logo(id);
    });
