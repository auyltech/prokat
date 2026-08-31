# Requests

Лента тендера, не заказ. Контракт live: `docs/architecture/workflow-refresh-and-requests.md`.

## Списки

- Клиент: `GET /requests?status=ACTIVE|HISTORY`. Active — `CREATED` / `DRAFT` / `RESPONDED` / `VIEWED` / `ACCEPTED`. History — только `CANCELLED`.
- `location` в DTO может быть `null` (нет адреса / удалён). Список не должен падать.
- Лимит новой заявки: слот занимают `DRAFT` / `CREATED` / `VIEWED` / `RESPONDED`. `ACCEPTED` остаётся в active, но не блокирует создание следующей.
- Владелец «Запросы на аренду» (будущий таб «Все»): `GET /requests/owner?status=ACTIVE`. Без `CANCELLED` / `EXPIRED`. Это чужие тендеры, не «мои отклики».
- Отмена клиентом разрешена только пока тендер открыт: `CREATED` / `DRAFT` / `VIEWED` / `RESPONDED`. `ACCEPTED` → 409, отменять нужно заказ. `CANCELLED` / `EXPIRED` → 409.
- Отмена/expire закрывает только чаты без `bookingId` (`Chat.status=CLOSED`). Живой заказ остаётся `ACTIVE`.

## Live

- Канал тот же, что у заказов: `workflow:update`. Комнаты участников (клиент + владельцы с чатом). Не broadcast на всех владельцев.
- `WorkflowCacheCoordinator` патчит списки заявок участников: terminal (`CANCELLED` / `EXPIRED`) → убрать из active; history клиента — патч или `invalidate()`.
- Лента чужих тендеров без чата обновляется HTTP: вход (`refreshIfStale`), pull-to-refresh, resume-ресинк.

Не эмитить `createRequest` в workflow. Не путать с заказами: отклик ≠ переезд в заказы.
