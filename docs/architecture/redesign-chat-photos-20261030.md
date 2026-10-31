# UI kit и фото чата — 30 октября 2026

Пользователь разрешил отдельный приватный дизайн-репозиторий и фото/галочки чата. Всё приложение, backend и web остаются локально в feat/redesign-20261013. Ни push этих веток, ни merge 1.3.0, ни deploy/store не разрешались. GitHub-разрешение касается только нового дизайн-репозитория.

## Дизайн-система

Создан PRIVATE https://github.com/auyltech/prokat-design-system, исходный commit 06e8f57, tag v0.1.0. Локально C:/Projects/Prokat-Mobile/prokat-design-system. Самостоятельный Flutter package с 64 исходниками UI kit и чистых зависимостей; assets/fonts с OFL; DTCG JSON токены, CSS, интерактивная HTML gallery, карта пресетов и provenance. Пакет проверен Flutter test/analyze, Node token checks. Приложение массово на этот пакет не переключали.

Завершены v0.1.1 и v0.1.2: прикладные карточки/запуск как reference (не standalone exports), CompactMessageText, readReceipt token, CI проверки tokens, независимый phone normalizer. Последний commit `2fb0917c2d6d7bc9cf1be7007d3684a929ffe5fe`, tag `v0.1.2`, запушен ТОЛЬКО дизайн-репозиторий. CI success: https://github.com/auyltech/prokat-design-system/actions/runs/41031424813. Рабочее дерево kit чистое.

## Фотографии

Подробная архитектура, ограничения, приватность, удаление и восстановление — `prokat-backend/docs/CHAT_PHOTOS.md`. Миграции `20261030120000_chat_photos` и `20261030133000_chat_photo_deletion_queue` применены ТОЛЬКО к маркированной локальной копии. Вторая сохраняет совместимость физического удаления старой истории: cascade + DB trigger ставит файлы в очередь удаления в той же транзакции. Отдельный private MinIO bucket `chat-attachments` создан. Остальные volumes fresh20261029 сохранены.

- Один IMAGE на сообщение, optional caption. Sharp resize/re-encode WebP, EXIF/GPS не сохраняются. Превью отдельно. ACL до чтения MinIO: участник чата с действующими правами либо ADMIN (audit log). Гостю/постороннему нельзя, private/no-store, без public URL.
- Guards отправки сохраняют блоки, закрытие чата, ONLINE частного владельца. IMAGE через обычный socket нельзя подделать. Квоты и idempotency есть.
- Жалоба CHAT_MESSAGE содержит attachment snapshot; в админке и владельческом веб-чате добавлен защищённый viewer/proxy. Prisma schema web синхронизирована, generate/tsc прошли, migrate из web не запускался.
- Account purge добавляет фото в существующую очередь удаления с учётом удержания истории/жалоб.
- Backup CLI export/verify/restore проверен на синтетическом фото: 2 объекта, manifest/SHA256; восстановление в отдельный временный private bucket побайтно совпало, anonymous403. Временный restore bucket очищен. Prod backup mount/timer и отдельная защищённая копия ещё не включались — это часть будущего deployment, не обещать автоматическую защиту уже работающего прода.
- Receipt берётся из серверного lastReadMessage, история отдаёт readAt, событие chat:read обновляет галочки; server проверяет messageId принадлежность чату. Короткий текст/время inline, WidgetSpan не масштабирует вложенный Text дважды. Merge сохраняет readAt.

## Проверки к текущему моменту

Backend и web tsc без ошибок. Ограниченный серверный регресс: 23/23 (фото, DTO/validation/lifecycle/права/условия брони); дополнительный конечный прогон photo integration прошёл после fail-closed проверки bucket policy. Гость401, посторонний404, участники/ADMIN200, web proxy и HTML жалобы проверены, повтор загрузки не создаёт дубль, удаление сообщения ставит два файла в очередь. Flutter: 118/118 проверок chat + visual copy + startup, включая 3 новых photo/receipt/layout проверки. Main Flutter analyze No issues. UI kit: 2/2 tests, analyze No issues; Node token checks и CI success. Это целевой регресс, не утверждение о полном тестировании каждого сценария приложения.

## A12

Samsung SM-A125F, serial R58R60PHZ9E, USB authorized. S22 сейчас не подключён. `scripts/s22-prokat.ps1` получил DeviceSerial и адаптивный scroll; старый default S22 оставлен для совместимости. A12 `stay_on_while_plugged_in` временно3, старое значение в artifacts/chat-photos-20261030/a12-stay-awake-before.txt; вернуть по завершении. Reverse4000 есть. Server/Firebase/push local flags прежние.

На A12 установлена новая 1.2.4+26 profile APK; API localhost4000. Зашли в НОВЫЙ локальный QA клиент +77000000111 / fakeOTP000000. Владелец +77000000112, имена «Тестовый клиент/владелец Фото QA», username photo-qa-client/owner. Это не существующие продовые люди. Созданы только локальные фикстуры: скрытая техника и ACTIVE inquiry чат без заказа cmvuom25h00005np4keck3cdz. Подготовка/ответ/прочтение второго пользователя — src/scripts/local-chat-photo-qa.ts (guard DB marker + LOCAL_REPLICA).

Телефон: прошли вход, открыли обсуждение, получили фото от локального владельца, отправили wow; owner read через HTTP — UI сразу показывает «Прочитано», на скриншоте две mint галочки в одной строке с текстом/временем. Через системный Photo Picker выбрали только добавленный prokat-local-photo-qa.jpg, просмотрели preview, отправили; сообщение IMAGE сохранилось. Другие личные фото не открывались. Backend `.local-artifacts` ignored.

Скриншоты/XML в artifacts/chat-photos-20261030 и artifacts/integration-20261028/a12-*. Скрепка на A12 видна и работает. Исправлены возврат клавиатуры после preview, semantic label фото и двойная шапка viewer (root Navigator). AppUpdatePrompt пропускает Env.isLocal: production update policy сохранена. При конечной визуальной проверке обнаружено наследование чёрных title/icon из legacy AppBarTheme; viewer получил явные белые title/icon styles. Все эти исправления вошли в конечную установленную сборку и визуально проверены на A12.

## Конечный проход и состояние для продолжения

- A12: клиент отправил фото через native picker → preview → HTTP; просмотрел, отправил жалобу на входящее фото без блокировки. Владелец вошёл отдельно, получил историю, отправил фото через тот же UI; `read-client` вызвал реальный HTTP markRead, и UI немедленно показал «Прочитано»/две mint-галочки. Никакой Booking от переписки/фото не появился.
- Для QA owner штатно проверены ограничения: нулевой баланс/отсутствие тарифа запрещали ONLINE/показ техники. Guarded `fund-test` добавил только тестовому владельцу 600 минут, тариф18000/час, категорию и видимость QA техники. Затем ONLINE включён настоящим switch профиля; фикстуры не имитируют реальный платёж. Телефон оставлен в OWNER mode. Не путать локальные тестовые аккаунты с перенесёнными людьми.
- Ограниченный UI smoke: клиентские каталог/профиль/настройки/документы/запрос и форма/заказы/чаты; владельческие профиль/ONLINE/парк/запросы/заказы/чаты. Общие пары формы симметричны. Все реальные перенесённые записи использовались только для чтения.
- Локальный backup всех нынешних фото: `artifacts/chat-photos-20261030/private-photo-backup` (6 объектов, SHA256 verify success). Отдельный пробный restore в временный private bucket ранее побайтно проверен и очищен. Этот каталог содержит приватные тестовые материалы; не коммитить/не публиковать. Таймер prod backup, off-server copy и изменение опубликованной политики не выполнялись.
- Видео отправки/прочтения QA-чата: `artifacts/chat-photos-20261030/a12-chat-demo.mp4`. Конечный вид после исправления цветов viewer: `a12-chat-demo-final.mp4` и `a12-final-viewer-white.png`. В синтетическом QA JPEG надпись изначально отрисована квадратами из-за отсутствия шрифта у генератора; это содержимое тестовой картинки, не проблема шрифта интерфейса.
- Web ADMIN viewer работает. При строгом App Check владельческий web proxy без App Check будет отклонён как и прежний `/api/media`; перед таким rollout требуется штатная веб-аттестация. Новый обход безопасности не добавлен. iOS разрешения добавлены, но сборка/устройство iOS на Windows не проверялись.
- Diff check исходников app/backend/web/infra пройден; generated Prisma не правили вручную (генератор оставляет whitespace в комментариях). В приложении, backend, web и infra всё остаётся незапушенным в рабочих ветках. Пользовательский `redesign-product-flow.md` сохранён.
- Конечный APK: `prokat/build/app/outputs/flutter-apk/app-profile.apk`, profile1.2.4+26, APP_ENV=local, SHA256 `FE3F976D9B2EA212E4B973E6E3F3F04B7DEE0255EE8E11B0E2A7B0689618CBAD`. Установка Success; после перезапуска сохранена QA owner сессия, фото загружается и подписи видны. Firebase/внешние push и jobs отключены локальными флагами; delivery настоящих push в этом прогоне не проверяли.
- A12 stay-on-while-plugged-in возвращён в исходное0, 30-минутный timeout пользователя не менялся. USB reverse4000 сохранён. Все5 локальных контейнеров healthy; сервер оставлен работать. Никакие app/backend/web/infra ветки не пушились и не деплоились.

## Дополнение: единое хранение обсуждений и фотографий

По следующему запросу пользователя реализовано 30 октября2026, только локально:

- Все сообщения, фото и thumbnails подчиняются одному сроку; постоянная `chatHistoryRetention` — 12 календарных месяцев. Общий `purgeChatHistory` используется и старой очисткой заказов, и новой очисткой обсуждений. Фото удаляются существующей durable queue через ChatAttachment trigger.
- Обсуждение не отдельный статус/таблица: это прежний Chat DIRECT с inquiryEquipmentId, пока нет bookingId. При превращении в заказ автоматически действуют старые правила Booking.historyEndedAt. Новая очистка не затрагивает SUPPORT, компании, заявки или чаты с офферами.
- Для закрытого обсуждения начало срока — первое закрытие. Для заброшенного ACTIVE — последнее сообщение, либо создание пустого чата. Реальный MAX(ChatMessage.createdAt) защищает от запоздавшего sidebar cache. Открытая жалоба удерживает историю, после разрешения дата не сбрасывается.
- Добавлены Chat.historyEndedAt/historyPurgedAt и миграция `20261030150000_inquiry_history_retention`. DB triggers фиксируют первое закрытие и сериализуют вставку сообщения с очисткой; запоздалый send не может воскресить очищенную историю. После purge остаётся минимальный ARCHIVED Chat без сообщений.
- Account purge после трёхмесячного срока удаляет личный аккаунт, но сохраняет ещё не очищенную общую историю обсуждения как историю заказа. Старые аккаунты не удерживаются ради FK — применяется прежняя архивная обезличенная связь.
- Суточный booking-history job обходит обе группы и обслуживает файловую очередь. Используются прежние выключатели очистки. На локальном зеркале AUTOMATIC_BUSINESS_JOBS_ENABLED/BOOKING_HISTORY_AUTO_PURGE_ENABLED/ACCOUNT_DELETION_AUTO_PURGE_ENABLED остались выключены; физическое удаление проверялось только на созданных синтетических строках/файлах с явным scope.
- Backend/web Prisma schema синхронизированы и generated обновлены; tsc обоих репозиториев прошёл. Целевой регресс16/16: history/photo/inquiry-close/lifecycle/account purge/calendar deadline/media queue. `artifacts/chat-photos-20261030/chat-retention-regression.log`. Первая попытка HTTP пришлась на перезапуск dev watcher; повтор после health200 прошёл полностью. Фикстуры очищены. Действительные перенесённые чаты не удалялись.
- Действующую политику зеркала дополнительно сверили через GET /legal-documents:12 месяцев по завершению заказа. Уточнения обсуждений/фото и исключения при удалении аккаунта подготовлены RU/KK/EN в backend `docs/legal/drafts/2026-10-30-chat-retention/`. Ни публикации, ни правки задним числом published revisions не было. Резервные копии по-прежнему подчиняются отдельному ограниченному циклу; prod mount/timer/offsite не включались.
- Изменения этого этапа серверные; APK на A12 остаётся конечным1.2.4+26 с hash FE3F976D…8CBAD. Повторная сборка мобилки не нужна. Никаких merge1.3.0/push/deploy/store действий.
