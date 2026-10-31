import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/features/support/screens/contact_support_screen.dart';
import 'package:prokat/features/support/state/support_provider.dart';
import 'package:prokat/features/support/state/support_service.dart';
import 'package:prokat/features/support/models/contact_inquiry_topic.dart';
import 'package:prokat/features/support/widgets/inquiry_topic_sheet.dart';
import 'package:prokat/l10n/app_localizations.dart';

class _UnusedSupportService implements SupportService {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('No API expected');
}

void main() {
  for (final locale in ['ru', 'kk', 'en']) {
    testWidgets('support form and topic picker fit 320px/2x in $locale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Widget app(Widget child) => ProviderScope(
        overrides: [
          supportApiProvider.overrideWithValue(_UnusedSupportService()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: ProkatFlowPage(builder: (_) => child),
        ),
      );
      await tester.pumpWidget(app(const ContactSupportScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -1500),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        app(
          const Scaffold(
            body: InquiryTopicSheet(selectedTopic: ContactInquiryTopic.general),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
