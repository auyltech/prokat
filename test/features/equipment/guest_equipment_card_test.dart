import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/features/auth/models/user_model.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/equipment/widgets/list/guest_equipment_card.dart';
import 'package:prokat/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('guest card shows city and opens login on tap', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: GuestEquipmentCard(
              item: Equipment(
                id: 'eq-1',
                name: 'ассенизатор',
                model: 'камаз',
                status: EquipmentStatus.available,
                isVisible: true,
                city: 'atyrau',
                owner: const UserModel(rating: 5, orderCount: 21),
                prices: [
                  PriceEntry(
                    id: 'p1',
                    price: 25000,
                    priceRate: parseRateOption('PER_DAY'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('ассенизатор'), findsOneWidget);
    expect(find.text('atyrau'), findsOneWidget);
    expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);

    await tester.tap(find.byType(GuestEquipmentCard));
    await tester.pumpAndSettle();

    expect(find.text('Требуется вход'), findsOneWidget);
  });
}
