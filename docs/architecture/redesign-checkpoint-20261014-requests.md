# Пауза: клиентские запросы и предложения — 14 октября 2026

Пользователь остановил работу из-за оставшихся 2% лимита. Новые правки, тесты и сборки не запускать до его просьбы продолжить. Этот checkpoint актуальнее прежнего catalog/resume. Ветки всех трёх repo локальные `feat/redesign-20261013`. Push/merge/deploy не выполнялись, equipment-limit stash не применять.

## Текущий срез

Ориентиры пользователя сохранены в `redesign-screen-guidance-20261014.md`: 1 каталог, 2 объявление, 3 форма общего запроса, 4 предложения, 5 чат, 6 парк, 7 запросы владельцев. Сейчас изменяются только клиентская форма общего запроса и список запросов/предложений (3/4), общие визуальные пресеты и необходимая навигация. Backend/web этой итерации не менялись. Согласование адреса/времени и версий условий остаётся отдельным этапом; не считать его реализованным.

Сделано:

- Scoped форма: белая поверхность, navy/blue палитра, category/address icons по смыслу, переключатели цены и групп, крупный бюджет, «Выбрать время» / «Как можно скорее», «Отправить владельцам». Existing payload, лимит одной активной заявки, past/ASAP schedule, обязательный комментарий Other, максимальный бюджет 100000, busy/retry сохранены.
- Компактная карточка запроса: настоящая категория/фото, счётчик загруженных pending offers, адрес, дата, полный комментарий, бюджет, оставшееся время и прежняя отмена с подтверждением. Нет дублирующего RESPONDED badge при положительном счётчике. Null address/date safe в scoped ветке.
- Карточки предложений: реальный владелец/аватар/рейтинг или «Пока без оценок», цена/единица, техника/комментарий, аккуратная иконка чата, Принять/Отклонить с прежними mutations. Существующие статусы/API сохранены.
- Локальное сравнение: оригинальный API order по умолчанию; дешевле/дороже и «Лучшая цена» только после полной загрузки и в одной известной единице. Час/рейс не сравниваются. Все равные минимумы лучшие. Missing/future units и nonpositive prices не выигрывают. Load all использует существующий notifier, остановка при ошибке/no progress. Unit reset остаётся виден при выбранном фильтре даже после live-исчезновения другой единицы.
- DTO parser `parseKnownRateOption` не выдумывает PER_TRIP для null/unknown. Legacy dropdown `parseRateOption` сохранён. Request DTO содержит сумму бюджета без корректной единицы (`offeratePriceRate` пустое legacy поле); на карточке показываем сумму без придуманного `/час`.
- Accept из списка переключает фон на Orders и открывает существующий chatId сверху. Back ведёт в заказы. Accept из уже открытого request chat сохраняет точный верхний маршрут. Router capture до await защищает от размонтирования карточки.
- Общие flow input/button допускают рост высоты при крупном тексте, без потери callback/loading guards. Legacy вид вне scope сохраняется.

## Проверено

46 разных выбранных tests прошли до последней навигационной проверки (41 этого среза и 5 прежних catalog-card regressions); повторные запуски не прибавлять. Формы/лимиты/ошибки, lifetime/cache/mutation, реальные wrapper controls, ties/live updates, unknown units, navigation accept, 320px/textScale2, legacy fallback. Последние 12 form/summary/wrapper tests прошли; затем расширенный live-reset wrapper test прошёл ещё раз. Последние изменённые source и новый navigation test анализировались: No issues found. Не заявлять полный suite или аудит всего приложения.

S22 финальная проверка установленного APK:

- Форма, категория «Экскаваторы», существующий тестовый адрес, выбранные blue budget/ASAP controls и реальный ввод 25000 (после отдельного ожидания клавиатуры). Request submit не нажимался.
- Mixed units требуют выбора тарифа; hour оставляет 25k/22k, low/high порядок подтверждён, Best оставляет 22k и blue badge/border. Иконка чата открывает переписку без Booking (проверено SQL).
- Принятие fake Offer0018 через UI выполнило существующую серверную транзакцию: Request0017 ACCEPTED, Offer0018 ACCEPTED, остальные Offers0019/0020 CLOSED; создан Booking CONFIRMED 22000/PER_HOUR, chat1 ACTIVE с bookingId, chat2/3 CLOSED. Балансы всех трёх тестовых владельцев остались 36000 секунд. Автоматически открылся нужный чат с зелёным подтверждением. Back действительно привёл в «Мои заказы».

Ignored screenshots: `build/redesign-request-form-final.png`, `redesign-request-best-final.png`, `redesign-request-accepted-chat.png`. Filled screenshot `redesign-request-form-filled-final.png` снят слишком рано во время закрытия IME и не показывает введённую сумму; подтверждение реального ввода — `build/requests-budget-typing.xml` (25000). Снимок `redesign-request-offer-chat.png` также не является доказательством открытия: первый Android dump не дождался idle и pull прочитал старый файл; успешное открытие подтверждено свежим отдельным `requests-offer-chat2.xml`. Учитывать ошибки idle, не читать оставшийся старый dump как свежий.

## Незавершённое — начать отсюда

На телефоне после Offer chat → Back фильтры сбросились в All units/original/Best=false, хотя позиция прокрутки вернулась. Это ещё не исправлено подтверждённо.

В исходниках уже удалён неиспользуемый GlobalKey, который `MainScaffold` создавал на каждом новом экземпляре StatelessWidget; конструктор теперь const. **Эта последняя правка НЕ вошла в установленный APK.** Причинность сброса пока не доказана. Stable GlobalKey самого StatefulNavigationShell может сохранять Navigator при reparenting. Другой возможный источник — некейованный nested ListView меняет индекс при conditional error banner, который показывается только в scope. На S22 error banner визуально не было; не предполагать подтверждённую причину.

Добавлен `test/features/layout/request_offer_scope_navigation_test.dart`: реальный MainScaffold, StatefulShellRoute, RequestWithOffers и настоящий OfferTile chat callback + MainAppBar Back; проверяет identity состояния и фильтры. Analyze прошёл, **test FAILED** на line186 `tester.takeException()`: `Null is not a subtype of DateTime`. Fake Request не содержит requiredOn/At, а при переключении scope underlying legacy ClientRequestTile вызывает formatDateTime с null. Пока это мешает оценить сохранение фильтров; не ослаблять assertions/не чинить unrelated legacy поведение только ради test. Сначала задать валидные даты fixture и повторить targeted test; затем доказать и минимально исправить причину remount/reset. Если удаление GlobalKey не решает наблюдение — переоценить правку. Стабилизировать list identity при необходимости.

После исправления: targeted analyze/tests → один финальный local debug build → install-r → S22 hour+Best → chat → Back с сохранённым фильтром. После этого можно оставить активный preview и сделать локальный завершённый commit с подтверждённой проверкой. Пользователю показать именно этот срез перед дальнейшими экранами.

## Локальные fixtures и среда

API4000/web3000/PG5432/Redis6379/MinIO9000/9001, пять prokat-local контейнеров healthy при паузе, сервер **оставлен работающим**. Volumes/snapshot не удалять, не reset/seed whole DB, prod не трогать. Docker восстановление — backend `scripts/local-docker-desktop-start.ps1` через скрытый WMI; затем `local-start.ps1`, как описано в resume. Прямой Start-Process из Codex ранее вызывал ошибку AF_UNIX AppData sockets.

БД marker local. Fixtures созданы только в ней INSERT-only guarded SQL, без пушей/сообщений реальным владельцам:

- Client f95afdcc-f3dc-4af2-84f6-d00fbc5860d7 (+77000000001), original fake owner d04045ec-0b83-4fa3-b0c0-64670ae221e8 (+77000000002), новые fake owners UUID suffix202610140005/0006 (+77000000003/4), OFFLINE, no tokens.
- UUID prefix `00000000-0000-4000-8000-20261014`: Equipment0003/0013/0014, address0002, Request0017, Offers0018/0019/0020. ChatIDs `redesign_request20261014_chat1/2/3`.
- Новый Booking после реального accept: `42c2da12-f0d9-4214-9da0-d10933e3ef69`, CONFIRMED. Не откатывать его для preview, не переоткрывать закрытые чаты.
- `build/redesign-request-fixtures.sql` уже выполнен; `build/redesign-request-verify.sql` только read-only. Старые Booking08aa6715-0432-4abd-a85f-0aab4a27cc99 CREATED и CLOSED inquiry cmv7dtwht0000u8ufc07kbm2e сохраняются.
- **`build/redesign-request-preview.sql` подготовлен/прочитан, но НЕ выполнен.** Guard первой заявки ACCEPTED/no other active, fresh Request0023, Offers0024/25/26, chatIDs `redesign_request20261014_preview1/2/3`, те же fake owners/equipment. Перед выполнением повторно проверить guards. Только INSERT, прежний Booking сохраняется.

S22 R3CT60F7MRV: APK debug с local endpoints127.0.0.1:4000 установлен install-r, тестовый аккаунт сохранён, reverse4000 есть. APK SHA256 `C28F41755F757659CCF0D81FC173A029874294475BF138AD52EC7F9C16362FB4` (unit chooser live-reset включён, последняя MainScaffold key правка отсутствует). FlutterSDK single queue, только require_escalated; другие агенты SDK не запускают. Все начатые SDK команды завершились, процессов этой итерации не оставлено.

USB stay-awake был временно2, возвращён в исходное0 и прочитан обратно. Телефон оставлен в форме нового запроса с черновиком категории/адреса/budget25000/ASAP, клавиатура закрыта; запрос не отправлен. При продолжении не просить новый тестовый вход — аккаунт уже есть, пользователь разрешил использовать/создавать тестовые аккаунты самостоятельно.

Checkpoint сохранён WIP commit: последний route regression test ещё падает, весь срез завершённым не считать. Backend HEADc18a8e1/web63b3b60 без новых правок; последний законченный mobile catalog commit3d5b9d9e. Продолжать от текущего WIP, не повторять каталог или восстановление БД заново.
