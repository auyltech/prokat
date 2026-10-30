# Свежий production snapshot для редизайна — 29 октября 2026

## Продолжение после возврата S22 (позже в тот же день)

Финальный local1.2.4+26 APK с company+tariff fix успешно установлен: SHA256 `FFE1CB7E4F582B7618274F7E65BE34680E285FA72DF9B4FE438DE8E8021E5926` (актуальнее всех hash ниже). Лог `company-tariff-final-apk.log`, build44.9s. Сессия и RU сохранены; новый inquiry виден в списке чатов со статусом «Обсуждение». Нет запуска production/release.

Финальная ручная проверка tariff fix на S22 выполнена: `final-tariff-form.png` и `mirror-final-tariff-form.xml` показывают цену30000/час отдельно и полное описание ниже. Телефон оставлен в этой незаполненной форме (из обсуждения), submit disabled. Это актуальнее прежнего пункта «нужна визуальная проверка». Заявки/Booking не отправляли.

Пользователь вернул PROKAT. RU восстановлен. На телефоне проверены публичный запрос (пустая форма не отправлялась), возврат, пустые списки заказов/чатов нового local клиента. Общий импорт сохраняется, пустые списки нового аккаунта ожидаемы.

В клиентских экранах компаний локализованы заголовки, retry/load more, empty state и количество техники; все4 public company страницы подключены к Flow через private presentation scaffold. Вход из каталога компании открывается root navigator: устранена двойная шапка Catalog + CreateOrder и лишняя нижняя навигация поверх формы. API/доступ/создание заказа/назад сохранены. Вручную проверены первая компания → категория8 машин → назад → каталог. Owner/company management screens всё ещё имеют отдельный локализационный долг; не заявлять, что все company UI закончены.

Открыт **один новый локальный inquiry** из реального частного объявления (автокран): перед этим11 Booking/17 Chat, после11 Booking/18 Chat, unconvertedInquiries1. Отправка сообщения/условий/создание Booking не выполнялись. Карточка «Оформить условия» открыла правильную форму с той же техникой/тарифом, Back вернул в то же обсуждение; SQL подтвердил11/18/1. Source production не менялся. Новое обсуждение намеренно оставлено для дальнейшего просмотра.

По реальному screenshot формы обнаружено обрезание длинного service label тарифа. В Flow `BookingOrderFields` цена/единица теперь отдельный selectedLabel, полное описание показано ниже без maxLines. Options/value/onChanged/payload и legacy label не менялись. 3 locale regression checks320px/2x +3 существующих company access checks прошли:6 passed. Analyze No issues. Логи `company-and-tariff-{tests,analyze}.log`. Широкие прогоны не повторялись.

Предыдущая company-only сборка установлена:8FBC040AC84DEE074BB06C7F9B62830232ACFD9BE8D50E1A2005A40EB510BB64. Она ещё до описанного ниже тарифного fix; финальный APK/hash нужно смотреть в самом свежем результате установки. Ничего не коммитили/не пушили. Последние гарантированные UI evidence `mirror-inquiry-back-to-chat.xml`, `company-catalog-updated.png`, `mirror-request-form.png`, `mirror-inquiry-order-fields.png` (последняя картинка показывает старое обрезание тарифа, до fix).

Дальше: company management translations, owner screens на новом snapshot (старого fakeowner2 теперь нет), full conversion/compact terminal comparison на новом snapshot, финальная визуальная проверка tariff fix. Сервер работает на fresh volumes; snapshot заново не снимать автоматически.

Этот документ актуальнее pause/progress файлов по состоянию базы. Код по-прежнему `feat/redesign-20261013`, никаких fetch/merge1.3.0/push/deploy не выполняли. Mobile изменения после12c8b5f9 пока uncommitted. Чужую правку `redesign-product-flow.md` сохранять отдельно.

## Данные и безопасный запуск

По прямой просьбе пользователя снята свежая база production read-only repeatable-read snapshot и скопировано211 объектов MinIO с SHA256, metadata и tags. Проверен fingerprint всех таблиц/колонок с разрешённой sanitization. Snapshot90 таблиц, 45 пользователей, 79 equipment, 11 bookings, 17 chats, 10 requests. UserDeviceToken не импортирован (0); pending notification deliveries отменены, OTP invalidated. Redis новый пустой. Production не изменяли.

Новые независимые Docker volumes: `prokat-local_fresh_20261029-105724972_{postgres,redis,minio}`. Старые volumes **сохранены**; дополнительно предыдущая БД в `prokat-backend/backups/replica-20261029-105724972/previous-local.dump`. Там же исходный dump без токенов, media objects, manifest, verification.json и rollback.txt. Содержимое персональное: не коммитить/не публиковать.

Активный compose override: `artifacts/resume-20261029/compose.fresh-mirror.yaml`. `scripts/local-start-redesign.ps1` теперь указывает на него; этот wrapper применять и при следующих запусках. Старый cached override вернёт прежние тома (остановив сервисы перед откатом). Не удалять volumes и не запускать старый destructive local-replica-refresh.mjs.

Свежий snapshot не содержал наши discussion/terms колонки. После локальных identity/marker guards применены **ровно две** уже проверенные additive миграции `20261013160000_direct_equipment_inquiries`, `20261028120000_booking_negotiation_terms`. Другие миграции не меняли. Runtime Prisma regenerated, API4000/web3000 healthy. Push/Firebase/business jobs/share analytics off, fake OTP000000. Новые флаги/секреты не выводились и не коммитились.

Скрипт переноса подготовлен в `artifacts/resume-20261029/{prepare-fresh-mirror.cjs,fresh-mirror.mjs}` на основе прежнего проверенного transfer: исправлены пути, выбран cached runtime, удалён destructive down--volumes, сохранена прежняя БД и переключение на новые тома. Это одноразовый runner: **повторно не запускать автоматически**.

## Ручной smoke на S22 и исправления

- Старый fake owner2 отсутствует в новой базе, поэтому прежняя сессия закономерно завершилась. Вошли через local OTP по номеру пользователя; он не был зарегистрирован в snapshot, создан1 локальный клиент. Его заказы/чаты пустые — это не потеря11/17 импортированных записей других аккаунтов. Старые fake QA records остались в прежнем volume.
- Каталог показывает реальные объявления/фото. Проверены профиль/настройки и каталог RU/EN/KK, смена локали без падения, категории/единицы тарифов. Пользовательские имена и описания сохраняются на исходном языке.
- Частное объявление: ⋮ → Report/Block → причины → Other с `LOCAL_QA_ONLY` → отправка → «Жалоба отправлена» → «Не сейчас». Локальная БД подтвердила ровно1 такую Report, блокировка не выполнялась. Продовый report не создавался.
- У карточек компаний UGC отсутствует в прежнем коде (`companyCard`/companyId gate). **Не устранено:** нужен отдельный безопасный сценарий цели жалобы; не выдавать company aggregate id за equipmentId.
- Исправлен пустой белый круг вокруг скрытого UgcMoreButton на собственном объявлении: убрана внешняя декорация, сама кнопка уже рисует заливку. Hidden-for-own/guest ACL оставлены.
- Локализованы заголовок/пустое значение комментария заказа (Flow и legacy обеих ролей), удаление фото; technical guide category теперь пользовательская локализованная подпись. ARB+generated updated.
- На KK замечено fading длинной подписи «Тапсырыстар». Flow label теперь scaleDown без обрезки/переносов; полный semantics label и hit area сохранены. Вне Flow прежний вид. Последний nav APK требует финальной ручной проверки после разблокировки.

## Проверки и пределы

Финальный local1.2.4+26 APK установлен через install-r: SHA256 `81815DD9FA81362BA4E1D19D6671F94CEB23200EBC0E67998347D1BEE1962C6C`. Build log `mirror-navigation-apk.log`. Все5 контейнеров healthy после установки. Backend/web рабочие деревья clean, ни их код, ни production не менялись.

43 targeted tests passed (user_safety, booking layouts, help) +2 navigation checks; analyze No issues до последнего малого nav edit; nav edit compile/build прошёл. Первая четвёрка failure была старым ожиданием русского label при en locale: исправлена на Order comment; layout assertions не ослаблялись. Log `mirror-ui-tests-final.log`, `mirror-navigation-tests.log`, `mirror-analyze.log`.

Полный обход **всех экранов ещё не выполнен**. Открытые долги: company UI содержит hardcoded RU (audit JSON), report company, оставшиеся формы/owner экраны на новом snapshot, компактный terminal consent, визуальная проверка последнего nav APK. Не считать отсутствие missing ARB доказательством полной локализации: все1281 ключи есть, но строки в коде/серверные dynamic labels требуют просмотра. Audit: `artifacts/resume-20261029/localization-audit.json`.

Телефон во время возврата RU ушёл из PROKAT; safety helper остановил ввод. Отправлен async запрос оставить разблокированным в PROKAT. Ожидается KK locale с открытым picker (последний гарантированно видимый экран); вернуть RU при возобновлении. Не переключать чужие приложения/не вводить туда. Сервер оставлен запущенным.
