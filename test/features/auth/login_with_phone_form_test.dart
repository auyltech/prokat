import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/features/auth/widgets/login_with_phone_form.dart';
import 'package:prokat/features/auth/widgets/phone_input_field.dart';
import 'package:prokat/l10n/app_localizations.dart';

class _RateLimitedAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({'code': 'RATE_LIMITED', 'message': 'Please try again later'}),
      429,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        'retry-after': ['45'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('phone mask keeps its state when the field rebuilds', (
    tester,
  ) async {
    final controller = TextEditingController();
    late StateSetter rebuild;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return PhoneInputField(controller: controller);
            },
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '700');
    expect(controller.text, '(700');

    rebuild(() {});
    await tester.pump();

    await tester.enterText(find.byType(TextField), '${controller.text}1');
    expect(controller.text, '(700) 1');

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('429 keeps phone form visible and disables send until retry', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://example.test',
        responseType: ResponseType.json,
        validateStatus: (status) => status != null && status < 600,
      ),
    )..httpClientAdapter = _RateLimitedAdapter();
    String? error;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [dioProvider.overrideWithValue(dio)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: LoginWithPhoneForm(onError: (value) => error = value),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '7001234567');
    await tester.pump();
    await tester.tap(find.text('Send Code'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Send Code'), findsOneWidget);
    expect(
      find.textContaining('You can request another code in'),
      findsOneWidget,
    );
    expect(error, 'Please try again later');
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
  });
}
