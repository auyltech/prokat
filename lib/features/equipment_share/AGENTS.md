# Equipment share

- Ссылка: `Env.equipmentShareUrl(id)` → `https://<SHARE_BASE_URL>/e/<id>`. Хосты: `Env.shareTrustedHosts`.
- Исходящий шаринг: `?s=<shareId>`. `shareId` — 22 символа base64url без `=`, непрозрачный, новый на каждый акт шаринга (`generateShareId` сразу перед `SharePlus`).
- Analytics `share` и backend `SHARED` — только при `ShareResultStatus.success` (`reportShareResult`); `SHARED` только для авторизованного. Оба best-effort, независимы, не блокируют UI.
- `isShareableNow`: `AVAILABLE` + `isVisible` + есть цена `> 0`. Только тогда PNG и ссылка.
- `canShowShareButton`: `isModerated` (не draft / created / rejected / archived).
- `needsPublishAlert`: кнопка есть, но `isShareableNow` ложно. Алерт, Share не открывается.
- Кнопка: клиентская плитка, список собственника (не черновик, под бейджем статуса, круг `filled`), хедер фото собственника, экран брони. На деталях собственника перед шарингом `ownerEquipmentDetailsProvider.refresh()`.
- В PNG и тексте нет телефона, номера, GPS, `adminComment` и чужих id. Описание — `shortDescriptionOf`; пустое не рисуется.
- Картинка на устройстве: Overlay + `RepaintBoundary.toImage(pixelRatio: 1)`, файл 1080×1350. Не `Offstage`.
- Приём ссылки: `app_links` → pending open → durable overlay в `EquipmentShareStorage` → один `router.push('/e/<id>')` из consume bootstrap. Не `go`, не push из redirect. `afterAuth` после гостевого «Создать заказ». Выход стирает pending open (`clearPendingUri`), overlay и intent, но не флаг install referrer. Flutter deep linking выключен.
- Нет приложения: страница `/e/<id>` ведёт в Play с `referrer=id=<id>`. Первый Android-запуск читает Install Referrer один раз и кладёт тот же pending open. Пустой/чужой referrer помечается проверенным и карточку не открывает. Ошибка Play не помечает проверку. iOS без стора — проверка сразу закрывается.
- Входящий `?s=<shareId>` сохраняется в App Link, cold start, pending и Install Referrer (`id=…&s=…` или полный URL). Невалидный `s` → `shareId` null, ссылка остаётся валидной. `EquipmentShareLink.canonical` намеренно без query (дедуп, overlay, навигация); `uri` = `canonical` + `?s=`. В bootstrap дальше передаётся `link.uri`, не `canonical`.
- Pending open — JSON `EquipmentShareOpen` (`uri` с `s`, `via` `app_link`/`install_referrer`, `firstShareBootstrapRun`); старая строка-URI читается как `app_link`, `false`. Flush берёт эти поля из pending, не пересчитывает; flush'и сериализованы.
- `firstShareBootstrapRun` — только диагностика: ссылку обработал первый `start()` при ещё непроверенном install referrer. Не «новая установка». Stream-ссылки всегда `false`.
- `ShareOpenRecorder.record` вызывается ровно в двух точках перед `writeOverlay` (готовый `openOrStore` и flush pending): GA `share_link_opened`, backend OPENED, для гостя `firstTouch.saveIfEmpty` (пока `NoopFirstTouch`). Все три независимы, best-effort, навигация их не ждёт. Overlay / `afterAuth` запись не повторяют.
- Экран `/e/:id` — `GuestCreateBookingScreen` с `ProkatAppBar`. Back: `pop` если есть стек, иначе landing (`startupLandingLocation`). Гость заполняет форму, первый тап «Создать заказ» кладёт UI-intent и overlay `afterAuth`, открывает вход. После OTP redirect подкладывает landing, consume пушит карточку один раз; форма из intent. Заказ — только повторный тап.
