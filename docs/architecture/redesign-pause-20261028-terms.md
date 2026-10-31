# Пауза: согласование условий — 28 октября 2026

**Пользователь попросил остановиться, закоммитить текущую работу и аккуратно закрыть локальный тестовый сервер.** Продолжать разработку и запускать новые проверки только после его просьбы. Этот checkpoint актуальнее предыдущих документов 28 октября.

## Ограничения и исходное состояние

- Все три repo остаются в `feat/redesign-20261013`, без push/deploy/store release.
- **Без нового согласия пользователя не объединять 1.3.0+27**, не выполнять fetch/merge этого выпуска автоматически. Текущий реализованный/установленный срез — local1.2.4+26, последний законченный mobile commit `82401af6`; backend7297a22, weba9d8a10 до этого WIP.
- Существующий BookingStatus, рабочие этапы, ONLINE, блокировки, старые price-only API и учёт в вебке должны сохраниться. Обсуждение без заказа и превращение его в CREATED в том же чате уже проверены ранее.
- Последнее требование пользователя: внимательно оценивать дизайн и вёрстку, длинные тексты, узкий экран и увеличенный шрифт. Иконку торга поменять; выбран существующий Lucide `filePenLine` — документ с карандашом, редактирование условий.
- Пользовательская исходная правка `docs/architecture/redesign-product-flow.md` остаётся unstaged и не относится к WIP; не включать её в коммит и не исправлять молча.

## Что сохранено сейчас — незавершённая реализация

Первый этап расширяет переговоры только для **прямого CREATED Booking без company**. Подтверждённые заказы, тендерные offers и компании сохраняют прежний механизм цены; изменение подтверждённых условий — отдельный будущий этап.

### Контракт backend

Существующий POST `/price-negotiations` получает необязательные `terms`:

```json
{
  "version": 1,
  "expectedBookingUpdatedAt": "ISO timestamp",
  "bookedOn": "ISO timestamp",
  "bookedAt": "ISO timestamp",
  "location": { "street": "...", "city": "...", "country": "...", "latitude": 0, "longitude": 0 }
}
```

Обычные `bookingId`, `type`, `price`, `priceRate`, `comment` остаются снаружи. Location допускает только безопасные адресные поля/переводы; mobile не отправляет private id/userId/service/equipment/timestamps. Backend также умеет разрешить optional location.id только для текущего адреса заказа либо собственного адреса автора.

Два nullable Prisma поля PriceNegotiation: `proposedTerms Json?`, `baseBookingUpdatedAt DateTime?`. Proposed snapshot содержит version/date/address и серверный `previous` (прежние price/rate/date/address), чтобы история не менялась вместе с Booking.

При ACCEPT terms обязательны `acceptedTermsVersion:1` и `expectedNegotiationUpdatedAt:ISO`. Старый клиент без acknowledgement не может согласиться с невидимым изменением адреса/времени. До принятия Booking не меняется; базовая версия и прежний адрес проверяются под locks; адрес materialize как client-owned Location только в accepting transaction, без orphan при rollback. User KEY SHARE до Booking→Negotiation. Для rich terms добавлены server ONLINE/block guards, legacy price-only не менялся.

DTO: proposedTerms, baseBookingUpdatedAt, requiresTermsAcknowledgement. Новая workflow reason **BOOKING_TERMS_ACCEPTED**; mobile должен refetch полный заказ, потому что короткая delta не содержит новый адрес/дату.

Основные файлы backend: `booking-terms.ts`, PriceNegotiations validation/DTO/service/controller/lifecycle, workflow.broadcast, схема, unit и PostgreSQL tests.

**Миграция `20261028120000_booking_negotiation_terms` создана, но НЕ ПРИМЕНЕНА НИ К КАКОЙ БД.** Только ALTER TABLE + две nullable колонки. Host Prisma client сгенерирован; контейнеры/образы после этого не обновлялись. Не запускать новую web/backend реализацию против старой схемы как будто она уже готова. При продолжении сначала проверить код, guarded local marker/target и применить только additive migration в локальной БД, синхронизировать runtime Prisma/образы. Не reset/db-push/restore локальную реплику. Реальные PG tests ниже требуют отдельной disposable DB и имеют собственные строгие guards.

### Mobile

- Добавлены `BookingTermsProposal` / previous snapshot, acknowledgement/version в модели и service/notifier.
- Новая `BookingTermsProposalSheet` редактирует price/rate/address/date/time локальным черновиком, отправляет предложение. Не меняет текущий Booking или primary address.
- Адреса пока только текущий общий адрес и собственные сохранённые ADDRESS. **Добавление нового адреса через карту пока не включено**: не городить второй shell, согласовать owner/client map путь отдельно.
- `BookingTermsSummary` и `BookingTermsProposalCard`: сравнение прежних/новых условий, принять/отклонить/отозвать. Неизвестная версия snapshot не принимается.
- `NegotiationMessageBubble` отдаёт rich terms новой карточке; legacy price bubble сохранён. Иконка в обоих путях filePenLine.
- Pending booking bubble открывает новую форму, сохраняет owner ONLINE guard. Пока есть pending proposal, не предлагает вторую и скрывает прямое подтверждение, чтобы сначала ответить на условия.
- CurrentChatNotifier refetch на BOOKING_TERMS_ACCEPTED добавлен. Проверки обновления активных списков/адресов после consent ещё предстоят.
- Добавлены RU/EN/KK строки и gen-l10n. Форматирование выполнено.

### Web

- Добавлены separate read-only proposal history/summary в admin booking/chat; реальные Booking price/date/location остаются источником учёта.
- Owner/admin chat отображают структурированные NEGOTIATION terms messages. Legacy/future metadata оставляют прежний text fallback; историческое событие не заявляет актуальный pending status.
- MessageDTO.service сохранён через readers/API/socket mappings. Schema синхронизирована, Prisma7.6 generated tracked additions сохранены.
- Новых web mutations/подтверждений не вводилось: раньше owner-web был text-only и это не расширялось в данном срезе.

## Что проверено и что не прошло

- Backend: typecheck прошёл по логу. Unit/helper/lifecycle **17 passed, 1 skipped** (18 total). Настоящие новые PostgreSQL cases написаны, **не запускались**; тест требует отдельный DB `prokat_m0_07c_booking`, user `prokat_m0_07c`, cluster `prokat-m0-07c-booking`, PostgreSQL17. Не направлять его в нашу replica/prokat: test использует db push и destructive disposable fixtures.
- Web: **37 targeted tests passed**, typecheck прошёл. Production Next build вывел полный список routes и успешное завершение compile в `web-terms-build.log`; проверить exit/completion при необходимости, повторного build не требуется только ради паузы.
- Mobile: первый выбранный прогон **7 passed, 2 failed**. Падают два новых sheet tests: `price edit preserves address, dates and baseline version without mutating booking` (requests.single пуст), `duplicate tap is blocked while proposal is pending and failure keeps the draft` (calls0 вместо1). В логе есть missed-hit предупреждение нижней кнопки. Не считать это только проблемой теста: проверить реальную доступность кнопки, валидацию/состояние и scrolling. Не подавлять assertions/warnings. Остальные narrow2x/owner-address/confirmed/ASAP cases и старые layout cases прошли в этом прогоне.
- Полный analyze нового mobile WIP и новые model/service/card/workflow regression tests ещё не сделаны. Последние1291+12+22 успешных тестов относились к предыдущему завершённому срезу, не доказывают готовность этого WIP.
- Новый terms WIP APK **не собирался/не устанавливался**. S22 остаётся на готовом1.2.4+26 из `82401af6`, SHA256 `2D4D2272D5B1A15F1AE2E9849D914E9978227BEBF27330FCD884E2B34D3ACE82`.

Логи: `C:\Projects\Prokat-Mobile\artifacts\integration-20261028\backend-terms-*.log`, `web-terms-*.log`, `terms-mobile-first-tests.log`, `terms-l10n.log`.

## Локальная среда и продолжение

На паузе выполнен штатный backend `scripts/local-stop.ps1` (docker stop по project label), **без удаления контейнеров, образов или volumes**. Docker Engine можно оставить запущенным. Контейнеры prokat-local postgres/redis/minio/backend/web остановлены; данные сохранены. Проверить итоговый `local-stop-pause.log` и docker ps -a.

Сохранённые endpoints API4000/web3000/PG5432/Redis6379/MinIO9000/9001. Cached datastore override и новые dependency volumes описаны в integration README. Обычный helper `scripts/local-start-redesign.ps1` есть, **но перед полным запуском нового WIP учесть ещё не применённую additive migration и runtime Prisma**, как выше.

Последние local env: replica true, OTP000000, business jobs/share analytics выключены, Firebase credentials fake, push в реальную систему выключен; прежние env backups ignored. Ничего из env не печатать/коммитить. DB local marker и данные предыдущего QA сохранены:33 users; fake client +77000000005, inquiry chat `cmvrt7zw800043pp4j4r8p393`, CREATED Booking `9b3b3003-9e6e-4883-8deb-90cf7bee30fa`, ownerOFFLINE. Никаких новых rich proposals в локальной БД ещё не создавалось. Preview запрос старого fake client +77000000001 сохранён; два его прежних заказа не отменять.

Порядок продолжения: устранить 2 mobile failures → review согласования и старых API/версий → guarded local migration + runtime → реальные изолированные PG tests и целевые mobile cache/protocol/card layout tests → APK → ручной client/owner pass, если S22 разблокирован. Затем pinned context/offer header и остальные экраны. Согласование confirmed заказов и новые адреса на карте пока отдельные незавершённые задачи.
