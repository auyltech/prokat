import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_provider.dart';

class PublishedLegalDocument {
  const PublishedLegalDocument({
    required this.slug,
    required this.title,
    required this.body,
    required this.version,
  });
  final String slug;
  final String title;
  final String body;
  final int version;
  factory PublishedLegalDocument.fromJson(Map<String, dynamic> value) =>
      PublishedLegalDocument(
        slug: value['slug'] as String,
        title: value['title'] as String,
        body: value['body'] as String,
        version: value['version'] as int,
      );
}

final legalDocumentsProvider = FutureProvider.autoDispose
    .family<List<PublishedLegalDocument>, String>((ref, locale) async {
      final response = await ref
          .watch(dioProvider)
          .get('/legal-documents', queryParameters: {'locale': locale});
      final items = (response.data as Map<String, dynamic>)['data'] as List;
      return items
          .map(
            (item) => PublishedLegalDocument.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    });
