# User safety (Report / Block)

Жалоба и блокировка пользователя (Apple Guideline 1.2). Жалоба ≠ блок: жалоба никогда не блокирует, блок никогда не создаёт жалобу. После успешной жалобы только *предлагаем* заблокировать (`notNow`).

## API

- `GET/POST /user-blocks`, `DELETE /user-blocks/:userId`. Блок направленный (`blockerId → blockedId`), проверка взаимодействия на сервере — в обе стороны.
- `POST /reports` `{targetType, targetId, reason, comment?}`. `targetType`: `EQUIPMENT` / `REQUEST` / `CHAT` / `CHAT_MESSAGE`. `USER` клиент не шлёт. Повтор той же жалобы → 200 `duplicate: true`, для UI это тот же успех.
- Владельца контента, автора и снапшот сервер вычисляет сам. Клиент шлёт только id цели.
- Ошибка взаимодействия: код `USER_BLOCKED` (HTTP 409 у брони/оффера, ack сокета у `chat:message:send`). Текст — `interactionUnavailableBody`, без «вас заблокировали».
- Фильтр текста: код `CONTENT_NOT_ALLOWED` (`contentNotAllowedErrorCode`, текст `contentNotAllowed`). Сейчас только `Request.comment` и TEXT в direct-чате. Источник правил один: бэкенд `contentSafety.policy.ts`; на клиенте списков слов нет.

## Состояние

- `userSafetyServiceProvider` (`UserSafetyApi`), `blockedUsersProvider` (`QueryState<BlockedUser>`, scope = сессия), `userSafetyControllerProvider`.
- `UserSafetyController.blockUser`: после 200 убирает автора из уже загруженных лент (`clientEquipmentProvider(group).removeOwnerLocally`, `ownerActiveRequestsProvider(group).removeClientLocally`) + фоновый refresh, `refreshNavigationCounts`, invalidate списка заблокированных, refresh `currentChatProvider(chatId)`.
- `unblockUser`: `removeLocally` в списке + refresh открытых лент + refresh чата.
- Скрытие из ленты — серверный фильтр. Локальное удаление только чтобы карточка исчезла сразу.

## UI

- `UgcMoreButton` (⋮) → `UgcActionsSheet` (Пожаловаться / Заблокировать или Разблокировать) → `ReportSheet` / `confirmAndBlockUser`. Кнопка скрыта у гостя, при пустом id автора и на своём контенте.
- Где стоит: `ClientEquipmentTile`, шапка `CreateBookingScreen` (после блока — `pop`), `OwnerRequestTile`, аппбар открытого direct-чата (`ChatSafetyMenuButton`).
- Чат: собеседник берётся из `chat.blockState.counterpartUserId` (только `GET /chats/id/:id`). `blockState == null` или `SUPPORT` → меню нет.
- Экран `BlockedUsersScreen`: `AppRoutes.clientBlockedUsers` / `ownerBlockedUsers`, вход из настроек над удалением аккаунта.
- Телефон заблокированного не показываем (`phoneNumber: null` в DTO).
