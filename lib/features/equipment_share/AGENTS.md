# Equipment share

- Ссылка: `Env.equipmentShareUrl(id)` → `https://<SHARE_BASE_URL>/e/<id>`. Хосты: `Env.shareTrustedHosts`.
- `isShareableNow`: `AVAILABLE` + `isVisible` + есть цена `> 0`. Только тогда PNG и ссылка.
- `canShowShareButton`: `isModerated` (не draft / created / rejected / archived).
- `needsPublishAlert`: кнопка есть, но `isShareableNow` ложно. Алерт, Share не открывается.
- Кнопка: клиентская плитка, список собственника (не черновик, под бейджем статуса, круг `filled`), хедер фото собственника, экран брони. На деталях собственника перед шарингом `ownerEquipmentDetailsProvider.refresh()`.
- В PNG и тексте нет телефона, номера, GPS, `adminComment` и чужих id. Описание — `shortDescriptionOf`; пустое не рисуется.
- Картинка на устройстве: Overlay + `RepaintBoundary.toImage(pixelRatio: 1)`, файл 1080×1350. Не `Offstage`.
- Приём ссылки и гостевой экран брони в этот модуль ещё не входят.
