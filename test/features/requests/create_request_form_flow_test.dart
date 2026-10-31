import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/core/widgets/ui_kit/flow/prokat_flow_actions.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/catalog/models/catalog_bundle.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/features/catalog/models/localized_names.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/locations/state/location_service.dart';
import 'package:prokat/features/requests/providers/request_mutation_provider.dart';
import 'package:prokat/features/requests/state/request_provider.dart';
import 'package:prokat/features/requests/state/request_service.dart';
import 'package:prokat/features/requests/widgets.dart/create_request_form.dart';
import 'package:prokat/l10n/app_localizations.dart';

const _category = Category(id: 'excavators', name: 'Excavators', sortIndex: 1);
const _otherEquipment = Category(
  id: 'other-equipment',
  name: 'Other equipment',
  slug: 'eq_type_other_equipment',
  sortIndex: 2,
  catalogGroup: CatalogGroup.equipment,
);

final _address = LocationModel(
  id: 'address-1',
  service: 'ADDRESS',
  street: 'A long delivery street',
  houseNumber: '116',
  city: 'Atyrau',
  country: 'Kazakhstan',
  longitude: 51.9,
  latitude: 47.1,
);

class _Catalog extends CatalogNotifier {
  @override
  Future<CatalogBundle> build() async => const CatalogBundle(
    version: 'test',
    cities: [],
    categories: [
      CatalogCategory(
        id: 'excavators',
        slug: 'excavators',
        names: LocalizedNames(en: 'Excavators'),
        sortIndex: 1,
        isUserVisible: true,
        isOwnerVisible: true,
      ),
      CatalogCategory(
        id: 'other-equipment',
        slug: 'eq_type_other_equipment',
        names: LocalizedNames(en: 'Other equipment'),
        sortIndex: 2,
        isUserVisible: true,
        isOwnerVisible: true,
        catalogGroup: CatalogGroup.equipment,
      ),
    ],
    units: [],
    specs: [],
    specOptions: [],
    categorySpecs: [],
  );
}

class _UnusedLocationService implements LocationService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RequestService implements RequestService {
  final submissions =
      <
        ({
          String categoryId,
          String locationId,
          int? rate,
          String? comment,
          DateTime? when,
        })
      >[];
  Completer<ApiResponse<void>>? pending;

  @override
  Future<ApiResponse<void>> createRequest({
    required String categoryId,
    required String locationId,
    String? capacity,
    required DateTime requiredOn,
    DateTime? requiredAt,
    String? comment,
    int? offeredRate,
  }) {
    submissions.add((
      categoryId: categoryId,
      locationId: locationId,
      rate: offeredRate,
      comment: comment,
      when: requiredAt,
    ));
    return pending?.future ??
        Future.value(ApiResponse<void>.failure(message: 'Try again'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  ProviderContainer makeContainer(_RequestService service) {
    final container = ProviderContainer(
      overrides: [
        catalogProvider.overrideWith(_Catalog.new),
        requestServiceProvider.overrideWithValue(service),
        locationApiProvider.overrideWithValue(_UnusedLocationService()),
      ],
    );
    addTearDown(container.dispose);
    container.read(locationProvider.notifier).selectAddress(_address);
    container.read(requestMutationProvider.notifier).selectCategory(_category);
    return container;
  }

  Future<void> pumpForm(
    WidgetTester tester,
    ProviderContainer container, {
    bool flow = true,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (flow)
                  const ProkatFlowScope(
                    palette: ProkatFlowPalette.light,
                    child: CreateRequestForm(),
                  )
                else
                  const CreateRequestForm(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder budgetField() => find.byWidgetPredicate(
    (widget) =>
        widget is TextField && widget.keyboardType == TextInputType.number,
  );
  Finder commentField() => find.byWidgetPredicate(
    (widget) =>
        widget is TextField && widget.keyboardType == TextInputType.multiline,
  );
  ProkatFlowPrimaryButton submit(WidgetTester tester) => tester
      .widget<ProkatFlowPrimaryButton>(find.byType(ProkatFlowPrimaryButton));
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'scope keeps mandatory fields and group reset at 320px with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = _RequestService();
      final container = makeContainer(service);
      await pumpForm(tester, container, textScale: 2);
      expect(tester.takeException(), isNull);
      expect(submit(tester).onPressed, isNull);

      await tapVisible(tester, find.text('from owner'));
      expect(submit(tester).onPressed, isNull);
      await tapVisible(tester, find.text('As soon as possible'));
      expect(submit(tester).onPressed, isNotNull);
      final schedule = container.read(requestMutationProvider).selectedTime;

      await tapVisible(tester, find.text('Equipment'));
      expect(
        container.read(mutationCatalogGroupProvider),
        CatalogGroup.equipment,
      );
      expect(
        container.read(browseCatalogGroupProvider),
        CatalogGroup.machinery,
      );
      expect(container.read(requestMutationProvider).selectedCategory, isNull);
      expect(
        container.read(requestMutationProvider).selectedLocation?.id,
        _address.id,
      );
      expect(container.read(requestMutationProvider).selectedTime, schedule);
      expect(submit(tester).onPressed, isNull);

      container
          .read(requestMutationProvider.notifier)
          .selectCategory(_otherEquipment);
      await tester.pumpAndSettle();
      expect(submit(tester).onPressed, isNull);
      await tester.ensureVisible(commentField());
      await tester.enterText(commentField(), 'Need a generator');
      await tester.pumpAndSettle();
      expect(submit(tester).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
      expect(service.submissions, isEmpty);
    },
  );

  testWidgets(
    'owner price and capped budget preserve payload, busy guard and retry',
    (tester) async {
      final service = _RequestService();
      final container = makeContainer(service);
      await pumpForm(tester, container);
      await tapVisible(tester, find.text('from owner'));
      await tapVisible(tester, find.text('As soon as possible'));
      await tapVisible(tester, find.byType(ProkatFlowPrimaryButton));
      expect(service.submissions, hasLength(1));
      expect(service.submissions.single.rate, isNull);
      expect(service.submissions.single.categoryId, _category.id);
      expect(service.submissions.single.locationId, _address.id);
      expect(service.submissions.single.when, isNotNull);
      expect(submit(tester).loading, isFalse);
      expect(submit(tester).onPressed, isNotNull);

      await tapVisible(tester, find.text('my budget'));
      expect(submit(tester).onPressed, isNull);
      await tester.ensureVisible(budgetField());
      await tester.enterText(budgetField(), '100000');
      await tester.pumpAndSettle();
      expect(submit(tester).onPressed, isNotNull);
      await tester.enterText(budgetField(), '100001');
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(budgetField()).controller!.text,
        '100000',
      );
      service.pending = Completer<ApiResponse<void>>();
      await tester.ensureVisible(find.byType(ProkatFlowPrimaryButton));
      await tester.tap(find.byType(ProkatFlowPrimaryButton));
      await tester.pump();
      expect(service.submissions, hasLength(2));
      expect(service.submissions.last.rate, 100000);
      expect(submit(tester).loading, isTrue);
      expect(submit(tester).onPressed, isNull);
      service.pending!.complete(
        ApiResponse<void>.failure(message: 'Try again'),
      );
      await tester.pumpAndSettle();
      expect(submit(tester).loading, isFalse);
      expect(submit(tester).onPressed, isNotNull);
      await tapVisible(tester, find.text('from owner'));
      expect(tester.widget<TextField>(budgetField()).controller!.text, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('unscoped form retains original submit control', (tester) async {
    await pumpForm(tester, makeContainer(_RequestService()), flow: false);
    expect(find.byType(ProkatFlowPrimaryButton), findsNothing);
    expect(
      tester.widget<AppElevatedButton>(find.byType(AppElevatedButton)).title,
      'Create',
    );
    expect(tester.takeException(), isNull);
  });
}
