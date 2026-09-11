import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/theme/app_fonts.dart';
import 'package:prokat/core/theme/app_icons.dart';
import 'package:prokat/core/theme/colors/app_colors_theme.dart';
import 'package:prokat/core/theme/extensions/app_theme_getter.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_elevated_button.dart';
import 'package:prokat/core/widgets/ui_kit/inputs/app_dropdown_field.dart';
import 'package:prokat/core/widgets/ui_kit/inputs/app_text_field.dart';
import 'package:prokat/core/widgets/ui_kit/sheets/app_bottom_sheet.dart';

Widget _wrap(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? AppTheme.lightTheme,
    home: Scaffold(body: child),
  );
}

void main() {
  test('legacy ThemeData registers AppColorsTheme extensions', () {
    expect(
      AppTheme.lightTheme.extension<AppColorsTheme>(),
      isA<LightColorTheme>(),
    );
    expect(
      AppTheme.darkTheme.extension<AppColorsTheme>(),
      isA<DarkColorTheme>(),
    );
  });

  testWidgets('context.colors resolves from ThemeData.extensions', (
    tester,
  ) async {
    late AppColorsTheme colors;
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            colors = context.colors;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(colors.text.main, isNotNull);
  });

  testWidgets('AppFonts body14 color follows light vs dark theme', (
    tester,
  ) async {
    late Color lightColor;
    late Color darkColor;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) {
            lightColor = AppFonts.body14(context).color!;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(
      lightColor,
      AppTheme.lightTheme.extension<AppColorsTheme>()!.text.main,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: Builder(
          builder: (context) {
            darkColor = AppFonts.body14(context).color!;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      darkColor,
      AppTheme.darkTheme.extension<AppColorsTheme>()!.text.main,
    );
    expect(lightColor, isNot(equals(darkColor)));
  });

  testWidgets('AppElevatedButton enabled / loading / disabled', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(AppElevatedButton(title: 'Go', onTap: () => taps++)),
    );
    await tester.tap(find.text('Go'));
    expect(taps, 1);

    await tester.pumpWidget(
      _wrap(
        AppElevatedButton(title: 'Go', onTap: () => taps++, isLoading: true),
      ),
    );
    await tester.tap(find.byType(AppElevatedButton));
    expect(taps, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpWidget(
      _wrap(const AppElevatedButton(title: 'Go', onTap: null)),
    );
    await tester.tap(find.byType(AppElevatedButton));
    expect(taps, 1);
  });

  testWidgets('AppTextField controller, onChanged, obscure', (tester) async {
    final controller = TextEditingController();
    var changed = '';
    await tester.pumpWidget(
      _wrap(
        AppTextField(
          controller: controller,
          hint: 'hint',
          obscure: true,
          onChanged: (v) => changed = v,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'secret');
    expect(controller.text, 'secret');
    expect(changed, 'secret');
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('AppBottomSheet.show pumps without throw', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                await AppBottomSheet.show<void>(
                  context,
                  title: 'Sheet',
                  contentBuilder: (_) => const Text('body'),
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Sheet'), findsOneWidget);
    expect(find.text('body'), findsOneWidget);
  });

  testWidgets('AppDropdownField selects option via sheet', (tester) async {
    String? value;
    await tester.pumpWidget(
      _wrap(
        StatefulBuilder(
          builder: (context, setState) {
            return AppDropdownField<String>(
              sheetTitle: 'Pick',
              value: value,
              options: const [
                DropdownOption(label: 'One', value: '1'),
                DropdownOption(label: 'Two', value: '2'),
              ],
              onChanged: (v) => setState(() => value = v),
            );
          },
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Two'));
    await tester.pumpAndSettle();
    expect(value, '2');
  });

  testWidgets('AppIcons.check builds', (tester) async {
    await tester.pumpWidget(_wrap(AppIcons.check.call(size: 16)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('theme mode switch with ui_kit child does not throw', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        AppElevatedButton(title: 'A', onTap: () {}),
        theme: AppTheme.lightTheme,
      ),
    );
    await tester.pumpWidget(
      _wrap(
        AppElevatedButton(title: 'A', onTap: () {}),
        theme: AppTheme.darkTheme,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
