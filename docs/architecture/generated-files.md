# Политика генерируемых файлов

Этот документ определяет источник правды для уже имеющихся генерируемых
артефактов. Генерируемые файлы не редактируются вручную. Изменение источника и
его результата должно входить в один PR.

| Группа | Источник правды | Инструмент | Хранение в Git | Ручное изменение |
| --- | --- | --- | --- | --- |
| Локализация Dart | `lib/l10n/*.arb`, `l10n.yaml` | `flutter gen-l10n` | да, `lib/l10n/app_localizations.dart` | запрещено |
| Firebase options | конфигурация Firebase/FlutterFire проекта | `flutterfire configure` | да, `lib/firebase_options.dart` | запрещено |
| Android plugin registrant | `pubspec.lock` и Flutter tooling | Flutter tooling | да | запрещено |
| iOS/macOS plugin registrants | `pubspec.lock` и Flutter tooling | Flutter tooling | да | запрещено |
| Linux/Windows plugin registrants | `pubspec.lock` и Flutter tooling | Flutter tooling | нет: пути исключены `.gitignore` | запрещено |
| Freezed/JSON/Riverpod codegen | annotated Dart source и утверждённый builder | `dart run build_runner build --delete-conflicting-outputs` | только после отдельного решения | запрещено |

## Правила

- Секреты и локальные конфигурации (`.env*`, `config.json`, Android keystore,
  `google-services.json`) не копируются в документацию и не добавляются в Git.
- Изменение зависимостей может законно обновить plugin registrant. Такой diff
  проверяется вместе с изменением `pubspec.lock`; самостоятельное ручное
  изменение registrant запрещено.
- В текущем tactical-треке не добавляются новые generators и не запускается
  `build_runner` ради преобразования существующего кода.
- Если в будущем будут одобрены Freezed, JSON или Riverpod generators,
  соответствующий source и outputs коммитятся одним PR. Рабочий кэш
  `.dart_tool/` не коммитится.
- Неожиданный generated diff, не объясняемый изменением источника, является
  стоп-условием до выяснения его происхождения.

## Проверка

Перед PR с изменением генерации необходимо проверить changed-file list,
`git diff --check`, `flutter analyze` и `flutter test`. Для локализации также
запускается `flutter gen-l10n`; для FlutterFire — только утверждённая команда
`flutterfire configure` в подходящем окружении.
