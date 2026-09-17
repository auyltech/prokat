import 'package:flutter/material.dart';
import 'package:prokat/core/theme/colors/app_colors.dart';
import 'package:prokat/core/theme/colors/app_colors_theme.dart';
import 'package:prokat/core/theme/colors/component_themes/component_themes.dart';

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
  AppIconButtonTheme get iconButton => AppIconButtonTheme(
    neutral: const AppButtonToneTheme(
      content: AppColorsDark.textPrimary,
      contentOnFill: AppColorsDark.textPrimary,
      fill: AppColorsDark.surfaceElevated,
      softFill: AppColorsDark.surface,
      border: AppColorsDark.border,
    ),
    primary: const AppButtonToneTheme(
      content: AppColorsDark.primaryInteractive,
      contentOnFill: AppColorsDark.white,
      fill: AppColorsDark.primaryInteractive,
      softFill: AppColorsDark.primarySoft,
      border: AppColorsDark.primaryInteractive,
    ),
    success: const AppButtonToneTheme(
      content: AppColorsDark.success,
      contentOnFill: AppColorsDark.background,
      fill: AppColorsDark.success,
      softFill: AppColorsDark.successSoft,
      border: AppColorsDark.success,
    ),
    warning: const AppButtonToneTheme(
      content: AppColorsDark.warning,
      contentOnFill: AppColorsDark.background,
      fill: AppColorsDark.amber,
      softFill: AppColorsDark.warningSoft,
      border: AppColorsDark.warning,
    ),
    destructive: const AppButtonToneTheme(
      content: AppColorsDark.danger,
      contentOnFill: AppColorsDark.white,
      fill: AppColors.danger,
      softFill: AppColorsDark.dangerSoft,
      border: AppColorsDark.danger,
    ),
    inverse: AppButtonToneTheme(
      content: AppColorsDark.white,
      contentOnFill: AppColors.primary,
      fill: AppColorsDark.white,
      softFill: AppColorsDark.black.withValues(alpha: 0.5),
      border: AppColorsDark.white.withValues(alpha: 0.6),
    ),
    contentDisabled: AppColorsDark.textDisabled,
    backgroundDisabled: AppColorsDark.surface,
    borderDisabled: AppColorsDark.textDisabled,
  );

  @override
  AppLabelButtonTheme get labelButton => AppLabelButtonTheme(
    neutral: iconButton.neutral,
    primary: iconButton.primary,
    success: iconButton.success,
    destructive: iconButton.destructive,
    inverse: iconButton.inverse,
    contentDisabled: AppColorsDark.textDisabled,
    backgroundDisabled: AppColorsDark.surface,
    borderDisabled: AppColorsDark.textDisabled,
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
    borderDestructive: AppColorsDark.danger,
    borderDisabled: AppColorsDark.textDisabled,
    content: AppColorsDark.white,
    contentDestructive: AppColorsDark.danger,
    contentDisabled: AppColorsDark.textDisabled,
    background: Colors.transparent,
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

  @override
  AppToastTheme get toast => const AppToastTheme(
    info: AppColorsDark.bubbleHim,
    success: AppColors.success,
    error: AppColors.danger,
    content: AppColorsDark.white,
  );
}
