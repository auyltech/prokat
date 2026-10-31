# Продолжение 29 октября: профиль и справка

Пользователь возобновил работу после паузы. Ветки `feat/redesign-20261013`; 1.3.0 не объединяли, push/deploy не выполняли. Чужой `redesign-product-flow.md` не трогать.

## Сделано после 12c8b5f9

- AppCard внутри Flow: общий surface/border, без старой тени; вне scope прежний вид, radius/padding/onTap сохранены. Stateful child не пересоздаётся при смене skin.
- AccountStatusCard: адаптивная компоновка, AppFonts/AppDimens, Flow цвета и зелёный ONLINE. Ни OwnerStatusTile, ни billing/state/guard не менялись.
- Help exact route включён в Flow; FAQ карточки, инструкция/preview и CTA в общем стиле. Переход через Navigator сохраняет тему и scope. Chips инструкции переносятся через Wrap вместо переполнения Row.
- Форма обращения в поддержку пока прежняя, не отправлялась.

## Проверено

11 tests passed: flow_account_help_test, balance_summary_card_test, profile_flow_layout_test. Проверены 320px/2x, light/dark, FAQ, навигация, callback switch, сохранение state карточки. Final analyze No issues. Логи в `artifacts/resume-20261029/account-help-{tests,analyze,apk}.log`.

APK local1.2.4+26 установлен на S22 через install -r. SHA256 `3B2C8344C229C494DA6AA85C2DBD50F133612C9A3BAA226C3EFBBDB33E3BF187`. Предыдущий hash B2F9... устарел. Build через scripts/build-redesign-local.ps1, local API/public Mapbox token; никаких prod defines.

Вход owner2 +77000000002/000000 восстановлен (приложение оказалось гостем). Переключено в owner mode. На телефоне профиль: баланс580, OFFLINE, 0 расхода, заказы3; статус не переключали, сделки/технику не меняли. Вручную открыты помощь, FAQ и первая инструкция, снимки `account-help-owner.png`, `account-help-faq.png`, `account-help-guide.png`. На момент окончания экран первой инструкции. USB reverse4000/3000 восстановлены. Настройки таймаута телефона не менялись.

Docker запущен безопасным существующим helper, все5 контейнеров healthy. Локальная реплика сохранена, сервер оставлен запущенным.

## Следующее

Форма поддержки/topic picker, настройки, остаточные photo/general/moderation/delete секции редактора. В текущей инструкции ещё виден прежний технический category `FIND_AND_ORDER`: при следующем проходе заменить на пользовательскую локализованную подпись или убрать служебный chip в Flow, не менять данные модели. Компактное принятое согласование ещё нуждается в финальном визуальном повторе (основная серверная проверка уже выполнена до паузы). Не объявлять весь редизайн завершённым. Основной контекст и ограничения см. pause-20261029.md.
