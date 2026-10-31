import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/theme/colors/app_colors_theme.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_icon_button.dart';

void main() {
  Future<void> pumpButtons(
    WidgetTester tester, {
    required ThemeData theme,
    ProkatFlowPalette? flow,
  }) async {
    final buttons = Scaffold(
      body: Wrap(
        children: [
          for (final tone in AppIconButtonTone.values)
            for (final variant in [
              AppIconButtonVariant.filled,
              AppIconButtonVariant.outlined,
              AppIconButtonVariant.soft,
            ])
              AppIconButton(
                key: ValueKey('${tone.name}-${variant.name}'),
                icon: Icons.check,
                tone: tone,
                variant: variant,
                onTap: () {},
              ),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: flow == null
            ? buttons
            : ProkatFlowScope(palette: flow, child: buttons),
      ),
    );
    await tester.pump();
  }

  void expectColors(
    WidgetTester tester,
    AppIconButtonTone tone,
    AppIconButtonVariant variant, {
    required Color content,
    required Color background,
    Color? border,
  }) {
    final button = find.byKey(ValueKey('${tone.name}-${variant.name}'));
    final material = tester.widget<Material>(
      find.descendant(of: button, matching: find.byType(Material)),
    );
    final icon = tester.widget<Icon>(
      find.descendant(of: button, matching: find.byIcon(Icons.check)),
    );
    expect(icon.color, content);
    expect(material.color, background);
    if (border != null) {
      expect((material.shape! as CircleBorder).side.color, border);
    }
  }

  for (final dark in [false, true]) {
    final theme = dark ? AppTheme.darkTheme : AppTheme.lightTheme;
    final flow = dark ? ProkatFlowPalette.dark : ProkatFlowPalette.light;

    testWidgets('Flow icon controls use shared contrast colours, dark $dark', (
      tester,
    ) async {
      await pumpButtons(tester, theme: theme, flow: flow);
      expectColors(
        tester,
        AppIconButtonTone.primary,
        AppIconButtonVariant.filled,
        content: Colors.white,
        background: flow.filledPrimary,
      );
      expectColors(
        tester,
        AppIconButtonTone.primary,
        AppIconButtonVariant.outlined,
        content: flow.primary,
        background: Colors.transparent,
        border: flow.primary,
      );
      expectColors(
        tester,
        AppIconButtonTone.primary,
        AppIconButtonVariant.soft,
        content: flow.primary,
        background: flow.primarySoft,
      );
      expectColors(
        tester,
        AppIconButtonTone.neutral,
        AppIconButtonVariant.filled,
        content: flow.title,
        background: flow.surface,
      );
      expectColors(
        tester,
        AppIconButtonTone.neutral,
        AppIconButtonVariant.outlined,
        content: flow.secondary,
        background: Colors.transparent,
        border: flow.border,
      );
      expectColors(
        tester,
        AppIconButtonTone.success,
        AppIconButtonVariant.filled,
        content: Colors.white,
        background: ProkatFlowPalette.light.success,
      );
      expectColors(
        tester,
        AppIconButtonTone.success,
        AppIconButtonVariant.outlined,
        content: flow.success,
        background: Colors.transparent,
        border: flow.success,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('unscoped icon colours remain unchanged, dark $dark', (
      tester,
    ) async {
      await pumpButtons(tester, theme: theme);
      final base = theme.extension<AppColorsTheme>()!.iconButton;
      for (final entry in {
        AppIconButtonTone.neutral: base.neutral,
        AppIconButtonTone.primary: base.primary,
        AppIconButtonTone.success: base.success,
        AppIconButtonTone.warning: base.warning,
        AppIconButtonTone.destructive: base.destructive,
        AppIconButtonTone.inverse: base.inverse,
      }.entries) {
        expectColors(
          tester,
          entry.key,
          AppIconButtonVariant.filled,
          content: entry.value.contentOnFill,
          background: entry.value.fill,
        );
        expectColors(
          tester,
          entry.key,
          AppIconButtonVariant.outlined,
          content: entry.value.content,
          background: Colors.transparent,
          border: entry.value.border,
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Flow preserves warning, destructive and inverse colours, dark $dark',
      (tester) async {
        await pumpButtons(tester, theme: theme, flow: flow);
        final base = theme.extension<AppColorsTheme>()!.iconButton;
        for (final entry in {
          AppIconButtonTone.warning: base.warning,
          AppIconButtonTone.destructive: base.destructive,
          AppIconButtonTone.inverse: base.inverse,
        }.entries) {
          expectColors(
            tester,
            entry.key,
            AppIconButtonVariant.filled,
            content: entry.value.contentOnFill,
            background: entry.value.fill,
          );
          expectColors(
            tester,
            entry.key,
            AppIconButtonVariant.outlined,
            content: entry.value.content,
            background: Colors.transparent,
            border: entry.value.border,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
