enum CatalogSpecType {
  number,
  select,
  multiSelect,
  boolean,
  string,
  unknown;

  static CatalogSpecType parse(String? raw) {
    return switch ((raw ?? '').trim().toUpperCase()) {
      'NUMBER' => CatalogSpecType.number,
      'SELECT' => CatalogSpecType.select,
      'MULTI_SELECT' => CatalogSpecType.multiSelect,
      'BOOLEAN' => CatalogSpecType.boolean,
      'STRING' || 'TEXT' => CatalogSpecType.string,
      _ => CatalogSpecType.unknown,
    };
  }

  String get wireName => switch (this) {
    CatalogSpecType.number => 'NUMBER',
    CatalogSpecType.select => 'SELECT',
    CatalogSpecType.multiSelect => 'MULTI_SELECT',
    CatalogSpecType.boolean => 'BOOLEAN',
    CatalogSpecType.string => 'STRING',
    CatalogSpecType.unknown => 'UNKNOWN',
  };

  bool get isKnown => this != CatalogSpecType.unknown;
}
