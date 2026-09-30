import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/config/env.dart';
import 'package:prokat/core/media/media_image_prefetcher.dart';

void main() {
  test('mediaPrefetchUrls keeps unique API media URLs only', () {
    final urls = mediaPrefetchUrls([
      null,
      '',
      '  ',
      'assets/media/empty.png',
      'user-content/category/a.png',
      '/media/user-content/category/a.png',
      '/media/user-content/category/b.png',
      'https://cdn.example/x.png',
      '/images/equipment-fallback.png',
    ]);

    expect(
      urls,
      unorderedEquals([
        '${Env.baseUrl}/media/user-content/category/a.png',
        '${Env.baseUrl}/media/user-content/category/b.png',
      ]),
    );
  });
}
