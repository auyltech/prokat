import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';

void main() {
  for (final scrollable in [false, true]) {
    testWidgets(
      'root overlay retains caller appearance and result ($scrollable)',
      (tester) async {
        String? result;
        const flow = ProkatFlowPalette.dark;
        Widget content(BuildContext context) {
          expect(ProkatFlowScope.maybeOf(context), same(flow));
          expect(Theme.of(context).brightness, Brightness.dark);
          return TextButton(
            onPressed: () => Navigator.of(context).pop('selected'),
            child: const Text('choose'),
          );
        }

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: ProkatFlowScope(
              palette: flow,
              child: Theme(
                data: flow.themeFor(AppTheme.darkTheme),
                child: Scaffold(
                  body: Builder(
                    builder: (context) => TextButton(
                      onPressed: () async {
                        result = scrollable
                            ? await AppBottomSheet.showScrollable<String>(
                                context,
                                title: 'Picker',
                                headerBuilder: (_) => const SizedBox.shrink(),
                                scrollableListBuilder: (context, controller) =>
                                    ListView(
                                      controller: controller,
                                      children: [content(context)],
                                    ),
                                footerBuilder: (_) => const SizedBox.shrink(),
                              )
                            : await AppBottomSheet.show<String>(
                                context,
                                title: 'Picker',
                                contentBuilder: content,
                              );
                      },
                      child: const Text('open'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(find.text('Picker'), findsOneWidget);
        await tester.tap(find.text('choose'));
        await tester.pumpAndSettle();
        expect(result, 'selected');
        expect(find.text('open'), findsOneWidget);
        expect(find.text('Picker'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
