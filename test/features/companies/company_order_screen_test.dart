import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/features/companies/company_order_screen.dart';
import 'package:prokat/l10n/app_localizations.dart';

void main() {
  setUpAll(() async {
    final brand = FontLoader('Manrope')
      ..addFont(rootBundle.load('assets/fonts/Manrope-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Manrope-Bold.ttf'));
    await brand.load();
    final config = File('.dart_tool/package_config.json').absolute;
    final packages =
        jsonDecode(await config.readAsString())['packages'] as List;
    final flutter = packages.firstWhere((p) => p['name'] == 'flutter') as Map;
    final root = config.uri.resolve('${flutter['rootUri']}/');
    final font = File.fromUri(
      root.resolve(
        '../../bin/cache/artifacts/material_fonts/roboto-regular.ttf',
      ),
    );
    final fallback = FontLoader('Roboto')
      ..addFont(font.readAsBytes().then(ByteData.sublistView));
    await fallback.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    final manifest =
        jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
    for (final family in manifest.where(
      (f) => '${f['family']}'.contains('lucide'),
    )) {
      final loader = FontLoader('${family['family']}');
      for (final font in family['fonts'] as List) {
        loader.addFont(rootBundle.load('${font['asset']}'));
      }
      await loader.load();
    }
  });
  for (final dark in [false, true])
    for (final side in [false, true]) {
      testWidgets('company order layout at 360px: dark=$dark company=$side', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        const id = 'review-order';
        final data = <String, dynamic>{
          'id': id,
          'status': 'PROPOSED',
          'version': 1,
          'companySide': side,
          'readOnly': false,
          'company': {'id': 'company', 'name': 'Атырау Спецтехника'},
          'clientName': 'Заказчик',
          'startsAt': '2026-10-02T09:00:00+05:00',
          'endsAt': '2026-10-02T12:00:00+05:00',
          'comment': 'Нужна вакуумная машина на объект. Уточните время подачи.',
          'budget': 50000,
          'agreedPrice': 45000,
          'equipmentIds': ['asset'],
          'assignedEquipmentIds': ['asset'],
          'assignedMachines': [
            {
              'id': 'asset',
              'name': 'Вакуумная машина КО-505',
              'model': 'КамАЗ',
            },
          ],
          'messages': [
            {
              'id': '1',
              'content': 'Здравствуйте! Нужна техника утром.',
              'createdAt': '2026-09-30T10:00:00+05:00',
              'fromCompany': false,
              'system': false,
            },
            {
              'id': '2',
              'content': 'Подготовили машину. Предлагаем условия, проверьте время и стоимость.',
              'createdAt': '2026-09-30T10:01:00+05:00',
              'fromCompany': true,
              'system': false,
            },
          ],
        };
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              companyInquiryProvider(id).overrideWith((ref) async => data),
            ],
            child: MaterialApp(
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
              locale: const Locale('ru'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const RepaintBoundary(
                key: Key('company-order-visual'),
                child: CompanyOrderScreen(id: id),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Атырау Спецтехника'), findsAtLeastNWidgets(1));
        expect(
          find.text(
            side ? 'Предложить технику и цену' : 'Подтвердить условия',
          ),
          findsOneWidget,
        );
        await expectLater(
          find.byKey(const Key('company-order-visual')),
          matchesGoldenFile(
            'goldens/order_${side ? 'company' : 'client'}_${dark ? 'dark' : 'light'}.png',
          ),
        );
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
}
