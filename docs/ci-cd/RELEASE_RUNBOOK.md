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

## Production: ручное восстановление

Один оператор, один production-релиз за раз. Автоматический повтор загрузки,
submission и Rebuild того же тега не используются. `PUBLISHER_INVOKED` означает
только то, что управление дошло до издателя. Успех Android — `PLAY_EDIT_COMMITTED`.
Успех iOS submission — `APPLE_REVIEW_SUBMISSION_CONFIRMED`.
`APPLE_SUBMISSION_STEP_COMPLETED` успехом submission не является.
Следующий выпуск — новая подписанная сборка: больший общий build number в
`pubspec.yaml` на `main` и новый тег `android/v…` или `ios/v…`. Уже созданный
тег повторно не используют.

### A. Ошибка до возможной мутации магазина

Признак: прогон закончился, в полном логе нет `PUBLISHER_INVOKED`. Типичные коды:
`Production publishing is disabled until owner gate U5`,
`ANDROID_CLOUD_AUTHORIZATION_INVALID`, `IOS_CLOUD_AUTHORIZATION_INVALID`,
`IOS_PRODUCTION_AUTHORIZATION_INVALID`, `IOS_PRODUCTION_REQUIRES_WEBHOOK`,
`iOS release requires Codemagic tag webhook context`, сообщения истории номеров
и preflight до издателя.

1. Прочитать код в логе и исправить причину: gate, строка разрешения, тег, SHA,
   номер, notes или подпись.
2. Play Console → App bundle explorer и production track: bundle этого номера
   отсутствует. App Store Connect → Build Uploads и App Store version: upload и
   submission этого номера отсутствуют.
3. Поднять build number, пройти review в `main` и запустить обычную команду
   только для этой платформы. Второй платформе новый бинарник не отправлять,
   если её релиз уже принят.

Preflight Play делает `edits.insert` и сразу `edits.delete`. Это не upload.
Если издатель не вызывался, новый тег допустим после проверки консоли.

### B. Upload подтверждён, следующий этап не завершён

Новый бинарник не собирать.

- Android: в логе есть `PLAY_EDIT_COMMITTED`, ревью или выпуск в консоли не
  закончены. Play Console → Publishing overview и production track. Завершать
  только уже отправленный release. Managed publishing не переключать в середине
  релиза.
- iOS: сборка видна в App Store Connect → Build Uploads / TestFlight, а
  `APPLE_REVIEW_SUBMISSION_CONFIRMED` нет. Открыть App Store version этой
  версии и привязать уже загруженный build. Второй IPA не загружать.

### C. UNKNOWN после возможной мутации

Признак: есть `PUBLISHER_INVOKED`, но нет `PLAY_EDIT_COMMITTED` или
`APPLE_REVIEW_SUBMISSION_CONFIRMED`. Сюда же `APPLE_SUBMISSION_OUTCOME_UNKNOWN`,
`PLAY_CHANGES_IN_REVIEW`, отмена, таймаут и неполный лог.

Автоматический повтор запрещён. Не нажимать Re-run, Rebuild и не создавать тег,
пока консоль не проверена.

1. Android: Play Console → App bundle explorer, production track, Publishing
   overview. Искать versionCode из тега.
2. iOS: App Store Connect → Build Uploads, TestFlight builds, App Store version,
   Review Submissions. Искать CFBundleVersion из тега.
3. Если загрузка или submission уже есть — продолжать с этим артефактом вручную,
   как в B или D. Новый бинарник не собирать.
4. Если эффекта нет и это видно надёжно (нет bundle, нет upload, нет submission,
   лог полный и оборвался до издателя) — готовить следующую сборку, как в A.
5. Если состояние неясно — остановиться. Новую мутацию не запускать.

### D. Сбой после создания App Store submission

Коды: `APPLE_SUBMISSION_OUTCOME_UNKNOWN`, `APPLE_SUBMISSION_GUARD_FAILED`,
`APPLE_SUBMISSION_ITEMS_CHANGED`, `APPLE_SUBMISSION_ITEMS_CHANGED_AFTER_CONFIRM`.
IPA к этому моменту уже мог быть принят.

1. App Store Connect → версия из тега → Review Submissions.
2. Продолжить существующий submission: items, What's New, confirm — вручную,
   если состояние версии это позволяет.
3. Второй submission ради зелёного CI не создавать. Повторный запуск
   `ios-production` для того же тега не делать.

## Retry и accepted binary

iOS +22 CLI parse failure: [publishing preflight / IPA recovery](IOS_PUBLISHING.md).
До expensive steps выполняется offline `ios_store.py validate-publish` с полным
argv из того же builder. CLI 0.70.0 требует attempt counts 1/1/1; нули запрещены,
default retries не допускаются. Version/parse failure — STOP до IPA. Следующий
iOS-only candidate +23 — отдельный PR/history/live check/U4 GO, не перенос +22.

SwiftPM download timeout на +21: [network retry guide](IOS_SWIFTPM_RETRIES.md).
Только locked resolver имеет до 3 попыток с паузами 15/45 секунд. Exit 74 без
распознанной transient network ошибки не повторяется; locks проверяются против
HEAD до и после. Manifest/version/checksum/signature/drift/unknown — STOP.
Ограничения: 10 минут на попытку, 32 на helper, dependency-phase deadline от
первого script; общий workflow 90 минут не меняется. Никакого retry IPA/publishing.
После финального FAIL сохранить URL/SHA/exit code; не двигать +21. Новый iOS-only
+22 готовится только через review, свежую history/store проверку и отдельный U4 GO.

Перед повтором iOS +20 используйте [Apple diagnostic runbook](IOS_CI_DIAGNOSTICS.md).
Ручной `ios-apple-diagnostic` не собирает/не публикует IPA и запускается только
после отдельного GO с main. Он не заменяет release guards и live preflight.
Retry старого +20 требует доказанного сохранения webhook CM_TAG/SHA и текущего
окружения; обычный выбор тега в UI/API недостаточен. Иначе отдельный reviewed
iOS-only +21 через feature → dev → main; Android +19 не повторять. Теги неизменяемы.

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
IPA `build/ios/ipa/*.ipa` сохраняется при любом исходе со стандартным retention
Codemagic ([компромисс и сроки](IOS_PUBLISHING.md)); не удаляется по одному exit 0.
Отдельного AAB/IPA архива/GitHub Releases нет; Android policy не меняется.
UNKNOWN publishing не разрешает повторный upload. Bit-for-bit rebuild не обещается.
SDK/Flutter/Gem/native locks и production defines хранятся в Git; credentials — вне Git.
Dart obfuscate/split-debug-info не включены; их добавление потребует отдельной
стратегии символов. Подробности существующей проверки:
[VERIFICATION](VERIFICATION.md), [CLI tests](../../tool/release/README.md).

При исчерпании бесплатных минут остановите теги. Не включайте billing, не
переносите iOS на GitHub macOS, не делайте repo public и не добавляйте worker.
Hotfix/rollback — новый исправляющий релиз через PR и больший общий номер,
не перезапись старых тегов.
