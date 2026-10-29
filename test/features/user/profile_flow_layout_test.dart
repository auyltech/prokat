import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/features/owner/models/owner_profile_model.dart';
import 'package:prokat/features/owner/models/owner_status.dart';
import 'package:prokat/features/owner/widgets/owner_profile_header.dart';
import 'package:prokat/features/user/models/user_profile_model.dart';
import 'package:prokat/features/user/state/client_profile_notifier.dart';
import 'package:prokat/features/user/state/client_profile_provider.dart';
import 'package:prokat/features/user/widgets/client_profile_header.dart';
import 'package:prokat/features/user/widgets/display_name.dart';
import 'package:prokat/features/user/widgets/owner_stat_card.dart';
import 'package:prokat/features/user/widgets/profile_image_picker.dart';
import 'package:prokat/l10n/app_localizations.dart';

const _name = 'Кирилл с длинным именем и фамилией для проверки экрана';
final _client = UserProfileModel(
  firstName: _name,
  ratingAverage: 5,
  orderCount: 128,
);
final _owner = OwnerProfileModel(
  firstName: _name,
  ratingAverage: 5,
  orderCount: 128,
  onlineStatus: OwnerStatus.offline,
);

class _ClientProfile extends ClientProfileNotifier {
  @override
  Future<UserProfileModel?> build() async => _client;
}

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    bool dark = false,
    bool flow = true,
    double width = 320,
  }) async {
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final palette = dark ? ProkatFlowPalette.dark : ProkatFlowPalette.light;
    final base = dark ? AppTheme.darkTheme : AppTheme.lightTheme;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [clientProfileProvider.overrideWith(_ClientProfile.new)],
        child: MaterialApp(
          theme: flow ? palette.themeFor(base) : base,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, app) => ProkatFlowScope(
            palette: palette,
            enabled: flow,
            child: MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: app!,
            ),
          ),
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void readable(WidgetTester tester, String text) {
    final finder = find.text(text);
    expect(finder, findsOneWidget);
    final paragraph = tester.renderObject<RenderParagraph>(finder);
    expect(paragraph.didExceedMaxLines, isFalse);
    final rect = tester.getRect(finder);
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(320));
  }

  for (final dark in [false, true]) {
    testWidgets(
      'client profile header grows for long names at 320px/2x, dark $dark',
      (tester) async {
        await pump(
          tester,
          ClientProfileHeader(userProfile: _client),
          dark: dark,
        );
        expect(tester.takeException(), isNull);
        readable(tester, _name);
        final nameTap = tester.widget<GestureDetector>(
          find.descendant(
            of: find.byType(DisplayName),
            matching: find.byType(GestureDetector),
          ),
        );
        expect(nameTap.onTap, isNotNull);
        expect(
          tester
              .widget<ProfileImagePicker>(find.byType(ProfileImagePicker))
              .showEditIcon,
          isTrue,
        );
        final l10n = AppLocalizations.of(
          tester.element(find.byType(ClientProfileHeader)),
        )!;
        readable(tester, '- ${l10n.ordersCount(128)}');
      },
    );

    testWidgets(
      'owner profile header preserves avatar callbacks at 320px/2x, dark $dark',
      (tester) async {
        Future<void> upload(File _) async {}
        Future<void> remove() async {}
        await pump(
          tester,
          OwnerProfileHeader(
            ownerProfile: _owner,
            onAvatarUpload: upload,
            onAvatarDelete: remove,
          ),
          dark: dark,
        );
        expect(tester.takeException(), isNull);
        readable(tester, _name);
        final picker = tester.widget<ProfileImagePicker>(
          find.byType(ProfileImagePicker),
        );
        expect(picker.onUpload, same(upload));
        expect(picker.onDelete, same(remove));
        expect(picker.showEditIcon, isTrue);
      },
    );

    testWidgets(
      'owner stat cards keep real values readable and tappable at 320px/2x, dark $dark',
      (tester) async {
        var opened = 0;
        await pump(
          tester,
          Padding(
            padding: const EdgeInsets.all(16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: OwnerStatCard(
                      icon: Icons.local_shipping,
                      title: 'Техника',
                      firstLabel: 'Всего',
                      firstValue: '1234',
                      secondLabel: 'Онлайн',
                      secondValue: '87',
                      onTap: () => opened++,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: OwnerStatCard(
                      icon: Icons.receipt_long,
                      title: 'Заказы',
                      firstLabel: 'Активные',
                      firstValue: '12',
                      secondLabel: 'Завершено',
                      secondValue: '345',
                    ),
                  ),
                ],
              ),
            ),
          ),
          dark: dark,
        );
        expect(tester.takeException(), isNull);
        for (final label in [
          'Техника',
          'Заказы',
          'Всего',
          'Онлайн',
          'Активные',
          'Завершено',
          '1234',
          '87',
          '12',
          '345',
        ]) {
          readable(tester, label);
        }
        final palette = dark ? ProkatFlowPalette.dark : ProkatFlowPalette.light;
        expect(
          tester.widget<Text>(find.text('1234')).style?.color,
          palette.title,
        );
        await tester.tap(find.text('Техника'));
        expect(opened, 1);
      },
    );
  }

  testWidgets('owner header keeps custom gradient outside Flow', (
    tester,
  ) async {
    const custom = [Colors.pink, Colors.deepPurple];
    await pump(
      tester,
      SizedBox(
        height: 600,
        child: OwnerProfileHeader(
          ownerProfile: _owner,
          gradientColors: custom,
          showRating: false,
        ),
      ),
      flow: false,
      width: 800,
    );
    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(OwnerProfileHeader),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(
      ((container.decoration! as BoxDecoration).gradient! as LinearGradient)
          .colors,
      custom,
    );
    expect(find.text('5.0'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
