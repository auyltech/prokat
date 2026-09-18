import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/utils/kz_phone_mask.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/l10n/app_localizations.dart';

void main() {
  testWidgets('phone field keeps +7, applies mask, and blocks extra digits', (
    tester,
  ) async {
    final controller = TextEditingController(
      text: kzPhoneEditingValue(null).text,
    );
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: Scaffold(
          body: Form(
            key: formKey,
            child: AppKzPhoneField(
              controller: controller,
              title: 'Телефон',
              hint: 'hint',
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), '');
    await tester.pump();
    expect(controller.text, '+7');
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Введите корректный номер телефона'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '+77051111111999');
    await tester.pump();
    expect(controller.text, '+7(705)111-11-11');
    expect(formKey.currentState!.validate(), isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}
