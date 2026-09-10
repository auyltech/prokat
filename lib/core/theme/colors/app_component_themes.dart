import 'package:flutter/material.dart';

final class AppBackgroundTheme {
  final Color main;
  final Color secondaryCard;
  final Color elevated;
  final Color primarySoft;
  final Color peachSoft;
  final Color amberSoft;
  final Color hover;
  final Color pressed;
  final Color successSoft;
  final Color dangerSoft;
  final Color warningSoft;

  const AppBackgroundTheme({
    required this.main,
    required this.secondaryCard,
    required this.elevated,
    required this.primarySoft,
    required this.peachSoft,
    required this.amberSoft,
    required this.hover,
    required this.pressed,
    required this.successSoft,
    required this.dangerSoft,
    required this.warningSoft,
  });
}

final class AppTextColors {
  final Color main;
  final Color secondary;
  final Color tertiary;
  final Color disabled;
  final Color primary;
  final Color success;
  final Color warning;
  final Color error;
  final Color white;

  const AppTextColors({
    required this.main,
    required this.secondary,
    required this.tertiary,
    required this.disabled,
    required this.primary,
    required this.success,
    required this.warning,
    required this.error,
    required this.white,
  });
}

final class AppBorderTheme {
  final Color main;
  final Color active;
  final Color error;

  const AppBorderTheme({
    required this.main,
    required this.active,
    required this.error,
  });
}

final class AppIconsTheme {
  final Color main;
  final Color primary;
  final Color success;
  final Color disabled;
  final Color white;

  const AppIconsTheme({
    required this.main,
    required this.primary,
    required this.success,
    required this.disabled,
    required this.white,
  });
}

final class AppElevatedButtonTheme {
  final Color background;
  final Color content;
  final Color contentDisabled;
  final Color destructiveBackground;
  final double disabledOpacity;

  const AppElevatedButtonTheme({
    required this.background,
    required this.content,
    required this.contentDisabled,
    required this.destructiveBackground,
    this.disabledOpacity = 0.45,
  });
}

final class AppOutlinedButtonTheme {
  final Color border;
  final Color borderDisabled;
  final Color content;
  final Color contentDisabled;
  final Color background;
  final double disabledOpacity;

  const AppOutlinedButtonTheme({
    required this.border,
    required this.borderDisabled,
    required this.content,
    required this.contentDisabled,
    required this.background,
    this.disabledOpacity = 0.45,
  });
}

final class AppTextButtonTheme {
  final Color content;
  final Color contentDestructive;
  final Color contentDisabled;

  const AppTextButtonTheme({
    required this.content,
    required this.contentDestructive,
    required this.contentDisabled,
  });
}

final class AppTextFieldTheme {
  final Color background;
  final Color backgroundDisabled;
  final Color backgroundFocused;
  final Color border;
  final Color borderFocused;
  final Color borderError;
  final Color focusHalo;
  final LinearGradient focusGradient;
  final Color text;
  final Color textDisabled;
  final Color hint;
  final Color label;
  final Color caption;
  final Color cursor;

  const AppTextFieldTheme({
    required this.background,
    required this.backgroundDisabled,
    required this.backgroundFocused,
    required this.border,
    required this.borderFocused,
    required this.borderError,
    required this.focusHalo,
    required this.focusGradient,
    required this.text,
    required this.textDisabled,
    required this.hint,
    required this.label,
    required this.caption,
    required this.cursor,
  });
}

final class AppSelectionTheme {
  final Color fillSelected;
  final Color fillUnselected;
  final Color border;
  final Color borderError;
  final Color iconOnFill;
  final List<BoxShadow> uncheckedShadows;

  const AppSelectionTheme({
    required this.fillSelected,
    required this.fillUnselected,
    required this.border,
    required this.borderError,
    required this.iconOnFill,
    required this.uncheckedShadows,
  });
}

final class AppSwitchTheme {
  final Color trackOn;
  final Color trackOff;
  final Color thumb;
  final List<BoxShadow> thumbShadows;

  const AppSwitchTheme({
    required this.trackOn,
    required this.trackOff,
    required this.thumb,
    required this.thumbShadows,
  });
}

final class AppRadioTheme {
  final Color enabled;
  final Color disabled;

  const AppRadioTheme({required this.enabled, required this.disabled});
}
