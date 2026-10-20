# Релизы PROKAT с Windows

Повседневные команды, bump/retry и Git integration:
[памятка владельцу](../../CICD-README.md). Она заменяет прежние примеры ручного
создания тегов и выбора SHA/номеров. Никакой документ не разрешает публикацию.

## До запуска

1. Закройте U1–U3 и получите отдельное U4 для RC / U5 для production.
   Account setup: [ANDROID_SETUP](ANDROID_SETUP.md),
   [MANUAL_SETUP](MANUAL_SETUP.md), [OWNER_CHECKLIST](OWNER_CHECKLIST.md).
   Credentials остаются в CI, локально их копировать не требуется.
2. Version bump и RU/EN/KK metadata проходят dev → main PR с review и squash.
   Новая сборка использует общий build выше историй обеих платформ.
   Исторические floors 18 (Play), 17 (Apple) — не сегодняшняя доступность.
3. Убедитесь в чистом checkout; подключите CLI:
   `. .\tool\release\prokat-release.ps1`.
   Выполните `prokat-rc-android -DryRun` / `prokat-rc-ios -DryRun`.
   Dry-run свежий по refs, но без fetch/записей. При отсутствии blobs отдельно
   обновите object cache командой `git fetch origin main`.
4. Проверьте preview текущего main, notes, канал и явное разрешение владельца.
   После GO используйте нужную команду без -DryRun. Production default-deny;
   дополнительно требуется PUBLISH PRODUCTION, и gate CI остаётся независимым.

Native versions задаёт tag; CLI получает его из pubspec текущего remote main.
Не редактируйте Android/iOS version-файлы. CI повторно проверяет tag/pubspec.
SwiftPM locks сохраняйте вместе с Podfile.lock; [native guide](IOS_DEPENDENCIES.md).
Нельзя автоматически откатывать main или выполнять ours sync ради CLI.

## Проверка результата

- [GitHub Actions](https://github.com/auyltech/prokat/actions): Android tag release,
  tag/SHA/run/attempt, upload certificate, AAB manifest/signature,
  Crashlytics mapping, PLAY_EDIT_COMMITTED. В Play проверьте фактический
  internal/production track и доступность тестировщику.
- Codemagic: ios-rc/ios-production, точный tag/SHA, existing distribution identity,
  profile/bundle/team, production APNs, Associated Domains, Boolean Export
  Compliance, dSYM upload, APPLE_SUBMISSION_STEP_COMPLETED.
  В ASC проверьте processing, внутреннюю AuylTech Test Team или App Review.
- Сохраните URL runs и store IDs в release issue. Uploaded, processing,
  available to testers, waiting for review, approved и publicly released —
  разные состояния. Не объявляйте PASS без установки/smoke на устройстве.
- RC использует production API и Firebase; тесты могут менять реальные данные.
  Холодный старт, auth, API, push, sharing/deep links и update prompt проверяются
  на обеих платформах. Публичный App Store не обновляет TestFlight-сборку.

## Retry и accepted binary

CI/store API checks обязательны до build и до upload. Timeout/403/5xx,
неполная pagination или неизвестный commit edit — STOP, state UNKNOWN.
Не нажимайте rerun/rebuild и не создавайте альтернативный тег вслепую.
Если нужен новый build: bump общего номера в dev, notes/review, новый PR main;
затем только команда неуспешной платформы. Успешную платформу не загружать снова.

Метаданные/reviewer access можно исправить без нового бинарника. Apple notes
обновляет version-guarded adapter apple_publish.py: только существующие locale,
ошибка останавливает submission. IPA к этому моменту уже мог быть принят.
У первой App Store version What's New не PATCH-ится, тексты сохраняются в Git.
Обычные notes остаются источником Git, не новой store locale.

Принятый Android bundle: проверить App bundle explorer, tracks/review.
Принятый Apple upload: Build Uploads → TestFlight → App Store version.
Существующую сборку можно рассматривать для ручного promotion/submission после
отдельного разрешения и проверки exact accepted build/SHA/notes.
**Наши publishers promotion не реализуют**: тег production с тем же номером
не продвинет RC, а попытался бы загрузить новый бинарник и будет заблокирован.
Codemagic CLI skip-package-upload/submission и Play UI/track promotion —
отдельный операторский recovery, не автоматические команды этого runbook.
Не меняйте production credentials/gate в рамках диагностики.

## Push не удался

Локальный annotated tag сохраняется; CLI не удаляет его автоматически.
Следуйте напечатанной инструкции: ls-remote exact tag и peeled SHA, затем CI/store.
Если remote тег существует, проверьте SHA и не повторяйте upload.
Если достоверно отсутствует, после повторной проверки main/history можно вручную
повторить только exact ref push, напечатанный CLI. Не используйте force,
push --tags, перенос или удаление опубликованного тега.
Новый запуск CLI при существующем локальном теге ожидаемо останавливается.

## Символы, квоты, воспроизводимость

Android mapping загружается в Crashlytics до Play; при ошибке store upload не идёт.
iOS все native dSYM загружаются до ASC; только неудача оставляет recovery ZIP
build/release/ios-symbols.zip (Personal retention 30 дней). Сохраните его до истечения.
AAB/IPA архивного хранилища/GitHub Releases нет; bit-for-bit rebuild не обещается.
SDK/Flutter/Gem/native locks и production defines хранятся в Git; credentials — вне Git.
Dart obfuscate/split-debug-info не включены; их добавление потребует отдельной
стратегии символов. Подробности существующей проверки:
[VERIFICATION](VERIFICATION.md), [CLI tests](../../tool/release/README.md).

При исчерпании бесплатных минут остановите теги. Не включайте billing, не
переносите iOS на GitHub macOS, не делайте repo public и не добавляйте worker.
Hotfix/rollback — новый исправляющий релиз через PR и больший общий номер,
не перезапись старых тегов.
