# Возобновление редизайна — 14 октября 2026

Работа возобновлена по просьбе пользователя. Ветки всех трёх repo по-прежнему локальные `feat/redesign-20261013`; push/merge/deploy не разрешены. Stash оборудования не применять. Предыдущие срезы сохранены в mobile448cf344, backenda9a4aca, web63b3b60.

## Среда восстановлена

Сохранённые PostgreSQL/Redis/MinIO volumes подняты без удаления/нового импорта. БД: markerlocal,48 finished migrations,90 public tables. Проверено прежнее CLOSED обсуждение `cmv7dtwht0000u8ufc07kbm2e`. Pending migrations нет. Штатный local-start прошёл, включая health/MinIO/admin/OTP smoke. Секреты/тестовые коды из вывода скрыты.

Пять long-running контейнеров projectprokat-local healthy. API http://127.0.0.1:4000, web http://127.0.0.1:3000/login, PostgreSQL5432, Redis6379, MinIO9000/9001. Код backend из prokat-backend, web из prokat-web. Существующие fixtures остаются на месте; prod не трогали.

## Причина повторного сбоя Docker

Прямой запуск Docker Desktop из процесса Codex снова завершился ошибкой доступа к `sailor-ingest.sock`. Из агентского процесса fsutil вернул1920; отдельный скрытый Windows/WMI процесс прочитал тот же файл с AF_UNIX tag0x80000023. Штатный stop зависшего Desktop не сработал, force stop завершился; приложения PROKAT в этот момент ещё не запускались.

После запуска Docker Desktop через Win32_Process.Create Engine29.7.2 стал доступен. Сокеты/каталоги/volumes не удаляли и не переименовывали; factory reset не делали. Наблюдение совпадает с [отчётом о MSIX AppData context](https://github.com/openai/codex/issues/52698); вывод о конкретной ошибке Windows kernel/повреждении диска не делаем.

Для следующего запуска сохранён backend `scripts/local-docker-desktop-start.ps1`: проверяет уже работающий Engine, при необходимости запускает Desktop скрытым WMI процессом, ждёт готовность, не создаёт второй Desktop при наличии процессов. Готовность при уже запущенном Engine проверена самим скриптом; холодный запуск через тот же WMI вызов проверен в этой сессии.

Команды запуска:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Projects\Prokat-Mobile\prokat-backend\scripts\local-docker-desktop-start.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Projects\Prokat-Mobile\prokat-backend\scripts\local-start.ps1
```

ExecutionPolicy только для процесса. local-start/local-smoke могут печатать тестовый пароль/OTP; в tool выводе фильтровать строки Admin credentials/Test OTP, не копировать их в чат/отчёт.

## Завершение маленького шага списка

Mobile ChatModel теперь читает nullable `inquiryEquipmentName` из настоящего list DTO. ChatTile выбирает full inquiryEquipment.name, иначе строку списка. HTTP merge сохраняет прежнее имя при отсутствии поля; sidebar/workflow updates используют copyWith. Частичный Equipment object не передаётся и не создаётся.

32 targeted tests прошли (8 новых JSON/parser/sidebar/workflow/HTTP/UI регрессий + прежние выбранные), analyze4 файлов — No issues found. Повторный полный аудит/полный suite не нужен: логика бронирования и статусы этого шага не менялись.

S22 `R3CT60F7MRV` подключён, reverse4000 восстановлен. Отложенная на паузе настройка stay_on_while_plugged_in возвращена в0. Обновлённый local debug APK собран и установлен через install-r с сохранением аккаунта.

Проверено на телефоне: в active списке видно «Газель · тест редизайна», в архиве — «Автокран · тест чата» и «Обсуждение завершено». Архивный тред открывается с обоими прежними TEXT, EVENT и read-only footer. Screenshots: build/redesign-chat-active-with-listing.png, build/redesign-chat-archive-with-listing.png, build/redesign-chat-closed-resume.png. Данные чатов при этой проверке не изменялись.

Список чатов в целом ещё использует прежний дизайн и подписи Booking (CREATED — «Заказ создан»); новый тред/Booking card показывают «Запрос ожидает ответа». Упрощение списка и единые пользовательские названия — следующий визуальный срез, не изменение серверных статусов.

## Дальше

Показать пользователю новый чат/запрос для согласования; S22 QA этого шага завершён. Затем следующий экран по очереди; пока не менять каталог/парк/компании/календарь без обсуждения. Предыдущие guards/Booking actions и ограничения из [chat checkpoint](redesign-checkpoint-20261014-chat.md) сохраняются. Локальный сервер оставить работающим для проверки пользователем.
