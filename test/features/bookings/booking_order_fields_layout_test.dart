import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/core/widgets/job_schedule_section.dart';
import 'package:prokat/core/widgets/ui_kit/inputs/app_dropdown_field.dart';
import 'package:prokat/features/bookings/widgets/booking_order_fields.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/l10n/app_localizations.dart';

void main() {
  for (final locale in ['ru', 'kk', 'en']) {
    testWidgets('long selected tariff remains readable at 320px/2x in $locale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      const description =
          'Подъём и перемещение строительных материалов, работа на площадке и дополнительные условия тарифа владельца';
      final price = PriceEntry(
        id: 'qa-price',
        label: description,
        price: 30000,
        priceRate: const PriceRateOption(value: 'PER_HOUR', label: 'час'),
      );
      var submits = 0;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ProkatFlowPalette.light.themeFor(AppTheme.lightTheme),
            locale: Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ProkatFlowScope(
              palette: ProkatFlowPalette.light,
              child: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: BookingOrderFields(
                        isEquipmentGroup: false,
                        address: null,
                        openAddressSheet: () async => null,
                        onAddressChanged: (_) {},
                        prices: [price],
                        selectedPrice: price,
                        onPriceChanged: (_) {},
                        scheduleMode: JobScheduleMode.asap,
                        selectedDate: null,
                        selectedTime: null,
                        locale: locale,
                        onScheduled: () {},
                        onAsap: () {},
                        onPickDate: () async {},
                        onPickTime: () async {},
                        commentController: controller,
                        canSubmit: false,
                        submitting: false,
                        onSubmit: () => submits++,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final descriptionFinder = find.text(description);
      expect(descriptionFinder, findsOneWidget);
      final descriptionText = tester.widget<Text>(descriptionFinder);
      expect(descriptionText.maxLines, isNull);
      final selected = tester.widget<AppDropdownField<PriceEntry>>(
        find.byType(AppDropdownField<PriceEntry>),
      );
      expect(selected.value, same(price));
      expect(selected.selectedLabel, contains('30 000'));
      expect(selected.selectedLabel, isNot(contains(description)));
      expect(submits, 0);
      expect(tester.takeException(), isNull);
    });
  }
}
