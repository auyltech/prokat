class FaqModel {
  const FaqModel({
    this.id,
    required this.category,
    required this.order,
    required this.isPublished,
    required this.translations,
  });

  final String? id;
  final String category;
  final int order;
  final bool isPublished;

  final List<FaqTranslation> translations;
}

class FaqTranslation {
  const FaqTranslation({
    required this.locale,
    required this.question,
    required this.answer,
  });

  final String locale; // en, ru, kk
  final String question;
  final String answer;
}

extension FaqLocalization on FaqModel {
  FaqTranslation translation(String locale) {
    return translations.firstWhere(
      (t) => t.locale == locale,
      orElse: () => translations.first,
    );
  }
}
