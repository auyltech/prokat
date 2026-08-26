# Workflow

Живые статусы заказа/заявки без новых REST-поллингов. Канал: `workflow:update`.

Решения (рефреш, заявка vs заказ, live списков заявок): `docs/architecture/workflow-refresh-and-requests.md`.

## Поток

1. Bootstrap: `workflowBootstrapProvider` в `lib/app.dart` (рядом с notification/chat sidebar).
2. Fan-out: `WorkflowSocketService` — несколько слушателей на одно событие. Не вешать второй `AppSocketService.on('workflow:update')`: `on()` **перезаписывает** хендлер.
3. Патч кэша: `WorkflowCacheCoordinator.apply`. Дубликаты режет LRU `eventId`.
4. Ресинк REST: после reconnect (не на первом connect) и после возврата из фона (`paused`/`hidden`/`detached` → `resumed`). Сокет рвать только на эти три состояния, не на `inactive`.
5. Обновление данных: сокет пока экран открыт; HTTP — ручной pull-to-refresh, вход на экран (`refreshIfStale`, TTL 30 с — не таймер), разворот приложения. Фоновых `Timer.periodic` нет.

## Что патчится

- Открытый чат: `CurrentChatNotifier.applyWorkflowDelta` (бейдж, лок ввода, `getChatConfig`). Если в payload оффер с новым id — ещё `currentChat.refresh()`.
- Списки чатов: `clientChatsByFilterProvider` / `ownerChatsByFilterProvider` (`ACTIVE` / `ARCHIVED`). Терминальный заказ/заявка → убрать из Active, инвалидировать Archive.
- Заказы: active — патч или remove + decrement; history — патч или `invalidate()`. Guard по `updatedAt`; HTTP-рефреш не затирает более новый сокет.
- Заявки участников: тот же канал и coordinator; terminal → убрать из active, history клиента — патч или `invalidate()`. Лента чужих тендеров у владельца — HTTP, не broadcast.
- Офферы / торг: при наличии в payload — `invalidate` family-провайдеров.

## Список vs тред

Список чатов с бэкенда: `bookingSummary`, полного `booking` нет. Подпись тайла — `getChatConfig` через summary. Тред (`getChatById`) отдаёт `booking`.

Не менять: `notification:new`, `chat:message:new`, `chat:sidebar:update`. Админка (`prokatWeb`) не слушает этот канал.

Бэкенд (соседний репо `prokat-backend`): эмит после коммита транзакции, `io.to(user rooms)`, `src/modules/socket/workflow.broadcast.ts`. Чат-листы: `GET .../chats/{client|owner}?filter=ACTIVE|ARCHIVED`.
