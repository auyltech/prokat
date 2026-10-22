# Production CI/CD PROKAT — план доведения прямых Production-релизов

Статус: **этап 0, ревизия 2 (после второго аудита). Реализация не начата.**
Ветка: `feat/production-cicd-hardening` от `origin/dev` `6f0aa0e506a0f4c74745d4e9fa7196032207b82c`.
Что исправлено в ревизии 2 — раздел 19.

План не разрешает публикацию, теги, push, merge, изменение секретов или консолей
магазинов. Каждый этап выполняется отдельным запуском только после явного GO
владельца и останавливается для аудита. Если код расходится с этим планом, агент
останавливается и сообщает расхождение, а не «чинит» план сам.

Ссылки на строки даны для ревизии `6f0aa0e5`; после правок ориентируйтесь на имена
функций и тестов.

---

## 1. Исходное состояние (зафиксировано 2026-10-22)

| Что | Значение |
| --- | --- |
| `origin/dev` | `6f0aa0e5` `fix(ci): confirm automatic internal TestFlight distribution without assignment (#84)` |
| `origin/main` | `07926a7d` `release: 1.2.3+24 (iOS retry) (#83)` |
| Расхождение по коммитам | `dev` впереди на 204, `main` впереди на 1 (squash `+24`) |
| Расхождение по дереву | **только 7 файлов** — исправление #84 (`ios_store.py`, `apple_publish.py`, их тесты, `testflight_distribution_test.py`, `cli_docs_test.py`, `IOS_PUBLISHING.md`). Squash-коммит `07926a7d` по содержимому уже есть в `dev` |
| `pubspec.yaml` на `main` и `dev` | `version: 1.2.3+24`, Flutter `3.47.2` |
| Release-теги в origin | `rc/android/v1.2.3+19`, `rc/ios/v1.2.3+19` (оба `94eb9b99`), `rc/ios/v1.2.3+20`…`+23`, `rc/ios/v1.2.3+24` (`07926a7d`). Production-тегов нет |
| Незакоммиченное | 5 untracked файлов отменённого promotion (раздел 4). Блокируют CLI: `clean()` требует пустой `git status --untracked-files=all` |
| Stash | `stash@{0}` `safety/local-production-replica-before-dev-sync-20261014` — не относится к CI/CD, не трогать |
| GitHub-настройки | **не прочитаны**: `gh` не авторизован. Rulesets, Environments, тариф, список collaborators неизвестны (checkpoint OC-A2) |

Вывод по расхождению `dev`/`main`: будущий PR `dev` → `main` не перенесёт сотни
несвязанных изменений. Он перенесёт #84, результат этого плана и version bump.
Перед этим PR снова проверить `git diff --stat origin/main origin/dev`.

Базовая линия тестов на `6f0aa0e5`, до любых правок:

| Набор | Команда | Результат |
| --- | --- | --- |
| Dart release | `flutter test --no-pub test/release` | 118 passed |
| Python release | `unittest discover -s tool/release -p '*_test.py'` во временном venv на `git archive HEAD` с одноразовым `git init` | 169 passed |
| Ruby (Play) | `play_policy_test.rb`, `play_store_test.rb`, `sdk_contract_test.rb` | **не запускались**: нет Ruby, Docker daemon не запущен |

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
| Запуск CLI | `main()` в `cli.dart` | нет | неверные аргументы; `git rev-parse --show-toplevel`; грязное дерево; `origin` не `auyltech/prokat` | нет (локальные чтения) | `cli_test.dart` |
| План | `ReleaseCli.plan` | `git ls-remote origin`; blobs `origin/main`: pubspec, `releases/X.Y.Z/*`, workflow, `production.json`, `Info.plist` | грязное дерево; нет main; notes не `ready`; тег существует; история номеров; guard-строки workflow; `production.json`; Export Compliance; main сдвинулся. **Production: gate `PRODUCTION_PUBLISHING_ENABLED` уже здесь, поэтому DryRun невозможен (P-01)** | Dry-run: нет. Обычный режим: fetch во временный bare-репозиторий вне checkout | `cli_test.dart` |
| Исполнение | `ReleaseCli.execute` | интерактивный ввод | `Continue? [y/N]`; для production фраза `PUBLISH PRODUCTION`; gate; повторная проверка main и тегов | `git fetch` в `refs/remotes/origin/main`, `git tag -a`, `git push origin refs/tags/T:refs/tags/T` | `cli_test.dart` |
| CI: источник | `release.dart ci` → `validateEvent`, `validateProduction`, `validateRevision`, `validatePubspecVersion`, `prepare` | env провайдера, `GITHUB_EVENT_PATH`/`CM_TAG`, `--revision` = `GITHUB_SHA`/`CM_COMMIT` | не tag push; удаление тега; SHA не в `main`; peeled-коммит тега ≠ revision; история; pubspec ≠ тег; gate | `git fetch` в runner | `release_test.dart`, `source_test.dart` |
| CI: gate Android | шаг `Reject production until U5` в `android-release.yml`; `play.rb` | `secrets.PRODUCTION_PUBLISHING_ENABLED` | значение ≠ `true` | нет | `config_test.py` (структура) |
| CI: gate iOS | `release.dart ci`, `ios_store.py main` | env-группа Codemagic `prokat-ios-release` | значение ≠ `true` | нет | `ios_store_test.py` |
| Состояние Play | `play.rb preflight` → `ProkatPlayStore.snapshot` → `PlayPolicy.check!` | `PLAY_SERVICE_ACCOUNT_JSON_BASE64`, `vars.PLAY_HISTORICAL_MAX_BUILD` | номер занят; номер ≤ максимума; locale; track ≠ канал | **да: `edits.insert` + `edits.delete`** (P-06) | `play_policy_test.rb`, `play_store_test.rb` |
| Состояние Apple | `ios_store.py preflight` → `read_apple_state` + `check_builds` | `PROKAT_ASC_PRIVATE_KEY_PEM`, `APP_STORE_CONNECT_*`, `APP_STORE_APP_ID`, `IOS_HISTORICAL_MAX_BUILD`, `TESTFLIGHT_GROUP` (RC) | номер занят в builds/buildUploads; номер не растёт; 401/403/429/5xx/timeout/пагинация → UNKNOWN | нет (GET). Пишет `build/release/apple-state.json` в runner | `ios_store_test.py` |
| Сборка Android | `inputs.dart android`, `verify_upload_key.py`, `flutter build appbundle`, Crashlytics mapping | keystore, пароли, alias, `google-services.json`, Mapbox `pk.*` | отпечаток upload key ≠ `ANDROID_UPLOAD_CERT_SHA256`; mapping пуст | загрузка mapping в Firebase | `verify_upload_key_test.py` |
| Проверка AAB | `verify_android.dart` + bundletool 1.18.3 (sha256 закреплён) | `ANDROID_UPLOAD_CERT_SHA256` | подпись; отпечаток; debug-сертификат; package; versionCode/Name. **Без targetSdk (P-05)** | нет | **нет тестов** |
| Публикация Android | шаг `Recheck state and publish once…` → `play.rb publish` → `Supply::Uploader#perform_upload` | service account | канал/track/номер заново (второй temporary edit); событие GitHub | **да**: edit, upload AAB, `update_track` (заменяет все releases track, P-04), changelogs, `edits.commit` (**default `CANCEL_IN_REVIEW_AND_SUBMIT`, P-03**) | `sdk_contract_test.rb` (наличие опций) |
| Сборка iOS | `swiftpm_resolve.py`, `xcode-project use-profiles`, `flutter build ipa`, `verify_ios.py`, dSYM | integration `prokat-app-store`, профили | lock-дрейф, entitlements, bundle, Export Compliance | загрузка dSYM в Firebase | `verify_ios_test.py`, `swiftpm_resolve_test.py` |
| Публикация iOS | шаг `Recheck Apple state and publish once…` → `ios_store.py publish` → `apple_publish.py` (Codemagic CLI 0.70.0) | integration, PEM | повторный preflight; ровно один IPA; argv через парсер CLI; локализации строго | **да**: upload IPA; RC — подтверждение Automatic Distribution (GET); production — App Store version create/update, `reviewSubmissions` create/reuse, submit (P-07) | `ios_store_test.py`, `apple_publish_test.py`, `testflight_distribution_test.py` |

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
| P-03 | P0 | Commit в Play без `changesInReviewBehavior`. Дефолт API `CANCEL_IN_REVIEW_AND_SUBMIT` отменяет текущий review. Касается и RC: commit internal-релиза отменит production review | `play.rb` задаёт только `changes_not_sent_for_review: false`; `Supply::Client#commit_current_edit!` (fastlane 2.241.0) передаёт только его; [edits.commit](https://developers.google.com/android-publisher/api-ref/rest/v3/edits/commit) | ПОДТВЕРЖДЕНО. Keyword `changes_in_review_behavior` есть в `google-apis-androidpublisher_v3` ≥ 0.97.0; в `Gemfile.lock` 0.109.0 |
| P-04 | P0 | Publish в production молча вытесняет существующие `draft`/`inProgress`/`halted` releases на track | `Supply::Uploader#update_track` делает `track.releases = [track_release]` (fastlane 2.241.0, `uploader.rb:451-456`); `PlayPolicy.check!` статусы production track не проверяет | ПОДТВЕРЖДЕНО |
| P-05 | P1 | AAB не проверяется на `targetSdkVersion ≥ 36`. Правило Google Play с 31.08.2026 | `verify_android.dart` проверяет только package/versionCode/versionName/подпись. Сейчас target = 36 из Flutter 3.47.2 (`flutter_tools/lib/src/android/gradle_utils.dart: targetSdkVersion = '36'`), но понижение не поймается. У `verify_android.dart` нет тестов | ПОДТВЕРЖДЕНО |
| P-06 | info | Чтение Play — не GET: `edits.insert` + `edits.delete`, дважды за прогон, плюс `play_access.rb` | `ProkatPlayStore.snapshot` (`play_store.rb:31-55`) | ПОДТВЕРЖДЕНО. Документировано в `ANDROID_SETUP.md`, менять не нужно. Запрещено вызывать без GO |
| P-07 | P0 | iOS production не проверяет App Store versions и review submissions до сборки. Codemagic CLI 0.70.0: (a) выбирает **самую новую** версию среди редактируемых, с любой строкой, и делает PATCH `versionString`/`build` (переименование чужой версии); (b) к редактируемым относит `WAITING_FOR_REVIEW`, то есть меняет build у версии, ожидающей ревью; (c) если `POST /v1/reviewSubmissions` отвечает «another reviewSubmissions … still in progress», **переиспользует** найденный submission, добавляет в него свою версию и подтверждает его вместе с чужими элементами | `SubmitToAppStoreAction._get_editable_app_store_version`, `_update_existing_app_store_version`, `_create_review_submission`; `AppStoreState.editable_states()`; запрос `Apps.list_app_store_versions` с `filter[appStoreState]`, `filter[platform]=IOS`, `limit=100` и обходом `links.next` (cli-tools v0.70.0). В `ios_store.py` таких GET нет. Чужие submissions CLI не отменяет: `--cancel-previous-submissions` не передаётся (P-15) | ПОДТВЕРЖДЕНО |
| P-08 | P2 | Production Apple app ID не закреплён (RC закреплён `require_rc_target`) | `validate_apple_environment` принимает любой `APP_STORE_APP_ID`. Смягчение: проверка `bundleId == com.auyltech.prokat` в `read_apple_state` | ПОДТВЕРЖДЕНО |
| P-09 | P0 | Облачный gate — постоянный boolean. После включения любой push production-тега (ошибка, агент, старый скрипт) или re-run публикует. `PUBLISH PRODUCTION` проверяется только локально. Неизменяемость тегов обеспечивает только клиентский CLI. Re-run (GitHub «Re-run jobs», Codemagic rebuild) переиспользует тот же тег и проходит любой gate, который в момент re-run разрешает этот тег | `android-release.yml` (`on.push.tags`, шаг `Reject production until U5`); `codemagic.yaml` (`ios-production`, `tag_patterns: ios/v*`); `cli.dart execute` | ПОДТВЕРЖДЕНО для кода. Серверные rulesets — ПРЕДПОЛОЖЕНИЕ (OC-A2). Поведение Codemagic rebuild с исходным `CM_TAG` — ПРЕДПОЛОЖЕНИЕ, в плане трактуется как худший случай |
| P-10 | P1 | Python- и Ruby-тесты релиза не запускаются в PR. Python идёт только в Codemagic release run (рядом с секретами); из Ruby в Android run запускается лишь `play_policy_test.rb`; `play_store_test.rb` и `sdk_contract_test.rb` автоматически не запускаются нигде | `.github/workflows/pull-request.yml`, `android-release.yml:99`, `codemagic.yaml:42` | ПОДТВЕРЖДЕНО |
| P-11 | P2 | Документация устарела: «production dry-run requires gate»; «следующий общий релиз `1.2.4+24`» (24 уже занят). Тесты закрепляют устаревший текст | `tool/release/README.md:49-51`; `CICD-README.md` раздел E; `cli_test.dart` `'documented wrappers…'` и `cli_docs_test.py test_owner_commands_and_flags_exist` проверяют `1.2.4+24` | ПОДТВЕРЖДЕНО |
| P-12 | P1 | Untracked-файлы promotion блокируют все четыре команды | `ReleaseCli.clean`, `main()` в `cli.dart` | ПОДТВЕРЖДЕНО |
| P-13 | info | После upload iOS ждёт обработку не более 20 минут; при таймауте IPA уже в ASC, submission нет | `publish_arguments`: `--max-build-processing-wait 20` | ПОДТВЕРЖДЕНО. Поведение fail-closed верное (UNKNOWN, без retry). Не менять без решения владельца |
| P-14 | info | Automatic Distribution внутренней TestFlight-группы может показать тестерам и production-билд | настройка Apple (`hasAccessToAllBuilds`), production argv группу не назначает | ПРИНЯТО. Не менять: сломает RC |
| P-15 | — | Production argv не содержит `--testflight`, `--beta-group`, `--cancel-previous-submissions`, `--expire-build-submitted-for-review` | `publish_arguments`, `test_production_requests_after_approval` | ИСПРАВЛЕНО РАНЕЕ |
| P-16 | — | Upload/API без blind retry: Play `retries = 0`, `SUPPLY_UPLOAD_MAX_RETRIES=0`; Apple attempt counts 1/1/1, парсинг argv закреплённым CLI | `play_store.rb NoBlindPlayRetries`, `apple_publish.validate_publish_arguments` | ИСПРАВЛЕНО РАНЕЕ |
| P-17 | P1 | Реальный production-запуск без gate до отказа успевает выполнить удалённые чтения: `git ls-remote`, fetch во временный bare-репозиторий. Gate проверяется только внутри `plan()`, а `main()` до этого уже вызывает git | порядок в `main()` и `ReleaseCli.plan` | ПОДТВЕРЖДЕНО |
| P-18 | P1 | По логу CI нельзя однозначно понять, начал ли шаг публикации мутацию магазина. Это нужно, чтобы отличить «упало до публикации» от UNKNOWN | `play.rb publish` и `ios_store.py publish` печатают маркер только при успехе | ПОДТВЕРЖДЕНО |

Поправки к прошлому аудиту: «204 коммита» — артефакт squash, по дереву 7 файлов
(раздел 1). P-07(b,c) и P-04 в прошлом аудите не были найдены.

---

## 4. Инвентаризация старых наработок

| Путь | Что это | Используется? | Решение |
| --- | --- | --- | --- |
| `tool/release/promotion.py` | Offline-планировщик RC → Production (`"P1 offline validate/plan only"`) | Нет: ни один tracked-файл не ссылается (`git grep` пуст); ни в одной ветке истории нет (`git log --all` пуст) | **Удалить на этапе 1** (разрешено владельцем) |
| `tool/release/promotion_model.py` | Модель блокеров promotion, импортируется только из `promotion.py` | Нет | Удалить на этапе 1 |
| `tool/release/promotion.schema.json` | JSON Schema манифеста promotion | Нет | Удалить на этапе 1 |
| `tool/release/requirements-promotion.txt` | Зависимости promotion-планировщика | Нет; workflow используют `requirements.txt`/`requirements-apple.txt` | Удалить на этапе 1 |
| `releases/1.2.3/promotion.json` | Манифест promotion для RC +19/+24 (политика rollout 10%, `MANUAL`) | Нет; `readNotesFrom` читает только `release.json` и `ru/en/kk.txt` | Удалить на этапе 1 |

Все пять файлов untracked, созданы 2026-10-21 18:09, в Git-истории отсутствуют.
Удаление необратимо. Если владелец хочет копию, он сохраняет её вне репозитория
до этапа 1.

Сохраняются:

- Тексты «promotion не реализован» в `release.dart`, `CICD-README.md`,
  `RELEASE_RUNBOOK.md`, `releases/README.md`. Это действующий контракт: другой канал
  того же номера блокируется.
- `ios-apple-diagnostic` (`apple_diagnostic.py check --build 20`) — ручной GET-only
  workflow, без триггера. Устаревший номер 20 безопасен; отдельной правки не требует.
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
- Повторный запуск CLI для уже созданного тега блокируется правилом 4. Повтор
  облачного прогона того же тега — отдельный контракт раздела 5.5.
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
| `main()` в `cli.dart` | Не проверяет | **Первым действием после разбора аргументов, до любого вызова git** |
| `ReleaseCli.plan(platform, channel, dryRun:)` | Не проверяет | Первым действием, до `clean()`, `ls-remote` и чтения blobs (защита при вызове API в обход `main`) |
| `ReleaseCli.execute(plan, dryRun:)` | Только печатает состояние gate | Повторно: до первого prompt и непосредственно перед `git tag` |
| `ReleasePlan` | Помечается `dryRun: true` | `execute(dryRun: false)` для плана с `dryRun: true` → BLOCK (план из локального кеша объектов не исполняется) |

Матрица операций:

| Операция | DryRun (любой канал) | Реальный RC | Реальный production, gate выключен | Реальный production, gate включён |
| --- | --- | --- | --- | --- |
| Разбор аргументов | да | да | да | да |
| Локальные чтения: `git rev-parse --show-toplevel`, `git status`, `git remote get-url`, `git tag --list`, `git rev-parse refs/tags/…`, `git cat-file`/`git show` локальных объектов, чтение `build/release/*-state.json` | да | да | **нет — отказ раньше любой git-команды** | да |
| Удалённое чтение `git ls-remote origin` | да | да | нет | да |
| `git fetch` во временный bare-репозиторий вне checkout | **нет** | да | нет | да |
| Печать preview | да, если план построен | да | нет | да |
| Prompt (`Continue? [y/N]`, `PUBLISH PRODUCTION`) | **нет** | да (`Continue?`) | нет | да (оба) |
| `git fetch` в `refs/remotes/origin/main` | нет | после подтверждения | нет | после обоих подтверждений и повторного gate |
| `git tag -a`, `git push origin refs/tags/T:refs/tags/T` | **нет** | да | нет | да |
| Push веток, `--force`, удаление и перенос тегов, запросы к CI или магазинам | никогда | никогда | никогда | никогда |

Вывод production DryRun при успешном плане: preview, строка
`Production gate (local): ENABLED|DISABLED`, после этапа 4 — строка облачного
разрешения (раздел 5.4) и `DRY RUN: no files, refs, tags or uploads changed.`
Если план не построен (история, guard, notes), печатается только `BLOCKED: …`.
DryRun не является разрешением ни в одном из режимов.

### 5.4 Облачное разрешение и границы защиты

Уровни защиты Production:

| Уровень | Сейчас | Цель (вариант A решения Q1) |
| --- | --- | --- |
| Локальный CLI | env `PRODUCTION_PUBLISHING_ENABLED=true` + `PUBLISH PRODUCTION` | Без изменения смысла; gate переносится на старт реального запуска (5.3) |
| GitHub Actions (Android) | `secrets.PRODUCTION_PUBLISHING_ENABLED == true` | Плюс repository Variable `PRODUCTION_RELEASE_AUTH_ANDROID` == `"$GITHUB_REF_NAME@$GITHUB_SHA"` |
| Codemagic (iOS) | `PRODUCTION_PUBLISHING_ENABLED == true` в группе `prokat-ios-release` | Плюс переменная группы `PRODUCTION_RELEASE_AUTH_IOS` == `"$CM_TAG@$CM_COMMIT"` |
| Сервер GitHub | неизвестно | Если тариф позволяет (OC-A2): tag ruleset на `refs/tags/android/v*`, `refs/tags/ios/v*`, `refs/tags/rc/**` — создание только владельцем, update и delete запрещены |
| Магазины | без production-права у Play service account | Право Release to production выдаётся один раз на U5 (OC-C1) |

Формат разрешения: `<точный тег>@<40-символьный SHA коммита>`, например
`android/v1.2.4+25@0123…abcd`. Сравнение строгое: без trim, без регистра, без
шаблонов. `GITHUB_SHA` и `CM_COMMIT` уже обязаны совпадать с peeled-коммитом тега
(`validateRevision`), поэтому разрешение привязано к содержимому, а не только к имени.
Production DryRun печатает точную строку для копирования.

Разрешения независимы по платформам: GitHub проверяет только
`PRODUCTION_RELEASE_AUTH_ANDROID` и только для `android/v*`; Codemagic — только
`PRODUCTION_RELEASE_AUTH_IOS` и только для `ios/v*`. Значение с тегом другой платформы
не совпадёт ни с одним прогоном. Boolean остаётся аварийным выключателем провайдера.

**Что разрешение даёт:**

- Push любого другого production-тега, в том числе следующего номера, не публикует.
- Тег с тем же именем на другом коммите не публикует.
- Забытый `PRODUCTION_PUBLISHING_ENABLED=true` без разрешения не публикует.
- Прогон после очистки разрешения не публикует.
- CI не может выдать разрешение сам себе: `permissions: contents: read`, переменные
  меняет только администратор GitHub или Codemagic.

**Чего разрешение не даёт:**

- Это **не одноразовый токен**. Пока переменная содержит строку, любой re-run того же
  тега (GitHub «Re-run jobs», Codemagic rebuild) проходит облачный gate.
- Оно не ограничивает, кто может создать тег. Без ruleset любой collaborator с правом
  write может отправить тег. Разрешение лишь требует, чтобы имя и SHA совпали с
  выбранными владельцем.
- Оно не защищает от collaborator с правом write, который меняет workflow в своей
  ветке и читает repository secrets. Это граница доверия репозитория: её снимают
  только ограничение write-доступа, rulesets и Environment-scoped секреты (OC-A2).
- Оно не доказывает, что магазин ещё не принял этот номер. Это делает store-preflight.

### 5.5 Повторный запуск, очистка разрешения и UNKNOWN

Первый мутирующий шаг магазина:

- Android: `play.rb publish`, сразу перед вызовом `Supply::Uploader`.
- iOS: `ios_store.py publish`, сразу перед вызовом `apple_publish.py`.

Temporary edit в `play.rb preflight` (P-06) публикацию не делает и мутирующим шагом
не считается. Этап 4 добавляет печать фиксированного маркера
`STORE_MUTATION_BEGIN platform=<android|ios> tag=<tag>` непосредственно перед этими
вызовами и не печатает его, если preflight внутри шага заблокировал.

Классификация завершённого прогона (владелец, по логу провайдера):

| Исход | Признак | Действие |
| --- | --- | --- |
| SUBMITTED | Android: `PLAY_EDIT_COMMITTED`. iOS: `APPLE_SUBMISSION_STEP_COMPLETED` | Очистить разрешение. Проверить track или App Review в консоли |
| FAILED_BEFORE_MUTATION | Прогон завершился, маркера `STORE_MUTATION_BEGIN` в логе нет | Очистить разрешение. Повтор того же тега допустим только по новому решению владельца: свежая проверка магазина (OC-D1), заново выставленное разрешение, один re-run. Иначе новый номер и новый тег |
| UNKNOWN | Маркер есть, маркера успеха нет. Сюда же: отмена, таймаут, потерянный лог | Очистить разрешение. **Re-run запрещён.** Проверить магазин: Play — App bundle explorer, tracks, Publishing overview; Apple — Build Uploads, TestFlight builds, App Store version, review submissions. Восстановление — вручную в консоли или новым номером, новым тегом и новым разрешением |

Порядок очистки:

1. Разрешение выставляется для одной платформы непосредственно перед реальной
   командой CLI этой платформы.
2. Как только прогон провайдера дошёл до конечного состояния (успех, ошибка, отмена),
   владелец **сначала** очищает переменную этой платформы и только потом разбирает
   результат.
3. Переменная другой платформы в это время пуста.
4. Boolean `PRODUCTION_PUBLISHING_ENABLED` после U5 остаётся `true` как признак
   активированного pipeline. Аварийная остановка — `false` у провайдера. Это не
   отменяет уже начатый прогон и уже отправленный review.

Re-run после SUBMITTED дополнительно блокируется store-preflight: номер виден в Play
(bundles/tracks) или Apple (builds/buildUploads). Если upload мог начаться, но
магазин ещё не показывает номер, store-preflight не гарантирует блокировку. Поэтому
после UNKNOWN re-run запрещён процедурно, а не только кодом.

### 5.6 Инварианты RC

Не меняются без отдельного решения владельца: формат `rc/*`; track `internal`;
`release_status: completed`; Automatic Distribution без `--beta-group` и `--testflight`;
подтверждение `TESTFLIGHT_INTERNAL_DISTRIBUTION_CONFIRMED`; существующие теги;
отсутствие gate и облачного разрешения для RC.
Единственное предлагаемое изменение RC: `ERROR_IF_IN_REVIEW` (Q2). Оно защищает
production review от RC-коммита. Маркер `STORE_MUTATION_BEGIN` (этап 4) печатается
и для RC: это только строка лога, без изменения поведения.

---

## 6. Порядок этапов

```text
Этап 1  Контракт: очистка, DryRun, gate до git, канал в истории номеров   (Dart)
   │
   ├── Этап 2  Android: Play commit, production track, targetSdk  (Ruby, Dart verify)
   ├── Этап 3  iOS: App Store versions / review submissions       (Python)
   │
Этап 4  Облачное разрешение tag@SHA по платформам + маркер мутации  (YAML, Dart, Ruby, Python)
   │
Этап 5  PR-регрессия Python/Ruby + эксплуатационная документация
   │
Этап 6  Репетиция без публикации + production-readiness
```

Обоснование:

- Этап 1 первым: он чисто локальный, снимает P-12, P-17 и даёт DryRun. С ним
  дальнейшие этапы проверяются preview без gate.
- Этапы 2 и 3 затрагивают разные файлы и могли бы идти параллельно. Выполняются
  последовательно: одна стадия за запуск, один писатель.
- Этап 4 после адаптеров: он правит те же `play.rb` и `ios_store.py`, конфликт
  исключён последовательностью.
- Этап 5 после кода: документация описывает уже существующее поведение, а PR-job
  ловит регрессию всего набора.
- Этап 6 не меняет код. Запросы к магазинам в нём выполняет только владелец.

Общие правила для каждого этапа:

- Один исполнитель-писатель в checkout. Параллельно допускаются только read-only аудиторы.
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
`git rev-parse HEAD`. Если Docker недоступен, Ruby-тесты считаются **NOT RUN**, а
этап, меняющий Ruby, не может быть принят. Ни одна команда не требует credentials.
Если тест падает из-за отсутствия credentials или сети, это дефект теста, а не повод
их передать.

---

## 7. Этап 1 — контракт: очистка, DryRun, gate до git, канал в истории номеров

1. **Цель.** Production DryRun без gate. Реальный production-запуск без gate
   отказывает раньше любой git-команды. RC и Production не делят номер. CLI снова
   работает на чистом дереве.
2. **Проблемы.** P-01, P-02, P-12, P-17; часть P-11 (`tool/release/README.md`).
3. **Зависимости.** Нет. GO владельца на удаление пяти файлов (Q6).
4. **Границы.**
   - Можно: `tool/release/cli.dart`, `tool/release/release.dart`,
     `test/release/cli_test.dart`, `test/release/release_test.dart`, абзац про
     dry-run в `tool/release/README.md`; удаление пяти untracked-файлов раздела 4.
   - Нельзя: workflow YAML, Ruby, Python, формат тегов, фразу `PUBLISH PRODUCTION`,
     RC-поведение, `CICD-README.md` (этап 5), любые git-операции с origin.
5. **Участки кода.** `main()` в `cli.dart`, `ReleaseCli.plan`, `ReleaseCli.execute`,
   `ReleasePlan`, `ReleaseCli.validateStores` (ветка `release.build == maximum`),
   `validateBuildHistory`, `validateProduction`.
6. **Решение.** Строго по разделу 5.3:
   - `main()`: если канал `production` и нет `--dry-run`, вызвать
     `validateProduction` сразу после проверки аргументов, до
     `git rev-parse --show-toplevel`.
   - `ReleaseCli.plan(platform, channel, {required bool dryRun})`: при
     `production && !dryRun` — `validateProduction` первым действием. Иначе gate не читать.
     `ReleasePlan` получает поле `dryRun`.
   - `execute`: если `dryRun != plan.dryRun` → `ReleaseFailure` без записей и prompt.
     Для production печатать `Production gate (local): ENABLED|DISABLED`. При
     `!dryRun && production` — `validateProduction` до первого `confirm` и
     существующая проверка перед `git tag`.
   - `validateBuildHistory`: в условие пары добавить `previous.channel == release.channel`.
     Сообщение для равного номера в другом канале:
     `Build N already used by <tag> in another channel; RC and production never share a build. Bump pubspec.`
   - `validateStores`: допустимое имя пары — только
     `'${release.production ? '' : 'rc/'}$other/v$same'`.
   - README: production dry-run не требует gate; реальный запуск требует и отказывает до git.
7. **Инструкция исполнителю.** Prompt E1 (раздел 13).
8. **Effort / Context.** Medium / файлы этапа плюс разделы 5.2–5.3.
9. **Тесты.** `flutter test --no-pub test/release`, `flutter analyze`, `dart format`,
   `git diff --check`, Python-набор (README и docs-тесты не должны сломаться).
   Fixture в `cli_test.dart` дополнить списком **всех** вызовов `runGit` (`calls`), а не
   только записей. Обязательные новые и изменённые тесты:
   - production DryRun без env и с env `true`: план построен; `calls` содержит только
     локальные чтения и `ls-remote`; нет `fetch`, `tag`, `push`; `confirm` не вызывался;
     вывод содержит `DISABLED` или `ENABLED` соответственно и `DRY RUN`;
   - production `plan(dryRun: false)` без env и с `'false'`, `'TRUE'`, `' true'`, `''`:
     `ReleaseFailure`, **`calls` пуст, `reads` пуст**, `confirm` не вызывался;
   - подпроцесс `dart <абсолютный путь>/tool/release/cli.dart android production` с
     `PRODUCTION_PUBLISHING_ENABLED=false`, рабочая директория — временная папка вне
     Git: exit 1 и сообщение о выключенном gate, **а не** ошибка `rev-parse`. Это
     доказывает, что отказ идёт до первой git-команды;
   - `execute(planDry, dryRun: false)` → `ReleaseFailure`, `writes` пуст, `confirm` не вызывался;
   - production с env `true`: прежние `fetch`, `tag`, `push`; отказ от `y` или от
     `PUBLISH PRODUCTION` → `writes` пуст;
   - `rc/ios/v1.2.3+24` на SHA `s`, версия `1.2.3+24` → `android production` BLOCK,
     `ios production` BLOCK, `android rc` OK (пара RC);
   - `android/v1.2.3+25` на `s` → `ios production` `+25` OK; на `other` → BLOCK;
     `rc/ios` `+25` → BLOCK (другой канал);
   - `validateBuildHistory` unit: матрица platform × channel × version × SHA для равного номера;
   - `validateStores`: снапшот Play с кодом 25 + `rc/android/v1.2.3+25` не даёт пары
     для `ios production`; `android/v1.2.3+25` даёт;
   - RC: реальный запуск без env по-прежнему не читает gate; существующие RC-тесты
     не меняются и проходят.
10. **Приёмка.**
    - [ ] 5 файлов раздела 4 удалены; `git status --short` пуст, кроме файлов этапа.
    - [ ] Таблица операций 5.3 реализована; каждая ячейка «нет» покрыта тестом.
    - [ ] Gate реального production проверяется в `main()` до git, в `plan()` первым
      действием, в `execute()` до prompt и перед `git tag`.
    - [ ] DryRun не делает `fetch` и не вызывает `confirm` ни при каком значении gate.
    - [ ] Пара номера требует одного канала в `validateBuildHistory` и `validateStores`.
    - [ ] Dart 118 + новые тесты проходят; Python-набор проходит.
    - [ ] Нет изменений в YAML, Ruby, Python-коде.
11. **Негативные сценарии.** Опечатка в gate; gate не `true`; исполнение плана,
    построенного как DryRun; ответ `N`/пустой/`yes`; отказ от `PUBLISH PRODUCTION`;
    main сдвинулся после preview; тег появился во время подтверждения; RC-номер для
    Production; Production-номер для RC; пара на другом SHA; пара другой версии;
    локальный неотправленный тег.
12. **Регрессии RC.** Тесты `rc` в `cli_test.dart`, `source_test.dart`, PowerShell-обёртки.
    Признак регрессии: любой изменённый ожидаемый результат для `rc`.
13. **Риски и откат.** Риск: DryRun начнут путать с разрешением. Смягчение: явная
    строка gate, отсутствие prompt, фраза `DRY RUN`. Откат: `git revert <коммит этапа>`
    в ветке. Удалённые untracked-файлы не восстанавливаются. STOP, если любой из пяти
    файлов окажется tracked или на него появится ссылка.
14. **Владелец.** GO на удаление (Q6). Если нужна копия — сохранить вне репозитория заранее.
15. **Аудит.** Diff этапа; список удалённых путей; вывод трёх команд из ветки против
    текущего `origin/main` (`07926a7d`):
    - `dart tool/release/cli.dart android production --dry-run` → `BLOCKED` историей
      (`+24` в другом канале), без prompt;
    - `dart tool/release/cli.dart ios production --dry-run` → `BLOCKED` историей;
    - `dart tool/release/cli.dart android production` без env → `BLOCKED` gate.
    До и после: `git show-ref --tags`, `git rev-parse refs/remotes/origin/main`, `git status --short`.

---

## 8. Этап 2 — Android: commit без отмены review, production track, targetSdk

1. **Цель.** Commit в Play никогда не отменяет чужой review. Production publish не
   вытесняет чужие releases. AAB доказуемо таргетирует API ≥ 36.
2. **Проблемы.** P-03, P-04, P-05; часть P-10 (Ruby-тесты в Android workflow).
3. **Зависимости.** Этап 1 принят. Решения Q2 и Q3. Docker Desktop для Ruby-тестов.
4. **Границы.**
   - Можно: `tool/release/play_store.rb`, `tool/release/play_policy.rb`, `tool/release/play.rb`
     (только классификация ошибки commit), `tool/release/sdk_contract_test.rb`,
     `tool/release/play_policy_test.rb`, `tool/release/play_store_test.rb`,
     `tool/release/verify_android.dart`, новый `test/release/verify_android_test.dart`,
     шаг `Analyze and run tests` в `.github/workflows/android-release.yml` (добавить
     два bundle-теста).
   - Нельзя: track RC, `release_status`, rollout, `Gemfile`/`Gemfile.lock`,
     gate-логика и маркер мутации (этап 4), чтение Play без temporary edit, любые
     сетевые вызовы в тестах.
5. **Участки кода.** `ProkatPlayStore` (рядом с `NoBlindPlayRetries`), `PlayPolicy.check!`,
   блок `rescue` в `play.rb`, `main` в `verify_android.dart`.
6. **Решение.**
   - `play_store.rb`: модуль `ProkatPlayStore::ErrorIfInReview`, prepend к
     `Google::Apis::AndroidpublisherV3::AndroidPublisherService#commit_edit`. Принудительно
     подставляет `changes_in_review_behavior: 'ERROR_IF_IN_REVIEW'` поверх любого
     переданного значения. При загрузке: если
     `instance_method(:commit_edit).parameters` не содержит
     `[:key, :changes_in_review_behavior]` — `raise` (fail closed до любого запроса).
     Применяется к RC и Production, если владелец не решит иначе (Q2).
   - `play.rb`: при `Google::Apis::ClientError` с HTTP 400 и причиной
     `CHANGES_ALREADY_IN_REVIEW` печатать фиксированный код
     `PLAY_CHANGES_IN_REVIEW: commit refused, edit not committed; inspect Play Console before any retry`.
     Тело ответа не печатать. Остальные ошибки — как сейчас.
   - `PlayPolicy.check!`: при `channel == 'production'` любой release на track
     `production` со статусом не `completed` (`draft`, `inProgress`, `halted`,
     `statusUnspecified` и неизвестные) → `Blocked`
     `Production track has a <status> release; resolve it in Play Console first`.
     Для RC правило не применяется (Q3).
   - `verify_android.dart`: вынести чистую функцию
     `void requireTargetSdk(String dumped, {int minimum = 36})` (trim, `int.tryParse`, `≥ minimum`).
     Вызвать bundletool
     `dump manifest --bundle=… --xpath=/manifest/uses-sdk/@android:targetSdkVersion`.
     Сообщение успеха дополнить `targetSdk`.
7. **Инструкция исполнителю.** Prompt E2.
8. **Effort / Context.** High / файлы этапа, fastlane `supply/lib/supply/{client,uploader}.rb`
   версии 2.241.0, документ edits.commit, раздел 5.
9. **Тесты.**
   - `sdk_contract_test.rb`: keyword присутствует; модуль в `ancestors`; вызов
     `commit_edit` на экземпляре сервиса с подменённым `execute_or_queue_command` даёт
     `command.query['changesInReviewBehavior'] == 'ERROR_IF_IN_REVIEW'`, даже если
     вызывающий передал `CANCEL_IN_REVIEW_AND_SUBMIT`.
   - `play_policy_test.rb`: production + track `production` с `draft`/`inProgress`/
     `halted`/`statusUnspecified`/`weird` → blocked; только `completed` старых кодов → OK;
     RC при production `draft` → OK; прежние случаи без изменений.
   - `verify_android_test.dart`: `36`, `37`, `" 36\n"` → OK; `35`, `""`, `abc`, `-1` → BLOCK.
   - Полный Dart, Python, Ruby наборы.
10. **Приёмка.**
    - [ ] Без keyword в SDK загрузка `play_store.rb` падает.
    - [ ] Любой `commit_edit` отправляет `ERROR_IF_IN_REVIEW`.
    - [ ] Production с не-`completed` release на track `production` блокируется в preflight и в publish.
    - [ ] AAB с target < 36 не доходит до `play.rb publish`.
    - [ ] Android workflow запускает все три Ruby-теста.
    - [ ] RC: track `internal`, `completed` — без изменений.
11. **Негативные сценарии.** SDK без параметра; вызывающий передаёт другой behavior;
    `CHANGES_ALREADY_IN_REVIEW`; неизвестный статус release; target 35; пустой вывод bundletool.
12. **Регрессии RC.** Если Q2 = «да», RC с открытым review теперь падает
    `PLAY_CHANGES_IN_REVIEW`, а не отменяет его. Это ожидаемо и отражается в runbook на этапе 5.
    Прочее поведение RC не меняется: проверяется тестами `rc` в `play_policy_test.rb`.
13. **Риски и откат.** Prepend в чужой gem: при обновлении fastlane или google-apis
    контракт-тест обязан упасть. Edit, не прошедший commit, Play со временем удаляет
    сам; версия кода считается занятой, пока владелец не проверит App bundle explorer.
    Откат — `git revert`. STOP, если Ruby-тесты нельзя запустить.
14. **Владелец.** Решения Q2, Q3. Live-проверки Play не выполняются.
15. **Аудит.** Diff; вывод трёх Ruby-тестов; новый Dart-тест; grep: `commit_edit` нигде
    не вызывается в обход сервиса; Gemfile.lock не менялся.

---

## 9. Этап 3 — iOS: App Store versions и review submissions до сборки

1. **Цель.** Production не стартует сборку и не загружает IPA, если CLI 0.70.0
   переименует чужую версию, изменит версию в ревью или переиспользует чужой submission.
   UNKNOWN останавливает прогон.
2. **Проблемы.** P-07, P-08.
3. **Зависимости.** Этап 1 принят (этап 2 не обязателен).
4. **Границы.**
   - Можно: `tool/release/ios_store.py` (только production-путь `preflight`/`main`, новые
     чистые функции, коды и стадии), `tool/release/ios_store_test.py`, при необходимости
     `tool/release/apple_diagnostic.py` — **только** если требуется синхронизация
     allowlist кодов.
   - Нельзя: RC-ветки `publish_arguments` и `checked_publish_arguments`,
     `confirm_testflight_distribution`, `apple_publish.py`, argv production,
     `codemagic.yaml`, `requirements*.txt`, любые POST/PATCH/DELETE.
5. **Участки кода.** `preflight(context)`, `read_apple_state`, `all_pages`,
   `FAILURE_CODES`, `STAGES`, `SUCCESS_EVENTS`, `validate_apple_environment`, `main`.
6. **Решение.**

   **6.1. Сверка с источниками (без запросов к живому магазину).**

   | Факт | Значение | Источник | Статус |
   | --- | --- | --- | --- |
   | Запрос CLI 0.70.0 для выбора версии | `GET /v1/apps/{id}/appStoreVersions?limit=100&filter[appStoreState]=DEVELOPER_REJECTED,INVALID_BINARY,METADATA_REJECTED,PREPARE_FOR_SUBMISSION,REJECTED,WAITING_FOR_REVIEW&filter[platform]=IOS`, обход `links.next` до конца | `SubmitToAppStoreAction._get_editable_app_store_version`; `Apps.list_app_store_versions_data`; `ResourceManager.Filter.as_query_params`; `AppStoreConnectApiClient._paginate` | ПОДТВЕРЖДЕНО |
   | Выбор CLI | максимум по `versionString` среди найденных; затем PATCH `versionString`, `build`, `releaseType` | `_get_editable_app_store_version`, `_update_existing_app_store_version`, `AppStoreVersions.modify` | ПОДТВЕРЖДЕНО |
   | Review submission в CLI | `POST /v1/reviewSubmissions`; при ошибке «another reviewSubmissions with id … still in progress» — чтение этого id и добавление своего item, затем confirm | `_create_review_submission`, `ReviewSubmissions.create/read` | ПОДТВЕРЖДЕНО |
   | `AppVersionState` (актуальное поле) | 15 значений: `ACCEPTED`, `DEVELOPER_REJECTED`, `IN_REVIEW`, `INVALID_BINARY`, `METADATA_REJECTED`, `PENDING_APPLE_RELEASE`, `PENDING_DEVELOPER_RELEASE`, `PREPARE_FOR_SUBMISSION`, `PROCESSING_FOR_DISTRIBUTION`, `READY_FOR_DISTRIBUTION`, `READY_FOR_REVIEW`, `REJECTED`, `REPLACED_WITH_NEW_VERSION`, `WAITING_FOR_EXPORT_COMPLIANCE`, `WAITING_FOR_REVIEW` | OpenAPI App Store Connect 4.3.1 (`components.schemas.AppVersionState`); `codemagic.apple.resources.enums.AppVersionState` 0.70.0 — совпадают | ПОДТВЕРЖДЕНО |
   | `AppStoreVersionState` (`appStoreState`, deprecated с API 3.3) | 20 значений: `ACCEPTED`, `DEVELOPER_REMOVED_FROM_SALE`, `DEVELOPER_REJECTED`, `IN_REVIEW`, `INVALID_BINARY`, `METADATA_REJECTED`, `PENDING_APPLE_RELEASE`, `PENDING_CONTRACT`, `PENDING_DEVELOPER_RELEASE`, `PREPARE_FOR_SUBMISSION`, `PREORDER_READY_FOR_SALE`, `PROCESSING_FOR_APP_STORE`, `READY_FOR_REVIEW`, `READY_FOR_SALE`, `REJECTED`, `REMOVED_FROM_SALE`, `WAITING_FOR_EXPORT_COMPLIANCE`, `WAITING_FOR_REVIEW`, `REPLACED_WITH_NEW_VERSION`, `NOT_APPLICABLE` | OpenAPI 4.3.1 `AppStoreVersionState`. В enum CLI 0.70.0 нет `ACCEPTED`, `READY_FOR_REVIEW`, `NOT_APPLICABLE` | ПОДТВЕРЖДЕНО |
   | Редактируемые состояния CLI | `DEVELOPER_REJECTED`, `INVALID_BINARY`, `METADATA_REJECTED`, `PREPARE_FOR_SUBMISSION`, `REJECTED`, `WAITING_FOR_REVIEW` (по `appStoreState`) | `AppStoreState.editable_states()` 0.70.0 | ПОДТВЕРЖДЕНО |
   | `ReviewSubmission.state` | 7 значений: `READY_FOR_REVIEW`, `WAITING_FOR_REVIEW`, `IN_REVIEW`, `UNRESOLVED_ISSUES`, `CANCELING`, `COMPLETING`, `COMPLETE` | OpenAPI 4.3.1 `ReviewSubmission.attributes.state`; `ReviewSubmissionState` 0.70.0 — совпадают | ПОДТВЕРЖДЕНО |
   | `GET /v1/reviewSubmissions` | `filter[app]` обязателен; `filter[platform]`, `filter[state]` необязательны; `limit` ≤ 200 | OpenAPI 4.3.1 | ПОДТВЕРЖДЕНО |
   | `fields[appStoreVersions]` | допускает `versionString`, `platform`, `appStoreState`, `appVersionState` | OpenAPI 4.3.1 | ПОДТВЕРЖДЕНО |
   | Сохранение `filter[...]` в `links.next` | Apple должен повторять фильтры в ссылке следующей страницы | Существующий `all_pages` уже требует этого для `/v1/builds` и `/v1/apps/{id}/buildUploads`, RC-прогоны прошли. Для двух новых endpoint не проверено | ПРЕДПОЛОЖЕНИЕ. Если фильтры пропадут, `all_pages` вернёт `APPLE_PAGINATION_FAILED` — fail closed, релиз блокируется до отдельного решения |
   | Связь `appStoreState` ↔ `appVersionState` | Полная таблица соответствия Apple не публикует | — | НЕИЗВЕСТНО. Проверяется консистентность (правило R4), расхождение — блок |

   **6.2. Запросы (только GET, через существующие `all_pages`/`checked_url`).**

   - Версии: `/v1/apps/{id}/appStoreVersions?filter[platform]=IOS&fields[appStoreVersions]=versionString,platform,appStoreState,appVersionState&limit=100`.
     Без фильтра по состоянию: классификатор должен увидеть все версии, включая неизвестные состояния. `limit=100`, как у CLI.
   - Submissions: `/v1/reviewSubmissions?filter[app]={id}&filter[platform]=IOS&fields[reviewSubmissions]=platform,state&limit=200`.
     Без `filter[state]`: незнакомое состояние должно стать UNKNOWN, а не выпасть из выборки.
   - Пагинация: существующие гарантии `all_pages` — тот же путь и те же `filter[...]`,
     только хост Apple, без редиректов, не больше 100 страниц, без циклов и дубликатов id,
     согласованный `meta.paging.total`, общий дедлайн 90 секунд. Любое нарушение — UNKNOWN.

   **6.3. Правила `check_app_store_versions(context, versions, submissions)`.** Применяются по порядку, первое сработавшее даёт код.

   | № | Условие | Код |
   | --- | --- | --- |
   | R1 | У версии нет `id`, `versionString`, `platform`, `appStoreState` или `appVersionState`; `platform ≠ IOS`; значение состояния вне списков 6.1; `versionString` не из 1–3 числовых компонентов. У submission нет `id`/`state`; `platform ≠ IOS`; `state` вне 7 значений | `APPLE_RESPONSE_INVALID` (UNKNOWN) |
   | R2 | Есть submission в `READY_FOR_REVIEW`, `WAITING_FOR_REVIEW`, `IN_REVIEW`, `UNRESOLVED_ISSUES`, `CANCELING` или `COMPLETING` (`COMPLETE` игнорируется) | `APPLE_REVIEW_SUBMISSION_OPEN` |
   | R3 | Есть версия с `appVersionState` ∈ {`WAITING_FOR_REVIEW`, `IN_REVIEW`, `READY_FOR_REVIEW`, `ACCEPTED`, `PENDING_APPLE_RELEASE`, `PENDING_DEVELOPER_RELEASE`, `PROCESSING_FOR_DISTRIBUTION`, `WAITING_FOR_EXPORT_COMPLIANCE`} | `APPLE_VERSION_IN_FLIGHT` |
   | R4 | Для какой-либо версии `appStoreState ∈ editable CLI` ≠ `appVersionState ∈ {PREPARE_FOR_SUBMISSION, DEVELOPER_REJECTED, REJECTED, METADATA_REJECTED, INVALID_BINARY}` | `APPLE_VERSION_STATE_MISMATCH` |
   | R5 | Редактируемых версий больше одной, либо одна со строкой ≠ версии тега | `APPLE_VERSION_CONFLICT` |
   | R6 | Версия в `READY_FOR_DISTRIBUTION` или `REPLACED_WITH_NEW_VERSION` со строкой ≥ версии тега (сравнение по трём компонентам, недостающие = 0) | `APPLE_VERSION_NOT_INCREASING` |
   | R7 | Иначе | OK: «создать версию» (редактируемых нет) или «продолжить» (одна редактируемая с нашей строкой) |

   R4 гарантирует, что CLI выберет ту же версию, что одобрил наш классификатор. При
   прохождении R3 состояние `WAITING_FOR_REVIEW` до R4 не доходит.

   **6.4. Прочее.**
   - Вызов только при `context["channel"] == "production"` внутри `preflight(context)`,
     то есть дважды: до сборки и перед upload в шаге publish.
   - Production закрепляет `config["app_id"] == "6817078475"` (константа без
     привязки к RC, например `APP_ID`). Код ошибки существующий: `APPLE_APP_MISMATCH`.
   - Новые коды (`APPLE_REVIEW_SUBMISSION_OPEN`, `APPLE_VERSION_IN_FLIGHT`,
     `APPLE_VERSION_STATE_MISMATCH`, `APPLE_VERSION_CONFLICT`,
     `APPLE_VERSION_NOT_INCREASING`) и стадии (`versions`, `submissions`) добавить в
     allowlist. Сообщения фиксированные, без тел ответов, без `versionString` чужих версий.
7. **Инструкция исполнителю.** Prompt E3.
8. **Effort / Context.** High / `ios_store.py`, `ios_store_test.py`, исходники cli-tools
   v0.70.0 (`submit_to_app_store_action.py`, `enums.py`, `apps/apps.py`,
   `versioning/review_submissions.py`, `api_client.py`), раздел 9.6.1.
9. **Тесты.** Fake `get_json`/`all_pages`, без сети:
   - каждое из 15 значений `appVersionState` и 20 значений `appStoreState` перечислено в
     тесте явно, с ожидаемой классификацией; значение вне списка → R1;
   - каждое из 7 значений `ReviewSubmission.state`, отсутствующее и неизвестное → R1/R2/игнор;
   - каждое правило R1–R7 → ожидаемый код; при любом блоке издатель (`subprocess.run`)
     не вызывается;
   - порядок правил: submission открыт и версия в ревью одновременно → R2;
   - 401/403/429/5xx/timeout/битая пагинация/фильтр пропал в `next` на стадиях `versions`
     и `submissions` → UNKNOWN без издателя;
   - URL запросов точно совпадают с 6.2: без `filter[state]` и `filter[appStoreState]`, только GET;
   - RC: URL `appStoreVersions` и `reviewSubmissions` не запрашиваются;
   - production argv идентичен текущему (snapshot-сравнение со списком из `test_production_requests_after_approval`);
   - production с `APP_STORE_APP_ID` ≠ `6817078475` → `APPLE_APP_MISMATCH` до publish;
   - существующие 169 тестов проходят, `testflight_distribution_test.py` не изменён.
10. **Приёмка.**
    - [ ] Таблицы 6.1–6.3 реализованы; списки состояний в коде совпадают с 6.1 буквально.
    - [ ] Неизвестное значение любого состояния даёт блок, а не «нет версии».
    - [ ] Только GET; `checked_url` и `all_pages` переиспользованы, без нового HTTP-клиента.
    - [ ] Нет изменений RC-пути и argv.
    - [ ] Ошибки и коды не содержат тел ответов или значений env.
11. **Негативные сценарии.** Все строки R1–R6; пустой ответ на второй странице;
    `next` на чужой хост или без фильтров; дубликат ID; таймаут общего дедлайна 90 секунд.
12. **Регрессии RC.** `ios_store_test.py` RC-случаи, `testflight_distribution_test.py`, `apple_publish_test.py`.
13. **Риски и откат.** Новые значения состояний Apple дадут UNKNOWN: fail closed, владелец
    увидит код. Между вторым preflight и действиями CLI остаётся окно до ~30 минут
    (`--max-find-build-wait 10` + `--max-build-processing-wait 20`): состояние может
    измениться. Это остаточный риск, документируется. Откат — `git revert`.
14. **Владелец.** Нет действий до фазы B. Live GET не выполняется.
15. **Аудит.** Diff; вывод Python-набора; построчное сопоставление 6.1–6.3 с тестами;
    grep на `method="POST"|PATCH|DELETE` в `ios_store.py` (должно быть пусто).

---

## 10. Этап 4 — облачное разрешение tag@SHA по платформам и маркер мутации

1. **Цель.** Один push тега, забытый `true` или чужой тег не публикуют: каждый
   провайдер требует разрешения конкретного `тег@SHA` своей платформы. Лог CI
   однозначно показывает, начиналась ли мутация магазина.
2. **Проблемы.** P-09, P-18.
3. **Зависимости.** Этапы 1–3 приняты. **Решение Q1 обязательно.** Ниже описан
   рекомендуемый вариант A. При другом решении план этапа переписывается и снова
   согласуется.
4. **Границы.**
   - Можно: `tool/release/release.dart` (`validateCloudAuthorization`, вызов в `ci`),
     `tool/release/cli.dart` (guard-строки, строка облачного разрешения в preview),
     `.github/workflows/android-release.yml` (env и шаг gate), `tool/release/play.rb` и
     `tool/release/play_policy.rb` (функция авторизации, маркер), `tool/release/ios_store.py`
     (`main`, маркер), тесты `release_test.dart`, `cli_test.dart`, `config_test.py`,
     `ios_store_test.py`, `play_policy_test.rb`; раздел U5 в `docs/ci-cd/MANUAL_SETUP.md`.
   - Нельзя: создавать или менять секреты и переменные, GitHub settings, Codemagic UI,
     триггеры workflow, RC-путь (для RC разрешение не читается и не требуется).
5. **Участки кода.** Шаг `Reject production until U5`; `validateProduction`;
   `play.rb` (строки с `PRODUCTION_PUBLISHING_ENABLED`); `ios_store.py main`; список
   guard в `ReleaseCli.plan`; `ReleaseCli.execute` (preview).
6. **Решение (вариант A).**
   - Переменные: GitHub repository **Variable** `PRODUCTION_RELEASE_AUTH_ANDROID`
     (видна, менять может только admin); Codemagic переменная группы `prokat-ios-release`
     `PRODUCTION_RELEASE_AUTH_IOS`. Формат и строгость — раздел 5.4.
   - Правило для production в CI: `PRODUCTION_PUBLISHING_ENABLED == "true"` **и**
     переменная своей платформы == `"<tag>@<commit>"`, где `commit` — уже проверенный
     `GITHUB_SHA` или `CM_COMMIT`.
   - Слои Android (каждый независимо): bash-шаг gate до установки Flutter
     (`$GITHUB_REF_NAME@$GITHUB_SHA`); `release.dart ci`; `play.rb preflight`;
     `play.rb publish` (`tag` и `commit` из `build/release/context.json`).
   - Слои iOS: `release.dart ci`; `ios_store.py validate-publish`; `ios_store.py preflight`;
     `ios_store.py publish`.
   - Маркер `STORE_MUTATION_BEGIN platform=<android|ios> tag=<tag>` печатается
     непосредственно перед `Supply::Uploader.new.perform_upload` и перед
     `subprocess.run([...apple_publish.py...])` для обоих каналов. Только `print`,
     без изменения логики.
   - Preview production (dry-run и реальный запуск) печатает
     `Cloud authorization required: <GitHub variable PRODUCTION_RELEASE_AUTH_ANDROID|Codemagic variable PRODUCTION_RELEASE_AUTH_IOS> = <tag>@<sha>`.
   - Guard в `ReleaseCli.plan` **только для channel `production`**: Android workflow
     обязан содержать `PRODUCTION_RELEASE_AUTH_ANDROID`; iOS принимается через
     `release.dart`, содержащий `validateCloudAuthorization` (по образцу текущего
     исключения). RC-план новую guard-строку не требует, иначе RC против старого
     `main` сломается.
   - `config_test.py` закрепляет точный список входов Android
     (`test_exact_android_u2_input_inventory_and_prebuild_key_check`,
     `test_cost_artifact_and_production_contract`). Обновить их явно, добавив
     `PRODUCTION_RELEASE_AUTH_ANDROID`, а не ослаблять проверку.
   - `MANUAL_SETUP.md`, раздел U5: порядок фаз C и D раздела 15 и правила 5.5.
7. **Инструкция исполнителю.** Prompt E4.
8. **Effort / Context.** High / все файлы этапа, разделы 5.4–5.5, текущие тесты gate.
9. **Тесты.**
   - `release_test.dart` (`validateCloudAuthorization`): матрица
     `enabled ∈ {absent,'true','TRUE','false'}` × `auth ∈ {absent, exact, тот же тег с
     другим SHA, другой тег с тем же SHA, exact+' ', ' '+exact, exact в верхнем регистре,
     значение для другой платформы, rc-тег}`. Пропускает только (`'true'`, exact).
     Android читает только `_ANDROID`, iOS только `_IOS`: значение, записанное в
     переменную другой платформы, не пропускает. RC — функция не вызывается.
   - `config_test.py`: gate-шаг в `android-release.yml` идёт до `Install pinned Flutter`,
     ссылается на `vars.PRODUCTION_RELEASE_AUTH_ANDROID`, `github.ref_name`, `github.sha`;
     шаги `play.rb` получают переменную; никакой шаг не записывает `vars`/`secrets`.
   - `ios_store_test.py`: production без точного совпадения → блок до API и издателя
     для `validate-publish`, `preflight`, `publish`; маркер печатается до издателя и не
     печатается при блоке preflight; RC без переменной работает как раньше.
   - `play_policy_test.rb`: функция авторизации — та же матрица; маркер печатается только
     после успешной повторной проверки и до `perform_upload` (проверка через подмену).
   - `cli_test.dart`: production-guard отсутствует → BLOCK; RC без guard → OK;
     preview содержит строку облачного разрешения с точным `tag@sha`.
   - Re-run: тест на уровне функции — одинаковые входы дважды подряд дают одинаковый
     результат (разрешение не «расходуется»). Это фиксирует, что защита от повторов —
     процедура 5.5 и store-preflight, а не gate.
10. **Приёмка.**
    - [ ] Четыре слоя Android и четыре слоя iOS проверяют `tag@SHA` своей платформы независимо.
    - [ ] Маркер мутации стоит строго перед первой мутацией магазина в обоих каналах.
    - [ ] RC не читает новые переменные.
    - [ ] Секреты и переменные не создавались.
    - [ ] MANUAL_SETUP U5 описывает выставление, очистку и правила повтора из 5.5.
11. **Негативные сценарии.** Boolean `true`, разрешение другого тега; тот же тег на
    другом SHA; разрешение `true`, boolean `false`; пробел в значении; значение iOS в
    Android-переменной; RC-тег в переменной; re-run после очистки переменной.
12. **Регрессии RC.** Все RC-тесты; `config_test.py` на неизменность RC-триггеров; лог RC
    получает только новую строку маркера.
13. **Риски и откат.** Разрешение остаётся, пока владелец его не очистит: re-run того же
    тега проходит gate (5.4, 5.5). Риск write-доступа к секретам кодом не снимается.
    Откат — `git revert`.
14. **Владелец.** Q1; OC-A2 (тариф, rulesets, collaborators). При возможности —
    создать tag ruleset (действие владельца).
15. **Аудит.** Diff; таблица «слой → где проверка → тест»; подтверждение, что
    `secrets.*` и `vars.*` в YAML только читаются; grep маркера во всех местах публикации.

---

## 11. Этап 5 — PR-регрессия и эксплуатационная документация

1. **Цель.** Любой PR прогоняет полный набор release-тестов без секретов.
   Документация совпадает с кодом.
2. **Проблемы.** P-10, P-11.
3. **Зависимости.** Этапы 1–4 приняты. Q7 (минуты Actions).
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
   - Документы описывают: таблицу 5.3; правило номеров 5.2; облачное разрешение и его
     границы 5.4; повтор и UNKNOWN 5.5 с таблицей исходов; Play `ERROR_IF_IN_REVIEW` и
     production track; iOS-коды этапа 3; порядок фаз раздела 15; RC `+19` и `+24` как
     неизменяемую историю.
   - `PRODUCTION_READINESS.md`: чек-лист раздела 15 с PASS/FAIL по каждому пункту.
6. **Инструкция исполнителю.** Prompt E5.
7. **Effort / Context.** Medium / список документов, этот план, итоговый код этапов 1–4.
8. **Тесты.** Весь Dart, Python и Ruby; `cli_docs_test.py` (ссылки, отсутствие ручных
   команд тегов); `actionlint`, если доступен локально, иначе отметить NOT RUN.
9. **Приёмка.**
    - [ ] Job не ссылается на `secrets`, не имеет `write`-прав.
    - [ ] Ни один текущий гайд не содержит ручного создания тегов или force-операций.
    - [ ] Пример следующего номера — без конкретного «безопасного» значения, только правило.
    - [ ] Нигде не сказано, что разрешение одноразовое или само исключает повтор.
    - [ ] Все команды, переменные и коды в документах существуют в коде.
10. **Негативные сценарии.** Сломанная ссылка; устаревший номер; job, зависящий от сети магазинов.
11. **Регрессии RC.** RC-разделы гайдов не меняют смысл, только номера и ссылки.
12. **Риски и откат.** Расход минут (Q7). Откат — `git revert`.
13. **Владелец.** Q7.
14. **Аудит.** Diff документов против кода (grep команд, переменных и кодов ошибок).

---

## 12. Этап 6 — репетиция без публикации и готовность

1. **Цель.** Доказать, что ни один путь не публикует без явного разрешения, и
   подготовить первый Production к решению владельца.
2. **Зависимости.** Этапы 1–5 приняты.
3. **Границы.** Без изменений кода, кроме исправлений, найденных репетицией. Они
   идут отдельным согласованным этапом. Никаких тегов, gate, секретов, переменных,
   store-запросов агентом. Локальный env `PRODUCTION_PUBLISHING_ENABLED` агент не выставляет.
4. **Шаги агента.** Ветка, CLI из ветки, `origin/main` = `07926a7d` (или текущий, если
   владелец уже что-то слил — тогда ожидания пересчитываются и согласуются заново).

   | Команда | Ожидание |
   | --- | --- |
   | `prokat-rc-android -DryRun` | План `rc/android/v1.2.3+24` (пара RC с `rc/ios/v1.2.3+24`, тот же SHA), `DRY RUN`, без записей и prompt. Только preview, не разрешение |
   | `prokat-rc-ios -DryRun` | `BLOCKED`: `rc/ios/v1.2.3+24` уже существует |
   | `prokat-prod-android -DryRun` | `BLOCKED` историей номеров: `+24` занят `rc/ios/v1.2.3+24` в другом канале. Preview и строка gate не печатаются: план не построен |
   | `prokat-prod-ios -DryRun` | `BLOCKED` историей: тот же номер той же платформы в канале RC |
   | `prokat-prod-android` без `-DryRun`, env не задан | `BLOCKED` gate: `Production publishing is disabled…`. Ни одной git-команды, prompt не показывается |
   | `prokat-prod-ios` без `-DryRun`, env не задан | То же |

   - Положительный случай production DryRun (план построен, строки gate и облачного
     разрешения) доказывается fake-тестами этапов 1 и 4 и проверяется владельцем на
     новом `main` в OC-B5.
   - До и после: `git show-ref --tags`, `git ls-remote --tags origin`,
     `git rev-parse refs/remotes/origin/main`, `git status --short` — без изменений.
   - Отчёт `PRODUCTION_READINESS.md` с фактическими результатами.
5. **Шаги владельца.** Фазы B–E раздела 15, каждая после отдельного решения.
6. **Effort / Context.** Medium / этот план, readiness, вывод команд.
7. **Приёмка.** Все ожидания таблицы совпали; теги и refs не изменились; чек-лист
   production-readiness заполнен.
8. **Риски.** Расхождение ожиданий — STOP и отчёт, без «подгонки».

---

## 13. Prompts для исполнителей

Общий заголовок каждого prompt:

> Ты исполнитель одного этапа в репозитории PROKAT (`C:\Users\User\Documents\GitHub\prokat`),
> ветка `feat/production-cicd-hardening`. Прочитай `docs/plans/production-cicd.md`
> целиком: разделы 3, 5 и свой этап. План — техническое задание, но код проверяй сам.
> Запрещено: push, merge, теги, изменения секретов, переменных и консолей магазинов,
> вызовы реальных API Google и Apple, выставление `PRODUCTION_PUBLISHING_ENABLED`,
> `git reset --hard`, `git clean`, правки вне границ этапа, изменения RC-поведения
> сверх описанного. Если план противоречит коду или тест требует credentials —
> остановись и опиши проблему. В конце: команды и фактический вывод,
> diff-статистика, список негативных сценариев с тестами, один коммит этапа без push.

**E1 (Effort Medium, Context: этап 1 + разделы 4, 5.2, 5.3).**
Удали пять untracked-файлов раздела 4, предварительно проверив `git ls-files` (должны
отсутствовать) и `git grep` (нет ссылок). Реализуй таблицы раздела 5.3 в `main()`,
`ReleaseCli.plan`, `ReleaseCli.execute` и `ReleasePlan`, канал в
`validateBuildHistory`/`validateStores` и тесты пункта 9, включая учёт **всех**
вызовов git в fixture и подпроцесс вне Git-репозитория. Не трогай YAML, Ruby,
Python-код и `CICD-README.md`. Покажи вывод трёх команд пункта 15 и состояние
тегов и refs до и после.

**E2 (Effort High, Context: этап 2 + fastlane 2.241.0 `supply/client.rb`, `uploader.rb`).**
Реализуй prepend `ERROR_IF_IN_REVIEW` с fail-closed проверкой сигнатуры, правило
production track в `PlayPolicy.check!`, классификацию `CHANGES_ALREADY_IN_REVIEW`,
`requireTargetSdk` и тест к нему, два bundle-теста в Android workflow. Не меняй
`Gemfile.lock`, track RC, `release_status`, gate и маркеры. Ruby-тесты запускай только
командой раздела 6. Если Docker недоступен — STOP, этап не сдаётся.

**E3 (Effort High, Context: этап 3 целиком, особенно 6.1–6.3; исходники cli-tools v0.70.0 из пункта 8).**
Добавь GET-only чтение `appStoreVersions` и `reviewSubmissions` строго с URL из 6.2,
функцию классификации R1–R7 в указанном порядке, константы состояний буквально по
6.1, закрепление app ID для production, коды и стадии в allowlist. Не добавляй
`filter[state]`/`filter[appStoreState]`. Не меняй RC, argv, `apple_publish.py`,
`all_pages`. Каждое значение перечислений и каждое правило — отдельный тест;
издатель в негативных тестах не вызывается. Если поведение `all_pages` мешает
реализации — STOP и опиши, не ослабляй проверки.

**E4 (Effort High, Context: этап 4 + разделы 5.4–5.5; только после записанного решения Q1).**
Реализуй `validateCloudAuthorization` с форматом `tag@sha` и переменными по
платформам во всех слоях таблицы этапа 4, маркер `STORE_MUTATION_BEGIN`, строку
облачного разрешения в preview и тесты-матрицы, включая тест «разрешение не
расходуется». Ни одного `gh secret`/`gh variable`, ни одной правки настроек. RC новые
переменные не читает. Не пиши в документах и комментариях, что разрешение одноразовое.

**E5 (Effort Medium, Context: этап 5 + разделы 5 и 15 + итоговый код).**
Добавь job `release-tooling` без секретов и обнови документы по списку. Порядок
действий владельца бери только из раздела 15, правила повтора — только из 5.5.
Каждое утверждение документа сверяй с кодом через grep и ссылайся на файл.

**Аудитор (read-only, Effort Medium, Context: diff этапа + план).**
Проверь diff этапа против границ и приёмки, запусти тесты раздела 6, перечисли
расхождения. Ничего не меняй.

---

## 14. Решения владельца

| ID | Вопрос | Рекомендация | Нужно до |
| --- | --- | --- | --- |
| Q1 | Модель облачного разрешения | A: boolean + переменная своей платформы `tag@SHA` (5.4). Альтернативы: оставить только boolean; GitHub Environment с required reviewers (по документации GitHub для private repo требуется Enterprise — подтвердить в OC-A2; у Codemagic аналога нет) | этапа 4 |
| Q2 | `ERROR_IF_IN_REVIEW` и для RC | Да: иначе RC-коммит может отменить production review | этапа 2 |
| Q3 | Production track с `draft`/`inProgress`/`halted` блокирует publish | Да; RC не затрагивается | этапа 2 |
| Q4 | `AFTER_APPROVAL` или `MANUAL`; phased release | Оставить `AFTER_APPROVAL` и дефолт приложения | OC-C1 |
| Q5 | Версия и номер первого Production | `X.Y.Z` > последней версии App Store в `READY_FOR_DISTRIBUTION`/`REPLACED_WITH_NEW_VERSION`; `N` > 24, > max Play, > max Apple (включая Build Uploads) | OC-B3 |
| Q6 | Удаление пяти promotion-файлов на этапе 1 | Да (владелец разрешил); копия — по желанию владельца | этапа 1 |
| Q7 | Job release-tooling в каждом PR | Да; оценить минуты Actions приватного репозитория | этапа 5 |

---

## 15. Ручные checkpoints владельца

Агент их не выполняет. Значения секретов в чат не передаются. Фазы идут строго по
порядку; внутри фазы — сверху вниз. FAIL любого пункта останавливает следующую фазу.

### Фаза A — до и во время реализации (ничего не включается)

| ID | Действие | PASS | FAIL / STOP |
| --- | --- | --- | --- |
| OC-A1 | Записать решения Q1–Q7 до этапов из колонки «Нужно до» | Решение записано | Этап, зависящий от решения, не стартует |
| OC-A2 | GitHub: тариф организации, видимость репозитория, Settings → Rules (rulesets), Environments, список людей с write/admin | Записано; write только у доверенных; при доступности создан tag ruleset (раздел 5.4) | Неизвестные writers → сначала ограничить доступ |
| OC-A3 | GitHub → Settings → Secrets and variables → Actions: имена RC-секретов и переменных (`ANDROID_*`, `PLAY_SERVICE_ACCOUNT_JSON_BASE64`, `GOOGLE_SERVICES_JSON_BASE64`, `MAPBOX_PUBLIC_TOKEN`, `ANDROID_UPLOAD_CERT_SHA256`, `PLAY_HISTORICAL_MAX_BUILD`) | Все есть; `PRODUCTION_PUBLISHING_ENABLED` отсутствует или `false`; `PRODUCTION_RELEASE_AUTH_ANDROID` отсутствует или пуста | Чего-то нет, или gate уже `true` → STOP |
| OC-A4 | Codemagic: `ios-production` виден; группа `prokat-ios-release` содержит `APP_STORE_APP_ID=6817078475`, `IOS_HISTORICAL_MAX_BUILD`, PEM, plist; integration `prokat-app-store`; signing `app_store`; кто в команде может менять группу и запускать сборки | Совпадает; gate и `PRODUCTION_RELEASE_AUTH_IOS` отсутствуют | Нет distribution identity → STOP |

### Фаза B — подготовка версии (после принятия этапов 1–6)

| ID | Действие | PASS | FAIL / STOP |
| --- | --- | --- | --- |
| OC-B1 | Play: в Console (или `play_access.rb` по отдельному GO — **создаёт и удаляет temporary edit**) записать максимум versionCode (включая drafts), статусы `production`/`internal`, primary locale, Managed publishing, наличие production access, очередь review | Записано; production track без чужих draft/inProgress/halted; production access есть | Abort edit не подтверждён; нет production access → STOP |
| OC-B2 | App Store Connect: максимум build и Build Uploads; список App Store versions и их состояния; review submissions; скриншоты, privacy, age rating, контакт ревьюера, export compliance | По правилам R2–R6 этапа 3 ничего не блокирует; метаданные заполнены | Есть in-flight версия или открытый submission → разрешить вручную, повторить OC-B2 |
| OC-B3 | Выбрать `X.Y.Z+N` по Q5 на основе OC-B1 и OC-B2; подготовить notes | Записано | — |
| OC-B4 | PR ветки в `dev`; затем bump и notes в `dev`; затем PR `dev` → `main` после `git diff --stat origin/main origin/dev`; после merge — `sync-dev` | Только ожидаемые файлы | Неожиданные файлы → STOP |
| OC-B5 | `prokat-prod-android -DryRun` и `prokat-prod-ios -DryRun` на новом `main`, без env | План построен; тег без `rc/`; номер из OC-B3; SHA = `origin/main`; `Production gate (local): DISABLED`; строки облачного разрешения записаны | Любое иное → STOP |

### Фаза C — U5: однократная активация

| ID | Действие | PASS | FAIL / STOP |
| --- | --- | --- | --- |
| OC-C1 | Решения Q4 и о Managed publishing приняты; Play service account получает app permission **Release to production** | Права выданы | — |
| OC-C2 | GitHub Secret `PRODUCTION_PUBLISHING_ENABLED=true`; Codemagic group secret `PRODUCTION_PUBLISHING_ENABLED=true` | Оба выставлены | — |
| OC-C3 | Проверить, что `PRODUCTION_RELEASE_AUTH_ANDROID` и `PRODUCTION_RELEASE_AUTH_IOS` пусты | Пусты: после U5 ни один тег всё ещё не публикуется | Не пусты → очистить, STOP |

### Фаза D — релиз одной платформы (повторяется отдельно для Android и для iOS)

Платформы выпускаются по очереди, никогда одновременно. Вторая платформа начинает
фазу D только после того, как первая прошла D7.

| ID | Действие | PASS | FAIL / STOP |
| --- | --- | --- | --- |
| OC-D1 | Свежая проверка магазина этой платформы (как OC-B1 или OC-B2) | Номер свободен, чужих review и releases нет | Иначе STOP |
| OC-D2 | `prokat-prod-<platform> -DryRun`: тот же номер и тот же SHA, что в OC-B5 (для второй платформы — пара того же канала и SHA) | Совпадает; строка облачного разрешения записана | `main` сдвинулся → вернуться к OC-B3/OC-B5 |
| OC-D3 | Выставить **только** переменную этой платформы (`PRODUCTION_RELEASE_AUTH_ANDROID` в GitHub или `PRODUCTION_RELEASE_AUTH_IOS` в Codemagic) равной строке из OC-D2. Переменная другой платформы пуста | Выставлено ровно одно значение | — |
| OC-D4 | В новой PowerShell-сессии: `$env:PRODUCTION_PUBLISHING_ENABLED='true'`, затем `prokat-prod-<platform>`, `y`, `PUBLISH PRODUCTION`; сразу после — `Remove-Item Env:PRODUCTION_PUBLISHING_ENABLED` | Тег отправлен, CLI напечатал SHA | Ошибка push → инструкция CLI; разрешение очистить (OC-D6) |
| OC-D5 | Наблюдать прогон провайдера до конечного состояния | Конечное состояние достигнуто | — |
| OC-D6 | **Сразу** очистить переменную этой платформы, до разбора результата | Пусто | — |
| OC-D7 | Классифицировать исход по таблице 5.5 и проверить магазин | SUBMITTED подтверждён в консоли | FAILED_BEFORE_MUTATION или UNKNOWN → действовать строго по 5.5; повтор только через новый цикл D1–D7 |

### Фаза E — после релиза и аварийная остановка

| ID | Действие | PASS |
| --- | --- | --- |
| OC-E1 | Обе переменные `PRODUCTION_RELEASE_AUTH_*` пусты; локальный env снят | Да |
| OC-E2 | Аварийная остановка в любой момент: `PRODUCTION_PUBLISHING_ENABLED=false` у провайдера. Начатый прогон и уже отправленный review проверяются отдельно в консоли | Документировано в runbook |

### Production-readiness (итог этапа 6)

- [ ] Этапы 1–5 приняты отдельными аудитами.
- [ ] Production DryRun строит план без gate, не делает `fetch` и не пишет refs.
- [ ] Реальный production без gate отказывает до первой git-команды.
- [ ] RC и Production не делят номер (тесты).
- [ ] Play: `ERROR_IF_IN_REVIEW`, production track без чужих releases, targetSdk ≥ 36.
- [ ] iOS: versions и submissions читаются GET до сборки и перед upload; все значения
      состояний из 6.1 покрыты тестами; неизвестное значение блокирует.
- [ ] Облако требует `tag@SHA` своей платформы (или иное записанное решение Q1).
- [ ] Маркер `STORE_MUTATION_BEGIN` есть в обоих адаптерах; runbook классифицирует исходы по 5.5.
- [ ] Документация не утверждает, что разрешение одноразовое; порядок очистки описан.
- [ ] PR прогоняет Dart, Python, Ruby release-тесты.
- [ ] Документация совпадает с кодом; в diff нет promotion-кода.
- [ ] Фаза A пройдена; фазы B–E описаны в runbook и готовы к исполнению владельцем.

---

## 16. Реестр рисков

| Риск | Вероятность / влияние | Мера |
| --- | --- | --- |
| Commit Play отменяет чужой review | Средняя / высокое | Этап 2 |
| Publish вытесняет production draft/staged rollout | Низкая / высокое | Этап 2, Q3 |
| CLI 0.70.0 переименовывает или меняет версию в ревью; подтверждает чужой submission | Средняя / высокое | Этап 3 (R2–R5) |
| Apple перестаёт возвращать deprecated `appStoreState` или повторять фильтры в `links.next` | Низкая / среднее | R1 и `all_pages` блокируют (fail closed); отдельное решение до релиза |
| Случайный production-тег при включённом boolean | Средняя / высокое | Этап 4: нужен `tag@SHA` своей платформы |
| Re-run того же тега, пока разрешение не очищено | Средняя / высокое | Процедура 5.5 (OC-D6 сразу после конечного состояния); store-preflight; маркер мутации |
| Владелец забыл очистить разрешение | Средняя / среднее | OC-E1; другие теги всё равно не совпадут; re-run остаётся возможен — см. строку выше |
| Тег с ожидаемым именем создан кем-то другим | Низкая / среднее | SHA в разрешении; ruleset при доступности (OC-A2) |
| Writer с доступом к репозиторию читает секреты или меняет workflow | Низкая / критическое | OC-A2: ограничить write, rulesets, environments по тарифу |
| UNKNOWN после upload (таймаут, сеть, отмена) | Средняя / среднее | Re-run запрещён; разбор в консоли; новый номер |
| Upload начался, а магазин ещё не показывает номер | Низкая / высокое | Store-preflight этого не гарантирует → после UNKNOWN re-run запрещён процедурно |
| Изменение Apple-состояний за окно обработки (до ~30 минут) | Низкая / среднее | Остаточный, задокументирован |
| Обновление fastlane/google-apis ломает prepend | Низкая / высокое | Контракт-тест, Gemfile.lock frozen |
| Новые значения enum Apple/Google | Низкая / низкое | Fail closed → UNKNOWN |
| Automatic Distribution показывает production-билд тестерам | Высокая / низкое | Принято (P-14) |
| Документы снова устаревают | Средняя / низкое | Этап 5, `cli_docs_test.py` |

---

## 17. RC `1.2.3+19` и `1.2.3+24`

Теги `rc/android/v1.2.3+19`, `rc/ios/v1.2.3+19`…`+24` остаются как есть: их не
двигают, не удаляют и не используют как обязательный шаг. После этапа 1 они
участвуют только как нижняя граница общего счётчика: первый Production `N > 24`.
Принятые в магазинах RC-сборки владелец при желании продвигает вручную в консоли.
Pipeline этого не делает.

---

## 18. Чек-лист аудита этого плана

- [ ] Раздел 1 совпадает с `git rev-parse origin/dev origin/main` и `git diff --stat origin/main origin/dev`.
- [ ] Каждая проблема раздела 3 воспроизводится по указанным функциям и источникам.
- [ ] Раздел 4: пять путей untracked, без ссылок, в истории отсутствуют.
- [ ] Правило 5.2 закрывает: RC↔Production, частичную пару, повтор CLI, другой SHA, другую версию.
- [ ] Таблица 5.3 однозначна: где проверяется gate, какие чтения до отказа разрешены, что запрещено всегда.
- [ ] 5.4–5.5 нигде не называют разрешение одноразовым; re-run, очистка и UNKNOWN описаны.
- [ ] Android и iOS получают разные переменные разрешения; порядок фазы D по платформе.
- [ ] Фазы A–E раздела 15 идут без противоречий: проверки → активация U5 → релиз → очистка.
- [ ] Перечисления 6.1 этапа 3 совпадают с исходниками CLI 0.70.0 и OpenAPI; неизвестное — fail closed.
- [ ] Ни один этап не требует store-запросов или изменения секретов агентом.
- [ ] Для каждого этапа заданы границы, тесты, приёмка, негативы, RC-регрессии, откат, аудит.
- [ ] RC-инварианты 5.6 не нарушаются ни одним этапом без решения владельца (Q2).
- [ ] Commit ревизии содержит только этот файл.

---

## 19. Ревизия 2: исправленные противоречия

| № | Было | Стало |
| --- | --- | --- |
| 1 | `PRODUCTION_RELEASE_TAG` описан как «одноразовое разрешение» | Разрешение `tag@SHA` — не токен. Границы защиты, права на теги, порядок очистки, повтор и UNKNOWN — разделы 5.4 и 5.5; маркер мутации P-18 |
| 2 | OC-9 настраивал «оба провайдера на один тег» | Отдельные переменные `PRODUCTION_RELEASE_AUTH_ANDROID` и `PRODUCTION_RELEASE_AUTH_IOS`; фаза D по одной платформе с очисткой |
| 3 | Gate в `execute()` «до вопроса», но `plan()` уже делал `ls-remote` и fetch; этап 6 ждал отказа «историей» | Таблица 5.3 (P-17): отказ до git в `main()` и `plan()`; DryRun без fetch и prompt; тесты этапа 1 и ожидания этапа 6 синхронизированы |
| 4 | OC-1…OC-10 смешивали проверки, merge, U5 и запуск; U5 включал выбор тега | Фазы A–E с однозначным порядком; U5 = фаза C без разрешения конкретного тега |
| 5 | Таблица состояний Apple без сверки, запрос submissions с `filter[state]` | Сверка 6.1 по CLI 0.70.0 и OpenAPI 4.3.1; запросы без фильтров состояния; правила R1–R7 по порядку; неизвестное — fail closed |
