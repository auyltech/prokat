# Однократная настройка владельцем PROKAT

Статус: **PENDING USER ACTION, начиная с U1**. Инструкции следующих gates
подготовлены заранее; это не разрешение переходить к публикации. Не отправляйте
в чат пароли, keystore, `.p8`, `.p12`, JSON credentials или их base64.

Для первого прохода используйте [короткие инструкции U2/U3](OWNER_CHECKLIST.md).
До получения административных прав создавать credentials не требуется.

Обновление 2026-10-16: владелец подтвердил техническое U1: GitHub App одобрен,
Personal без billing, 500 M2 минут / 0 использовано, UI triggers/schedules
выключены; YAML и оба workflows видны, после push сборок нет. Видимость private,
GitHub Billing и применимость Personal Free ещё PENDING. Подготовка A2/A3/A4
разрешена отдельно, реальные CI builds по-прежнему запрещены.

## STOP: U1 — Подключение GitHub и Codemagic без оплаты

1. Уже выполнено: аудит, ветка `feat/tag-only-mobile-release`, release tooling,
   предварительные Android/Codemagic workflows, локальные проверки. Полная
   таблица результатов — [VERIFICATION.md](VERIFICATION.md).
2. Остановка нужна: у агента нет авторизованного GitHub CLI/Codemagic и права
   принимать финансовые условия. Доступность Personal Free для коммерческого
   проекта организации нельзя доказать исходным кодом.
3. Откройте [Codemagic signup](https://codemagic.io/signup), войдите через свой
   GitHub. Выберите **Personal account**, не Team. В меню выбора аккаунта
   должен быть именно личный аккаунт; GitHub-репозиторий при этом остаётся в
   организации `auyltech` и приватным.
4. Откройте **Billing** в левом меню выбранного Personal account. Должны быть
   Free, 500 M2 minutes/month, одна параллельная сборка, billing не включён.
   Не нажимайте Enable billing, не вводите карту, не активируйте trial платного
   плана/дополнительную concurrency. Бесплатные минуты относятся только к M2.
   При уже включённом billing остановитесь: агент не будет менять его сам.
5. Уточните применимость Free: [документация](https://docs.codemagic.io/billing/pricing/)
   описывает hobby/indie/PoC, а [FAQ](https://docs.codemagic.io/getting-started/faq/)
   — personal/hobby; Team не получает бесплатные минуты. Если UI/условия не
   дают однозначного разрешения для PROKAT, напишите сами через
   [Codemagic contact](https://codemagic.io/contact/) или in-app support:

   > I am the sole CI user for a commercial Flutter app, PROKAT. The private
   > GitHub repository belongs to the auyltech organization. May I use the
   > Personal Free plan's 500 macOS M2 minutes for this project without enabling
   > billing? Will builds stop at the free quota with billing disabled?

   Если требуется платный Team, продолжение iOS **BLOCKED**. Не обходите это
   фиктивным типом аккаунта. YAML не умеет ограничивать выставление счёта.
6. **Applications → Add application → GitHub**. Используйте GitHub App
   Codemagic CI/CD, **Only select repositories → auyltech/prokat**.
   Если требуется разрешение организации, владелец `auyltech` подтверждает
   установку в [GitHub organization installations](https://github.com/organizations/auyltech/settings/installations).
   Не включайте общий OAuth-доступ ко всем private repositories.
7. Для checkout нужны чтение Contents/Metadata и webhook tag-push events.
   Permissions приложения задаются провайдером, пользователь не может всегда
   переключать каждый scope: прочитайте список на экране установки. Запись
   Checks/Statuses может запрашиваться для индикации результата; pipeline не
   требует записи source, secrets, releases, issues, deployments, управления
   billing или Actions. Зафиксируйте фактически запрошенные дополнительные
   права; не заявляйте, что установка read-only, если экран показывает больше.
   Не выдавайте отдельный PAT с широким `repo`/`workflow` scope.
8. Выберите приложение **prokat**, тип Flutter; включите конфигурацию
   **codemagic.yaml / Switch to YAML configuration**. Для просмотра YAML можно
   выбрать рабочую ветку `feat/tag-only-mobile-release`; не нажимайте Start new
   build. Если ветка ещё не опубликована, сообщите агенту: merge не нужен для
   простого подключения и просмотра YAML в feature branch.
9. **App settings → Build triggers / Webhooks**: отключите старые Flutter
   Workflow Editor branch/PR builds, auto-build после подключения, schedules.
   Убедитесь, что нет второго workflow или приложения с broad triggers.
   В YAML ровно два workflow: `ios-rc` с `rc/ios/v*` и `ios-production` с
   `ios/v*`; events только `tag`. Не включайте push/pull_request events в YAML.
   Не задавайте CM_TAG, CM_COMMIT, CM_BUILD_ID, CM_PULL_REQUEST или CM_REPO_SLUG
   вручную в environment groups: это контекст провайдера, а не настройки релиза.
   Webhook GitHub может получать обычные Push events — это транспорт; именно
   `triggering.events: [tag]` и tag_patterns определяют запуск Codemagic.
10. **Settings → Webhooks** репозитория:
    [GitHub webhooks](https://github.com/auyltech/prokat/settings/hooks).
    Проверьте одно ожидаемое подключение Codemagic; при GitHub App часть событий
    управляется installation и не выглядит как обычный webhook. Не добавляйте
    дубликат вручную. Без публикации/тегов проверьте статус подключения и
    доступность YAML. Доставку реального tag webhook проверим только на U4.
11. **GitHub repository → Settings → Actions → General**:
    [страница](https://github.com/auyltech/prokat/settings/actions).
    Workflow permissions: **Read repository contents and packages permissions**;
    создание/одобрение PR workflow-ами выключено. Не включайте secrets для
    fork PR. Убедитесь в **Private** на Settings → General; видимость не меняйте.
    Существующие PR quality checks сохраняются, они не собирают релизные AAB/IPA.
12. Владелец организации открывает **Settings → Billing & licensing → Budgets
    and alerts**: [billing](https://github.com/organizations/auyltech/settings/billing).
    Проверьте GitHub Free и остаток общей квоты Actions; текущий справочник
    указывает 2,000 standard runner minutes/month, 500 MB artifact storage.
    Создайте/проверьте бюджет Actions с блокировкой **Stop usage when budget
    limit is reached**, минимально допустимым пределом для нулевых платных
    расходов. Если UI допускает $0 — используйте $0; положительный бюджет не
    является нулевым лимитом. При невозможности $0 не считайте alerts hard cap.
    Без payment method GitHub блокирует использование после квоты. Если карта
    нужна другим сервисам, проверьте именно блокирующий Actions budget. Cache
    storage также не должна автоматически докупаться; не включайте paid cache
    расширения/large runners. Если блокировку доказать нельзя, сообщите это.
13. На U1 секреты магазинов не нужны. `PRODUCTION_PUBLISHING_ENABLED` оставьте
    отсутствующей/`false` у обоих провайдеров. Не создавайте RC/production-теги.
14. Проверка результата: репозиторий private, Codemagic показывает YAML и M2
    Free quota, billing disabled, branch/PR/schedule triggers выключены, реальных
    сборок не было. Отсутствие запусков по push подтвердим доступной историей;
    не создавайте технический tag или ручной build ради проверки.
15. Сообщите: «U1 выполнен», тип плана/остаток квоты, подтверждение Free
    eligibility для этого проекта, billing disabled/Actions blocking budget,
    App ID Codemagic или ссылку приложения, найденные UI-trigger настройки.
    Секреты не присылайте. При необходимости выполните `gh auth login --web`
    на своей машине (GitHub CLI доступ нужен для read-only проверок).
16. Следующий шаг агента: безопасно проверить доступные настройки/историю,
    завершить A2 и перейти к U2. Код A2/A3 уже подготовлен независимо от аккаунтов.

## STOP: U2 — Google Play, существующий upload key и API

Точный актуальный checklist, включая **7 Secrets / 2 Variables**, проверку
публичного upload certificate и команду access probe:
[ANDROID_SETUP.md](ANDROID_SETUP.md). Указанные ниже действия подготовки
не означают разрешения upload/CI build; эти проверки остаются на U4.

1. В [Play Console](https://play.google.com/console/) выберите PROKAT.
   **Protected with Play → Play Store distribution → Go to Play app signing**
   (прежний UI: App integrity → App signing): package должен быть
   `com.auyltech.prokat`. Запишите **Upload key certificate SHA-256**, отдельно
   отличайте App signing certificate (он нужен для App Links). Ничего не
   сбрасывайте и не меняйте. Убедитесь, что локальный существующий keystore
   принадлежит этому upload certificate. Для проверки с запросом пароля:

   Скачивание сертификата не обязательно. Скопируйте SHA-256 из **Upload key
   certificate** и сравните с существующим keystore (пароль вводится скрыто,
   не в командной строке):

   ```powershell
   python tool/release/verify_upload_key.py --keystore .\android\app\upload-keystore.jks --alias 'upload' --expected-sha256 'REPLACE_WITH_PUBLIC_PLAY_UPLOAD_SHA256'
   ```

   Текущая локальная проверка уже выполнена: **MATCH**, alias `upload`.
   Keystore и key.properties не изменены; пароль не выводился. Режим
   `--play-certificate` остаётся необязательной альтернативой.

2. **Test and release → App bundle explorer**, Production и Internal testing:
   запишите максимальный **когда-либо загруженный** versionCode, включая draft,
   inactive, testing и не опубликованные версии; текущую production versionName,
   internal track readiness и статус review. Это не обязательно pubspec +18.
   Если историю подтвердить невозможно, не выставляйте floor «на глаз».
   У новой app record проверьте, разрешён ли API initial upload и завершён ли
   onboarding. Если требуется первая загрузка через UI — отдельно организуем её
   после разрешения U4; U2 сам по себе загрузку не разрешает.
3. **Grow users → Store presence → Main store listing**: primary language должна
   быть ru-RU/en-US/kk, либо агент добавляет явную соответствующую mapping до RC.
   RU/EN/KK должны быть настроены как поддерживаемые store localizations.
4. Выберите существующий Google Cloud project (не обязательно Firebase project)
   либо создайте обычный бесплатный project. В
   [Google Cloud API Library](https://console.cloud.google.com/apis/library/androidpublisher.googleapis.com)
   включите **Google Play Android Developer API**. Не подключайте billing.
5. [IAM & Admin → Service Accounts](https://console.cloud.google.com/iam-admin/serviceaccounts):
   создайте `prokat-play-ci`. Не выдавайте Owner/Editor проекта; для вызова Play
   API не нужна широкая Cloud IAM role. **Keys → Add key → Create new key → JSON**.
   Скачайте в локальную закрытую папку вне Git. Если organization policy запрещает
   JSON keys, не ослабляйте её: потребуется отдельное решение identity на U2.
6. Play Console **Users and permissions → Invite new user**: email созданного
   service account. **App permissions → Add app → PROKAT**. Выдайте чтение app
   information (**View app information (read-only)**) и **Release apps to testing
   tracks**. Manage testing tracks/tester lists и Manage store presence не нужны:
   pipeline не меняет tester lists/store listing; testing-release permission
   включает notes для непроизводственных релизов. Тестовую группу один раз
   настраивает владелец. Google не выделяет Internal-only permission: это право
   также охватывает Open/Closed. RC destination жёстко ограничен `internal` в коде.
   До U5 **Release to production, exclude devices, and use Play App Signing**
   не выдавайте. Нет финансовых permissions, orders, admin или доступа ко всем
   приложениям. Для отправки production эта дополнительная app permission
   понадобится только после U5. Права могут применяться с задержкой.
7. На GitHub откройте
   [Settings → Secrets and variables → Actions](https://github.com/auyltech/prokat/settings/secrets/actions).
   В Repository secrets сохраните значения из таблицы ниже. Base64 — кодировка,
   а не шифрование. Пример копирования без печати содержимого в терминал:

   ```powershell
   Set-Clipboard -Value ([Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path 'C:\secure\play-ci.json'))))
   ```

   Сразу вставьте в Secret → Add secret; затем `Set-Clipboard -Value ''`.
   Аналогично закодируйте keystore и native Firebase JSON, заменяя путь.

| GitHub secret | Источник | Проверка / локальная копия |
| --- | --- | --- |
| `PLAY_SERVICE_ACCOUNT_JSON_BASE64` | JSON ключ prokat-play-ci | API preflight на разрешённом RC; временную JSON удалить после защищённой резервной копии |
| `ANDROID_KEYSTORE_BASE64` | Существующий upload-keystore | SHA256 должен совпасть с Play Upload certificate; исходный key хранить в password manager/офлайн backup, не удалять единственную копию |
| `ANDROID_KEYSTORE_PASSWORD` | Существующий пароль keystore | Подпись + fingerprint проверятся до upload; не менять пароль/key |
| `ANDROID_KEY_ALIAS` | Существующий alias | Проверка keytool и сборка |
| `ANDROID_KEY_PASSWORD` | Существующий пароль ключа | Проверка подписанной AAB |
| `GOOGLE_SERVICES_JSON_BASE64` | Firebase project prokat-bfbec → Project settings → Android app → google-services.json | Проверяется package, project, Firebase App ID; временную скачанную копию можно удалить |
| `MAPBOX_PUBLIC_TOKEN` | Mapbox → Access tokens → существующий public `pk.*` | Только публичный runtime token, не `sk.*`; временную копию удалить |

8. Во вкладке **Variables** задайте `ANDROID_UPLOAD_CERT_SHA256` (64 hex, можно
   с `:`) и `PLAY_HISTORICAL_MAX_BUILD` (свежеподтверждённый максимум, не ниже
   исторически подтверждённого 18). Ноль для PROKAT недопустим. Live API всё равно
   проверяется до сборки и до upload. Это не секреты. Не включайте production gate.
9. Проверьте dashboard на незавершённые agreements, Data safety, privacy,
   reviewer app access, target API и требования тестирования/production access.
   Проверить **Managed publishing**: когда он включён, commit release может
   требовать ручного выпуска изменений; нельзя обещать штатную автоматическую
   публикацию. Не меняйте production-настройки сейчас — сообщите их для U5.
10. Сообщите «U2 выполнен», package, текущие store версии/build maxima, совпадение
    fingerprint, readiness internal track, primary locale, состояние managed
    publishing и список имён сохранённых secrets/variables. Никаких значений
    credentials. После отдельного согласования access probe агент проверит API
    через временный edit без upload/commit, затем продолжит A3/U3.

## STOP: U3 — Apple и signing в Codemagic

1. [Apple Developer → Membership](https://developer.apple.com/account/): действующая
   membership, Team ID `VT7KXG8NBR`. Account Holder принимает действующие agreements.
   Если требуется покупка аккаунта, бюджет инфраструктуры не покрывает этот сбор:
   агент не покупает membership и не включает billing.
2. [App Store Connect → Apps](https://appstoreconnect.apple.com/apps): откройте
   существующий PROKAT, **App Information**. Bundle `com.auyltech.prokat`; запишите
   числовой Apple ID и primary locale. Проверьте actual production version,
   TestFlight builds и **Build Uploads**, включая failed/in-flight. Подтвердите
   глобальный максимум build number. Мы выбираем новый номер даже после неудачи;
   Apple допускает reuse некоторых failed uploads, но эта система его не делает.
   Если старые номера уже больше 9999/имеют сложную схему — сообщите до RC.
3. Primary locale должна быть ru/en-US/en-GB. Другие обязательные localizations
   требуют явного расширения mapping; `kk` Apple metadata не поддерживает.
   Казахский перевод сохраняем в Git, fallback App Store — английский.
4. **Users and Access → Integrations → App Store Connect API → Team Keys → +**:
   имя `prokat-codemagic`, роль **App Manager** для publishing. Запишите Issuer ID,
   Key ID, скачайте `.p8` **один раз** в password manager/закрытую резервную копию.
   Account Holder/Admin может потребоваться для создания/разрешения API access.
   Team API keys применяются ко всем приложениям Apple team: app-scoped доступ
   для такого ключа обещать нельзя. Не давайте Finance/Admin ради публикации.
5. Codemagic Personal **Settings → Integrations → Developer Portal → Connect**:
   Integration/API key name ровно **`prokat-app-store`**, Issuer ID, Key ID, `.p8`.
   Подключение используется native CLI для publishing и работы с existing signing.
   Наш custom CLI использует `APP_STORE_CONNECT_PRIVATE_KEY`,
   `APP_STORE_CONNECT_KEY_IDENTIFIER`, `APP_STORE_CONNECT_ISSUER_ID`. Сохраните
   те же значения как Secret variables группы ниже, чтобы не зависеть от способа
   экспорта integration. Это один ключ; не создавайте второй и не печатайте `printenv`.
6. [Apple Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/):
   Identifier `com.auyltech.prokat` должен иметь **Push Notifications** и
   **Associated Domains**. Нужен действующий **App Store distribution profile**,
   не Development/Ad Hoc; APNs environment production, team как выше, domains:
   `prokat-bfbec.web.app`, `prokat-bfbec.firebaseapp.com`, `open.prokat.auyltech.kz`.
   APNs auth key существующего Firebase push backend не меняйте.
7. В Codemagic **Code signing identities → iOS certificates / Provisioning
   profiles** загрузите подходящие существующие distribution `.p12` (с private key)
   и профиль. Если существующие credentials уже в Codemagic, используйте их.
   Публичный `.cer` сам по себе не содержит private key. Если existing private
   key хранится только на прежнем Mac: однократно откройте **Keychain Access →
   login → My Certificates**, раскройте нужный Apple Distribution certificate,
   убедитесь в наличии его private key, выберите пару → **File → Export Items →
   Personal Information Exchange (.p12)**. Задайте пароль экспорта, загрузите
   `.p12` и пароль непосредственно в Codemagic, сохраните защищённый backup.
   Это перенос существующей identity, без генерации/замены ключа; Mac не нужен
   для последующих сборок. Существующий profile скачивается в Developer Portal
   **Profiles → нужный App Store profile → Download**.
   Установите соответствие
   `app_store` и bundle identifier, используемое `environment.ios_signing`.
   Pipeline применяет profiles через `xcode-project use-profiles`; команд создания
   сертификатов, `--create`, отзыва или удаления stale profiles в нём нет.
   Если подходящей identity нет, **STOP на U3**: опишите отсутствие и согласуйте
   необходимое однократное создание с владельцем, не заменяя действующий key.
8. **App → Environment variables**: группа **`prokat-ios-release`**, Secret для
   confidential values. Добавьте:

| Переменная | Источник и назначение |
| --- | --- |
| `GOOGLE_SERVICE_INFO_PLIST_BASE64` | Firebase → Project settings → iOS com.auyltech.prokat → GoogleService-Info.plist, base64 через PowerShell как на U2 |
| `MAPBOX_PUBLIC_TOKEN` | Тот же public pk token |
| `APP_STORE_APP_ID` | Владелец записал в Codemagic `6817078475`; это не bundle ID |
| `IOS_HISTORICAL_MAX_BUILD` | Владелец записал `17`; это пол, не замена свежей проверки истории перед upload |
| `TESTFLIGHT_GROUP` | Владелец записал `AuylTech Test Team`; не создавайте параллельную `PROKAT Internal` |

   Три API environment aliases из шага 5 тоже Secret; это тот же ключ, который
   подключён integration. `PRODUCTION_PUBLISHING_ENABLED` пока отсутствует/false.
   `.p8`/`.p12` и пароли не хранятся в Git; `.p8` и `.p12` нельзя удалять из
   единственной резервной копии. Временные upload-копии удалите после проверки.
9. **TestFlight → Internal Testing → +** создайте внутреннюю группу из
   существующих App Store Connect users. Запишите точное имя в TESTFLIGHT_GROUP.
   RC публикуется в эту группу; внешние тестеры/beta review не требуются.
10. **iOS dependencies закрыты 2026-10-20 на домашнем Mac.** CocoaPods metadata
    приведена к 1.16.2 без смены графа; оба `Package.resolved` строго разрешены
    и не изменились. Неподписанный `flutter build ios --release --no-codesign`
    прошёл на Xcode 26.3. Подписанного IPA нет. Образ Codemagic остаётся
    Xcode 26.6 и отдельно не запускался. Повторять
    [IOS_DEPENDENCIES.md](IOS_DEPENDENCIES.md) не нужно. Production signing
    не менялся.
11. App Store initial setup: category, screenshots, privacy URL/Data Privacy,
    age rating, content rights, reviewer account/contact, availability/pricing и
    export compliance должны быть заполнены. Export compliance закрыт 2026-10-20:
    владелец подтвердил только Казахстан, France: Not Available, стандартное
    шифрование вне Apple OS и Save без запроса документов. В Info.plist установлен
    Boolean `ITSAppUsesNonExemptEncryption=false`. См. [решение и ограничения](APPLE_EXPORT_COMPLIANCE.md):
    при изменении SDK, криптографии или географии повторить проверку. Новые legal
    agreements или требования review могут потребовать отдельных действий позднее.
12. После отдельного разрешения можно выполнить с Windows
    `python tool/release/ios_store.py access`: GET-only, без CI/tag/IPA/publishing.
    Проверяются app identity, `/v1/builds`, `/v1/apps/<id>/buildUploads` и внутренняя
    beta group. 403/unsupported/timeout означает UNKNOWN, а не отсутствие сборок.
    Наличие ключа или успешный probe не доказывают signing/upload permission.
    IPA validation отдельно проверит реальные signing entitlements.
13. В **Billing** повторно проверьте Free M2 и **concurrency = 1**: она также
    сериализует RC/production. Не подключайте второй платный worker. Никаких IPA
    artifacts в YAML нет; только ZIP dSYM при неуспешной отправке символов.
14. Сообщите «U3 выполнен», Apple ID/team/bundle/primary locale, текущие версии
    и максимум, integration name, наличие existing signing identities, группу
    тестеров, результат подготовки native lock и решение export compliance.
    Без ключей. Агент завершит A3/A4; следующий gate — разрешение RC на U4.

## STOP: U4 — Разрешение на точную RC-публикацию

До этого gate не создаём теги и не делаем реальные store writes.

1. Агент предоставляет exact approved commit SHA, версии/новые platform build
   numbers, notes, readiness internal/TestFlight и результаты локальных проверок.
2. Владелец явно разрешает конкретные `rc/android/...` и `rc/ios/...`, их SHA и
   push. Разрешение на один тест не разрешает неограниченную серию новых тегов.
3. Если нужна интеграция в dev/main — владелец отдельно разрешает merge;
   предварительно готовим diff/PR. Скрытого merge нет. RC можно собрать из
   утверждённого feature commit с workflow-файлами; main ancestry нужна только
   production. GitHub tag workflow берётся из tagged commit, Codemagic — тоже.
4. После разрешения агент проверяет SHA и exact remote refs, создаёт annotated
   tags, отправляет только разрешённые refs, наблюдает оба provider runs.
5. При неопределённом upload не нажимайте rerun/rebuild. Сначала магазин и
   [recovery runbook](RELEASE_RUNBOOK.md). Новые теги — по новому разрешению.
6. Для A5 сохраняем run IDs/URLs, version/build/commit, фактические состояния
   Internal/TestFlight, notes, signing fingerprints, symbol upload, расход минут.
   Принятая загрузка не равна доступной сборке; CI success не равен publication.

## STOP: U5 — Однократное разрешение production

Вход: успешный A5 обеих платформ, подтверждённые API/signing/notes/symbols и
отсутствие нерешённых блокеров. Агент предъявляет доказательства, риски, расходы
и exact команды production-тегов. Владелец явно разрешает активацию production.

1. Только после разрешения: Play service account получает app-specific
   **Release to production**. Согласованно отключите Managed publishing, если
   цель — автоматический выпуск после одобрения Google; это production-настройка
   и её не меняют на U2. Existing managed publishing сохраняем до разрешения.
2. GitHub Repository Secret `PRODUCTION_PUBLISHING_ENABLED=true`.
3. Codemagic `prokat-ios-release`: Secret `PRODUCTION_PUBLISHING_ENABLED=true`.
   Ни один другой workflow/channel не должен переопределять gate.
4. После этого production-теги автоматические, без обязательного approval на
   каждый запуск. Android: completed production release с отправкой на Google
   review. iOS: App Review submission и release_type AFTER_APPROVAL.
5. **Первый production-тег создаёт сам владелец.** Агент не создаёт его в рамках
   активации U5. Коммит должен быть явно утверждён и достижим из origin/main.
6. Аварийное отключение следующих production attempts: установить gate=false
   у обоих провайдеров. Это не отменяет уже отправленный review/начатый run;
   проверьте их состояние отдельно. Не отзывайте signing keys ради остановки CI.

Официальные инструкции: [Play API setup](https://developers.google.com/android-publisher/getting_started),
[Play permissions](https://support.google.com/googleplay/android-developer/answer/9844686),
[Codemagic GitHub App](https://docs.codemagic.io/partials/github/),
[Apple API scope](https://developer.apple.com/help/app-store-connect/get-started/app-store-connect-api),
[Codemagic signing](https://docs.codemagic.io/yaml-code-signing/signing-ios/).
