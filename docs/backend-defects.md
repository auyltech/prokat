# Недостатки бэкенда (для агента `prokat-backend`)

Живой список дефектов, которые **нельзя закрыть правками Flutter-клиента** (или клиентский workaround хуже, чем исправление API/данных).

Аудитория: LLM-агент с доступом к репозиторию `prokat-backend` и Docker-контейнерам (API, Postgres, seed). Пишите правки в бэкенде; клиентское приложение — соседний репо `prokat`.

## Как пользоваться этим файлом

1. Берите пункты со статусом `open`.
2. Не ломайте текущий JSON-контракт без явной миграции: клиент уже парсит поля ниже.
3. После фикса поставьте статус `fixed`, укажите коммит/PR бэкенда и как проверить.
4. Новые находки добавляйте **в конец списка** по шаблону внизу. Не удаляйте закрытые пункты — нужен след.

Поддерживаемые языки клиента: `ru`, `kk`, `en` (`lib/l10n`, `locale_provider.dart`).

---

## BE-001 — Имена характеристик техники (`specs[].name`) только на английском

**Статус:** `fixed`  
**Бэкенд:** `prokat-backend` ветка `feat/equipment-demand-survey`, коммит `6fedbd7` (локально, ещё не в remote).  
**Дата фикса:** 2026-08-26.

Fallback локали без `locale`/`lang`/`Accept-Language`: **`ru`**.

Сериализация: `name` уже локализован; дополнительно `names: { en, ru, kk }` на категории и на `specs[]`.

### Проверка

1. `GET /equipment/guest` без языка: `tank_volume.name` = `Объём цистерны`, `hose_length.name` = `Длина рукава`.
2. `Accept-Language: en` → английские подписи; `kk` → казахские; `?locale=ru` тоже работает.
3. `GET /categories` без заголовка — русские названия категорий (`Вакуумные машины`, не `Vacuum Trucks`).
4. PATCH values specs не затирает `CategorySpec.names`.

### Почему это бэкенд, а не Flutter

Клиент **не имеет** строк `Tank Volume` / `Hose Length` в `app_ru.arb` / `app_kk.arb`. Карточка печатает поле API как есть:

- виджет: `lib/features/equipment/widgets/client_equipment_tile.dart` → `"${spec.name}: ${spec.value}"`;
- модель: `lib/features/equipment/models/equipment_spec.dart` → `name: json["name"]`;
- то же `name` в форме владельца: `lib/features/equipment/widgets/owner/owner_equipment_specs.dart`.

Имя характеристики **не вводит владелец**. Владелец шлёт только значения. Шаблон имени живёт в справочнике категории (`CategorySpec`) и копируется/резолвится в `Equipment.specs[]` при GET техники.

Обновление значений (имя не передаётся):

- `PATCH`/`POST`-эквивалент клиента: путь `/equipment/{equipmentId}/specs`;
- тело: `{ "id": "<equipmentId>", "specs": [ { "specId", "value", "categorySpecId" } ] }`  
  (`EquipmentSpecUpdateInput`).

### Текущий контракт, который клиент уже парсит

Каждый элемент `equipment.specs[]` (и аналогичный шаблон категории):

| Поле | Тип | Смысл |
|---|---|---|
| `id` | string | id характеристики на единице техники |
| `name` | string | **человекочитаемая подпись**, сейчас EN |
| `key` | string | машинный ключ (стабильный id для логики; не показывать пользователю, если есть `name`) |
| `unit` | string | единица (`m³`, `m`, …) |
| `value` | string \| null | значение, заданное владельцем (`8`, `10`) |
| `iconLibrary`, `iconName` | string | иконка пилюли |
| `categoryId` | string | категория |
| `inputType` | string | напр. `TEXT` / число |
| `isRequired` | bool | |
| `sortIndex` | int | порядок на карточке (клиент берёт до 4 штук) |
| `imageUrl` | string | |

Точный `key` для «Tank Volume» / «Hose Length» в клиенте не зашит. Ищите в seed/миграциях/админке категории (цистерны, вакуумные машины, КО-505 и т.п.) записи, у которых `name` равен этим английским фразам или `key` вроде `tank_volume` / `tankVolume` / `hose_length` / `hoseLength`.

### Ожидаемое поведение

В UI на `ru` должно быть по-русски, на `kk` по-казахски, на `en` можно оставить английский.

Примеры целевых подписей (уточните стиль по остальному каталогу, но смысл такой):

| EN (сейчас) | ru | kk |
|---|---|---|
| Tank Volume | Объём цистерны | Цистерна көлемі |
| Hose Length | Длина рукава | Шланг ұзындығы |

Значение (`8`, `10`) и `unit` не переводить как часть `name`. Формат на карточке: `{локализованное имя}: {value}`. Единицу клиент в пилюле поиска сейчас **не** дописывает — только `name` и `value`. Не вшивайте единицу внутрь `name`.

Распространите исправление на **все** шаблоны `CategorySpec`, не только эти два ключа: та же дыра будет у любой характеристики, заведённой по-английски.

То же для `category.name`, если категории в списках тоже приходят одним английским `name` (клиент: `lib/features/categories/models/category.dart`). Названия **конкретной единицы** (`equipment.name`, «Kamaz Vacuum Truck KO-505A») — пользовательский/карточечный текст, **не** переводить каталогом характеристик, пока продукт явно не попросит.

### Как сделать в бэкенде (однозначный контракт)

Сделайте **оба** слоя, чтобы не ждать отдельного релиза клиента и не сломать старые сборки:

1. **Данные.** В справочнике `CategorySpec` (таблица/коллекция, откуда берётся `name`) храните переводы `en` / `ru` / `kk`. Прогоните seed + миграцию существующих строк. Не оставляйте только английский литерал в `name`.
2. **Сериализация GET техники и GET категории.**  
   - Поле `name` должно быть **уже локализовано** под язык запроса (обратная совместимость: Flutter продолжит печатать `spec.name`).  
   - Дополнительно отдайте карту, например `names: { "en": "...", "ru": "...", "kk": "..." }` (или `nameI18n`). Старый клиент лишнее поле проигнорирует.
3. **Выбор локали запроса**, по приоритету:  
   1. query `locale` / `lang` (`ru` \| `kk` \| `en`);  
   2. заголовок `Accept-Language` (взять первый поддерживаемый тег `ru` / `kk` / `en`);  
   3. fallback `en` или `ru` — зафиксируйте один в коде и в этом пункте после реализации.  
   
   Сейчас Flutter **не** шлёт `Accept-Language` (`ApiInterceptor` + `ClientRequestMetadataService`: только `Authorization`, `Accept`, `X-Client-Platform`, версия, installation id, App Check). Пока заголовка нет, либо используйте fallback, удобный для прод-аудитории (Казахстан → `ru`), либо оставьте `names.*` и отдельно попросите клиент начать слать язык. **Нельзя** считать задачу закрытой, если `name` на GET без заголовка остаётся `"Tank Volume"`.
4. **Не** требуйте от владельца переводить подписи при PATCH specs. Меняется только `value`.
5. Инвайрианты: `key` стабилен; смена `id` шаблона сломает `categorySpecId` у существующей техники.

### Где искать в `prokat-backend` (ориентиры)

Клиентский указатель на соседний репо: `lib/features/workflow/AGENTS.md` (`prokat-backend`). Ищите:

- модели/DTO `CategorySpec`, `EquipmentSpec`, `specs`;
- seed/fixtures категорий и характеристик;
- сериализаторы GET `/equipment`, GET списка для клиента/гостя, GET категории;
- модуль категорий (admin/seed).

### Проверка в Docker

1. Поднять стек как обычно (`docker compose` API + Postgres; при необходимости seed).
2. Найти единицу техники с цистерной/рукавом (как в UI: вакуумная машина, значения 8 и 10).
3. `GET` этой техники **без** `Accept-Language`: `name` характеристик не должен остаться голым английским, если выбран fallback `ru`; либо в JSON есть `names.ru`.
4. `GET` с `Accept-Language: ru` → `Tank Volume` / `Hose Length` нет; русские подписи + те же `value`.
5. `GET` с `Accept-Language: kk` и `en` — соответствующие подписи.
6. `GET` с `Accept-Language: ru` списка поиска (тот же endpoint, что кормит экран «Поиск») — пилюли на карточке локализованы.
7. PATCH values specs не затирает переводы шаблона.

### Критерий готовности

Русский UI Flutter без клиентского словаря ключей показывает русские подписи характеристик. Английский UI — английские. Казахский — казахские. Старый клиент, читающий только `name`, не падает.

---

## BE-002 — В `GET /offers` у `owner` пустые имя, аватар, рейтинг и счётчики

**Статус:** `fixed`  
**Бэкенд:** `prokat-backend` ветка `feat/equipment-demand-survey`, коммит `6fedbd7` (локально, ещё не в remote).  
**Дата фикса:** 2026-08-26.

`getOfferDTO` берёт `getOwnerPublicDTO(equipment.owner)` (`OwnerProfile`). `orderCount` ← `completedOrderCount`; `rating`/`ratingAverage` ← `ratingAverage`; `ratingCount` отдельно.

### Проверка

1. `GET /offers` под клиентом: у `owner` есть `firstName`/`lastName`/`imageUrl` из `OwnerProfile`, даже если `UserProfile` пустой.
2. `orderCount` совпадает с `completedOrderCount`, а не с `ratingCount`.
3. Карточка заказа (`booking.owner`) и карточка отклика выглядят одинаково.

### Симптом

Клиент видит номер телефона вместо имени откликнувшегося владельца. Аватар, рейтинг и количество заказов/отзывов часто нулевые/плейсхолдеры.

Регистрация в приложении — по телефону; **имя и псевдоним не обязательны**. В JSON `firstName`/`lastName`/`username` часто пустые, `phoneNumber` есть всегда. Старый клиент в `UserModel.displayName` подставлял телефон как публичное имя.

### Почему бэкенд (дополнительно)

Пустое имя — ожидаемые данные, пока нет обязательного публичного имени. Отдельно: `GET /offers` может **не отдать** имя даже если оно есть в `OwnerProfile`.

`GET /offers` грузит технику через `equipmentListItemSelect`:

```ts
owner: { include: { ownerProfile: true } }
```

Имя, фото, рейтинг владельца живут в `OwnerProfile` (`firstName`, `lastName`, `profileImageUrl`, `ratingAverage`, `ratingCount`, `completedOrderCount`).

Сериализация оффера берёт **не тот** маппер:

- `src/modules/offers/offers.dto.ts` → `getOfferDTO` → `owner: getUserPublicDTO(data.equipment?.owner)`
- `getUserPublicDTO` (`src/modules/auth/auth.dto.ts`) читает **`user.profile`** (`UserProfile`), а не `ownerProfile`
- `profile` в этом include **нет** → в JSON уходят пустые `firstName`, `lastName`, `imageUrl`, нули в `ratingAverage` / `ratingCount` / `orderCount`
- с `User` остаётся в основном `phoneNumber` (и id/role)

Тот же `equipmentListItemSelect` в **бронировании** маппится правильно:

- `src/modules/booking/booking.dto.ts` → `owner: getOwnerPublicDTO(data.equipment.owner)`
- `getOwnerPublicDTO` читает `ownerProfile.*`

### Текущий контракт, который клиент уже парсит

`OfferModel.owner` → `UserModel.fromJson` (`lib/features/auth/models/user_model.dart`):

| JSON поле | Куда на клиенте |
|---|---|
| `firstName`, `lastName` | публичное имя |
| `username` | псевдоним, если имени нет |
| `imageUrl` | аватар |
| `rating` **или** `ratingAverage` | звезда |
| `orderCount` | «N orders» |
| `phoneNumber` | контакт, **не** подпись карточки |

`UserPublicDTO` отдаёт `imageUrl` и `ratingAverage`. Если публичное имя в профиле не задано, клиент больше не подставляет телефон — показывает локализованный fallback («Владелец» / «Клиент»).

Если имя **заполнено в `OwnerProfile`**, его всё равно нужно отдавать в `owner` оффера (см. маппер ниже). `OwnerPublicDTO` совместим: `firstName`/`lastName`/`imageUrl`/`rating`/`orderCount`.

### Ожидаемое поведение

В каждом элементе `GET /offers` и `GET /offers/owner` объект `owner` должен содержать публичные данные **владельца техники**, как в `GET` бронирования:

- имя: `OwnerProfile.firstName` + `lastName` (для `BUSINESS` — ещё `companyName`, чтобы клиент мог показать его, если имени нет)
- `imageUrl` ← `OwnerProfile.profileImageUrl`
- `rating` / `ratingAverage` ← `OwnerProfile.ratingAverage`
- `ratingCount` ← `OwnerProfile.ratingCount`
- `orderCount` ← `OwnerProfile.completedOrderCount` (в текущем `getOwnerPublicDTO` в `orderCount` ошибочно кладётся `ratingCount` — поправить и здесь)

Не отдавать сырой Prisma-объект. Не требовать отдельного `GET /users/:id` с клиента.

### Реализация

В `getOfferDTO` использовать `getOwnerPublicDTO(data.equipment?.owner)` (как booking), либо расширить include до `userSelect` **и** `ownerProfile` и явно смержить поля владельца.

Не подставлять клиентский `UserProfile`: у владельца имя/фото/рейтинг заполняются в `OwnerProfile`.

Выровнять `getOwnerPublicDTO.orderCount` на `completedOrderCount`, а отзывы оставить в `ratingCount`.

### Проверка

1. У тестового владельца заполнить `OwnerProfile`: имя, `profileImageUrl`, ненулевые `ratingAverage` / `ratingCount` / `completedOrderCount`. `UserProfile` можно оставить пустым.
2. Создать отклик на заявку клиента.
3. `GET /offers` под клиентом: у `owner` не пустые `firstName`/`imageUrl`, рейтинг и счётчики не нули при ненулевых данных в БД.
4. Тот же владелец на карточке заказа (`booking.owner`) и на карточке отклика выглядят одинаково.
5. Регрессия: список техники / поиск по-прежнему отдаёт `owner` через `getUserPublicDTO`+`userSelect` — не ломать, если это отдельный контракт.

---

## Шаблон нового пункта

```md
## BE-XXX — короткий заголовок

**Статус:** `open`  
**Где замечено:** экран / роль / локаль / воспроизведение.  
**Дата:** ГГГГ-ММ-ДД.

### Симптом
Что видит пользователь или клиентский парсер.

### Почему бэкенд
Какой JSON/сокет/seed виноват. Какие файлы Flutter только отображают.

### Текущий контракт
Поля, методы, события (`workflow:update`, REST path).

### Ожидаемое поведение
Однозначный результат, включая ru/kk/en и обратную совместимость.

### Реализация
Таблицы, миграции, сериализация, Docker/seed.

### Проверка
Конкретные HTTP/socket шаги на поднятом compose.
```
