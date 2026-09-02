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
- `completed` — конец работ; клиент подтверждает заказ

Шит: `BookingStatusSheet` берёт `nextWorkStatuses`. Кнопки — ARB. Тела EVENT и пушей — бэкенд `meta.i18n` / `data.i18n`, не ARB.
