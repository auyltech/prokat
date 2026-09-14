# Notifications

Тап открывает оболочку роли **в этом событии**, не «аккаунт может быть владельцем».

Текст: `data.i18n` `{ ru, kk, en: { title, body } }`. Если i18n нет — для admin-типов `OWNER_APPROVED` / `OWNER_REJECTED` / `BOOKING_COMPLETED` берём l10n по типу (эти события пишет админка без шаблона API).
В body старые строки с сырым `PER_HOUR` / `PER_TRIP` локализуем на клиенте (`localizePriceRateInNotificationText`).

## Куда ведёт тап

- `data.audience`: `CLIENT` | `OWNER` — сторона сделки у получателя.
- Если audience нет: односторонние типы (ход работ → клиент, `BOOKING_CREATED` / новый запрос → владелец), иначе текущий режим `/client` vs `/owner`.
- Не смотреть на `user.isOwner`: владелец в режиме заказчика иначе всегда уходит в `/owner`.
- Маршрут строит клиент из `type` + `data` (`resolveNotificationRoute`). Backend `route` / `deepLink` не исполняются.

### В чат сделки (`/…/chat/direct/{chatId}`)

При непустом `data.chatId` (через `AppNotification.chatId`):

- сообщения: `CHAT_MESSAGE_*`, `PRICE_NEGOTIATION_MESSAGE_*` (+ legacy `BOOKING_EVENT_MESSAGE_*` / `ADMIN_MESSAGE_*`);
- ход работ: `BOOKING_WORK_STATUS` и legacy `WORK_*` / `CLIENT_CONFIRMATION_REQUIRED`;
- старт операционки: `BOOKING_CONFIRMED` (CTA владельца — в чате);
- legacy counter-offer / negotiation types.

Без `chatId`: chat/price → home уведомлений; work / confirmed → orders/bookings; counter-offer → список чатов.

### Не в чат (даже если в payload есть chatId)

- тендер: `OFFER_*` / `REQUEST_*` → списки заявок;
- терминальный статус заказа: `BOOKING_CANCELLED` / `REJECTED` / `COMPLETED` / `CREATED` → orders/bookings;
- reviews, equipment, moderation, billing — как раньше.

## Типы

`BOOKING_WORK_STATUS` — прогресс работ, шлётся заказчику. `BOOKING_CONFIRMED` после тендера приходит обеим сторонам — без audience смотрим текущий режим.

`OWNER_APPROVED` → `/owner/profile` (режим владельца). `OWNER_REJECTED` → `/client/become-owner` (экран заявки с комментарием модератора).
