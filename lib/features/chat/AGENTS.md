# Chat

Тред сделки, не каталог. Список vs открытый чат: `lib/features/workflow/AGENTS.md`.

## Статус треда

`getChatConfig` берёт booking (в списке — `bookingSummary`), иначе заявку **этого** треда.

- `ACCEPTED` без booking на треде = выбран другой владелец (`offernotselected`), не «Booking Created».
- Карточка оффера только если `service: OFFER` и в `meta` есть `id` (DTO оффера). EVENT проигрыша тендера (`reason: NOT_SELECTED`, текст поддержки) рисуется как обычное сообщение; превью списка берёт `lastMessage.content`.
- Кнопка Cancel Request только у клиента на `requestcreated`. У `requestaccepted` / `offernotselected` действий нет.
- Архив списка и лок ввода: `Chat.status` (`closed` / `archived`). `SUPPORT` всегда Active и не лочится. `ChatParticipant.isArchived` не используется.

## Ввод

`isChatInputLocked` в `get_chat_status.dart`. Композер скрыт при `Chat.status` closed/archived и для `workcompleted`, `leaveReview`, `bookingcancelled`, `bookingreviewed`, `requestcancelled`, `offernotselected`. На `leaveReview` остаётся панель Review без поля ввода; клавиатура закрывается.

Сервер режет `chat:message:send`, если `Chat.status` не `ACTIVE`. `SUPPORT` не блокируется.
