import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/theme/colors/app_colors.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/reviews/widgets/review_sheet.dart';
import 'package:prokat/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('review sheet uses the UI kit elevated surface in dark mode', (
    tester,
  ) async {
    const surface = Color(0xFF1C1C1E);
    final theme = AppTheme.darkTheme.copyWith(
      colorScheme: const ColorScheme.dark(surface: surface),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: theme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () {
                    unawaited(
                      ReviewSheet.show(
                        context,
                        bookingId: 'booking-1',
                        revieweeId: 'user-1',
                        mode: AppMode.ownerMode,
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Review client'), findsOneWidget);

    expect(find.byType(AppBottomSheetFrame), findsOneWidget);

    final sheetDecoration =
        tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.byType(AppBottomSheetFrame),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration;
    expect(sheetDecoration.color, AppColorsDark.surfaceElevated);
    expect(sheetDecoration.color, isNot(Colors.white));
  });
}
