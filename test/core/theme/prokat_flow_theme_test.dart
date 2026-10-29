import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/theme/app_fonts.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';

void main() {
  for (final dark in [false, true]) {
    test(
      'Flow shares inherited typography and preserves semantic theme, dark $dark',
      () {
        final base = ThemeData(
          brightness: dark ? Brightness.dark : Brightness.light,
        );
        final palette = dark ? ProkatFlowPalette.dark : ProkatFlowPalette.light;
        final refreshed = palette.themeFor(base);
        expect(
          refreshed.textTheme.bodyMedium?.fontFamily,
          AppFonts.manropeFamily,
        );
        expect(
          refreshed.textTheme.titleLarge?.fontFamily,
          AppFonts.manropeFamily,
        );
        expect(refreshed.textTheme.bodyMedium?.color, palette.title);
        expect(refreshed.colorScheme.primary, palette.filledPrimary);
        expect(refreshed.colorScheme.onPrimary, Colors.white);
        expect(refreshed.scaffoldBackgroundColor, palette.background);
        expect(refreshed.colorScheme.error, base.colorScheme.error);
        expect(refreshed.colorScheme.brightness, base.colorScheme.brightness);
        expect(
          base.textTheme.bodyMedium?.fontFamily,
          isNot(AppFonts.manropeFamily),
        );
      },
    );
  }
}
