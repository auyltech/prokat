import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/core/widgets/ui_kit/flow/prokat_flow_actions.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/catalog/models/localized_names.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/locations/state/location_service.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_notifier.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_service.dart';
import 'package:prokat/features/price_negotiations/widgets/booking_terms_proposal_sheet.dart';
import 'package:prokat/l10n/app_localizations.dart';

final _originalAddress = LocationModel(
  id: 'client-private-location',
  userId: 'client-private-user',
  equipmentId: 'unrelated-equipment',
  service: 'ADDRESS',
  street: 'Original delivery street',
  streetNames: const LocalizedNames(en: 'Original delivery street'),
  houseNumber: '116',
  city: 'Atyrau',
  country: 'Kazakhstan',
  latitude: 47.1,
  longitude: 51.9,
  createdAt: DateTime.utc(2026),
);
final _savedAddress = LocationModel(
  id: 'owner-private-address',
  userId: 'owner-private-user',
  service: 'ADDRESS',
  street: 'Other shared delivery street',
  city: 'Atyrau',
  country: 'Kazakhstan',
  latitude: 47.2,
  longitude: 51.8,
);

BookingModel _booking({BookingStatus status = BookingStatus.created}) {
  final day = DateTime.now().add(const Duration(days: 3));
  return BookingModel(
    id: 'pending-booking',
    status: status,
    price: 18000,
    priceRate: priceRateOptions.firstWhere((rate) => rate.value == 'PER_HOUR'),
    bookedOn: DateTime(day.year, day.month, day.day),
    bookedAt: DateTime(day.year, day.month, day.day, 10),
    updatedAt: DateTime.utc(2026, 10, 28, 7),
    location: _originalAddress,
  );
}

class _UnusedService implements PriceNegotiationService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Locations implements LocationService {
  int reads = 0;
  @override
  Future<ApiResponse<List<LocationModel>>> getClientLocations({
    String? mode,
  }) async {
    reads++;
    return ApiResponse.success([_savedAddress]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Mutation extends PriceNegotiationMutationNotifier {
  _Mutation(Ref ref) : super(ref, _UnusedService());
  final submissions = <Map<String, dynamic>>[];
  Completer<void>? pending;
  bool failNext = false;

  @override
  Future<void> createCounterOffer({
    required int price,
    String? bookingId,
    String? offerId,
    String? priceRate,
    String? comment,
    required String type,
    String? chatId,
    Map<String, dynamic>? terms,
  }) async {
    submissions.add({
      'price': price,
      'priceRate': priceRate,
      'bookingId': bookingId,
      'offerId': offerId,
      'type': type,
      'chatId': chatId,
      'terms': terms,
    });
    await pending?.future;
    if (failNext) {
      failNext = false;
      throw Exception('The booking changed. Refresh the chat.');
    }
  }
}

void main() {
  Future<({_Mutation mutation, _Locations locations})> pumpForm(
    WidgetTester tester, {
    required BookingModel booking,
    AppMode mode = AppMode.clientMode,
    double textScale = 1,
  }) async {
    late _Mutation mutation;
    final locations = _Locations();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          priceNegotiationMutationProvider.overrideWith(
            (ref) => mutation = _Mutation(ref),
          ),
          locationApiProvider.overrideWithValue(locations),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ProkatFlowScope(
                  palette: ProkatFlowPalette.light,
                  child: BookingTermsProposalSheet(
                    booking: booking,
                    mode: mode,
                    chatId: 'discussion-chat',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (mutation: mutation, locations: locations);
  }

  Finder priceInput() => find.descendant(
    of: find.byKey(const ValueKey('terms-price')),
    matching: find.byType(TextField),
  );

  Future<void> submit(WidgetTester tester) async {
    await tester.pumpAndSettle();
    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final button = find.byType(ProkatFlowPrimaryButton);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    expect(button.hitTestable(), findsOneWidget);
    await tester.tap(button.hitTestable());
    await tester.pump();
  }

  testWidgets('unchanged terms stay local and fit a narrow large-text screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final booking = _booking();
    final fixture = await pumpForm(tester, booking: booking, textScale: 2);
    expect(tester.takeException(), isNull);
    expect(tester.widget<TextField>(priceInput()).controller!.text, '18000');
    expect(
      tester
          .widget<ProkatFlowPrimaryButton>(find.byType(ProkatFlowPrimaryButton))
          .onPressed,
      isNull,
    );
    expect(fixture.locations.reads, 0);
    expect(fixture.mutation.submissions, isEmpty);
    expect(booking.price, 18000);
    expect(booking.location, same(_originalAddress));
    await tester.enterText(priceInput(), '17500');
    await submit(tester);
    expect(fixture.mutation.submissions.single['price'], 17500);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'price edit preserves address, dates and baseline version without mutating booking',
    (tester) async {
      final booking = _booking();
      final fixture = await pumpForm(tester, booking: booking);
      await tester.enterText(priceInput(), '17000');
      await submit(tester);
      final sent = fixture.mutation.submissions.single;
      final terms = sent['terms'] as Map<String, dynamic>;
      expect(sent['type'], 'CLIENT_COUNTER');
      expect(sent['price'], 17000);
      expect(sent['priceRate'], 'PER_HOUR');
      expect(sent['bookingId'], booking.id);
      expect(sent['chatId'], 'discussion-chat');
      expect(
        terms['expectedBookingUpdatedAt'],
        booking.updatedAt!.toUtc().toIso8601String(),
      );
      expect(terms['bookedOn'], booking.bookedOn!.toUtc().toIso8601String());
      expect(terms['bookedAt'], booking.bookedAt!.toUtc().toIso8601String());
      expect((terms['location'] as Map)['street'], _originalAddress.street);
      for (final field in [
        'id',
        'userId',
        'equipmentId',
        'service',
        'createdAt',
        'updatedAt',
      ]) {
        expect((terms['location'] as Map).containsKey(field), isFalse);
      }
      expect(booking.price, 18000);
      expect(booking.status, BookingStatus.created);
      expect(fixture.locations.reads, 0);
    },
  );

  testWidgets(
    'owner selects saved address as a snapshot without setting client primary address',
    (tester) async {
      final fixture = await pumpForm(
        tester,
        booking: _booking(),
        mode: AppMode.ownerMode,
      );
      final address = find.byKey(const ValueKey('terms-address'));
      await tester.ensureVisible(address);
      await tester.tap(
        find.descendant(of: address, matching: find.byType(TextField)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Current request address'), findsOneWidget);
      await tester.tap(find.text('Other shared delivery street, Atyrau'));
      await tester.pumpAndSettle();
      await submit(tester);
      final sent = fixture.mutation.submissions.single;
      expect(sent['type'], 'OWNER_COUNTER');
      final location = (sent['terms'] as Map)['location'] as Map;
      expect(location['street'], _savedAddress.street);
      expect(location['latitude'], _savedAddress.latitude);
      expect(location.containsKey('id'), isFalse);
      expect(location.containsKey('userId'), isFalse);
      expect(fixture.locations.reads, 1);
    },
  );

  testWidgets('price proposal preserves an unchanged elapsed schedule', (
    tester,
  ) async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final booking = _booking().copyWith(
      bookedOn: DateTime(yesterday.year, yesterday.month, yesterday.day),
      bookedAt: DateTime(yesterday.year, yesterday.month, yesterday.day, 10),
    );
    final fixture = await pumpForm(tester, booking: booking);
    await tester.enterText(priceInput(), '17000');
    await submit(tester);
    final sent = fixture.mutation.submissions.single;
    final terms = sent['terms'] as Map;
    expect(terms['bookedOn'], booking.bookedOn!.toUtc().toIso8601String());
    expect(terms['bookedAt'], booking.bookedAt!.toUtc().toIso8601String());
    expect(sent['price'], 17000);
    expect(booking.price, 18000);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'duplicate tap is blocked while proposal is pending and failure keeps the draft',
    (tester) async {
      final fixture = await pumpForm(tester, booking: _booking());
      fixture.mutation.pending = Completer<void>();
      fixture.mutation.failNext = true;
      await tester.enterText(priceInput(), '16000');
      await submit(tester);
      final button = find.byType(ProkatFlowPrimaryButton);
      await tester.ensureVisible(button);
      await tester.pump();
      expect(button.hitTestable(), findsOneWidget);
      await tester.tap(button.hitTestable());
      await tester.pump();
      expect(fixture.mutation.submissions.length, 1);
      fixture.mutation.pending!.complete();
      await tester.pumpAndSettle();
      expect(
        find.text('The booking changed. Refresh the chat.'),
        findsOneWidget,
      );
      expect(tester.widget<TextField>(priceInput()).controller!.text, '16000');
      expect(
        tester
            .widget<ProkatFlowPrimaryButton>(
              find.byType(ProkatFlowPrimaryButton),
            )
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets('confirmed booking never offers terms submission', (
    tester,
  ) async {
    final fixture = await pumpForm(
      tester,
      booking: _booking(status: BookingStatus.confirmed),
    );
    await tester.enterText(priceInput(), '17000');
    expect(
      tester
          .widget<ProkatFlowPrimaryButton>(find.byType(ProkatFlowPrimaryButton))
          .onPressed,
      isNull,
    );
    expect(fixture.mutation.submissions, isEmpty);
  });

  testWidgets(
    'ASAP is a proposed future schedule and leaves the original booking intact',
    (tester) async {
      final booking = _booking();
      final fixture = await pumpForm(tester, booking: booking);
      final asap = find.text('As soon as possible');
      await tester.ensureVisible(asap);
      await tester.tap(asap);
      await tester.pumpAndSettle();
      final before = DateTime.now().toUtc();
      await submit(tester);
      final terms = fixture.mutation.submissions.single['terms'] as Map;
      final proposedTime = DateTime.parse(terms['bookedAt'] as String);
      expect(proposedTime.isAfter(before), isTrue);
      expect(
        proposedTime.isBefore(before.add(const Duration(minutes: 2))),
        isTrue,
      );
      expect(
        booking.bookedAt!.day,
        DateTime.now().add(const Duration(days: 3)).day,
      );
      expect(fixture.mutation.submissions.single['price'], booking.price);
    },
  );
}
