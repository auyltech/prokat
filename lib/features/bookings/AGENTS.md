# Bookings

Два статуса, не путать.

## Заказ (`BookingStatus`)

Сделка: `CREATED` → `CONFIRMED` → `COMPLETED` / `CANCELLED` / `REJECTED`.
Отмена задания — это **заказ**: крестик на карточке или «Отклонить заказ». Пишет шаблон в чат, закрывает тред.

## Ход работ (`workStatus`)

Только владелец, только `CONFIRMED`. Повтор того же статуса сервер отклоняет.
`cancelled` как workStatus больше не выставляется; старые значения можно увести в `started` / `stopped` / `completed`.

- `pending` → `onMyWay` | `onSite` | `started` | `postponed`
- `onMyWay` → `onSite` | `started` | `postponed`
- `onSite` → `started` | `postponed`
- `postponed` → `onMyWay` | `onSite` | `started`
- `started` → `stopped` | `completed`
- `stopped` → `started` (возобновить) | `completed`
- `completed` — конец работ; клиент подтверждает заказ.

На карточках «Мои заказы» у владельца нет кнопок хода работ («Начать/Завершить работу» и т.п.) — только принять/отклонить заказ или чат. Операционный пульт выполняемого заказа — чат (`ChatActionBar` / `BookingStatusSheet`).

Карточка частной техники из каталога открывает `CreateBookingScreen` над shell; публичная ссылка `/e/:id` — `GuestCreateBookingScreen` через push. Общий `EquipmentListingContent` сначала показывает объявление; иконка чата открывает обсуждение без заказа, «Отправить запрос» открывает форму. Back из формы возвращает карточку, сохраняя поля. Переход из `InquiryContextCard` с `inquiryChatId` сразу показывает форму условий. Стиль общих контролов включён только внутри `ProkatFlowScope`; компании пока показывают прежний сценарий формы.

Публичная ссылка: тариф, адрес, дата и комментарий заполняются до входа. Отправка формы без сессии пишет UI-intent и durable overlay, открывает вход с `from=/e/<id>` (redirect после OTP → landing, затем один push карточки). После OTP поля из intent; создание заказа автоматически не вызывается. Второй тап: свой `ownerId` — алерт; свежий/ensure GET адресов; совпавший pin → id без `createLocation`; иначе `createLocation`, id в intent до `createBooking`, затем `go` прямо в возвращённый chatId (заказы только fallback старого API). Intent сбрасывается при успехе, выходе, битом JSON, чужом `userId`, 404 и «В каталог». Карта гостя и «Выбрать на карте» у уже вошедшего пользователя на этом экране: `/e/:id/address`, `from: guest_share`, без `createLocation`. Не пушить `/client/addresses/map` — экран ссылки вне shell, второй shell перехватывает нажатия. Форма обоих экранов — `BookingOrderFields`: адрес и тариф — `AppDropdownField` (один тариф предвыбран, без стрелки и без disabled-фона; несколько — пусто и обязательны). Дата/время — общий `JobScheduleSection`.


Шит: `BookingStatusSheet` берёт `nextWorkStatuses`. Кнопки — ARB. Тела EVENT и пушей — бэкенд `meta.i18n` / `data.i18n`, не ARB. `BOOKING_ACTIVE_LIMIT` на создании заказа показывается как `bookingActiveLimitReached`, не английский текст ответа.
