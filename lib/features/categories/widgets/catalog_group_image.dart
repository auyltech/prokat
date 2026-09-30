import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';

extension CatalogGroupImage on CatalogGroup {
  /// Group artwork for "all categories" and categories without an image.
  AppImage get stdImage => switch (this) {
    CatalogGroup.machinery => AppImages.machineryStd,
    CatalogGroup.equipment => AppImages.equipmentStd,
  };
}
