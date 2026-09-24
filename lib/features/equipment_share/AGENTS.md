# Equipment share

- Ссылка: `Env.equipmentShareUrl(id)` → `https://<SHARE_BASE_URL>/e/<id>`. Хосты: `Env.shareTrustedHosts`.
- `isShareableNow`: `AVAILABLE` + `isVisible` + есть цена `> 0`. Только тогда PNG и ссылка.
- `canShowShareButton`: `isModerated` (не draft / created / rejected / archived).
- `needsPublishAlert`: кнопка есть, но `isShareableNow` ложно. Алерт, Share не открывается.
- Кнопка: клиентская плитка, список собственника (не черновик, под бейджем статуса, круг `filled`), хедер фото собственника, экран брони. На деталях собственника перед шарингом `ownerEquipmentDetailsProvider.refresh()`.
- В PNG и тексте нет телефона, номера, GPS, `adminComment` и чужих id. Описание — `shortDescriptionOf`; пустое не рисуется.
- Картинка на устройстве: Overlay + `RepaintBoundary.toImage(pixelRatio: 1)`, файл 1080×1350. Не `Offstage`.
- Приём ссылки: `app_links` → `EquipmentShareLink` (https, доверенный хост, путь ровно `/e/<id>`). Пока старт `loading` / `otp` / `unauthorized` / `error`, URI лежит в `EquipmentShareStorage`. `guest` / `client` / `owner` → `router.go('/e/<id>')`. Flutter deep linking выключен.
- Экран `/e/:id` — `GuestCreateBookingScreen`: публичный GET, фото, имя, описание, тарифы. Кнопка «Забронировать» у гостя ведёт на вход с `from=/e/<id>`. Форма и заказ — этап 3.
