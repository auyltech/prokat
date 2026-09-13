import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/widgets/overlay_badge_icon.dart';
import 'package:prokat/core/widgets/profile_accent_cta.dart';
import 'package:prokat/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpCta(WidgetTester tester, Widget cta) {
    return tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: cta),
      ),
    );
  }

  testWidgets('role CTAs share accent layout and copy', (tester) async {
    await pumpCta(
      tester,
      Column(
        children: [
          ProfileAccentCta(
            leading: ProfileAccentCta.truck(),
            title: 'Моя техника и заказы',
            subtitle: 'Управляйте техникой, заказами и доходом',
            onTap: () {},
          ),
          ProfileAccentCta(
            leading: ProfileAccentCta.truckPlus(),
            title: 'Начать сдавать технику',
            subtitle: 'Размещайте технику и получайте заказы',
            onTap: () {},
          ),
          ProfileAccentCta(
            leading: ProfileAccentCta.truckSearch(),
            title: 'Найти технику',
            subtitle: 'Смотрите предложения владельцев',
            onTap: () {},
          ),
        ],
      ),
    );

    final cards = tester.widgetList<Container>(
      find.descendant(
        of: find.byType(ProfileAccentCta),
        matching: find.byType(Container),
      ),
    );

    final paddings = cards
        .map((card) => card.padding)
        .whereType<EdgeInsets>()
        .where(
          (padding) =>
              padding.vertical == ProfileAccentCta.verticalPadding * 2 &&
              padding.horizontal == ProfileAccentCta.horizontalPadding * 2,
        )
        .toList();

    expect(paddings, hasLength(3));
    expect(
      cards
          .where((card) => card.decoration is BoxDecoration)
          .map((card) => (card.decoration as BoxDecoration).color)
          .where((color) => color == AppTheme.accent)
          .length,
      3,
    );

    expect(find.byType(OverlayBadgeIcon), findsNWidgets(2));
    final badges = tester.widgetList<OverlayBadgeIcon>(
      find.byType(OverlayBadgeIcon),
    );
    expect(
      badges.every((badge) => badge.badgeBackground == Colors.white),
      isTrue,
    );
  });
}
