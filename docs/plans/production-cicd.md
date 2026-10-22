# Production CI/CD PROKAT — план доведения прямых Production-релизов

Статус: **этап 0, ревизия 3 (после третьего аудита). Реализация не начата.**
Ветка: `feat/production-cicd-hardening` от `origin/dev` `6f0aa0e506a0f4c74745d4e9fa7196032207b82c`.
Что исправлено в ревизиях 2 и 3 — раздел 19.

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
| `origin/main` | `07926a7d` `release: 1.2.3+24 (iOS retry) (#83)`; локальный `refs/remotes/origin/main` совпадает с `git ls-remote origin refs/heads/main` |
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
G3–G4 выполняет только CLI владельца в фазе D.

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
| Исполнение | `ReleaseCli.execute` | интерактивный ввод | `Continue? [y/N]`; для production `PUBLISH PRODUCTION`; gate; повторная проверка main и тегов | G2 в `refs/remotes/origin/main`, G3, G4 exact tag ref | `cli_test.dart` |
| CI: источник | `release.dart ci` → `validateEvent`, `validateProduction`, `validateRevision`, `validatePubspecVersion`, `prepare` | env провайдера, `GITHUB_EVENT_PATH`/`CM_TAG`, `--revision` = `GITHUB_SHA`/`CM_COMMIT` | не tag push; удаление тега; SHA не в `main`; peeled-коммит тега ≠ revision; история; pubspec ≠ тег; gate | `git fetch` в runner | `release_test.dart`, `source_test.dart` |
| CI: gate Android | шаг `Reject production until U5` в `android-release.yml`; `play.rb` | `secrets.PRODUCTION_PUBLISHING_ENABLED` | значение ≠ `true` | нет | `config_test.py` (структура) |
| CI: gate iOS | `release.dart ci`, `ios_store.py main` | env-группа Codemagic `prokat-ios-release` | значение ≠ `true` | нет | `ios_store_test.py` |
| Состояние Play | `play.rb preflight` → `ProkatPlayStore.snapshot` → `PlayPolicy.check!` | `PLAY_SERVICE_ACCOUNT_JSON_BASE64`, `vars.PLAY_HISTORICAL_MAX_BUILD` | номер занят; номер ≤ максимума; locale; track ≠ канал | **да: `edits.insert` + `edits.delete`** (P-06) | `play_policy_test.rb`, `play_store_test.rb` |
| Состояние Apple | `ios_store.py preflight` → `read_apple_state` + `check_builds` | `PROKAT_ASC_PRIVATE_KEY_PEM`, `APP_STORE_CONNECT_*`, `APP_STORE_APP_ID`, `IOS_HISTORICAL_MAX_BUILD`, `TESTFLIGHT_GROUP` (RC) | номер занят в builds/buildUploads; номер не растёт; 401/403/429/5xx/timeout/пагинация → UNKNOWN | нет (GET). Пишет `build/release/apple-state.json` в runner | `ios_store_test.py` |
| Сборка Android | `inputs.dart android`, `verify_upload_key.py`, `flutter build appbundle`, Crashlytics mapping | keystore, пароли, alias, `google-services.json`, Mapbox `pk.*` | отпечаток upload key ≠ `ANDROID_UPLOAD_CERT_SHA256`; mapping пуст | загрузка mapping в Firebase | `verify_upload_key_test.py` |
| Проверка AAB | `verify_android.dart` + bundletool 1.18.3 (sha256 закреплён) | `ANDROID_UPLOAD_CERT_SHA256` | подпись; отпечаток; debug-сертификат; package; versionCode/Name. **Без targetSdk (P-05)** | нет | **нет тестов** |
| Публикация Android | шаг `Recheck state and publish once…` → `play.rb publish` → `Supply::Uploader#perform_upload` | service account | канал/track/номер в отдельном temporary edit; событие GitHub | **да**: `begin_edit` (новый edit), upload AAB, `update_track` (заменяет все releases track, P-04), changelogs, `edits.commit` (**default `CANCEL_IN_REVIEW_AND_SUBMIT`, P-03**) | `sdk_contract_test.rb` (наличие опций) |
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
| P-03 | P0 | Commit в Play без `changesInReviewBehavior`. Дефолт API `CANCEL_IN_REVIEW_AND_SUBMIT` отменяет текущий review. Касается и RC: commit internal-релиза отменит production review | `play.rb` задаёт только `changes_not_sent_for_review: false`; `Supply::Client#commit_current_edit!` (fastlane 2.241.0) передаёт только его; [edits.commit](https://developers.google.com/android-publisher/api-ref/rest/v3/edits/commit) | ПОДТВЕРЖДЕНО. Keyword `changes_in_review_behavior` есть в `google-apis-androidpublisher_v3` ≥ 0.97.0; в `Gemfile.lock` 0.109.0 |
| P-04 | P0 | Publish в production молча вытесняет существующие `draft`/`inProgress`/`halted` releases на track | `Supply::Uploader#update_track` делает `track.releases = [track_release]` (fastlane 2.241.0, `uploader.rb:451-456`); `PlayPolicy.check!` статусы production track не проверяет | ПОДТВЕРЖДЕНО |
| P-05 | P1 | AAB не проверяется на `targetSdkVersion ≥ 36`. Правило Google Play с 31.08.2026 | `verify_android.dart` проверяет только package/versionCode/versionName/подпись. Сейчас target = 36 из Flutter 3.47.2 (`flutter_tools/lib/src/android/gradle_utils.dart: targetSdkVersion = '36'`), но понижение не поймается. У `verify_android.dart` нет тестов | ПОДТВЕРЖДЕНО |
| P-06 | info | Чтение Play — не GET: `edits.insert` + `edits.delete`, дважды за прогон, плюс `play_access.rb` | `ProkatPlayStore.snapshot` (`play_store.rb:31-55`) | ПОДТВЕРЖДЕНО. Документировано в `ANDROID_SETUP.md`, менять не нужно. Запрещено вызывать без GO |
| P-07 | P0 | iOS production не проверяет App Store versions и review submissions. Codemagic CLI 0.70.0: (a) выбирает **самую новую** версию среди редактируемых, с любой строкой, и делает PATCH `versionString`/`build`; (b) к редактируемым относит `WAITING_FOR_REVIEW`; (c) если `POST /v1/reviewSubmissions` отвечает «another reviewSubmissions … still in progress», **переиспользует** найденный submission, добавляет в него свою версию и подтверждает его вместе с чужими элементами | `SubmitToAppStoreAction._get_editable_app_store_version`, `_update_existing_app_store_version`, `_create_review_submission`; `AppStoreState.editable_states()`; `Apps.list_app_store_versions` (`filter[appStoreState]`, `filter[platform]=IOS`, `limit=100`, обход `links.next`) — cli-tools v0.70.0. Чужие submissions CLI не отменяет: `--cancel-previous-submissions` не передаётся (P-15) | ПОДТВЕРЖДЕНО |
| P-08 | P2 | Production Apple app ID не закреплён (RC закреплён `require_rc_target`) | `validate_apple_environment` принимает любой `APP_STORE_APP_ID`. Смягчение: проверка `bundleId == com.auyltech.prokat` в `read_apple_state` | ПОДТВЕРЖДЕНО |
| P-09 | P0 | Облачный gate — постоянный boolean. После включения любой push production-тега или re-run публикует. `PUBLISH PRODUCTION` проверяется только локально. Неизменяемость тегов обеспечивает только клиентский CLI. Re-run (GitHub «Re-run jobs», Codemagic rebuild) переиспользует тот же тег и проходит любой gate, который в момент re-run разрешает этот тег | `android-release.yml` (`on.push.tags`, шаг `Reject production until U5`); `codemagic.yaml` (`ios-production`, `tag_patterns: ios/v*`); `cli.dart execute` | ПОДТВЕРЖДЕНО для кода. Серверные rulesets — ПРЕДПОЛОЖЕНИЕ (OC-A2). Сохраняет ли Codemagic rebuild исходный `CM_TAG` — ПРЕДПОЛОЖЕНИЕ (OC-A4) |
| P-10 | P1 | Python- и Ruby-тесты релиза не запускаются в PR. Python идёт только в Codemagic release run (рядом с секретами); из Ruby в Android run запускается лишь `play_policy_test.rb`; `play_store_test.rb` и `sdk_contract_test.rb` автоматически не запускаются нигде | `.github/workflows/pull-request.yml`, `android-release.yml:99`, `codemagic.yaml:42` | ПОДТВЕРЖДЕНО |
| P-11 | P2 | Документация устарела: «production dry-run requires gate»; «следующий общий релиз `1.2.4+24`» (24 уже занят). Тесты закрепляют устаревший текст | `tool/release/README.md:49-51`; `CICD-README.md` раздел E; `cli_test.dart` `'documented wrappers…'` и `cli_docs_test.py test_owner_commands_and_flags_exist` проверяют `1.2.4+24` | ПОДТВЕРЖДЕНО |
| P-12 | P1 | Untracked-файлы promotion блокируют все четыре команды | `ReleaseCli.clean`, `main()` в `cli.dart` | ПОДТВЕРЖДЕНО |
| P-13 | info | После upload iOS ждёт обработку не более 20 минут; при таймауте IPA уже в ASC, submission нет | `publish_arguments`: `--max-build-processing-wait 20` | ПОДТВЕРЖДЕНО. Поведение fail-closed верное (UNKNOWN, без retry). Не менять без решения владельца |
| P-14 | info | Automatic Distribution внутренней TestFlight-группы может показать тестерам и production-билд | настройка Apple (`hasAccessToAllBuilds`), production argv группу не назначает | ПРИНЯТО. Не менять: сломает RC |
| P-15 | — | Production argv не содержит `--testflight`, `--beta-group`, `--cancel-previous-submissions`, `--expire-build-submitted-for-review` | `publish_arguments`, `test_production_requests_after_approval` | ИСПРАВЛЕНО РАНЕЕ |
| P-16 | — | Upload/API без blind retry: Play `retries = 0`, `SUPPLY_UPLOAD_MAX_RETRIES=0`; Apple attempt counts 1/1/1, парсинг argv закреплённым CLI | `play_store.rb NoBlindPlayRetries`, `apple_publish.validate_publish_arguments` | ИСПРАВЛЕНО РАНЕЕ |
| P-17 | P1 | Реальный production-запуск без gate до отказа успевает выполнить G1 `ls-remote` и fetch во временный bare-репозиторий. Gate проверяется только внутри `plan()`, а `main()` до этого уже вызывает git | порядок в `main()` и `ReleaseCli.plan` | ПОДТВЕРЖДЕНО |
| P-18 | P1 | По логу CI нельзя однозначно понять, вызывался ли издатель. Это нужно, чтобы отличить «издатель не вызывался» от UNKNOWN | `play.rb publish` и `ios_store.py publish` печатают маркер только при успехе | ПОДТВЕРЖДЕНО |
| P-19 | P0 | Preflight iOS — единственная защита до мутаций. Между вторым preflight и PATCH версии, созданием submission и confirm проходит до ~30 минут (`--max-find-build-wait 10`, `--max-build-processing-wait 20`); CLI сам заново выбирает версию и может переиспользовать чужой submission | `_submit_to_app_store` → `_ensure_app_store_version` → `_create_review_submission` → `create_review_submission_item` → `confirm_review_submission` (cli-tools v0.70.0) | ПОДТВЕРЖДЕНО |
| P-20 | P0 | Проверка production track (P-04) в плане ревизии 2 шла в отдельном temporary edit `play.rb preflight`, а commit делает другой edit, созданный `Supply::Uploader#perform_upload` | `ProkatPlayStore.snapshot` и `Supply::Uploader#perform_upload` (`client.begin_edit`) | ПОДТВЕРЖДЕНО. По [Edits](https://developers.google.com/android-publisher/edits): edit — копия развёрнутого состояния на момент `insert`; изменение в Console или commit другого edit инвалидирует открытый edit, commit инвалидированного edit падает без эффекта. Значит, проверка внутри публикуемого edit закрывает окно |
| P-21 | P1 | Commit edit отправляет на ревью и изменения из Console, «готовые к отправке» владельцем ([Concurrency considerations](https://developers.google.com/android-publisher/concurrency-considerations)). API не даёт надёжно увидеть этот список | контракт Google Play | ПОДТВЕРЖДЕНО. Закрывается ручным checkpoint OC-D1 |
| P-22 | P2 | Dry-run читает blobs по точному SHA из `ls-remote` (`cat-file -e`, `git show`, `GIT_NO_LAZY_FETCH=1`), поэтому устаревшие blobs не читает, но не сравнивает SHA с локальным `refs/remotes/origin/main` и не даёт явной диагностики «tracking-ref устарел/отсутствует» | `main()` в `cli.dart`, `readGitBlob` | ПОДТВЕРЖДЕНО. Явная проверка добавляется на этапе 1 |

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
- CLI не умеет и не должен повторять уже созданный тег: правило 4 блокирует
  `prokat-prod-<platform>` для существующего тега. Повтор облачного прогона того же
  тега — отдельный путь раздела 5.6.
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
| `ReleaseCli.plan(platform, channel, dryRun:)` | Не проверяет | Первым действием, до `clean()`, `ls-remote` и чтения blobs (защита при вызове API в обход `main`) |
| `ReleaseCli.execute(plan, dryRun:)` | Только печатает состояние gate | Повторно: до первого prompt и непосредственно перед `git tag` |
| `ReleasePlan` | Помечается `dryRun: true` | `execute(dryRun: false)` для плана с `dryRun: true` → BLOCK (план из локального кеша объектов не исполняется) |

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
| Push веток, `--force`, удаление и перенос тегов, запросы к CI или магазинам | никогда | никогда | никогда | никогда |

Вывод production DryRun при успешном плане: preview, строка
`Production gate (local): ENABLED|DISABLED`, после этапа 4 — строка облачного
разрешения (раздел 5.4) и `DRY RUN: no files, refs, tags or uploads changed.`
Если план не построен (свежесть, история, guard, notes), печатается только `BLOCKED: …`.
DryRun не является разрешением ни в одном из режимов.

### 5.4 Облачное разрешение и границы защиты

Уровни защиты Production:

| Уровень | Сейчас | Цель (вариант A решения Q1) |
| --- | --- | --- |
| Локальный CLI | env `PRODUCTION_PUBLISHING_ENABLED=true` + `PUBLISH PRODUCTION` | Без изменения смысла; gate переносится на старт реального запуска (5.3) |
| GitHub Actions (Android) | `secrets.PRODUCTION_PUBLISHING_ENABLED == true` | Плюс repository Variable `PRODUCTION_RELEASE_AUTH_ANDROID` == `"$GITHUB_REF_NAME@$GITHUB_SHA#$GITHUB_RUN_ATTEMPT"` |
| Codemagic (iOS) | `PRODUCTION_PUBLISHING_ENABLED == true` в группе `prokat-ios-release` | Плюс переменная группы `PRODUCTION_RELEASE_AUTH_IOS` == `"$CM_TAG@$CM_COMMIT"` |
| Сервер GitHub | неизвестно | Если тариф позволяет (OC-A2): tag ruleset на `refs/tags/android/v*`, `refs/tags/ios/v*`, `refs/tags/rc/**` — создание только владельцем, update и delete запрещены |
| Магазины | без production-права у Play service account | Право Release to production выдаётся один раз на U5 (OC-C1) |

Форматы разрешения (сравнение строгое: без trim, без регистра, без шаблонов):

- Android: `android/vX.Y.Z+N@<40-hex SHA>#<номер попытки>`, например
  `android/v1.2.4+25@0123…abcd#1`. Первый прогон тега — всегда попытка `1`;
  GitHub увеличивает `GITHUB_RUN_ATTEMPT` при каждом re-run того же run.
- iOS: `ios/vX.Y.Z+N@<40-hex SHA>`. У Codemagic нет счётчика попыток, известного до старта.

`GITHUB_SHA` и `CM_COMMIT` уже обязаны совпадать с peeled-коммитом тега
(`validateRevision`), поэтому разрешение привязано к содержимому, а не только к имени.
Production DryRun печатает точную строку для копирования (для Android — с `#1`).

Разрешения независимы по платформам: GitHub проверяет только
`PRODUCTION_RELEASE_AUTH_ANDROID` и только для `android/v*`; Codemagic — только
`PRODUCTION_RELEASE_AUTH_IOS` и только для `ios/v*`. Значение другой платформы не
совпадёт ни с одним прогоном. Boolean остаётся аварийным выключателем провайдера.

**Что разрешение даёт:**

- Push любого другого production-тега, в том числе следующего номера, не публикует.
- Тег с тем же именем на другом коммите не публикует.
- Android: re-run того же run не проходит, пока владелец явно не выставит номер новой
  попытки (`#2`, `#3`, …). Это техническая защита от случайного повтора при активной
  переменной.
- Забытый `PRODUCTION_PUBLISHING_ENABLED=true` без разрешения не публикует.
- Прогон после очистки разрешения не публикует.
- CI не может выдать разрешение сам себе: `permissions: contents: read`, переменные
  меняет только администратор GitHub или Codemagic.

**Чего разрешение не даёт:**

- Это **не одноразовый токен** и не запись о расходовании. Значение остаётся
  действительным, пока его не изменят.
- **iOS:** пока `PRODUCTION_RELEASE_AUTH_IOS` содержит строку, любой rebuild того же
  тега в Codemagic, если он сохраняет `CM_TAG`, проходит облачный gate. Это явный
  остаточный риск; решение Q8 обязательно до U5 (раздел 14).
- **Android:** разрешение с `#n` пропускает ровно попытку `n` того же run. Новый push
  того же тега невозможен (правило 4 и неизменяемость тега), поэтому другого run для
  этого тега быть не должно; при tag ruleset это гарантирует сервер.
- Оно не ограничивает, кто может создать тег. Без ruleset любой collaborator с правом
  write может отправить тег. Разрешение лишь требует, чтобы имя и SHA совпали с
  выбранными владельцем.
- Оно не защищает от collaborator с правом write, который меняет workflow в своей
  ветке и читает repository secrets. Это граница доверия репозитория: её снимают
  только ограничение write-доступа, rulesets и Environment-scoped секреты (OC-A2).
- Оно не доказывает, что магазин ещё не принял этот номер. Это делает store-preflight.

Параллельные прогоны: Android сериализован `concurrency: prokat-android-store`
(`cancel-in-progress: false`); iOS — concurrency 1 на тарифе Codemagic (проверяется в
OC-A4). Два одновременных прогона одной платформы этим исключены, но последовательный
повтор — нет (см. выше).

Почему повтор не создаёт второй публичный бинарник: Play отвергает уже
использованный versionCode, Apple отвергает повторный `CFBundleVersion` той же версии.
Store-preflight до сборки и перед upload блокирует номер, который магазин уже
показывает, а защита submission (этап 3) не даёт подтвердить чужой submission.
Остаточный риск повтора — лишняя попытка и путаница в консоли, а не двойная публикация.
Это не повод снимать процедуру 5.6.

### 5.5 Маркеры в логах и классификация исхода

Фиксированные строки (печатаются только в CI, без значений секретов):

| Маркер | Где | Что означает | Чего **не** означает |
| --- | --- | --- | --- |
| `PUBLISHER_INVOKED platform=<android\|ios> tag=<tag>` | Android: в `play.rb publish` после повторной проверки и сборки конфигурации Supply, **непосредственно перед** `Supply::Uploader.new.perform_upload`. iOS: в `apple_publish.py` после проверки argv и установки защит этапа 3, **непосредственно перед** `AppStoreConnect.invoke_cli()` | Управление передано издателю; с этого момента мутация магазина **возможна** | Что запрос к магазину был отправлен или что что-то изменилось |
| `PLAY_EDIT_COMMITTED` | после возврата `perform_upload` без исключения | Commit edit принят Google | Что релиз прошёл review или виден пользователям |
| `APPLE_REVIEW_SUBMISSION_CONFIRMED` | после успешного `confirm_review_submission` своего submission (этап 3) | Своя версия отправлена в App Review | Что ревью пройдено или версия опубликована |

Строки `APPLE_PUBLISH_ARGUMENTS_VALID`, `APPLE_PREFLIGHT_VERIFIED`,
`PLAY_PREFLIGHT_VERIFIED`, `VERIFIED: AAB …`, `APPLE_SUBMISSION_STEP_COMPLETED` и
нулевой код валидации **никогда** не считаются доказательством публикации.

Классификация завершённого прогона (владелец, по логу провайдера):

| Исход | Признак | Действие |
| --- | --- | --- |
| SUBMITTED | Android: `PLAY_EDIT_COMMITTED`. iOS: `APPLE_REVIEW_SUBMISSION_CONFIRMED` | Очистить разрешение. Проверить track или App Review в консоли |
| NOT_INVOKED | Прогон завершился, строки `PUBLISHER_INVOKED` в логе нет, лог полный | Очистить разрешение. Повтор того же `tag@SHA` допустим только путём 5.6 |
| UNKNOWN | `PUBLISHER_INVOKED` есть, маркера SUBMITTED нет. Сюда же: отмена, таймаут, неполный или потерянный лог | Очистить разрешение. **Повтор прежнего тега запрещён.** Проверить магазин: Play — App bundle explorer, tracks, Publishing overview; Apple — Build Uploads, TestFlight builds, App Store version, review submissions. Восстановление — вручную в консоли или новым номером, новым тегом и новым разрешением (фаза D заново) |

Порядок очистки разрешения:

1. Разрешение выставляется для одной платформы непосредственно перед действием,
   которое запускает прогон (OC-D3 или OC-R4).
2. Как только прогон провайдера дошёл до конечного состояния (успех, ошибка, отмена),
   владелец **сначала** очищает переменную этой платформы и только потом разбирает результат.
3. Переменная другой платформы в это время пуста.
4. Boolean `PRODUCTION_PUBLISHING_ENABLED` после U5 остаётся `true` как признак
   активированного pipeline. Аварийная остановка — `false` у провайдера. Это не
   отменяет уже начатый прогон и уже отправленный review.

### 5.6 Два пути запуска: первый релиз тега и повтор существующего тега

**Первый релиз тега** (фаза D): тега ещё нет; его создаёт `prokat-prod-<platform>`
после DryRun, разрешения и обоих подтверждений.

**Повтор существующего тега** (фаза R) допускается только для исхода NOT_INVOKED:

- `prokat-prod-<platform>` для повтора **не используется**: правило 4 раздела 5.2
  блокирует существующий тег, и это правильно.
- Новый push того же тега невозможен и запрещён.
- Проверка тега только чтением (G1):
  `git ls-remote origin "refs/tags/<tag>" "refs/tags/<tag>^{}"` — peeled SHA должен
  совпасть с SHA из разрешения.
- Свежая проверка магазина владельцем (как OC-D1). CI в повторном прогоне заново
  выполнит весь preflight до сборки и перед upload.
- Android: в GitHub Actions открыть **исходный** run тега → «Re-run all jobs»
  (или `gh run rerun <run-id>`). Перед этим выставить
  `PRODUCTION_RELEASE_AUTH_ANDROID=<tag>@<sha>#<следующий номер попытки>` (номер
  последней попытки run + 1). Другие способы (новый workflow_dispatch, ручной запуск
  другого workflow) запрещены: workflow запускается только push тега. GitHub позволяет
  re-run в течение 30 дней.
- iOS: в Codemagic открыть исходную сборку тега → «Rebuild». Перед этим выставить
  `PRODUCTION_RELEASE_AUTH_IOS=<tag>@<sha>`. Если в новой сборке нет `CM_TAG` или он
  другой, `release.dart ci` её заблокирует; тогда повтор невозможен, нужен новый номер.
  Поддержку rebuild с исходным `CM_TAG` владелец подтверждает в OC-A4; без подтверждения
  повтор iOS запрещён, только новый номер.
- Один повтор на одно выставление разрешения; после конечного состояния — очистка и
  новая классификация по 5.5.

**UNKNOWN** — повтор прежнего тега запрещён и процедурно, и (для Android) технически:
разрешение не выставляется заново для того же тега.

### 5.7 Инварианты RC

Не меняются без отдельного решения владельца: формат `rc/*`; track `internal`;
`release_status: completed`; Automatic Distribution без `--beta-group` и `--testflight`;
подтверждение `TESTFLIGHT_INTERNAL_DISTRIBUTION_CONFIRMED`; существующие теги;
отсутствие gate и облачного разрешения для RC.
Предлагаемые изменения RC: `ERROR_IF_IN_REVIEW` (Q2) — защищает production review от
RC-коммита; строка `PUBLISHER_INVOKED` печатается и для RC — только лог. Защиты
submission этапа 3 для RC не устанавливаются (RC не вызывает App Store submission).
Проверка production track этапа 2 для RC не активна.

---

## 6. Порядок этапов

```text
Этап 1  Контракт: очистка, DryRun со свежестью, gate до git, канал в истории   (Dart, PowerShell-тест)
   │
   ├── Этап 2  Android: commit без отмены review, проверка track в публикуемом edit, targetSdk  (Ruby, Dart verify)
   ├── Этап 3  iOS: preflight + защита выбора версии и submission в издателе                (Python)
   │
Этап 4  Облачное разрешение по платформам (Android с номером попытки) + PUBLISHER_INVOKED  (YAML, Dart, Ruby, Python)
   │
Этап 5  PR-регрессия Python/Ruby + эксплуатационная документация
   │
Этап 6  Репетиция без публикации + production-readiness
```

Обоснование:

- Этап 1 первым: он чисто локальный, снимает P-12, P-17, P-22 и даёт DryRun. С ним
  дальнейшие этапы проверяются preview без gate.
- Этапы 2 и 3 затрагивают разные файлы и могли бы идти параллельно. Выполняются
  последовательно: одна стадия за запуск, один писатель.
- Этап 4 после адаптеров: он правит те же `play.rb`, `ios_store.py` и `apple_publish.py`,
  конфликт исключён последовательностью.
- Этап 5 после кода: документация описывает уже существующее поведение, а PR-job
  ловит регрессию всего набора.
- Этап 6 не меняет код. Запросы к магазинам в нём выполняет только владелец.

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
   - Нельзя: workflow YAML, Ruby, Python, `prokat-release.ps1` (он уже передаёт
     код возврата), формат тегов, фразу `PUBLISH PRODUCTION`, RC-поведение,
     `CICD-README.md` (этап 5), операции G2–G4 (раздел 1).
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
     о gate, нет следов git. Тест выполняется только на Windows (как существующие
     PowerShell-тесты); на других ОС пропускается явно;
   - `execute(planDry, dryRun: false)` → `ReleaseFailure`, `writes` пуст, `confirm` не вызывался;
   - production с env `true`: прежние `fetch`, `tag`, `push`; отказ от `y` или от
     `PUBLISH PRODUCTION` → `writes` пуст;
   - `rc/ios/v1.2.3+24` на SHA `s`, версия `1.2.3+24` → `android production` BLOCK,
     `ios production` BLOCK, `android rc` OK (пара RC);
   - `android/v1.2.3+25` на `s` → `ios production` `+25` OK; на `other` → BLOCK;
     `rc/ios` `+25` → BLOCK (другой канал);
   - существующий production-тег → `plan` BLOCK (правило 4), в том числе после NOT_INVOKED:
     CLI не является путём повтора;
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
    Признак регрессии: любой изменённый ожидаемый результат для `rc`. RC DryRun теперь
    тоже требует свежий tracking-ref — это намеренное усиление, отражается в README.
13. **Риски и откат.** Риск: DryRun начнут путать с разрешением. Смягчение: явная
    строка gate, отсутствие prompt, фраза `DRY RUN`. Откат: `git revert <коммит этапа>`
    в ветке. Удалённые untracked-файлы не восстанавливаются. STOP, если любой из пяти
    файлов окажется tracked или на него появится ссылка; STOP, если тест «без git»
    нельзя построить так, чтобы git действительно был недоступен.
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

## 8. Этап 2 — Android: commit без отмены review, track в публикуемом edit, targetSdk

1. **Цель.** Commit в Play никогда не отменяет чужой review. Production publish не
   вытесняет чужие releases **в том edit, который будет зафиксирован**. AAB доказуемо
   таргетирует API ≥ 36.
2. **Проблемы.** P-03, P-04, P-05, P-20; часть P-10 (Ruby-тесты в Android workflow).
3. **Зависимости.** Этап 1 принят. Решения Q2 и Q3. Docker Desktop для Ruby-тестов.
4. **Границы.**
   - Можно: `tool/release/play_store.rb`, `tool/release/play_policy.rb`, `tool/release/play.rb`
     (включение защиты публикуемого edit перед `perform_upload` и классификация ошибок),
     `tool/release/sdk_contract_test.rb`, `tool/release/play_policy_test.rb`,
     `tool/release/play_store_test.rb`, `tool/release/verify_android.dart`, новый
     `test/release/verify_android_test.dart`, шаг `Analyze and run tests` в
     `.github/workflows/android-release.yml` (добавить два bundle-теста).
   - Нельзя: track RC, `release_status`, rollout, `Gemfile`/`Gemfile.lock`,
     gate-логика и маркер `PUBLISHER_INVOKED` (этап 4), любые сетевые вызовы в тестах.
5. **Участки кода.** `ProkatPlayStore` (рядом с `NoBlindPlayRetries`), `PlayPolicy.check!`,
   публикующая ветка и блок `rescue` в `play.rb`, `main` в `verify_android.dart`.
6. **Решение.**
   - **Commit:** модуль `ProkatPlayStore::ErrorIfInReview`, prepend к
     `Google::Apis::AndroidpublisherV3::AndroidPublisherService#commit_edit`. Принудительно
     подставляет `changes_in_review_behavior: 'ERROR_IF_IN_REVIEW'` поверх любого
     переданного значения. При загрузке: если
     `instance_method(:commit_edit).parameters` не содержит
     `[:key, :changes_in_review_behavior]` — `raise` (fail closed до любого запроса).
     Применяется к RC и Production, если владелец не решит иначе (Q2).
   - **Проверка в публикуемом edit:** модуль `ProkatPlayStore::GuardedPublishEdit`,
     prepend к `Supply::Client`. Активируется только явным вызовом
     `ProkatPlayStore.guard_publish!(track: 'production', version_code: N)` из
     `play.rb` непосредственно перед `Supply::Uploader.new.perform_upload`; для RC не
     активируется (Q3). В режиме preflight (`snapshot`) не активен.
     - `begin_edit` (после `super`, в **том же** edit, до upload): `tracks('production')`;
       каждый release должен иметь статус `completed`; иначе `raise` с фиксированным кодом
       `PLAY_PRODUCTION_TRACK_NOT_CLEAN status=<status>`. Также
       `list_edit_bundles`/`list_edit_apks` этого edit не должны содержать `N`.
     - `update_track(track_name, track_object)` (до `super`, тот же edit): повторное
       чтение `tracks(track_name)` с тем же правилом; `track_object.releases` должен
       состоять ровно из одного release со статусом `completed` и `version_codes == [N]`.
       Иначе `raise` до `update_edit_track`.
     - Повторное включение защиты в одном процессе или вызов `begin_edit` второй раз
       при активной защите → `raise`.
     - Обоснование: по контракту Edits Google этот edit — снимок состояния на момент
       `insert`; изменение в Console или чужой commit после этого инвалидирует edit, и
       commit падает без эффекта. Значит, проверка внутри публикуемого edit плюс
       атомарный commit закрывают окно между проверкой и фиксацией. Отдельный preflight
       edit (`snapshot`) остаётся ранней проверкой до сборки, но не единственной.
   - `play.rb`: при `Google::Apis::ClientError` с HTTP 400 и причиной
     `CHANGES_ALREADY_IN_REVIEW` печатать
     `PLAY_CHANGES_IN_REVIEW: commit refused, edit not committed; inspect Play Console before any retry`.
     При ошибке commit из-за инвалидированного edit — общий `BLOCKED … state UNKNOWN`.
     Тела ответов не печатать.
   - `PlayPolicy.check!` (ранний preflight до сборки): при `channel == 'production'` то же
     правило статусов track `production`. Для RC правило не применяется.
   - `verify_android.dart`: вынести чистую функцию
     `void requireTargetSdk(String dumped, {int minimum = 36})` (trim, `int.tryParse`, `≥ minimum`).
     Вызвать bundletool
     `dump manifest --bundle=… --xpath=/manifest/uses-sdk/@android:targetSdkVersion`.
     Сообщение успеха дополнить `targetSdk`.
7. **Инструкция исполнителю.** Prompt E2.
8. **Effort / Context.** High / файлы этапа, fastlane `supply/lib/supply/{client,uploader}.rb`
   версии 2.241.0, документы Edits и edits.commit, раздел 5.
9. **Тесты.**
   - `sdk_contract_test.rb`: keyword присутствует; `ErrorIfInReview` в `ancestors`;
     `commit_edit` на экземпляре сервиса с подменённым `execute_or_queue_command` даёт
     `command.query['changesInReviewBehavior'] == 'ERROR_IF_IN_REVIEW'`, даже если
     вызывающий передал `CANCEL_IN_REVIEW_AND_SUBMIT`; `Supply::Client` содержит
     `begin_edit`, `tracks`, `update_track` с ожидаемой арностью; `GuardedPublishEdit` в `ancestors`.
   - `play_store_test.rb`, fake-клиент без сети:
     - **TOCTOU:** preflight-снапшот (отдельный edit) видит только `completed` → policy OK;
       затем в публикуемом edit `tracks('production')` возвращает `draft` → `raise` в
       `begin_edit`; upload bundle, `update_edit_track`, `commit_edit` не вызывались;
     - публикуемый edit чистый при `begin_edit`, но при `update_track` чтение возвращает
       `inProgress` (изменилось в том же сценарии) → `raise`; `update_edit_track` и
       `commit_edit` не вызывались;
     - `halted`, `statusUnspecified`, неизвестный статус → `raise`;
     - `N` уже есть в bundles публикуемого edit → `raise` до upload;
     - `track_object` с двумя releases или с другим кодом → `raise`;
     - защита не активирована (RC) → вызовы проходят без дополнительных чтений;
     - commit фейкового «инвалидированного» edit бросает ошибку → печатается `UNKNOWN`,
       `PLAY_EDIT_COMMITTED` не печатается.
   - `play_policy_test.rb`: production + track `production` с `draft`/`inProgress`/
     `halted`/`statusUnspecified`/`weird` → blocked; только `completed` → OK;
     RC при production `draft` → OK; прежние случаи без изменений.
   - `verify_android_test.dart`: `36`, `37`, `" 36\n"` → OK; `35`, `""`, `abc`, `-1` → BLOCK.
   - Полный Dart, Python, Ruby наборы.
10. **Приёмка.**
    - [ ] Без keyword в SDK загрузка `play_store.rb` падает.
    - [ ] Любой `commit_edit` отправляет `ERROR_IF_IN_REVIEW`.
    - [ ] Статусы track `production` проверяются **в публикуемом edit** (в `begin_edit`
      до upload и в `update_track` до записи), а не только в preflight-edit.
    - [ ] Тест изменения состояния между preflight и публикацией проходит.
    - [ ] AAB с target < 36 не доходит до `play.rb publish`.
    - [ ] Android workflow запускает все три Ruby-теста.
    - [ ] RC: track `internal`, `completed`, защита публикуемого edit не активна.
11. **Негативные сценарии.** SDK без параметра; вызывающий передаёт другой behavior;
    `CHANGES_ALREADY_IN_REVIEW`; draft появился после preflight; неизвестный статус
    release; код уже в bundles; лишний release в `track_object`; target 35; пустой
    вывод bundletool; инвалидированный edit на commit.
12. **Регрессии RC.** Если Q2 = «да», RC с открытым review теперь падает
    `PLAY_CHANGES_IN_REVIEW`, а не отменяет его. Это ожидаемо и отражается в runbook на этапе 5.
    Прочее поведение RC не меняется: проверяется тестами `rc` в `play_policy_test.rb` и
    тестом «защита не активирована» в `play_store_test.rb`.
13. **Риски и откат.** Prepend в чужой gem: при обновлении fastlane или google-apis
    контракт-тест обязан упасть. Edit, не прошедший commit, Play удаляет сам; после
    `PUBLISHER_INVOKED` исход всё равно UNKNOWN до проверки консоли. Откат — `git revert`.
    STOP, если Ruby-тесты нельзя запустить.
14. **Владелец.** Решения Q2, Q3. Live-проверки Play не выполняются.
15. **Аудит.** Diff; вывод трёх Ruby-тестов; новый Dart-тест; grep: `commit_edit` нигде
    не вызывается в обход сервиса; защита активируется только в публикующей ветке
    `play.rb`; Gemfile.lock не менялся.

---

## 9. Этап 3 — iOS: preflight и защита выбора версии и submission в издателе

1. **Цель.** Ни preflight, ни издатель не могут переименовать чужую версию, изменить
   версию в ревью или подтвердить чужой submission — в том числе если состояние
   изменилось после preflight. UNKNOWN останавливает прогон.
2. **Проблемы.** P-07, P-08, P-19.
3. **Зависимости.** Этап 1 принят (этап 2 не обязателен).
4. **Границы.**
   - Можно: `tool/release/ios_store.py` (production-путь `preflight`/`main`, коды и стадии),
     новый чистый модуль `tool/release/apple_review_policy.py` (только stdlib, без сети),
     `tool/release/apple_publish.py` (установка защит, версия-guard),
     `tool/release/ios_store_test.py`, `tool/release/apple_publish_test.py`, новый
     `tool/release/apple_review_policy_test.py`; `tool/release/apple_diagnostic.py` —
     **только** если требуется синхронизация allowlist кодов.
   - Нельзя: RC-ветки `publish_arguments` и `checked_publish_arguments`,
     `confirm_testflight_distribution`, argv production, `codemagic.yaml`,
     `requirements*.txt`, версию Codemagic CLI, POST/PATCH/DELETE в собственном HTTP-клиенте
     `ios_store.py`, маркер `PUBLISHER_INVOKED` (этап 4).
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
   | Последовательность мутаций CLI | `_ensure_app_store_version` → (phased release не трогается) → локализации → `_create_review_submission` → `create_review_submission_item` → `confirm_review_submission` | `SubmitToAppStoreAction._submit_to_app_store` | ПОДТВЕРЖДЕНО |
   | Review submission в CLI | `POST /v1/reviewSubmissions`; при ошибке «another reviewSubmissions with id … still in progress» — `read` этого id и дальнейшее использование | `_create_review_submission`, `ReviewSubmissions.create/read` | ПОДТВЕРЖДЕНО |
   | Где определены item и confirm | `ReviewSubmissionItemsActionGroup.create_review_submission_item`, `ReviewSubmissionsActionGroup.confirm_review_submission` (PATCH `submitted=true`); список items — `ReviewSubmissions.list_items` | `action_groups/review_submission_items_actions_group.py`, `action_groups/review_submissions_actions_group.py`, `versioning/review_submissions.py` | ПОДТВЕРЖДЕНО |
   | `AppVersionState` (актуальное поле) | 15 значений: `ACCEPTED`, `DEVELOPER_REJECTED`, `IN_REVIEW`, `INVALID_BINARY`, `METADATA_REJECTED`, `PENDING_APPLE_RELEASE`, `PENDING_DEVELOPER_RELEASE`, `PREPARE_FOR_SUBMISSION`, `PROCESSING_FOR_DISTRIBUTION`, `READY_FOR_DISTRIBUTION`, `READY_FOR_REVIEW`, `REJECTED`, `REPLACED_WITH_NEW_VERSION`, `WAITING_FOR_EXPORT_COMPLIANCE`, `WAITING_FOR_REVIEW` | OpenAPI App Store Connect 4.3.1 (`components.schemas.AppVersionState`); `codemagic.apple.resources.enums.AppVersionState` 0.70.0 — совпадают | ПОДТВЕРЖДЕНО |
   | `AppStoreVersionState` (`appStoreState`, deprecated с API 3.3) | 20 значений: `ACCEPTED`, `DEVELOPER_REMOVED_FROM_SALE`, `DEVELOPER_REJECTED`, `IN_REVIEW`, `INVALID_BINARY`, `METADATA_REJECTED`, `PENDING_APPLE_RELEASE`, `PENDING_CONTRACT`, `PENDING_DEVELOPER_RELEASE`, `PREPARE_FOR_SUBMISSION`, `PREORDER_READY_FOR_SALE`, `PROCESSING_FOR_APP_STORE`, `READY_FOR_REVIEW`, `READY_FOR_SALE`, `REJECTED`, `REMOVED_FROM_SALE`, `WAITING_FOR_EXPORT_COMPLIANCE`, `WAITING_FOR_REVIEW`, `REPLACED_WITH_NEW_VERSION`, `NOT_APPLICABLE` | OpenAPI 4.3.1 `AppStoreVersionState`. В enum CLI 0.70.0 нет `ACCEPTED`, `READY_FOR_REVIEW`, `NOT_APPLICABLE` | ПОДТВЕРЖДЕНО |
   | Редактируемые состояния CLI | `DEVELOPER_REJECTED`, `INVALID_BINARY`, `METADATA_REJECTED`, `PREPARE_FOR_SUBMISSION`, `REJECTED`, `WAITING_FOR_REVIEW` (по `appStoreState`) | `AppStoreState.editable_states()` 0.70.0 | ПОДТВЕРЖДЕНО |
   | `ReviewSubmission.state` | 7 значений: `READY_FOR_REVIEW`, `WAITING_FOR_REVIEW`, `IN_REVIEW`, `UNRESOLVED_ISSUES`, `CANCELING`, `COMPLETING`, `COMPLETE` | OpenAPI 4.3.1 `ReviewSubmission.attributes.state`; `ReviewSubmissionState` 0.70.0 — совпадают | ПОДТВЕРЖДЕНО |
   | `GET /v1/reviewSubmissions` | `filter[app]` обязателен; `filter[platform]`, `filter[state]` необязательны; `limit` ≤ 200 | OpenAPI 4.3.1 | ПОДТВЕРЖДЕНО |
   | `fields[appStoreVersions]` | допускает `versionString`, `platform`, `appStoreState`, `appVersionState` | OpenAPI 4.3.1 | ПОДТВЕРЖДЕНО |
   | Сохранение `filter[...]` в `links.next` | Apple должен повторять фильтры в ссылке следующей страницы | Существующий `all_pages` уже требует этого для `/v1/builds` и `/v1/apps/{id}/buildUploads`, RC-прогоны прошли. Для двух новых endpoint не проверено | ПРЕДПОЛОЖЕНИЕ. Если фильтры пропадут, `all_pages` вернёт `APPLE_PAGINATION_FAILED` — fail closed |
   | Связь `appStoreState` ↔ `appVersionState` | Полная таблица соответствия Apple не публикует | — | НЕИЗВЕСТНО. Проверяется консистентность (R4), расхождение — блок |

   **6.2. Слой 1 — preflight в `ios_store.py` (только GET, через `all_pages`/`checked_url`).**

   - Версии: `/v1/apps/{id}/appStoreVersions?filter[platform]=IOS&fields[appStoreVersions]=versionString,platform,appStoreState,appVersionState&limit=100`.
     Без фильтра по состоянию: классификатор должен увидеть все версии, включая
     неизвестные состояния. `limit=100`, как у CLI.
   - Submissions: `/v1/reviewSubmissions?filter[app]={id}&filter[platform]=IOS&fields[reviewSubmissions]=platform,state&limit=200`.
     Без `filter[state]`: незнакомое состояние должно стать UNKNOWN, а не выпасть из выборки.
   - Пагинация: существующие гарантии `all_pages` — тот же путь и те же `filter[...]`,
     только хост Apple, без редиректов, не больше 100 страниц, без циклов и дубликатов id,
     согласованный `meta.paging.total`, общий дедлайн 90 секунд. Любое нарушение — UNKNOWN.
   - Вызов только при `context["channel"] == "production"` внутри `preflight(context)`:
     до сборки и перед upload. Этот слой — ранняя дешёвая остановка, **не** единственная защита.

   **6.3. Правила (`apple_review_policy.classify(target_version, versions, submissions)`).**
   Чистая функция, общая для обоих слоёв. Применяются по порядку, первое сработавшее
   даёт код. Возвращает также id выбранной редактируемой версии или `None`.

   | № | Условие | Код |
   | --- | --- | --- |
   | R1 | У версии нет `id`, `versionString`, `platform`, `appStoreState` или `appVersionState`; `platform ≠ IOS`; значение состояния вне списков 6.1; `versionString` не из 1–3 числовых компонентов. У submission нет `id`/`state`; `platform ≠ IOS`; `state` вне 7 значений | `APPLE_RESPONSE_INVALID` (UNKNOWN) |
   | R2 | Есть submission в `READY_FOR_REVIEW`, `WAITING_FOR_REVIEW`, `IN_REVIEW`, `UNRESOLVED_ISSUES`, `CANCELING` или `COMPLETING` (`COMPLETE` игнорируется) | `APPLE_REVIEW_SUBMISSION_OPEN` |
   | R3 | Есть версия с `appVersionState` ∈ {`WAITING_FOR_REVIEW`, `IN_REVIEW`, `READY_FOR_REVIEW`, `ACCEPTED`, `PENDING_APPLE_RELEASE`, `PENDING_DEVELOPER_RELEASE`, `PROCESSING_FOR_DISTRIBUTION`, `WAITING_FOR_EXPORT_COMPLIANCE`} | `APPLE_VERSION_IN_FLIGHT` |
   | R4 | Для какой-либо версии `appStoreState ∈ editable CLI` ≠ `appVersionState ∈ {PREPARE_FOR_SUBMISSION, DEVELOPER_REJECTED, REJECTED, METADATA_REJECTED, INVALID_BINARY}` | `APPLE_VERSION_STATE_MISMATCH` |
   | R5 | Редактируемых версий больше одной, либо одна со строкой ≠ версии тега | `APPLE_VERSION_CONFLICT` |
   | R6 | Версия в `READY_FOR_DISTRIBUTION` или `REPLACED_WITH_NEW_VERSION` со строкой ≥ версии тега (три компонента, недостающие = 0) | `APPLE_VERSION_NOT_INCREASING` |
   | R7 | Иначе | OK: «создать» (редактируемых нет) или «продолжить» с id единственной редактируемой версии |

   **6.4. Слой 2 — защита в издателе (`apple_publish.py`), в момент мутации.**

   Устанавливается только при `parsed.submit_to_app_store` (production), тем же
   способом, что существующий `strict_localizations`: замена методов на классах
   Codemagic CLI 0.70.0 до `AppStoreConnect.invoke_cli()`. Состояние сессии хранится в
   модульной структуре одного процесса: `version_id`, `submission_id`, `item_created`.
   Все отказы — `SystemExit("BLOCKED: <фиксированный код>; no further App Store mutation. Inspect build uploads; no reupload")`,
   без тел ответов.

   | Метод CLI (класс) | Замена делает | Гарантия |
   | --- | --- | --- |
   | `SubmitToAppStoreAction._ensure_app_store_version(app, build, info)` | Заново читает **все** IOS-версии через `self.api_client.apps.list_app_store_versions_data(app, resource_filter=AppStoreVersions.Filter(platform=Platform.IOS))`, пропускает их и **свежий** список submissions через `classify` с `info.version_string`. Блок → отказ до PATCH/POST. OK → **сама** выполняет ровно одну мутацию: `_update_existing_app_store_version` для одобренной версии (по id) или `create_app_store_version` при «создать»; повторно CLI не перечитывает и не выбирает. Проверяет, что результат имеет ожидаемый id (или `created`), `versionString == info.version_string`. Записывает `version_id` | Мутируется только версия, одобренная классификатором в этот же момент; переименование чужой версии и изменение версии в ревью исключены |
   | `SubmitToAppStoreAction._create_review_submission(app, platform)` | Читает submissions `self.api_client.review_submissions.list(ReviewSubmissions.Filter(app=app.id, platform=platform))`; любое не-`COMPLETE` или неизвестное состояние → отказ. Затем `review_submissions.create(platform, app)`; **любая** ошибка API → отказ (ветка переиспользования удалена). Требует `created is True`, записывает `submission_id` | Своя версия никогда не попадает в чужой submission |
   | `ReviewSubmissionItemsActionGroup.create_review_submission_item(...)` | Требует `review_submission_id == submission_id`, `app_store_version_id == version_id`, отсутствие прочих id, первый вызов. Иначе отказ до POST | Только один item, только наша версия, только наш submission |
   | `ReviewSubmissionsActionGroup.confirm_review_submission(review_submission_id, ...)` | Требует `review_submission_id == submission_id` и `item_created`; читает `review_submissions.list_items(id)` — ровно один item. Иначе отказ до PATCH. После успешного PATCH печатает `APPLE_REVIEW_SUBMISSION_CONFIRMED` | Подтверждается только собственный submission с одним элементом |

   - Version guard: перед установкой проверить, что все четыре атрибута существуют на
     указанных классах, `AppStoreConnect` разрешает их в заменённые функции, сигнатуры
     совпадают с 0.70.0 (`inspect.signature`). Иначе `PublishCliError` до `invoke_cli`.
   - Отказ слоя 2 происходит **после** upload IPA: исход UNKNOWN, IPA сохраняется в
     Codemagic Artifacts, повторный upload запрещён. Это намеренный fail closed.
   - Окно между перечитыванием в слое 2 и PATCH/POST — один сетевой обмен. App Store
     Connect API не даёт условных обновлений (ETag/версии ресурса), поэтому окно нельзя
     закрыть полностью; отвергнет ли Apple PATCH версии, перешедшей в другое состояние
     в эти миллисекунды, не проверено. Submission подтверждается только собственный и
     только с одним нашим item. Остаточный риск записывается в реестр.
   - Рассмотренная альтернатива — разделить upload (`publish` без `--app-store`) и
     submission отдельной командой. Отклонена: те же методы CLI вызываются в обоих
     вариантах, а замена методов даёт гарантию без изменения argv.

   **6.5. Прочее.**
   - Production закрепляет `config["app_id"] == "6817078475"` (константа без
     привязки к RC, например `APP_ID`). Код ошибки существующий: `APPLE_APP_MISMATCH`.
   - Новые коды (`APPLE_REVIEW_SUBMISSION_OPEN`, `APPLE_VERSION_IN_FLIGHT`,
     `APPLE_VERSION_STATE_MISMATCH`, `APPLE_VERSION_CONFLICT`,
     `APPLE_VERSION_NOT_INCREASING`, `APPLE_SUBMISSION_GUARD_FAILED`) и стадии
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
   - `apple_review_policy_test.py`: каждое из 15 значений `appVersionState` и 20 значений
     `appStoreState` перечислено явно с ожидаемой классификацией; значение вне списка → R1;
     каждое из 7 значений `ReviewSubmission.state`, отсутствующее и неизвестное; каждое
     правило R1–R7; порядок правил (submission открыт и версия в ревью → R2).
   - `ios_store_test.py` (слой 1): URL точно как в 6.2, только GET, без `filter[state]` и
     `filter[appStoreState]`; 401/403/429/5xx/timeout/битая пагинация/фильтр пропал в
     `next` → UNKNOWN без издателя; при любом блоке `subprocess.run` не вызывается; RC не
     запрашивает новые URL; production argv идентичен текущему; `APP_STORE_APP_ID` ≠
     `6817078475` → `APPLE_APP_MISMATCH`.
   - `apple_publish_test.py` (слой 2), fake `api_client` с журналом вызовов:
     - **TOCTOU версии:** preflight-данные пусты (слой 1 OK), а при `_ensure_app_store_version`
       список содержит версию в `WAITING_FOR_REVIEW` → отказ; `modify`/`create` версии не вызывались;
     - **TOCTOU переименования:** при `_ensure_app_store_version` появилась редактируемая
       версия с другой строкой → отказ до PATCH;
     - **TOCTOU submission:** при `_create_review_submission` список содержит `READY_FOR_REVIEW`
       → отказ до POST;
     - POST submission отвечает «another reviewSubmissions … still in progress» →
       отказ; `review_submissions.read`, `create_review_submission_item`, confirm не вызывались;
     - item с чужим `review_submission_id` или чужой версией, повторный item → отказ до POST;
     - confirm чужого id, confirm без item, `list_items` возвращает 2 → отказ до PATCH;
     - счастливый путь: ровно одна мутация версии, один POST submission, один POST item,
       один PATCH confirm, затем `APPLE_REVIEW_SUBMISSION_CONFIRMED`;
     - version guard: отсутствующий метод или изменённая сигнатура → `PublishCliError` до `invoke_cli`;
     - RC (`submit_to_app_store` ложно) — замены не устанавливаются, существующие RC-тесты не меняются.
   - Существующие 169 тестов проходят, `testflight_distribution_test.py` не изменён.
10. **Приёмка.**
    - [ ] Таблицы 6.1–6.4 реализованы; списки состояний в коде совпадают с 6.1 буквально
      и живут в одном модуле `apple_review_policy.py`.
    - [ ] Слой 2 перечитывает состояние в момент мутации, сам выполняет единственную
      мутацию версии и никогда не переиспользует чужой submission.
    - [ ] Все тесты изменения состояния после preflight проходят без вызова соответствующих мутаций.
    - [ ] Неизвестное значение любого состояния даёт блок, а не «нет версии».
    - [ ] Собственный HTTP-клиент `ios_store.py` — только GET.
    - [ ] Нет изменений RC-пути и argv.
    - [ ] Ошибки и коды не содержат тел ответов или значений env.
11. **Негативные сценарии.** Все строки R1–R6 в обоих слоях; изменения состояния
    после preflight (версия, переименование, submission); POST с переиспользованием;
    чужой item или confirm; пустой ответ на второй странице; `next` на чужой хост или
    без фильтров; дубликат ID; таймаут общего дедлайна 90 секунд; несовпадение
    сигнатур CLI.
12. **Регрессии RC.** `ios_store_test.py` RC-случаи, `testflight_distribution_test.py`,
    существующие `apple_publish_test.py`.
13. **Риски и откат.** Новые значения состояний Apple дадут UNKNOWN: fail closed, владелец
    увидит код. Отказ слоя 2 после upload оставляет загруженный IPA без submission —
    UNKNOWN, ручная обработка в ASC. Замена методов привязана к CLI 0.70.0: version guard
    обязан остановить другой CLI. Откат — `git revert`.
14. **Владелец.** Нет действий до фазы B. Live GET не выполняется.
15. **Аудит.** Diff; вывод Python-набора; построчное сопоставление 6.1–6.4 с тестами;
    grep на `method="POST"|PATCH|DELETE` в `ios_store.py` (должно быть пусто); проверка,
    что в `apple_publish.py` нет пути, где CLI выбирает версию или submission сам.

---

## 10. Этап 4 — облачное разрешение по платформам и маркер вызова издателя

1. **Цель.** Один push тега, забытый `true`, чужой тег или (для Android) re-run без
   нового разрешения не публикуют: каждый провайдер требует разрешения своей
   платформы. Лог CI однозначно показывает, вызывался ли издатель.
2. **Проблемы.** P-09, P-18.
3. **Зависимости.** Этапы 1–3 приняты. **Решения Q1 и Q8 обязательны.** Ниже описан
   рекомендуемый вариант A. При другом решении план этапа переписывается и снова
   согласуется.
4. **Границы.**
   - Можно: `tool/release/release.dart` (`validateCloudAuthorization`, вызов в `ci`),
     `tool/release/cli.dart` (guard-строки, строка облачного разрешения в preview),
     `.github/workflows/android-release.yml` (env и шаг gate), `tool/release/play.rb` и
     `tool/release/play_policy.rb` (функция авторизации, маркер), `tool/release/ios_store.py`
     (`main`), `tool/release/apple_publish.py` (только строка маркера), тесты
     `release_test.dart`, `cli_test.dart`, `config_test.py`, `ios_store_test.py`,
     `apple_publish_test.py`, `play_policy_test.rb`, `play_store_test.rb`; раздел U5 в
     `docs/ci-cd/MANUAL_SETUP.md`.
   - Нельзя: создавать или менять секреты и переменные, GitHub settings, Codemagic UI,
     триггеры workflow, RC-путь (для RC разрешение не читается и не требуется).
5. **Участки кода.** Шаг `Reject production until U5`; `validateProduction`;
   `play.rb` (строки с `PRODUCTION_PUBLISHING_ENABLED` и вызов `perform_upload`);
   `ios_store.py main`; `apple_publish.py main`; список guard в `ReleaseCli.plan`;
   `ReleaseCli.execute` (preview).
6. **Решение (вариант A).**
   - Переменные и форматы — раздел 5.4. Android сравнивает с
     `"<tag>@<commit>#<GITHUB_RUN_ATTEMPT>"`, iOS — с `"<tag>@<commit>"`, где `commit` —
     уже проверенный `GITHUB_SHA` или `CM_COMMIT`. Отсутствующий или нечисловой
     `GITHUB_RUN_ATTEMPT` → BLOCK.
   - Правило для production в CI: `PRODUCTION_PUBLISHING_ENABLED == "true"` **и**
     точное совпадение разрешения своей платформы.
   - Слои Android (каждый независимо): bash-шаг gate до установки Flutter
     (`$GITHUB_REF_NAME@$GITHUB_SHA#$GITHUB_RUN_ATTEMPT`); `release.dart ci`;
     `play.rb preflight`; `play.rb publish` (`tag`, `commit` из `build/release/context.json`,
     попытка из env).
   - Слои iOS: `release.dart ci`; `ios_store.py validate-publish`; `ios_store.py preflight`;
     `ios_store.py publish`.
   - Маркер `PUBLISHER_INVOKED` — точные места и смысл в разделе 5.5, для обоих каналов.
     Только печать, без изменения логики.
   - Preview production (dry-run и реальный запуск) печатает
     `Cloud authorization required: GitHub variable PRODUCTION_RELEASE_AUTH_ANDROID = <tag>@<sha>#1`
     или `… Codemagic variable PRODUCTION_RELEASE_AUTH_IOS = <tag>@<sha>`.
   - Guard в `ReleaseCli.plan` **только для channel `production`**: Android workflow
     обязан содержать `PRODUCTION_RELEASE_AUTH_ANDROID` и `GITHUB_RUN_ATTEMPT`; iOS
     принимается через `release.dart`, содержащий `validateCloudAuthorization` (по образцу
     текущего исключения). RC-план новые guard-строки не требует.
   - `config_test.py` закрепляет точный список входов Android
     (`test_exact_android_u2_input_inventory_and_prebuild_key_check`,
     `test_cost_artifact_and_production_contract`). Обновить их явно, добавив
     `PRODUCTION_RELEASE_AUTH_ANDROID`, а не ослаблять проверку.
   - `MANUAL_SETUP.md`, раздел U5: фазы C, D, R и правила 5.4–5.6.
7. **Инструкция исполнителю.** Prompt E4.
8. **Effort / Context.** High / все файлы этапа, разделы 5.4–5.6, текущие тесты gate.
9. **Тесты.**
   - `release_test.dart` (`validateCloudAuthorization`): матрица
     `enabled ∈ {absent,'true','TRUE','false'}` × разрешение ∈ {absent, exact, тот же тег
     с другим SHA, другой тег с тем же SHA, exact+' ', ' '+exact, exact в верхнем
     регистре, значение для другой платформы, rc-тег}; для Android дополнительно
     `attempt ∈ {1, 2, absent, 'x'}` × суффикс ∈ {`#1`, `#2`, без суффикса}. Пропускает
     только (`'true'`, exact, совпавшая попытка). RC — функция не вызывается.
   - Тест «разрешение не расходуется»: одинаковые входы дважды дают одинаковый результат;
     для Android попытка `2` при значении `#1` — BLOCK. Это фиксирует, что защита от
     повтора — номер попытки (Android), процедура 5.5–5.6 и store-preflight, а не gate.
   - `config_test.py`: gate-шаг в `android-release.yml` идёт до `Install pinned Flutter`,
     ссылается на `vars.PRODUCTION_RELEASE_AUTH_ANDROID`, `github.ref_name`, `github.sha`,
     `github.run_attempt`; шаги `play.rb` получают переменную; ни один шаг не записывает
     `vars`/`secrets`.
   - `ios_store_test.py`: production без точного совпадения → блок до API и издателя
     для `validate-publish`, `preflight`, `publish`; RC без переменной работает как раньше.
   - `apple_publish_test.py` и `play_store_test.rb`: `PUBLISHER_INVOKED` печатается после всех
     проверок и непосредственно перед вызовом издателя (`invoke_cli`/`perform_upload`, через
     подмену); при блоке до этого места не печатается; успешная валидация argv
     (`validate-publish`) его не печатает.
   - `cli_test.dart`: production-guard отсутствует → BLOCK; RC без guard → OK;
     preview содержит строку облачного разрешения с точным значением.
10. **Приёмка.**
    - [ ] Четыре слоя Android и четыре слоя iOS проверяют разрешение своей платформы независимо.
    - [ ] Android-разрешение привязано к номеру попытки; re-run без нового значения блокируется.
    - [ ] `PUBLISHER_INVOKED` стоит строго перед вызовом издателя в обоих каналах и не
      утверждает, что мутация произошла.
    - [ ] RC не читает новые переменные.
    - [ ] Секреты и переменные не создавались.
    - [ ] MANUAL_SETUP U5 описывает выставление, очистку, путь повтора и остаточный риск iOS.
11. **Негативные сценарии.** Boolean `true`, разрешение другого тега; тот же тег на
    другом SHA; разрешение `true`, boolean `false`; пробел в значении; значение iOS в
    Android-переменной; RC-тег в переменной; re-run Android с прежним `#n`; re-run после
    очистки переменной.
12. **Регрессии RC.** Все RC-тесты; `config_test.py` на неизменность RC-триггеров; лог RC
    получает только строку `PUBLISHER_INVOKED`.
13. **Риски и откат.** iOS: пока разрешение не очищено, rebuild того же тега проходит
    gate (Q8). Риск write-доступа к секретам кодом не снимается. Откат — `git revert`.
14. **Владелец.** Q1, Q8; OC-A2 (тариф, rulesets, collaborators). При возможности —
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
     PowerShell-тесты на Linux пропускаются явно; они обязательны локально на Windows.
   - Документы описывают: классы Git-операций (раздел 1); таблицу и свежесть 5.3;
     правило номеров 5.2; облачное разрешение и его границы 5.4; маркеры и
     классификацию 5.5; два пути запуска 5.6; Play `ERROR_IF_IN_REVIEW`, проверку track в
     публикуемом edit и «Changes ready to send for review» (P-21); оба слоя iOS этапа 3;
     порядок фаз раздела 15; RC `+19` и `+24` как неизменяемую историю.
   - `PRODUCTION_READINESS.md`: чек-лист раздела 15 с PASS/FAIL по каждому пункту.
6. **Инструкция исполнителю.** Prompt E5.
7. **Effort / Context.** Medium / список документов, этот план, итоговый код этапов 1–4.
8. **Тесты.** Весь Dart, Python и Ruby; `cli_docs_test.py` (ссылки, отсутствие ручных
   команд тегов); `actionlint`, если доступен локально, иначе отметить NOT RUN.
9. **Приёмка.**
    - [ ] Job не ссылается на `secrets`, не имеет `write`-прав.
    - [ ] Ни один текущий гайд не содержит ручного создания тегов или force-операций.
    - [ ] Пример следующего номера — без конкретного «безопасного» значения, только правило.
    - [ ] Нигде не сказано, что разрешение одноразовое или само исключает повтор;
      остаточный риск iOS (Q8) записан.
    - [ ] Повтор существующего тега описан только как путь 5.6, не через `prokat-prod-*`.
    - [ ] Все команды, переменные, маркеры и коды в документах существуют в коде.
10. **Негативные сценарии.** Сломанная ссылка; устаревший номер; job, зависящий от сети магазинов.
11. **Регрессии RC.** RC-разделы гайдов не меняют смысл, только номера и ссылки.
12. **Риски и откат.** Расход минут (Q7). Откат — `git revert`.
13. **Владелец.** Q7.
14. **Аудит.** Diff документов против кода (grep команд, переменных, маркеров и кодов ошибок).

---

## 12. Этап 6 — репетиция без публикации и готовность

1. **Цель.** Доказать, что ни один путь не публикует без явного разрешения, и
   подготовить первый Production к решению владельца.
2. **Зависимости.** Этапы 1–5 приняты.
3. **Границы.** Без изменений кода, кроме исправлений, найденных репетицией. Они
   идут отдельным согласованным этапом. Никаких тегов, gate, секретов, переменных,
   store-запросов агентом. Локальный env `PRODUCTION_PUBLISHING_ENABLED` агент не
   выставляет. Разрешён один G2 в начале: `git fetch origin main`.
4. **Шаги агента.** Записать `git rev-parse refs/remotes/origin/main` и
   `git ls-remote origin refs/heads/main`; выполнить `git fetch origin main`; записать
   снова. Ветка, CLI из ветки, `origin/main` = `07926a7d` (или текущий, если владелец уже
   что-то слил — тогда ожидания пересчитываются и согласуются заново).

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
   - Устаревший tracking-ref доказывается тестами этапа 1; в репетиции не воспроизводится.
   - До и после команд: `git show-ref --tags`, `git ls-remote --tags origin`,
     `git rev-parse refs/remotes/origin/main`, `git status --short` — без изменений.
   - Отчёт `PRODUCTION_READINESS.md` с фактическими результатами.
5. **Шаги владельца.** Фазы B–E и R раздела 15, каждая после отдельного решения.
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
> Запрещено: G2–G4 вне указанного, push, merge, теги, изменения секретов, переменных и
> консолей магазинов, вызовы реальных API Google и Apple, выставление
> `PRODUCTION_PUBLISHING_ENABLED`, `git reset --hard`, `git clean`, правки вне границ
> этапа, изменения RC-поведения сверх описанного. Если план противоречит коду или тест
> требует credentials — остановись и опиши проблему. В конце: команды и фактический
> вывод, diff-статистика, список негативных сценариев с тестами, один коммит этапа без push.

**E1 (Effort Medium, Context: этап 1 + разделы 1, 4, 5.2, 5.3).**
Локально удали пять untracked-файлов раздела 4 через `Remove-Item -LiteralPath`
(не `git rm`, не `git clean`), предварительно проверив `git ls-files` (должны
отсутствовать) и `git grep` (нет ссылок); приложи `git status --short` до и после.
Реализуй таблицы и шаги свежести раздела 5.3 в `main()`, `ReleaseCli.plan`,
`ReleaseCli.execute` и `ReleasePlan`, канал в `validateBuildHistory`/`validateStores`
и тесты пункта 9: учёт **всех** вызовов git, устаревший и отсутствующий tracking-ref,
отказ без git и для Dart CLI, и для `prokat-prod-android`/`prokat-prod-ios` в окружении
без git. Не трогай YAML, Ruby, Python-код, `prokat-release.ps1` и `CICD-README.md`.
Не обновляй tracking-ref. Покажи вывод трёх команд пункта 15 и состояние тегов и refs
до и после.

**E2 (Effort High, Context: этап 2 + fastlane 2.241.0 `supply/client.rb`, `uploader.rb`, документы Google Edits и edits.commit).**
Реализуй prepend `ERROR_IF_IN_REVIEW` с fail-closed проверкой сигнатуры, защиту
публикуемого edit (`GuardedPublishEdit` в `begin_edit` и `update_track`, активируется
только из публикующей ветки `play.rb` для production), правило track в
`PlayPolicy.check!` для раннего preflight, классификацию `CHANGES_ALREADY_IN_REVIEW`,
`requireTargetSdk` и тест к нему, два bundle-теста в Android workflow. Обязательно тест,
где preflight-edit чистый, а публикуемый edit содержит `draft`. Не меняй `Gemfile.lock`,
track RC, `release_status`, gate и маркеры. Ruby-тесты запускай только командой
раздела 6. Если Docker недоступен — STOP, этап не сдаётся.

**E3 (Effort High, Context: этап 3 целиком, особенно 6.1–6.4; исходники cli-tools v0.70.0 из пункта 8).**
Создай `apple_review_policy.py` с константами буквально по 6.1 и функцией `classify`
(R1–R7 по порядку). Добавь в `ios_store.py` GET-only слой 1 строго с URL из 6.2 и
закрепление app ID. В `apple_publish.py` установи для production замены четырёх методов
из таблицы 6.4 с version guard; переиспользование чужого submission удали полностью.
Не добавляй `filter[state]`/`filter[appStoreState]`. Не меняй RC, argv, `all_pages`.
Обязательны fake-тесты изменения состояния после preflight для версии, переименования
и submission; в негативных тестах соответствующие мутации не вызываются. Если метод
CLI 0.70.0 не совпадает с описанием — STOP и опиши, не подбирай обходной путь.

**E4 (Effort High, Context: этап 4 + разделы 5.4–5.6; только после записанных решений Q1 и Q8).**
Реализуй `validateCloudAuthorization` с форматами раздела 5.4 (Android с номером
попытки), во всех слоях таблицы этапа 4, маркер `PUBLISHER_INVOKED` строго в местах
5.5, строку облачного разрешения в preview и тесты-матрицы, включая «разрешение не
расходуется» и re-run Android с прежним `#n`. Ни одного `gh secret`/`gh variable`, ни
одной правки настроек. RC новые переменные не читает. Не пиши в документах и
комментариях, что разрешение одноразовое или что маркер доказывает мутацию.

**E5 (Effort Medium, Context: этап 5 + разделы 1, 5 и 15 + итоговый код).**
Добавь job `release-tooling` без секретов и обнови документы по списку. Порядок
действий владельца бери только из раздела 15, правила повтора и классификации — только
из 5.5–5.6. Каждое утверждение документа сверяй с кодом через grep и ссылайся на файл.

**Аудитор (read-only, Effort Medium, Context: diff этапа + план).**
Проверь diff этапа против границ и приёмки, запусти тесты раздела 6, перечисли
расхождения. Ничего не меняй.

---

## 14. Решения владельца

| ID | Вопрос | Рекомендация | Нужно до |
| --- | --- | --- | --- |
| Q1 | Модель облачного разрешения | A: boolean + переменная своей платформы (5.4; Android с номером попытки). Альтернативы: оставить только boolean; GitHub Environment с required reviewers (по документации GitHub для private repo требуется Enterprise — подтвердить в OC-A2; у Codemagic аналога нет) | этапа 4 |
| Q2 | `ERROR_IF_IN_REVIEW` и для RC | Да: иначе RC-коммит может отменить production review | этапа 2 |
| Q3 | Production track с `draft`/`inProgress`/`halted` блокирует publish | Да; RC не затрагивается | этапа 2 |
| Q4 | `AFTER_APPROVAL` или `MANUAL`; phased release | Оставить `AFTER_APPROVAL` и дефолт приложения | OC-C1 |
| Q5 | Версия и номер первого Production | `X.Y.Z` > последней версии App Store в `READY_FOR_DISTRIBUTION`/`REPLACED_WITH_NEW_VERSION`; `N` > 24, > max Play, > max Apple (включая Build Uploads) | OC-B3 |
| Q6 | Локальная очистка пяти promotion-файлов на этапе 1 | Да (владелец разрешил); копия — по желанию владельца | этапа 1 |
| Q7 | Job release-tooling в каждом PR | Да; оценить минуты Actions приватного репозитория | этапа 5 |
| Q8 | Остаточный риск повтора iOS при активной `PRODUCTION_RELEASE_AUTH_IOS` | Принять риск с мерами 5.4–5.6: concurrency 1, очистка сразу после конечного состояния (OC-D6/OC-R6), store-уникальность номера, защита submission этапа 3; повтор iOS только путём 5.6 и только при подтверждённом в OC-A4 сохранении `CM_TAG`. Альтернативы: (b) запретить любой повтор iOS — только новый номер; (c) добавить в CI запрос к Codemagic API о других сборках того же тега — требует нового секрета API Codemagic с полными правами, не рекомендуется | этапа 4 и U5 (OC-C2) |

---

## 15. Ручные checkpoints владельца

Агент их не выполняет. Значения секретов в чат не передаются. Фазы идут строго по
порядку; внутри фазы — сверху вниз. FAIL любого пункта останавливает следующую фазу.
Фаза R выполняется только вместо повторного прохождения фазы D, когда исход D — NOT_INVOKED.

### Фаза A — до и во время реализации (ничего не включается)

| ID | Действие | PASS | FAIL / STOP |
| --- | --- | --- | --- |
| OC-A1 | Записать решения Q1–Q8 до этапов и checkpoints из колонки «Нужно до» | Решение записано | Зависящий этап или checkpoint не стартует |
| OC-A2 | GitHub: тариф организации, видимость репозитория, Settings → Rules (rulesets), Environments, список людей с write/admin | Записано; write только у доверенных; при доступности создан tag ruleset (раздел 5.4) | Неизвестные writers → сначала ограничить доступ |
| OC-A3 | GitHub → Settings → Secrets and variables → Actions: имена RC-секретов и переменных (`ANDROID_*`, `PLAY_SERVICE_ACCOUNT_JSON_BASE64`, `GOOGLE_SERVICES_JSON_BASE64`, `MAPBOX_PUBLIC_TOKEN`, `ANDROID_UPLOAD_CERT_SHA256`, `PLAY_HISTORICAL_MAX_BUILD`) | Все есть; `PRODUCTION_PUBLISHING_ENABLED` отсутствует или `false`; `PRODUCTION_RELEASE_AUTH_ANDROID` отсутствует или пуста | Чего-то нет, или gate уже `true` → STOP |
| OC-A4 | Codemagic: `ios-production` виден; группа `prokat-ios-release` содержит `APP_STORE_APP_ID=6817078475`, `IOS_HISTORICAL_MAX_BUILD`, PEM, plist; integration `prokat-app-store`; signing `app_store`; concurrency 1; кто может менять группу и запускать сборки; **сохраняет ли «Rebuild» сборки тега исходные `CM_TAG` и `CM_COMMIT`** (документация или история сборок) | Совпадает; gate и `PRODUCTION_RELEASE_AUTH_IOS` отсутствуют; ответ про rebuild записан (да/нет/неизвестно) | Нет distribution identity → STOP. Rebuild без `CM_TAG` или «неизвестно» → повтор iOS путём 5.6 запрещён |

### Фаза B — подготовка версии (после принятия этапов 1–6)

| ID | Действие | PASS | FAIL / STOP |
| --- | --- | --- | --- |
| OC-B1 | Play: в Console (или `play_access.rb` по отдельному GO — **создаёт и удаляет temporary edit**) записать максимум versionCode (включая drafts), статусы `production`/`internal`, primary locale, Managed publishing, наличие production access, очередь review, раздел Publishing overview «Changes ready to send for review» | Записано; production track без чужих draft/inProgress/halted; production access есть | Abort edit не подтверждён; нет production access → STOP |
| OC-B2 | App Store Connect: максимум build и Build Uploads; список App Store versions и их состояния; review submissions; скриншоты, privacy, age rating, контакт ревьюера, export compliance | По правилам R2–R6 этапа 3 ничего не блокирует; метаданные заполнены | Есть in-flight версия или открытый submission → разрешить вручную, повторить OC-B2 |
| OC-B3 | Выбрать `X.Y.Z+N` по Q5 на основе OC-B1 и OC-B2; подготовить notes | Записано | — |
| OC-B4 | PR ветки в `dev`; затем bump и notes в `dev`; затем PR `dev` → `main` после `git diff --stat origin/main origin/dev`; после merge — `sync-dev` | Только ожидаемые файлы | Неожиданные файлы → STOP |
| OC-B5 | `git fetch origin main`; затем `prokat-prod-android -DryRun` и `prokat-prod-ios -DryRun` на новом `main`, без env | План построен; тег без `rc/`; номер из OC-B3; SHA = `origin/main`; `Production gate (local): DISABLED`; строки облачного разрешения записаны | Любое иное → STOP |

### Фаза C — U5: однократная активация

| ID | Действие | PASS | FAIL / STOP |
| --- | --- | --- | --- |
| OC-C1 | Решения Q4 и о Managed publishing приняты; Play service account получает app permission **Release to production** | Права выданы | — |
| OC-C2 | Q8 записан. GitHub Secret `PRODUCTION_PUBLISHING_ENABLED=true`; Codemagic group secret `PRODUCTION_PUBLISHING_ENABLED=true` | Оба выставлены | Q8 не записан → STOP |
| OC-C3 | Проверить, что `PRODUCTION_RELEASE_AUTH_ANDROID` и `PRODUCTION_RELEASE_AUTH_IOS` пусты | Пусты: после U5 ни один тег всё ещё не публикуется | Не пусты → очистить, STOP |

### Фаза D — первый релиз тега одной платформы (повторяется отдельно для Android и для iOS)

Платформы выпускаются по очереди, никогда одновременно. Вторая платформа начинает
фазу D только после того, как первая прошла OC-D7.

| ID | Действие | PASS | FAIL / STOP |
| --- | --- | --- | --- |
| OC-D1 | Свежая проверка магазина этой платформы (как OC-B1 или OC-B2). Для Android дополнительно: «Changes ready to send for review» пуст — commit отправит их вместе с релизом (P-21) | Номер свободен, чужих review, releases и неотправленных изменений нет | Иначе STOP |
| OC-D2 | `git fetch origin main`; `prokat-prod-<platform> -DryRun`: тот же номер и тот же SHA, что в OC-B5 (для второй платформы — пара того же канала и SHA) | Совпадает; строка облачного разрешения записана | `main` сдвинулся → вернуться к OC-B3/OC-B5 |
| OC-D3 | Выставить **только** переменную этой платформы равной строке из OC-D2 (Android — с `#1`). Переменная другой платформы пуста | Выставлено ровно одно значение | — |
| OC-D4 | В новой PowerShell-сессии: `$env:PRODUCTION_PUBLISHING_ENABLED='true'`, затем `prokat-prod-<platform>`, `y`, `PUBLISH PRODUCTION`; сразу после — `Remove-Item Env:PRODUCTION_PUBLISHING_ENABLED` | Тег отправлен, CLI напечатал SHA | Ошибка push → инструкция CLI; разрешение очистить (OC-D6) |
| OC-D5 | Наблюдать прогон провайдера до конечного состояния | Конечное состояние достигнуто | — |
| OC-D6 | **Сразу** очистить переменную этой платформы, до разбора результата | Пусто | — |
| OC-D7 | Классифицировать исход по таблице 5.5 и проверить магазин | SUBMITTED подтверждён в консоли | NOT_INVOKED → фаза R или новый номер; UNKNOWN → только ручное восстановление или новый номер (фаза D заново) |

### Фаза R — повтор существующего тега (только после NOT_INVOKED)

| ID | Действие | PASS | FAIL / STOP |
| --- | --- | --- | --- |
| OC-R1 | Убедиться по полному логу прогона, что `PUBLISHER_INVOKED` отсутствует | Подтверждено | Строка есть или лог неполный → это UNKNOWN, фаза R запрещена |
| OC-R2 | `git ls-remote origin "refs/tags/<tag>" "refs/tags/<tag>^{}"` | Тег существует, peeled SHA = SHA разрешения | Иначе STOP |
| OC-R3 | Свежая проверка магазина (как OC-D1) | Номер свободен | Номер виден → STOP, это не NOT_INVOKED-ситуация |
| OC-R4 | Android: `PRODUCTION_RELEASE_AUTH_ANDROID=<tag>@<sha>#<последняя попытка run + 1>`. iOS (только если OC-A4 = «да» и Q8 разрешает): `PRODUCTION_RELEASE_AUTH_IOS=<tag>@<sha>` | Выставлено одно значение | — |
| OC-R5 | Android: исходный run → «Re-run all jobs». iOS: исходная сборка → «Rebuild». CLI не используется | Новый прогон стартовал; в его логе тот же тег и SHA (iOS — `CM_TAG`) | Иначе OC-R6 и STOP |
| OC-R6 | Сразу после конечного состояния очистить переменную; классифицировать по 5.5 | Как OC-D6–OC-D7 | — |

### Фаза E — после релиза и аварийная остановка

| ID | Действие | PASS |
| --- | --- | --- |
| OC-E1 | Обе переменные `PRODUCTION_RELEASE_AUTH_*` пусты; локальный env снят | Да |
| OC-E2 | Аварийная остановка в любой момент: `PRODUCTION_PUBLISHING_ENABLED=false` у провайдера. Начатый прогон и уже отправленный review проверяются отдельно в консоли | Документировано в runbook |

### Production-readiness (итог этапа 6)

- [ ] Этапы 1–5 приняты отдельными аудитами.
- [ ] Production DryRun строит план без gate, только при `refs/remotes/origin/main == ls-remote`,
      не делает `fetch` и не пишет refs.
- [ ] Реальный production без gate отказывает до первой git-команды — и через Dart CLI,
      и через `prokat-prod-android`/`prokat-prod-ios`.
- [ ] RC и Production не делят номер; CLI не повторяет существующий тег (тесты).
- [ ] Play: `ERROR_IF_IN_REVIEW`; проверка track в публикуемом edit с тестом TOCTOU; targetSdk ≥ 36.
- [ ] iOS: слой 1 (GET-preflight) и слой 2 (защита выбора версии и submission в
      издателе) с тестами изменения состояния после preflight; все значения 6.1 покрыты;
      неизвестное значение блокирует.
- [ ] Облако требует разрешения своей платформы (Android — с номером попытки), или иное
      записанное решение Q1; Q8 записан.
- [ ] `PUBLISHER_INVOKED` есть в обоих адаптерах; runbook классифицирует исходы по 5.5 и
      описывает фазу R; повтор после UNKNOWN запрещён.
- [ ] Документация не утверждает, что разрешение одноразовое; порядок очистки описан.
- [ ] PR прогоняет Dart, Python, Ruby release-тесты.
- [ ] Документация совпадает с кодом; в diff нет promotion-кода.
- [ ] Фаза A пройдена; фазы B–E и R описаны в runbook и готовы к исполнению владельцем.

---

## 16. Реестр рисков

| Риск | Вероятность / влияние | Мера |
| --- | --- | --- |
| Commit Play отменяет чужой review | Средняя / высокое | Этап 2 (`ERROR_IF_IN_REVIEW`) |
| Publish вытесняет production draft/staged rollout, в том числе появившийся после preflight | Низкая / высокое | Этап 2: проверка в публикуемом edit; инвалидация edit Google при изменениях в Console |
| Commit отправляет на ревью «готовые к отправке» изменения из Console | Средняя / среднее | OC-D1 (ручная проверка; API её не видит) |
| CLI 0.70.0 переименовывает или меняет версию в ревью; подтверждает чужой submission | Средняя / высокое | Этап 3, слои 1 и 2 |
| Состояние App Store меняется после preflight (до ~30 минут) | Средняя / высокое | Этап 3, слой 2 перечитывает в момент мутации; остаётся окно одного сетевого обмена без условного обновления в API (остаточный, низкая вероятность) |
| Отказ слоя 2 после upload | Низкая / среднее | UNKNOWN, IPA в Artifacts, ручная обработка; без reupload |
| Apple перестаёт возвращать deprecated `appStoreState` или повторять фильтры в `links.next` | Низкая / среднее | R1 и `all_pages` блокируют (fail closed); отдельное решение до релиза |
| Обновление Codemagic CLI меняет заменённые методы | Низкая / высокое | Version guard этапа 3; версия CLI закреплена |
| Случайный production-тег при включённом boolean | Средняя / высокое | Этап 4: нужно разрешение своей платформы |
| Re-run Android при активном разрешении | Низкая / среднее | Номер попытки в разрешении; OC-D6 |
| **Rebuild iOS при активном разрешении** | Средняя / среднее | **Остаточный, явно принимается или запрещается решением Q8 до U5**; очистка сразу (OC-D6/OC-R6); concurrency 1; store-уникальность номера; защита submission |
| Владелец забыл очистить разрешение | Средняя / среднее | OC-E1; другие теги и (Android) другие попытки не совпадут; iOS — строка выше |
| Тег с ожидаемым именем создан кем-то другим | Низкая / среднее | SHA в разрешении; ruleset при доступности (OC-A2) |
| Writer с доступом к репозиторию читает секреты или меняет workflow | Низкая / критическое | OC-A2: ограничить write, rulesets, environments по тарифу |
| UNKNOWN после вызова издателя (таймаут, сеть, отмена) | Средняя / среднее | Повтор прежнего тега запрещён; разбор в консоли; новый номер |
| Upload начался, а магазин ещё не показывает номер | Низкая / высокое | Store-preflight этого не гарантирует → после UNKNOWN повтор запрещён процедурно; дубликат номера магазин отвергнет |
| Маркер ошибочно принят за доказательство мутации или публикации | Средняя / среднее | Семантика 5.5; документация этапа 5 |
| DryRun на устаревшем локальном `origin/main` | Средняя / низкое | Этап 1: сравнение с `ls-remote`, fail closed |
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
- [ ] Классы Git-операций G0–G4 используются единообразно в этапах, prompts и checkpoints.
- [ ] Каждая проблема раздела 3 (P-01…P-22) воспроизводится по указанным функциям и источникам.
- [ ] Раздел 4: пять путей untracked, без ссылок, в истории отсутствуют; очистка описана
      как локальная, не как Git-удаление; в этапе 0 файлы не удалены.
- [ ] Правило 5.2 закрывает: RC↔Production, частичную пару, повтор через CLI, другой SHA, другую версию.
- [ ] Таблица 5.3 однозначна: где проверяется gate (включая PowerShell), свежесть
      tracking-ref в DryRun, какие операции до отказа разрешены, что запрещено всегда.
- [ ] 5.4 нигде не называет разрешение одноразовым; Android привязан к номеру попытки;
      остаточный риск iOS и решение Q8 записаны.
- [ ] 5.5: `PUBLISHER_INVOKED` означает «издатель вызван», не «мутация произошла»;
      валидация не считается публикацией; SUBMITTED подтверждается только двумя маркерами.
- [ ] 5.6 и фаза R: повтор существующего тега идёт через провайдера, не через CLI;
      только после NOT_INVOKED; UNKNOWN — повтор запрещён.
- [ ] Этап 2: track проверяется в публикуемом edit; есть тест TOCTOU.
- [ ] Этап 3: слой 2 в издателе перечитывает состояние, сам выполняет единственную
      мутацию версии и не переиспользует чужой submission; есть тесты TOCTOU.
- [ ] Перечисления 6.1 этапа 3 совпадают с исходниками CLI 0.70.0 и OpenAPI; неизвестное — fail closed.
- [ ] Фазы A–E и R раздела 15 идут без противоречий: проверки → активация U5 → релиз →
      очистка → (повтор).
- [ ] Ни один этап не требует store-запросов или изменения секретов агентом.
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
| 1 | iOS: preflight — единственная защита перед мутациями CLI (P-19) | Слой 2 в `apple_publish.py`: перечитывание в момент мутации, собственный выбор версии, запрет переиспользования submission, проверка item и confirm; fake-тесты TOCTOU (9.6.4) |
| 2 | Android: track проверялся в отдельном preflight-edit (P-20) | `GuardedPublishEdit` проверяет track в публикуемом edit (`begin_edit`, `update_track`); опора на контракт инвалидации edit Google; тест TOCTOU |
| 3 | Повтор после FAILED_BEFORE_MUTATION подразумевал тот же путь, что первый релиз | Два пути (5.6): CLI только для первого релиза; повтор — фаза R через re-run/rebuild провайдера после свежей проверки и нового разрешения; после UNKNOWN повтор запрещён |
| 4 | DryRun без явной проверки свежести tracking-ref (P-22); «никаких Git-операций с origin» | Шаги свежести 5.3 с тестами устаревшей и отсутствующей ссылки; классы G0–G4 |
| 5 | `STORE_MUTATION_BEGIN` утверждал мутацию | `PUBLISHER_INVOKED` = «издатель вызван, мутация возможна»; SUBMITTED только по `PLAY_EDIT_COMMITTED`/`APPLE_REVIEW_SUBMISSION_CONFIRMED`; валидация не считается публикацией |
| 6 | Отказ до git проверялся только для Dart CLI | Тесты в окружении без git для Dart CLI и для `prokat-prod-android`/`prokat-prod-ios` |
| 7 | «Удалить пять файлов» без уточнения | Локальная очистка рабочего дерева, не Git-удаление; в этапе 0 не выполняется |
| 8 | Риск повтора при активной переменной описан без защиты | Android — номер попытки в разрешении; iOS — явный остаточный риск и решение Q8 до U5; P-21 и OC-D1 для неотправленных изменений Play |
