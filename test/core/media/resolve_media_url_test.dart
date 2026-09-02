import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/config/env.dart';
import 'package:prokat/core/media/resolve_media_url.dart';

void main() {
  test('joins relative user-content keys onto /media without a double slash', () {
    final resolved = resolveMediaUrl('user-content/category/icon.png');

    expect(resolved, '${Env.baseUrl}/media/user-content/category/icon.png');
    expect(resolved, isNot(contains('//media')));
  });

  test('keeps an absolute /media path on the API host without //media', () {
    final resolved = resolveMediaUrl('/media/user-content/equipment/a.jpg');

    expect(resolved, '${Env.baseUrl}/media/user-content/equipment/a.jpg');
    expect(resolved, isNot(contains('//media')));
  });

  test('does not send fallback images or assets through /media', () {
    expect(resolveMediaUrl('assets/media/empty.png'), 'assets/media/empty.png');
    expect(
      resolveMediaUrl('/images/equipment-fallback.png'),
      '${Env.baseUrl}/images/equipment-fallback.png',
    );
  });

  test('leaves external http(s) URLs unchanged', () {
    const randomUser =
        'https://randomuser.me/api/portraits/men/1.jpg';
    expect(resolveMediaUrl(randomUser), randomUser);
    expect(isApiMediaUrl(randomUser), isFalse);
  });

  test('isApiMediaUrl is true only for this API host /media paths', () {
    expect(
      isApiMediaUrl('${Env.baseUrl}/media/user-content/category/x.png'),
      isTrue,
    );
    expect(
      isApiMediaUrl('https://cdn.example/media/user-content/x.png'),
      isFalse,
    );
  });
}
