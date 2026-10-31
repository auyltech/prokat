import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/core/widgets/account_status_card.dart';
import 'package:prokat/core/widgets/ui_kit/cards/app_card.dart';
import 'package:prokat/features/appstatic/widgets/faq_tile.dart';
import 'package:prokat/features/support/data/faq_data.dart';
import 'package:prokat/features/support/data/guides_data.dart';
import 'package:prokat/features/support/models/faq_model.dart';
import 'package:prokat/features/support/models/user_guide.dart';
import 'package:prokat/features/support/widgets/user_guides_section.dart';
import 'package:prokat/features/support/screens/user_guide_screen.dart';
import 'package:prokat/l10n/app_localizations.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('account and help remain usable at 320px/2x, dark=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final flow = dark ? ProkatFlowPalette.dark : ProkatFlowPalette.light;
      var changes = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: flow.themeFor(dark ? AppTheme.darkTheme : AppTheme.lightTheme),
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: ProkatFlowScope(
            palette: flow,
            child: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    AccountStatusCard(
                      isOnline: false,
                      title: 'Вы офлайн',
                      subtitle: 'Не принимаете заказы',
                      explanation: 'Чтобы принимать прямые заявки клиентов, вы должны быть онлайн',
                      onChanged: (_) => changes++,
                    ),
                    FaqTile(faq: faqs.first, currentLocale: 'ru'),
                    UserGuidesSection(
                      guides: [guides.firstWhere((g) => g.isPublished)],
                      currentLocale: 'ru',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(Switch));
      expect(changes, 1);
      final question = find.text(faqs.first.translation('ru').question);
      await tester.ensureVisible(question);
      await tester.tap(question);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final guide = guides.firstWhere((g) => g.isPublished);
      final title = find.text(guide.translation('ru').title);
      await tester.ensureVisible(title);
      await tester.tap(title);
      await tester.pumpAndSettle();
      expect(find.byType(UserGuideScreen), findsOneWidget);
      final context = tester.element(find.byType(UserGuideScreen));
      expect(ProkatFlowScope.maybeOf(context), flow);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('changing card skin retains stateful content', (tester) async {
    var builds = 0;
    Widget app(bool flow) => MaterialApp(
      theme: AppTheme.lightTheme,
      home: ProkatFlowScope(
        palette: ProkatFlowPalette.light,
        enabled: flow,
        child: AppCard(child: _StateProbe(onInit: () => builds++)),
      ),
    );
    await tester.pumpWidget(app(false));
    await tester.pumpWidget(app(true));
    expect(builds, 1);
  });
}

class _StateProbe extends StatefulWidget {
  const _StateProbe({required this.onInit});
  final VoidCallback onInit;
  @override
  State<_StateProbe> createState() => _StateProbeState();
}

class _StateProbeState extends State<_StateProbe> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) => const Text('state preserved');
}
