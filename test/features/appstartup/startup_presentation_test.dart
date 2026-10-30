import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/appstartup/widgets/startup_presentation.dart';

void main() {
  testWidgets(
    'fast startup warms destination under logo then reveals it once',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: StartupPresentation(
            loading: false,
            splash: const ColoredBox(color: Colors.blue, child: Text('logo')),
            child: TextButton(
              onPressed: () => taps++,
              child: const Text('destination'),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.text('logo'), findsOneWidget);
      expect(find.text('destination'), findsOneWidget);
      await tester.tap(find.text('destination'), warnIfMissed: false);
      expect(taps, 0);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await tester.pump(StartupPresentation.transitionDuration);
      await tester.pumpAndSettle();
      expect(find.text('logo'), findsNothing);
      await tester.tap(find.text('destination'));
      expect(taps, 1);
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('logo'), findsNothing);
    },
  );
  testWidgets(
    'slow startup reveals as soon as ready without another two seconds',
    (tester) async {
      Widget frame(bool loading) => MaterialApp(
        home: StartupPresentation(
          loading: loading,
          splash: const Text('logo'),
          child: const Text('destination'),
        ),
      );
      await tester.pumpWidget(frame(true));
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('logo'), findsOneWidget);
      expect(find.text('destination'), findsNothing);
      await tester.pumpWidget(frame(false));
      await tester.pump();
      await tester.pump(StartupPresentation.transitionDuration);
      await tester.pumpAndSettle();
      expect(find.text('logo'), findsNothing);
      expect(find.text('destination'), findsOneWidget);
    },
  );
}
