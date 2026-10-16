# Apple Export Compliance — техническая записка для владельца

Дата: 2026-10-16. Исследован код ветки `feat/tag-only-mobile-release` и её
зафиксированные зависимости. Это техническая рекомендация, не юридическая
классификация и не декларация от имени владельца. `Info.plist` не изменён;
`ITSAppUsesNonExemptEncryption` и `ITSEncryptionExportComplianceCode` отсутствуют.
App Store Connect и итоговый IPA не проверялись.

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

## Обоснованная рекомендация и границы уверенности

Рабочий кандидат — **`ITSAppUsesNonExemptEncryption = false`**, только если
владелец подтвердит применимость exemption ко всему поставляемому приложению,
включая стандартную Dart TLS и binary SDK. Назначение PROKAT — аренда техники,
а найденная crypto-функциональность выглядит вспомогательной: транспорт,
credentials, attestation и идентификаторы. Пользовательская crypto/VPN/E2EE/file
encryption функциональность или proprietary алгоритмы не обнаружены.
Это инженерная оценка назначения, НЕ достаточная юридическая классификация.

Сейчас нельзя обоснованно выбрать false безусловно: не подтверждены территории,
предыдущая декларация/классификация, сведения непрозрачных SDK и результат анкеты
Apple. **Рекомендация сейчас — оставить ключ неизменённым до решения владельца**,
не подставлять true «на всякий случай» и не выбирать «only Apple OS» вопреки
установленному TLS stack.

Если анкета/подтверждённая классификация требует документации, дальнейшая ветка —
оформление документации владельцем, Apple review и затем true с предоставленным
Apple compliance code/привязкой декларации, когда это требуется. Один Boolean
true не решает readiness. При освобождении возможны отдельные обязанности
self-classification/reporting; false не является подтверждением их отсутствия.
[Apple encryption compliance](https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations),
[код, предоставляемый Apple](https://developer.apple.com/documentation/bundleresources/information-property-list/itsencryptionexportcompliancecode).

## Какие сведения и решение нужны от владельца

После получения доступа, без upload/signing/новой сборки:

1. Подтвердить утверждённый source SHA и что за пределами просмотренного кода нет
   дополнительных extensions/SDK, proprietary algorithms, VPN/tunneling,
   пользовательского шифрования файлов или E2EE/защищённого обмена ключами.
2. Сообщить фактические территории текущей/планируемой availability, отдельно
   **France: yes/no/unknown**. Ничего не переключать в магазине самостоятельно.
3. App Store Connect → PROKAT → **App Information → App Encryption Documentation**:
   проверить существующую декларацию, решение Apple и относящуюся к этому
   приложению документацию/SDK classification. Не переносить без проверки ответ
   от старой версии, в которой могли быть другие SDK.
4. Владелец (Account Holder/Admin/App Manager) проходит актуальную анкету там же
   либо через Manage у существующего build. Использовать технические факты выше:
   transport encryption есть, OS-only утверждать нельзя, самописных/непубличных
   алгоритмов не найдено. Если необходима точная характеристика binary SDK,
   запросить у поставщика crypto/export information; не угадывать ECCN/CCATS.
   При спорной классификации обратиться к Apple export support/специалисту.
5. Сообщить только несекретные сведения: территории, подтверждение функционального
   inventory, наличие предыдущей декларации и результат анкеты («документация
   не требуется» / «требуется» / «нужны уточнения»). Секретные ключи не нужны.
6. Явно подтвердить выбранный Boolean и основание: например «Подтверждаю exempt
   classification для указанного SHA/SDK, разрешаю установить false», либо
   согласовать документационный путь. Агент внесёт значение отдельным изменением
   только после этого; код Apple нельзя придумывать.

## Влияние на U4

**BLOCKED / PENDING OWNER DECISION.** Текущий IPA verifier намеренно блокирует
отсутствующую Boolean-декларацию. Этот аудит подготовил факты, но не закрывает
legal/metadata gate. Mac dependency PASS также не является export-compliance
PASS: это две независимые задачи. Текущий шаг не меняет настройки магазина,
Info.plist, runtime, production config, secrets, certificates или CI publishing.
