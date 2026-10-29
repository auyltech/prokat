import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';
import 'package:prokat/features/equipment/state/equipment_mutation_notifier.dart';
import 'package:prokat/features/equipment/state/equipment_service.dart';
import 'package:prokat/features/equipment/widgets/online_toggle.dart';
import 'package:prokat/features/equipment/widgets/owner/equipment_plate_badge.dart';
import 'package:prokat/features/equipment/widgets/owner/equipment_status_badge.dart';
import 'package:prokat/features/equipment/widgets/owner/owner_equipment_card.dart';
import 'package:prokat/features/equipment_share/widgets/share_equipment_button.dart';
import 'package:prokat/l10n/app_localizations.dart';

class _UnusedEquipmentService implements EquipmentService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Mutation extends EquipmentMutationNotifier {
  _Mutation(Ref ref) : super(api: _UnusedEquipmentService(), ref: ref);
  final calls = <(String, bool)>[];

  @override
  Future<bool> toggleEquipmentOnline(String equipmentId, bool isVisible) async {
    calls.add((equipmentId, isVisible));
    return true;
  }
}

const _name = 'Экскаватор-погрузчик для строительных работ';
const _model = 'JCB 3CX Super Long Model';
const _plate = '907 EMR 06';

Equipment _equipment(EquipmentStatus status, {bool priced = true}) => Equipment(
  id: 'fleet-1',
  name: _name,
  model: _model,
  plateNumber: _plate,
  status: status,
  isVisible: true,
  prices: priced
      ? [
          PriceEntry(
            id: 'p1',
            price: 1250000,
            priceRate: const PriceRateOption(value: 'PER_HOUR', label: 'hour'),
            isStartingFrom: true,
          ),
        ]
      : [],
);

Future<void> _pump(
  WidgetTester tester,
  Widget card, {
  bool dark = false,
  bool flow = true,
  double scale = 2,
  double width = 320,
  void Function(_Mutation)? onMutation,
}) async {
  tester.view.physicalSize = Size(width, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final palette = dark ? ProkatFlowPalette.dark : ProkatFlowPalette.light;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        equipmentMutationProvider.overrideWith((ref) {
          final mutation = _Mutation(ref);
          onMutation?.call(mutation);
          return mutation;
        }),
      ],
      child: MaterialApp(
        theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: ProkatFlowScope(
            palette: palette,
            enabled: flow,
            child: child!,
          ),
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: card,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Russian visibility label stays on one line at 390px and normal text',
    (tester) async {
      await _pump(
        tester,
        OwnerEquipmentCard(equipment: _equipment(EquipmentStatus.available)),
        width: 390,
        scale: 1,
      );
      final l10n = AppLocalizations.of(
        tester.element(find.byType(OnlineToggle)),
      )!;
      final label = find.text(l10n.equipmentShown);
      final paragraph = tester.renderObject<RenderParagraph>(label);
      final boxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: l10n.equipmentShown.length),
      );
      expect(boxes.map((box) => box.top).toSet(), hasLength(1));
      expect(
        tester.widget<OnlineToggle>(find.byType(OnlineToggle)).vertical,
        isFalse,
      );
      expect(
        tester
            .getSize(
              find.byKey(const ValueKey('owner-equipment-tariff-fleet-1')),
            )
            .width,
        greaterThan(250),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'full-width visibility row stays readable at 320px and double text',
    (tester) async {
      await _pump(
        tester,
        OwnerEquipmentCard(equipment: _equipment(EquipmentStatus.available)),
      );
      final l10n = AppLocalizations.of(
        tester.element(find.byType(OnlineToggle)),
      )!;
      final label = find.text(l10n.equipmentShown);
      final paragraph = tester.renderObject<RenderParagraph>(label);
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(tester.widget<Text>(label).maxLines, isNull);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  for (final dark in [false, true]) {
    testWidgets('Flow visible listing uses success green, dark $dark', (
      tester,
    ) async {
      await _pump(
        tester,
        const OnlineToggle(id: 'fleet-1', isVisible: true, vertical: true),
        dark: dark,
        scale: 1,
      );
      final toggle = tester.widget<Switch>(find.byType(Switch));
      final palette = dark ? ProkatFlowPalette.dark : ProkatFlowPalette.light;
      final l10n = AppLocalizations.of(
        tester.element(find.byType(OnlineToggle)),
      )!;
      expect(toggle.value, isTrue);
      expect(toggle.activeTrackColor, palette.success);
      expect(toggle.activeThumbColor, Colors.white);
      expect(
        tester.widget<Text>(find.text(l10n.equipmentShown)).style?.color,
        palette.success,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('unscoped visibility keeps its original theme colors', (
    tester,
  ) async {
    await _pump(
      tester,
      const OnlineToggle(id: 'fleet-1', isVisible: true, vertical: true),
      flow: false,
      scale: 1,
    );
    final toggle = tester.widget<Switch>(find.byType(Switch));
    final context = tester.element(find.byType(OnlineToggle));
    final l10n = AppLocalizations.of(context)!;
    expect(toggle.activeTrackColor, isNull);
    expect(toggle.activeThumbColor, isNull);
    expect(
      tester.widget<Text>(find.text(l10n.equipmentShown)).style?.color,
      Theme.of(context).colorScheme.primary,
    );
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    for (final status in [
      EquipmentStatus.draft,
      EquipmentStatus.created,
      EquipmentStatus.rejected,
      EquipmentStatus.available,
      EquipmentStatus.booked,
      EquipmentStatus.maintenance,
    ]) {
      testWidgets('park $status fits 320px and 2x text, dark $dark', (
        tester,
      ) async {
        final equipment = _equipment(status);
        await _pump(
          tester,
          OwnerEquipmentCard(equipment: equipment),
          dark: dark,
        );
        expect(tester.takeException(), isNull);
        expect(find.text(_name), findsOneWidget);
        expect(find.text(_model), findsOneWidget);
        expect(find.text(_plate), findsOneWidget);
        expect(find.byType(EquipmentPlateBadge), findsOneWidget);
        expect(find.byType(EquipmentStatusBadge), findsOneWidget);
        final toggles =
            status == EquipmentStatus.available ||
            status == EquipmentStatus.accepted;
        expect(
          find.byType(OnlineToggle),
          toggles ? findsOneWidget : findsNothing,
        );
        expect(
          find.byType(ShareEquipmentButton),
          equipment.isModerated ? findsOneWidget : findsNothing,
        );
        if (status == EquipmentStatus.draft) {
          final l10n = AppLocalizations.of(
            tester.element(find.byType(OwnerEquipmentCard)),
          )!;
          // Identity and specs are complete; general data still lacks the city.
          expect(find.text(l10n.draftSectionsFilled(2, 3)), findsOneWidget);
          expect(
            find.byKey(const ValueKey('owner-equipment-tariff-fleet-1')),
            findsNothing,
          );
        } else {
          final tariff = tester.widget<Text>(
            find.byKey(const ValueKey('owner-equipment-tariff-fleet-1')),
          );
          expect(tariff.data, contains('1 250 000'));
          expect(tariff.maxLines, isNull);
        }
      });
    }
  }

  testWidgets(
    'card opens the existing editor and visibility keeps its mutation',
    (tester) async {
      var opened = 0;
      late _Mutation mutation;
      await _pump(
        tester,
        OwnerEquipmentCard(
          equipment: _equipment(EquipmentStatus.available),
          onOpen: () => opened++,
        ),
        scale: 1,
        onMutation: (value) => mutation = value,
      );
      await tester.tap(
        find.byKey(const ValueKey('owner-equipment-open-fleet-1')),
      );
      expect(opened, 1);
      await tester.ensureVisible(find.byType(Switch));
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(mutation.calls, [('fleet-1', false)]);
      expect(opened, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('missing tariff cannot publish a unit', (tester) async {
    late _Mutation mutation;
    await _pump(
      tester,
      OwnerEquipmentCard(
        equipment: _equipment(EquipmentStatus.available, priced: false),
      ),
      scale: 1,
      onMutation: (value) => mutation = value,
    );
    final toggle = tester.widget<OnlineToggle>(find.byType(OnlineToggle));
    expect(toggle.canShow, isFalse);
    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(mutation.calls, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('read-only rendering retains the existing presentation', (
    tester,
  ) async {
    await _pump(
      tester,
      OwnerEquipmentCard(
        equipment: _equipment(EquipmentStatus.created, priced: false),
        readOnly: true,
        showShare: false,
      ),
      scale: 1,
    );
    expect(
      find.byKey(const ValueKey('owner-equipment-flow-fleet-1')),
      findsNothing,
    );
    expect(find.byType(EquipmentPlateBadge), findsNothing);
    expect(find.byType(OnlineToggle), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('read-only long tariff keeps its own row at 320px and 2x text', (
    tester,
  ) async {
    await _pump(
      tester,
      OwnerEquipmentCard(
        equipment: _equipment(EquipmentStatus.created),
        readOnly: true,
        showShare: false,
      ),
    );
    expect(
      find.byKey(const ValueKey('owner-equipment-flow-fleet-1')),
      findsNothing,
    );
    expect(find.textContaining('1250000'), findsOneWidget);
    expect(find.byType(OnlineToggle), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
