# Пауза редизайна PROKAT — 14 октября 2026

Историческая точка паузы. Пользователь возобновил работу14 октября; текущее состояние описано в [redesign-resume-20261014.md](redesign-resume-20261014.md). Все изменения кода сохраняются в локальных `feat/redesign-20261013` трёх репозиториев. Не push, не merge в dev/main, не deploy. Stash повышения лимита оборудования не применять; остальные stash тоже сохранены.

## Что сохранено

- Mobile: последний commit ветки содержит новую оболочку чата/карточек, закрытие обсуждения, локализацию и этот checkpoint. Первый согласованный экран listing/form ранее сохранён в `acf9cf3d`.
- Backend: `a9a4aca`, participant-only завершение inquiry без заказа, атомарный EVENT/история, гонка close/convert и безопасное имя техники в списке. Первый срез ранее `19ff0cd`.
- Web/admin: `63b3b60`, Prisma relation, обсуждение/завершение/архив в админке, backend DELETE техники, проверки.

Подробности и пределы проверки: [redesign-checkpoint-20261014-chat.md](redesign-checkpoint-20261014-chat.md). На последнем дополнительном backend patch сборка и4 DTO tests прошли. Основные integration/mobile/web проверки описаны в checkpoint; не повторять все без причины.

## Где остановились

Финальная локальная debug сборка поставлена на S22 и визуально проверена после перезапуска. Обсуждение без заказа закрывается через подтверждение, остаётся в архиве с обоими сообщениями и одним EVENT. Исходный CREATED запрос не изменён, отмена и предложение цены остаются доступными.

Последняя обнаруженная деталь: list DTO не возвращает полный `inquiryEquipment`, поэтому название объявления не видно в ChatTile. Backend уже добавляет `inquiryEquipmentName: string | null` (только name, без приватных данных и неполного Equipment object). **Мобильная модель ещё не читает это поле.** Следующий небольшой шаг: добавить nullable поле/fromJson/copyWith, использовать fallback в ChatTile, проверить сохранение при sidebar/workflow merge и реальный архив на S22. После этого показать чат пользователю перед новым экраном. Остальная логика не менялась.

Каталог/парк/общие заявки/компании/календарь/TTL и полный редизайн приложения не выполнены; выполнять по согласованию экран за экраном. Условия пока выбираются из опубликованных тарифов; существующий торг сохранён.

## Локальный сервер перед остановкой

Docker Compose: `C:\Projects\Prokat-Mobile\prokat-backend\compose.local.yaml`, project `prokat-local`. Пять long-running контейнеров были healthy:

| Сервис | Контейнер | Доступ |
| --- | --- | --- |
| Backend | prokat-local-backend-1 | 127.0.0.1:4000 |
| Admin/web | prokat-local-web-1 | 127.0.0.1:3000/login |
| PostgreSQL17 | prokat-local-postgres-1 | 127.0.0.1:5432 |
| Redis7 | prokat-local-redis-1 | 127.0.0.1:6379 |
| MinIO | prokat-local-minio-1 | 127.0.0.1:9000/9001 |

База — ранее восстановленный снимок прода с маркером `local`,48 применённых миграций и добавленными локальными тестовыми фикстурами. Не считать её новым свежим снимком прода; во время редизайна production не меняли. Новый seed message template не запускали (RU/KK/EN fallback работает). Полный импорт всех продовых MinIO изображений не делали.

Код backend смонтирован из `prokat-backend`, web — из **prokat-web**, не `prokatWeb`. Backend запускается `prisma generate` + `npm run dev:watch`; web — Next dev webpack. `.env.local` backend/web/mobile остаются на диске и игнорируются Git; секреты в checkpoint не копировать.

Volumes сохраняются:

- prokat-local_postgres_data
- prokat-local_redis_data
- prokat-local_minio_data
- prokat-local_backend_node_modules
- prokat-local_web_node_modules
- prokat-local_web_next

Остановка штатным `scripts/local-stop.ps1` (`docker compose stop`), без down -v/reset/удаления volumes, без дампов/повторного восстановления БД. На этой машине запуск .ps1 был запрещён ExecutionPolicy; выполнен эквивалент напрямую: Docker CLI `compose -f C:\Projects\Prokat-Mobile\prokat-backend\compose.local.yaml stop -t 30` (без изменения системной политики).

Docker Compose stop завершился успешно, все локальные порты освобождены. PostgreSQL, Redis и MinIO завершились с exit0; volumes сохранились. Dev backend (shell/tsx watcher) не уложился в30с остановки и имеет exit137, dev web — exit1. Это не чистое завершение dev-процессов приложений; при возобновлении проверить штатный старт и health, не считать эти коды ошибкой БД. Docker Desktop сам не завершали; данные и контейнеры оставлены для следующего запуска.

## Телефон и фикстуры

S22 serial `R3CT60F7MRV`,1080x2316. Local API/socket4000 через `adb reverse tcp:4000 tcp:4000`; повторить после подключения. В финале паузы ADB уже не видит телефон. Во время QA временно включали `stay_on_while_plugged_in=2`; исходное значение0. При следующем подключении вернуть0 после QA (в конце паузы устройство было недоступно).

APK: `C:\Projects\Prokat-Mobile\prokat\build\app\outputs\flutter-apk\app-debug.apk`, local `.env.local`/APP_ENV=local, API/socket http://127.0.0.1:4000. Этот APK ещё не использует inquiryEquipmentName.

Только local fake client +77000000001 и owner +77000000002. Исходный запрос: equipment `00000000-0000-4000-8000-202610140001`, booking `08aa6715-0432-4abd-a85f-0aab4a27cc99` CREATED, chat `cmv74mz2k00006sufv9f7l2vy`. Завершённое обсуждение: equipment `00000000-0000-4000-8000-202610140003`, chat `cmv7dtwht0000u8ufc07kbm2e`, CLOSED, Booking0, TEXT2 + EVENT1. Owner восстановлен OFFLINE, fake sessions удалены, billing/balance сохранены. Реальную S22 session не удалять.

Ignored backend `backups/chat-redesign-e2e*`, `backups/redesign-e2e*` содержат скрипты/безопасные результаты фикстур; не коммитить. Не трогать реальные аккаунты и не отправлять реальные push. Кадры mobile `build/redesign-chat-request-final.png`, `build/redesign-chat-closed-final.png`, `build/redesign-chat-archive-final.png` остаются на диске.

## Как поднять вновь

1. Из Codex запускать Docker Desktop через `powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Projects\Prokat-Mobile\prokat-backend\scripts\local-docker-desktop-start.ps1`. Прямой Start-Process из этой среды воспроизводит ошибку AppData AF_UNIX1920; отдельный WMI процесс запускает Engine успешно. Дождаться успешного `docker info`; не вызывать compose до готовности Engine. CLI: `C:\Users\Admin\AppData\Local\Programs\DockerDesktop\resources\bin\docker.exe`.
2. Запустить `powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Projects\Prokat-Mobile\prokat-backend\scripts\local-start.ps1` (policy только для этого процесса, не менять общую политику Windows). Скрипт проверяет local identity/миграции, поднимает прежние volumes, приложения и smoke. Не использовать local-refresh/дамп, если база сохранена.
3. Проверить /health4000 и /login3000, число/маркер миграций при необходимости; подключить S22 и повторить reverse4000. Flutter SDK `C:\src\flutter\bin\flutter.bat`, ADB `C:\Users\Admin\AppData\Local\Android\Sdk\platform-tools\adb.exe`.
4. Продолжить с маленького незавершённого шага имени техники в списке, не начинать аудит/редизайн заново.
