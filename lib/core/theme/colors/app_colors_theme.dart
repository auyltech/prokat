import 'package:flutter/material.dart';
import 'package:prokat/core/theme/colors/app_colors.dart';
import 'package:prokat/core/theme/colors/app_component_themes.dart';

abstract class AppColorsTheme extends ThemeExtension<AppColorsTheme> {
  const AppColorsTheme();

  Color get barrierColor;
  double get barrierBlurSigma;
  List<BoxShadow> get dialogShadows;

  AppBackgroundTheme get background;
  AppTextColors get text;
  AppBorderTheme get borders;
  AppIconsTheme get icons;
  AppElevatedButtonTheme get elevatedButton;
  AppOutlinedButtonTheme get outlinedButton;
  AppTextButtonTheme get textButton;
  AppTextFieldTheme get textField;
  AppSelectionTheme get selection;
  AppSwitchTheme get appSwitch;
  AppRadioTheme get radio;

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

class LightColorTheme extends AppColorsTheme {
  const LightColorTheme();

  @override
  Color get primary => AppColors.primary;

  @override
  Color get amber => AppColors.amber;

  @override
  Color get peach => AppColors.peach;

  @override
  Color get barrierColor => AppColors.black.withValues(alpha: 0.4);

  @override
  double get barrierBlurSigma => 3;

  @override
  List<BoxShadow> get dialogShadows => [
    BoxShadow(
      offset: const Offset(0, 8),
      blurRadius: 16,
      color: AppColors.black.withValues(alpha: 0.12),
    ),
    BoxShadow(
      offset: const Offset(0, 16),
      blurRadius: 32,
      color: AppColors.black.withValues(alpha: 0.08),
    ),
  ];

  @override
  AppBackgroundTheme get background => const AppBackgroundTheme(
    main: AppColors.background,
    secondaryCard: AppColors.surface,
    elevated: AppColors.surfaceElevated,
    primarySoft: AppColors.primarySoft,
    peachSoft: AppColors.peach,
    amberSoft: AppColors.peach,
    hover: AppColors.primarySoft,
    pressed: Color(0xFFB3D4EF),
    successSoft: AppColors.successSoft,
    dangerSoft: AppColors.dangerSoft,
    warningSoft: AppColors.warningSoft,
  );

  @override
  AppTextColors get text => const AppTextColors(
    main: AppColors.textPrimary,
    secondary: AppColors.textSecondary,
    tertiary: AppColors.textTertiary,
    disabled: AppColors.textDisabled,
    primary: AppColors.primary,
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.danger,
    white: AppColors.white,
  );

  @override
  AppBorderTheme get borders => const AppBorderTheme(
    main: AppColors.border,
    active: AppColors.primary,
    error: AppColors.danger,
  );

  @override
  AppIconsTheme get icons => const AppIconsTheme(
    main: AppColors.textPrimary,
    primary: AppColors.primary,
    success: AppColors.success,
    disabled: AppColors.textDisabled,
    white: AppColors.white,
  );

  @override
  AppElevatedButtonTheme get elevatedButton => const AppElevatedButtonTheme(
    background: AppColors.primary,
    content: AppColors.white,
    contentDisabled: AppColors.white,
    destructiveBackground: AppColors.danger,
  );

  @override
  AppOutlinedButtonTheme get outlinedButton => const AppOutlinedButtonTheme(
    border: AppColors.primary,
    borderDisabled: AppColors.textDisabled,
    content: AppColors.primary,
    contentDisabled: AppColors.textDisabled,
    background: AppColors.white,
  );

  @override
  AppTextButtonTheme get textButton => const AppTextButtonTheme(
    content: AppColors.primary,
    contentDestructive: AppColors.danger,
    contentDisabled: AppColors.textDisabled,
  );

  @override
  AppTextFieldTheme get textField => const AppTextFieldTheme(
    background: AppColors.surface,
    backgroundDisabled: Color(0xFFF5F5F5),
    backgroundFocused: AppColors.surface,
    border: AppColors.border,
    borderFocused: AppColors.primary,
    borderError: AppColors.danger,
    focusHalo: AppColors.inputFocusHalo,
    focusGradient: LinearGradient(
      colors: <Color>[AppColors.primary, AppColors.primary],
    ),
    text: AppColors.textPrimary,
    textDisabled: AppColors.textDisabled,
    hint: AppColors.textTertiary,
    label: AppColors.textSecondary,
    caption: AppColors.textSecondary,
    cursor: AppColors.primary,
  );

  @override
  AppSelectionTheme get selection => const AppSelectionTheme(
    fillSelected: AppColors.primary,
    fillUnselected: AppColors.white,
    border: AppColors.border,
    borderError: AppColors.danger,
    iconOnFill: AppColors.white,
    uncheckedShadows: <BoxShadow>[
      BoxShadow(
        offset: Offset(0, 1),
        blurRadius: 2,
        color: AppColors.switchThumbShadow,
      ),
    ],
  );

  @override
  AppSwitchTheme get appSwitch => const AppSwitchTheme(
    trackOn: AppColors.primary,
    trackOff: AppColors.peach,
    thumb: AppColors.white,
    thumbShadows: <BoxShadow>[
      BoxShadow(
        offset: Offset(0, 1),
        blurRadius: 2,
        color: AppColors.switchThumbShadow,
      ),
    ],
  );

  @override
  AppRadioTheme get radio => const AppRadioTheme(
    enabled: AppColors.primary,
    disabled: AppColors.textDisabled,
  );
}

class DarkColorTheme extends AppColorsTheme {
  const DarkColorTheme();

  @override
  Color get primary => AppColorsDark.primary;

  @override
  Color get amber => AppColorsDark.amber;

  @override
  Color get peach => AppColorsDark.peachSoft;

  @override
  Color get barrierColor => AppColorsDark.black.withValues(alpha: 0.5);

  @override
  double get barrierBlurSigma => 3;

  @override
  List<BoxShadow> get dialogShadows => [
    BoxShadow(
      offset: const Offset(0, 8),
      blurRadius: 16,
      color: AppColorsDark.black.withValues(alpha: 0.35),
    ),
  ];

  @override
  AppBackgroundTheme get background => const AppBackgroundTheme(
    main: AppColorsDark.background,
    secondaryCard: AppColorsDark.surface,
    elevated: AppColorsDark.surfaceElevated,
    primarySoft: AppColorsDark.primarySoft,
    peachSoft: AppColorsDark.peachSoft,
    amberSoft: AppColorsDark.amberSoft,
    hover: AppColorsDark.primarySoft,
    pressed: Color(0xFF1A2F4A),
    successSoft: AppColorsDark.successSoft,
    dangerSoft: AppColorsDark.dangerSoft,
    warningSoft: AppColorsDark.warningSoft,
  );

  @override
  AppTextColors get text => const AppTextColors(
    main: AppColorsDark.textPrimary,
    secondary: AppColorsDark.textSecondary,
    tertiary: AppColorsDark.textTertiary,
    disabled: AppColorsDark.textDisabled,
    primary: AppColorsDark.primaryInteractive,
    success: AppColorsDark.success,
    warning: AppColorsDark.warning,
    error: AppColorsDark.danger,
    white: AppColorsDark.white,
  );

  @override
  AppBorderTheme get borders => const AppBorderTheme(
    main: AppColorsDark.border,
    active: AppColorsDark.primaryInteractive,
    error: AppColorsDark.danger,
  );

  @override
  AppIconsTheme get icons => const AppIconsTheme(
    main: AppColorsDark.textPrimary,
    primary: AppColorsDark.primaryInteractive,
    success: AppColorsDark.success,
    disabled: AppColorsDark.textDisabled,
    white: AppColorsDark.white,
  );

  @override
  AppElevatedButtonTheme get elevatedButton => const AppElevatedButtonTheme(
    background: AppColorsDark.primaryInteractive,
    content: AppColorsDark.white,
    contentDisabled: AppColorsDark.white,
    destructiveBackground: Color(0xFFC62828),
  );

  @override
  AppOutlinedButtonTheme get outlinedButton => const AppOutlinedButtonTheme(
    border: AppColorsDark.primaryInteractive,
    borderDisabled: AppColorsDark.textDisabled,
    content: AppColorsDark.primaryInteractive,
    contentDisabled: AppColorsDark.textDisabled,
    background: AppColorsDark.surface,
  );

  @override
  AppTextButtonTheme get textButton => const AppTextButtonTheme(
    content: AppColorsDark.primaryInteractive,
    contentDestructive: AppColorsDark.danger,
    contentDisabled: AppColorsDark.textDisabled,
  );

  @override
  AppTextFieldTheme get textField => const AppTextFieldTheme(
    background: AppColorsDark.surface,
    backgroundDisabled: Color(0xFF181B1F),
    backgroundFocused: AppColorsDark.surface,
    border: AppColorsDark.border,
    borderFocused: AppColorsDark.primaryInteractive,
    borderError: AppColorsDark.danger,
    focusHalo: AppColorsDark.inputFocusHalo,
    focusGradient: LinearGradient(
      colors: <Color>[
        AppColorsDark.primaryInteractive,
        AppColorsDark.primaryInteractive,
      ],
    ),
    text: AppColorsDark.textPrimary,
    textDisabled: AppColorsDark.textDisabled,
    hint: AppColorsDark.textTertiary,
    label: AppColorsDark.textSecondary,
    caption: AppColorsDark.textSecondary,
    cursor: AppColorsDark.primaryInteractive,
  );

  @override
  AppSelectionTheme get selection => const AppSelectionTheme(
    fillSelected: AppColorsDark.primaryInteractive,
    fillUnselected: AppColorsDark.surface,
    border: AppColorsDark.border,
    borderError: AppColorsDark.danger,
    iconOnFill: AppColorsDark.white,
    uncheckedShadows: <BoxShadow>[
      BoxShadow(
        offset: Offset(0, 1),
        blurRadius: 2,
        color: AppColorsDark.switchThumbShadow,
      ),
    ],
  );

  @override
  AppSwitchTheme get appSwitch => const AppSwitchTheme(
    trackOn: AppColorsDark.primaryInteractive,
    trackOff: AppColorsDark.peachSoft,
    thumb: AppColorsDark.white,
    thumbShadows: <BoxShadow>[
      BoxShadow(
        offset: Offset(0, 1),
        blurRadius: 2,
        color: AppColorsDark.switchThumbShadow,
      ),
    ],
  );

  @override
  AppRadioTheme get radio => const AppRadioTheme(
    enabled: AppColorsDark.primaryInteractive,
    disabled: AppColorsDark.textDisabled,
  );
}
