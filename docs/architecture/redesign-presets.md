# Пресеты редизайна PROKAT

Карта действующей системы на 29 октября 2026. Пути ниже указаны от корня `prokat/`. Цель — менять повторяющийся визуальный приём в одном месте и подключать его к экранам постепенно, сохраняя текущие действия, данные и статусы.

## Что уже общее

| Область | Где менять | Что охватывает |
| --- | --- | --- |
| Новая палитра и Material-тема | `lib/core/theme/prokat_flow_palette.dart` | Светлая/тёмная поверхность, фон, акцент, текст, границы, успех. `filledPrimary` сохраняет контраст белой надписи. `themeFor(base)` централизованно задаёт Manrope для наследуемого текста, фон и Material-цвета нового потока; это общий способ подключения темы. |
| Подключение нового вида | `lib/core/theme/prokat_flow_scope.dart` | Opt-in для проверенного экрана. Корневые маршруты подключаются в `lib/features/layout/main_scaffold.dart`; отдельные формы/экраны могут иметь собственный scope. Сам scope не заменяет всю `ThemeData`. |
| Типографика UI kit | `lib/core/theme/app_fonts.dart` | Именованные роли заголовков, текста, подписи, цены и технического текста. Сейчас все используют Manrope; Sora/Space Mono только обозначены как будущая замена, не подключены. |
| Размеры UI kit | `lib/core/theme/app_dimens.dart` | Интервалы, радиусы, кнопки, поля, навигация, карточки и нижние панели. Действуют в компонентах, которые обращаются к этим константам. |
| Кнопки нового потока | `lib/core/widgets/ui_kit/flow/prokat_flow_actions.dart` | `ProkatFlowPrimaryButton` и `ProkatFlowIconButton`: синий основной CTA и контурная кнопка действия с доступной подписью, загрузкой и блокировкой повторного нажатия. Размеры нового семейства правятся здесь. |
| Остальные кнопки | `lib/core/widgets/ui_kit/controls/buttons/` | Общие elevated/outlined/text/icon/segmented-компоненты. `AppIconButton` учитывает Flow для primary/neutral/success; контрастные заливки и белые иконки общие. Warning/destructive/inverse и вид без scope сохранены. Segmented также учитывает Flow. Остальные компоненты могут использовать `context.colors`. |
| Поля и переключатели формы | `lib/core/widgets/ui_kit/inputs/` | Общие текстовые поля, подписи, рамка, focus/error. `app_text_field.dart` и `app_input_field_box.dart` уже учитывают Flow. Radio/checkbox/switch находятся в `controls/selection/`. |
| Навигация и вкладки | `lib/core/widgets/ui_kit/layout/app_navigation_bar.dart`, `layout/prokat_app_bar.dart`, `tabs/app_tabs.dart` | Уже учитывают Flow scope. Состав и назначение пунктов остаются в `lib/features/layout/main_navigation_bar.dart` и `main_app_bar.dart`. |
| Панели и диалоги | `lib/core/widgets/ui_kit/sheets/app_bottom_sheet.dart`, `app_alert_bottom_sheet.dart` | Общие отступы, радиус, шапка, прокрутка/клавиатура и подтверждение. Используют `AppFonts`, `AppDimens` и `context.colors`. Внутри нового сценария контент подключается к Flow отдельно. |
| Карточка заказа | `lib/features/bookings/widgets/booking_flow_card.dart` | `BookingFlowCard` — общий вид заказов клиента/владельца и истории; обработчики действий остаются в существующих tiles. |
| Входящий запрос владельцу | `lib/features/requests/widgets.dart/owner_request_flow_card.dart` | `OwnerRequestFlowCard` — общий вид запроса с бюджетом, сроком, клиентом и действиями; прежние ONLINE/offer/visibility-проверки остаются в tile. |
| Номер техники | `lib/features/equipment/widgets/owner/equipment_plate_badge.dart` | `EquipmentPlateBadge` — единый вид номера для карточки парка; готов для повторного использования в форме техники. |

Общий экспорт компонентов — `lib/core/widgets/ui_kit/ui_kit.dart`. Базовая тема вне нового потока: `lib/core/theme/colors/` и `lib/core/theme/legacy/app_theme.dart`; доступ к семантическим цветам — `context.colors` из `extensions/app_theme_getter.dart`. Их нельзя массово переписать ради одного экрана: это затронет ещё не проверенные места.

## Что пока не полностью сведено к пресетам

- **Карточки.** `ui_kit/cards/app_card.dart` — общий компонент базовой темы. Заказы уже используют `BookingFlowCard`, входящие запросы — `OwnerRequestFlowCard`; парк обновлён в `OwnerEquipmentCard`. Карточки каталога, предложений, чатов и условий также используют Flow-палитру, но часть радиусов, отступов и `TextStyle` ещё локальная. Изменение `AppDimens.cardRadius` пока не изменит их все.
- **Chips.** Популярные категории — локальный `_FlowCategoryChip` в `lib/features/categories/widgets/category_header_card.dart`; фильтры цены — `ChoiceChip`/`FilterChip` в `lib/features/requests/widgets.dart/request_with_offers.dart`. Общего Flow-chip для всех экранов ещё нет.
- **Статусы.** Бейджи находятся в `features/bookings/widgets/booking_status_badge.dart`, `features/requests/widgets.dart/request_status_badge.dart`, `features/offers/widgets/offer_status_badge.dart`, `features/price_negotiations/widgets/price_negotiation_status_badge.dart`; у списка чатов свой `_StatusBadge`. Семантика берётся из существующих моделей и `features/chat/utils/get_chat_status.dart`. Единое визуальное оформление не должно объединять разные бизнес-статусы.
- **Иконки.** Новые действия используют существующее семейство `lucide_icons_flutter`, например `filePenLine` для изменения условий, `chevronRight` для открытия деталей, `archive` для завершения обсуждения. `lib/core/theme/app_icons.dart` хранит часть SVG. Старые Material/SVG ещё встречаются; единого словаря иконок всех действий пока нет.
- **Шрифты и размеры.** `themeFor(base)` уже выравнивает наследуемые Material-тексты по Manrope. Явные `TextStyle` и отдельные метрики внутри Flow-компонентов ещё нужно переносить на общие роли `AppFonts`/`AppDimens`. Полная замена всех текстовых ролей/метрик одной правкой пока не завершена.

## Как продолжать без разрушения

1. Сначала выделять повторяемый приём в существующий UI kit или небольшой общий Flow-компонент, затем применять к очередному экрану. Не создавать второй набор цветов для каждой страницы.
2. Переносить оформление без изменения обработчиков, запросов, прав доступа и текста. Новую формулировку вводить только для нового действия или если старая мешает понять его смысл. У кнопки-иконки оставлять tooltip/semantic label; не добавлять неработающие действия ради сходства с референсом.
3. После подключения проверять светлую/тёмную тему, 320px и двойной размер текста. Название в превью может сокращаться; цена, условия согласия и значимый статус должны оставаться читаемыми. Длинные данные должны расширять карточку, а не вылезать за её границы.

На текущем срезе оформление заказов/истории, парка и входящих запросов владельца реализовано и прошло целевые проверки. Подключены также частное создание техники, основные секции редактора/тарифы/номер и оба профиля с адаптивными шапками и статистикой. Это не означает, что всё приложение уже переведено. Дальше — **поддержка и вспомогательные экраны**, вложенные photo/general-info/moderation/delete элементы редактора и общий Flow-вид оставшихся AppCard. Параллельно завершать перенос локальных текстовых ролей и метрик в общие пресеты. Перед каждым шагом сверять реальный функционал экрана с референсом; глобально включать новую тему только после проверки всего приложения.
