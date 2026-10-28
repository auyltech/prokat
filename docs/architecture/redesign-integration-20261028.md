# Редизайн после объединения с dev — 28 октября 2026

Пользователь возобновил работу и разрешил локально объединить актуальный dev с редизайном. Этот документ заменяет указание о паузе из checkpoint 14 октября. Рабочая ветка всех трёх repo — `feat/redesign-20261013`. Публикация веток, production deployment и выпуск в магазины не выполнялись.

## Интеграция

- Mobile dev `62d384e5`, backend dev `c2cbeea`, web dev `85a098b`. Локальные dev обновлены, перед объединением сохранены `backup/redesign-pre-dev-20261028` и `backup/dev-pre-redesign-20261028`.
- Сохранены новые release workflows, update prompts, публичные ссылки, квоты, серверные административные команды и защита одновременных изменений заказа.
- При создании заказа сохранены inquiryChatId и возвращаемый chatId; локальная share analytics отключается новым флагом. Заказ из обсуждения остаётся в том же чате.
- Административное удаление использует новый backend endpoint; inquiry history теперь блокирует hard delete и через этот endpoint.
- Исправлено переключение underlying request screen на старую тему при открытии клиентского чата. Регрессия проверяет реальный переход и возврат, сохранение state и фильтров предложений.
- Оформление каталога, объявления, формы заявки, предложений и чата сохранено. Версии условий с согласованием адреса/времени остаются отдельным незавершённым этапом.

## Проверки

- Flutter: полный suite 1291 passed / 3 skipped; analyze без замечаний; local config и inquiry booking regression прошли; debug APK собран.
- Backend: build и typecheck; 116 выбранных регрессий; 11 PostgreSQL inquiry lifecycle tests, включая защиту истории при удалении администратором.
- Web: typecheck и production build; после обновления старого delete-контракта 23 inquiry/media/schema tests прошли; 19 дополнительных TypeScript tests прошли. Предшествующий полный прогон имел одну именно эту ошибку; повторного полного прогона после исправления не было.

## Локальная среда

Пять сервисов `prokat-local` healthy: API4000, web3000, PostgreSQL5432, Redis6379, MinIO9000/9001. Исходные data volumes сохранены. После интеграционных тестов 32 пользователя / 30 device tokens, как до них. Нет restore dump, reset или общего seed.

Docker восстановлен штатной остановкой, завершением WSL без запущенных дистрибутивов и стартом через backend helper. Из-за недоступной загрузки закреплённых registry images используется локальный compose override с прежними cached datastore images и отдельными dependency volumes.

Повторный запуск из корня workspace:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Projects\Prokat-Mobile\scripts\local-start-redesign.ps1
```

Без `-Build` используются уже подготовленные app images. Обычная остановка — существующий backend local-stop helper, без удаления volumes. Env приведён к новому local-replica контракту; внешние Firebase credentials заменены локальными заглушками, push в реальную систему исключён. Прежние env сохранены в игнорируемых `.env.local.pre-dev-20261028`. Не печатать env или переносить его в Git.

Подробные результаты и operational helpers: `C:\Projects\Prokat-Mobile\artifacts\integration-20261028\README.md`.

## Телефон и следующий шаг

S22 `R3CT60F7MRV`, package `com.auyltech.prokat`: обновлён с 1.2.2+18 до **1.2.4+26**, install-r без очистки данных. APP_ENV=local, API/socket127.0.0.1:4000, reverse4000/3000, Firebase/push выключены. APK SHA256 `FC5544AF7FB9F7FD3F139882B60CC250B9E7685F28A2ECA7D89BB01481F7692B`.

Запуск Activity успешен, но устройство показало keyguard и чёрный screenshot. Пользователю отправлена просьба разблокировать; ручную визуальную проверку пока не считать выполненной. Следом проверить заявки/предложения → чат → Back и фильтры на устройстве, показать пользователю этот срез перед следующим экраном.

Тестовый клиент +77000000001 / local OTP000000 уже существует; входить самостоятельно при необходимости. Существующий принятый Request0017 и Booking42c2da12 не откатывать. Подготовленный `build/redesign-request-preview.sql` до сих пор не выполнялся: перед использованием перечитать guards, даты и состояние локальной БД. Только fake accounts, без сообщений реальным владельцам.

Пользовательская незакоммиченная правка `redesign-product-flow.md` возвращена после merge commit и оставлена unstaged. Исходные байты сверены с отдельной резервной копией; временный stash `f298924375efaf53ee075c3d8d1bfcdb70d98627` после этого удалён. Прежние stashes, включая equipment-limit, не применять.
