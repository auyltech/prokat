import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/core/utils/kz_plate_mask.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/core/widgets/ui_kit/flow/prokat_flow_actions.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_details_provider.dart';
import 'package:prokat/features/equipment/state/owner_equipment_editor_state.dart';
import 'package:prokat/features/equipment/utils/vacuum_tariffs.dart';
import 'package:prokat/features/equipment/widgets/owner/equipment_editor_section.dart';
import 'package:prokat/features/equipment/widgets/owner/equipment_plate_badge.dart';
import 'package:prokat/features/equipment/widgets/owner/owner_tariff_card.dart';
import 'package:prokat/features/equipment/widgets/owner/registration_section.dart';
import 'package:prokat/l10n/app_localizations.dart';

const _title = 'Основные данные и условия предоставления техники в аренду';
Equipment _equipment(EquipmentStatus status) => Equipment(
  id: 'eq-1',
  name: 'Автокран',
  model: 'Ивановец КС-45717',
  plateNumber: '245 ATB 06',
  status: status,
  isVisible: true,
  prices: const [],
);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool dark = false,
  bool flow = true,
  CatalogGroup group = CatalogGroup.machinery,
  double scale = 2,
}) async {
  tester.view.physicalSize = const Size(320, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final palette = dark ? ProkatFlowPalette.dark : ProkatFlowPalette.light;
  final base = dark ? AppTheme.darkTheme : AppTheme.lightTheme;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ownerEquipmentCatalogGroupProvider('eq-1').overrideWithValue(group),
      ],
      child: MaterialApp(
        theme: flow ? palette.themeFor(base) : base,
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, appChild) => ProkatFlowScope(
          palette: palette,
          enabled: flow,
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: appChild!,
          ),
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final dark in [false, true]) {
    for (final expanded in [false, true]) {
      testWidgets(
        'editor heading stays readable at 320px/2x, expanded $expanded, dark $dark',
        (tester) async {
          var toggles = 0;
          await _pump(
            tester,
            EquipmentEditorSection(
              title: _title,
              indicator: BlockIndicator.valid,
              expanded: expanded,
              onToggleExpanded: () => toggles++,
              saveLabel: 'Сохранить',
              child: const Text('Действующие данные секции'),
            ),
            dark: dark,
          );
          final heading = tester.widget<Text>(find.text(_title));
          expect(heading.maxLines, isNull);
          expect(heading.overflow, TextOverflow.visible);
          expect(
            heading.style?.color,
            dark ? ProkatFlowPalette.dark.title : ProkatFlowPalette.light.title,
          );
          await tester.tap(find.text(_title));
          expect(toggles, 1);
          expect(tester.takeException(), isNull);
        },
      );
    }
    for (final saved in [false, true]) {
      for (final canEdit in [false, true]) {
        testWidgets(
          'tariff keeps its fields at 320px/2x, saved $saved, editable $canEdit, dark $dark',
          (tester) async {
            final draft = TariffDraft(
              id: saved ? 'price-1' : null,
              labelKey: vacuumTariffOther,
              customName: 'Дополнительные работы на строительном объекте',
              price: 1250000,
              priceRate: const PriceRateOption(
                value: 'PER_HOUR',
                label: 'hour',
              ),
              expanded: true,
            );
            await _pump(
              tester,
              OwnerTariffCard(
                draft: draft,
                canEdit: canEdit,
                onChanged: (_) {},
                onDelete: () {},
              ),
              dark: dark,
            );
            // AppDropdownField also renders an AppTextField for its selection.
            // Custom service, price and billing unit are all existing fields.
            expect(find.byType(AppTextField), findsNWidgets(3));
            final l10n = AppLocalizations.of(
              tester.element(find.byType(OwnerTariffCard)),
            )!;
            final fields = tester
                .widgetList<AppTextField>(find.byType(AppTextField))
                .toList();
            expect(
              fields.map((field) => field.title),
              unorderedEquals([
                l10n.customServiceName,
                l10n.priceFieldLabel,
                l10n.billingUnit,
              ]),
            );
            expect(fields.every((field) => field.readOnly == !canEdit), isTrue);
            expect(
              fields
                  .singleWhere((field) => field.title == l10n.priceFieldLabel)
                  .controller
                  .text,
              '1250000',
            );
            expect(
              find.byType(AppDropdownField<PriceRateOption>),
              findsOneWidget,
            );
            expect(find.byType(ChoiceChip), findsNWidgets(2));
            for (final chip in tester.widgetList<ChoiceChip>(
              find.byType(ChoiceChip),
            )) {
              expect(chip.onSelected, canEdit ? isNotNull : isNull);
            }
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets('Flow save button preserves enabled and disabled callbacks', (
    tester,
  ) async {
    var saves = 0;
    Widget section(bool enabled) => EquipmentEditorSection(
      title: _title,
      indicator: BlockIndicator.empty,
      expanded: true,
      onToggleExpanded: () {},
      saveLabel: 'Сохранить',
      showSave: true,
      saveEnabled: enabled,
      onSave: () => saves++,
      child: const Text('Поля формы'),
    );
    await _pump(tester, section(true));
    await tester.ensureVisible(find.byType(ProkatFlowPrimaryButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ProkatFlowPrimaryButton));
    expect(saves, 1);
    await _pump(tester, section(false));
    expect(
      tester
          .widget<ProkatFlowPrimaryButton>(find.byType(ProkatFlowPrimaryButton))
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'price display choice keeps its original draft and commit callback',
    (tester) async {
      TariffDraft? changed;
      var commits = 0;
      final draft = TariffDraft(
        id: 'price-1',
        labelKey: vacuumTariffOther,
        customName: 'Монтаж',
        price: 18000,
        expanded: true,
      );
      await _pump(
        tester,
        OwnerTariffCard(
          draft: draft,
          canEdit: true,
          onChanged: (value) => changed = value,
          onCommit: () => commits++,
        ),
      );
      final from = find.byWidgetPredicate(
        (widget) => widget is ChoiceChip && !widget.selected,
      );
      await tester.ensureVisible(from);
      await tester.pumpAndSettle();
      await tester.tap(from);
      expect(changed?.id, 'price-1');
      expect(changed?.price, 18000);
      expect(changed?.isStartingFrom, isTrue);
      expect(commits, 1);
      expect(tester.takeException(), isNull);
    },
  );

  for (final status in [
    EquipmentStatus.draft,
    EquipmentStatus.rejected,
    EquipmentStatus.created,
    EquipmentStatus.available,
  ]) {
    testWidgets('registration keeps edit permissions for $status', (
      tester,
    ) async {
      await _pump(tester, RegistrationSection(equipment: _equipment(status)));
      final section = tester.widget<EquipmentEditorSection>(
        find.byType(EquipmentEditorSection),
      );
      await tester.tap(find.text(section.title));
      await tester.pumpAndSettle();
      final editable =
          status == EquipmentStatus.draft || status == EquipmentStatus.rejected;
      expect(
        find.byType(EquipmentPlateBadge),
        editable ? findsNothing : findsOneWidget,
      );
      final fields = tester
          .widgetList<AppTextField>(find.byType(AppTextField))
          .toList();
      expect(fields.length, editable ? 2 : 1);
      expect(fields.every((field) => field.readOnly == !editable), isTrue);
      if (editable) {
        expect(fields.last.onFocusLost, isNotNull);
        expect(
          fields.last.inputFormatters?.any(
            (value) => value is KzPlateInputFormatter,
          ),
          isTrue,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('equipment group still hides the plate field', (tester) async {
    await _pump(
      tester,
      RegistrationSection(equipment: _equipment(EquipmentStatus.draft)),
      group: CatalogGroup.equipment,
    );
    final section = tester.widget<EquipmentEditorSection>(
      find.byType(EquipmentEditorSection),
    );
    await tester.tap(find.text(section.title));
    await tester.pumpAndSettle();
    expect(find.byType(AppTextField), findsOneWidget);
    expect(find.byType(EquipmentPlateBadge), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unscoped registration and tariff retain the legacy controls', (
    tester,
  ) async {
    await _pump(
      tester,
      RegistrationSection(equipment: _equipment(EquipmentStatus.available)),
      flow: false,
      scale: 1,
    );
    final section = tester.widget<EquipmentEditorSection>(
      find.byType(EquipmentEditorSection),
    );
    await tester.tap(find.text(section.title));
    await tester.pumpAndSettle();
    expect(find.byType(AppTextField), findsNWidgets(2));
    expect(find.byType(EquipmentPlateBadge), findsNothing);
    await _pump(
      tester,
      OwnerTariffCard(
        draft: TariffDraft.custom(),
        canEdit: true,
        onChanged: (_) {},
      ),
      flow: false,
      scale: 1,
    );
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.byType(AppLabelButton), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
