# Релизы PROKAT с Windows

Эти команды применяются после настройки U1–U3. RC требует U4; production требует
завершённого A5/U5. Наличие документа не разрешает создавать теги сейчас.

## Подготовка версии и исходного коммита

1. Выполните `git fetch origin --prune --tags`, проверьте `git status --short`.
   Подготовьте исправления обычным процессом PR. Не выбирайте автоматически HEAD
   как release source. Владелец должен утвердить **полный 40-character SHA**.
2. Создайте notes до утверждения финального release commit:

   ```powershell
   dart tool/release/release.dart init --version 1.2.3
   ```

   В `releases/1.2.3/` отредактируйте ru.txt/en.txt/kk.txt в UTF-8 без BOM.
   Каждый текст 1–500 символов, plain text без HTML/`<`/`>`, без placeholders.
   В release.json установите `ready: true` после проверки переводов. Закоммитьте.
   Не меняйте pubspec version ради CI. Все native версии задаёт тег.
3. Выберите новый build number отдельно для платформы: больше любого предыдущего
   platform release tag, store build/upload и подтверждённого historical floor.
   Android: 1..2100000000. iOS: 1..9999 (консервативная single-component политика).
   RC → production тоже использует новый номер. Не переиспользуйте номер при
   неясном результате. Другую платформу увеличивать/собирать не требуется.
4. Откройте отдельный чистый worktree утверждённого SHA для проверки. Пример:

   ```powershell
   $approved = 'REPLACE_WITH_APPROVED_40_CHARACTER_SHA'
   git worktree add --detach ..\prokat-release-check $approved
   Set-Location ..\prokat-release-check
   dart tool/release/release.dart check --tag 'rc/android/v1.2.3+19' --platform android --channel rc --revision $approved
   ```

   `check` только проверяет Git/notes и генерирует ignored build/release; он не
   создаёт тег и не обращается к store. Для production он ещё fetch-ит main и
   проверяет ancestry. Папка worktree должна отсутствовать; если занята, выберите
   другое имя. Flutter можно установить через `fvm install` / `fvm use` по .fvmrc,
   либо использовать установленный Flutter 3.47.2. Проверка
   `dart tool/release/check_toolchain.dart android` подтверждает SDK.

## Создание и отправка тегов

Ниже **примеры**, номера 19/20 не подтверждены магазином. Подставьте утверждённые
версию/номера/SHA. Каждый вызов `git tag` содержит revision явно.

```powershell
$approved = 'REPLACE_WITH_APPROVED_40_CHARACTER_SHA'
git show --no-patch --format=fuller $approved
git ls-remote --tags origin 'refs/tags/rc/android/v1.2.3+19' 'refs/tags/rc/ios/v1.2.3+19'
```

Если remote ref существует — не перезаписывайте и не удаляйте его. Для RC после
точного разрешения U4:

```powershell
git tag -a 'rc/android/v1.2.3+19' $approved -m 'Android internal 1.2.3+19'
git push origin 'refs/tags/rc/android/v1.2.3+19'
```

Только iOS RC (Android не запускается):

```powershell
git tag -a 'rc/ios/v1.2.3+19' $approved -m 'iOS TestFlight 1.2.3+19'
git push origin 'refs/tags/rc/ios/v1.2.3+19'
```

Production после U5, из утверждённого main commit:

```powershell
git fetch origin main
git merge-base --is-ancestor $approved origin/main
if ($LASTEXITCODE -ne 0) { throw 'Production source is not in origin/main' }
git tag -a 'android/v1.2.3+20' $approved -m 'Android production 1.2.3+20'
git push origin 'refs/tags/android/v1.2.3+20'
```

Только iOS production:

```powershell
git tag -a 'ios/v1.2.3+20' $approved -m 'iOS production 1.2.3+20'
git push origin 'refs/tags/ios/v1.2.3+20'
```

Перед iOS production выполните ту же проверку main ancestry. Чтобы отправить оба
уже подготовленных production refs одним действием:

```powershell
git push --atomic origin 'refs/tags/android/v1.2.3+20' 'refs/tags/ios/v1.2.3+20'
```

Не используйте `git push --tags` (может захватить лишние теги). Не отправляйте
более трёх тегов одновременно: GitHub может не создать tag push events.
Одинаковый SHA обеих платформ разрешён, зависимостей между workflows нет.
При ошибке push проверьте remote refs, не создавайте альтернативный тег вслепую.

## Проверка результата

- [GitHub Actions](https://github.com/auyltech/prokat/actions): `Android tag
  release`, tag/SHA, run ID, attempt, tool versions, fingerprint/AAB validation,
  `PLAY_EDIT_COMMITTED`. Проверьте фактический release статус в нужном Play track.
- Codemagic application → Builds: `ios-rc`/`ios-production`, точный tag/SHA,
  signing/IPA verification, Firebase upload, `APPLE_SUBMISSION_STEP_COMPLETED`.
  Проверьте **TestFlight internal group** или состояние **App Review** в ASC.
- Сохраняйте URL runs в рабочем release/issue при необходимости; отдельная база
  не нужна. Git хранит notes/lockfiles/версии, CI logs — инструменты и store state.
- Google/Apple review — внешний процесс. Uploaded, processing, available to
  testers, waiting for review, approved и publicly released — разные состояния.
  Ни зелёный run, ни сообщение об upload не доказывают публикацию в магазине.

## Повторить только одну платформу

Если Android уже выпущен, а iOS упал: проверьте Apple state, выберите новый iOS
build и тот же approved source commit (или утверждённый fix). Создайте только
`rc/ios/...` либо `ios/...`. Аналогично только Android тег при его ошибке. Не
меняйте старые теги, Android не зависит от iOS и не запустится по iOS-тегу.

В период U4–A5 новый RC требует отдельного разрешения, если владелец явно не
разрешил серию конкретных тестов. После U5 штатные теги отправляет владелец без
ежерелизного approval CI; агент всё равно соблюдает полномочия текущей задачи.

| Ситуация | Действие |
| --- | --- |
| До upload, store API подтверждает состояние | Исправить причину, новый platform build/tag на approved SHA |
| Уже принят Android bundle | Не reupload. App bundle explorer + track/review state. Существующий internal build можно продвинуть штатным Supply/Play UI без загрузки; pipeline этот recovery автоматически не делает |
| Уже принят iOS upload/build | Не reupload. Build Uploads → TestFlight → App Store version. Дождаться processing, затем использовать существующий build при submission/recovery |
| Timeout/403/5xx/неполный список | **BLOCKED / state UNKNOWN**. Восстановить API access, проверить store. Отсутствие результата не доказывает отсутствие upload |
| Запущен более новый platform tag | Старый номер блокируется историей Git. Не запускать несколько выпусков одной платформы одновременно |

Стандартная стратегия **RC → production — новая сборка с новым номером** для
обоих магазинов. Supply поддерживает track promotion; Apple позволяет выбрать
готовый TestFlight build для App Store. Это запасные ручные/операторские recovery
операции, а не ещё один tag workflow. Не вызывайте команды продвижения без
production authorization и проверки exact accepted build/SHA/notes.

Для безопасного Apple recovery штатный CLI умеет `--skip-package-upload` и
`builds submit-to-app-store`; команда зависит от принятого build ID и статуса
версии. Агент сначала читает состояние и готовит точный вызов, не пересобирает IPA
и не запускает шаблонный publish повторно. Не включайте cancellation/expire
предыдущих submissions для обхода конфликта.

## Review, квоты, hotfix

При App Review rejection сохраните build/submission ID и причину. Если проблема
в metadata/reviewer access, исправьте её и повторно отправьте существующую сборку
штатным ASC API/консолью по разрешению; исправление кода — новый approved commit,
новый build/tag. Обычные What's New продолжайте менять в Git. Review exceptions
могут требовать участия владельца, полной гарантии «никогда не заходить в консоль»
при изменении правил/agreements/отказах нет.

При исчерпании бесплатных минут остановите создание release tags до следующего
reset квоты. Не включайте billing, не переносите iOS на GitHub macOS, не меняйте
репозиторий на public. Проверьте остаток общей GitHub quota (включая PR checks)
и Codemagic Billing. Linux cache должен оставаться в бесплатном storage limit.

Hotfix: исправление через обычный PR → approved main commit → новый patch version
и больший platform build. Rollback осуществляется новым исправляющим выпуском
с большим versionCode/build; переустановка старой AAB поверх новой не работает.
Если нужно остановить rollout/review, это отдельная production-операция владельца.

## Восстановление и символы

```powershell
git fetch origin --tags
git rev-parse 'refs/tags/ios/v1.2.3+20^{commit}'
git show 'ios/v1.2.3+20:releases/1.2.3/release.json'
git worktree add --detach ..\prokat-investigate 'refs/tags/ios/v1.2.3+20^{commit}'
```

SDK pins, pubspec.lock, Gemfile.lock, native Podfile.lock, Gradle wrapper/AGP,
Xcode selection и production defines восстановим из Git. Credentials должны
существовать в provider/защищённом backup; Git их не содержит. Битовую
идентичность пересборки не обещаем (OS image, signing timestamps, store processing).

Нет долгосрочного AAB/IPA-хранилища, GitHub Release attachments не создаются.
Android mapping отправляется Crashlytics до Play. При неуспехе mapping upload
сборка не поступает в Play. На iOS upload-symbols должен успешно принять все
dSYM до Apple upload. При сбое ZIP `build/release/ios-symbols.zip` сохраняется
как единственный recovery artifact Codemagic; Personal retention сейчас 30 дней.
Скачайте его до истечения срока в существующий защищённый архив разработчика,
повторите upload после устранения причины и подтвердите пригодность отчётов.
Единственные symbols не удаляйте до подтверждения приёма Firebase. При успехе
ZIP удаляется до artifact collection; IPA никогда не сохраняется как artifact.

`--obfuscate` и `--split-debug-info` не используются. Если их позже добавят,
нужно заранее загрузить Flutter symbols в Firebase через Firebase CLI и
обеспечить независимую сохранность для `flutter symbolize`: обычный dSYM/R8
mapping не заменяет Dart symbol files. До этого такие флаги добавлять нельзя.
