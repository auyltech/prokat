# Chat

Тред сделки, не каталог. Список vs открытый чат: `lib/features/workflow/AGENTS.md`.

## Статус треда

`getChatConfig` берёт booking (в списке — `bookingSummary`), иначе заявку **этого** треда.

- `ACCEPTED` без booking на треде = выбран другой владелец (`offernotselected`), не «Booking Created».
- Кнопка Cancel Request только у клиента на `requestcreated`. У `requestaccepted` / `offernotselected` действий нет.
- `Chat.status` и `ChatParticipant.isArchived` не используются. Архив списка: terminal booking, либо `CANCELLED`/`EXPIRED` заявки при `bookingId == null`. Живой заказ при отменённой заявке в Active остаётся.

## Ввод

`isChatInputLocked` в `get_chat_status.dart`. Композер скрыт для `workcompleted`, `bookingcancelled`, `bookingreviewed`, `requestcancelled`, `offernotselected`.

Сервер тоже режет `chat:message:send` на тех же terminal-тредах. `SUPPORT` не блокируется. Одна только вкладка Archive ввод не запирает.
