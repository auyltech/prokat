import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/user/widgets/profile_image_picker.dart';
import 'package:prokat/l10n/app_localizations.dart';

void main() {
  for (final radius in [35.0, 80.0]) {
    testWidgets('empty profile icon stays centered at radius $radius', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ru'),
            home: Scaffold(
              body: ProfileImagePicker(
                mode: AppMode.clientMode,
                radius: radius,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final avatar = tester.getCenter(find.byType(CircleAvatar));
      final icon = tester.getCenter(find.byIcon(Icons.person));
      expect(icon.dx, closeTo(avatar.dx, 0.01));
      expect(icon.dy, closeTo(avatar.dy, 0.01));
      await tester.tap(find.byType(ProfileImagePicker));
      await tester.pumpAndSettle();
      expect(find.text('Удалить фото'), findsNothing);
    });
  }
}
