import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/companies/company_accent_border.dart';

void main() {
  testWidgets('company animation continues and stops in background', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CompanyAccentBorder(child: SizedBox(width: 360, height: 180)),
      ),
    );
    await tester.pump(const Duration(seconds: 4));
    expect(tester.takeException(), isNull);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('company border respects reduced motion', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: CompanyAccentBorder(child: SizedBox(width: 360, height: 180)),
        ),
      ),
    );
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });
}
