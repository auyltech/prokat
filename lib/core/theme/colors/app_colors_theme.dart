import 'package:flutter/material.dart';
import 'package:prokat/core/theme/colors/component_themes/component_themes.dart';

export 'package:prokat/core/theme/colors/dark_color_theme.dart';
export 'package:prokat/core/theme/colors/light_color_theme.dart';

abstract class AppColorsTheme extends ThemeExtension<AppColorsTheme> {
  const AppColorsTheme();

  Color get barrierColor;
  double get barrierBlurSigma;
  List<BoxShadow> get dialogShadows;

  AppBackgroundTheme get background;
  AppTextColors get text;
  AppBorderTheme get borders;
  AppIconsTheme get icons;
  AppIconButtonTheme get iconButton;
  AppLabelButtonTheme get labelButton;
  AppElevatedButtonTheme get elevatedButton;
  AppOutlinedButtonTheme get outlinedButton;
  AppTextButtonTheme get textButton;
  AppTextFieldTheme get textField;
  AppSelectionTheme get selection;
  AppSwitchTheme get appSwitch;
  AppRadioTheme get radio;
  AppToastTheme get toast;
  ProkatAppBarTheme get appBar;
  AppNavigationBarTheme get navigationBar;

  /// Brand navy (same hex light/dark). Prefer [elevatedButton.background] for CTAs.
  Color get primary;

  Color get amber;
  Color get peach;

  @override
  ThemeExtension<AppColorsTheme> copyWith() => this;

  @override
  ThemeExtension<AppColorsTheme> lerp(
    covariant ThemeExtension<AppColorsTheme>? other,
    double t,
  ) {
    // Discrete light/dark palettes: snap at midpoint so MaterialApp theme
    // animation does not keep the start extension when t → 1.
    if (other is! AppColorsTheme) return this;
    return t < 0.5 ? this : other;
  }
}
