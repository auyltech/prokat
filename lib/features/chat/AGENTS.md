# Chat

Тред сделки, не каталог. Список vs открытый чат: `lib/features/workflow/AGENTS.md`.

## Статус треда

`getChatConfig` берёт booking (в списке — `bookingSummary`), иначе заявку **этого** треда.

- `ACCEPTED` без booking на треде = выбран другой владелец (`offernotselected`), не «Booking Created».
- Кнопка Cancel Request только у клиента на `requestcreated`. У `requestaccepted` / `offernotselected` действий нет.
- Архив списка и лок ввода: `Chat.status` (`closed` / `archived`). `SUPPORT` всегда Active и не лочится. `ChatParticipant.isArchived` не используется.

## Ввод

`isChatInputLocked` в `get_chat_status.dart`. Композер скрыт при `Chat.status` closed/archived и для `workcompleted`, `bookingcancelled`, `bookingreviewed`, `requestcancelled`, `offernotselected`. `leaveReview` остаётся на закрытом треде после `COMPLETED`.

Сервер режет `chat:message:send`, если `Chat.status` не `ACTIVE`. `SUPPORT` не блокируется.
