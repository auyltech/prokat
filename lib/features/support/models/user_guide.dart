import 'package:prokat/features/support/models/guide_icon.dart';

class UserGuide {
  const UserGuide({
    required this.id,
    required this.slug,
    required this.category,
    required this.icon,
    required this.order,
    required this.isPublished,
    required this.translations,
  });

  final String id;
  final String slug;
  final String category;
  final GuideIcon icon;
  final int order;
  final bool isPublished;

  final List<UserGuideTranslation> translations;
}

class UserGuideTranslation {
  const UserGuideTranslation({
    required this.locale,
    required this.title,
    required this.summary,
    required this.content,
  });

  final String locale; // en, ru, kk
  final String title;
  final String summary;
  final String content;
}

extension UserGuideLocalization on UserGuide {
  UserGuideTranslation translation(String locale) {
    return translations.firstWhere(
      (t) => t.locale == locale,
      orElse: () => translations.first,
    );
  }
}
