# Requests

Лента тендера, не заказ. Контракт live: `docs/architecture/workflow-refresh-and-requests.md`.

## Списки

- Клиент: `GET /requests?status=ACTIVE|HISTORY`. Active — `CREATED` / `DRAFT` / `RESPONDED` / `VIEWED` / `ACCEPTED`. History — только `CANCELLED`.
- Владелец «Запросы на аренду» (будущий таб «Все»): `GET /requests/owner?status=ACTIVE`. Без `CANCELLED` / `EXPIRED`. Это чужие тендеры, не «мои отклики».
- Отмена клиентом → `CANCELLED`. В ленте владельца карточки быть не должно.

## Live

- Канал тот же, что у заказов: `workflow:update`. Комнаты участников (клиент + владельцы с чатом). Не broadcast на всех владельцев.
- `WorkflowCacheCoordinator` патчит списки заявок участников: terminal (`CANCELLED` / `EXPIRED`) → убрать из active; history клиента — патч или `invalidate()`.
- Лента чужих тендеров без чата обновляется HTTP: вход (`refreshIfStale`), pull-to-refresh, resume-ресинк.

Не эмитить `createRequest` в workflow. Не путать с заказами: отклик ≠ переезд в заказы.
