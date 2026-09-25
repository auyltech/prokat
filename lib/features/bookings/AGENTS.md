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

Входящая ссылка `/e/:id` открывает `GuestCreateBookingScreen` поверх текущего экрана (`push`), не `CreateBookingScreen`. Тариф, адрес, дата и комментарий заполняются до входа. Первый «Забронировать» без сессии пишет UI-intent и durable overlay, открывает вход с `from=/e/<id>` (redirect после OTP → landing, затем один push карточки). После OTP поля из intent; сеть не вызывается. Второй тап: свой `ownerId` — алерт; свежий/ensure GET адресов; совпавший pin → id без `createLocation`; иначе `createLocation`, id в intent до `createBooking`, затем `go` на заказы. Intent сбрасывается при успехе, выходе, битом JSON, чужом `userId`, 404 и «В каталог». Карта гостя и «Выбрать на карте» у уже вошедшего пользователя на этом экране: `/e/:id/address`, `from: guest_share`, без `createLocation`. Не пушить `/client/addresses/map` — экран ссылки вне shell, второй shell перехватывает нажатия. Тарифы — общий `ServiceTariffBlock`.


Шит: `BookingStatusSheet` берёт `nextWorkStatuses`. Кнопки — ARB. Тела EVENT и пушей — бэкенд `meta.i18n` / `data.i18n`, не ARB. `BOOKING_ACTIVE_LIMIT` на создании заказа показывается как `bookingActiveLimitReached`, не английский текст ответа.
