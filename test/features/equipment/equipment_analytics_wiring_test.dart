import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/analytics/analytics_service.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/billing/state/billing_notifier.dart';
import 'package:prokat/features/billing/state/billing_provider.dart';
import 'package:prokat/features/billing/state/billing_service.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/catalog/models/catalog_bundle.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/features/catalog/models/localized_names.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_details_provider.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_provider.dart';
import 'package:prokat/features/equipment/screens/create_equipment_screen.dart';
import 'package:prokat/features/equipment/screens/owner_equipment_detail_screen.dart';
import 'package:prokat/features/equipment/state/equipment_service.dart';
import 'package:prokat/features/equipment/state/owner_equipment_details_notifier.dart';
import 'package:prokat/features/equipment/state/owner_equipment_notifier.dart';
import 'package:prokat/features/owner/models/owner_profile_model.dart';
import 'package:prokat/features/owner/models/owner_status.dart';
import 'package:prokat/features/owner/state/owner_profile_notifier.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

import '../../helpers/recording_analytics_client.dart';

const _category = Category(
  id: 'cat-1',
  name: 'Excavators',
  sortIndex: 1,
  slug: 'excavators',
  names: LocalizedNames(en: 'Excavators'),
  catalogGroup: CatalogGroup.machinery,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('create screen emits equipment_creation_started once', (
    tester,
  ) async {
    final harness = await _pumpCreateScreen(tester, createSucceeds: true);

    await tester.pump();
    final events = harness.analytics.events
        .where((event) => event.name == 'equipment_creation_started')
        .toList();
    expect(events, hasLength(1));
    expect(events.single.params, {'is_first_equipment': 1});
  });

  testWidgets('successful create mutation emits equipment_draft_created', (
    tester,
  ) async {
    final harness = await _pumpCreateScreen(tester, createSucceeds: true);
    await _completeCreateForm(tester, harness.container);

    final events = harness.analytics.events
        .where((event) => event.name == 'equipment_draft_created')
        .toList();
    expect(harness.service.createCalls, 1);
    expect(events, hasLength(1));
    expect(events.single.params, {
      'category_id': 'cat-1',
      'catalog_group': 'machinery',
      'is_first_equipment': 1,
    });
  });

  testWidgets('failed create mutation emits no equipment_draft_created', (
    tester,
  ) async {
    final harness = await _pumpCreateScreen(tester, createSucceeds: false);
    await _completeCreateForm(tester, harness.container);

    expect(
      harness.analytics.events.where(
        (event) => event.name == 'equipment_draft_created',
      ),
      isEmpty,
    );
    expect(harness.service.createCalls, 1);
  });

  testWidgets('missing photo submission emits equipment_submit_blocked', (
    tester,
  ) async {
    final equipment = _equipment(imageUrl: null);
    final harness = await _pumpDetailScreen(
      tester,
      equipment: equipment,
      statusSucceeds: true,
    );

    await _tapDetailSubmit(tester);

    final events = harness.analytics.events
        .where((event) => event.name == 'equipment_submit_blocked')
        .toList();
    expect(events, hasLength(1));
    expect(events.single.params, {'reason': 'photo_missing'});
    expect(harness.service.statusCalls, 0);
  });

  testWidgets(
    'successful CREATED transition emits equipment_submitted_for_review',
    (tester) async {
      final equipment = _equipment(
        imageUrl: 'https://example.invalid/equipment.jpg',
      );
      final harness = await _pumpDetailScreen(
        tester,
        equipment: equipment,
        statusSucceeds: true,
      );

      await _tapDetailSubmit(tester);

      final events = harness.analytics.events
          .where((event) => event.name == 'equipment_submitted_for_review')
          .toList();
      expect(events, hasLength(1));
      expect(events.single.params, {
        'is_resubmit': 0,
        'category_id': 'cat-1',
        'catalog_group': 'machinery',
      });
      expect(harness.service.statusCalls, 1);
      expect(harness.service.lastStatus, EquipmentStatus.created);
    },
  );

  testWidgets('failed CREATED transition emits no submitted event', (
    tester,
  ) async {
    final equipment = _equipment(
      imageUrl: 'https://example.invalid/equipment.jpg',
    );
    final harness = await _pumpDetailScreen(
      tester,
      equipment: equipment,
      statusSucceeds: false,
    );

    await _tapDetailSubmit(tester);

    expect(
      harness.analytics.events.where(
        (event) => event.name == 'equipment_submitted_for_review',
      ),
      isEmpty,
    );
    expect(harness.service.statusCalls, 1);
  });
}

class _EquipmentHarness {
  const _EquipmentHarness({
    required this.analytics,
    required this.container,
    required this.service,
  });

  final RecordingAnalyticsClient analytics;
  final ProviderContainer container;
  final _FakeEquipmentService service;
}

Future<_EquipmentHarness> _pumpCreateScreen(
  WidgetTester tester, {
  required bool createSucceeds,
}) async {
  final analytics = RecordingAnalyticsClient();
  final service = _FakeEquipmentService(createSucceeds: createSucceeds);
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Text('home')),
      ),
      GoRoute(
        path: '/create',
        builder: (_, _) => const CreateEquipmentScreen(),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: _equipmentOverrides(
        analytics: analytics,
        service: service,
        ownerEquipment: const QueryState<Equipment>(itemsPerPage: 1, count: 0),
      ),
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(
    tester.element(find.text('home')),
  );
  await Future.wait([
    container.read(ownerEquipmentProvider.future),
    container.read(ownerProfileProvider.future),
  ]);
  unawaited(router.push('/create'));
  await _pumpFrames(tester);

  return _EquipmentHarness(
    analytics: analytics,
    container: container,
    service: service,
  );
}

Future<void> _completeCreateForm(
  WidgetTester tester,
  ProviderContainer container,
) async {
  container.read(equipmentMutationProvider.notifier).selectCategory(_category);
  await tester.pump();

  final fields = find.byType(AppTextField);
  await tester.enterText(
    find.descendant(of: fields.at(2), matching: find.byType(TextField)),
    'Excavator',
  );
  await tester.enterText(
    find.descendant(of: fields.at(3), matching: find.byType(TextField)),
    'CAT 320',
  );
  await tester.enterText(
    find.descendant(of: fields.at(4), matching: find.byType(TextField)),
    '123ABC01',
  );
  await tester.pump();

  expect(container.read(equipmentMutationProvider).category, _category);
  expect(find.text('atyrau'), findsOneWidget);

  final submit = find.text('Continue');
  await tester.scrollUntilVisible(submit, 300, scrollable: _listScrollable());
  await tester.ensureVisible(submit);
  await tester.pump();
  expect(
    tester.widget<AppElevatedButton>(find.byType(AppElevatedButton)).onTap,
    isNotNull,
  );
  await tester.tap(submit);
  await _pumpFrames(tester);
}

Future<_EquipmentHarness> _pumpDetailScreen(
  WidgetTester tester, {
  required Equipment equipment,
  required bool statusSucceeds,
}) async {
  final analytics = RecordingAnalyticsClient();
  final service = _FakeEquipmentService(statusSucceeds: statusSucceeds);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ..._equipmentOverrides(
          analytics: analytics,
          service: service,
          ownerEquipment: QueryState<Equipment>(
            items: [equipment],
            itemsPerPage: 1,
            count: 1,
          ),
        ),
        ownerEquipmentDetailsProvider.overrideWith(
          () => _FixedEquipmentDetailsNotifier(equipment),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OwnerEquipmentDetailScreen(equipmentId: equipment.id),
      ),
    ),
  );
  await _pumpFrames(tester);

  return _EquipmentHarness(
    analytics: analytics,
    container: ProviderScope.containerOf(
      tester.element(find.byType(OwnerEquipmentDetailScreen)),
    ),
    service: service,
  );
}

List<Override> _equipmentOverrides({
  required RecordingAnalyticsClient analytics,
  required _FakeEquipmentService service,
  required QueryState<Equipment> ownerEquipment,
}) => [
  analyticsServiceProvider.overrideWithValue(AnalyticsService(analytics)),
  equipmentServiceProvider.overrideWithValue(service),
  catalogProvider.overrideWith(_FixedCatalogNotifier.new),
  ownerProfileProvider.overrideWith(_FixedOwnerProfileNotifier.new),
  ownerEquipmentProvider.overrideWith(
    () => _FixedOwnerEquipmentNotifier(ownerEquipment),
  ),
  billingProvider.overrideWith((ref) => _NoopBillingNotifier()),
];

Future<void> _tapDetailSubmit(WidgetTester tester) async {
  final submit = find.text('Submit for moderation');
  await tester.scrollUntilVisible(submit, 350, scrollable: _listScrollable());
  await tester.ensureVisible(submit);
  await tester.pump();
  await tester.tap(submit);
  await _pumpFrames(tester);
}

Finder _listScrollable() => find
    .descendant(
      of: find.byType(ListView).first,
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Equipment _equipment({String? imageUrl}) => Equipment(
  id: 'eq-1',
  name: 'Excavator',
  model: 'CAT 320',
  plateNumber: '123ABC01',
  status: EquipmentStatus.draft,
  imageUrl: imageUrl,
  isVisible: false,
  categoryId: 'cat-1',
  category: _category,
  city: 'atyrau',
  prices: [
    PriceEntry(
      id: 'price-1',
      price: 1000,
      priceRate: parseRateOption('PER_DAY'),
    ),
  ],
);

class _FixedCatalogNotifier extends CatalogNotifier {
  @override
  Future<CatalogBundle> build() async => const CatalogBundle(
    version: 'test',
    cities: [],
    categories: [
      CatalogCategory(
        id: 'cat-1',
        slug: 'excavators',
        names: LocalizedNames(en: 'Excavators'),
        sortIndex: 1,
        isUserVisible: true,
        isOwnerVisible: true,
      ),
    ],
    units: [],
    specs: [],
    specOptions: [],
    categorySpecs: [],
  );

  @override
  Future<void> refresh() async {}

  @override
  Future<void> refreshIfStale() async {}
}

class _FixedOwnerProfileNotifier extends OwnerProfileNotifier {
  @override
  Future<OwnerProfileModel?> build() async =>
      OwnerProfileModel(city: 'atyrau', onlineStatus: OwnerStatus.offline);

  @override
  Future<void> refresh() async {}

  @override
  Future<void> refreshIfStale() async {}
}

class _FixedOwnerEquipmentNotifier extends OwnerEquipmentNotifier {
  _FixedOwnerEquipmentNotifier(this.value);

  final QueryState<Equipment> value;

  @override
  Future<QueryState<Equipment>> build() async => value;

  @override
  Future<void> refresh() async {}
}

class _FixedEquipmentDetailsNotifier extends OwnerEquipmentDetailsNotifier {
  _FixedEquipmentDetailsNotifier(this.equipment);

  final Equipment equipment;

  @override
  Future<Equipment> build(String id) async => equipment;

  @override
  Future<void> refresh() async {}
}

class _FakeEquipmentService extends EquipmentService {
  _FakeEquipmentService({
    this.createSucceeds = true,
    this.statusSucceeds = true,
  }) : super(_TestApiClient(Dio()));

  final bool createSucceeds;
  final bool statusSucceeds;
  int createCalls = 0;
  int statusCalls = 0;
  EquipmentStatus? lastStatus;

  @override
  Future<ApiResponse<void>> createEquipment(Map<String, dynamic> data) async {
    createCalls += 1;
    return createSucceeds
        ? ApiResponse.success(null)
        : ApiResponse.failure(message: 'create failed');
  }

  @override
  Future<ApiResponse<void>> updateEquipmentStatus({
    required String equipmentId,
    required EquipmentStatus status,
  }) async {
    statusCalls += 1;
    lastStatus = status;
    return statusSucceeds
        ? ApiResponse.success(null)
        : ApiResponse.failure(message: 'status failed');
  }
}

class _NoopBillingNotifier extends BillingNotifier {
  _NoopBillingNotifier() : super(BillingService(_TestApiClient(Dio())));

  @override
  Future<void> getOwnerBalance({bool silent = false}) async {}
}

class _TestApiClient implements ApiClient {
  _TestApiClient(this.dio);

  @override
  Dio dio;
}
