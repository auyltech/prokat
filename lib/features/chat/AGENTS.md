# Chat

Тред сделки, не каталог. Список vs открытый чат: `lib/features/workflow/AGENTS.md`.

## Сообщения

HTTP `GET /chats/id/:id/messages` не ждёт handshake сокета. `chat:join` только для live. Отказ connect не роняет историю. Handshake `Not authorized` пишется в Crashlytics (`reason: socket_connect`). В нотифаере сообщений читать `AsyncValue.valueOrNull`, не `value`.

## Статус треда

`getChatConfig` берёт booking (в списке — `bookingSummary`), иначе заявку **этого** треда.

- Список: `getChatConfig` с `mode`. На `workcompleted` у владельца бейдж «ждёт подтверждения», не CTA клиента.
- `ACCEPTED` без booking на треде = выбран другой владелец (`offernotselected`), не «Booking Created».
- Карточка оффера только если `service: OFFER` и в `meta` есть `id` (DTO оффера). EVENT проигрыша тендера (`reason: NOT_SELECTED`, текст поддержки) рисуется как обычное сообщение; превью списка берёт `lastMessage.localizedContent(locale)`, не сырой `content`.
- Системные EVENT: `meta.i18n = { ru, kk, en }` (тела) + `templateKey` + `params`. `content` — RU fallback для старых клиентов. Не затирать DTO в `meta` (оффер/бронь).
- Ход работ (`workStatus`): в тред уходит EVENT на каждый валидный переход (в пути / на объекте / начал / отложил / пауза / возобновил / выполнена). Отмена задания — не workStatus, а `BookingStatus` reject/cancel.
- Кнопка Cancel Request только у клиента на `requestcreated`. У `requestaccepted` / `offernotselected` действий нет.
- Архив списка и лок ввода: `Chat.status` (`closed` / `archived`). `SUPPORT` всегда Active и не лочится. `ChatParticipant.isArchived` не используется.

## Ввод

`isChatInputLocked` в `get_chat_status.dart`. Композер скрыт при `Chat.status` closed/archived и для `workcompleted`, `leaveReview`, `bookingcancelled`, `bookingreviewed`, `requestcancelled`, `offernotselected`. На `leaveReview` остаётся панель Review без поля ввода; клавиатура закрывается.

Сервер режет `chat:message:send`, если `Chat.status` не `ACTIVE`. `SUPPORT` не блокируется.
