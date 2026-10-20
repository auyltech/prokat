# PROKAT — памятка по CI/CD

## A. Подготовка релиза

Изменения идут через feature PR → dev. В dev задайте, например:

```yaml
version: 1.2.3+19
```

Коммит: `chore: bump version to 1.2.3+19`.
Подготовьте `releases/1.2.3/release.json`:

```json
{"schema":1,"version":"1.2.3","ready":true}
```

Добавьте проверенные «Что нового» в `ru.txt`, `en.txt`, `kk.txt`: UTF-8 без BOM,
plain text, 1–500 символов, без placeholders. Если каталога ещё нет:
`dart tool/release/release.dart init --version 1.2.3` создаёт draft с ready=false.
Не затирайте существующие notes. Правила локалей: [releases/README](releases/README.md).

Перед PR:

```powershell
flutter analyze --no-pub --fatal-infos --fatal-warnings
flutter test --no-pub --dart-define=ENABLE_FIREBASE_SERVICES=false --dart-define=ENABLE_PUSH_NOTIFICATIONS=false
git diff --check
```

## B. Git-интеграция

Feature PR → dev, review, затем отдельный PR dev → main с проверкой полного diff.
Выполните **Squash and merge**; сообщение:
`release: 1.2.3+19 (Android+iOS)`.
Для платформенного retry допустимо `release: 1.2.3+20 (iOS)`.

CLI всегда выбирает текущий remote main: это требует предварительного review
и утверждения его HEAD. Версию/SHA вручную не вводят. Старые SHA выбирать нельзя.
Если main продвинулся между двумя платформами, даже при неизменной версии парный
тег блокируется: подготовьте новый общий build через dev → main.
Не используйте `merge -s ours` как регулярную процедуру — он может скрыть изменения.
Откат существующего main для внедрения CLI не нужен.

## C. Запуск публикации

После отдельного разрешения владельца на реальную публикацию:

| Команда | Канал | Тег для 1.2.3+19 |
| --- | --- | --- |
| `prokat-rc-android` | Google Play Internal Testing | `rc/android/v1.2.3+19` |
| `prokat-rc-ios` | TestFlight Internal, AuylTech Test Team | `rc/ios/v1.2.3+19` |
| `prokat-prod-android` | Google Play Production, U5 gate | `android/v1.2.3+19` |
| `prokat-prod-ios` | App Store Review / AFTER_APPROVAL, U5 gate | `ios/v1.2.3+19` |

Production-строки показывают формат, **не разрешают** production 1.2.3+19.
Каждая команда сначала показывает platform/channel/version/full SHA/tag, затем
`Continue? [y/N]`. Production дополнительно требует `PUBLISH PRODUCTION`.
Локальная и CI-проверки default-deny требуют явного U5 gate; наличие локального
разрешения не включает secret CI. Не включайте gates ради проверки CLI.

Результаты: [GitHub Actions](https://github.com/auyltech/prokat/actions),
[Codemagic Builds](https://codemagic.io/apps),
[Play Console](https://play.google.com/console/),
[App Store Connect / TestFlight](https://appstoreconnect.apple.com/apps).
Зелёный CI не доказывает доступность тестировщикам или публикацию: проверьте
магазин, группу, установку и smoke tests.

## D. Ошибка CI или отказ магазина

| Ситуация | Действие |
| --- | --- |
| CI упал до upload | Установить точную стадию и состояние магазина; исправить причину. Если нужен новый tag/build — повысить общий номер через PR. Старый тег неизменяем |
| Отказ только метаданных | Исправить metadata/reviewer access; после отдельного разрешения повторить submission уже принятой сборки без upload. Новый бинарник/номер может не требоваться |
| Отказ бинарника | Исправить код, повысить общий build, пройти dev → main и запустить только нужную платформу |
| Android принят, iOS нет | Не повторять Android; после проверки Apple подготовить, например, 1.2.3+20 и выполнить только prokat-rc-ios |
| iOS принят, Android нет | Аналогично: повысить общий build и выполнить только prokat-rc-android |
| Timeout / неизвестный upload | STOP: проверить API, uploads/builds и CI. Отсутствие ответа не означает свободный номер |
| Локальный тег создан, push не удался | Сохранить тег, прочитать напечатанную инструкцию восстановления; сначала remote refs/CI/store, без force/delete и слепого rerun |

Retry только номера: в dev измените `pubspec.yaml` на `1.2.3+20`,
commit `chore: bump version to 1.2.3+20`, проверьте notes той же версии,
PR dev → main, squash `release: 1.2.3+20 (iOS)`. Native version-файлы не меняйте.

## E. Следующий общий релиз

Общий счётчик: Android+iOS `1.2.3+19` → retry iOS `1.2.3+20` →
следующий общий релиз **`1.2.4+21`**, а не +20.
Если retry не было, +20 допустим только после проверки истории обеих платформ.
Новая версия требует нового каталога notes, version bump, тестов и PR.
Будущую доработку профиля собственника готовят отдельно, не в CLI-задаче.

## F. Ограничения и безопасность

- CLI читает pubspec и notes из свежего remote main, не из текущей ветки.
  CI получает version/build из immutable tag и проверяет совпадение с pubspec.
- Счётчик общий, 1..9999. Новый номер больше всех предыдущих release-тегов
  обеих платформ и известных store builds. Одинаковый номер двух платформ
  допустим только для одной версии и одного SHA.
- Git не гарантирует свободный номер: обязательные live preflight выполняются
  до build и непосредственно перед upload. Локальные snapshots — только нижние границы.
- RC → Production того же бинарника логически возможен, но **promotion в текущих
  publishers не реализован**. CLI блокирует другой канал того же platform/build.
  Принятый AAB/IPA повторно не загружать. Ручной promotion/submission — отдельная
  операция владельца с проверкой accepted build, не эти четыре команды.
- Production новой сборки требует нового общего номера, одобрения U5, CI gate
  и прав магазина. Эти команды не включают разрешения.
- Отмена не меняет checkout/index/refs/tags. Обычная подготовка использует
  временный bare Git-кэш вне checkout и удаляет его. После подтверждения CLI
  fetch-ит main в origin/main, создаёт annotated tag и отправляет только его.
- Dry-run ничего не записывает и не fetch-ит: свежий remote SHA читается через
  ls-remote, blobs должны уже быть в локальном object cache. Если их нет,
  отдельно выполните `git fetch origin main`, затем повторите dry-run.
- Чистый checkout обязателен. CLI не делает switch, merge, rebase, push веток,
  force, удаление или перемещение тегов. Изменение main/тегов во время проверки — STOP.
- Между последней проверкой refs и push остаётся малая неатомарная гонка main.
  CI независимо проверяет ancestry, tag identity, подпись, package и live store state.
- RC использует production API/Firebase: тестовые действия могут менять реальные данные.
  Export Compliance действует для Kazakhstan only / France Not Available; при
  изменении SDK/криптографии/географии повторить [аудит](docs/ci-cd/APPLE_EXPORT_COMPLIANCE.md).

## G. Установка CLI (Windows / PowerShell)

Нужны Git, Dart из pinned Flutter, SSH-доступ к origin. В корне checkout:

```powershell
. .\tool\release\prokat-release.ps1
Get-Command prokat-rc-android, prokat-rc-ios, prokat-prod-android, prokat-prod-ios
prokat-rc-android -DryRun
prokat-rc-ios -DryRun
```

Для постоянного подключения один раз добавьте **в существующий** PowerShell
`$PROFILE` строку (не перезаписывайте остальной профиль):

```powershell
. 'C:\Users\User\Documents\GitHub\prokat\tool\release\prokat-release.ps1'
```

Загрузчик не создаёт aliases и отказывается перезаписать одноимённые чужие
aliases/functions. После перемещения checkout обновите путь в профиле.
Из любого shell доступен кроссплатформенный эквивалент:
`dart tool/release/cli.dart android rc --dry-run` (из корня checkout).

После review/merge CLI в main, успешного dry-run и отдельного GO:

```powershell
prokat-rc-android
prokat-rc-ios
```

Для следующего production сначала подготовьте новый общий номер/notes через
dev → main, подтвердите U4/A5, получите U5. Только после отдельной настройки
разрешённых локального и CI gates: `prokat-prod-android -DryRun`,
`prokat-prod-ios -DryRun`, затем соответствующая команда без -DryRun.
Не пытайтесь этим способом продвинуть уже загруженный RC с тем же номером.

Подробности: [runbook](docs/ci-cd/RELEASE_RUNBOOK.md),
[настройка аккаунтов](docs/ci-cd/MANUAL_SETUP.md),
[CLI contract/tests](tool/release/README.md).
