# Полировка интерфейса — 29 октября 2026

Продолжение после `redesign-mirror-20261029.md`. Ветка `feat/redesign-20261013`; без fetch/merge 1.3.0, push, deploy и публикации. Backend/web без изменений. До отдельной просьбы пользователя текущие mobile изменения не коммитить. Постороннюю правку в `redesign-product-flow.md` не включать.

## Что изменено

- LaunchScreen: navy/blue, Manrope, существующий логотип, тонкий индикатор. Сохранены startup/session/router и обработка долгого запуска. Native Android splash согласован по фону; config flutter_native_splash обновлён, генератор не запускался. iOS storyboard в этой итерации не изменён.
- Нижняя панель: отключён прямоугольный ink в Flow, овальный selection анимируется 180 мс, учитывает reduced motion. Подписи/действия/счётчики сохранены.
- Аватар: карандаш 16px + padding 7 вместо 22+10 в Flow; выбор/загрузка/удаление не менялись.
- Empty bookings/chats: чистые Lucide calendarDays/messagesSquare вместо PNG с бирками; обычный вторичный текст вместо старого жирного label. Остальные иллюстрации сохранены.
- Каталог/запрос: `CatalogGroupTabs` включает `AppSegmentedButton.equalWidth` для равных половин. Другие segmented сохраняют пропорции по содержимому.
- Настройки обеих ролей, документы, blocked users, become-owner/registration включены в Flow allowlist. `ProkatListTile`, `SettingsSwitchTile`, primary `AppElevatedButton` используют общий scoped вид. Колокольчик настроек теперь контрастный, иконки уведомлений обеих ролей — Lucide. Permissions/push/persistence не менялись.
- `ProkatFlowPage` сохраняет стиль отдельного маршрута текста документа. Markdown, locale, ссылки и содержимое не менялись.
- `ProkatFlowIcons` задаёт общие адрес/категории/цена/календарь/время; применён в запросе, условиях брони, расписании, профиле владельца.
- Список чатов сохраняет уже загруженные элементы при background refresh; owner skeleton только когда список пуст. Сетевая политика и TTL сохранены.

## Проверки

41 целевой тест passed (контролы, навигация, профиль, запрос, расписание, чаты); log `artifacts/resume-20261029/polish-tests.log`. После финального уточнения заглушек ещё раз прошёл соответствующий файл: 5 passed (`polish-final-controls-tests.log`, повтор, не суммировать как новые 46 тестов). Analyze No issues (`polish-final-analyze.log`); финальное уточнение стиля subtitle после него прошло compilation/widget tests. Launch preview с настоящим Manrope/logo отрисован и просмотрен (`polish-launch.png`).

Первая local profile APK собрана и установлена с сохранением сессии (hash E06EC7B0451D32975221E5EEE8779374B0EFABEE81AD4BA049F10BBDF28E47E1). Она уже проверена на S22: профиль/карандаш, документы/открытие policy, настройки, пустая регистрация владельца, orders, архив чатов, запрос и равные переключатели. Финальная APK после поправки контраста уведомлений и subtitle — смотреть следующий checkpoint/результат установки, не путать с первой profile и старой debug FFE1CB7E.

Существующее private inquiry открывается в том же чате со статусом «Обсуждение». «Оформить условия» открыло правильные equipment/tariff, Back вернуло тот же чат. Не отправляли сообщения, запрос, application или условия, не создавали Booking и не меняли owner status. Это smoke перехода, не повтор полного E2E подтверждения владельцем.

S22 evidence: `artifacts/resume-20261029/polish-{profile,documents,settings,owner-form,orders,chats-archive,request-form}.png`; XML helper сохраняет в `artifacts/integration-20261028/polish-*.xml`. Первая settings/orders/archive картинка сделана до финальной поправки колокольчика/подписи. Не использовать их как финальные там, где есть `polish-final-*`.

## Среда и оставшееся

Пять local контейнеров healthy. Активны fresh volumes `prokat-local_fresh_20261029-105724972_{postgres,redis,minio}`, запуск только через `scripts/local-start-redesign.ps1`; старые тома и backup сохранены. Не переснимать базу/не удалять volumes. Firebase/push/jobs off; local profile APK не является store/release и подключена к localhost по USB reverse.

Два guest замера каталога 56–136 мс не доказывают отсутствие всех задержек. Profile убирает debug/JIT overhead, фоновые refresh больше не скрывают загруженные чаты. Не заявлять, что все проблемы производительности устранены.

Пользователь подтвердил: кнопка чата отсутствовала у ИП/компаний, у частных владельцев есть. Company pre-booking inquiry **не добавлять без отдельного решения**; в текущей итерации это не дефект частного inquiry. Старые company moderation/access/report gates сохранены.

Полный redesign всего приложения ещё не объявлен завершённым. Остались company management/localization debt, вложенные элементы equipment editor, support и полный проход owner-путей на fresh snapshot (старого fake owner2 там нет), полная конверсия/согласование на fresh snapshot и финальное видео. Общая карта пресетов — `redesign-presets.md`. Никаких заглушек кнопок и обещаний несуществующих функций не добавлено.
