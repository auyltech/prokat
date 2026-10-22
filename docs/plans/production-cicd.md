# Production CI/CD PROKAT — план доведения прямых Production-релизов

Статус: **этап 0 завершён (исследование и план). Реализация не начата.**
Ветка: `feat/production-cicd-hardening` от `origin/dev` `6f0aa0e506a0f4c74745d4e9fa7196032207b82c`.

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
| GitHub-настройки | **не прочитаны**: `gh` не авторизован. Rulesets, Environments, тариф, список collaborators неизвестны (owner checkpoint OC-2) |

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
| План | `ReleaseCli.plan` | `git ls-remote origin`, blobs `origin/main`: pubspec, `releases/X.Y.Z/*`, workflow, `production.json`, `Info.plist` | грязное дерево; нет main; notes не `ready`; тег существует; история номеров; guard-строки workflow; `production.json`; Export Compliance; main сдвинулся. **Production: gate `PRODUCTION_PUBLISHING_ENABLED` уже здесь, поэтому DryRun невозможен (P-01)** | нет. Обычный режим делает fetch во временный bare-репозиторий вне checkout | `cli_test.dart` |
| Исполнение | `ReleaseCli.execute` | интерактивный ввод | `Continue? [y/N]`; для production фраза `PUBLISH PRODUCTION`; gate; повторная проверка main и тегов | `git fetch` в `refs/remotes/origin/main`, `git tag -a`, `git push origin refs/tags/T:refs/tags/T` | `cli_test.dart` |
| CI: источник | `release.dart ci` → `validateEvent`, `validateProduction`, `validateRevision`, `validatePubspecVersion`, `prepare` | env провайдера, `GITHUB_EVENT_PATH`/`CM_TAG` | не tag push; удаление тега; SHA не в `main`; тег сдвинут; история; pubspec ≠ тег; gate | `git fetch` в runner | `release_test.dart`, `source_test.dart` |
| CI: gate Android | шаг `Reject production until U5` в `android-release.yml`; `play.rb` | `secrets.PRODUCTION_PUBLISHING_ENABLED` | значение ≠ `true` | нет | `config_test.py` (структура) |
| CI: gate iOS | `release.dart ci`, `ios_store.py main` | env-группа Codemagic `prokat-ios-release` | значение ≠ `true` | нет | `ios_store_test.py` |
| Состояние Play | `play.rb preflight` → `ProkatPlayStore.snapshot` → `PlayPolicy.check!` | `PLAY_SERVICE_ACCOUNT_JSON_BASE64`, `vars.PLAY_HISTORICAL_MAX_BUILD` | номер занят; номер ≤ максимума; locale; track ≠ канал | **да: `edits.insert` + `edits.delete`** (P-06) | `play_policy_test.rb`, `play_store_test.rb` |
| Состояние Apple | `ios_store.py preflight` → `read_apple_state` + `check_builds` | `PROKAT_ASC_PRIVATE_KEY_PEM`, `APP_STORE_CONNECT_*`, `APP_STORE_APP_ID`, `IOS_HISTORICAL_MAX_BUILD`, `TESTFLIGHT_GROUP` (RC) | номер занят в builds/buildUploads; номер не растёт; 401/403/429/5xx/timeout/пагинация → UNKNOWN | нет (GET). Пишет `build/release/apple-state.json` в runner | `ios_store_test.py` |
| Сборка Android | `inputs.dart android`, `verify_upload_key.py`, `flutter build appbundle`, Crashlytics mapping | keystore, пароли, alias, `google-services.json`, Mapbox `pk.*` | отпечаток upload key ≠ `ANDROID_UPLOAD_CERT_SHA256`; mapping пуст | загрузка mapping в Firebase | `verify_upload_key_test.py` |
| Проверка AAB | `verify_android.dart` + bundletool 1.18.3 (sha256 закреплён) | `ANDROID_UPLOAD_CERT_SHA256` | подпись; отпечаток; debug-сертификат; package; versionCode/Name. **Без targetSdk (P-05)** | нет | **нет тестов** |
| Публикация Android | `play.rb publish` → `Supply::Uploader#perform_upload` | service account | канал/track/номер заново (второй temporary edit); событие GitHub | **да**: edit, upload AAB, `update_track` (заменяет все releases track, P-04), changelogs, `edits.commit` (**default `CANCEL_IN_REVIEW_AND_SUBMIT`, P-03**) | `sdk_contract_test.rb` (наличие опций) |
| Сборка iOS | `swiftpm_resolve.py`, `xcode-project use-profiles`, `flutter build ipa`, `verify_ios.py`, dSYM | integration `prokat-app-store`, профили | lock-дрейф, entitlements, bundle, Export Compliance | загрузка dSYM в Firebase | `verify_ios_test.py`, `swiftpm_resolve_test.py` |
| Публикация iOS | `ios_store.py publish` → `apple_publish.py` (Codemagic CLI 0.70.0) | integration, PEM | повторный preflight; ровно один IPA; argv через парсер CLI; локализации строго | **да**: upload IPA; RC — подтверждение Automatic Distribution (GET); production — App Store version create/update, `reviewSubmissions` create/reuse, submit (P-07) | `ios_store_test.py`, `apple_publish_test.py`, `testflight_distribution_test.py` |

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
| P-07 | P0 | iOS production не проверяет App Store versions и review submissions до сборки. Codemagic CLI 0.70.0: (a) берёт **самую новую редактируемую** версию с любой строкой и переименовывает её в нашу; (b) к «редактируемым» относит `WAITING_FOR_REVIEW`, то есть меняет build у версии, ожидающей ревью; (c) при открытом `reviewSubmission` **переиспользует** его и подтверждает вместе с чужими элементами | `SubmitToAppStoreAction._get_editable_app_store_version`, `_update_existing_app_store_version`, `_create_review_submission`; `AppStoreState.editable_states()` (cli-tools v0.70.0). В `ios_store.py` таких GET нет | ПОДТВЕРЖДЕНО |
| P-08 | P2 | Production Apple app ID не закреплён (RC закреплён `require_rc_target`) | `validate_apple_environment` принимает любой `APP_STORE_APP_ID`. Смягчение: проверка `bundleId == com.auyltech.prokat` в `read_apple_state` | ПОДТВЕРЖДЕНО |
| P-09 | P0 | Облачный gate — постоянный boolean. После включения любой push production-тега (ошибка, агент, старый скрипт) или re-run упавшего job публикует. `PUBLISH PRODUCTION` проверяется только локально. Неизменяемость тегов обеспечивает только клиентский CLI | `android-release.yml` (`on.push.tags`, шаг `Reject production until U5`); `codemagic.yaml` (`ios-production`, `tag_patterns: ios/v*`); `cli.dart execute` | ПОДТВЕРЖДЕНО для кода. Серверные rulesets — ПРЕДПОЛОЖЕНИЕ (OC-2) |
| P-10 | P1 | Python- и Ruby-тесты релиза не запускаются в PR. Python идёт только в Codemagic release run (рядом с секретами); из Ruby в Android run запускается лишь `play_policy_test.rb`; `play_store_test.rb` и `sdk_contract_test.rb` автоматически не запускаются нигде | `.github/workflows/pull-request.yml`, `android-release.yml:99`, `codemagic.yaml:42` | ПОДТВЕРЖДЕНО |
| P-11 | P2 | Документация устарела: «production dry-run requires gate»; «следующий общий релиз `1.2.4+24`» (24 уже занят). Тесты закрепляют устаревший текст | `tool/release/README.md:49-51`; `CICD-README.md` раздел E; `cli_test.dart` `'documented wrappers…'` и `cli_docs_test.py test_owner_commands_and_flags_exist` проверяют `1.2.4+24` | ПОДТВЕРЖДЕНО |
| P-12 | P1 | Untracked-файлы promotion блокируют все четыре команды | `ReleaseCli.clean`, `main()` в `cli.dart` | ПОДТВЕРЖДЕНО |
| P-13 | info | После upload iOS ждёт обработку не более 20 минут; при таймауте IPA уже в ASC, submission нет | `publish_arguments`: `--max-build-processing-wait 20` | ПОДТВЕРЖДЕНО. Поведение fail-closed верное (UNKNOWN, без retry). Не менять без решения владельца |
| P-14 | info | Automatic Distribution внутренней TestFlight-группы может показать тестерам и production-билд | настройка Apple (`hasAccessToAllBuilds`), production argv группу не назначает | ПРИНЯТО. Не менять: сломает RC |
| P-15 | — | Production argv не содержит `--testflight`, `--beta-group`, `--cancel-previous-submissions`, `--expire-build-submitted-for-review` | `publish_arguments`, `test_production_requests_after_approval` | ИСПРАВЛЕНО РАНЕЕ |
| P-16 | — | Upload/API без blind retry: Play `retries = 0`, `SUPPLY_UPLOAD_MAX_RETRIES=0`; Apple attempt counts 1/1/1, парсинг argv закреплённым CLI | `play_store.rb NoBlindPlayRetries`, `apple_publish.validate_publish_arguments` | ИСПРАВЛЕНО РАНЕЕ |

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
- Store-снапшоты (`build/release/*-state.json`) — нижние границы. Равенство с
  максимумом другого магазина допустимо только при парном теге **того же канала** и SHA.
- Первый production-номер обязан быть > 24 и > фактических максимумов Play и Apple,
  включая Build Uploads. `+25` не считается безопасным заранее (OC-4, OC-5).

### 5.3 DryRun и исполнение

| Режим | Production gate выключен | Production gate включён |
| --- | --- | --- |
| `prokat-prod-* -DryRun` | Preview, все проверки истории и источника, строка `Production gate (local): DISABLED`, `DRY RUN`. Без fetch, тегов, сборок и запросов к магазинам | То же, `ENABLED` |
| `prokat-prod-*` | BLOCK **до первого вопроса**: никаких prompt, fetch, tag | Preview → `y` → `PUBLISH PRODUCTION` → повторная проверка gate, main, тегов → tag → push |

### 5.4 Уровни защиты Production

| Уровень | Сейчас | Цель |
| --- | --- | --- |
| Локальный CLI | `PRODUCTION_PUBLISHING_ENABLED=true` в env сессии + `PUBLISH PRODUCTION` | Без изменений (только перенос проверки из `plan` в `execute`) |
| GitHub Actions | `secrets.PRODUCTION_PUBLISHING_ENABLED == true` | Плюс точное совпадение `vars.PRODUCTION_RELEASE_TAG == github.ref_name` в шаге gate, `release.dart ci`, `play.rb` (решение Q1) |
| Codemagic | `PRODUCTION_PUBLISHING_ENABLED == true` из группы `prokat-ios-release` | Плюс `PRODUCTION_RELEASE_TAG == CM_TAG` в `release.dart ci` и `ios_store.py` |
| Сервер GitHub | неизвестно | Если тариф позволяет: tag ruleset на `refs/tags/android/v*`, `refs/tags/ios/v*`, `refs/tags/rc/**` (create только владелец; update и delete запрещены) |
| Магазины | без production-права у Play service account | Право Release to production выдаётся только на U5 |

Почему exact-tag. Это одноразовое разрешение на конкретный тег. Его может выставить
только администратор репозитория или Codemagic. Оно не срабатывает на случайный
следующий тег и не требует платного GitHub. Boolean остаётся аварийным выключателем.
Остаточный риск: любой collaborator с правом write может изменить workflow в своей
ветке и прочитать repository secrets. Этот риск снимается только ограничением write-доступа
(OC-2), Environment-scoped секретами и rulesets, а не кодом workflow.

### 5.5 Инварианты RC

Не меняются без отдельного решения владельца: формат `rc/*`; track `internal`;
`release_status: completed`; Automatic Distribution без `--beta-group` и `--testflight`;
подтверждение `TESTFLIGHT_INTERNAL_DISTRIBUTION_CONFIRMED`; существующие теги.
Единственное предлагаемое изменение RC: `ERROR_IF_IN_REVIEW` (Q2). Оно защищает
production review от RC-коммита.

---

## 6. Порядок этапов

```text
Этап 1  Контракт: очистка, DryRun, канал в истории номеров   (Dart)
   │
   ├── Этап 2  Android: Play commit, production track, targetSdk  (Ruby, Dart verify)
   ├── Этап 3  iOS: App Store versions / review submissions       (Python)
   │
Этап 4  Облачный gate: exact-tag во всех слоях                (YAML, Dart, Ruby, Python)
   │
Этап 5  PR-регрессия Python/Ruby + эксплуатационная документация
   │
Этап 6  Репетиция без публикации + production-readiness
```

Обоснование:

- Этап 1 первым: он чисто локальный, снимает P-12 и даёт DryRun. С ним дальнейшие
  этапы проверяются preview без gate.
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

## 7. Этап 1 — контракт: очистка, DryRun, канал в истории номеров

1. **Цель.** Production DryRun без gate. Настоящий запуск блокируется до любого
   вопроса и тега. RC и Production не делят номер. CLI снова работает на чистом дереве.
2. **Проблемы.** P-01, P-02, P-12; часть P-11 (`tool/release/README.md`).
3. **Зависимости.** Нет. GO владельца на удаление пяти файлов (Q6).
4. **Границы.**
   - Можно: `tool/release/cli.dart`, `tool/release/release.dart`,
     `test/release/cli_test.dart`, `test/release/release_test.dart`, абзац про
     dry-run в `tool/release/README.md`; удаление пяти untracked-файлов раздела 4.
   - Нельзя: workflow YAML, Ruby, Python, формат тегов, фразу `PUBLISH PRODUCTION`,
     RC-поведение, `CICD-README.md` (этап 5), любые git-операции с origin.
5. **Участки кода.** `ReleaseCli.plan`, `ReleaseCli.execute`,
   `ReleaseCli.validateStores` (ветка `release.build == maximum`),
   `validateBuildHistory`, `validateProduction`.
6. **Решение.**
   - Удалить `validateProduction(release, environment)` из `plan`.
   - В `execute` после печати preview: строка
     `Production gate (local): ENABLED|DISABLED` (только для production). Если
     `!dryRun && production` — `validateProduction` **до** `confirm('Continue?…')`.
     Существующую проверку перед `git tag` оставить.
   - `validateBuildHistory`: в условие пары добавить `previous.channel == release.channel`.
     Сообщение для равного номера в другом канале:
     `Build N already used by <tag> in another channel; RC and production never share a build. Bump pubspec.`
   - `validateStores`: допустимое имя пары — только
     `'${release.production ? '' : 'rc/'}$other/v$same'`.
   - README: production dry-run больше не требует gate; настоящий запуск требует.
7. **Инструкция исполнителю.** См. prompt E1 в разделе 13.
8. **Effort / Context.** Medium / файлы этапа плюс разделы 5.2–5.3.
9. **Тесты.** `flutter test --no-pub test/release`, `flutter analyze`, `dart format`,
   `git diff --check`, Python-набор (README и docs-тесты не должны сломаться).
   Обязательные новые и изменённые тесты:
   - production DryRun без env: план построен, `writes` пуст, `confirm` не вызывался,
     вывод содержит `DISABLED` и `DRY RUN`;
   - production execute без env и с `'false'`, `'TRUE'`, `' true'`, `''`: `ReleaseFailure`,
     `writes` пуст, **ни одного вызова `confirm`**;
   - production execute с env `true`: прежние `fetch`, `tag`, `push`;
   - `rc/ios/v1.2.3+24` на SHA `s`, версия `1.2.3+24` → `android production` BLOCK,
     `ios production` BLOCK, `android rc` OK (пара RC);
   - `android/v1.2.3+25` на `s` → `ios production` `+25` OK; на `other` → BLOCK;
     `rc/ios` `+25` → BLOCK (другой канал);
   - `validateBuildHistory` unit: матрица platform × channel × version × SHA для равного номера;
   - `validateStores`: снапшот Play с кодом 25 + `rc/android/v1.2.3+25` не даёт пары
     для `ios production`; `android/v1.2.3+25` даёт;
   - существующие RC-тесты не меняются и проходят.
10. **Приёмка.**
    - [ ] 5 файлов раздела 4 удалены; `git status --short` пуст, кроме файлов этапа.
    - [ ] `plan()` не читает gate; `execute(dryRun: false)` для production читает gate раньше `confirm`.
    - [ ] Проверка gate перед `git tag` сохранена.
    - [ ] Пара номера требует одного канала в `validateBuildHistory` и `validateStores`.
    - [ ] Dart 118 + новые тесты проходят; Python-набор проходит.
    - [ ] Нет изменений в YAML, Ruby, Python-коде.
11. **Негативные сценарии.** Опечатка в gate; gate не `true`; ответ `N`/пустой/`yes`;
    отказ от `PUBLISH PRODUCTION`; main сдвинулся после preview; тег появился во время
    подтверждения; RC-номер для Production; Production-номер для RC; пара на другом SHA;
    пара другой версии; локальный неотправленный тег.
12. **Регрессии RC.** Тесты `rc` в `cli_test.dart`, `source_test.dart`, PowerShell-обёртки.
    Признак регрессии: любой изменённый ожидаемый результат для `rc`.
13. **Риски и откат.** Риск: DryRun начнут путать с разрешением. Смягчение: явная
    строка `DISABLED` и отсутствие prompt. Откат: `git revert <коммит этапа>` в ветке.
    Удалённые untracked-файлы не восстанавливаются. STOP, если любой из пяти файлов
    окажется tracked или на него появится ссылка.
14. **Владелец.** GO на удаление (Q6). Если нужна копия — сохранить вне репозитория заранее.
15. **Аудит.** Diff этапа; список удалённых путей; вывод
    `dart tool/release/cli.dart android production --dry-run` из ветки против
    текущего `origin/main`. Ожидаемо BLOCK по P-02 (`+24` занят `rc/ios`), без prompt
    и записей. Сравнить `git show-ref --tags` до и после.

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
     gate-логика (этап 4), чтение Play без temporary edit, любые сетевые вызовы в тестах.
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
   версии 2.241.0, документ edits.commit, раздел 5.4.
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
5. **Участки кода.** `preflight(context)`, `read_apple_state`, `FAILURE_CODES`,
   `STAGES`, `SUCCESS_EVENTS`, `validate_apple_environment`, `main`.
6. **Решение.**
   - Новый GET-only `read_production_state(config, token, deadline)`:
     - `all_pages("/v1/apps/{id}/appStoreVersions?filter[platform]=IOS&fields[appStoreVersions]=versionString,platform,appStoreState,appVersionState&limit=200")`;
     - `all_pages("/v1/reviewSubmissions?filter[app]={id}&filter[platform]=IOS&filter[state]=READY_FOR_REVIEW,WAITING_FOR_REVIEW,IN_REVIEW,UNRESOLVED_ISSUES,CANCELING,COMPLETING&limit=200")`.
   - Чистая функция `check_app_store_versions(context, versions, submissions)`:

     | Условие | Результат |
     | --- | --- |
     | У версии нет `versionString` или `appVersionState`; неизвестное значение состояния; платформа ≠ `IOS` | `APPLE_RESPONSE_INVALID` (UNKNOWN) |
     | `appVersionState` ∈ {`WAITING_FOR_REVIEW`, `IN_REVIEW`, `READY_FOR_REVIEW`, `ACCEPTED`, `PENDING_APPLE_RELEASE`, `PENDING_DEVELOPER_RELEASE`, `PROCESSING_FOR_DISTRIBUTION`, `WAITING_FOR_EXPORT_COMPLIANCE`} | `APPLE_VERSION_IN_FLIGHT` |
     | Редактируемых (`PREPARE_FOR_SUBMISSION`, `DEVELOPER_REJECTED`, `REJECTED`, `METADATA_REJECTED`, `INVALID_BINARY`) больше одной, или одна со строкой ≠ версии тега | `APPLE_VERSION_CONFLICT` |
     | `appStoreState` ∈ editable-набор CLI 0.70.0 (включая `WAITING_FOR_REVIEW`), а `appVersionState` не редактируемый | `APPLE_VERSION_CONFLICT` |
     | `READY_FOR_DISTRIBUTION` или `REPLACED_WITH_NEW_VERSION` со строкой ≥ версии тега (покомпонентно) | `APPLE_VERSION_NOT_INCREASING` |
     | Есть хоть один review submission из запроса | `APPLE_REVIEW_SUBMISSION_OPEN` |
     | Иначе | OK: путь «создать версию» (нет редактируемой) или «продолжить» (одна редактируемая с нашей строкой) |

   - Вызывается из `preflight(context)` только при `context["channel"] == "production"`,
     то есть дважды: до сборки и перед upload.
   - Production закрепляет `config["app_id"] == "6817078475"` (константа без
     привязки к RC, например `APP_ID`), новый код не нужен: `APPLE_APP_MISMATCH`.
   - Новые коды и стадии (`versions`, `submissions`) добавить в allowlist;
     сообщения фиксированные, без тел ответов.
7. **Инструкция исполнителю.** Prompt E3.
8. **Effort / Context.** High / `ios_store.py`, `ios_store_test.py`, исходник
   `submit_to_app_store_action.py` и `enums.py` cli-tools v0.70.0, раздел 3 P-07.
9. **Тесты.** Fake `get_json`/`all_pages`, без сети:
   - каждая строка таблицы → ожидаемый код, издатель (`subprocess.run`) не вызывается;
   - 401/403/429/5xx/timeout/битая пагинация на стадиях `versions` и `submissions` → UNKNOWN без издателя;
   - RC: URL `appStoreVersions` и `reviewSubmissions` не запрашиваются;
   - production argv идентичен текущему (snapshot-сравнение со списком из `test_production_requests_after_approval`);
   - production с `APP_STORE_APP_ID` ≠ `6817078475` → `APPLE_APP_MISMATCH` до publish;
   - существующие 169 тестов проходят, `testflight_distribution_test.py` не изменён.
10. **Приёмка.**
    - [ ] Таблица реализована и покрыта тестами построчно.
    - [ ] Только GET; `checked_url` и пагинация переиспользованы, без нового HTTP-клиента.
    - [ ] Нет изменений RC-пути и argv.
    - [ ] Ошибки и коды не содержат тел ответов или значений env.
11. **Негативные сценарии.** Таблица целиком; пустой ответ на второй странице;
    `next` на чужой хост; дубликат ID; таймаут общего дедлайна 90 секунд.
12. **Регрессии RC.** `ios_store_test.py` RC-случаи, `testflight_distribution_test.py`, `apple_publish_test.py`.
13. **Риски и откат.** Новые значения состояний Apple дадут UNKNOWN (fail closed),
    владелец увидит код. Между вторым preflight и действиями CLI остаётся окно
    обработки IPA до 20 минут: состояние может измениться. Это остаточный риск,
    документируется. Откат — `git revert`.
14. **Владелец.** Нет действий до этапа 6. Live GET не выполняется.
15. **Аудит.** Diff; вывод Python-набора; построчное сопоставление таблицы с тестами;
    grep на `method="POST"|PATCH|DELETE` в `ios_store.py` (должно быть пусто).

---

## 10. Этап 4 — облачный gate: точное разрешение тега

1. **Цель.** Одного push тега, re-run или забытого `true` недостаточно для публикации:
   облако требует разрешения именно этого тега.
2. **Проблемы.** P-09.
3. **Зависимости.** Этапы 1–3 приняты. **Решение Q1 обязательно.** Ниже описан
   рекомендуемый вариант A. При другом решении план этапа переписывается и снова
   согласуется.
4. **Границы.**
   - Можно: `tool/release/release.dart` (`validateCloudAuthorization`, вызов в `ci`),
     `tool/release/cli.dart` (guard-строки), `.github/workflows/android-release.yml`
     (env и шаги gate), `tool/release/play.rb` и `tool/release/play_policy.rb`
     (функция авторизации), `tool/release/ios_store.py` (`main`), тесты
     `release_test.dart`, `cli_test.dart`, `config_test.py`, `ios_store_test.py`,
     `play_policy_test.rb`; раздел U5 в `docs/ci-cd/MANUAL_SETUP.md`.
   - Нельзя: создавать или менять секреты и переменные, GitHub settings, Codemagic UI,
     RC-путь (для RC новая проверка не вызывается), триггеры workflow.
5. **Участки кода.** Шаг `Reject production until U5`; `validateProduction`;
   `play.rb` (строки с `PRODUCTION_PUBLISHING_ENABLED`); `ios_store.py main`; список
   guard в `ReleaseCli.plan`.
6. **Решение (вариант A).**
   - Имя: `PRODUCTION_RELEASE_TAG`. GitHub — repository **Variable** (видна, правит
     только admin); Codemagic — переменная в группе `prokat-ios-release`.
   - Правило для production в CI: `PRODUCTION_PUBLISHING_ENABLED == "true"` **и**
     `PRODUCTION_RELEASE_TAG == <точное имя тега>` (без trim и регистра).
   - Проверка в каждом слое независимо: bash-шаг до установки Flutter;
     `release.dart ci`; `play.rb preflight/publish`; `ios_store.py validate-publish/preflight/publish`.
   - Локальный CLI не видит переменные провайдеров. В production preview печатает
     `Cloud requires PRODUCTION_RELEASE_TAG=<tag> on <GitHub|Codemagic>`.
   - Guard в `ReleaseCli.plan` **только для channel `production`**: Android workflow
     обязан содержать `PRODUCTION_RELEASE_TAG`; iOS принимается через `release.dart`,
     содержащий `validateCloudAuthorization` (по образцу текущего исключения). RC-план
     новую guard-строку не требует, иначе RC против старого `main` сломается.
   - `config_test.py` закрепляет точный список входов Android
     (`test_exact_android_u2_input_inventory_and_prebuild_key_check`,
     `test_cost_artifact_and_production_contract`). Обновить их явно, добавив
     `PRODUCTION_RELEASE_TAG`, а не ослаблять проверку.
7. **Инструкция исполнителю.** Prompt E4.
8. **Effort / Context.** High / все файлы этапа, раздел 5.4, текущие тесты gate.
9. **Тесты.**
   - `release_test.dart`: матрица `enabled ∈ {absent,'true','TRUE','false'}` ×
     `tag ∈ {absent, exact, other, exact+' ', rc-tag}`. Пропускает только
     (`'true'`, exact). RC — без проверки.
   - `config_test.py`: в `android-release.yml` gate-шаг идёт до `Install pinned Flutter`,
     ссылается на `vars.PRODUCTION_RELEASE_TAG` и `github.ref_name`; шаги `play.rb`
     получают переменную.
   - `ios_store_test.py`: production без совпадения → блок до API и издателя для
     `validate-publish`, `preflight`, `publish`.
   - `play_policy_test.rb`: функция авторизации — та же матрица.
   - `cli_test.dart`: guard отсутствует → BLOCK; preview содержит строку облачного требования.
10. **Приёмка.**
    - [ ] Четыре слоя Android и три слоя iOS проверяют exact-tag независимо.
    - [ ] RC не читает новую переменную.
    - [ ] Секреты и переменные не создавались.
    - [ ] MANUAL_SETUP U5 описывает выставление и очистку переменной.
11. **Негативные сценарии.** Boolean `true`, тег не тот; тег тот, boolean `false`;
    переменная с пробелом; RC-тег в переменной; re-run после очистки переменной.
12. **Регрессии RC.** Все RC-тесты; `config_test.py` на неизменность RC-триггеров.
13. **Риски и откат.** Владелец забывает очистить переменную: следующий тег всё равно
    не совпадёт. Риск write-доступа к секретам кодом не снимается (раздел 5.4).
    Откат — `git revert`.
14. **Владелец.** Q1; OC-2 (тариф, rulesets, collaborators). При возможности —
    создать tag ruleset (действие владельца).
15. **Аудит.** Diff; таблица «слой → где проверка → тест»; подтверждение, что
    `secrets.*` и `vars.*` в YAML только читаются.

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
   - Документы описывают: DryRun без gate; правило номеров (раздел 5.2); exact-tag;
     Play `ERROR_IF_IN_REVIEW` и production-track; iOS-коды этапа 3; восстановление
     после UNKNOWN; RC `+19` и `+24` как неизменяемую историю.
   - `PRODUCTION_READINESS.md`: чек-лист раздела 15 с PASS/FAIL по каждому пункту.
6. **Инструкция исполнителю.** Prompt E5.
7. **Effort / Context.** Medium / список документов, этот план, итоговый код этапов 1–4.
8. **Тесты.** Весь Dart, Python и Ruby; `cli_docs_test.py` (ссылки, отсутствие ручных
   команд тегов); `actionlint`, если доступен локально, иначе отметить NOT RUN.
9. **Приёмка.**
    - [ ] Job не ссылается на `secrets`, не имеет `write`-прав.
    - [ ] Ни один текущий гайд не содержит ручного создания тегов или force-операций.
    - [ ] Пример следующего номера — без конкретного «безопасного» значения, только правило.
    - [ ] Все команды в документах существуют в коде.
10. **Негативные сценарии.** Сломанная ссылка; устаревший номер; job, зависящий от сети магазинов.
11. **Регрессии RC.** RC-разделы гайдов не меняют смысл, только номера и ссылки.
12. **Риски и откат.** Расход минут (Q7). Откат — `git revert`.
13. **Владелец.** Q7.
14. **Аудит.** Diff документов против кода (grep команд и кодов ошибок).

---

## 12. Этап 6 — репетиция без публикации и готовность

1. **Цель.** Доказать, что ни один путь не публикует без явного разрешения, и
   подготовить первый Production к решению владельца.
2. **Зависимости.** Этапы 1–5 приняты.
3. **Границы.** Без изменений кода, кроме исправлений, найденных репетицией. Они
   идут отдельным согласованным этапом. Никаких тегов, gate, секретов, store-запросов
   агентом.
4. **Шаги агента.**
   - Ветка, CLI из ветки, `origin/main` = `07926a7d`:
     | Команда | Ожидание |
     | --- | --- |
     | `prokat-rc-android -DryRun` | План `rc/android/v1.2.3+24` (пара RC с `rc/ios/v1.2.3+24`, тот же SHA), `DRY RUN`, без записей. Это только preview, не разрешение |
     | `prokat-rc-ios -DryRun` | BLOCK: `rc/ios/v1.2.3+24` уже существует |
     | `prokat-prod-android -DryRun` | BLOCK историей номеров: `+24` занят `rc/ios/v1.2.3+24` (история проверяется раньше guard-строк) |
     | `prokat-prod-ios -DryRun` | BLOCK историей номеров: тот же номер на той же платформе в канале RC |
     | `prokat-prod-android` без `-DryRun`, без env | BLOCK историей до prompt (gate проверяется в `execute`, но `plan` падает раньше) |
   - Дополнительно на fake-фикстуре (unit-тест этапа 1): номер свободен, gate выключен →
     BLOCK до первого `confirm`.
   - До и после: `git show-ref --tags`, `git ls-remote --tags origin` — без изменений.
   - Отчёт `PRODUCTION_READINESS.md` с фактическими результатами.
5. **Шаги владельца (вне агента, после отдельного GO).** Push ветки и PR в `dev` →
   review → merge → `sync-dev`. Bump версии и notes в `dev` → PR `dev` → `main`
   (проверить `git diff --stat origin/main origin/dev`) → DryRun на новом `main` →
   OC-1…OC-10 → U5.
6. **Effort / Context.** Medium / этот план, readiness, вывод команд.
7. **Приёмка.** Все ожидания таблицы совпали; теги не изменились; чек-лист раздела 15 заполнен.
8. **Риски.** Расхождение ожиданий — STOP и отчёт, без «подгонки».

---

## 13. Prompts для исполнителей

Общий заголовок каждого prompt:

> Ты исполнитель одного этапа в репозитории PROKAT (`C:\Users\User\Documents\GitHub\prokat`),
> ветка `feat/production-cicd-hardening`. Прочитай `docs/plans/production-cicd.md`
> целиком: разделы 3, 5 и свой этап. План — техническое задание, но код проверяй сам.
> Запрещено: push, merge, теги, изменения секретов, переменных и консолей магазинов,
> вызовы реальных API Google и Apple, `git reset --hard`, `git clean`, правки вне
> границ этапа, изменения RC-поведения сверх описанного. Если план противоречит коду
> или тест требует credentials — остановись и опиши проблему. В конце: команды и
> фактический вывод, diff-статистика, список негативных сценариев с тестами, один
> коммит этапа без push.

**E1 (Effort Medium, Context: этап 1 + разделы 4, 5.2, 5.3).**
Удали пять untracked-файлов раздела 4, предварительно проверив `git ls-files` (должны
отсутствовать) и `git grep` (нет ссылок). Реализуй решение этапа 1 в `cli.dart` и
`release.dart` и тесты пункта 9. Не трогай YAML, Ruby, Python-код и
`CICD-README.md`. Покажи вывод
`dart tool/release/cli.dart android production --dry-run` против текущего `origin/main`
(ожидается BLOCK без prompt) и `git show-ref --tags` до и после.

**E2 (Effort High, Context: этап 2 + fastlane 2.241.0 `supply/client.rb`, `uploader.rb`).**
Реализуй prepend `ERROR_IF_IN_REVIEW` с fail-closed проверкой сигнатуры, правило
production track в `PlayPolicy.check!`, классификацию `CHANGES_ALREADY_IN_REVIEW`,
`requireTargetSdk` и тест к нему, два bundle-теста в Android workflow. Не меняй
`Gemfile.lock`, track RC и `release_status`. Ruby-тесты запускай только командой
раздела 6. Если Docker недоступен — STOP, этап не сдаётся.

**E3 (Effort High, Context: этап 3 + cli-tools v0.70.0 `submit_to_app_store_action.py`, `enums.py`).**
Добавь GET-only чтение `appStoreVersions` и `reviewSubmissions`, функцию
классификации строго по таблице этапа 3, закрепление app ID для production, коды в
allowlist. Не меняй RC, argv, `apple_publish.py`. Каждая строка таблицы — отдельный
тест; издатель в негативных тестах не вызывается.

**E4 (Effort High, Context: этап 4 + раздел 5.4; только после записанного решения Q1).**
Реализуй exact-tag авторизацию во всех слоях по таблице этапа 4 и тесты-матрицы.
Ни одного `gh secret`/`gh variable`, ни одной правки настроек. RC новую переменную не читает.

**E5 (Effort Medium, Context: этап 5 + итоговый код).**
Добавь job `release-tooling` без секретов и обнови документы по списку. Каждое
утверждение документа сверяй с кодом через grep и ссылайся на файл.

**Аудитор (read-only, Effort Medium, Context: diff этапа + план).**
Проверь diff этапа против границ и приёмки, запусти тесты раздела 6, перечисли
расхождения. Ничего не меняй.

---

## 14. Решения владельца

| ID | Вопрос | Рекомендация |
| --- | --- | --- |
| Q1 | Модель облачного разрешения | A: boolean + `PRODUCTION_RELEASE_TAG` (exact). Альтернативы: оставить только boolean; GitHub Environment с required reviewers (по документации GitHub для private repo требуется Enterprise — подтвердить в OC-2; у Codemagic аналога нет) |
| Q2 | `ERROR_IF_IN_REVIEW` и для RC | Да: иначе RC-коммит может отменить production review |
| Q3 | Production track с `draft`/`inProgress`/`halted` блокирует publish | Да; RC не затрагивается |
| Q4 | `AFTER_APPROVAL` или `MANUAL`; phased release | Оставить `AFTER_APPROVAL` и дефолт приложения, пока владелец не решит иначе до тега |
| Q5 | Версия и номер первого Production | `X.Y.Z` > последней публичной версии App Store и без «занятой» App Store version; `N` > 24, > max Play, > max Apple (включая Build Uploads). Подбирается по OC-4 и OC-5 |
| Q6 | Удаление пяти promotion-файлов на этапе 1 | Да (владелец разрешил); копия — по желанию владельца |
| Q7 | Job release-tooling в каждом PR | Да; оценить минуты Actions приватного репозитория |

---

## 15. Ручные checkpoints владельца (до первого Production)

Агент их не выполняет. Значения секретов в чат не передаются.

| ID | Действие | PASS | FAIL / STOP |
| --- | --- | --- | --- |
| OC-1 | GitHub → Settings → Secrets and variables → Actions: проверить имена RC-секретов и переменных (`ANDROID_*`, `PLAY_SERVICE_ACCOUNT_JSON_BASE64`, `GOOGLE_SERVICES_JSON_BASE64`, `MAPBOX_PUBLIC_TOKEN`, `ANDROID_UPLOAD_CERT_SHA256`, `PLAY_HISTORICAL_MAX_BUILD`) | Все есть; `PRODUCTION_PUBLISHING_ENABLED` отсутствует или `false` | Чего-то нет, или gate уже `true` → STOP |
| OC-2 | GitHub: тариф организации, видимость репозитория, Settings → Rules (rulesets), Environments, список людей с write/admin | Записано; write только у доверенных; при доступности создан tag ruleset | Неизвестные writers → сначала ограничить доступ |
| OC-3 | Codemagic: `ios-production` виден; группа `prokat-ios-release` содержит `APP_STORE_APP_ID=6817078475`, `IOS_HISTORICAL_MAX_BUILD`, PEM, plist; integration `prokat-app-store`; signing `app_store` | Совпадает; gate отсутствует | Нет distribution identity → STOP |
| OC-4 | Play: снимок через `play_access.rb` (**создаёт и удаляет temporary edit**) или вручную в Console: максимум versionCode (включая drafts), статусы `production`/`internal`, primary locale, Managed publishing, production access аккаунта, review-очередь | Максимум записан; production track без чужих draft/inProgress; доступ к production есть | Abort edit не подтверждён; нет production access → STOP |
| OC-5 | App Store Connect: максимум build и Build Uploads; список App Store versions и их состояния; открытые review submissions; скриншоты, privacy, age rating, контакт ревьюера, export compliance | Нет версии в ревью и нет чужого submission; метаданные заполнены | Есть in-flight версия → решить вручную до тега |
| OC-6 | Решения Q1–Q7 записаны | Да | Нет → этап, зависящий от решения, не стартует |
| OC-7 | Merge: ветка → `dev` → `main` с bump; `git diff --stat origin/main origin/dev` перед PR в `main` | Только ожидаемые файлы | Неожиданные файлы → STOP |
| OC-8 | DryRun обеих production-команд на новом `main` | Тег без `rc/`, номер по Q5, SHA = `origin/main` | Любое иное → STOP |
| OC-9 | U5: Play service account получает Release to production; GitHub `PRODUCTION_PUBLISHING_ENABLED=true` и `PRODUCTION_RELEASE_TAG=<тег>`; то же в Codemagic | Оба провайдера настроены на один тег | Расхождение → STOP |
| OC-10 | Запуск одной платформы, затем наблюдение: Android — `PLAY_EDIT_COMMITTED` и track в Console; iOS — `APPLE_SUBMISSION_STEP_COMPLETED` и версия в App Review. После — очистить `PRODUCTION_RELEASE_TAG` | Подтверждено в консоли | UNKNOWN → без re-run, разбор по runbook |

### Production-readiness (итог этапа 6)

- [ ] Этапы 1–5 приняты отдельными аудитами.
- [ ] DryRun Production работает без gate и не пишет refs.
- [ ] Реальный запуск без gate останавливается до prompt и тега.
- [ ] RC и Production не делят номер (тесты).
- [ ] Play: `ERROR_IF_IN_REVIEW`, production track без чужих releases, targetSdk ≥ 36.
- [ ] iOS: versions и submissions проверяются GET до сборки и перед upload; UNKNOWN останавливает.
- [ ] Облако требует exact-tag (или иное записанное решение Q1).
- [ ] PR прогоняет Dart, Python, Ruby release-тесты.
- [ ] Документация совпадает с кодом; в diff нет promotion-кода.
- [ ] OC-1…OC-8 пройдены владельцем.

---

## 16. Реестр рисков

| Риск | Вероятность / влияние | Мера |
| --- | --- | --- |
| Commit Play отменяет чужой review | Средняя / высокое | Этап 2 |
| Publish вытесняет production draft/staged rollout | Низкая / высокое | Этап 2, Q3 |
| CLI 0.70.0 переименовывает или меняет версию в ревью; подтверждает чужой submission | Средняя / высокое | Этап 3 |
| Случайный production-тег при включённом boolean | Средняя / высокое | Этап 4, OC-2 |
| Writer с доступом к репозиторию читает секреты | Низкая / критическое | OC-2: ограничить write, rulesets, environments по тарифу |
| UNKNOWN после upload (таймаут, сеть) | Средняя / среднее | Без retry; runbook; новый номер только после проверки консоли |
| Re-run упавшего job | Средняя / среднее | Exact-tag + повторный store-preflight |
| Изменение Apple-состояний за 20 минут обработки | Низкая / среднее | Остаточный, задокументирован |
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
- [ ] Правило 5.2 закрывает: RC↔Production, частичную пару, повтор, другой SHA, другую версию.
- [ ] Ни один этап не требует store-запросов или изменения секретов агентом.
- [ ] Для каждого этапа заданы границы, тесты, приёмка, негативы, RC-регрессии, откат, аудит.
- [ ] RC-инварианты 5.5 не нарушаются ни одним этапом без решения владельца (Q2).
- [ ] Решения Q1–Q7 получены до соответствующих этапов.
- [ ] Commit этапа 0 содержит только этот файл.
