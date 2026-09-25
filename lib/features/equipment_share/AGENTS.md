# Equipment share

- Ссылка: `Env.equipmentShareUrl(id)` → `https://<SHARE_BASE_URL>/e/<id>`. Хосты: `Env.shareTrustedHosts`.
- `isShareableNow`: `AVAILABLE` + `isVisible` + есть цена `> 0`. Только тогда PNG и ссылка.
- `canShowShareButton`: `isModerated` (не draft / created / rejected / archived).
- `needsPublishAlert`: кнопка есть, но `isShareableNow` ложно. Алерт, Share не открывается.
- Кнопка: клиентская плитка, список собственника (не черновик, под бейджем статуса, круг `filled`), хедер фото собственника, экран брони. На деталях собственника перед шарингом `ownerEquipmentDetailsProvider.refresh()`.
- В PNG и тексте нет телефона, номера, GPS, `adminComment` и чужих id. Описание — `shortDescriptionOf`; пустое не рисуется.
- Картинка на устройстве: Overlay + `RepaintBoundary.toImage(pixelRatio: 1)`, файл 1080×1350. Не `Offstage`.
- Приём ссылки: `app_links` → pending URI → durable overlay в `EquipmentShareStorage` → один `router.push('/e/<id>')` из consume bootstrap. Не `go`, не push из redirect. `afterAuth` после гостевого «Забронировать». Выход стирает pending URI, overlay и intent. Flutter deep linking выключен.
- Экран `/e/:id` — `GuestCreateBookingScreen` с `ProkatAppBar`. Back: `pop` если есть стек, иначе landing (`startupLandingLocation`). Гость заполняет форму, первый тап кладёт UI-intent и overlay `afterAuth`, открывает вход. После OTP redirect подкладывает landing, consume пушит карточку один раз; форма из intent. Заказ — только повторный тап.
