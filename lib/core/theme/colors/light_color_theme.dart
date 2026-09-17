import 'package:flutter/material.dart';
import 'package:prokat/core/theme/colors/app_colors.dart';
import 'package:prokat/core/theme/colors/app_colors_theme.dart';
import 'package:prokat/core/theme/colors/component_themes/component_themes.dart';

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
  AppIconButtonTheme get iconButton => AppIconButtonTheme(
    neutral: const AppButtonToneTheme(
      content: AppColors.textPrimary,
      contentOnFill: AppColors.textPrimary,
      fill: AppColors.surfaceElevated,
      softFill: AppColors.surface,
      border: AppColors.border,
    ),
    primary: const AppButtonToneTheme(
      content: AppColors.primary,
      contentOnFill: AppColors.white,
      fill: AppColors.primary,
      softFill: AppColors.primarySoft,
      border: AppColors.primary,
    ),
    success: const AppButtonToneTheme(
      content: AppColors.success,
      contentOnFill: AppColors.white,
      fill: AppColors.success,
      softFill: AppColors.successSoft,
      border: AppColors.success,
    ),
    warning: const AppButtonToneTheme(
      content: AppColors.warning,
      contentOnFill: AppColors.textPrimary,
      fill: AppColors.amber,
      softFill: AppColors.warningSoft,
      border: AppColors.warning,
    ),
    destructive: const AppButtonToneTheme(
      content: AppColors.danger,
      contentOnFill: AppColors.white,
      fill: AppColors.danger,
      softFill: AppColors.dangerSoft,
      border: AppColors.danger,
    ),
    inverse: AppButtonToneTheme(
      content: AppColors.white,
      contentOnFill: AppColors.primary,
      fill: AppColors.white,
      softFill: AppColors.black.withValues(alpha: 0.4),
      border: AppColors.white.withValues(alpha: 0.6),
    ),
    contentDisabled: AppColors.textDisabled,
    backgroundDisabled: AppColors.surface,
    borderDisabled: AppColors.textDisabled,
  );

  @override
  AppLabelButtonTheme get labelButton => AppLabelButtonTheme(
    neutral: iconButton.neutral,
    primary: iconButton.primary,
    success: iconButton.success,
    destructive: iconButton.destructive,
    inverse: iconButton.inverse,
    contentDisabled: AppColors.textDisabled,
    backgroundDisabled: AppColors.surface,
    borderDisabled: AppColors.textDisabled,
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
    borderDestructive: AppColors.danger,
    borderDisabled: AppColors.textDisabled,
    content: AppColors.primary,
    contentDestructive: AppColors.danger,
    contentDisabled: AppColors.textDisabled,
    background: Colors.transparent,
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

  @override
  AppToastTheme get toast => const AppToastTheme(
    info: AppColors.textSecondary,
    success: AppColors.success,
    error: AppColors.danger,
    content: AppColors.white,
  );
}
