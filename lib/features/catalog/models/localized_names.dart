class LocalizedNames {
  final String en;
  final String ru;
  final String kk;

  const LocalizedNames({this.en = '', this.ru = '', this.kk = ''});

  factory LocalizedNames.fromJson(dynamic json) {
    if (json is! Map) return const LocalizedNames();
    return LocalizedNames(
      en: json['en']?.toString() ?? '',
      ru: json['ru']?.toString() ?? '',
      kk: json['kk']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'en': en, 'ru': ru, 'kk': kk};

  bool get isEmpty => en.isEmpty && ru.isEmpty && kk.isEmpty;

  String pick(String languageCode, {String fallback = ''}) {
    final code = languageCode.toLowerCase();
    final byLocale = switch (code) {
      'ru' => ru,
      'kk' => kk,
      _ => en,
    };
    if (byLocale.trim().isNotEmpty) return byLocale.trim();
    if (en.trim().isNotEmpty) return en.trim();
    if (ru.trim().isNotEmpty) return ru.trim();
    if (kk.trim().isNotEmpty) return kk.trim();
    return fallback;
  }
}
