import 'package:prokat/core/widgets/ui_kit/app_icon.dart';
import 'package:prokat/core/widgets/ui_kit/asset_paths.dart';

abstract final class AppIcons {
  static const AppIcon check = AppIcon.asset('${kIconsPath}check.svg');
  static const AppIcon eyeOpen = AppIcon.asset('${kIconsPath}eye_open.svg');
  static const AppIcon eyeClose = AppIcon.asset('${kIconsPath}eye_close.svg');
  static const AppIcon search = AppIcon.asset('${kIconsPath}search.svg');
  static const AppIcon appBarChevronLeft = AppIcon.asset(
    '${kIconsPath}app_bar/chevron_left.svg',
  );
}
