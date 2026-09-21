# Requests

Лента тендера, не заказ. Контракт live: `docs/architecture/workflow-refresh-and-requests.md`.

## Списки

- Клиент: `GET /requests?status=ACTIVE|HISTORY`. Active — `CREATED` / `DRAFT` / `RESPONDED` / `VIEWED`. History — `ACCEPTED` / `CANCELLED` (вкладка истории ещё не в UI).
- `location` в DTO может быть `null` (нет адреса / удалён). Список не должен падать.
- Лимит новой заявки: слот занимают `DRAFT` / `CREATED` / `VIEWED` / `RESPONDED`. `ACCEPTED` не в active и слот не занимает.
- Владелец «Запросы на аренду»: `GET /requests/owner?status=ACTIVE`. Только открытый тендер. После мэтча (`ACCEPTED`) карточка пропадает у всех владельцев. Это чужие тендеры, не «мои отклики».
- Отмена клиентом разрешена только пока тендер открыт: `CREATED` / `DRAFT` / `VIEWED` / `RESPONDED`. `ACCEPTED` → 409, отменять нужно заказ. `CANCELLED` / `EXPIRED` → 409.
- Принятие оффера клиентом из «Мои заявки» (карточка или чат, открытый с неё) переключает раздел на «Мои заказы»; чат остаётся сверху.
- Отмена/expire закрывает только чаты без `bookingId` (`Chat.status=CLOSED`). Живой заказ остаётся `ACTIVE`.

## Live

- Канал тот же, что у заказов: `workflow:update`. Создание и завершение тендера рассылаются всем для обновления ленты владельцев; payload содержит только дельту заявки и `requestClientId`. Данные чатов и офферов — только комнатам участников.
- `WorkflowCacheCoordinator` патчит списки заявок участников: terminal (`CANCELLED` / `EXPIRED`) → убрать из active; history клиента — патч или `invalidate()`.
- Создание обновляет ленту через HTTP; завершение удаляет карточку дельтой. Чужие события не обновляют историю клиента: проверять `requestClientId`. Вход (`refreshIfStale`), pull-to-refresh и resume восстанавливают пропущенные события.
- Resume рефетчит загруженные списки заявок и офферов (`OfferQuery.active|history`).
- Владелец не может создать оффер при нуле оплаченных минут (`CONFLICT:OFFERS:CREATE:BALANCE`).

Счётчик ожидающих решения заявок берётся из `/notifications/navigation-counts`, не из загруженных страниц. Просмотр не уменьшает его; скрытие и активный отклик исключают заявку. Не путать с заказами: отклик ≠ переезд в заказы.
