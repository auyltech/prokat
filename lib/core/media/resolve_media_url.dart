import 'package:prokat/core/config/env.dart';

String? resolveMediaUrl(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  if (trimmed.startsWith('assets/')) {
    return trimmed;
  }

  if (trimmed.startsWith('/images/')) {
    return Uri.parse(Env.baseUrl).resolve(trimmed).toString();
  }

  final parsed = Uri.tryParse(trimmed);
  if (parsed != null && parsed.hasScheme) {
    if (parsed.scheme != 'http' && parsed.scheme != 'https') {
      return trimmed;
    }
    return trimmed;
  }

  final path = trimmed.startsWith('/media/')
      ? trimmed
      : trimmed.startsWith('user-content/')
      ? '/media/$trimmed'
      : trimmed.startsWith('/')
      ? trimmed
      : '/media/$trimmed';

  return Uri.parse(Env.baseUrl).resolve(path).toString();
}

bool isApiMediaUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  final parsed = Uri.tryParse(url);
  if (parsed == null || !parsed.hasScheme) {
    return !url.startsWith('//') &&
        (url.startsWith('/media/') ||
            RegExp(r'^/companies/[^/]+/fleet/[^/]+/images/[^/]+$')
                .hasMatch(url));
  }

  final api = Uri.tryParse(Env.baseUrl);
  if (api == null) return parsed.path.contains('/media/');

  if (parsed.scheme != 'http' && parsed.scheme != 'https') return false;
  return parsed.origin == api.origin &&
      (parsed.path.startsWith('/media/') ||
          RegExp(r'^/companies/[^/]+/fleet/[^/]+/images/[^/]+$')
              .hasMatch(parsed.path));
}
