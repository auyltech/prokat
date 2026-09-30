enum CatalogGroup {
  machinery,
  equipment;

  static const machineryApi = 'MACHINERY';
  static const equipmentApi = 'EQUIPMENT';

  String get apiValue => switch (this) {
    CatalogGroup.machinery => machineryApi,
    CatalogGroup.equipment => equipmentApi,
  };

  static CatalogGroup fromApi(String? raw) {
    final normalized = raw?.trim().toUpperCase();
    if (normalized == equipmentApi) return CatalogGroup.equipment;
    return CatalogGroup.machinery;
  }
}
