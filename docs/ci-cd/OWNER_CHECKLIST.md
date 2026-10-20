# Короткие инструкции U2 / U3

Штатные команды, общий build counter и dev → main squash:
[CICD-README](../../CICD-README.md). Датированные результаты ниже сохранены;
они не заменяют live preflight и не разрешают создание тегов.

Состояние на 19.10.2026: доступ Google Play API подтверждён; оставшиеся Apple
доступы и другие prerequisites ещё ожидают проверки. **Ничего не пересоздавайте**:
выполненные Android-действия ниже повторять не нужно. Агент не создаёт
секреты, сертификаты, теги, CI runs и не включает billing/production.
Не присылайте JSON, `.p8`, `.p12`, пароли или base64 в чат.

## Android U2 — полностью с Windows

**Выполнено 19.10.2026:** Play API Access Probe — **PASS**: OAuth 200,
временный edit create 200, GET 200, delete 204. Identity сервисного аккаунта и
package `com.auyltech.prokat` совпали; изменений выпусков не было.
Владелец подтвердил создание всех **7 GitHub Secrets и 2 Variables**, настройку
Internal Testing (`PROKAT developers`, 2 тестировщика) и исторический максимум
versionCode **18** на эту дату. Новый аккаунт/ключ и повторный probe не нужны.
Фактические AAB-сборка, подпись, upload и содержимое GitHub Secrets остаются
**NOT VERIFIED до отдельно разрешённого U4**. Production gates закрыты.
Подробные [результаты и ограничения](VERIFICATION.md#u2-play-api-access-probe--2026-10-19).
Ниже сохранена исходная процедура настройки; не повторяйте выполненные шаги.

1. В [Play Console](https://play.google.com/console/) откройте PROKAT, проверьте
   package `com.auyltech.prokat`. Последний подтверждённый исторический максимум
   versionCode — **18**, но это не утверждение о сегодняшнем состоянии магазина.
   Откройте **Test and release → App bundle explorer**, Production и тестовые
   треки: проверьте, не загружены ли новые draft/inactive/testing builds.
   Зафиксируйте свежий максимум. Не выбирайте 19 автоматически.
2. В **Testing → Internal testing → Testers** подтвердите существующую группу
   тестеров и opt-in ссылку. Если группы нет, владелец настраивает её один раз.
   Проверьте незавершённые agreements/policy declarations и основной язык
   `ru-RU`, `en-US` или `kk`. Состояние Managed publishing только прочитайте.
3. В [Cloud API Library](https://console.cloud.google.com/apis/library/androidpublisher.googleapis.com)
   выберите существующий проект и включите **Google Play Android Developer API**.
   Billing не подключайте. **IAM & Admin → Service Accounts → Create service
   account**: `prokat-play-ci`, без Cloud Owner/Editor. Если подходящий отдельный
   аккаунт уже есть, используйте его, не создавайте дубликат.
4. В Play **Users and permissions → Invite new user → App permissions → Add app**
   добавьте email сервисного аккаунта **только к PROKAT**. Права:
   **View app information (read-only)** и **Release apps to testing tracks**.
   Не выдавайте production, Admin, Finance, Manage store presence/tester lists.
   Google не имеет Internal-only IAM scope: право охватывает и Open/Closed;
   выбор `internal` дополнительно фиксируется кодом.
5. После разрешённого владельцем создания credentials: Service Account →
   **Keys → Add key → Create new key → JSON**. Сохраните вне Git в защищённую
   папку. Если policy запрещает JSON, остановитесь, не ослабляйте её.
   Не отправляйте JSON сообщением: для проверки агенту достаточно локального
   пути и отдельного разрешения на конкретный access probe.
6. В [GitHub → Settings → Secrets and variables → Actions](https://github.com/auyltech/prokat/settings/secrets/actions)
   создайте Repository Secrets:
   `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`,
   `ANDROID_KEY_PASSWORD`, `PLAY_SERVICE_ACCOUNT_JSON_BASE64`,
   `GOOGLE_SERVICES_JSON_BASE64`, `MAPBOX_PUBLIC_TOKEN`.
   Во **Variables**: `ANDROID_UPLOAD_CERT_SHA256` (уже проверенный публичный
   fingerprint, MATCH / alias `upload`) и `PLAY_HISTORICAL_MAX_BUILD`
   (свежеподтверждённый максимум, не ниже 18).
   Источники каждого значения и безопасное копирование в clipboard —
   [ANDROID_SETUP](ANDROID_SETUP.md#exact-github-configuration).
   `PRODUCTION_PUBLISHING_ENABLED` оставьте отсутствующим/false.
7. Сообщите: package, свежий максимум/production version, primary locale,
   готовность Internal, Managed publishing, имена настроек и выданных прав.
   Ограниченный probe уже выполнен 19.10.2026: временный edit создан/прочитан/удалён,
   без upload/track update/commit. Вместо более широкого snapshot `play_access.rb`
   использован одноразовый скрипт с закреплённым SDK. Probe не доказывает право
   загрузки AAB; не повторяйте его без отдельного разрешения.
   Временный JSON удаляется после проверки и защищённого backup; единственный
   оригинал upload keystore не удаляйте. **U2 не разрешает RC.**

## iOS U3 — Windows, кроме явно указанных Mac-действий

1. После предоставления прав откройте [App Store Connect → Apps](https://appstoreconnect.apple.com/apps).
   В существующем PROKAT → **App Information** запишите числовой Apple ID,
   bundle `com.auyltech.prokat`, primary locale (`ru` / `en-US` / `en-GB`).
   Team — `VT7KXG8NBR`. В **TestFlight / Build Uploads** проверьте всю историю,
   включая in-flight/failed, и подтвердите максимальный build number.
   Нужны действующая membership и принятые Account Holder agreements.
2. Используйте подходящий существующий Team API Key или попросите Account
   Holder/Admin создать один: **Users and Access → Integrations → App Store
   Connect API → Team Keys → Generate API Key**, имя `prokat-codemagic`, роль
   **App Manager**, не Admin/Finance. При первом доступе Account Holder выбирает
   **Request Access**. Скачайте `.p8` один раз; сохраните с Key ID и Issuer ID в
   защищённый backup. Создание ключа выполняет владелец, не агент. Team Key
   действует на все приложения team; app-scoped ограничения для него нет.
3. В **Codemagic Personal Settings → Integrations → Developer Portal → Manage
   keys / Add key** добавьте тот же `.p8`, Key ID и Issuer ID с именем интеграции
   **`prokat-app-store`**. Не создавайте платную Team ради названия UI-раздела.
   В PROKAT → **Environment variables**, группа **`prokat-ios-release`**, задайте
   для custom CLI три Secret-переменные того же ключа:
   `APP_STORE_CONNECT_PRIVATE_KEY` (содержимое `.p8`, не base64),
   `APP_STORE_CONNECT_KEY_IDENTIFIER`, `APP_STORE_CONNECT_ISSUER_ID`.
   Это один ключ, не три новых credentials. Из Windows копируйте содержимое
   через `Set-Clipboard -Value ([IO.File]::ReadAllText('C:\secure\AuthKey.p8'))`,
   вставьте прямо в Secret и очистите clipboard: `Set-Clipboard -Value ''`.
4. Владелец уже записал в Codemagic group `prokat-ios-release`, не в Git:
   `APP_STORE_APP_ID` `6817078475`, `IOS_HISTORICAL_MAX_BUILD` `17`,
   `TESTFLIGHT_GROUP` `AuylTech Test Team`. Не создавайте вторую группу
   `PROKAT Internal`. `GOOGLE_SERVICE_INFO_PLIST_BASE64` и `MAPBOX_PUBLIC_TOKEN`
   этой записью не подтверждены. Confidential values остаются Secret;
   production gate отсутствует/false.
5. Указанная группа — `AuylTech Test Team`. Для RC она должна быть единственной
   внутренней группой с этим именем. Внешняя группа не подходит. API ещё не
   активирован, поэтому probe это не подтвердил. Export compliance закрыт отдельно
   подтверждением владельца от 2026-10-20; это не подтверждает API/group probe.
6. **Codemagic signing:** подходящей Apple Distribution identity для PROKAT в
   Codemagic пока нет. На домашнем Mac её тоже нет: в login keychain только
   сертификаты другой команды. Не создавайте и не отзывайте сертификаты на Mac.
   После активации App Store Connect API владельцем подпись планируется как
   Codemagic API-managed для `com.auyltech.prokat`, team `VT7KXG8NBR`, App Store.
   Portal Identifier должен иметь Push Notifications и Associated Domains.
   Пока identity нет, U3 signing не закрыт.
7. **Export compliance закрыт 2026-10-20:** владелец подтвердил только Казахстан,
   France: Not Available, стандартное шифрование вне Apple OS и отсутствие запроса
   документов после Save. В Info.plist установлен Boolean
   `ITSAppUsesNonExemptEncryption=false`; [основание и ограничения](APPLE_EXPORT_COMPLIANCE.md).
   Повторная проверка нужна при изменении SDK, криптографии или географии.
   Production listing/screenshots/App Review readiness готовятся перед U5,
   если они не нужны для текущей первичной регистрации приложения.
8. **Mac dependency check выполнен 2026-10-20:** CocoaPods 1.16.2, оба SwiftPM
   lock и неподписанный iOS release на локальном Xcode 26.3. Повторять
   [IOS_DEPENDENCIES](IOS_DEPENDENCIES.md) не нужно. Distribution private key
   PROKAT в Keychain этого Mac нет, поэтому `.p12` оттуда экспортировать нельзя.
   Xcode 26.6 локально не устанавливался; в Codemagic пин 26.6 сохранён.
9. После настройки можно отдельно разрешить локальный GET-only API probe
   `python tool/release/ios_store.py access`. Он использует те же 3 API env vars,
   `APP_STORE_APP_ID`, `IOS_HISTORICAL_MAX_BUILD`, `TESTFLIGHT_GROUP`; не требует
   CI/tag/IPA/Mac и ничего не публикует. Загружайте `.p8` в память локального
   процесса из защищённого файла, не через текст команд/чат; агент подготовит
   точный запуск для предоставленного локального пути. 403/timeout/неполная
   pagination — BLOCKED / UNKNOWN, не «сборок нет».
10. Сообщите только Apple ID, team/bundle, primary locale, максимум build,
    имя внутренней группы, наличие integration/имён env vars, срок и тип profile,
    совпадение certificate в Codemagic и результат Mac lock-проверки. Не содержимое
    credentials. **U3 не разрешает сборку или публикацию.**

## Перед запросом U4

Нужны закрытые U1 (private/billing/Personal eligibility), U2/U3 и их probes,
согласованные native locks/export compliance, готовые Git notes (`ready: true`),
утверждённый HEAD свежего main, версия из его pubspec и общий build counter.
После разрешения запускают четыре CLI-команды из памятки, не ручные теги.
Не нужны merge или release tags для account probes. После этого можно запросить
отдельное U4; production gate и права production остаются закрытыми до U5.

Источники: [Play API](https://developers.google.com/android-publisher/getting_started),
[Play permissions](https://support.google.com/googleplay/android-developer/answer/9844686?hl=en),
[Apple Team Keys](https://developer.apple.com/help/app-store-connect/get-started/app-store-connect-api),
[Codemagic signing](https://docs.codemagic.io/yaml-code-signing/signing-ios/).
