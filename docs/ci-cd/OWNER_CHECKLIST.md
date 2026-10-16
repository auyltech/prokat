# Короткие инструкции U2 / U3

Состояние: административные доступы ожидаются. **Сейчас ничего не создавайте**:
инструкции предназначены для владельца после получения прав. Агент не создаёт
секреты, сертификаты, теги, CI runs и не включает billing/production.
Не присылайте JSON, `.p8`, `.p12`, пароли или base64 в чат.

## Android U2 — полностью с Windows

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
   Затем отдельно согласуем `play_access.rb`: временный edit создаётся/удаляется,
   но нет upload/track update/commit. Probe не доказывает право загрузки AAB.
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
4. В той же группе добавьте `GOOGLE_SERVICE_INFO_PLIST_BASE64` (Firebase
   prokat-bfbec, iOS app), `MAPBOX_PUBLIC_TOKEN` (существующий public `pk.*`),
   `APP_STORE_APP_ID` (числовой Apple ID), `IOS_HISTORICAL_MAX_BUILD` и
   `TESTFLIGHT_GROUP` (точное имя из следующего шага). Confidential values —
   Secret; production gate отсутствует/false. Пакеты/версии инструментов уже в Git.
5. **TestFlight → Internal Testing → +**: используйте/создайте одну внутреннюю
   группу `PROKAT Internal` из существующих App Store Connect users. Запишите
   точное имя в `TESTFLIGHT_GROUP`; внешняя группа не подходит. Подтвердите
   доступ тестеров и требуемую Apple test information/export compliance.
   Missing/ambiguous/external group блокирует preflight до upload.
6. **Codemagic → Code signing identities**: загрузите подходящие существующие
   Apple Distribution `.p12` с private key/паролем и App Store provisioning
   profile либо используйте уже сохранённые identities. Portal Identifier должен
   иметь Push Notifications и Associated Domains. Profile: App Store, нужные
   bundle/team, production APNs, не expired/Development/Ad Hoc. Список domains и
   подробные экраны — [MANUAL_SETUP U3](MANUAL_SETUP.md#stop-u3--apple-и-signing-в-codemagic).
   Автовыбор/установка существующих identities выполняется pipeline; новый
   сертификат не генерируйте и старый не отзывайте. Если подходящей пары нет,
   STOP U3 для отдельного решения владельца, а не автоматическая замена ключа.
7. Владелец должен подтвердить применимую export-compliance декларацию для
   `ITSAppUsesNonExemptEncryption`: сейчас её нет в Info.plist. Агент внесёт
   согласованное значение в Git; без решения автоматическая отправка блокируется.
   Production listing/screenshots/App Review readiness готовятся перед U5,
   если они не нужны для текущей первичной регистрации приложения.
8. **Mac действительно нужен**: один раз выполнить
   [IOS_DEPENDENCIES](IOS_DEPENDENCIES.md), согласовать CocoaPods metadata
   1.17.0 с CI 1.16.2 и проверить оба SwiftPM locks. Это только dependency
   resolution, без build/sign/publishing. Дополнительно Mac нужен, только если
   существующий distribution private key хранится исключительно в его Keychain:
   экспортировать существующую пару в `.p12` по MANUAL_SETUP U3. Если `.p12`
   уже есть, этот шаг не нужен. Все остальные настройки выше доступны с Windows.
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
явно выбранный SHA и новые platform build numbers. Обновления пока локальные:
их доставка в origin требует отдельного разрешения на branch-only push.
Не нужны merge или release tags для account probes. После этого можно запросить
отдельное U4; production gate и права production остаются закрытыми до U5.

Источники: [Play API](https://developers.google.com/android-publisher/getting_started),
[Play permissions](https://support.google.com/googleplay/android-developer/answer/9844686?hl=en),
[Apple Team Keys](https://developer.apple.com/help/app-store-connect/get-started/app-store-connect-api),
[Codemagic signing](https://docs.codemagic.io/yaml-code-signing/signing-ios/).
