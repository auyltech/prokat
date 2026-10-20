# Apple Export Compliance — техническая записка для владельца

Обновлено: 2026-10-20. Исследован код ветки `feat/tag-only-mobile-release` и её
зафиксированные зависимости; исходная точка изменения декларации — commit
`0c0108b54d957bb3c3d5ad0bce43f74a7d232ed8`, чистое рабочее дерево.
Владелец подтвердил результат актуальной анкеты App Store Connect: документы
для текущего распространения только в Казахстане не запрошены. На этом основании
в `ios/Runner/Info.plist` установлен Boolean `ITSAppUsesNonExemptEncryption=false`.
`ITSEncryptionExportComplianceCode` не добавлен: одобренный Apple код не выдавался.
Это фиксация решения для текущего состава приложения и географии, не юридическая
классификация всех SDK. Агент не проверял live App Store Connect и итоговый IPA.

## Что фактически найдено

| Компонент | Доказательство в проекте / pinned SDK | Значение для анкеты |
| --- | --- | --- |
| HTTPS API | `lib/core/api/api_client.dart` создаёт обычный Dio5.11.0; `lib/core/config/env.dart` и tracked production.json задают HTTPS. Локальный IO adapter Dio использует Dart HttpClient; custom Cupertino/native adapter не найден | Шифрование транспорта используется. Нельзя заявлять «шифрования нет» |
| Socket.IO / чат | `lib/core/services/app_socket_service.dart`, socket_io_client3.1.6 → default_ws_connector_io.dart → dart:io WebSocket; HTTPS origin даёт защищённый транспорт | TLS, не доказательство end-to-end encryption между пользователями. Собственный E2EE-протокол в просмотренном исходном коде не найден |
| Flutter/Dart TLS | Flutter3.47.2 / Dart3.13.2; официальный Dart3.13.2 secure_socket_filter.cc вызывает SSL API, BUILD.gn подключает third_party/boringssl, включая iOS | Стандартная TLS-реализация вне Apple OS. Использование OS trust store не превращает её в URLSession-only encryption |
| Secure storage | flutter_secure_storage11.0.0 / flutter_secure_storage_darwin0.4.0; `SecureStorageClient` задаёт first_unlock; AuthSecureStorage пишет JSON сессии/OTP в Keychain. useSecureEnclave по умолчанию false, явное включение в app source не найдено | Apple Security/Keychain защищает локальные credentials. В SDK также есть опциональные AES-GCM / ECIES через Apple CryptoKit / SecKey, а не собственная AES-библиотека; не скрываем наличие этих возможностей |
| Firebase | Core, Analytics, AppCheck, Messaging, RemoteConfig, Crashlytics; native SDK12.19.0. Package.swift выбранных FlutterFire plugins проверены; нет cloud_firestore/firebase_auth в pubspec | SDK-сеть, attestation/authenticity и связанные системные механизмы входят в inventory. Это не собственный пользовательский crypto-продукт |
| gRPC в Swift locks | grpc-binary1.69.1, abseil/leveldb присутствуют в общем Firebase resolution. Upstream Package.swift связывает gRPC с Firestore targets | Lock pin НЕ доказывает, что gRPC/OpenSSL реально включены в Runner. Нельзя объявлять «Firebase точно включает BoringSSL» по одному Package.resolved |
| Mapbox / прочие binary SDK | mapbox-maps-ios11.29.1, mapbox-common-ios24.29.1, core-maps11.29.1, reCAPTCHA18.9.1 и Google measurement binary products | Имеют непрозрачные бинарные части. Точный shipped crypto inventory / export classification не выведен из manifests. При необходимости нужны сведения поставщика, не догадка |
| Dart crypto / идентификаторы | crypto3.0.7 — transitive; UUID4.6.0 содержит SHA-1 для UUIDv5, приложение использует UUIDv4. Share IDs: Random.secure + base64url; прямые imports crypto/cryptography/encrypt/pointycastle и реализации AES/RSA/HMAC в app source не найдены | Hashing, randomness и encoding нельзя называть собственным шифрованием данных. Наличие пакета не доказывает использование каждого его алгоритма |

Проверялись `lib/`, собственный код `ios/Runner`, pubspec/lock, оба Swift locks и
доступный локальный package cache. Алгоритмы backend, скрытые binary SDK,
финальный linked binary и будущие изменения этим аудитом не покрыты. Python
cryptography/PyJWT release-tools и signing CI не поставляются как runtime-функции
приложения и не должны ошибочно учитываться как его пользовательское шифрование.

Источники TLS: [Dart3.13.2 SSL implementation](https://raw.githubusercontent.com/dart-lang/sdk/3.13.2/runtime/bin/secure_socket_filter.cc),
[Dart3.13.2 build dependency](https://raw.githubusercontent.com/dart-lang/sdk/3.13.2/runtime/bin/BUILD.gn).
Firebase: [Package.swift зафиксированного revision](https://raw.githubusercontent.com/firebase/firebase-ios-sdk/27eaab3918e0bf78711cf1abf240577176326432/Package.swift).
SDK cache исследован как исходный код, но не выполнялся; native symbols/binary
inspection на Mac не проводилась. Проверка linked binary не разрешает новую
сборку: можно исследовать уже имеющийся approved archive при отдельном доступе.

## Как понимать вопросы Apple

«Использует ли приложение шифрование?» и ключ **Uses Non-Exempt Encryption** —
разные вопросы. Для PROKAT технический ответ на первый — **да, как минимум TLS**.
`false` во втором означает «нет non-exempt encryption», а не «нет TLS».
Apple включает сторонние библиотеки в определение; отсутствие самописного AES
само по себе не доказывает exemption. [Описание ключа](https://developer.apple.com/documentation/bundleresources/information-property-list/itsappusesnonexemptencryption).

Для OS-only encryption Apple приводит освобождение от загрузки документации,
но к PROKAT нельзя автоматически применять аргумент «всё только в Apple OS»:
Dart TLS использует отдельную реализацию. При этом стандартная сторонняя TLS
реализация **не равна** proprietary/non-standard cryptography и **не означает
автоматически**, что значение ключа должно быть true.
[Обзор Apple](https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance/),
[правила определения и анкета](https://developer.apple.com/help/app-store-connect/manage-app-information/determine-and-upload-app-encryption-documentation/).

Отдельно важно распространение во **Франции**: текущая таблица Apple различает
OS-only и стандартные алгоритмы вне OS, а French declaration связывает с
распространением во Франции. Не делаем вывод о территориях из того, что приложение
предназначено для Казахстана, и не меняем availability ради обхода вопроса.
[Таблица требуемой документации](https://developer.apple.com/help/app-store-connect/reference/app-information/export-compliance-documentation-for-encryption/).

## Принятое решение — 2026-10-20

Владелец сообщил следующие факты из App Store Connect:

1. PROKAT доступен **только в Казахстане**; **France: Not Available**.
2. В анкете выбрано **стандартное шифрование вне Apple OS**.
3. На вопрос о распространении во Франции выбран **No**.
4. После **Save** система вернулась к App Information без запроса документов.

Это owner-confirmed evidence, а не независимая API/browser-проверка агентом и не
одобрение загруженного документа Apple. Ранее открытые вопросы о территориях и
результате анкеты закрыты этим подтверждением. Новых оснований считать найденные
алгоритмы proprietary/non-standard при повторной сверке не обнаружено.

Для указанного сценария обоснован **Boolean `false`**: документация в App Store
Connect не потребовалась. Основание — технический аудит вместе с подтверждённым
результатом анкеты, а не отсутствие шифрования или OS-only реализация. По таблице
Apple французская декларация для стандартных алгоритмов вне OS требуется только
при распространении во Франции. Apple предписывает отразить отсутствие обязанности
предоставлять документацию в Info.plist. Самостоятельно устанавливать `true` или
придумывать compliance code оснований нет.

## Ограничения и повторная проверка

- Решение относится к текущему составу приложения и распространению **только в
  Казахстане**. Перед изменением availability, особенно добавлением Франции,
  повторить анкету и при необходимости предоставить требуемые документы.
- Повторить crypto/export audit при изменении Flutter/Dart, зависимостей/SDK,
  их настроек или криптографических функций: TLS, storage, authentication,
  attestation, E2EE, VPN, шифрование файлов и собственные алгоритмы.
- Закрытые части Mapbox/Google SDK остаются ограничением технической уверенности.
  Анкета без запроса документов не доказывает отсутствие скрытых алгоритмов и
  не заменяет сведения поставщика при появлении противоречащих фактов.
- Итоговый подписанный IPA не исследован. В отдельно разрешённом U4 существующий
  `verify_ios.py` должен проверить реальный экспортированный Info.plist и подпись;
  локальная проверка исходного plist не заменяет эту проверку артефакта.
- `false` не является подтверждением отсутствия отдельных обязательств
  self-classification/reporting вне App Store Connect.

[Apple encryption compliance](https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations),
[инструкция при отсутствии необходимости документации](https://developer.apple.com/help/app-store-connect/manage-app-information/determine-and-upload-app-encryption-documentation/),
[код, предоставляемый Apple](https://developer.apple.com/documentation/bundleresources/information-property-list/itsencryptionexportcompliancecode).

## Влияние на U4

**Export Compliance blocker CLOSED для указанного сценария.** Исходный plist
содержит Boolean `false`, который принимает существующий IPA verifier; его
проверка обязательности Boolean не ослаблена. Остальные U1/U3 prerequisites и
отдельное разрешение U4 сохраняются: это не READY FOR U4 и не разрешение сборки
или публикации. Signing, entitlements, Firebase, production gate, конфигурация
публикации и настройки Apple этим изменением не затрагиваются.
