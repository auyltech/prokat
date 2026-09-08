import 'package:dio/dio.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/constants/api_routes.dart';
import 'package:prokat/features/catalog/models/catalog_bundle.dart';
import 'package:prokat/features/catalog/models/catalog_facet.dart';

class CatalogFetchResult {
  final CatalogBundle? bundle;
  final bool notModified;

  const CatalogFetchResult({this.bundle, this.notModified = false});
}

class CatalogService {
  final ApiClient apiClient;

  CatalogService(this.apiClient);

  Dio get _dio => apiClient.dio;

  Future<CatalogFetchResult> fetchBundle({String? ifNoneMatch}) async {
    final response = await _dio.get(
      ApiRoutes.catalog,
      options: Options(
        headers: {
          if (ifNoneMatch != null && ifNoneMatch.isNotEmpty)
            'If-None-Match': '"$ifNoneMatch"',
        },
      ),
    );

    if (response.statusCode == 304) {
      return const CatalogFetchResult(notModified: true);
    }

    if (response.statusCode != 200) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );
    }

    final payload = response.data;
    if (payload is! Map) {
      throw const FormatException('Failed to load CatalogBundle.');
    }
    final data = payload['data'];
    if (data is! Map) {
      throw const FormatException('Failed to load CatalogBundle.');
    }

    return CatalogFetchResult(
      bundle: CatalogBundle.fromJson(Map<String, dynamic>.from(data)),
    );
  }

  Future<List<CatalogFacet>> fetchFacets(String categoryId) async {
    final response = await _dio.get(
      ApiRoutes.catalogFacets,
      queryParameters: {'categoryId': categoryId},
    );
    if (response.statusCode != 200) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );
    }
    final payload = response.data;
    if (payload is! Map) {
      throw const FormatException('Failed to load catalog facets.');
    }
    final data = payload['data'];
    if (data is! Map) {
      throw const FormatException('Failed to load catalog facets.');
    }
    final raw = data['facets'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((item) {
      return CatalogFacet.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }
}
