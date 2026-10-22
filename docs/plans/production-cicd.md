# Production CI/CD PROKAT — план доведения прямых Production-релизов

Статус: **этап 0, ревизия 4 (после четвёртого аудита). Реализация не начата.**
Ветка: `feat/production-cicd-hardening` от `origin/dev` `6f0aa0e506a0f4c74745d4e9fa7196032207b82c`.
Что исправлено в ревизиях 2–4 — раздел 19.

План не разрешает публикацию, теги, push, merge, изменение секретов или консолей
магазинов. Каждый этап выполняется отдельным запуском только после явного GO
владельца и останавливается для аудита. Если код расходится с этим планом, агент
останавливается и сообщает расхождение, а не «чинит» план сам.

Ссылки на строки даны для ревизии `6f0aa0e5`; после правок ориентируйтесь на имена
функций и тестов.

### Общий порядок работ (без циклов)

```text
Агентские этапы 1 → 1Б → 2 → 3 → 4 → 5 → 6   (каждый: отдельный GO → реализация → аудит владельца)
      ║ параллельно, только решения и настройки владельца: фаза A
      ▼ все этапы 1–6 приняты аудитом + отдельный GO владельца
Фазы владельца B → C (U5) → D → E   (+ P при сбое push, + R только Android NOT_INVOKED)
```

- Этапы 1–6 (включая 1Б) проходят аудит **до** любой реальной подготовки версии и публикации.
- Этап 6 — только безопасная репетиция: без тегов, gate, секретов, магазинов.
- Фазы B–E выполняет **владелец** после отдельного GO, когда этап 6 принят.
  Ни один этап не зависит от результата фаз B–E; ни одна фаза B–E не начинается до
  приёмки этапа 6.

---

## 1. Исходное состояние (зафиксировано 2026-10-22)

| Что | Значение |
| --- | --- |
| `origin/dev` | `6f0aa0e5` `fix(ci): confirm automatic internal TestFlight distribution without assignment (#84)` |
| `origin/main` | `07926a7d` `release: 1.2.3+24 (iOS retry) (#83)`; локальный `refs/remotes/origin/main` совпадает с `git ls-remote origin refs/heads/main` |
| Расхождение по коммитам | `dev` впереди на 204, `main` впереди на 1 (squash `+24`) |
| Расхождение по дереву | **только 7 файлов** — исправление #84 (`ios_store.py`, `apple_publish.py`, их тесты, `testflight_distribution_test.py`, `cli_docs_test.py`, `IOS_PUBLISHING.md`). Squash-коммит `07926a7d` по содержимому уже есть в `dev` |
| `pubspec.yaml` на `main` и `dev` | `version: 1.2.3+24`, Flutter `3.47.2` |
| Release-теги в origin | `rc/android/v1.2.3+19`, `rc/ios/v1.2.3+19` (оба `94eb9b99`), `rc/ios/v1.2.3+20`…`+23`, `rc/ios/v1.2.3+24` (`07926a7d`). Production-тегов нет |
| Незакоммиченное | 5 untracked файлов отменённого promotion (раздел 4). Блокируют CLI: `clean()` требует пустой `git status --untracked-files=all` |
| Stash | `stash@{0}` `safety/local-production-replica-before-dev-sync-20261014` — не относится к CI/CD, не трогать |
| GitHub-настройки | **не прочитаны**: `gh` не авторизован. Rulesets, Environments, тариф, список collaborators неизвестны (OC-A2). Tag rulesets для приватного репозитория организации доступны только на GitHub Team или Enterprise Cloud |

Вывод по расхождению `dev`/`main`: будущий PR `dev` → `main` не перенесёт сотни
несвязанных изменений. Он перенесёт #84, результат этого плана и version bump.
Перед этим PR снова проверить `git diff --stat origin/main origin/dev`.

Базовая линия тестов на `6f0aa0e5`, до любых правок:

| Набор | Команда | Результат |
| --- | --- | --- |
| Dart release | `flutter test --no-pub test/release` | 118 passed |
| Python release | `unittest discover -s tool/release -p '*_test.py'` во временном venv на `git archive HEAD` с одноразовым `git init` | 169 passed |
| Ruby (Play) | `play_policy_test.rb`, `play_store_test.rb`, `sdk_contract_test.rb` | **не запускались**: нет Ruby, Docker daemon не запущен |

### Классы Git-операций (используются во всём плане)

| Класс | Примеры | Меняет что-либо? |
| --- | --- | --- |
| G0 локальное чтение | `git status`, `git rev-parse`, `git tag --list`, `git cat-file`, `git show <sha>:<path>`, `git log`, `git diff` | Нет |
| G1 удалённое чтение | `git ls-remote origin …` | Нет (только сетевой запрос на чтение) |
| G2 обновление локальных refs | `git fetch …` (меняет `refs/remotes/*`, `FETCH_HEAD`, объекты) | Да, локально |
| G3 локальный тег | `git tag -a` | Да, локально |
| G4 запись в origin | `git push` | Да, удалённо |

Исполнители этапов 1–5: G0 и G1 разрешены, G2–G4 запрещены. Этап 6: G2 разрешён
один раз (`git fetch origin main` в начале, с фиксацией refs до и после), G3–G4 запрещены.
G3–G4 выполняет только CLI владельца в фазах D и P.

---

## 2. Фактическая схема процесса

```text
pubspec X.Y.Z+N на origin/main
  → локальный CLI (plan → preview → confirm → annotated tag → push exact ref)
  → GitHub Actions (android) | Codemagic (ios) по push/webhook тега
  → release.dart ci (событие, тег, ancestry от main, pubspec == тег, gate)
  → чтение состояния магазина до сборки
  → сборка и подпись → проверка артефакта → символы
  → повторное чтение магазина → одна попытка upload/commit или submission
  → обработка/ревью магазином → публикация (вне pipeline)
```

| Шаг | Код | Данные и секреты | Блокирует | Внешняя мутация | Тесты |
| --- | --- | --- | --- | --- | --- |
| Команды владельца | `tool/release/prokat-release.ps1` → `dart tool/release/cli.dart <platform> <channel> [--dry-run]` | нет | коллизии alias/функций, опечатка `-DryRunn` | нет | `cli_test.dart` (PowerShell), `cli_docs_test.py` |
| Запуск CLI | `main()` в `cli.dart` | нет | неверные аргументы; `git rev-parse --show-toplevel`; грязное дерево; `origin` не `auyltech/prokat` | нет (G0) | `cli_test.dart` |
| План | `ReleaseCli.plan` | G1 `ls-remote`; blobs коммита `origin/main`: pubspec, `releases/X.Y.Z/*`, workflow, `production.json`, `Info.plist` | грязное дерево; нет main; notes не `ready`; тег существует; история номеров; guard-строки workflow; `production.json`; Export Compliance; main сдвинулся. **Production: gate уже здесь, поэтому DryRun невозможен (P-01)** | Dry-run: G0 по точному SHA из `ls-remote`, без fetch. Обычный режим: fetch во временный bare-репозиторий вне checkout | `cli_test.dart` |
| Исполнение | `ReleaseCli.execute` | интерактивный ввод | `Continue? [y/N]`; для production `PUBLISH PRODUCTION`; gate; повторная проверка main и тегов | G2 в `refs/remotes/origin/main`, G3, G4 exact tag ref. При ошибке push — локальный тег остаётся, печатается ручная инструкция (P-25) | `cli_test.dart` |
| CI: источник | `release.dart ci` → `validateEvent`, `validateProduction`, `validateRevision`, `validatePubspecVersion`, `prepare` | env провайдера, `GITHUB_EVENT_PATH`/`CM_TAG`, `--revision` = `GITHUB_SHA`/`CM_COMMIT` | не tag push; удаление тега; SHA не в `main`; peeled-коммит тега ≠ revision; история; pubspec ≠ тег; gate. iOS production дополнительно фильтрует `CM_TRIGGER_SOURCE` и native `event` (5.10); это не claim и не криптографическое доказательство | `git fetch` в runner | `release_test.dart`, `source_test.dart` |
| CI: gate Android | шаг `Reject production until U5` в `android-release.yml`; `play.rb` | `secrets.PRODUCTION_PUBLISHING_ENABLED` | значение ≠ `true` | нет | `config_test.py` (структура) |
| CI: gate iOS | `release.dart ci`, `ios_store.py main` | env-группа Codemagic `prokat-ios-release` | значение ≠ `true` | нет | `ios_store_test.py` |
| Состояние Play | `play.rb preflight` → `ProkatPlayStore.snapshot` → `PlayPolicy.check!` | `PLAY_SERVICE_ACCOUNT_JSON_BASE64`, `vars.PLAY_HISTORICAL_MAX_BUILD` | номер занят; номер ≤ максимума; locale; track ≠ канал | **да: `edits.insert` + `edits.delete`** (P-06) | `play_policy_test.rb`, `play_store_test.rb` |
| Состояние Apple | `ios_store.py preflight` → `read_apple_state` + `check_builds` | `PROKAT_ASC_PRIVATE_KEY_PEM`, `APP_STORE_CONNECT_*`, `APP_STORE_APP_ID`, `IOS_HISTORICAL_MAX_BUILD`, `TESTFLIGHT_GROUP` (RC) | номер занят в builds/buildUploads; номер не растёт; 401/403/429/5xx/timeout/пагинация → UNKNOWN | нет (GET). Пишет `build/release/apple-state.json` в runner | `ios_store_test.py` |
| Сборка Android | `inputs.dart android`, `verify_upload_key.py`, `flutter build appbundle`, Crashlytics mapping | keystore, пароли, alias, `google-services.json`, Mapbox `pk.*` | отпечаток upload key ≠ `ANDROID_UPLOAD_CERT_SHA256`; mapping пуст | загрузка mapping в Firebase | `verify_upload_key_test.py` |
| Проверка AAB | `verify_android.dart` + bundletool 1.18.3 (sha256 закреплён) | `ANDROID_UPLOAD_CERT_SHA256` | подпись; отпечаток; debug-сертификат; package; versionCode/Name. **Без targetSdk (P-05)** | нет | **нет тестов** |
| Публикация Android | шаг `Recheck state and publish once…` → `play.rb publish` → `Supply::Uploader#perform_upload` | service account | канал/track/номер в отдельном temporary edit; событие GitHub | **да**: `begin_edit` (новый edit), upload AAB, `update_track` (заменяет все releases track, P-04), changelogs, `edits.commit` (**default `CANCEL_IN_REVIEW_AND_SUBMIT`, P-03**). Ошибки Google внутри `call_google_api` превращаются в `FastlaneCore::Interface::FastlaneError` (P-26) | `sdk_contract_test.rb` (наличие опций) |
| Сборка iOS | `swiftpm_resolve.py`, `xcode-project use-profiles`, `flutter build ipa`, `verify_ios.py`, dSYM | integration `prokat-app-store`, профили | lock-дрейф, entitlements, bundle, Export Compliance | загрузка dSYM в Firebase | `verify_ios_test.py`, `swiftpm_resolve_test.py` |
| Публикация iOS | шаг `Recheck Apple state and publish once…` → `ios_store.py publish` → `apple_publish.py` (Codemagic CLI 0.70.0) | integration, PEM | повторный preflight; ровно один IPA; argv через парсер CLI; локализации строго | **да**: upload IPA; RC — подтверждение Automatic Distribution (GET); production — App Store version create/update, `reviewSubmissions` create/reuse, item, confirm (P-07, P-19) | `ios_store_test.py`, `apple_publish_test.py`, `testflight_distribution_test.py` |

RC и Production сейчас различаются только префиксом тега и веткой внутри общих
адаптеров: track `internal`/`production`; TestFlight/`--app-store --release-type
AFTER_APPROVAL`; группа TestFlight нужна только RC.

---

## 3. Подтверждённые проблемы

Статусы: **ПОДТВЕРЖДЕНО** — прослежено по коду или контракту зависимости;
**ПРЕДПОЛОЖЕНИЕ** — требует внешней проверки; **ИСПРАВЛЕНО РАНЕЕ** — подтверждено,
что код уже защищает.

| ID | Приоритет | Проблема | Доказательство | Статус |
| --- | --- | --- | --- | --- |
| P-01 | P1 | Production DryRun невозможен без включения того же gate, что разрешает тег | `ReleaseCli.plan` вызывает `validateProduction` до ветки dry-run (`cli.dart:87`); тест `'$platform production default deny, including dry-run'` | ПОДТВЕРЖДЕНО |
| P-02 | P0 | Production может разделить номер с RC другой платформы. Пример: `android/v1.2.3+24` разрешён при существующем `rc/ios/v1.2.3+24` на том же SHA | `validateBuildHistory` (`release.dart:117-123`) не сравнивает канал; `validateStores` (`cli.dart:226-236`) принимает пару `rc/$other` для любого канала | ПОДТВЕРЖДЕНО |
| P-03 | P0 | Commit в Play без `changesInReviewBehavior`. Дефолт API `CANCEL_IN_REVIEW_AND_SUBMIT` отменяет текущий review. Касается и RC | `play.rb` задаёт только `changes_not_sent_for_review: false`; `Supply::Client#commit_current_edit!` (fastlane 2.241.0) передаёт только его; [edits.commit](https://developers.google.com/android-publisher/api-ref/rest/v3/edits/commit) | ПОДТВЕРЖДЕНО. Keyword `changes_in_review_behavior` есть в `google-apis-androidpublisher_v3` ≥ 0.97.0; в `Gemfile.lock` 0.109.0 |
| P-04 | P0 | Publish в production молча вытесняет существующие `draft`/`inProgress`/`halted` releases на track | `Supply::Uploader#update_track` делает `track.releases = [track_release]` (fastlane 2.241.0, `uploader.rb:451-456`) | ПОДТВЕРЖДЕНО |
| P-05 | P1 | AAB не проверяется на `targetSdkVersion ≥ 36`. Правило Google Play с 31.08.2026 | `verify_android.dart`; Flutter 3.47.2 `targetSdkVersion = '36'`. У `verify_android.dart` нет тестов | ПОДТВЕРЖДЕНО |
| P-06 | info | Чтение Play — не GET: `edits.insert` + `edits.delete`, дважды за прогон, плюс `play_access.rb` | `ProkatPlayStore.snapshot` (`play_store.rb:31-55`) | ПОДТВЕРЖДЕНО. Запрещено вызывать без GO |
| P-07 | P0 | Codemagic CLI 0.70.0: (a) выбирает самую новую редактируемую версию с любой строкой и делает PATCH `versionString`/`build`; (b) к редактируемым относит `WAITING_FOR_REVIEW`; (c) при ответе «another reviewSubmissions … still in progress» переиспользует чужой submission и подтверждает его | `SubmitToAppStoreAction._get_editable_app_store_version`, `_update_existing_app_store_version`, `_create_review_submission`; `AppStoreState.editable_states()` (cli-tools v0.70.0) | ПОДТВЕРЖДЕНО |
| P-08 | P2 | Production Apple app ID не закреплён (RC закреплён `require_rc_target`) | `validate_apple_environment` | ПОДТВЕРЖДЕНО |
| P-09 | P0 | Облачный gate — постоянный boolean; `PUBLISH PRODUCTION` проверяется только локально; неизменяемость тегов обеспечивает только клиентский CLI; re-run и rebuild переиспользуют тег | `android-release.yml`, `codemagic.yaml`, `cli.dart execute` | ПОДТВЕРЖДЕНО для кода. Серверные rulesets — ПРЕДПОЛОЖЕНИЕ (OC-A2) |
| P-10 | P1 | Python- и Ruby-тесты релиза не запускаются в PR; `play_store_test.rb` и `sdk_contract_test.rb` не запускаются нигде | `pull-request.yml`, `android-release.yml:99`, `codemagic.yaml:42` | ПОДТВЕРЖДЕНО |
| P-11 | P2 | Документация устарела («production dry-run requires gate», «следующий `1.2.4+24`»); тесты закрепляют устаревший текст | `tool/release/README.md:49-51`; `CICD-README.md` раздел E; `cli_test.dart`, `cli_docs_test.py` | ПОДТВЕРЖДЕНО |
| P-12 | P1 | Untracked-файлы promotion блокируют все четыре команды | `ReleaseCli.clean`, `main()` в `cli.dart` | ПОДТВЕРЖДЕНО |
| P-13 | info | После upload iOS ждёт обработку не более 20 минут; при таймауте IPA уже в ASC, submission нет | `--max-build-processing-wait 20` | ПОДТВЕРЖДЕНО. Fail-closed верный. Не менять без решения владельца |
| P-14 | info | Automatic Distribution внутренней TestFlight-группы может показать тестерам и production-билд | настройка Apple (`hasAccessToAllBuilds`) | ПРИНЯТО. Не менять: сломает RC |
| P-15 | — | Production argv не содержит `--testflight`, `--beta-group`, `--cancel-previous-submissions`, `--expire-build-submitted-for-review` | `publish_arguments`, `test_production_requests_after_approval` | ИСПРАВЛЕНО РАНЕЕ |
| P-16 | — | Upload/API без blind retry: Play `retries = 0`, `SUPPLY_UPLOAD_MAX_RETRIES=0`; Apple attempt counts 1/1/1 | `play_store.rb NoBlindPlayRetries`, `apple_publish.validate_publish_arguments` | ИСПРАВЛЕНО РАНЕЕ |
| P-17 | P1 | Реальный production без gate до отказа успевает выполнить G1 и fetch во временный репозиторий | порядок в `main()` и `ReleaseCli.plan` | ПОДТВЕРЖДЕНО |
| P-18 | P1 | По логу CI нельзя понять, вызывался ли издатель | маркеры только при успехе | ПОДТВЕРЖДЕНО |
| P-19 | P0 | Preflight iOS — единственная защита до мутаций; между ним и PATCH/submission/confirm до ~30 минут | `_submit_to_app_store` (cli-tools v0.70.0) | ПОДТВЕРЖДЕНО |
| P-20 | P0 | Проверка production track шла в отдельном preflight-edit, а commit делает другой edit | `ProkatPlayStore.snapshot` и `Supply::Uploader#perform_upload`; [Edits](https://developers.google.com/android-publisher/edits): edit — копия состояния на момент `insert`, Console-изменение или чужой commit инвалидирует его, commit инвалидированного edit падает без эффекта | ПОДТВЕРЖДЕНО |
| P-21 | P1 | Commit edit отправляет на ревью и изменения из Console, «готовые к отправке» ([Concurrency considerations](https://developers.google.com/android-publisher/concurrency-considerations)); API их не показывает | контракт Google Play | ПОДТВЕРЖДЕНО. Закрывается заморозкой Console (5.9) |
| P-22 | P2 | Dry-run читает blobs по точному SHA, но не сравнивает его с локальным `refs/remotes/origin/main` и не даёт явной диагностики | `main()` в `cli.dart`, `readGitBlob` | ПОДТВЕРЖДЕНО |
| P-23 | P0 | `GITHUB_RUN_ATTEMPT` начинается с 1 в **каждом новом run**. Удаление и повторное создание того же тега (в том числе повторный push идентичного объекта тега из любого клона) создаёт новый run с попыткой 1 и проходит активное разрешение `#1`. Привязка к номеру попытки защищает только от re-run, но не от replay события | Контракт GitHub Actions (`github.run_attempt`); `on.push.tags`; тег — объект с детерминированным SHA, его можно отправить повторно | ПОДТВЕРЖДЕНО. Закрывается только серверным tag ruleset (5.4, OC-A5, OC-C0) |
| P-24 | P0 | Классификатор R1–R7 ревизии 3 сравнивал поля только по признаку «редактируемо/нет». Пара `appStoreState=IN_REVIEW` + `appVersionState=READY_FOR_DISTRIBUTION` проходила R3 и R4 и могла дать OK | правила 9.6.3 ревизии 3 | ПОДТВЕРЖДЕНО (дефект плана). Новые правила — 9.6.3 |
| P-25 | P1 | После ошибки `git push` CLI оставляет локальный тег и печатает ручную инструкцию; протокол различения local-only, remote-present и запуска провайдера не формализован, безопасного повтора push с проверкой SHA нет | `ReleaseCli.execute`, ветка `catch` вокруг `push` | ПОДТВЕРЖДЕНО |
| P-26 | P1 | В fastlane 2.241.0 `AbstractGoogleServiceClient#call_google_api` перехватывает `Google::Apis::Error` и вызывает `UI.user_error!("Google Api Error: … - <сообщение ответа>")`. Внешний `rescue Google::Apis::ClientError` в `play.rb` поэтому не увидит `CHANGES_ALREADY_IN_REVIEW`, а текст ответа Google попадает в сообщение исключения | `supply/lib/supply/client.rb` 2.241.0: `call_google_api`, `commit_current_edit!` | ПОДТВЕРЖДЕНО |
| P-27 | P1 | Изменения в Play Console во время прогона инвалидируют edit (commit падает) или, если сделаны до `insert`, попадают в commit вместе с релизом | контракт Edits и Concurrency considerations | ПОДТВЕРЖДЕНО. Заморозка Console (5.9) |
| P-28 | P1 | Между проверкой items и `confirm_review_submission` в App Store Connect есть окно: API не даёт атомарного «подтвердить, только если items не менялись» | `ReviewSubmissions.list_items`, `confirm_review_submission` (PATCH `submitted=true`) | ПОДТВЕРЖДЕНО. Остаточный риск, этап 3 |
| P-29 | P1 | iOS production не проверяет источник запуска. Ручной запуск или Rebuild в Codemagic проходит те же проверки, что webhook | `validateEvent` проверяет `CM_TAG`, `CM_REPO_SLUG`, `CM_PULL_REQUEST`, но не `CM_TRIGGER_SOURCE`. Документация Codemagic: `CM_TRIGGER_SOURCE` ∈ {`webhook`, `schedule`, `api`}; запуск из UI или REST API — `api` | ПОДТВЕРЖДЕНО |

Поправки к прошлому аудиту: «204 коммита» — артефакт squash, по дереву 7 файлов
(раздел 1). P-07(b,c) и P-04 в прошлом аудите не были найдены.

---

## 4. Инвентаризация старых наработок

| Путь | Что это | Используется? | Решение |
| --- | --- | --- | --- |
| `tool/release/promotion.py` | Offline-планировщик RC → Production (`"P1 offline validate/plan only"`) | Нет: ни один tracked-файл не ссылается (`git grep` пуст); ни в одной ветке истории нет (`git log --all` пуст) | **Локально удалить из рабочего дерева на этапе 1** (разрешено владельцем) |
| `tool/release/promotion_model.py` | Модель блокеров promotion, импортируется только из `promotion.py` | Нет | То же |
| `tool/release/promotion.schema.json` | JSON Schema манифеста promotion | Нет | То же |
| `tool/release/requirements-promotion.txt` | Зависимости promotion-планировщика | Нет; workflow используют `requirements.txt`/`requirements-apple.txt` | То же |
| `releases/1.2.3/promotion.json` | Манифест promotion для RC +19/+24 (политика rollout 10%, `MANUAL`) | Нет; `readNotesFrom` читает только `release.json` и `ru/en/kk.txt` | То же |

Все пять файлов **untracked**: их нет в индексе и в Git-истории, созданы 2026-10-21 18:09.
Поэтому их удаление — **локальная очистка рабочего дерева** (`Remove-Item -LiteralPath`
по каждому из пяти путей), а не отслеживаемое Git-удаление. `git rm` к ним неприменим,
`git clean` не используется, коммит этапа эти пути не содержит и не может содержать.
Доказательство выполнения — `git status --short` до (пять `??`) и после (их нет).
Удаление необратимо. Если владелец хочет копию, он сохраняет её вне репозитория
до этапа 1. В этапе 0 файлы не удаляются.

Сохраняются:

- Тексты «promotion не реализован» в `release.dart`, `CICD-README.md`,
  `RELEASE_RUNBOOK.md`, `releases/README.md`. Это действующий контракт.
- `ios-apple-diagnostic` (`apple_diagnostic.py check --build 20`) — ручной GET-only
  workflow, без триггера.
- `ios_store.py access` и `play_access.rb` — ручные диагностики; доступ только по GO.
- `docs/ci-cd/PLAN.md`, `PREFLIGHT.md`, `VERIFICATION.md`, `RC_1.2.3_PREPARATION.md` —
  датированные свидетельства, уже помечены как исторические.
- Ветки `origin/backup/main-before-restore-20261009`, `origin/feat/redesign-20261013`,
  `origin/fix/ios-swiftpm-retry-diagnostics`, `feat/easy-add-machinery`, а также stash
  не относятся к задаче и не трогаются.

---

## 5. Целевой контракт Production-релиза

### 5.1 Теги и каналы

| Канал | Android | iOS | Назначение |
| --- | --- | --- | --- |
| RC | `rc/android/vX.Y.Z+N` | `rc/ios/vX.Y.Z+N` | Play `internal`, `completed`; TestFlight через Automatic Distribution |
| Production | `android/vX.Y.Z+N` | `ios/vX.Y.Z+N` | Play `production`, `completed`; App Store Review, `AFTER_APPROVAL` |

Формат закреплён в `ReleaseTag.parse`: компоненты версии до 4 цифр, Android build
1..2100000000, iOS 1..9999. Общий счётчик ограничен 9999 (`pubspecVersion`
валидирует как `rc/ios`). RC → Production promotion не существует и не возвращается.
Android и iOS публикуются **разными тегами** и разными провайдерами; каждая
платформа получает своё разрешение (раздел 5.4).

### 5.2 Правило истории номеров

Для целевого тега `T` (платформа `p`, канал `c`, версия `v`, build `n`, SHA `s`) и
каждого существующего разбираемого release-тега `E ≠ T`, локального или удалённого:

1. `E.build > n` → BLOCK.
2. `E.build == n` → разрешено **только если** `E.platform ≠ p` **и** `E.channel == c`
   **и** `E.version == v` **и** `commit(E) == s`. Иначе BLOCK.
3. `E.build < n` → OK.
4. Сам `T` уже существует локально или в origin → BLOCK. Тег никогда не двигается.

Следствия, обязательные для тестов:

- RC и Production никогда не делят номер. `rc/ios/v1.2.3+24` блокирует
  `android/v1.2.3+24` и `ios/v1.2.3+24`.
- Корректная пара: `android/vX+N`, затем `ios/vX+N` на том же SHA.
- Частичная пара: Android создан, iOS упал до upload. iOS-тег с тем же `N` допустим
  только на том же SHA. Если `main` сдвинулся — нужен новый `N`.
- CLI не повторяет уже созданный тег: правило 4 блокирует `prokat-prod-<platform>`.
  Повтор push локального тега — только протокол 5.8; повтор облачного прогона — 5.6.
- Store-снапшоты (`build/release/*-state.json`) — нижние границы. Равенство с
  максимумом другого магазина допустимо только при парном теге **того же канала** и SHA.
- Первый production-номер обязан быть > 24 и > фактических максимумов Play и Apple,
  включая Build Uploads. `+25` не считается безопасным заранее (OC-B1, OC-B2).

### 5.3 DryRun, `plan()` и `execute()`

Локальный gate — переменная окружения сессии `PRODUCTION_PUBLISHING_ENABLED`,
ровно строка `true`. Для RC gate не используется.

Где проверяется gate (целевое поведение после этапа 1):

| Место | DryRun | Реальный запуск production |
| --- | --- | --- |
| `prokat-prod-*` (PowerShell) | Передаёт `--dry-run` | Ничего не проверяет сам; вызывает Dart CLI; при ненулевом коде бросает исключение |
| `main()` в `cli.dart` | Не проверяет | **Первым действием после разбора аргументов, до любой git-команды** |
| `ReleaseCli.plan(platform, channel, dryRun:)` | Не проверяет | Первым действием, до `clean()`, `ls-remote` и чтения blobs |
| `ReleaseCli.execute(plan, dryRun:)` | Только печатает состояние gate | Повторно: до первого prompt и непосредственно перед `git tag` |
| `ReleasePlan` | Помечается `dryRun: true` | `execute(dryRun: false)` для плана с `dryRun: true` → BLOCK |

Свежесть данных в DryRun (без G2):

1. `S` = SHA `refs/heads/main` из G1 `git ls-remote origin`.
2. `L` = `git rev-parse --verify refs/remotes/origin/main^{commit}` (G0). Нет ссылки → BLOCK
   `Local origin/main is missing; run git fetch origin main outside the CLI and retry`.
3. `L ≠ S` → BLOCK `Local origin/main is stale (L) vs remote (S); run git fetch origin main outside the CLI and retry`.
4. `git cat-file -e S^{commit}` и каждый `git show S:<path>` с `GIT_NO_LAZY_FETCH=1`.
   Отсутствие объекта → BLOCK. Blobs читаются **только** по `S`, никогда по
   `refs/remotes/origin/main` и никогда по `HEAD`.
5. Повторный `ls-remote` в конце `plan()` (уже есть) → main сдвинулся → BLOCK.

Матрица операций:

| Операция | DryRun (любой канал) | Реальный RC | Реальный production, gate выключен | Реальный production, gate включён |
| --- | --- | --- | --- | --- |
| Разбор аргументов | да | да | да | да |
| G0: `git rev-parse --show-toplevel`, `git status`, `git remote get-url`, `git tag --list`, `git rev-parse refs/tags/…`, `git rev-parse refs/remotes/origin/main`, `git cat-file`/`git show` по `S`, чтение `build/release/*-state.json` | да | да | **нет — отказ раньше любой git-команды** | да |
| G1: `git ls-remote origin` | да | да | нет | да |
| G2: `git fetch` во временный bare-репозиторий вне checkout | **нет** | да | нет | да |
| Печать preview | да, если план построен | да | нет | да |
| Prompt (`Continue? [y/N]`, `PUBLISH PRODUCTION`) | **нет** | да (`Continue?`) | нет | да (оба) |
| G2: `git fetch` в `refs/remotes/origin/main` | нет | после подтверждения | нет | после обоих подтверждений и повторного gate |
| G3 `git tag -a`, G4 `git push origin refs/tags/T:refs/tags/T` | **нет** | да | нет | да |
| Push веток, `--force`, `--tags`, удаление и перенос тегов, запросы к CI или магазинам | никогда | никогда | никогда | никогда |

Вывод production DryRun при успешном плане: preview, строка
`Production gate (local): ENABLED|DISABLED`, после этапа 4 — строка облачного
разрешения (раздел 5.4) и `DRY RUN: no files, refs, tags or uploads changed.`
Если план не построен (свежесть, история, guard, notes), печатается только `BLOCKED: …`.
DryRun не является разрешением ни в одном из режимов.

### 5.4 Облачное разрешение, источник события и границы защиты

Уровни защиты Production:

| Уровень | Сейчас | Принято владельцем 2026-10-22 (Q1, вариант A) |
| --- | --- | --- |
| Локальный CLI | env `PRODUCTION_PUBLISHING_ENABLED=true` + `PUBLISH PRODUCTION` | Без изменения смысла; gate переносится на старт реального запуска (5.3) |
| Сервер GitHub | неизвестно | **Обязательное условие U5** (OC-A5, OC-C0): два активных tag ruleset на `refs/tags/android/v*`, `refs/tags/ios/v*`, `refs/tags/rc/**`. Ruleset «immutable»: Restrict updates + Restrict deletions, **пустой** bypass list. Ruleset «create»: Restrict creations, bypass — только роль или команда, где состоит один владелец |
| GitHub Actions (Android) | `secrets.PRODUCTION_PUBLISHING_ENABLED == true` | Плюс repository Variable `PRODUCTION_RELEASE_AUTH_ANDROID` == `"$GITHUB_REF_NAME@$GITHUB_SHA#$GITHUB_RUN_ATTEMPT"`; событие `push` тега (уже `validateEvent`) |
| Codemagic (iOS) | `PRODUCTION_PUBLISHING_ENABLED == true` в группе `prokat-ios-release` | Плюс переменная группы `PRODUCTION_RELEASE_AUTH_IOS` == `"$CM_TAG@$CM_COMMIT"`. Штатный запуск — tag webhook. `CM_TRIGGER_SOURCE` и native `event` — фильтры, не доказательство происхождения (5.10) |
| Магазины | без production-права у Play service account | Право Release to production выдаётся один раз на U5 (OC-C1) |

Форматы разрешения (сравнение строгое: без trim, без регистра, без шаблонов):

- Android: `android/vX.Y.Z+N@<40-hex SHA>#<номер попытки>`, например
  `android/v1.2.4+25@0123…abcd#1`. GitHub увеличивает `GITHUB_RUN_ATTEMPT` при
  re-run **того же** run; каждый **новый** run начинается с `1`.
- iOS: `ios/vX.Y.Z+N@<40-hex SHA>`.

`GITHUB_SHA` и `CM_COMMIT` уже обязаны совпадать с peeled-коммитом тега
(`validateRevision`), поэтому разрешение привязано к содержимому, а не только к имени.
Production DryRun печатает точную строку для копирования (для Android — с `#1`).
Разрешения независимы по платформам: GitHub проверяет только
`PRODUCTION_RELEASE_AUTH_ANDROID` и только для `android/v*`; Codemagic — только
`PRODUCTION_RELEASE_AUTH_IOS` и только для `ios/v*`. Boolean остаётся аварийным
выключателем провайдера.

**Что даёт каждая мера:**

| Сценарий | Чем остановлен | Гарантия |
| --- | --- | --- |
| Push любого другого production-тега, следующего номера | Разрешение (имя и SHA) | Да, пока владелец не выставил это значение |
| Тег с тем же именем на другом коммите | SHA в разрешении | Да |
| Re-run Android того же run | Номер попытки | Да, пока владелец не выставил `#n+1` |
| Rebuild или ручной запуск iOS в Codemagic | Операционная модель 5.10: оператор не запускает workflow вручную и через API. `when.condition` отсекает UI и schedule без `event`. `CM_TRIGGER_SOURCE` можно перекрыть переменной группы или API | Остаточный риск, не запрет pipeline. Язык условий не связывает `event.ref` с тегом. API-обработка `when` документами не подтверждена. Код не обещает exactly-once |
| **Удаление и повторное создание того же тега, в том числе повторный push идентичного объекта тега** → новый run (`GITHUB_RUN_ATTEMPT=1`) или новый webhook Codemagic | **Только** ruleset «immutable» + «create» | Гарантия есть, **только если** ruleset активен. Без ruleset схема **не** защищает от replay при активном разрешении |
| Забытый `PRODUCTION_PUBLISHING_ENABLED=true` без разрешения | Разрешение | Да |
| Прогон после очистки разрешения | Разрешение | Да |
| CI выдаёт разрешение сам себе | `permissions: contents: read`; переменные меняет только admin GitHub/Codemagic | Да |

Почему ruleset обязателен: привязка к объекту тега не помогает, потому что Git-объект
тега детерминирован, и любой клон, где тег уже есть, может отправить его повторно
с тем же SHA объекта. Номер попытки GitHub в новом run снова равен 1. Серверный
запрет удаления и повторного создания тегов GitHub предоставляет через rulesets
(прежние tag protection rules переведены в rulesets). Если тариф не
позволяет rulesets для приватного репозитория (нужен GitHub Team или Enterprise Cloud),
Q9 принято владельцем 2026-10-22: U5 блокируется, пока ruleset не создан и не проверен. Отсутствие ruleset не принято как риск, и план **не утверждает** защиту от replay.

**Чего разрешение и ruleset не дают:**

- Разрешение — **не одноразовый токен** и не запись о расходовании. Значение
  действует, пока его не изменят; поэтому очистка сразу после конечного состояния (5.5).
- Ruleset не защищает от администратора репозитория или организации: он может
  изменить или отключить ruleset. Это граница доверия; изменения видны в истории ruleset.
- Collaborator с правом write может менять workflow в своей ветке и читать repository
  secrets. Это граница доверия репозитория: её снимают только ограничение write-доступа
  и Environment-scoped секреты (OC-A2).
- Разрешение не доказывает, что магазин ещё не принял этот номер. Это делает store-preflight.

Параллельные прогоны: Android сериализован `concurrency: prokat-android-store`
(`cancel-in-progress: false`); iOS — concurrency 1 на тарифе Codemagic (OC-A4).

Почему повтор не создаёт второй публичный бинарник: Play отвергает уже использованный
versionCode, Apple отвергает повторный `CFBundleVersion` той же версии; store-preflight
блокирует номер, который магазин уже показывает; защита submission (этап 3) не даёт
подтвердить чужой submission. Остаточный риск повтора — лишняя попытка и путаница в
консоли, а не двойная публикация. Это не повод снимать процедуры 5.5–5.9.

### 5.5 Маркеры в логах и классификация исхода

| Маркер | Где | Что означает | Чего **не** означает |
| --- | --- | --- | --- |
| `PUBLISHER_INVOKED platform=<android\|ios> tag=<tag>` | Android: в `play.rb publish` после повторной проверки и сборки конфигурации Supply, **непосредственно перед** `Supply::Uploader.new.perform_upload`. iOS: в `apple_publish.py` после проверки argv и установки защит этапа 3, **непосредственно перед** `AppStoreConnect.invoke_cli()` | Управление передано издателю; с этого момента мутация магазина **возможна** | Что запрос к магазину был отправлен или что что-то изменилось |
| `PLAY_EDIT_COMMITTED` | после возврата `perform_upload` без исключения | Commit edit принят Google | Что релиз прошёл review или виден пользователям |
| `PLAY_CHANGES_IN_REVIEW` | при отказе commit с `CHANGES_ALREADY_IN_REVIEW` (этап 2) | Google сообщил, что commit не выполнен, edit не применён | Что номер свободен для повтора без проверки консоли |
| `APPLE_REVIEW_SUBMISSION_CONFIRMED` | после успешного `confirm_review_submission` своего submission (этап 3) | Своя версия отправлена в App Review | Что ревью пройдено или версия опубликована |

Строки `APPLE_PUBLISH_ARGUMENTS_VALID`, `APPLE_PREFLIGHT_VERIFIED`,
`PLAY_PREFLIGHT_VERIFIED`, `VERIFIED: AAB …`, `APPLE_SUBMISSION_STEP_COMPLETED` и
нулевой код валидации **никогда** не считаются доказательством публикации.

| Исход | Признак | Действие |
| --- | --- | --- |
| SUBMITTED | Android: `PLAY_EDIT_COMMITTED`. iOS: `APPLE_REVIEW_SUBMISSION_CONFIRMED` | Очистить разрешение. Проверить track или App Review в консоли |
| NOT_INVOKED | Прогон завершился, строки `PUBLISHER_INVOKED` в логе нет, лог полный | Очистить разрешение. Тот же production-тег не перезапускать ради зелёного CI (5.6, 5.10). Если консоль подтверждает отсутствие эффекта — исправить причину и выпустить новый тег с новым build number. Иначе сначала магазин; при неясности новую мутацию не запускать |
| UNKNOWN | `PUBLISHER_INVOKED` есть, маркера SUBMITTED нет (включая `PLAY_CHANGES_IN_REVIEW`). Сюда же: отмена, таймаут, неполный или потерянный лог | Очистить разрешение. **Повтор прежнего тега запрещён на обеих платформах.** Проверить магазин: Play — App bundle explorer, tracks, Publishing overview; Apple — Build Uploads, TestFlight builds, App Store version, review submissions. Восстановление — вручную в консоли или новым номером, новым тегом и новым разрешением (фаза D заново) |

Порядок очистки разрешения:

1. Разрешение выставляется для одной платформы непосредственно перед действием,
   которое запускает прогон (OC-D3, OC-P5 или OC-R4).
2. Как только прогон провайдера дошёл до конечного состояния (успех, ошибка, отмена),
   владелец **сначала** очищает переменную этой платформы и только потом разбирает результат.
3. Переменная другой платформы в это время пуста.
4. Boolean `PRODUCTION_PUBLISHING_ENABLED` после U5 остаётся `true` как признак
   активированного pipeline. Аварийная остановка — `false` у провайдера. Это не
   отменяет уже начатый прогон и уже отправленный review.

### 5.6 Первый релиз тега и повтор облачного прогона

**Первый релиз тега** (фаза D): тега ещё нет; его создаёт `prokat-prod-<platform>`
после DryRun, разрешения и обоих подтверждений.

**Повтор облачного прогона существующего тега** (фаза R) ниже — прежнее описание Android NOT_INVOKED. **E4-LEAN (5.10) заменяет его как операционную процедуру:** тот же production-релиз не перезапускают. Ошибка до мутации закрывается новым тегом и новым build number. Исторические шаги фазы R:

- `prokat-prod-android` для повтора **не используется**: правило 4 раздела 5.2
  блокирует существующий тег.
- Новый push того же тега невозможен (ruleset) и запрещён.
- Проверка тега только чтением (G1):
  `git ls-remote origin "refs/tags/<tag>" "refs/tags/<tag>^{}"` — peeled SHA должен
  совпасть с SHA из разрешения.
- Свежая проверка магазина владельцем (как OC-D1) и заморозка Console (5.9). CI в
  повторном прогоне заново выполнит весь preflight до сборки и перед upload.
- В GitHub Actions открыть **исходный** run тега → «Re-run all jobs»
  (или `gh run rerun <run-id>`). Перед этим выставить
  `PRODUCTION_RELEASE_AUTH_ANDROID=<tag>@<sha>#<последняя попытка run + 1>`. GitHub
  позволяет re-run в течение 30 дней.
- Один повтор на одно выставление разрешения; после конечного состояния — очистка и
  новая классификация по 5.5.

**iOS: повтор прежнего тега запрещён** (Q8, принято владельцем 2026-10-22). Код не создаёт заменяющий тег. RC и диагностика сохраняют свои контракты.

E4-R1 в тот же день требовал считать `CM_TRIGGER_SOURCE` недостаточным и держать iOS production закрытым кодом `IOS_PRODUCTION_REPLAY_GUARD_UNAVAILABLE`, пока нет durable atomic claim. **E4-LEAN (5.10) эти два технических требования снимает.** Операционный запрет повтора и tag ruleset как условие U5 остаются. Отдельный replay backend не строится.

Текущий путь: boolean, `PRODUCTION_RELEASE_AUTH_IOS` и штатный tag webhook доходят до сборки и publisher. Фильтры `CM_TRIGGER_SOURCE` и `when.condition` не являются claim и не доказывают происхождение события. U5 по-прежнему не активирован: нужен проверенный tag ruleset (OC-A5, OC-C0) и отдельное разрешение владельца. Q7 не утверждён, этап 5 запрещён.

При NOT_INVOKED и UNKNOWN владелец вручную берёт новый build number и новый тег, фаза D заново. Повтор той же identity не разрешается отсутствием результата. Конкретные шаги — в `docs/ci-cd/RELEASE_RUNBOOK.md`.

**UNKNOWN** — повтор прежнего тега запрещён на обеих платформах.

### 5.7 Инварианты RC

Не меняются без отдельного решения владельца: формат `rc/*`; track `internal`;
`release_status: completed`; Automatic Distribution без `--beta-group` и `--testflight`;
подтверждение `TESTFLIGHT_INTERNAL_DISTRIBUTION_CONFIRMED`; существующие теги;
отсутствие gate, облачного разрешения и проверки `CM_TRIGGER_SOURCE` для RC.
Предлагаемые изменения RC: `ERROR_IF_IN_REVIEW` и классификация
`PLAY_CHANGES_IN_REVIEW` (Q2); строка `PUBLISHER_INVOKED` — только лог; tag ruleset
распространяется и на `rc/**` (теги и так неизменяемы по контракту, CLI владельца
остаётся единственным создателем). Защиты submission этапа 3 и проверка production
track этапа 2 для RC не активны.

### 5.8 Протокол сбоя `git push` после создания локального тега

Ситуация: CLI создал annotated tag `T` локально (G3), а `git push origin refs/tags/T:refs/tags/T`
завершился ошибкой или результат неизвестен. Локальный тег остаётся (это резервирование
номера); удаление и перенос тегов, `--force`, `--tags` и слепой повтор push запрещены.

Шаги (этап 1Б реализует их как режим CLI `--resume-push`, без новых PowerShell-функций):

1. **Локальная проверка (G0).** `git cat-file -t refs/tags/T` = `tag`;
   `git rev-parse refs/tags/T` = объект `O_local`; `git rev-parse refs/tags/T^{commit}` =
   ожидаемый SHA `E`, переданный владельцем явно (`--expect-sha E`, 40 hex). Иначе STOP
   `LOCAL_TAG_MISMATCH`.
2. **Удалённая проверка (G1).** `git ls-remote origin "refs/tags/T" "refs/tags/T^{}"`:

   | Результат | Классификация | Действие |
   | --- | --- | --- |
   | Команда успешна, строк для `T` нет | `REMOTE_ABSENT` | Перейти к шагу 3 |
   | Две строки: `O_local refs/tags/T` и `E refs/tags/T^{}` | `REMOTE_SAME` | Push фактически прошёл. Ничего не отправлять. Провайдер, вероятно, запущен — наблюдать (OC-D5) |
   | Тег есть, но объект или peeled SHA отличаются; лишние или неполные строки | `REMOTE_DIFFERS` | **STOP**, ручная проверка; ничего не менять |
   | Ошибка, таймаут, нет доступа, неразборчивый вывод | `REMOTE_UNKNOWN` | **STOP**; повторить только чтение позже |

3. **Проверка провайдера (владелец).** При `REMOTE_ABSENT` в GitHub Actions/Codemagic не
   должно быть ни одного прогона для `T`. Прогон есть, а ref нет → STOP (кто-то создал и
   удалил тег) — ручное расследование.
4. **Условия безопасного повтора push** (`REMOTE_ABSENT`, все обязательны):
   - production gate в env сессии (`PRODUCTION_PUBLISHING_ENABLED=true`);
   - `git ls-remote origin refs/heads/main` == `E` (main не сдвинулся). Иначе STOP
     `MAIN_MOVED_NEW_NUMBER_REQUIRED`: номер отбрасывается, тег остаётся локальным резервом;
   - история номеров (5.2, правила 1–3) по свежему `ls-remote` без учёта самого `T`;
   - облачное разрешение платформы выставлено заново равным `T@E` (Android с `#1`, это
     новый run) — OC-P5;
   - свежая проверка магазина и заморозка Console (5.9) — OC-P4.
5. **Отдельное подтверждение владельца:** ввести полное имя тега `T` точно. Затем ровно
   одна команда `git push origin refs/tags/T:refs/tags/T`.
6. **Повторная удалённая проверка** (шаг 2). `REMOTE_SAME` → наблюдать прогон.
   Любой другой результат → STOP, повтор push только через новый цикл шагов 1–5 с
   новым подтверждением.

### 5.9 Заморозка Google Play Console

С момента финальной проверки OC-D1 (или OC-R3, OC-P4) и до маркера `PLAY_EDIT_COMMITTED`
или иного конечного состояния прогона владелец и все пользователи Play Console:

- не создают, не редактируют, не отправляют на ревью и не публикуют production-релизы;
- не меняют store listing, Data safety, content rating, ценовые и иные настройки, которые
  требуют ревью, и не готовят «Changes ready to send for review»;
- не включают и не выключают Managed publishing.

Если изменение всё же произошло: до создания тега — STOP и повторить OC-D1; во время
прогона — прогон не останавливать вручную; его исход классифицируется по 5.5 (изменение
в Console инвалидирует edit, commit упадёт без эффекта → UNKNOWN), затем повторная
проверка консоли. Код не может проверить заморозку; это обязательное условие владельца.

### 5.10 Операционная модель LEAN (решение владельца 2026-10-22)

Последнее требование владельца по сложности и эксплуатации уточняет Q8 и Q9, не отменяя их операционный смысл. История решений 2026-10-22 и предпосылки E4-R1 в разделах 5.6 и 14 сохранены.

**Остаётся обязательным**

- Новая подписанная сборка из проверенного `main`. Promotion RC → Production не реализуется.
- Guards этапа 3 для App Store submission.
- Проверки source/ref/SHA, version/build, signing identity и production gates Q1.
- Tag ruleset — базовая защита create/update/delete production-тегов и условие U5. Это не replay store.
- Автоматические повторы публикационных мутаций запрещены.
- `UNKNOWN` означает ручную сверку до следующих действий.
- `PRODUCTION_PUBLISHING_ENABLED` остаётся выключенным до отдельной активации U5.

**Больше не требуется**

- Durable atomic replay store, отдельная база, backend endpoint или внешний сервис ради одноразового claim.
- Журнал состояний, распределённая блокировка, lease и гарантия exactly-once.
- Автоматическое восстановление после неизвестного результата.
- Криптографическое подтверждение каждого CI trigger, если для него нужна отдельная система доверия.
- Постоянный отказ `IOS_PRODUCTION_REPLAY_GUARD_UNAVAILABLE`. В репозитории нет интерфейса, который изображает такой claim.

**Как устроен штатный запуск**

Оператор одной командой создаёт уникальный production-тег. Android идёт через GitHub tag push, iOS — через Codemagic tag webhook. За один раз выполняется один production-релиз. Параллельные, конфликтующие и повторные запуски того же релиза оператор не инициирует.

`ios-production` `when.condition` проверяет репозиторий, `created`, отсутствие `deleted`, SHA и значение `CM_TRIGGER_SOURCE`. Условие считается после clone. Язык Codemagic не связывает `event.ref` с `refs/tags/$CM_TAG`. Переменные группы и REST API перекрывают built-in `CM_*` и не создают `event`. Поэтому сравнение `CM_TRIGGER_SOURCE == webhook` — операционный фильтр UI/schedule, а не attestation. Остаточный риск: административный или API-запуск с подменёнными переменными. Для этой модели такой запуск не является штатным путём и не считается разрешением повторить неизвестную операцию.

Разрешение платформы не расходуется кодом. Повторный тег и уже занятый build number останавливают существующие проверки истории и preflight магазина. Это не защита от повторной доставки webhook.

**Почему так**

E4-R1 останавливал весь iOS production из-за гарантий, которые владелец для первого использования не требует. Отсутствие абсолютной отказоустойчивости не держит публикацию выключенной. Ручная сверка консоли не становится отдельным продуктом.

---

## 6. Порядок этапов

```text
Этап 1   Контракт: очистка, DryRun со свежестью, gate до git, канал в истории   (Dart, PowerShell-тест)
Этап 1Б  Протокол сбоя push: режим --resume-push                                (Dart)
   │
   ├── Этап 2  Android: commit без отмены review и с классификацией, track в публикуемом edit, targetSdk  (Ruby, Dart verify)
   ├── Этап 3  iOS: preflight + защита выбора версии, submission и confirm в издателе          (Python)
   │
Этап 4   Облачное разрешение по платформам + CM_TRIGGER_SOURCE + PUBLISHER_INVOKED  (YAML, Dart, Ruby, Python)
   │
Этап 5   PR-регрессия Python/Ruby + эксплуатационная документация
   │
Этап 6   Репетиция без публикации + production-readiness
```

Обоснование:

- Этап 1 первым: он чисто локальный, снимает P-12, P-17, P-22 и даёт DryRun.
- Этап 1Б сразу после: тот же файл `cli.dart`, тот же набор тестов; отдельный этап
  ограничивает размер diff.
- Этапы 2 и 3 затрагивают разные файлы и могли бы идти параллельно. Выполняются
  последовательно: одна стадия за запуск, один писатель.
- Этап 4 после адаптеров: он правит те же `play.rb`, `ios_store.py`, `apple_publish.py`.
- Этап 5 после кода: документация описывает уже существующее поведение.
- Этап 6 не меняет код. Запросы к магазинам в нём не выполняются.

Общие правила для каждого этапа:

- Один исполнитель-писатель в checkout. Параллельно допускаются только read-only аудиторы.
- Классы Git-операций — раздел 1.
- Перед коммитом: `git status --short` (никаких посторонних файлов), полный
  `git diff --staged`, тесты этапа, `git diff --check`.
- Коммит этапа: `feat(release): <этап>` или `fix(release): …`. Без push.
- Отчёт этапа: файлы, SHA коммита, команды и фактические результаты, проверенные
  негативные сценарии, остаточные риски, чек-лист аудита, что осталось.

### Команды проверки (Windows, без внешних эффектов)

```powershell
# Dart
flutter test --no-pub test/release --reporter expanded
flutter analyze --no-pub --fatal-infos --fatal-warnings
dart format --output=none --set-exit-if-changed tool/release test/release
git diff --check

# Python: временный venv вне репозитория, копия текущего рабочего дерева (tracked + новые, без ignored)
$tmp = Join-Path $env:TEMP "prokat-release-check"
if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
git ls-files --cached --others --exclude-standard | ForEach-Object {
  $dest = Join-Path "$tmp\src" $_
  New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
  if (Test-Path -LiteralPath $_) { Copy-Item -LiteralPath $_ -Destination $dest }
}
Push-Location "$tmp\src"; git init -q; git -c core.autocrlf=false add -A; git -c user.name=check -c user.email=check@example.invalid commit -qm check; Pop-Location
python -m venv "$tmp\venv"
& "$tmp\venv\Scripts\python.exe" -m pip install -q -r "$tmp\src\tool\release\requirements.txt"
Push-Location "$tmp\src"; & "$tmp\venv\Scripts\python.exe" -B -m unittest discover -s tool/release -p "*_test.py"; Pop-Location

# Ruby: нужен запущенный Docker Desktop. Установка гемов идёт с сетью, тесты без внешних магазинов
docker run --rm --mount "type=bind,source=$($PWD.Path),target=/workspace" -w /workspace `
  -e BUNDLE_GEMFILE=/workspace/tool/release/Gemfile -e BUNDLE_PATH=/workspace/build/release/gems -e BUNDLE_FROZEN=true `
  ruby:3.3.10 bash -lc 'bundle install --jobs 4 --retry 0 && ruby tool/release/play_policy_test.rb && bundle exec ruby tool/release/sdk_contract_test.rb && bundle exec ruby tool/release/play_store_test.rb'
```

Python-копия нужна, потому что тесты пишут в `build/release` и один тест требует
`git rev-parse HEAD`. Копия во временной папке включает untracked-файлы, поэтому
до этапа 1 в неё попадают и promotion-файлы; тестов в них нет. Если Docker
недоступен, Ruby-тесты считаются **NOT RUN**, а этап, меняющий Ruby, не может быть
принят. Ни одна команда не требует credentials. Если тест падает из-за отсутствия
credentials или сети, это дефект теста, а не повод их передать.

---

## 7. Этап 1 — контракт: очистка, DryRun, gate до git, канал в истории номеров

1. **Цель.** Production DryRun без gate и только на актуальном `origin/main`. Реальный
   production-запуск без gate отказывает раньше любой git-команды — и через Dart CLI,
   и через публичную PowerShell-команду. RC и Production не делят номер. CLI снова
   работает на чистом дереве.
2. **Проблемы.** P-01, P-02, P-12, P-17, P-22; часть P-11 (`tool/release/README.md`).
3. **Зависимости.** Нет. GO владельца на локальную очистку пяти файлов (Q6).
4. **Границы.**
   - Можно: `tool/release/cli.dart`, `tool/release/release.dart`,
     `test/release/cli_test.dart`, `test/release/release_test.dart`, абзац про
     dry-run в `tool/release/README.md`; локальное удаление пяти untracked-файлов
     раздела 4 (`Remove-Item -LiteralPath`, не `git rm`, не `git clean`).
   - Нельзя: workflow YAML, Ruby, Python, `prokat-release.ps1`, формат тегов, фразу
     `PUBLISH PRODUCTION`, RC-поведение, `CICD-README.md` (этап 5), режим `--resume-push`
     (этап 1Б), операции G2–G4 (раздел 1).
5. **Участки кода.** `main()` в `cli.dart`, `ReleaseCli.plan`, `ReleaseCli.execute`,
   `ReleasePlan`, `ReleaseCli.validateStores` (ветка `release.build == maximum`),
   `validateBuildHistory`, `validateProduction`, функция чтения blobs dry-run в `main()`.
6. **Решение.** Строго по разделу 5.3:
   - `main()`: если канал `production` и нет `--dry-run`, вызвать
     `validateProduction` сразу после проверки аргументов, до
     `git rev-parse --show-toplevel`.
   - `ReleaseCli.plan(platform, channel, {required bool dryRun})`: при
     `production && !dryRun` — `validateProduction` первым действием. Иначе gate не читать.
     `ReleasePlan` получает поле `dryRun`.
   - Dry-run (любой канал): шаги свежести 1–5 раздела 5.3, проверка `L == S` до
     чтения первого blob.
   - `execute`: если `dryRun != plan.dryRun` → `ReleaseFailure` без записей и prompt.
     Для production печатать `Production gate (local): ENABLED|DISABLED`. При
     `!dryRun && production` — `validateProduction` до первого `confirm` и
     существующая проверка перед `git tag`.
   - `validateBuildHistory`: в условие пары добавить `previous.channel == release.channel`.
     Сообщение для равного номера в другом канале:
     `Build N already used by <tag> in another channel; RC and production never share a build. Bump pubspec.`
   - `validateStores`: допустимое имя пары — только
     `'${release.production ? '' : 'rc/'}$other/v$same'`.
   - README: production dry-run не требует gate, требует актуальный локальный
     `origin/main`; реальный запуск требует gate и отказывает до git.
7. **Инструкция исполнителю.** Prompt E1 (раздел 13).
8. **Effort / Context.** Medium / файлы этапа плюс разделы 1, 5.2–5.3.
9. **Тесты.** `flutter test --no-pub test/release`, `flutter analyze`, `dart format`,
   `git diff --check`, Python-набор (README и docs-тесты не должны сломаться).
   Fixture в `cli_test.dart` дополнить списком **всех** вызовов `runGit` (`calls`),
   записью чтений blobs (`reads`) и управляемым `refs/remotes/origin/main`.
   Обязательные новые и изменённые тесты:
   - production DryRun без env и с env `true`: план построен; `calls` содержит только
     G0 и G1; нет `fetch`, `tag`, `push`; `confirm` не вызывался; вывод содержит
     `DISABLED` или `ENABLED` соответственно и `DRY RUN`;
   - DryRun, `refs/remotes/origin/main` отсутствует → BLOCK `missing`, `reads` пуст;
   - DryRun, `refs/remotes/origin/main` = старый SHA, а `ls-remote` = новый → BLOCK `stale`,
     `reads` пуст, хотя объекты старого коммита доступны;
   - DryRun, ссылка совпадает, но объекта `S` нет → BLOCK, без fetch;
   - на реальном временном Git-репозитории (по образцу теста `real immutable Git blobs…`):
     устаревший tracking-ref не приводит к чтению старых blobs;
   - production `plan(dryRun: false)` без env и с `'false'`, `'TRUE'`, `' true'`, `''`:
     `ReleaseFailure`, **`calls` пуст, `reads` пуст**, `confirm` не вызывался;
   - **Dart CLI без git:** подпроцесс `<dart-sdk>/bin/dart.exe <repo>/tool/release/cli.dart
     android production` с `includeParentEnvironment: false` и окружением, где `PATH`
     содержит только каталог Dart SDK и `%SystemRoot%\System32`, а
     `PRODUCTION_PUBLISHING_ENABLED=false`: exit 1, сообщение о выключенном gate, нет
     сообщений `Git … failed`/`ProcessException`. Путь к Dart SDK вычисляется из
     установленного Flutter (например, из `Platform.resolvedExecutable` →
     `<flutter>/bin/cache/dart-sdk/bin/dart.exe`), не через `flutter/bin/dart.bat`
     (он сам вызывает git);
   - **PowerShell-обёртка без git:** абсолютный путь к `powershell.exe`, то же урезанное
     окружение; команда `. ./tool/release/prokat-release.ps1; prokat-prod-android` и
     отдельно `prokat-prod-ios`: исключение `PROKAT release blocked`, в выводе сообщение
     о gate, нет следов git. Тест выполняется только на Windows; на других ОС
     пропускается явно;
   - `execute(planDry, dryRun: false)` → `ReleaseFailure`, `writes` пуст, `confirm` не вызывался;
   - production с env `true`: прежние `fetch`, `tag`, `push`; отказ от `y` или от
     `PUBLISH PRODUCTION` → `writes` пуст;
   - `rc/ios/v1.2.3+24` на SHA `s`, версия `1.2.3+24` → `android production` BLOCK,
     `ios production` BLOCK, `android rc` OK (пара RC);
   - `android/v1.2.3+25` на `s` → `ios production` `+25` OK; на `other` → BLOCK;
     `rc/ios` `+25` → BLOCK (другой канал);
   - существующий production-тег → `plan` BLOCK (правило 4);
   - `validateBuildHistory` unit: матрица platform × channel × version × SHA для равного номера;
   - `validateStores`: снапшот Play с кодом 25 + `rc/android/v1.2.3+25` не даёт пары
     для `ios production`; `android/v1.2.3+25` даёт;
   - RC: реальный запуск без env по-прежнему не читает gate; существующие RC-тесты
     не меняются и проходят.
10. **Приёмка.**
    - [ ] Пять файлов раздела 4 удалены **из рабочего дерева**; `git status --short` до
      и после приложен; коммит этапа их не содержит.
    - [ ] Таблица операций 5.3 реализована; каждая ячейка «нет» покрыта тестом.
    - [ ] Gate реального production проверяется в `main()` до git, в `plan()` первым
      действием, в `execute()` до prompt и перед `git tag`.
    - [ ] Отказ до git доказан тестами и для Dart CLI, и для `prokat-prod-android`/`prokat-prod-ios`.
    - [ ] DryRun не делает `fetch`, не вызывает `confirm`, отказывает при отсутствующем
      или устаревшем `refs/remotes/origin/main` и читает blobs только по `S`.
    - [ ] Пара номера требует одного канала в `validateBuildHistory` и `validateStores`.
    - [ ] Dart 118 + новые тесты проходят; Python-набор проходит.
    - [ ] Нет изменений в YAML, Ruby, Python-коде и `prokat-release.ps1`.
11. **Негативные сценарии.** Опечатка в gate; gate не `true`; исполнение плана,
    построенного как DryRun; отсутствующий или устаревший tracking-ref; отсутствующий
    объект; ответ `N`/пустой/`yes`; отказ от `PUBLISH PRODUCTION`; main сдвинулся после
    preview; тег появился во время подтверждения; RC-номер для Production;
    Production-номер для RC; пара на другом SHA; пара другой версии; локальный
    неотправленный тег; повтор существующего тега через CLI.
12. **Регрессии RC.** Тесты `rc` в `cli_test.dart`, `source_test.dart`, PowerShell-обёртки.
    RC DryRun теперь тоже требует свежий tracking-ref — намеренное усиление, отражается в README.
13. **Риски и откат.** Риск: DryRun начнут путать с разрешением. Смягчение: явная
    строка gate, отсутствие prompt, фраза `DRY RUN`. Откат: `git revert <коммит этапа>`.
    Удалённые untracked-файлы не восстанавливаются. STOP, если любой из пяти файлов
    окажется tracked или на него появится ссылка; STOP, если тест «без git» нельзя
    построить так, чтобы git действительно был недоступен.
14. **Владелец.** GO на очистку (Q6). Если нужна копия — сохранить вне репозитория заранее.
15. **Аудит.** Diff этапа; `git status --short` до и после очистки; вывод команд из
    ветки против текущего `origin/main` (`07926a7d`), локальный tracking-ref не обновлять:
    - `dart tool/release/cli.dart android production --dry-run` → `BLOCKED` историей
      (`+24` в другом канале), без prompt; если tracking-ref к этому моменту устарел —
      `BLOCKED stale`, это тоже допустимый и задокументированный исход;
    - `dart tool/release/cli.dart ios production --dry-run` → `BLOCKED`;
    - `dart tool/release/cli.dart android production` без env → `BLOCKED` gate.
    До и после: `git show-ref --tags`, `git rev-parse refs/remotes/origin/main`, `git status --short`.

---

## 7Б. Этап 1Б — протокол сбоя push: режим `--resume-push`

1. **Цель.** После ошибки push формально различать local-only, remote-present-same,
   remote-differs и unknown; повторять push только для local-only, с точным ожидаемым
   SHA и отдельным подтверждением; никогда не удалять, не двигать тег и не делать слепой повтор.
2. **Проблемы.** P-25.
3. **Зависимости.** Этап 1 принят.
4. **Границы.**
   - Можно: `tool/release/cli.dart` (новый режим и текст ошибки push в `execute`),
     `tool/release/release.dart` (общие функции), `test/release/cli_test.dart`, абзац в
     `tool/release/README.md`.
   - Нельзя: `prokat-release.ps1` (новых PowerShell-функций нет; режим вызывается
     `dart tool/release/cli.dart <platform> <channel> --resume-push <tag> --expect-sha <sha>`),
     YAML, Ruby, Python, G2–G4 у исполнителя, `--force`, `git tag -d`, `git push --delete`.
5. **Участки кода.** `ReleaseCli.execute` (ветка ошибки push), разбор аргументов в `main()`,
   `remoteRefs`, `validateTags`, `validateBuildHistory`.
6. **Решение.** Строго по разделу 5.8:
   - Новый метод `ReleaseCli.resumePush(tag, expectSha, dryRun)`; аргументы проверяются
     строго (`tag` — разбираемый release-тег того же platform/channel, `expectSha` — 40 hex).
   - Шаг 1 (G0) и шаг 2 (G1) выполняются всегда, в том числе в `--dry-run`. Классификация
     `REMOTE_ABSENT`/`REMOTE_SAME`/`REMOTE_DIFFERS`/`REMOTE_UNKNOWN` — фиксированные строки.
     Разбор вывода `ls-remote` строгий: допустимы только 0 строк или ровно две ожидаемые.
   - Для production gate проверяется первым действием (как в 5.3), до любой git-команды,
     если не `--dry-run`.
   - `REMOTE_ABSENT` и не `--dry-run`: проверки шага 4 (main == `expectSha`, история без
     `T`), печать требований к облачному разрешению, prompt
     `Type the full tag name to push it:`; только точное совпадение → одна команда
     `git push origin refs/tags/T:refs/tags/T`; затем повторный шаг 2.
   - Сообщение ошибки push в `execute` заменить на ссылку на этот режим с точной
     командой (`--resume-push T --expect-sha <sha>`), без советов удалить или двигать тег.
7. **Инструкция исполнителю.** Prompt E1B.
8. **Effort / Context.** Medium / этап 1Б, раздел 5.8, итог этапа 1.
9. **Тесты** (fake git, без сети):
   - каждая из четырёх классификаций; разбор `ls-remote` с лишней строкой, одной строкой,
     другим объектом, другим peeled SHA, ненулевым кодом → `REMOTE_DIFFERS`/`REMOTE_UNKNOWN`;
   - `REMOTE_SAME` → push не вызывается, печатается указание наблюдать прогон;
   - `REMOTE_ABSENT` + main сдвинулся → `MAIN_MOVED_NEW_NUMBER_REQUIRED`, push не вызывается;
   - `REMOTE_ABSENT` + неверное имя тега в подтверждении → push не вызывается;
   - `REMOTE_ABSENT` + точное подтверждение → ровно один `push` с exact ref, без
     `--force`/`--tags`, затем повторная проверка;
   - локальный тег не annotated или peeled ≠ `expectSha` → `LOCAL_TAG_MISMATCH`;
   - production без gate и не dry-run → отказ до git;
   - `--dry-run` никогда не вызывает push и prompt;
   - ни в одном пути не вызываются `tag -d`, `push --delete`, `--force`, `fetch`;
   - текст ошибки push в `execute` содержит команду `--resume-push` и не содержит советов удалить тег.
10. **Приёмка.**
    - [ ] Таблица шага 2 раздела 5.8 реализована дословно, неоднозначность → STOP.
    - [ ] Повтор push только при `REMOTE_ABSENT`, main == `expectSha` и точном подтверждении.
    - [ ] Нет кода удаления, переноса, force или `--tags`.
    - [ ] Все тесты этапа 1 продолжают проходить.
11. **Негативные сценарии.** Все строки пункта 9.
12. **Регрессии RC.** Режим работает и для RC (без gate); существующий RC-путь `execute` не меняется,
    кроме текста ошибки push.
13. **Риски и откат.** Гонка между проверкой и push (кто-то создаст тег) — ruleset
    «create» (OC-A5) и повторная проверка шага 6. Откат — `git revert`.
14. **Владелец.** Нет действий до фазы P.
15. **Аудит.** Diff; grep отсутствия `tag -d`, `--delete`, `--force`, `--tags` в `cli.dart`;
    вывод `--resume-push … --dry-run` на несуществующем локальном теге → `LOCAL_TAG_MISMATCH`.

---

## 8. Этап 2 — Android: commit без отмены review, track в публикуемом edit, targetSdk

1. **Цель.** Commit в Play никогда не отменяет чужой review, а его отказ классифицируется
   на слое, где доступен исходный ответ Google. Production publish не вытесняет чужие
   releases **в том edit, который будет зафиксирован**. AAB доказуемо таргетирует API ≥ 36.
2. **Проблемы.** P-03, P-04, P-05, P-20, P-26; часть P-10 (Ruby-тесты в Android workflow).
3. **Зависимости.** Этапы 1 и 1Б приняты. Решения Q2 и Q3. Docker Desktop для Ruby-тестов.
4. **Границы.**
   - Можно: `tool/release/play_store.rb`, `tool/release/play_policy.rb`, `tool/release/play.rb`
     (включение защиты публикуемого edit перед `perform_upload`, отображение фиксированных
     кодов ошибок), `tool/release/sdk_contract_test.rb`, `tool/release/play_policy_test.rb`,
     `tool/release/play_store_test.rb`, `tool/release/verify_android.dart`, новый
     `test/release/verify_android_test.dart`, шаг `Analyze and run tests` в
     `.github/workflows/android-release.yml` (добавить два bundle-теста).
   - Нельзя: track RC, `release_status`, rollout, `Gemfile`/`Gemfile.lock`,
     gate-логика и маркер `PUBLISHER_INVOKED` (этап 4), сетевые вызовы в тестах,
     печать `e.body`, `e.message` исходных ошибок Google или сообщений `FastlaneError`.
5. **Участки кода.** `ProkatPlayStore` (рядом с `NoBlindPlayRetries`), `PlayPolicy.check!`,
   `PlayPolicy.safe_error`, публикующая ветка и блок `rescue` в `play.rb`, `main` в
   `verify_android.dart`.
6. **Решение.**
   - **Commit и его классификация (P-03, P-26).** Модуль `ProkatPlayStore::ErrorIfInReview`,
     prepend к `Google::Apis::AndroidpublisherV3::AndroidPublisherService#commit_edit`:
     - принудительно подставляет `changes_in_review_behavior: 'ERROR_IF_IN_REVIEW'`
       поверх любого переданного значения; при загрузке без keyword в сигнатуре — `raise`;
     - вокруг `super` перехватывает **только** `Google::Apis::ClientError`; если
       `status_code == 400` и JSON тела содержит `error.details[*].reason ==
       "CHANGES_ALREADY_IN_REVIEW"`, бросает `ProkatPlayStore::ChangesInReview` с
       фиксированным сообщением. Этот класс **не** наследует `Google::Apis::Error`, поэтому
       `call_google_api` его не перехватывает и не превращает в `UI.user_error!`;
     - иначе исходная ошибка пробрасывается без изменений (дальше её превратит
       `call_google_api`, и `play.rb` напечатает только общий UNKNOWN).
     - Тело ответа разбирается в памяти только ради `reason`; ни тело, ни сообщение не
       попадают в лог и в текст исключения.
     - Применяется к RC и Production (Q2).
   - **`play.rb`:** `rescue ProkatPlayStore::ChangesInReview` → печать
     `PLAY_CHANGES_IN_REVIEW: commit refused, edit not committed; inspect Play Console before any retry`
     и выход 1. `rescue ProkatPlayStore::TrackNotClean` → печать его фиксированного кода.
     Остальные `StandardError` (включая `FastlaneCore::Interface::FastlaneError`) →
     существующий `PlayPolicy.safe_error`: только класс, `state UNKNOWN`, без сообщения.
   - **Проверка в публикуемом edit (P-04, P-20).** Модуль `ProkatPlayStore::GuardedPublishEdit`,
     prepend к `Supply::Client`. Активируется только явным вызовом
     `ProkatPlayStore.guard_publish!(track: 'production', version_code: N)` из
     `play.rb` непосредственно перед `Supply::Uploader.new.perform_upload`; для RC не
     активируется (Q3). В режиме preflight (`snapshot`) не активен.
     - `begin_edit` (после `super`, в **том же** edit, до upload): `tracks('production')`;
       каждый release должен иметь статус `completed`; иначе `ProkatPlayStore::TrackNotClean`
       с кодом `PLAY_PRODUCTION_TRACK_NOT_CLEAN status=<status>`. Также
       `list_edit_bundles`/`list_edit_apks` этого edit не должны содержать `N`.
     - `update_track(track_name, track_object)` (до `super`, тот же edit): повторное
       чтение `tracks(track_name)` с тем же правилом; `track_object.releases` — ровно один
       release со статусом `completed` и `version_codes == [N]`. Иначе отказ до `update_edit_track`.
     - Повторное включение защиты в одном процессе или второй `begin_edit` при активной
       защите → отказ.
     - Обоснование — P-20: edit — снимок на момент `insert`; изменение в Console или чужой
       commit инвалидирует edit, commit падает без эффекта.
     - `TrackNotClean` и `ChangesInReview` не наследуют `Google::Apis::Error`.
   - `PlayPolicy.check!` (ранний preflight до сборки): при `channel == 'production'` то же
     правило статусов track `production`. Для RC правило не применяется.
   - `verify_android.dart`: чистая функция
     `void requireTargetSdk(String dumped, {int minimum = 36})` (trim, `int.tryParse`, `≥ minimum`);
     bundletool `dump manifest --bundle=… --xpath=/manifest/uses-sdk/@android:targetSdkVersion`.
7. **Инструкция исполнителю.** Prompt E2.
8. **Effort / Context.** High / файлы этапа, fastlane 2.241.0
   `supply/lib/supply/{client,uploader}.rb` (`call_google_api`, `commit_current_edit!`,
   `perform_upload`, `update_track`), документы Edits и edits.commit (пример ответа
   `CHANGES_ALREADY_IN_REVIEW`), раздел 5.
9. **Тесты.**
   - `sdk_contract_test.rb`: keyword присутствует; `ErrorIfInReview` и `GuardedPublishEdit`
     в `ancestors`; `commit_edit` на экземпляре сервиса с подменённым
     `execute_or_queue_command` даёт `command.query['changesInReviewBehavior'] == 'ERROR_IF_IN_REVIEW'`,
     даже если вызывающий передал `CANCEL_IN_REVIEW_AND_SUBMIT`; `Supply::Client` содержит
     `begin_edit`, `tracks`, `update_track`, `commit_current_edit!` с ожидаемой арностью;
     `AbstractGoogleServiceClient#call_google_api` существует (контракт P-26).
   - `play_store_test.rb`, **полный путь через обёртку** без сети: настоящий
     `Supply::Client#commit_current_edit!` (с подставленным `current_edit`) над настоящим
     сервисом, у которого `execute_or_queue_command` бросает
     `Google::Apis::ClientError` (status 400, тело — пример Google с
     `reason: CHANGES_ALREADY_IN_REVIEW` и строкой-сентинелом `SECRET_SENTINEL`) →
     наружу выходит `ProkatPlayStore::ChangesInReview`, а **не** `FastlaneError`;
     сообщение исключения фиксированное и не содержит сентинел.
   - Тот же путь с 403 и с 400 без нужного `reason` → наружу `FastlaneError` (поведение
     `call_google_api`); отображение `play.rb` (функция, вынесенная для теста, например
     `PlayPolicy.publish_failure_line(error)`) даёт общий UNKNOWN без сентинела.
   - Защита публикуемого edit, fake-клиент:
     - **TOCTOU:** preflight-снапшот видит только `completed` → policy OK; публикуемый edit
       при `begin_edit` видит `draft` → `TrackNotClean`; upload, `update_edit_track`,
       `commit_edit` не вызывались;
     - при `begin_edit` чисто, при `update_track` чтение возвращает `inProgress` → отказ;
       `update_edit_track` и `commit_edit` не вызывались;
     - `halted`, `statusUnspecified`, неизвестный статус → отказ;
     - `N` уже есть в bundles публикуемого edit → отказ до upload;
     - `track_object` с двумя releases или с другим кодом → отказ;
     - защита не активирована (RC) → вызовы проходят без дополнительных чтений;
     - commit «инвалидированного» edit бросает ошибку → печатается UNKNOWN,
       `PLAY_EDIT_COMMITTED` не печатается.
   - `play_policy_test.rb`: production + track `production` с `draft`/`inProgress`/
     `halted`/`statusUnspecified`/`weird` → blocked; только `completed` → OK;
     RC при production `draft` → OK; прежние случаи без изменений.
   - `verify_android_test.dart`: `36`, `37`, `" 36\n"` → OK; `35`, `""`, `abc`, `-1` → BLOCK.
   - Полный Dart, Python, Ruby наборы.
10. **Приёмка.**
    - [ ] Без keyword в SDK загрузка `play_store.rb` падает.
    - [ ] Любой `commit_edit` отправляет `ERROR_IF_IN_REVIEW`.
    - [ ] `CHANGES_ALREADY_IN_REVIEW` классифицируется в prepend к `commit_edit`; тест полного
      пути через `commit_current_edit!` и `call_google_api` доказывает фиксированный код
      и отсутствие тела ответа в выводе.
    - [ ] Статусы track `production` проверяются **в публикуемом edit**; тест TOCTOU проходит.
    - [ ] AAB с target < 36 не доходит до `play.rb publish`.
    - [ ] Android workflow запускает все три Ruby-теста.
    - [ ] RC: track `internal`, `completed`, защита публикуемого edit не активна.
11. **Негативные сценарии.** SDK без параметра; вызывающий передаёт другой behavior;
    `CHANGES_ALREADY_IN_REVIEW`; 400 с другим reason; 403; тело с сентинелом; draft
    появился после preflight; неизвестный статус release; код уже в bundles; лишний
    release в `track_object`; target 35; пустой вывод bundletool; инвалидированный edit.
12. **Регрессии RC.** Если Q2 = «да», RC с открытым review теперь падает
    `PLAY_CHANGES_IN_REVIEW`, а не отменяет его. Отражается в runbook на этапе 5.
13. **Риски и откат.** Prepend в чужой gem: при обновлении fastlane или google-apis
    контракт-тест обязан упасть. Edit, не прошедший commit, Play удаляет сам; после
    `PUBLISHER_INVOKED` исход всё равно UNKNOWN до проверки консоли. Откат — `git revert`.
    STOP, если Ruby-тесты нельзя запустить.
14. **Владелец.** Решения Q2, Q3. Live-проверки Play не выполняются.
15. **Аудит.** Diff; вывод трёх Ruby-тестов; новый Dart-тест; grep: `commit_edit` нигде
    не вызывается в обход сервиса; `e.body`/`e.message` не печатаются; защита
    активируется только в публикующей ветке `play.rb`; Gemfile.lock не менялся.

---

## 9. Этап 3 — iOS: preflight и защита выбора версии, submission и confirm в издателе

1. **Цель.** Ни preflight, ни издатель не могут переименовать чужую версию, изменить
   версию в ревью или подтвердить чужой submission — в том числе если состояние
   изменилось после preflight. UNKNOWN останавливает прогон.
2. **Проблемы.** P-07, P-08, P-19, P-24, P-28.
3. **Зависимости.** Этапы 1 и 1Б приняты (этап 2 не обязателен).
4. **Границы.**
   - Можно: `tool/release/ios_store.py` (production-путь `preflight`/`main`, коды и стадии),
     новый чистый модуль `tool/release/apple_review_policy.py` (только stdlib, без сети),
     `tool/release/apple_publish.py` (установка защит, version guard),
     `tool/release/ios_store_test.py`, `tool/release/apple_publish_test.py`, новый
     `tool/release/apple_review_policy_test.py`; `tool/release/apple_diagnostic.py` —
     **только** если требуется синхронизация allowlist кодов.
   - Нельзя: RC-ветки `publish_arguments` и `checked_publish_arguments`,
     `confirm_testflight_distribution`, argv production, `codemagic.yaml`,
     `requirements*.txt`, версию Codemagic CLI, POST/PATCH/DELETE в собственном HTTP-клиенте
     `ios_store.py`, маркер `PUBLISHER_INVOKED` и `CM_TRIGGER_SOURCE` (этап 4).
5. **Участки кода.** `preflight(context)`, `read_apple_state`, `all_pages`,
   `FAILURE_CODES`, `STAGES`, `SUCCESS_EVENTS`, `validate_apple_environment`, `main`
   в `ios_store.py`; `main`, `strict_localizations`, `validate_publish_arguments` в
   `apple_publish.py`.
6. **Решение.**

   **6.1. Сверка с источниками (без запросов к живому магазину).**

   | Факт | Значение | Источник | Статус |
   | --- | --- | --- | --- |
   | Запрос CLI 0.70.0 для выбора версии | `GET /v1/apps/{id}/appStoreVersions?limit=100&filter[appStoreState]=DEVELOPER_REJECTED,INVALID_BINARY,METADATA_REJECTED,PREPARE_FOR_SUBMISSION,REJECTED,WAITING_FOR_REVIEW&filter[platform]=IOS`, обход `links.next` до конца | `SubmitToAppStoreAction._get_editable_app_store_version`; `Apps.list_app_store_versions_data`; `ResourceManager.Filter.as_query_params`; `AppStoreConnectApiClient._paginate` | ПОДТВЕРЖДЕНО |
   | Выбор CLI | максимум по `versionString` среди найденных; затем PATCH `versionString`, `build`, `releaseType` или POST новой версии | `_ensure_app_store_version`, `_update_existing_app_store_version`, `AppStoreVersions.modify/create` | ПОДТВЕРЖДЕНО |
   | Последовательность мутаций CLI | `_ensure_app_store_version` → локализации → `_create_review_submission` → `create_review_submission_item` → `confirm_review_submission` | `SubmitToAppStoreAction._submit_to_app_store` | ПОДТВЕРЖДЕНО |
   | Review submission в CLI | `POST /v1/reviewSubmissions`; при ошибке «another reviewSubmissions with id … still in progress» — `read` этого id и дальнейшее использование | `_create_review_submission`, `ReviewSubmissions.create/read` | ПОДТВЕРЖДЕНО |
   | Где определены item и confirm | `ReviewSubmissionItemsActionGroup.create_review_submission_item` (возвращает `ReviewSubmissionItem` с id), `ReviewSubmissionsActionGroup.confirm_review_submission` (PATCH `submitted=true`); список items — `ReviewSubmissions.list_items` | `action_groups/review_submission_items_actions_group.py`, `action_groups/review_submissions_actions_group.py`, `versioning/review_submissions.py` | ПОДТВЕРЖДЕНО |
   | Атомарное подтверждение «только если items не менялись» | Не предоставляется: PATCH без условий (ETag/версия не используются) | `ReviewSubmissions.modify` | ПОДТВЕРЖДЕНО отсутствие (P-28) |
   | `AppVersionState` (актуальное поле) | 15 значений: `ACCEPTED`, `DEVELOPER_REJECTED`, `IN_REVIEW`, `INVALID_BINARY`, `METADATA_REJECTED`, `PENDING_APPLE_RELEASE`, `PENDING_DEVELOPER_RELEASE`, `PREPARE_FOR_SUBMISSION`, `PROCESSING_FOR_DISTRIBUTION`, `READY_FOR_DISTRIBUTION`, `READY_FOR_REVIEW`, `REJECTED`, `REPLACED_WITH_NEW_VERSION`, `WAITING_FOR_EXPORT_COMPLIANCE`, `WAITING_FOR_REVIEW` | OpenAPI App Store Connect 4.3.1 (`components.schemas.AppVersionState`); `codemagic.apple.resources.enums.AppVersionState` 0.70.0 — совпадают | ПОДТВЕРЖДЕНО |
   | `AppStoreVersionState` (`appStoreState`, deprecated с API 3.3) | 20 значений: `ACCEPTED`, `DEVELOPER_REMOVED_FROM_SALE`, `DEVELOPER_REJECTED`, `IN_REVIEW`, `INVALID_BINARY`, `METADATA_REJECTED`, `PENDING_APPLE_RELEASE`, `PENDING_CONTRACT`, `PENDING_DEVELOPER_RELEASE`, `PREPARE_FOR_SUBMISSION`, `PREORDER_READY_FOR_SALE`, `PROCESSING_FOR_APP_STORE`, `READY_FOR_REVIEW`, `READY_FOR_SALE`, `REJECTED`, `REMOVED_FROM_SALE`, `WAITING_FOR_EXPORT_COMPLIANCE`, `WAITING_FOR_REVIEW`, `REPLACED_WITH_NEW_VERSION`, `NOT_APPLICABLE` | OpenAPI 4.3.1 `AppStoreVersionState`. В enum CLI 0.70.0 нет `ACCEPTED`, `READY_FOR_REVIEW`, `NOT_APPLICABLE` | ПОДТВЕРЖДЕНО |
   | Редактируемые состояния CLI | `DEVELOPER_REJECTED`, `INVALID_BINARY`, `METADATA_REJECTED`, `PREPARE_FOR_SUBMISSION`, `REJECTED`, `WAITING_FOR_REVIEW` (по `appStoreState`) | `AppStoreState.editable_states()` 0.70.0 | ПОДТВЕРЖДЕНО |
   | `ReviewSubmission.state` | 7 значений: `READY_FOR_REVIEW`, `WAITING_FOR_REVIEW`, `IN_REVIEW`, `UNRESOLVED_ISSUES`, `CANCELING`, `COMPLETING`, `COMPLETE` | OpenAPI 4.3.1; `ReviewSubmissionState` 0.70.0 — совпадают | ПОДТВЕРЖДЕНО |
   | `GET /v1/reviewSubmissions` | `filter[app]` обязателен; `filter[platform]`, `filter[state]` необязательны; `limit` ≤ 200 | OpenAPI 4.3.1 | ПОДТВЕРЖДЕНО |
   | `fields[appStoreVersions]` | допускает `versionString`, `platform`, `appStoreState`, `appVersionState` | OpenAPI 4.3.1 | ПОДТВЕРЖДЕНО |
   | Сохранение `filter[...]` в `links.next` | Apple должен повторять фильтры в ссылке следующей страницы | Существующий `all_pages` уже требует этого для `/v1/builds` и `/v1/apps/{id}/buildUploads`. Для двух новых endpoint не проверено | ПРЕДПОЛОЖЕНИЕ. Если фильтры пропадут — `APPLE_PAGINATION_FAILED`, fail closed |
   | Соответствие значений `appStoreState` ↔ `appVersionState` | Apple не публикует таблицу соответствия | — | **НЕИЗВЕСТНО. План не вводит соответствие значений**; используются только категории внутри каждого поля (6.3) и запрет противоречий |

   **6.2. Слой 1 — preflight в `ios_store.py` (только GET, через `all_pages`/`checked_url`).**

   - Версии: `/v1/apps/{id}/appStoreVersions?filter[platform]=IOS&fields[appStoreVersions]=versionString,platform,appStoreState,appVersionState&limit=100`.
     Без фильтра по состоянию. `limit=100`, как у CLI.
   - Submissions: `/v1/reviewSubmissions?filter[app]={id}&filter[platform]=IOS&fields[reviewSubmissions]=platform,state&limit=200`.
     Без `filter[state]`: незнакомое состояние должно стать UNKNOWN, а не выпасть из выборки.
   - Пагинация: существующие гарантии `all_pages` — тот же путь и те же `filter[...]`,
     только хост Apple, без редиректов, не больше 100 страниц, без циклов и дубликатов id,
     согласованный `meta.paging.total`, общий дедлайн 90 секунд. Любое нарушение — UNKNOWN.
   - Вызов только при `context["channel"] == "production"` внутри `preflight(context)`:
     до сборки и перед upload. Этот слой — ранняя дешёвая остановка, **не** единственная защита.

   **6.3. Классификатор (`apple_review_policy.classify(target_version, versions, submissions)`).**

   Категории назначаются **внутри каждого поля отдельно**, по его собственным значениям 6.1;
   соответствие значений между полями не предполагается.

   | Категория | `appVersionState` (15) | `appStoreState` (20) |
   | --- | --- | --- |
   | ACTIVE — ревью, обработка, ожидание релиза | `WAITING_FOR_REVIEW`, `IN_REVIEW`, `READY_FOR_REVIEW`, `ACCEPTED`, `PENDING_APPLE_RELEASE`, `PENDING_DEVELOPER_RELEASE`, `PROCESSING_FOR_DISTRIBUTION`, `WAITING_FOR_EXPORT_COMPLIANCE` | `WAITING_FOR_REVIEW`, `IN_REVIEW`, `READY_FOR_REVIEW`, `ACCEPTED`, `PENDING_APPLE_RELEASE`, `PENDING_DEVELOPER_RELEASE`, `PROCESSING_FOR_APP_STORE`, `WAITING_FOR_EXPORT_COMPLIANCE` |
   | EDITABLE | `PREPARE_FOR_SUBMISSION`, `DEVELOPER_REJECTED`, `REJECTED`, `METADATA_REJECTED`, `INVALID_BINARY` | `PREPARE_FOR_SUBMISSION`, `DEVELOPER_REJECTED`, `REJECTED`, `METADATA_REJECTED`, `INVALID_BINARY` |
   | FINAL — завершённая версия | `READY_FOR_DISTRIBUTION`, `REPLACED_WITH_NEW_VERSION` | `READY_FOR_SALE`, `REPLACED_WITH_NEW_VERSION`, `REMOVED_FROM_SALE`, `DEVELOPER_REMOVED_FROM_SALE` |
   | UNSUPPORTED — не используется этим pipeline | — | `PENDING_CONTRACT`, `PREORDER_READY_FOR_SALE`, `NOT_APPLICABLE` |

   Пара полей одной версии:

   | Пара | Результат |
   | --- | --- |
   | Хотя бы одно поле ACTIVE | BLOCK `APPLE_VERSION_IN_FLIGHT` |
   | Хотя бы одно поле UNSUPPORTED (и ни одно не ACTIVE) | UNKNOWN `APPLE_VERSION_STATE_UNSUPPORTED` |
   | Оба EDITABLE и значения **буквально равны** | EDITABLE |
   | Оба EDITABLE, но значения различаются | UNKNOWN `APPLE_VERSION_STATE_MISMATCH` |
   | Оба FINAL | FINAL |
   | EDITABLE в одном поле и FINAL в другом | UNKNOWN `APPLE_VERSION_STATE_MISMATCH` |

   Правила (по порядку, первое сработавшее даёт код):

   | № | Условие | Код |
   | --- | --- | --- |
   | R1 | Схема: у версии нет `id`, `versionString`, `platform`, `appStoreState` или `appVersionState`; `platform ≠ IOS`; значение вне списков 6.1; `versionString` не из 1–3 числовых компонентов. У submission нет `id`/`state`; `platform ≠ IOS`; `state` вне 7 значений | `APPLE_RESPONSE_INVALID` (UNKNOWN) |
   | R2 | Есть submission не в `COMPLETE` | `APPLE_REVIEW_SUBMISSION_OPEN` |
   | R3 | Есть версия, пара которой ACTIVE | `APPLE_VERSION_IN_FLIGHT` |
   | R4 | Есть версия, пара которой UNSUPPORTED или MISMATCH | `APPLE_VERSION_STATE_UNSUPPORTED` / `APPLE_VERSION_STATE_MISMATCH` (UNKNOWN) |
   | R5 | EDITABLE-версий больше одной, либо одна со строкой ≠ версии тега | `APPLE_VERSION_CONFLICT` |
   | R6 | FINAL-версия со строкой ≥ версии тега (три компонента, недостающие = 0) | `APPLE_VERSION_NOT_INCREASING` |
   | R7 | Иначе | OK: «создать» (EDITABLE нет) или «продолжить» с id единственной EDITABLE |

   Следствие для CLI: любая версия, которую CLI 0.70.0 может выбрать (`appStoreState` из его
   шести редактируемых), либо даёт ACTIVE (`WAITING_FOR_REVIEW`) → BLOCK, либо обязана быть
   EDITABLE-парой с равными значениями → она и есть одобренная.

   **6.4. Слой 2 — защита в издателе (`apple_publish.py`), в момент мутации.**

   Устанавливается только при `parsed.submit_to_app_store` (production), тем же
   способом, что существующий `strict_localizations`: замена методов на классах
   Codemagic CLI 0.70.0 до `AppStoreConnect.invoke_cli()`. Состояние сессии — модульная
   структура одного процесса: `version_id`, `submission_id`, `item_id`. Все отказы —
   `SystemExit("BLOCKED: <фиксированный код>; no further App Store mutation. Inspect build uploads; no reupload")`,
   без тел ответов.

   | Метод CLI (класс) | Замена делает | Гарантия |
   | --- | --- | --- |
   | `SubmitToAppStoreAction._ensure_app_store_version(app, build, info)` | Заново читает **все** IOS-версии (`self.api_client.apps.list_app_store_versions_data(app, resource_filter=AppStoreVersions.Filter(platform=Platform.IOS))`) и свежий список submissions, пропускает через `classify` с `info.version_string`. Блок → отказ до PATCH/POST. OK → **сама** выполняет ровно одну мутацию: `_update_existing_app_store_version` для одобренной версии (по id) или `create_app_store_version` при «создать». Проверяет id/`created` и `versionString`. Записывает `version_id` | Мутируется только версия, одобренная классификатором в этот момент |
   | `SubmitToAppStoreAction._create_review_submission(app, platform)` | Читает submissions `review_submissions.list(ReviewSubmissions.Filter(app=app.id, platform=platform))`; любое не-`COMPLETE` или неизвестное состояние → отказ. Затем `review_submissions.create(platform, app)`; **любая** ошибка API → отказ (ветка переиспользования удалена). Требует `created is True`, записывает `submission_id` | Своя версия никогда не попадает в чужой submission |
   | `ReviewSubmissionItemsActionGroup.create_review_submission_item(...)` | Требует `review_submission_id == submission_id`, `app_store_version_id == version_id`, отсутствие прочих id, первый вызов. Иначе отказ до POST. Записывает `item_id` из ответа | Один item, наша версия, наш submission |
   | `ReviewSubmissionsActionGroup.confirm_review_submission(review_submission_id, ...)` | Требует `review_submission_id == submission_id` и `item_id`. **Непосредственно перед** PATCH: свежий `review_submissions.list_items(submission_id)` — ровно один item и его id == `item_id`; иначе `APPLE_SUBMISSION_ITEMS_CHANGED` до PATCH. После успешного PATCH — ещё один `list_items`: если items не равны `[item_id]`, печатается `APPLE_SUBMISSION_ITEMS_CHANGED_AFTER_CONFIRM` и выход 1 (исход UNKNOWN); иначе `APPLE_REVIEW_SUBMISSION_CONFIRMED` | Подтверждается только собственный submission с одним нашим item; расхождение обнаруживается и не маскируется |

   - **Остаточное окно (P-28).** Между последним `list_items` и PATCH confirm проходит один
     сетевой обмен. App Store Connect API не даёт условного подтверждения, поэтому
     атомарность **не обещается**. Если кто-то добавит item в наш собственный submission в
     это окно, проверка после confirm это покажет и даст UNKNOWN; автоматическая отмена
     submission не выполняется (это была бы ещё одна мутация) — владелец решает в ASC.
   - Version guard: перед установкой проверить, что все четыре атрибута существуют на
     указанных классах, `AppStoreConnect` разрешает их в заменённые функции, сигнатуры
     совпадают с 0.70.0 (`inspect.signature`). Иначе `PublishCliError` до `invoke_cli`.
   - Отказ слоя 2 происходит **после** upload IPA: исход UNKNOWN, IPA сохраняется в
     Codemagic Artifacts, повторный upload запрещён. Это намеренный fail closed.
   - Окно между перечитыванием версий в слое 2 и PATCH/POST версии — один сетевой обмен;
     условных обновлений в API нет; отвергнет ли Apple PATCH версии, перешедшей в другое
     состояние в это время, не проверено. Остаточный риск записывается.
   - Рассмотренная альтернатива — разделить upload и submission отдельными командами.
     Отклонена: те же методы CLI вызываются в обоих вариантах.

   **6.5. Прочее.**
   - Production закрепляет `config["app_id"] == "6817078475"` (константа `APP_ID`).
     Код ошибки существующий: `APPLE_APP_MISMATCH`.
   - Новые коды (`APPLE_REVIEW_SUBMISSION_OPEN`, `APPLE_VERSION_IN_FLIGHT`,
     `APPLE_VERSION_STATE_UNSUPPORTED`, `APPLE_VERSION_STATE_MISMATCH`,
     `APPLE_VERSION_CONFLICT`, `APPLE_VERSION_NOT_INCREASING`, `APPLE_SUBMISSION_GUARD_FAILED`,
     `APPLE_SUBMISSION_ITEMS_CHANGED`, `APPLE_SUBMISSION_ITEMS_CHANGED_AFTER_CONFIRM`) и стадии
     (`versions`, `submissions`) добавить в allowlist. Сообщения фиксированные, без тел
     ответов, без `versionString` чужих версий.
7. **Инструкция исполнителю.** Prompt E3.
8. **Effort / Context.** High / `ios_store.py`, `apple_publish.py`, их тесты, исходники
   cli-tools v0.70.0 (`tools/app_store_connect/actions/submit_to_app_store_action.py`,
   `action_groups/review_submissions_actions_group.py`,
   `action_groups/review_submission_items_actions_group.py`, `apple/resources/enums.py`,
   `apple/app_store_connect/apps/apps.py`, `apple/app_store_connect/versioning/{app_store_versions,review_submissions}.py`,
   `apple/app_store_connect/api_client.py`), разделы 9.6.1–9.6.4.
9. **Тесты.** Fake-объекты, без сети:
   - `apple_review_policy_test.py`:
     - категории заданы в тесте **независимо** (отдельными литералами, не импортом из модуля);
     - **все 300 пар** `appStoreState × appVersionState` проверяются табличным тестом против
       ожидаемого результата таблицы «Пара полей»;
     - именованные случаи: (`IN_REVIEW`, `READY_FOR_DISTRIBUTION`) → `APPLE_VERSION_IN_FLIGHT`;
       (`READY_FOR_SALE`, `IN_REVIEW`) → `IN_FLIGHT`; (`PROCESSING_FOR_APP_STORE`,
       `READY_FOR_DISTRIBUTION`) → `IN_FLIGHT`; (`PREPARE_FOR_SUBMISSION`, `READY_FOR_DISTRIBUTION`) →
       `MISMATCH`; (`REJECTED`, `METADATA_REJECTED`) → `MISMATCH`; (`NOT_APPLICABLE`,
       `PREPARE_FOR_SUBMISSION`) → `UNSUPPORTED`; (`PENDING_CONTRACT`, `READY_FOR_DISTRIBUTION`) →
       `UNSUPPORTED`; (`REMOVED_FROM_SALE`, `READY_FOR_DISTRIBUTION`) → FINAL;
     - значение вне списков и отсутствующее поле → R1;
     - каждое из 7 значений `ReviewSubmission.state`, отсутствующее и неизвестное;
     - каждое правило R1–R7; порядок правил (submission открыт и версия в ревью → R2).
   - `ios_store_test.py` (слой 1): URL точно как в 6.2, только GET, без `filter[state]` и
     `filter[appStoreState]`; 401/403/429/5xx/timeout/битая пагинация/фильтр пропал в
     `next` → UNKNOWN без издателя; при любом блоке `subprocess.run` не вызывается; RC не
     запрашивает новые URL; production argv идентичен текущему; `APP_STORE_APP_ID` ≠
     `6817078475` → `APPLE_APP_MISMATCH`.
   - `apple_publish_test.py` (слой 2), fake `api_client` с журналом вызовов:
     - **TOCTOU версии:** слой 1 видел пусто, при `_ensure_app_store_version` появилась
       версия с (`IN_REVIEW`, `READY_FOR_DISTRIBUTION`) или в `WAITING_FOR_REVIEW` → отказ;
       `modify`/`create` версии не вызывались;
     - **TOCTOU переименования:** появилась EDITABLE-версия с другой строкой → отказ до PATCH;
     - **TOCTOU submission:** при `_create_review_submission` список содержит `READY_FOR_REVIEW` → отказ до POST;
     - POST submission отвечает «another reviewSubmissions … still in progress» → отказ;
       `read`, item, confirm не вызывались;
     - item с чужим `review_submission_id` или чужой версией, повторный item → отказ до POST;
     - **гонка confirm:** перед PATCH `list_items` возвращает два items или один чужой id
       → `APPLE_SUBMISSION_ITEMS_CHANGED`, PATCH не вызывался; `list_items` с ошибкой →
       отказ без PATCH; после PATCH `list_items` возвращает лишний item →
       `APPLE_SUBMISSION_ITEMS_CHANGED_AFTER_CONFIRM`, выход 1, отмена submission не вызывалась,
       `APPLE_REVIEW_SUBMISSION_CONFIRMED` не печатается;
     - confirm чужого id или без item → отказ до PATCH;
     - счастливый путь: ровно одна мутация версии, один POST submission, один POST item,
       `list_items` → PATCH → `list_items`, затем `APPLE_REVIEW_SUBMISSION_CONFIRMED`;
     - version guard: отсутствующий метод или изменённая сигнатура → `PublishCliError` до `invoke_cli`;
     - RC (`submit_to_app_store` ложно) — замены не устанавливаются, RC-тесты не меняются.
   - Существующие 169 тестов проходят, `testflight_distribution_test.py` не изменён.
10. **Приёмка.**
    - [ ] Категории и таблица пар 6.3 реализованы буквально в `apple_review_policy.py`;
      соответствие значений между полями не введено.
    - [ ] Любое ACTIVE в любом поле блокирует; противоречивые и неподдерживаемые пары дают UNKNOWN.
    - [ ] Табличный тест 300 пар и именованные случаи проходят.
    - [ ] Слой 2 перечитывает состояние в момент мутации, сам выполняет единственную
      мутацию версии и никогда не переиспользует чужой submission.
    - [ ] Confirm: свежая проверка items до PATCH и проверка после PATCH; атомарность
      нигде не заявлена.
    - [ ] Все тесты изменения состояния после preflight проходят без вызова соответствующих мутаций.
    - [ ] Собственный HTTP-клиент `ios_store.py` — только GET; RC и argv не изменены.
    - [ ] Ошибки и коды не содержат тел ответов или значений env.
11. **Негативные сценарии.** Все строки R1–R6 и таблицы пар в обоих слоях; изменения
    состояния после preflight (версия, переименование, submission, items); POST с
    переиспользованием; чужой item или confirm; пустой ответ на второй странице; `next`
    на чужой хост или без фильтров; дубликат ID; таймаут общего дедлайна 90 секунд;
    несовпадение сигнатур CLI.
12. **Регрессии RC.** `ios_store_test.py` RC-случаи, `testflight_distribution_test.py`,
    существующие `apple_publish_test.py`.
13. **Риски и откат.** Новые значения состояний Apple дадут UNKNOWN. Отказ слоя 2 после
    upload оставляет IPA без submission — UNKNOWN, ручная обработка в ASC. Замена методов
    привязана к CLI 0.70.0: version guard обязан остановить другой CLI. Откат — `git revert`.
14. **Владелец.** Нет действий до фазы B. Live GET не выполняется.
15. **Аудит.** Diff; вывод Python-набора; построчное сопоставление 6.1–6.4 с тестами;
    grep на `method="POST"|PATCH|DELETE` в `ios_store.py` (должно быть пусто); проверка,
    что в `apple_publish.py` нет пути, где CLI выбирает версию или submission сам, и нет
    вызова отмены submission.

---

## 10. Этап 4 — облачное разрешение, источник события и маркер вызова издателя

1. **Цель.** Один push тега, забытый `true`, чужой тег, re-run Android без нового
   разрешения и любой не-webhook запуск iOS не публикуют. Лог CI однозначно показывает,
   вызывался ли издатель. Защита от replay события обеспечивается ruleset (владелец),
   а не кодом.
2. **Проблемы.** P-09, P-18, P-23 (кодовая часть), P-29.
3. **Зависимости.** Этапы 1, 1Б, 2 и 3 приняты. **Q1 (вариант A), Q8 и Q9 приняты владельцем 2026-10-22.** Ниже —
   этот принятый контракт, а не ожидающая выбора рекомендация. Q7 не принят: этап 5 не разрешён.
4. **Границы.**
   - Можно: `tool/release/release.dart` (`validateCloudAuthorization`, проверка
     `CM_TRIGGER_SOURCE` для iOS production в `validateEvent`, вызов в `ci`),
     `tool/release/cli.dart` (guard-строки, строка облачного разрешения в preview),
     `.github/workflows/android-release.yml` (env и шаг gate), `tool/release/play.rb` и
     `tool/release/play_policy.rb` (функция авторизации, маркер), `tool/release/ios_store.py`
     (`main`), `tool/release/apple_publish.py` (только строка маркера), тесты
     `release_test.dart`, `cli_test.dart`, `config_test.py`, `ios_store_test.py`,
     `apple_publish_test.py`, `play_policy_test.rb`, `play_store_test.rb`; раздел U5 в
     `docs/ci-cd/MANUAL_SETUP.md`.
   - Нельзя: создавать или менять секреты, переменные, rulesets, GitHub settings,
     Codemagic UI, триггеры workflow, RC-путь.
5. **Участки кода.** Шаг `Reject production until U5`; `validateEvent`; `validateProduction`;
   `play.rb` (строки с `PRODUCTION_PUBLISHING_ENABLED` и вызов `perform_upload`);
   `ios_store.py main`; `apple_publish.py main`; список guard в `ReleaseCli.plan`;
   `ReleaseCli.execute` (preview).
6. **Решение (вариант A).**
   - Переменные и форматы — раздел 5.4. Android сравнивает с
     `"<tag>@<commit>#<GITHUB_RUN_ATTEMPT>"`, iOS — с `"<tag>@<commit>"`, где `commit` —
     уже проверенный `GITHUB_SHA` или `CM_COMMIT`. Отсутствующий или нечисловой
     `GITHUB_RUN_ATTEMPT` → BLOCK.
   - iOS production: `CM_TRIGGER_SOURCE` должен быть ровно `webhook`; `api`, `schedule`,
     пусто или иное → BLOCK `IOS_PRODUCTION_REQUIRES_WEBHOOK` до любых других шагов
     (проверяется в `release.dart ci` и повторно в `ios_store.py` для production). RC не проверяет.
   - Правило для production в CI: `PRODUCTION_PUBLISHING_ENABLED == "true"` **и**
     точное совпадение разрешения своей платформы (и для iOS — webhook).
   - Слои Android (каждый независимо): bash-шаг gate до установки Flutter
     (`$GITHUB_REF_NAME@$GITHUB_SHA#$GITHUB_RUN_ATTEMPT`); `release.dart ci`;
     `play.rb preflight`; `play.rb publish`.
   - Слои iOS: `release.dart ci`; `ios_store.py validate-publish`; `ios_store.py preflight`;
     `ios_store.py publish`.
   - Маркер `PUBLISHER_INVOKED` — точные места и смысл в разделе 5.5, для обоих каналов.
   - Preview production (dry-run и реальный запуск) печатает
     `Cloud authorization required: GitHub variable PRODUCTION_RELEASE_AUTH_ANDROID = <tag>@<sha>#1`
     или `… Codemagic variable PRODUCTION_RELEASE_AUTH_IOS = <tag>@<sha>` и строку
     `Server tag ruleset is a U5 precondition (OC-C0); not verifiable from this CLI`.
   - Guard в `ReleaseCli.plan` **только для channel `production`**: Android workflow
     обязан содержать `PRODUCTION_RELEASE_AUTH_ANDROID` и `GITHUB_RUN_ATTEMPT`; iOS
     принимается через `release.dart`, содержащий `validateCloudAuthorization` и
     `CM_TRIGGER_SOURCE`. RC-план новые guard-строки не требует.
   - `config_test.py` закрепляет точный список входов Android. Обновить его явно,
     добавив `PRODUCTION_RELEASE_AUTH_ANDROID`, а не ослаблять проверку.
   - `MANUAL_SETUP.md`, раздел U5: фазы C, D, P, R и правила 5.4–5.9.
7. **Инструкция исполнителю.** Prompt E4.
8. **Effort / Context.** High / все файлы этапа, разделы 5.4–5.9, текущие тесты gate.
9. **Тесты.**
   - `release_test.dart` (`validateCloudAuthorization`): матрица
     `enabled ∈ {absent,'true','TRUE','false'}` × разрешение ∈ {absent, exact, тот же тег
     с другим SHA, другой тег с тем же SHA, exact+' ', ' '+exact, exact в верхнем
     регистре, значение для другой платформы, rc-тег}; для Android дополнительно
     `attempt ∈ {1, 2, absent, 'x'}` × суффикс ∈ {`#1`, `#2`, без суффикса}. Пропускает
     только (`'true'`, exact, совпавшая попытка). RC — функция не вызывается.
   - `validateEvent` для iOS production: `CM_TRIGGER_SOURCE` ∈ {`webhook`} → OK;
     {`api`, `schedule`, `''`, отсутствует, `Webhook`} → BLOCK; для RC не проверяется.
   - Тест «разрешение не расходуется»: одинаковые входы дважды дают одинаковый результат;
     **новый run** (попытка 1) с тем же тегом и активным `#1` — **проходит** gate. Тест
     фиксирует, что replay события останавливает только ruleset (OC-C0), а не код.
   - `config_test.py`: gate-шаг идёт до `Install pinned Flutter`, ссылается на
     `vars.PRODUCTION_RELEASE_AUTH_ANDROID`, `github.ref_name`, `github.sha`,
     `github.run_attempt`; шаги `play.rb` получают переменную; ни один шаг не записывает
     `vars`/`secrets`.
   - `ios_store_test.py`: production без точного совпадения или без webhook → блок до API
     и издателя для `validate-publish`, `preflight`, `publish`; RC работает как раньше.
   - `apple_publish_test.py` и `play_store_test.rb`: `PUBLISHER_INVOKED` печатается после всех
     проверок и непосредственно перед вызовом издателя; при блоке до этого места не
     печатается; `validate-publish` его не печатает.
   - `cli_test.dart`: production-guard отсутствует → BLOCK; RC без guard → OK;
     preview содержит строку облачного разрешения и строку о ruleset.
10. **Приёмка.**
    - [ ] Четыре слоя Android и четыре слоя iOS проверяют разрешение своей платформы независимо.
    - [ ] iOS production в штатном webhook-контексте доходит до сборки. `CM_TRIGGER_SOURCE == webhook` — фильтр, не attestation. Постоянный replay-block снят решением 5.10.
    - [ ] Android-разрешение привязано к номеру попытки; тест явно показывает, что новый run
      с попыткой 1 код не останавливает.
    - [ ] `PUBLISHER_INVOKED` стоит строго перед вызовом издателя и не утверждает мутацию.
    - [ ] RC не читает новые переменные и не проверяет trigger source.
    - [ ] Секреты, переменные и rulesets не создавались.
    - [ ] MANUAL_SETUP U5 описывает ruleset как обязательное условие, выставление и очистку
      разрешения, фазы P и R и запрет повтора iOS.
11. **Негативные сценарии.** Boolean `true`, разрешение другого тега; тот же тег на
    другом SHA; разрешение `true`, boolean `false`; пробел в значении; значение iOS в
    Android-переменной; RC-тег в переменной; re-run Android с прежним `#n`; iOS `api`/`schedule`;
    re-run после очистки переменной.
12. **Регрессии RC.** Все RC-тесты; `config_test.py` на неизменность RC-триггеров; лог RC
    получает только строку `PUBLISHER_INVOKED`.
13. **Риски и откат.** Replay события без ruleset не останавливается кодом (P-23) — U5
    заблокирован решением Q9 до ruleset. Риск write-доступа к секретам кодом не снимается.
    Откат — `git revert`.
14. **Владелец.** Q1, Q8, Q9; OC-A2, OC-A5 (ruleset).
15. **Аудит.** Diff; таблица «слой → где проверка → тест»; подтверждение, что
    `secrets.*` и `vars.*` в YAML только читаются; grep маркера во всех местах публикации.

---

## 11. Этап 5 — PR-регрессия и эксплуатационная документация

1. **Цель.** Любой PR прогоняет полный набор release-тестов без секретов.
   Документация совпадает с кодом.
2. **Проблемы.** P-10, P-11.
3. **Зависимости.** Этапы 1, 1Б и 2–4 приняты. Q7 (минуты Actions).
4. **Границы.**
   - Можно: `.github/workflows/pull-request.yml` (новый job), `CICD-README.md`,
     `docs/ci-cd/RELEASE_RUNBOOK.md`, `docs/ci-cd/MANUAL_SETUP.md`, `docs/ci-cd/README.md`,
     `tool/release/README.md`, новый `docs/ci-cd/PRODUCTION_READINESS.md`, строки
     `1.2.4+24` в `cli_test.dart` и `cli_docs_test.py`.
   - Нельзя: release workflows, код адаптеров, исторические датированные документы
     (кроме ссылок).
5. **Решение.**
   - Job `release-tooling`: `ubuntu-24.04`, `timeout-minutes: 15`,
     `permissions: contents: read`, без единой ссылки на `secrets`. Python 3.12,
     `pip install -r tool/release/requirements.txt`, `unittest discover`; Ruby 3.3.10,
     `BUNDLE_GEMFILE=tool/release/Gemfile`, `bundle install` с `frozen`, три Ruby-теста.
     PowerShell-тесты на Linux пропускаются явно; они обязательны локально на Windows.
   - Runbook (`RELEASE_RUNBOOK.md`) описывает: классы Git-операций (раздел 1); таблицу и
     свежесть 5.3; правило номеров 5.2; облачное разрешение, ruleset как условие U5 и
     границы 5.4; маркеры и классификацию 5.5; первый релиз и повтор Android 5.6; запрет
     повтора iOS; протокол сбоя push 5.8; **заморозку Play Console 5.9**; Play
     `ERROR_IF_IN_REVIEW`, `PLAY_CHANGES_IN_REVIEW` и проверку track в публикуемом edit;
     оба слоя iOS этапа 3 и окно confirm; порядок фаз раздела 15; RC `+19` и `+24` как
     неизменяемую историю.
   - `PRODUCTION_READINESS.md`: чек-лист раздела 15 с PASS/FAIL по каждому пункту.
6. **Инструкция исполнителю.** Prompt E5.
7. **Effort / Context.** Medium / список документов, этот план, итоговый код этапов 1–4.
8. **Тесты.** Весь Dart, Python и Ruby; `cli_docs_test.py` (ссылки, отсутствие ручных
   команд тегов); `actionlint`, если доступен локально, иначе отметить NOT RUN.
9. **Приёмка.**
    - [ ] Job не ссылается на `secrets`, не имеет `write`-прав.
    - [ ] Ни один текущий гайд не содержит ручного создания, удаления или переноса тегов,
      force-операций или `--tags`.
    - [ ] Пример следующего номера — без конкретного «безопасного» значения, только правило.
    - [ ] Нигде не сказано, что разрешение одноразовое или что схема защищает от replay
      без ruleset.
    - [ ] Повтор существующего тега описан только как путь 5.6 (Android) и протокол 5.8;
      повтор iOS запрещён.
    - [ ] Заморозка Play Console описана в runbook и в readiness.
    - [ ] Все команды, переменные, маркеры и коды в документах существуют в коде.
10. **Негативные сценарии.** Сломанная ссылка; устаревший номер; job, зависящий от сети магазинов.
11. **Регрессии RC.** RC-разделы гайдов не меняют смысл, только номера и ссылки.
12. **Риски и откат.** Расход минут (Q7). Откат — `git revert`.
13. **Владелец.** Q7.
14. **Аудит.** Diff документов против кода (grep команд, переменных, маркеров и кодов ошибок).

---

## 12. Этап 6 — безопасная репетиция и готовность (последний агентский этап)

1. **Цель.** Доказать, что ни один путь не публикует без явного разрешения, и
   подготовить материалы для решения владельца. Этап 6 **не** является подготовкой
   версии или публикацией и не зависит ни от одной фазы B–E.
2. **Зависимости.** Этапы 1, 1Б и 2–5 приняты.
3. **Границы.** Без изменений кода, кроме исправлений, найденных репетицией. Они
   идут отдельным согласованным этапом. Никаких тегов, gate, секретов, переменных,
   rulesets, store-запросов агентом. Локальный env `PRODUCTION_PUBLISHING_ENABLED` агент не
   выставляет. Разрешён один G2 в начале: `git fetch origin main`.
4. **Шаги агента.** Записать `git rev-parse refs/remotes/origin/main` и
   `git ls-remote origin refs/heads/main`; выполнить `git fetch origin main`; записать
   снова. Ветка, CLI из ветки, `origin/main` = `07926a7d` (или текущий, если владелец уже
   что-то слил — тогда ожидания пересчитываются и согласуются заново).

   | Команда | Ожидание |
   | --- | --- |
   | `prokat-rc-android -DryRun` | План `rc/android/v1.2.3+24` (пара RC с `rc/ios/v1.2.3+24`, тот же SHA), `DRY RUN`, без записей и prompt. Только preview, не разрешение |
   | `prokat-rc-ios -DryRun` | `BLOCKED`: `rc/ios/v1.2.3+24` уже существует |
   | `prokat-prod-android -DryRun` | `BLOCKED` историей номеров: `+24` занят `rc/ios/v1.2.3+24` в другом канале. Preview и строка gate не печатаются |
   | `prokat-prod-ios -DryRun` | `BLOCKED` историей: тот же номер той же платформы в канале RC |
   | `prokat-prod-android` без `-DryRun`, env не задан | `BLOCKED` gate: `Production publishing is disabled…`. Ни одной git-команды, prompt не показывается |
   | `prokat-prod-ios` без `-DryRun`, env не задан | То же |
   | `dart tool/release/cli.dart android production --resume-push android/v1.2.3+24 --expect-sha 07926a7dc9dcd5c8467717423130abc65ddba294 --dry-run` | `LOCAL_TAG_MISMATCH` (локального тега нет), без push и prompt |

   - Положительный случай production DryRun доказывается fake-тестами этапов 1 и 4 и
     проверяется владельцем на новом `main` в OC-B5.
   - До и после команд: `git show-ref --tags`, `git ls-remote --tags origin`,
     `git rev-parse refs/remotes/origin/main`, `git status --short` — без изменений.
   - Отчёт `PRODUCTION_READINESS.md` с фактическими результатами и отметкой: фаза A —
     статус от владельца; фазы B–E — не начаты.
5. **Шаги владельца.** После приёмки этапа 6 и отдельного GO — фазы B–E (и P/R по
   необходимости) раздела 15.
6. **Effort / Context.** Medium / этот план, readiness, вывод команд.
7. **Приёмка.** Все ожидания таблицы совпали; теги не изменились; refs изменились только
   единственным разрешённым fetch; чек-лист production-readiness заполнен.
8. **Риски.** Расхождение ожиданий — STOP и отчёт, без «подгонки».

---

## 13. Prompts для исполнителей

Общий заголовок каждого prompt:

> Ты исполнитель одного этапа в репозитории PROKAT (`C:\Users\User\Documents\GitHub\prokat`),
> ветка `feat/production-cicd-hardening`. Прочитай `docs/plans/production-cicd.md`
> целиком: разделы 1, 3, 5 и свой этап. План — техническое задание, но код проверяй сам.
> Git: разрешены только классы G0 и G1 раздела 1 (этап 6 — плюс один указанный G2).
> Запрещено: G2–G4 вне указанного, push, merge, теги, удаление и перенос тегов,
> изменения секретов, переменных, rulesets и консолей магазинов, вызовы реальных API
> Google и Apple, выставление `PRODUCTION_PUBLISHING_ENABLED`, `git reset --hard`,
> `git clean`, правки вне границ этапа, изменения RC-поведения сверх описанного. Если
> план противоречит коду или тест требует credentials — остановись и опиши проблему.
> В конце: команды и фактический вывод, diff-статистика, список негативных сценариев с
> тестами, один коммит этапа без push.

**E1 (Effort Medium, Context: этап 1 + разделы 1, 4, 5.2, 5.3).**
Локально удали пять untracked-файлов раздела 4 через `Remove-Item -LiteralPath`
(не `git rm`, не `git clean`), предварительно проверив `git ls-files` (должны
отсутствовать) и `git grep` (нет ссылок); приложи `git status --short` до и после.
Реализуй таблицы и шаги свежести раздела 5.3 в `main()`, `ReleaseCli.plan`,
`ReleaseCli.execute` и `ReleasePlan`, канал в `validateBuildHistory`/`validateStores`
и тесты пункта 9: учёт **всех** вызовов git, устаревший и отсутствующий tracking-ref,
отказ без git и для Dart CLI, и для `prokat-prod-android`/`prokat-prod-ios` в окружении
без git. Не трогай YAML, Ruby, Python-код, `prokat-release.ps1`, `CICD-README.md` и
режим `--resume-push`. Не обновляй tracking-ref. Покажи вывод трёх команд пункта 15 и
состояние тегов и refs до и после.

**E1B (Effort Medium, Context: этап 1Б + раздел 5.8 + итог этапа 1).**
Реализуй режим `--resume-push <tag> --expect-sha <sha>` строго по 5.8: локальная проверка,
строгий разбор `ls-remote` с четырьмя классификациями, условия повтора, подтверждение
полным именем тега, ровно один exact-ref push, повторная проверка. Замени текст ошибки
push в `execute` на ссылку на этот режим. Никакого `tag -d`, `--delete`, `--force`,
`--tags`, `fetch`. Тесты пункта 9 на fake git. Не трогай PowerShell, YAML, Ruby, Python.

**E2 (Effort High, Context: этап 2 + fastlane 2.241.0 `supply/client.rb` (`call_google_api`, `commit_current_edit!`), `uploader.rb`, документы Google Edits и edits.commit).**
Реализуй prepend `ERROR_IF_IN_REVIEW` с fail-closed проверкой сигнатуры и классификацией
`CHANGES_ALREADY_IN_REVIEW` **внутри** prepend через собственный класс исключения, не
наследующий `Google::Apis::Error`; защиту публикуемого edit (`GuardedPublishEdit` в
`begin_edit` и `update_track`, активируется только из публикующей ветки `play.rb` для
production); правило track в `PlayPolicy.check!`; `requireTargetSdk` и тест к нему; два
bundle-теста в Android workflow. Обязательны тест полного пути через
`Supply::Client#commit_current_edit!` с сентинелом в теле ответа и тест TOCTOU для track.
Не печатай тела ответов и сообщения исходных ошибок. Не меняй `Gemfile.lock`, track RC,
`release_status`, gate и маркеры. Ruby-тесты запускай только командой раздела 6. Если
Docker недоступен — STOP, этап не сдаётся.

**E3 (Effort High, Context: этап 3 целиком, особенно 6.1–6.4; исходники cli-tools v0.70.0 из пункта 8).**
Создай `apple_review_policy.py` с категориями по каждому полю буквально по 6.3, таблицей
пар и функцией `classify` (R1–R7 по порядку). Не вводи соответствие значений между
полями. Добавь в `ios_store.py` GET-only слой 1 строго с URL из 6.2 и закрепление app ID.
В `apple_publish.py` установи для production замены четырёх методов из таблицы 6.4 с
version guard, проверкой items до и после confirm и без автоматической отмены submission;
переиспользование чужого submission удали полностью. Обязательны табличный тест 300 пар
(категории в тесте — независимые литералы), именованные пары, fake-тесты изменения
состояния после preflight и гонки confirm. Не меняй RC, argv, `all_pages`. Если метод
CLI 0.70.0 не совпадает с описанием — STOP.

**E4 (Effort High, Context: этап 4 + разделы 5.4–5.9; только после записанных решений Q1, Q8, Q9).**
Реализуй `validateCloudAuthorization` с форматами 5.4 (Android с номером попытки),
`CM_TRIGGER_SOURCE == webhook` для iOS production, во всех слоях таблицы этапа 4; маркер
`PUBLISHER_INVOKED` строго в местах 5.5; строки облачного разрешения и ruleset в preview;
тесты-матрицы, включая тест, что новый run с попыткой 1 проходит gate (replay
останавливает только ruleset). Ни одного `gh secret`/`gh variable`/ruleset, ни одной
правки настроек. RC новые переменные и trigger source не читает. Не пиши, что разрешение
одноразовое, что маркер доказывает мутацию или что код защищает от replay.

**E5 (Effort Medium, Context: этап 5 + разделы 1, 5 и 15 + итоговый код).**
Добавь job `release-tooling` без секретов и обнови документы по списку. Порядок
действий владельца бери только из раздела 15, правила — только из 5.2–5.9. Каждое
утверждение документа сверяй с кодом через grep и ссылайся на файл.

**Аудитор (read-only, Effort Medium, Context: diff этапа + план).**
Проверь diff этапа против границ и приёмки, запусти тесты раздела 6, перечисли
расхождения. Ничего не меняй.

---

## 14. Решения владельца

| ID | Вопрос | Рекомендация | Нужно до |
| --- | --- | --- | --- |
| Q1 | Модель облачного разрешения | **Принято владельцем 2026-10-22, вариант A:** boolean `PRODUCTION_PUBLISHING_ENABLED` плюс отдельная переменная платформы (`PRODUCTION_RELEASE_AUTH_ANDROID`, `PRODUCTION_RELEASE_AUTH_IOS`, форматы 5.4). Общая переменная не заменяет платформенную. Production capability остаётся выключенной до отдельной активации U5 | этапа 4 |
| Q2 | `ERROR_IF_IN_REVIEW` и классификация для RC | Да: иначе RC-коммит может отменить production review | этапа 2 |
| Q3 | Production track с `draft`/`inProgress`/`halted` блокирует publish | Да; RC не затрагивается | этапа 2 |
| Q4 | `AFTER_APPROVAL` или `MANUAL`; phased release | Оставить `AFTER_APPROVAL` и дефолт приложения | OC-C1 |
| Q5 | Версия и номер первого Production | `X.Y.Z` > последней FINAL-версии App Store; `N` > 24, > max Play, > max Apple (включая Build Uploads) | OC-B3 |
| Q6 | Локальная очистка пяти promotion-файлов на этапе 1 | Да (владелец разрешил); копия — по желанию владельца | этапа 1 |
| Q7 | Job release-tooling в каждом PR | Не утверждено. Рекомендация плана не является решением владельца; этап 5 не разрешён | этапа 5 |
| Q8 | Повтор iOS | **Принято владельцем 2026-10-22:** повтор прежнего тега запрещён. E4-R1 считал `CM_TRIGGER_SOURCE` недостаточным и F1 незакрытым. **Уточнено E4-LEAN (5.10):** запрет остаётся операционным. Фильтр webhook сохраняется и не является attestation. Постоянная блокировка pipeline из-за невыразимого `event.ref` снята | этапа 4 и OC-C2 |
| Q9 | Что делать, если tag ruleset недоступен на тарифе | **Принято владельцем 2026-10-22: U5 заблокирован**, пока ruleset не создан и не проверен (OC-A5, OC-C0). E4-R1 дополнительно требовал durable atomic claim и код `IOS_PRODUCTION_REPLAY_GUARD_UNAVAILABLE`. **Уточнено E4-LEAN (5.10):** claim store не требуется. Препятствием U5 остаётся непроверенный ruleset, не отсутствие replay backend. Локальные тесты U5 не выполняют | этапа 4 и OC-C0 |

Q1, Q8 и Q9 зафиксированы выше 2026-10-22. В тот же день E4-LEAN (5.10) уточняет Q8 и Q9: exactly-once и отдельный replay store не требуются. Q2–Q6 в этой записи не пересматривались.
Q7 остаётся открытым: этап 5 не стартует, пока владелец отдельно не утвердит его.

---

## 15. Ручные checkpoints владельца

Агент их не выполняет. Значения секретов в чат не передаются. Фазы идут строго по
порядку раздела «Общий порядок работ»; внутри фазы — сверху вниз. FAIL любого пункта
останавливает следующую фазу. Фаза A идёт параллельно агентским этапам; фазы B–E —
только после приёмки этапа 6 и отдельного GO. Фаза P — только при сбое push в OC-D4.
Фаза R сохранена как исторический Android-чеклист NOT_INVOKED. Операционно её заменяет 5.10: тот же production-релиз не перезапускают.

### Фаза A — решения и настройки (параллельно этапам; ничего не включается)

| ID | Действие | PASS | FAIL / STOP |
| --- | --- | --- | --- |
| OC-A1 | Записать решения Q1–Q9 до этапов и checkpoints из колонки «Нужно до». Q1, Q8 и Q9 записаны 2026-10-22; Q7 не записан, поэтому этап 5 не стартует | Решение записано | Зависящий этап или checkpoint не стартует |
| OC-A2 | GitHub: тариф организации, видимость репозитория, Settings → Rules (rulesets), Environments, список людей с write/admin | Записано; write только у доверенных | Неизвестные writers → сначала ограничить доступ |
| OC-A3 | GitHub → Settings → Secrets and variables → Actions: имена RC-секретов и переменных (`ANDROID_*`, `PLAY_SERVICE_ACCOUNT_JSON_BASE64`, `GOOGLE_SERVICES_JSON_BASE64`, `MAPBOX_PUBLIC_TOKEN`, `ANDROID_UPLOAD_CERT_SHA256`, `PLAY_HISTORICAL_MAX_BUILD`) | Все есть; `PRODUCTION_PUBLISHING_ENABLED` отсутствует или `false`; `PRODUCTION_RELEASE_AUTH_ANDROID` отсутствует или пуста | Чего-то нет, или gate уже `true` → STOP |
| OC-A4 | Codemagic: `ios-production` виден; группа `prokat-ios-release` содержит `APP_STORE_APP_ID=6817078475`, `IOS_HISTORICAL_MAX_BUILD`, PEM, plist; integration `prokat-app-store`; signing `app_store`; concurrency 1; кто может менять группу и запускать сборки; по истории RC-сборок тега — что они отмечены как запущенные webhook | Совпадает; gate и `PRODUCTION_RELEASE_AUTH_IOS` отсутствуют | Нет distribution identity → STOP |
| OC-A5 | Создать два tag ruleset (5.4): «immutable» — `refs/tags/android/v*`, `refs/tags/ios/v*`, `refs/tags/rc/**`, Restrict updates + Restrict deletions, bypass пуст, Active; «create» — те же шаблоны, Restrict creations, bypass только роль/команда владельца, Active. Существующие теги не трогаются | Оба активны | Тариф не позволяет → Q9 |

### Фаза B — подготовка версии (после приёмки этапа 6 и GO)

| ID | Действие | PASS | FAIL / STOP |
| --- | --- | --- | --- |
| OC-B1 | Play: в Console (или `play_access.rb` по отдельному GO — **создаёт и удаляет temporary edit**) записать максимум versionCode (включая drafts), статусы `production`/`internal`, primary locale, Managed publishing, наличие production access, очередь review, «Changes ready to send for review» | Записано; production track без чужих draft/inProgress/halted; production access есть | Abort edit не подтверждён; нет production access → STOP |
| OC-B2 | App Store Connect: максимум build и Build Uploads; App Store versions с обоими полями состояния; review submissions; скриншоты, privacy, age rating, контакт ревьюера, export compliance | По правилам 9.6.3 ничего не блокирует; метаданные заполнены | ACTIVE, UNSUPPORTED, MISMATCH или открытый submission → разрешить вручную, повторить OC-B2 |
| OC-B3 | Выбрать `X.Y.Z+N` по Q5 на основе OC-B1 и OC-B2; подготовить notes | Записано | — |
| OC-B4 | PR ветки в `dev`; затем bump и notes в `dev`; затем PR `dev` → `main` после `git diff --stat origin/main origin/dev`; после merge — `sync-dev` | Только ожидаемые файлы | Неожиданные файлы → STOP |
| OC-B5 | `git fetch origin main`; затем `prokat-prod-android -DryRun` и `prokat-prod-ios -DryRun` на новом `main`, без env | План построен; тег без `rc/`; номер из OC-B3; SHA = `origin/main`; `Production gate (local): DISABLED`; строки облачного разрешения записаны | Любое иное → STOP |

### Фаза C — U5: однократная активация

| ID | Действие | PASS | FAIL / STOP |
| --- | --- | --- | --- |
| OC-C0 | Проверить ruleset только чтением: Settings → Rules или `gh api repos/auyltech/prokat/rulesets` и `…/rulesets/<id>`; записать enforcement, шаблоны, правила, bypass | Оба ruleset из OC-A5 активны и совпадают с 5.4 | Нет или не совпадают → **U5 заблокирован** (Q9) |
| OC-C1 | Решения Q4 и о Managed publishing приняты; Play service account получает app permission **Release to production** | Права выданы | — |
| OC-C2 | Q8 и Q9 записаны 2026-10-22. GitHub Secret `PRODUCTION_PUBLISHING_ENABLED=true` и Codemagic group secret выставляются только на U5, после ruleset (Q9). До этого capability остаётся выключенной | Оба выставлены после ruleset | Ruleset не проверен → STOP; секреты не включать заранее |
| OC-C3 | Проверить, что `PRODUCTION_RELEASE_AUTH_ANDROID` и `PRODUCTION_RELEASE_AUTH_IOS` пусты | Пусты: после U5 ни один тег всё ещё не публикуется | Не пусты → очистить, STOP |

### Фаза D — первый релиз тега одной платформы (повторяется отдельно для Android и для iOS)

Платформы выпускаются по очереди, никогда одновременно. Вторая платформа начинает
фазу D только после того, как первая прошла OC-D7.

| ID | Действие | PASS | FAIL / STOP |
| --- | --- | --- | --- |
| OC-D1 | Ruleset из OC-C0 по-прежнему активен (просмотр Settings → Rules). Свежая проверка магазина этой платформы (как OC-B1 или OC-B2). Android: «Changes ready to send for review» пуст; **с этого момента действует заморозка Play Console 5.9**, все пользователи Console предупреждены | Ruleset активен; номер свободен, чужих review, releases и неотправленных изменений нет | Иначе STOP |
| OC-D2 | `git fetch origin main`; `prokat-prod-<platform> -DryRun`: тот же номер и тот же SHA, что в OC-B5 (для второй платформы — пара того же канала и SHA) | Совпадает; строка облачного разрешения записана | `main` сдвинулся → вернуться к OC-B3/OC-B5 |
| OC-D3 | Выставить **только** переменную этой платформы равной строке из OC-D2 (Android — с `#1`). Переменная другой платформы пуста | Выставлено ровно одно значение | — |
| OC-D4 | В новой PowerShell-сессии: `$env:PRODUCTION_PUBLISHING_ENABLED='true'`, затем `prokat-prod-<platform>`, `y`, `PUBLISH PRODUCTION`; сразу после — `Remove-Item Env:PRODUCTION_PUBLISHING_ENABLED` | Тег отправлен, CLI напечатал SHA | Ошибка push → очистить разрешение, перейти к фазе P |
| OC-D5 | Наблюдать прогон провайдера до конечного состояния. Заморозка Console действует (Android) | Конечное состояние достигнуто | Изменение в Console → не вмешиваться в прогон, исход по 5.5, затем повторная проверка |
| OC-D6 | **Сразу** очистить переменную этой платформы, до разбора результата | Пусто | — |
| OC-D7 | Классифицировать исход по 5.5 и проверить магазин. Заморозка Console снимается после `PLAY_EDIT_COMMITTED` или конечного неуспешного состояния | SUBMITTED подтверждён в консоли | NOT_INVOKED: Android → фаза R или новый номер; iOS → новый номер (фаза D заново). UNKNOWN → только ручное восстановление или новый номер |

### Фаза P — сбой push после создания локального тега (протокол 5.8)

| ID | Действие | PASS | FAIL / STOP |
| --- | --- | --- | --- |
| OC-P1 | Разрешение платформы уже очищено (OC-D4 FAIL) | Пусто | — |
| OC-P2 | `dart tool/release/cli.dart <platform> production --resume-push <tag> --expect-sha <sha> --dry-run` | `REMOTE_SAME` → push фактически прошёл; разрешение заново **не** выставлять; перейти к OC-D5–OC-D7 по логу провайдера (если прогон увидел уже очищенное разрешение, он закончится NOT_INVOKED и классифицируется по 5.5). `REMOTE_ABSENT` → OC-P3 | `REMOTE_DIFFERS`, `REMOTE_UNKNOWN`, `LOCAL_TAG_MISMATCH` → STOP, ручная проверка; ничего не менять |
| OC-P3 | Провайдер: для этого тега нет ни одного прогона | Прогонов нет | Прогон есть при отсутствующем ref → STOP, расследование |
| OC-P4 | Свежая проверка магазина (как OC-D1); заморозка Console 5.9 | Номер свободен | Иначе STOP |
| OC-P5 | Снова выставить разрешение этой платформы `<tag>@<sha>` (Android — `#1`, это будет новый run) | Выставлено | — |
| OC-P6 | Сессия с `PRODUCTION_PUBLISHING_ENABLED=true`; `… --resume-push <tag> --expect-sha <sha>` без `--dry-run`; ввести полное имя тега; затем снять env | `REMOTE_SAME` после push → OC-D5–OC-D7 | Любой другой итог → очистить разрешение, STOP; новый цикл только с новым решением |

### Фаза R — исторический чеклист повторного Android-прогона

E4-LEAN (5.10) эту фазу как операционную процедуру не использует. Ошибка до мутации закрывается новым тегом и новым build number. Таблица ниже остаётся описанием прежнего пути и не является разрешением перезапустить релиз.

| ID | Действие | PASS | FAIL / STOP |
| --- | --- | --- | --- |
| OC-R1 | Убедиться по полному логу прогона, что `PUBLISHER_INVOKED` отсутствует | Подтверждено | Строка есть или лог неполный → это UNKNOWN, фаза R запрещена |
| OC-R2 | `git ls-remote origin "refs/tags/<tag>" "refs/tags/<tag>^{}"` | Тег существует, peeled SHA = SHA разрешения | Иначе STOP |
| OC-R3 | Свежая проверка магазина (как OC-D1); заморозка Console 5.9 | Номер свободен | Номер виден → STOP |
| OC-R4 | `PRODUCTION_RELEASE_AUTH_ANDROID=<tag>@<sha>#<последняя попытка run + 1>` | Выставлено одно значение | — |
| OC-R5 | Исходный run → «Re-run all jobs». CLI не используется | Новая попытка стартовала; в логе тот же тег и SHA | Иначе OC-R6 и STOP |
| OC-R6 | Сразу после конечного состояния очистить переменную; классифицировать по 5.5 | Как OC-D6–OC-D7 | — |
| — | **iOS:** повтор прежнего тега **запрещён** (Q8). Rebuild не выполнять; при NOT_INVOKED — новый номер, фаза D заново | — | — |

### Фаза E — после релиза и аварийная остановка

| ID | Действие | PASS |
| --- | --- | --- |
| OC-E1 | Обе переменные `PRODUCTION_RELEASE_AUTH_*` пусты; локальный env снят; заморозка Console снята | Да |
| OC-E2 | Аварийная остановка в любой момент: `PRODUCTION_PUBLISHING_ENABLED=false` у провайдера. Начатый прогон и уже отправленный review проверяются отдельно в консоли | Документировано в runbook |

### Production-readiness (итог этапа 6)

- [ ] Этапы 1, 1Б и 2–5 приняты отдельными аудитами.
- [ ] Production DryRun строит план без gate, только при `refs/remotes/origin/main == ls-remote`,
      не делает `fetch` и не пишет refs.
- [ ] Реальный production без gate отказывает до первой git-команды — и через Dart CLI,
      и через `prokat-prod-android`/`prokat-prod-ios`.
- [ ] RC и Production не делят номер; CLI не повторяет существующий тег (тесты).
- [ ] Протокол сбоя push 5.8 реализован (`--resume-push`), без удаления, переноса, force.
- [ ] Play: `ERROR_IF_IN_REVIEW`; `PLAY_CHANGES_IN_REVIEW` классифицируется в prepend (тест
      полного пути); проверка track в публикуемом edit с тестом TOCTOU; targetSdk ≥ 36.
- [ ] iOS: классификатор пар полей (300 пар) и именованные пары; слой 2 с тестами TOCTOU и
      гонки confirm; атомарность не заявлена.
- [ ] Облако требует boolean и разрешения своей платформы (Q1 вариант A, 2026-10-22).
      E4-LEAN (5.10) снимает постоянный iOS replay-block. Q7 не утверждён.
- [ ] **Tag ruleset активен (OC-C0).** Q9 не принимает отсутствие ruleset как риск: U5 остаётся заблокированным. Отсутствие replay store таким риском больше не является.
- [ ] `PUBLISHER_INVOKED` есть в обоих адаптерах; runbook даёт ручной маршрут 5.10;
      повтор после UNKNOWN запрещён; тот же production-релиз оператор не перезапускает.
- [ ] Заморозка Play Console описана в runbook и в фазе D.
- [ ] Документация не утверждает, что разрешение одноразовое; порядок очистки описан.
- [ ] PR прогоняет Dart, Python, Ruby release-тесты.
- [ ] Документация совпадает с кодом; в diff нет promotion-кода.
- [ ] Фаза A пройдена; фазы B–E, P, R описаны в runbook и готовы к исполнению владельцем.

---

## 16. Реестр рисков

| Риск | Вероятность / влияние | Мера |
| --- | --- | --- |
| Commit Play отменяет чужой review | Средняя / высокое | Этап 2 (`ERROR_IF_IN_REVIEW`) |
| Отказ commit `CHANGES_ALREADY_IN_REVIEW` не распознан из-за `call_google_api` или печатает тело ответа | Средняя / среднее | Этап 2: классификация в prepend к `commit_edit`, тест полного пути с сентинелом |
| Publish вытесняет production draft/staged rollout, в том числе появившийся после preflight | Низкая / высокое | Этап 2: проверка в публикуемом edit; инвалидация edit Google |
| Изменения в Play Console во время релиза: отправка «готовых» изменений вместе с релизом или инвалидация edit | Средняя / среднее | Заморозка 5.9 от OC-D1 до конечного состояния; OC-D1, OC-D5, OC-D7 |
| CLI 0.70.0 переименовывает или меняет версию в ревью; подтверждает чужой submission | Средняя / высокое | Этап 3, слои 1 и 2 |
| Противоречивые значения `appStoreState`/`appVersionState` приняты за безопасные | Средняя / высокое | Этап 3: ACTIVE в любом поле блокирует; противоречия и неподдерживаемые → UNKNOWN; тест 300 пар |
| Состояние App Store меняется после preflight (до ~30 минут) | Средняя / высокое | Слой 2 перечитывает в момент мутации; остаётся окно одного сетевого обмена |
| Item добавлен в наш submission между `list_items` и confirm | Низкая / среднее | Проверка до и после PATCH; UNKNOWN при расхождении; атомарность не заявляется (P-28) |
| Отказ слоя 2 после upload | Низкая / среднее | UNKNOWN, IPA в Artifacts, ручная обработка; без reupload |
| Apple перестаёт возвращать `appStoreState` или повторять фильтры в `links.next` | Низкая / среднее | R1 и `all_pages` блокируют (fail closed) |
| Обновление Codemagic CLI меняет заменённые методы | Низкая / высокое | Version guard этапа 3; версия CLI закреплена |
| Случайный production-тег при включённом boolean | Средняя / высокое | Этап 4: разрешение своей платформы |
| **Replay события: тег удалён и создан снова (в том числе тот же объект) при активном разрешении** | Низкая / высокое | **Только tag ruleset (OC-A5, OC-C0) — условие U5**; без него Q9 блокирует U5. Отсутствие защиты не принято |
| Re-run Android при активном разрешении | Низкая / среднее | Номер попытки в разрешении; OC-D6 |
| Rebuild/ручной запуск iOS | Низкая / среднее | Штатный путь — tag webhook (5.10). Фильтр `event`/`CM_TRIGGER_SOURCE` не является attestation. Оператор не запускает API/UI/Rebuild |
| Сбой push, неоднозначное состояние тега | Средняя / среднее | Протокол 5.8 и фаза P; STOP при неоднозначности; без удаления и переноса |
| Владелец забыл очистить разрешение | Средняя / среднее | OC-E1; другие теги, попытки и не-webhook запуски не совпадут; replay — только ruleset |
| Тег с ожидаемым именем создан кем-то другим | Низкая / среднее | Ruleset «create»; SHA в разрешении |
| Администратор отключает ruleset | Низкая / высокое | Граница доверия; проверка OC-C0 перед каждым релизом в фазе D (OC-D1 включает просмотр ruleset) |
| Writer с доступом к репозиторию читает секреты или меняет workflow | Низкая / критическое | OC-A2: ограничить write; environments по тарифу |
| UNKNOWN после вызова издателя (таймаут, сеть, отмена) | Средняя / среднее | Повтор прежнего тега запрещён; разбор в консоли; новый номер |
| Upload начался, а магазин ещё не показывает номер | Низкая / высокое | После UNKNOWN повтор запрещён процедурно; дубликат номера магазин отвергнет |
| Маркер ошибочно принят за доказательство мутации или публикации | Средняя / среднее | Семантика 5.5; документация этапа 5 |
| DryRun на устаревшем локальном `origin/main` | Средняя / низкое | Этап 1: сравнение с `ls-remote`, fail closed |
| Обновление fastlane/google-apis ломает prepend или контракт `call_google_api` | Низкая / высокое | Контракт-тест, Gemfile.lock frozen |
| Новые значения enum Apple/Google | Низкая / низкое | Fail closed → UNKNOWN |
| Automatic Distribution показывает production-билд тестерам | Высокая / низкое | Принято (P-14) |
| Документы снова устаревают | Средняя / низкое | Этап 5, `cli_docs_test.py` |

---

## 17. RC `1.2.3+19` и `1.2.3+24`

Теги `rc/android/v1.2.3+19`, `rc/ios/v1.2.3+19`…`+24` остаются как есть: их не
двигают, не удаляют и не используют как обязательный шаг. После этапа 1 они
участвуют только как нижняя граница общего счётчика: первый Production `N > 24`.
Ruleset OC-A5 защищает их от удаления и переноса. Принятые в магазинах RC-сборки
владелец при желании продвигает вручную в консоли. Pipeline этого не делает.

---

## 18. Чек-лист аудита этого плана

- [ ] Раздел 1 совпадает с `git rev-parse origin/dev origin/main` и `git diff --stat origin/main origin/dev`.
- [ ] «Общий порядок работ»: этапы 1–6 до фаз B–E; этап 6 — только репетиция; нет циклов.
- [ ] Классы Git-операций G0–G4 используются единообразно в этапах, prompts и checkpoints.
- [ ] Каждая проблема раздела 3 (P-01…P-29) воспроизводится по указанным функциям и источникам.
- [ ] Раздел 4: пять путей untracked; очистка описана как локальная; в этапе 0 файлы не удалены.
- [ ] Правило 5.2 закрывает: RC↔Production, частичную пару, повтор через CLI, другой SHA, другую версию.
- [ ] Таблица 5.3 однозначна: где проверяется gate (включая PowerShell), свежесть
      tracking-ref, какие операции до отказа разрешены, что запрещено всегда.
- [ ] 5.4: таблица «сценарий → мера → гарантия»; replay события закрывает только ruleset;
      ruleset — обязательное условие U5 (OC-C0, Q9); отсутствие ruleset не принято. Разрешение не названо одноразовым.
- [ ] 5.5: `PUBLISHER_INVOKED` — «издатель вызван»; валидация не считается публикацией;
      SUBMITTED только по двум маркерам; NOT_INVOKED для iOS — новый номер.
- [ ] 5.6 и 5.10: фаза R сохранена как история; операционно тот же production-релиз не перезапускают.
- [ ] 5.8 и фаза P: четыре классификации, STOP при неоднозначности, повтор push только
      при `REMOTE_ABSENT` с точным SHA и подтверждением; без удаления и переноса.
- [ ] 5.9: заморозка Play Console от OC-D1 до конечного состояния; отражена в фазах D, P, R,
      в runbook этапа 5 и в реестре рисков.
- [ ] Этап 2: `CHANGES_ALREADY_IN_REVIEW` классифицируется в prepend, есть тест полного
      пути через `call_google_api`; track проверяется в публикуемом edit с тестом TOCTOU.
- [ ] Этап 3: категории по каждому полю без межполевого соответствия; ACTIVE в любом поле
      блокирует; противоречия → UNKNOWN; тест 300 пар и пара (`IN_REVIEW`,
      `READY_FOR_DISTRIBUTION`); гонка confirm документирована и протестирована.
- [ ] Этап 4 и 5.10: iOS production не блокируется отсутствием replay store; webhook-фильтр не назван attestation; новый Android run с попыткой 1 проходит gate.
- [ ] Фазы A–E, P, R раздела 15 идут без противоречий.
- [ ] Ни один этап не требует store-запросов или изменения секретов, переменных, rulesets агентом.
- [ ] Для каждого этапа заданы границы, тесты, приёмка, негативы, RC-регрессии, откат, аудит.
- [ ] RC-инварианты 5.7 не нарушаются ни одним этапом без решения владельца (Q2).
- [ ] Commit ревизии содержит только этот файл.

---

## 19. Исправленные противоречия

### Ревизия 2

| № | Было | Стало |
| --- | --- | --- |
| 1 | `PRODUCTION_RELEASE_TAG` описан как «одноразовое разрешение» | Разрешение `tag@SHA` — не токен; границы — 5.4 |
| 2 | OC-9 настраивал «оба провайдера на один тег» | Отдельные переменные по платформам; фаза D по одной платформе с очисткой |
| 3 | Gate в `execute()` «до вопроса», но `plan()` уже делал `ls-remote` и fetch | Таблица 5.3 (P-17): отказ до git |
| 4 | OC-1…OC-10 смешивали проверки, merge, U5 и запуск | Фазы с однозначным порядком; U5 = фаза C |
| 5 | Таблица состояний Apple без сверки, submissions с `filter[state]` | Сверка 6.1; запросы без фильтров состояния; R1–R7 |

### Ревизия 3

| № | Было | Стало |
| --- | --- | --- |
| 1 | iOS: preflight — единственная защита перед мутациями CLI (P-19) | Слой 2 в `apple_publish.py` |
| 2 | Android: track проверялся в отдельном preflight-edit (P-20) | `GuardedPublishEdit` в публикуемом edit |
| 3 | Повтор после сбоя подразумевал тот же путь, что первый релиз | Два пути: CLI — первый релиз; повтор — провайдер |
| 4 | DryRun без явной проверки свежести tracking-ref (P-22) | Шаги свежести 5.3; классы G0–G4 |
| 5 | `STORE_MUTATION_BEGIN` утверждал мутацию | `PUBLISHER_INVOKED` = «издатель вызван» |
| 6 | Отказ до git проверялся только для Dart CLI | Тесты без git для Dart CLI и PowerShell |
| 7 | «Удалить пять файлов» без уточнения | Локальная очистка, не Git-удаление |
| 8 | Риск повтора при активной переменной без защиты | Android — номер попытки; iOS — Q8 |

### Ревизия 4

| № | Было | Стало |
| --- | --- | --- |
| 1 | Номер попытки GitHub подавался как защита от повтора, ruleset — «если тариф позволяет» (P-23) | Новый run начинается с попытки 1: replay события закрывает только ruleset. Ruleset обязателен для U5 (OC-A5, OC-C0); без него Q9 блокирует U5 или фиксирует отсутствие защиты. Таблица «сценарий → мера → гарантия» в 5.4; тест, что код replay не останавливает |
| 2 | R4 сравнивал только «редактируемо/нет»; пара (`IN_REVIEW`, `READY_FOR_DISTRIBUTION`) проходила (P-24) | Категории по каждому полю; ACTIVE в любом поле блокирует; UNSUPPORTED и противоречия → UNKNOWN; соответствие значений не вводится; тест 300 пар и именованные пары |
| 3 | Сбой push описан ручной инструкцией (P-25) | Протокол 5.8, этап 1Б `--resume-push`, фаза P: local-only / remote-same / remote-differs / unknown; повтор только local-only с точным SHA и подтверждением полным именем тега |
| 4 | `CHANGES_ALREADY_IN_REVIEW` ловился внешним `rescue ClientError` (P-26) | Классификация в prepend к `commit_edit` собственным исключением вне `Google::Apis::Error`; тест полного пути через `commit_current_edit!`/`call_google_api` с сентинелом |
| 5 | Нет условия на действия в Play Console во время релиза (P-27) | Заморозка 5.9 от OC-D1 до конечного состояния; фазы D, P, R; runbook; реестр рисков |
| 6 | Гонка между `list_items` и confirm не описана (P-28) | Проверка items до и после PATCH, фиксированные коды, без автоматической отмены; атомарность не заявлена; тесты гонки |
| 7 | Q8 рекомендовал принять риск Rebuild iOS; фаза R содержала iOS | Q8: повтор прежнего iOS-тега запрещён; `CM_TRIGGER_SOURCE == webhook` для iOS production (P-29); фаза R — только Android |
| 8 | Этап 6 и фаза B выглядели взаимозависимыми | «Общий порядок работ»: этапы 1–6 до фаз B–E; этап 6 — только репетиция |
