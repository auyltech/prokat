import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/widgets/job_schedule_section.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/l10n/app_localizations.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('date picker uses AppBottomSheet and standard action buttons', (
    tester,
  ) async {
    DateTime? result;
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showJobDatePicker(context: context, current: null);
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(AppBottomSheetFrame), findsOneWidget);
    expect(find.byType(AppOutlinedButton), findsOneWidget);
    expect(find.byType(AppElevatedButton), findsOneWidget);
    expect(find.byType(AppLabelButton), findsNothing);

    final cancelButton = find.widgetWithText(AppOutlinedButton, 'Cancel');
    await tester.ensureVisible(cancelButton);
    await tester.tap(cancelButton);
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('time picker returns the draft from the elevated action', (
    tester,
  ) async {
    final date = DateTime.now().add(const Duration(days: 2));
    final current = DateTime(date.year, date.month, date.day, 10, 20);
    DateTime? result;

    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showJobTimePicker(
                context: context,
                date: date,
                current: current,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(AppBottomSheetFrame), findsOneWidget);
    expect(find.byType(CupertinoDatePicker), findsOneWidget);
    expect(find.byType(AppOutlinedButton), findsOneWidget);
    expect(find.byType(AppElevatedButton), findsOneWidget);

    await tester.tap(find.widgetWithText(AppElevatedButton, 'OK'));
    await tester.pumpAndSettle();
    expect(result, current);
  });
}
