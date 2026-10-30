import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/core/widgets/account_status_card.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/core/widgets/empty_state_artwork.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';
import 'package:prokat/features/equipment/state/equipment_service.dart';
import 'package:prokat/features/equipment/widgets/owner/owner_equipment_card.dart';
import 'package:prokat/features/requests/models/request_status.dart';
import 'package:prokat/features/requests/widgets.dart/request_status_badge.dart';
import 'package:prokat/l10n/app_localizations.dart';

class _NoNetwork extends Fake implements EquipmentService {}

Future<void> pumpReview(
  WidgetTester tester,
  Widget child, {
  String locale = 'ru',
  double scale = 1,
}) async {
  tester.view.physicalSize = const Size(320, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [equipmentServiceProvider.overrideWithValue(_NoNetwork())],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProkatFlowPage(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: child,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final locale in ['ru', 'kk', 'en']) {
    testWidgets(
      'request header and confirmation fit a narrow phone ($locale)',
      (tester) async {
        await pumpReview(
          tester,
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Column(
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Text(l10n.newRequest),
                      const RequestStatusBadge(
                        status: RequestStatus.accepted,
                        mode: AppMode.clientMode,
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => AppAlertBottomSheet.show(
                      context,
                      title: l10n.inquiryCloseQuestion,
                      primaryLabel: l10n.inquiryCloseConfirm,
                      secondaryLabel: l10n.cancel,
                    ),
                    child: const Text('open'),
                  ),
                ],
              );
            },
          ),
          locale: locale,
          scale: 2,
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final primary = tester.getSize(find.byType(AppElevatedButton));
        final secondary = tester.getSize(find.byType(AppOutlinedButton));
        expect(primary.width, closeTo(secondary.width, 0.1));
        expect(primary.height, closeTo(secondary.height, 0.1));
      },
    );
  }

  testWidgets(
    'long fleet names stay compact and all visibility switches align',
    (tester) async {
      OwnerEquipmentCard card(String id, String name) => OwnerEquipmentCard(
        showShare: false,
        onOpen: () {},
        equipment: Equipment(
          id: id,
          name: name,
          model: 'Very long machinery model name with many extra words',
          plateNumber: '245 ATB 06',
          status: EquipmentStatus.available,
          isVisible: false,
          prices: [
            PriceEntry.fromJson({
              'id': 'price',
              'price': 60000,
              'priceRate': 'PER_TRIP',
            }),
          ],
        ),
      );
      await pumpReview(
        tester,
        Column(
          children: [
            card('short', 'Кран'),
            const SizedBox(height: 12),
            card('long', 'Автокран с очень длинным названием ' * 5),
          ],
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester
            .getSize(find.byKey(const ValueKey('owner-equipment-flow-short')))
            .height,
        closeTo(
          tester
              .getSize(find.byKey(const ValueKey('owner-equipment-flow-long')))
              .height,
          0.1,
        ),
      );
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(2));
      expect(
        tester.getTopRight(switches.at(0)).dx,
        tester.getTopRight(switches.at(1)).dx,
      );
    },
  );

  testWidgets(
    'offline switch has a distinct thumb and all old empty images use vectors',
    (tester) async {
      await pumpReview(
        tester,
        Column(
          children: [
            AccountStatusCard(
              isOnline: false,
              title: 'Вы офлайн',
              subtitle: 'Не принимаете заказы',
              onChanged: (_) {},
            ),
            for (final name in [
              'empty_bookings.png',
              'empty_chats.png',
              'empty_requests.png',
              'empty_equipment.png',
              'empty_notifications.png',
              'empty_error.png',
              'connection_error.png',
            ])
              EmptyStateTile(imageName: name),
          ],
        ),
      );
      final control = tester.widget<Switch>(find.byType(Switch));
      expect(control.inactiveThumbColor, Colors.white);
      expect(control.inactiveTrackColor, isNot(control.inactiveThumbColor));
      expect(find.byType(EmptyStateArtwork), findsNWidgets(7));
      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
