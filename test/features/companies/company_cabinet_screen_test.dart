import 'package:prokat/features/companies/company_workspace_screen.dart';
import 'package:prokat/features/companies/company_category_screen.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/catalog/models/catalog_bundle.dart';

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/features/companies/company_cabinet_screen.dart';
import 'package:prokat/features/companies/company_models.dart';
import 'package:prokat/features/companies/company_service.dart';
import 'package:prokat/features/user/models/user_profile_model.dart';
import 'package:prokat/features/user/state/client_profile_notifier.dart';
import 'package:prokat/features/user/state/client_profile_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class _Profile extends ClientProfileNotifier {
  @override
  Future<UserProfileModel?> build() async =>
      UserProfileModel(firstName: 'Адиль', phoneNumber: '+77000000000');
}

class _Catalog extends CatalogNotifier {
  @override
  Future<CatalogBundle> build() async =>
      CatalogBundle.fromJson({'version': 'test'});
}

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

  for (final dark in [false, true]) {
    for (final owner in [false, true]) {
      testWidgets('company profile at 360px: dark=$dark owner=$owner', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              clientProfileProvider.overrideWith(_Profile.new),
              companyBillingProvider('company').overrideWith(
                (ref) async => {
                  'secondsRemaining': 6000,
                  'online': false,
                  'burnRateMinutesPerHour': 0,
                  'estimatedExhaustionAt': null,
                },
              ),
              companyContextProvider.overrideWith(
                (ref) async => CompanyContext(
                  memberships: [
                    CompanyMembership(
                      id: 'member',
                      role: owner ? 'OWNER' : 'MANAGER',
                      organization: const CompanyProfile(
                        id: 'company',
                        name: 'Атырау Спецтехника',
                        bin: '990930000004',
                        description: '',
                        city: 'atyrau',
                        status: 'ACTIVE',
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: MaterialApp(
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
              locale: const Locale('ru'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const CompanyCabinetScreen(
                companyId: 'company',
                section: 'profile',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(owner ? 'Руководитель' : 'Диспетчер'), findsOneWidget);

        expect(
          tester.widget<SliverAppBar>(find.byType(SliverAppBar)).expandedHeight,
          320,
        );
        expect(find.text('Баланс компании'), findsOneWidget);
        await expectLater(
          find.byType(CompanyCabinetScreen),
          matchesGoldenFile(
            'goldens/profile_${owner ? "leader" : "dispatcher"}_${dark ? "dark" : "light"}.png',
          ),
        );
        await tester.scrollUntilVisible(
          find.text('Выйти из кабинета компании'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Выйти из кабинета компании'), findsOneWidget);
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
        await tester.pumpAndSettle();
        expect(
          find.text('Пригласить диспетчера'),
          owner ? findsOneWidget : findsNothing,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  for (final dark in [false, true]) {
    for (final category in [false, true]) {
      testWidgets('company fleet simple layout dark=$dark category=$category', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final park = CompanyFleet.fromJson({
          'totals': {'total': 1, 'busy': 0},
          'groups': [
            {
              'id': 'MACHINERY',
              'name': 'Техника',
              'categories': [
                {
                  'id': 'vacuum',
                  'name': 'Вакуумные машины',
                  'total': 1,
                  'busy': 0,
                  'items': [
                    {
                      'id': 'machine',
                      'name': 'Вакуумка 1',
                      'model': 'КО-505',
                      'categoryId': 'vacuum',
                      'status': 'DRAFT',
                      'busy': false,
                    },
                  ],
                },
              ],
            },
          ],
        });
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              catalogProvider.overrideWith(_Catalog.new),
              companyLogoProvider('company').overrideWith((ref) async => null),
              companyFleetProvider('company').overrideWith((ref) async => park),
              companyContextProvider.overrideWith(
                (ref) async => const CompanyContext(
                  memberships: [
                    CompanyMembership(
                      id: 'member',
                      role: 'OWNER',
                      organization: CompanyProfile(
                        id: 'company',
                        name: 'Атырау Спецтехника',
                        bin: '990930000004',
                        description: 'Аренда спецтехники',
                        city: 'atyrau',
                        status: 'ACTIVE',
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: MaterialApp(
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
              locale: const Locale('ru'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: category
                  ? const CompanyCategoryScreen(
                      companyId: 'company',
                      categoryId: 'vacuum',
                    )
                  : const CompanyWorkspaceScreen(companyId: 'company'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Заявки'), findsNothing);
        if (category) {
          expect(find.text('Удалить'), findsOneWidget);
          expect(find.text('Свободна'), findsOneWidget);
        } else {
          expect(find.text('Объявление компании'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(Scaffold).first,
          matchesGoldenFile(
            'goldens/fleet_${category ? "category" : "home"}_${dark ? "dark" : "light"}.png',
          ),
        );
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
