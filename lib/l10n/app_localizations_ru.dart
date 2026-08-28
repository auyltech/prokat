// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appLanguage => 'Язык приложения';

  @override
  String offerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count предложения',
      many: '$count предложений',
      few: '$count предложения',
      one: '1 предложение',
    );
    return '$_temp0';
  }

  @override
  String offersReceivedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Получено $count предложения',
      many: 'Получено $count предложений',
      few: 'Получено $count предложения',
      one: 'Получено 1 предложение',
    );
    return '$_temp0';
  }

  @override
  String get activeRequestAlreadyExists => 'У вас уже есть активный запрос.';

  @override
  String get supportTicketSubmitted =>
      'Обращение в поддержку успешно отправлено!';

  @override
  String get failedToSubmitTicket => 'Не удалось отправить обращение';

  @override
  String get getInTouch => 'Связаться с нами';

  @override
  String get createOrder => 'Создать заказ';

  @override
  String get myProfile => 'Мой профиль';

  @override
  String get mapSearch => 'Поиск на карте';

  @override
  String get myAddresses => 'Мои адреса';

  @override
  String get rentalRequests => 'Запросы на аренду';

  @override
  String get registration => 'Регистрация';

  @override
  String get equipmentDetails => 'Сведения о технике';

  @override
  String get createAddress => 'Создать адрес';

  @override
  String get editAddress => 'Изменить адрес';

  @override
  String get pinToMap => 'Отметить на карте';

  @override
  String get addresses => 'Адреса';

  @override
  String get topUpBalance => 'Пополнить баланс';

  @override
  String get payments => 'Платежи';

  @override
  String get offerCreated => 'Предложение создано';

  @override
  String get offerCreateRequestNotFound => 'Заявка не найдена или уже удалена';

  @override
  String get offerReceived => 'Предложение получено';

  @override
  String get counterOfferSent => 'Встречное предложение отправлено';

  @override
  String get respondToCounterOffer => 'Ответьте на встречное предложение';

  @override
  String get orderHasBeenCancelled => 'Заказ отменён';

  @override
  String get waitingOwnerResponse => 'Ожидание ответа владельца';

  @override
  String get waitingClientConfirmation => 'Ожидание подтверждения клиента';

  @override
  String get confirmWorkCompleted => 'Подтвердить завершение работы';

  @override
  String get orderCompleted => 'Заказ завершён';

  @override
  String get reviewSent => 'Отзыв отправлен';

  @override
  String get orderCreated => 'Заказ создан';

  @override
  String get workCompleted => 'Работа завершена';

  @override
  String get selectRegistrationMethod =>
      'Выберите предпочтительный способ регистрации';

  @override
  String get couldNotLoadCategories => 'Не удалось загрузить категории';

  @override
  String get checkYourConnection => 'Проверьте подключение к интернету.';

  @override
  String get noServicesAvailableYet => 'Услуг пока нет';

  @override
  String get checkBackLater => 'Загляните позже — появятся обновления.';

  @override
  String get balanceUnavailable => 'Баланс недоступен';

  @override
  String get accountBalance => 'Баланс аккаунта';

  @override
  String get notVerified => 'Не подтверждено';

  @override
  String get uploadProfileImage => 'Загрузить фото профиля';

  @override
  String get switchBackToClient => 'Вернуться в клиентский раздел';

  @override
  String get vehicleName => 'Название техники';

  @override
  String get modelType => 'Модель';

  @override
  String get noLocationSet => 'Местоположение не указано';

  @override
  String get noPriceSet => 'Цена не указана';

  @override
  String get hasPricesListed => 'Тарифы указаны';

  @override
  String get dateNotSet => 'Дата не указана';

  @override
  String get balanceLoadError => 'Не удалось загрузить баланс';

  @override
  String get priceEntryDeleted => 'Тариф удалён';

  @override
  String get failedToDeletePriceEntry => 'Не удалось удалить тариф';

  @override
  String get systemError => 'СИСТЕМНАЯ ОШИБКА';

  @override
  String get equipmentDataNotLocated => 'ДАННЫЕ О ТЕХНИКЕ НЕ НАЙДЕНЫ';

  @override
  String get backToFleet => 'НАЗАД К ТЕХНИКЕ';

  @override
  String get howCanWeHelp => 'Чем мы можем помочь?';

  @override
  String get supportFormDescription =>
      'Заполните форму, и наша команда свяжется с вами в ближайшее время.';

  @override
  String get contactInformation => 'Контактная информация';

  @override
  String get fullNameRequiredLabel => 'Полное имя *';

  @override
  String get fullNameValidation => 'Введите полное имя';

  @override
  String get emailOrPhoneRequired => 'Укажите email или номер телефона';

  @override
  String get phoneRequiredIfEmailEmpty =>
      'Обязательно, если номер телефона не указан';

  @override
  String get invalidEmail => 'Введите корректный email';

  @override
  String get emailAddressRequiredLabel => 'Адрес электронной почты *';

  @override
  String get phoneNumberRequiredLabel => 'Номер телефона *';

  @override
  String get inquiryTopicValidation => 'Выберите тему обращения';

  @override
  String get inquiryDetails => 'Сведения об обращении';

  @override
  String get inquiryTopicRequiredLabel => 'Тема обращения *';

  @override
  String get selectInquiryTopic => 'Выберите тему обращения';

  @override
  String get inquiryTopicGeneral => 'Общий вопрос';

  @override
  String get inquiryTopicSupport => 'Поддержка';

  @override
  String get inquiryTopicBugReport => 'Сообщение об ошибке';

  @override
  String get inquiryTopicFeatureRequest => 'Предложение функции';

  @override
  String get inquiryTopicSales => 'Продажи';

  @override
  String get inquiryTopicPartnership => 'Партнёрство';

  @override
  String get inquiryTopicBilling => 'Оплата и счета';

  @override
  String get inquiryTopicCallMe => 'Перезвоните мне';

  @override
  String get inquiryTopicAccountDeletion => 'Удаление аккаунта';

  @override
  String get inquiryTopicAccountRecovery => 'Восстановление аккаунта';

  @override
  String get inquiryTopicAccountIssue => 'Проблема с аккаунтом';

  @override
  String get inquiryTopicOther => 'Другое';

  @override
  String get yourMessageRequiredLabel => 'Ваше сообщение *';

  @override
  String get messageValidation => 'Введите сообщение';

  @override
  String get counterOffer => 'Встречное предложение';

  @override
  String get legalDocumentLoadError =>
      'Не удалось загрузить документ. Попробуйте позже.';

  @override
  String get termsLoadError =>
      'Не удалось загрузить условия использования. Попробуйте позже.';

  @override
  String get startupLoadingMode => 'Загрузка режима приложения...';

  @override
  String get startupRestoringSession => 'Восстановление сеанса...';

  @override
  String get startupRestoringOtp => 'Восстановление OTP-сеанса...';

  @override
  String get startupRefreshingSession => 'Обновление сеанса...';

  @override
  String get startupLoadingProfile => 'Загрузка профиля...';

  @override
  String get startupFinalizing => 'Завершение...';

  @override
  String get done => 'Готово';

  @override
  String get offerDetails => 'Сведения о предложении';

  @override
  String get cancelOffer => 'Отменить предложение';

  @override
  String get invalidOrExpiredOtp => 'Неверный или просроченный код';

  @override
  String resendOtpIn(int seconds) {
    return 'Отправить код повторно через $seconds сек.';
  }

  @override
  String otpRetryIn(int seconds) {
    return 'Повторно запросить код можно через $seconds сек.';
  }

  @override
  String get resendOtp => 'Отправить код повторно';

  @override
  String get equipmentRenting => 'Аренда техники';

  @override
  String get getStartedWithProkat => 'Начните работу с Prokat';

  @override
  String get guestSignInDescription =>
      'Войдите, чтобы просматривать технику, связываться с владельцами и оформлять заказы в несколько нажатий.';

  @override
  String get equipmentSubmittedForReview => 'Техника отправлена на проверку';

  @override
  String get equipmentDeleted => 'Техника удалена';

  @override
  String get failedToDeleteEquipment => 'Не удалось удалить технику';

  @override
  String get moderatorReview => 'Проверка модератором';

  @override
  String get resubmit => 'Отправить повторно';

  @override
  String get maintenance => 'Обслуживание';

  @override
  String get owner => 'Владелец';

  @override
  String get specification => 'Характеристика';

  @override
  String get pleaseProvideRequiredInformation =>
      'Укажите обязательную информацию';

  @override
  String failedToLoadMessage(String message) {
    return 'Не удалось загрузить: $message';
  }

  @override
  String get selectValue => 'Выбрать';

  @override
  String noEquipmentForCategory(String category) {
    return 'Сейчас техника в категории «$category» отсутствует.';
  }

  @override
  String noEquipmentListedInCity(String category, String city) {
    return 'Сейчас техника в категории «$category» в городе $city отсутствует.';
  }

  @override
  String equipmentIsNow(String status) {
    return 'Техника теперь $status';
  }

  @override
  String failedToToggleEquipment(String status) {
    return 'Не удалось перевести технику в статус «$status»';
  }

  @override
  String get requestReceived => 'Запрос получен';

  @override
  String get legalNoticePrefix => 'Продолжая, вы принимаете ';

  @override
  String get userAgreement => 'Пользовательское соглашение';

  @override
  String get legalNoticeAfterAgreement => ', подтверждаете ознакомление с ';

  @override
  String get privacyPolicy => 'Политикой конфиденциальности';

  @override
  String get legalNoticeAfterPrivacy => ' и даете ';

  @override
  String get personalDataConsent =>
      'согласие на сбор и обработку персональных данных';

  @override
  String get legalNoticeSuffix => '.';

  @override
  String get ok => 'ОК';

  @override
  String get confirmDeletion => 'Подтвердите удаление';

  @override
  String get initiateAccountDeletion => 'Начать удаление аккаунта';

  @override
  String get failedToRequestAccountDeletion =>
      'Не удалось запросить удаление аккаунта. Попробуйте ещё раз.';

  @override
  String get accountDeletionScheduledBody =>
      'Ваш аккаунт поставлен в очередь на удаление.\n\nВы немедленно выйдете из системы. Вход в аккаунт в течение 14-дневного периода ожидания отменит запрос на удаление.';

  @override
  String get accountDeletionConfirmationBody =>
      'Ваш аккаунт немедленно получит статус «Ожидает удаления».\n\nДля защиты от случайной потери данных они будут окончательно удалены после 14-дневного периода ожидания.';

  @override
  String get permanentlyDeleteAccount => 'Удалить аккаунт навсегда';

  @override
  String get accountDeletionHoldDescription =>
      'Начнётся 14-дневный период ожидания. Чтобы отменить удаление до его окончания, войдите в аккаунт снова.';

  @override
  String get failedToLoadVersion => 'Не удалось загрузить версию';

  @override
  String versionLabel(String version, String buildNumber) {
    return 'Версия: $version ($buildNumber)';
  }

  @override
  String get markCompletedQuestion => 'Отметить завершённым?';

  @override
  String get markCompleted => 'Отметить завершённым';

  @override
  String get clientConfirmCompletion =>
      'Клиенту потребуется подтвердить завершение.';

  @override
  String get confirmCompletionQuestion => 'Подтвердить завершение?';

  @override
  String get confirmCompletionPrompt => 'Подтвердите, что работа завершена.';

  @override
  String get notYet => 'Ещё нет';

  @override
  String get errorLoadingBooking => 'Ошибка загрузки заказа';

  @override
  String get errorLoadingRequest => 'Ошибка загрузки запроса';

  @override
  String get errorLoadingOffer => 'Ошибка загрузки предложения';

  @override
  String get failedToLoadNegotiation => 'Не удалось загрузить переговоры';

  @override
  String get failedToLoadChat => 'Не удалось загрузить чат';

  @override
  String get offer => 'Предложение';

  @override
  String get support => 'Поддержка';

  @override
  String get service => 'Услуга';

  @override
  String get deletePriceEntry => 'Удалить тариф';

  @override
  String get deletePriceEntryConfirmation => 'Удалить этот тариф?';

  @override
  String get loginRequired => 'Требуется вход';

  @override
  String get loginRequiredToViewEquipment =>
      'Войдите, чтобы просмотреть подробности и забронировать технику.';

  @override
  String get reviewOwner => 'Отзыв о владельце';

  @override
  String get reviewClient => 'Отзыв о клиенте';

  @override
  String get requestAccepted => 'Запрос принят';

  @override
  String get requestRejected => 'Запрос отклонён';

  @override
  String get requestPending => 'Запрос ожидает ответа';

  @override
  String get estimatedExhaustion => 'Прогноз исчерпания';

  @override
  String get enterValidPrice => 'Введите корректную цену';

  @override
  String get requiredIfEmailEmpty => 'Обязательно, если email не указан';

  @override
  String get submitInquiry => 'Отправить обращение';

  @override
  String get couldNotLoadServices => 'Не удалось загрузить услуги';

  @override
  String get noServicesFound => 'Услуги не найдены';

  @override
  String get noServicesAvailable => 'Сейчас в списке нет услуг';

  @override
  String get applicationSettings => 'Настройки приложения';

  @override
  String get userGuides => 'Руководства пользователя';

  @override
  String get submitTopUpRequest => 'Отправить запрос на пополнение';

  @override
  String get selectStars => 'Выберите оценку';

  @override
  String get commentOptional => 'Комментарий (необязательно)';

  @override
  String get completeWork => 'Завершить работу';

  @override
  String get submitReview => 'Отправить отзыв';

  @override
  String get markAllAsRead => 'Отметить всё прочитанным';

  @override
  String get notFound => 'Не найдено';

  @override
  String get placeOrder => 'Оформить заказ';

  @override
  String get notification => 'Уведомление';

  @override
  String get typeMessageHint => 'Введите сообщение...';

  @override
  String get rejectPrice => 'Отклонить цену';

  @override
  String get acceptPrice => 'Принять цену';

  @override
  String get cancelPrice => 'Отменить цену';

  @override
  String get hideRequest => 'Скрыть запрос';

  @override
  String get updateStatus => 'Обновить статус';

  @override
  String get review => 'Отзыв';

  @override
  String get saved => 'Сохранено';

  @override
  String get noNotificationsYet => 'Уведомлений пока нет';

  @override
  String get errorLoadingEquipment => 'Ошибка загрузки техники';

  @override
  String get priceMustBePositive => 'Цена должна быть больше нуля';

  @override
  String get priceMaximumExceeded => 'Цена не может превышать 100 000';

  @override
  String get notSupportedYet => 'Пока не поддерживается';

  @override
  String get errorLoadingProfile => 'Не удалось загрузить профиль';

  @override
  String get tapToRetry => 'Нажмите, чтобы повторить';

  @override
  String get announcements => 'Объявления';

  @override
  String get noMessagesYet => 'Сообщений пока нет';

  @override
  String get unknownEquipment => 'Неизвестная техника';

  @override
  String get pending => 'Ожидается';

  @override
  String get orderConfirmed => 'Заказ подтверждён';

  @override
  String get failedToConfirmOrder => 'Не удалось подтвердить заказ';

  @override
  String get chatLocked => 'Чат заблокирован';

  @override
  String get priceOffer => 'Предложение цены';

  @override
  String offeredPrice(String price) {
    return 'Предложено: $price';
  }

  @override
  String get topUpAdded => 'Пополнение добавлено';

  @override
  String get failedToCompleteTopUp => 'Не удалось выполнить пополнение';

  @override
  String get remainingTime => 'Оставшееся время';

  @override
  String get bestValue => 'ЛУЧШАЯ ЦЕНА';

  @override
  String activeRequestCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count активного запроса',
      many: '$count активных запросов',
      few: '$count активных запроса',
      one: '1 активный запрос',
    );
    return '$_temp0';
  }

  @override
  String minutesRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count мин чтения',
      many: '$count мин чтения',
      few: '$count мин чтения',
      one: '1 мин чтения',
    );
    return '$_temp0';
  }

  @override
  String get pleaseSelectCategory => 'Выберите категорию';

  @override
  String get pleaseSelectEquipment => 'Выберите технику';

  @override
  String get pleaseSelectPrice => 'Выберите цену';

  @override
  String get pleaseSelectLocation => 'Выберите местоположение';

  @override
  String get pleaseSelectDate => 'Выберите дату';

  @override
  String get pleaseSelectTime => 'Выберите время';

  @override
  String get noRequestHistory => 'В истории пока нет запросов';

  @override
  String get noOrderHistoryDescription => 'В истории пока нет заказов';

  @override
  String get reviewSubmitted => 'Отзыв отправлен';

  @override
  String get failedToSubmitReview => 'Не удалось отправить отзыв';

  @override
  String get failedToCancelOrder => 'Не удалось отменить заказ';

  @override
  String get failedToCancelRequest => 'Не удалось отменить запрос';

  @override
  String get saveFailed => 'Не удалось сохранить';

  @override
  String get heroPlatformTag => 'ПЛАТФОРМА АРЕНДЫ №1 В КАЗАХСТАНЕ';

  @override
  String get heroTitle => 'Найди и арендуй технику\nза минуты';

  @override
  String get allLocations => 'Все города';

  @override
  String get getStarted => 'Начать';

  @override
  String get services => 'Услуги';

  @override
  String get seeAll => 'Все';

  @override
  String get popularRents => 'Популярная аренда';

  @override
  String get errorLoadingServices => 'Ошибка загрузки услуг';

  @override
  String get selectLanguage => 'Выберите язык';

  @override
  String get topRated => 'Топ рейтинга';

  @override
  String get available => 'Доступно';

  @override
  String get booked => 'Занята';

  @override
  String get perDay => '/ день';

  @override
  String get heavyEquipmentRentals => 'ПРОКАТ ТЯЖЁЛОЙ ТЕХНИКИ';

  @override
  String get initializingSystems => 'ИНИЦИАЛИЗАЦИЯ...';

  @override
  String get serverWarmingUp => 'Сервер запускается, пожалуйста подождите...';

  @override
  String get save => 'Сохранить';

  @override
  String get cancel => 'Отмена';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get delete => 'Удалить';

  @override
  String get edit => 'Изменить';

  @override
  String get retry => 'Повторить';

  @override
  String get refresh => 'Обновить';

  @override
  String get close => 'Закрыть';

  @override
  String get apply => 'Применить';

  @override
  String get send => 'Отправить';

  @override
  String get submit => 'Отправить';

  @override
  String get upload => 'Загрузить';

  @override
  String get create => 'Создать';

  @override
  String get accept => 'Принять';

  @override
  String get reject => 'Отклонить';

  @override
  String get manage => 'Управлять';

  @override
  String get viewAll => 'Смотреть все';

  @override
  String get goBack => 'Назад';

  @override
  String get search => 'Поиск';

  @override
  String get repeat => 'Повторить';

  @override
  String get crop => 'Обрезать';

  @override
  String get somethingWentWrong => 'Что-то пошло не так!';

  @override
  String get loading => 'Загрузка...';

  @override
  String get noCategories => 'Категории недоступны';

  @override
  String get phoneNumber => 'Номер телефона';

  @override
  String get email => 'Email';

  @override
  String get password => 'Пароль';

  @override
  String get username => 'Имя пользователя';

  @override
  String get city => 'Город';

  @override
  String get street => 'Улица';

  @override
  String get address => 'Адрес';

  @override
  String get model => 'Модель';

  @override
  String get capacity => 'Объём';

  @override
  String get comments => 'Комментарии';

  @override
  String get message => 'Сообщение';

  @override
  String get name => 'Имя';

  @override
  String get fullName => 'Полное имя';

  @override
  String get firstName => 'Имя';

  @override
  String get lastName => 'Фамилия';

  @override
  String get offeredRate => 'Предложенная ставка';

  @override
  String get location => 'Адрес';

  @override
  String get dateAndTime => 'Дата и время';

  @override
  String get priceKZT => 'Цена (₸)';

  @override
  String get priceRateLabel => 'Тариф';

  @override
  String get privateOwner => 'ЧАСТНЫЙ ВЛАДЕЛЕЦ';

  @override
  String get loginSubtitle => 'Продолжите с того места, где остановились';

  @override
  String get signingIn => 'Вход...';

  @override
  String get sendOtp => 'Отправить код';

  @override
  String get verifying => 'Проверка...';

  @override
  String get verifyOtp => 'Подтвердить код';

  @override
  String get changePhoneNumber => 'Изменить номер';

  @override
  String get registrationFailed => 'Ошибка регистрации. Повторите попытку.';

  @override
  String get otpSubtitle => 'Введите 6-значный код, отправленный на';

  @override
  String get creating => 'СОЗДАНИЕ...';

  @override
  String get sendCode => 'ОТПРАВИТЬ КОД';

  @override
  String get sending => 'ОТПРАВКА...';

  @override
  String get pleaseEnterPhone => 'Введите номер телефона';

  @override
  String get validKazakhPhone => 'Введите казахстанский номер (+7XXXXXXXXXX)';

  @override
  String get failedSendOtp => 'Не удалось отправить код. Попробуйте снова.';

  @override
  String get pleaseEnterBothFields => 'Введите имя пользователя и пароль';

  @override
  String get pleaseEnterOtp => 'Введите код подтверждения';

  @override
  String get otpMustBeSixDigits => 'Код должен содержать 6 цифр';

  @override
  String get invalidExpiredOtp => 'Неверный или истёкший код';

  @override
  String get createAccount => 'Создать аккаунт';

  @override
  String get joinCommunity => 'Присоединяйтесь к Prokat сегодня';

  @override
  String get registerWithPhone => 'Зарегистрироваться по телефону';

  @override
  String get useEmailPassword => 'Использовать Email и пароль';

  @override
  String get alreadyRegistered => 'Уже зарегистрированы?';

  @override
  String get loginLink => 'Войти';

  @override
  String get resetPassword => 'Сброс пароля';

  @override
  String get checkYourEmail => 'Проверьте почту';

  @override
  String get sendRecoveryLink => 'ОТПРАВИТЬ ССЫЛКУ';

  @override
  String get backToLogin => 'НАЗАД К ВХОДУ';

  @override
  String get resendLink => 'Отправить снова';

  @override
  String get emailAddress => 'Адрес электронной почты';

  @override
  String get pleaseEnterEmail => 'Введите адрес электронной почты';

  @override
  String get pleaseEnterAllFields => 'Заполните все поля регистрации';

  @override
  String get enterRegisteredEmail =>
      'Введите зарегистрированный email для получения ссылки на сброс пароля.';

  @override
  String recoverySentTo(String email) {
    return 'Ссылка для восстановления отправлена на $email';
  }

  @override
  String get navHome => 'Главная';

  @override
  String get navMyFleet => 'Мой парк';

  @override
  String get navOrders => 'Заказы';

  @override
  String get navChats => 'Чаты';

  @override
  String get navSearch => 'Поиск';

  @override
  String get navCreate => 'Создать';

  @override
  String get navDashboard => 'Панель';

  @override
  String get navMap => 'Карта';

  @override
  String get navMyRequests => 'Мои заявки';

  @override
  String get navFavorites => 'Избранное';

  @override
  String get navMyOrders => 'Мои заказы';

  @override
  String get navEquipment => 'Техника';

  @override
  String get navBookings => 'Брони';

  @override
  String get navRequests => 'Заявки';

  @override
  String get navProfile => 'Профиль';

  @override
  String get navSettings => 'Настройки';

  @override
  String get navLogin => 'Войти';

  @override
  String get selectService => 'Выбрать услугу';

  @override
  String get myOrders => 'Мои заказы';

  @override
  String get orderHistory => 'История заказов';

  @override
  String get loginToViewBookings => 'Войдите для просмотра заказов';

  @override
  String get loadingOrders => 'Загрузка заказов...';

  @override
  String get errorLoadingOrders => 'Ошибка загрузки заказов';

  @override
  String get noBookingsFound => 'Заказы не найдены';

  @override
  String get updateWorkStatus => 'Обновить статус работы';

  @override
  String get statusUpdated => 'Статус обновлён';

  @override
  String get failedSaveStatus => 'Не удалось сохранить статус';

  @override
  String get confirmOrder => 'Подтвердить заказ';

  @override
  String get counter => 'Встречное';

  @override
  String get acceptOrder => 'Принять заказ';

  @override
  String get startWork => 'Начать работу';

  @override
  String get orderCancelled => 'Заказ отменён';

  @override
  String get cancelBooking => 'Отменить заказ';

  @override
  String get confirmCancellation => 'Подтвердить отмену';

  @override
  String get yesCancel => 'Да, отменить';

  @override
  String get acceptOrderQuestion => 'Принять заказ?';

  @override
  String get openIn2GIS => 'Открыть в 2GIS';

  @override
  String get openInGoogleMaps => 'Открыть в Google Maps';

  @override
  String get deliveryAddress => 'Адрес доставки';

  @override
  String get noActiveOrders => 'Нет активных заказов';

  @override
  String get draftIncomplete => 'ЧЕРНОВИК НЕ ЗАВЕРШЁН';

  @override
  String get finishBookingRequest => 'Завершите запрос на бронирование';

  @override
  String get resume => 'ПРОДОЛЖИТЬ';

  @override
  String get rejectOrder => 'Отклонить заказ';

  @override
  String get rejectOrderQuestion =>
      'Вы уверены, что хотите отклонить этот заказ?';

  @override
  String get cancelOrderQuestion =>
      'Вы уверены, что хотите отменить этот заказ?';

  @override
  String get acceptOrderConfirmation =>
      'Вы уверены, что хотите принять этот заказ?';

  @override
  String acceptBookingFor(String name) {
    return 'Принять бронирование для $name?';
  }

  @override
  String get yesReject => 'Да, отклонить';

  @override
  String get yes => 'Да';

  @override
  String get no => 'Нет';

  @override
  String get decline => 'Отклонить';

  @override
  String minutesLeft(int minutes) {
    return '$minutes мин осталось';
  }

  @override
  String get volume => 'Объём';

  @override
  String get specFilterFrom => 'от';

  @override
  String get specFilterTo => 'до';

  @override
  String get noOrderHistory => 'История заказов пуста';

  @override
  String get cancelReasonClientNotRespond => 'Клиент не ответил';

  @override
  String get cancelReasonEquipUnavailable => 'Техника недоступна';

  @override
  String get cancelReasonPricingIssue => 'Проблема с ценой';

  @override
  String get cancelReasonSchedulingConflict => 'Конфликт расписания';

  @override
  String get cancelReasonDidNotShowUp => 'Не явился';

  @override
  String get cancelReasonChangedMind => 'Передумал';

  @override
  String get cancelReasonEquipNotSuitable => 'Техника не подходит';

  @override
  String get cancelReasonOther => 'Другое';

  @override
  String get workStatusPending => 'Ожидание';

  @override
  String get workStatusOnMyWay => 'Еду';

  @override
  String get workStatusOnSite => 'На месте';

  @override
  String get workStatusStartWork => 'Начать работу';

  @override
  String get workStatusPostpone => 'Отложить';

  @override
  String get workStatusStopWork => 'Остановить работу';

  @override
  String get workStatusCompleteWork => 'Завершить работу';

  @override
  String get workStatusCancelJob => 'Отменить задание';

  @override
  String get myEquipment => 'Моя техника';

  @override
  String get addEquipment => 'Добавить технику';

  @override
  String get noEquipmentListed => 'Техника ещё не добавлена';

  @override
  String get online => 'ОНЛАЙН';

  @override
  String get offline => 'ОФЛАЙН';

  @override
  String get repair => 'РЕМОНТ';

  @override
  String get couldNotAddEquipment => 'Не удалось добавить технику';

  @override
  String get equipmentNameLabel => 'НАЗВАНИЕ ТЕХНИКИ';

  @override
  String get equipmentNameHint => 'напр. Ассенизатор';

  @override
  String get modelLabel => 'МОДЕЛЬ';

  @override
  String get modelHint => 'напр. КАМАЗ-65115';

  @override
  String get plateNumberLabel => 'ГОСНОМЕР';

  @override
  String get plateNumberHint => 'напр. 777 ABC 01';

  @override
  String get availableForRent => 'Доступна для аренды';

  @override
  String get operatingStatus => 'Статус работы';

  @override
  String get submitForReview => 'Отправить на проверку';

  @override
  String get submittedForReview => 'Техника отправлена на проверку';

  @override
  String get failedToSubmit => 'Не удалось отправить';

  @override
  String get equipmentUpdated => 'Техника обновлена';

  @override
  String get pleaseEnterValidValues => 'Введите корректные значения';

  @override
  String get equipmentUpdatedSuccessfully => 'Техника успешно обновлена';

  @override
  String get failedToUpdateEquipment => 'Не удалось обновить технику';

  @override
  String get editEquipment => 'Редактировать технику';

  @override
  String get ownerComment => 'Комментарий владельца';

  @override
  String get rentCondition => 'Условия аренды';

  @override
  String get fullLoadOnly => 'Только полная загрузка...';

  @override
  String get commentNotes => 'Комментарий / Заметки';

  @override
  String get cropEquipmentPhoto => 'Обрезать фото техники';

  @override
  String get deletePhotoQuestion => 'Удалить фото?';

  @override
  String get deletePhotoConfirmation => 'Это действие нельзя отменить.';

  @override
  String get failedAddPriceEntry => 'Не удалось добавить цену';

  @override
  String get failedUpdatePriceEntry => 'Не удалось обновить цену';

  @override
  String get failedSavePriceEntry => 'Не удалось сохранить цену';

  @override
  String get couldNotSaveEquipment => 'Не удалось сохранить технику';

  @override
  String get viewAllLocations => 'Смотреть все адреса';

  @override
  String get addAddressManually => 'Добавить адрес вручную';

  @override
  String get setOnMap => 'Отметить на карте';

  @override
  String get noPricesListed => 'Цены не указаны';

  @override
  String get bookEquipment => 'Заказать';

  @override
  String get requestEquipment => 'Запрос';

  @override
  String get perHour => '/ час';

  @override
  String get perTrip => '/ рейс';

  @override
  String get retryNow => 'Повторить';

  @override
  String get selectCity => 'Выберите город';

  @override
  String get required => 'ОБЯЗАТЕЛЬНО';

  @override
  String get equipmentAdded => 'Техника добавлена';

  @override
  String get updateDetails => 'Обновить данные';

  @override
  String get status => 'Статус';

  @override
  String get perM3 => '/ м³';

  @override
  String get myRequests => 'Мои заявки';

  @override
  String get createRequest => 'Создать заявку';

  @override
  String get loginToViewRequests => 'Войдите для просмотра заявок';

  @override
  String get errorLoadingRequests => 'Ошибка загрузки заявок';

  @override
  String get noActiveRequests => 'У вас нет активных заявок';

  @override
  String get createNewRequest => 'Создать новую заявку';

  @override
  String get requiredCapacity => 'Необходимый объём';

  @override
  String get capacityHint => '10 M3';

  @override
  String get offeredRateHint => 'Цена, которую готовы заплатить';

  @override
  String get additionalDetails => 'Дополнительные детали...';

  @override
  String get newRequestBadge => 'НОВЫЙ ЗАПРОС';

  @override
  String get offerSentBadge => 'ПРЕДЛОЖЕНИЕ ОТПРАВЛЕНО';

  @override
  String get cancelRequest => 'Отменить заявку?';

  @override
  String get requestCancelled => 'Заявка отменена';

  @override
  String get noChats => 'Нет чатов';

  @override
  String get chatsActiveTab => 'Активные';

  @override
  String get chatsArchiveTab => 'Архив';

  @override
  String get noArchivedChats => 'Нет архивных чатов';

  @override
  String get youHaveNoArchivedChats =>
      'Здесь появятся завершённые и отменённые чаты.';

  @override
  String get deliverTo => 'ДОСТАВИТЬ К';

  @override
  String get houseBuilding => 'Дом / Корпус / Подъезд';

  @override
  String get myHouseHint => 'Мой дом';

  @override
  String get streetHint => 'Стапаева 123';

  @override
  String get cityHint => 'Атырау';

  @override
  String get saveLocation => 'Сохранить адрес';

  @override
  String get confirmLocation => 'Подтвердить местоположение';

  @override
  String get failedCreateAddress => 'Не удалось создать адрес';

  @override
  String get failedSaveAddress => 'Не удалось сохранить адрес';

  @override
  String get deleteAddress => 'Удалить адрес';

  @override
  String get deleteAddressQuestion => 'Удалить этот адрес?';

  @override
  String get deleteAddressConfirmation =>
      'Адрес будет удалён из сохранённого списка.';

  @override
  String get failedToDeleteAddress => 'Не удалось удалить адрес';

  @override
  String get noEquipmentLocations => 'Адреса техники не добавлены';

  @override
  String get equipmentLocations => 'Адреса техники';

  @override
  String get searchAddress => 'Поиск адреса';

  @override
  String get setDeliveryAddress => 'Указать адрес доставки';

  @override
  String get setEquipmentLocation => 'Указать адрес техники';

  @override
  String get equipmentMap => 'Карта техники';

  @override
  String get failedCreateLocation => 'Не удалось создать местоположение';

  @override
  String get loginToViewFavorites => 'Войдите для просмотра избранного';

  @override
  String get displayName => 'Имя';

  @override
  String get supportUsTitle => 'Поддержать нас';

  @override
  String get donateOrHelp => 'Помогите нам развиваться';

  @override
  String get termsConditions => 'Условия использования';

  @override
  String get helpSupportTitle => 'Помощь и поддержка';

  @override
  String get preferences => 'НАСТРОЙКИ';

  @override
  String get pushNotifications => 'Push-уведомления';

  @override
  String get bookingAlerts => 'Уведомления о заказах и заявках';

  @override
  String get biometricLogin => 'Биометрический вход';

  @override
  String get secureAccess => 'Безопасный вход через FaceID/TouchID';

  @override
  String get supportSection => 'ПОДДЕРЖКА';

  @override
  String get helpCenter => 'Центр помощи';

  @override
  String get termsOfService => 'Условия обслуживания';

  @override
  String get accountSection => 'АККАУНТ';

  @override
  String get logout => 'Выйти';

  @override
  String get deleteAccount => 'Удалить аккаунт';

  @override
  String get editPhone => 'Изменить телефон';

  @override
  String get editName => 'Изменить имя';

  @override
  String get setUsername => 'Установить имя пользователя';

  @override
  String get ownerDashboard => 'Панель владельца';

  @override
  String get becomeOwner => 'Стать владельцем';

  @override
  String get registrationStatus => 'Статус регистрации';

  @override
  String get appSettings => 'Настройки приложения';

  @override
  String get paymentsBalance => 'Платежи и баланс';

  @override
  String get totalBalance => 'Общий баланс';

  @override
  String get save15Percent => 'Сэкономьте 15%';

  @override
  String get topUpMinutes => 'Пополнить минуты';

  @override
  String get payWithKaspi => 'Оплатить через Kaspi.kz';

  @override
  String get submitManualRequest => 'Отправить запрос вручную (оффлайн оплата)';

  @override
  String get legalInformation => 'Юридическая информация';

  @override
  String get documents => 'Документы';

  @override
  String get idPassport => 'Удостоверение / Паспорт';

  @override
  String get proofOfAddress => 'Подтверждение адреса';

  @override
  String get businessLicense => 'Бизнес-лицензия (необязательно)';

  @override
  String get firstNameHint => 'Введите ваше имя';

  @override
  String get lastNameHint => 'Введите вашу фамилию';

  @override
  String get phoneHint => 'Введите номер телефона';

  @override
  String get emailHint => 'Введите email (необязательно)';

  @override
  String get cityInputHint => 'Введите ваш город';

  @override
  String get camera => 'Камера';

  @override
  String get photoGallery => 'Галерея';

  @override
  String get cropProfilePicture => 'Обрезать фото профиля';

  @override
  String get initializationError => 'ОШИБКА ИНИЦИАЛИЗАЦИИ';

  @override
  String get initializationErrorMessage =>
      'Не удалось загрузить сессию или соединение потеряно. Проверьте подключение и повторите попытку.';

  @override
  String get retryConnection => 'ПОВТОРИТЬ ПОДКЛЮЧЕНИЕ';

  @override
  String get reconnecting => 'ПЕРЕПОДКЛЮЧЕНИЕ...';

  @override
  String get information => 'Информация';

  @override
  String get prices => 'Цены';

  @override
  String get allRatingOptionsListed => 'Все тарифы добавлены';

  @override
  String get pleaseEnterValidPrice => 'Введите корректную цену';

  @override
  String get priceEntryAdded => 'Тариф добавлен';

  @override
  String get priceEntrySaved => 'Тариф сохранён';

  @override
  String get editRate => 'Изменить тариф';

  @override
  String get newRate => 'Новый тариф';

  @override
  String get add => 'Добавить';

  @override
  String get technicalSpecs => 'Технические характеристики';

  @override
  String get pleaseFillMissingInfo =>
      'Пожалуйста, заполните все обязательные поля';

  @override
  String get noSpecsConfigured => 'Характеристики пока не настроены';

  @override
  String get invalidNumber => 'Неверное число';

  @override
  String get updateFailed => 'Ошибка обновления';

  @override
  String get currentLocation => 'Текущее местоположение';

  @override
  String get enterLocation => 'Введите местоположение';

  @override
  String get equipmentBaseLocation => 'Базовое расположение техники';

  @override
  String get dangerZone => 'ОПАСНАЯ ЗОНА';

  @override
  String get deleteEquipmentWarning =>
      'Удаление техники навсегда уберёт её из инвентаря, включая все данные о ценах и истории.';

  @override
  String get deleteEquipment => 'Удалить технику';

  @override
  String get deleteEquipmentQuestion => 'Удалить технику?';

  @override
  String get deleteEquipmentConfirmation =>
      'Это удалит объявление с маркетплейса и всю историю аренды.';

  @override
  String get failedToUploadPhoto => 'Не удалось загрузить фото';

  @override
  String get failedToDeletePhoto => 'Не удалось удалить фото';

  @override
  String get failedToSetCoverPhoto => 'Не удалось установить обложку';

  @override
  String get maxPhotosReached => 'Достигнут лимит 5 фото';

  @override
  String get noPhotosYet => 'Фото пока нет';

  @override
  String get selectLocation => 'Выберите местоположение';

  @override
  String get noSavedLocations => 'Нет сохранённых адресов';

  @override
  String get createNewOnMap => 'Создать новый на карте';

  @override
  String get chooseFromGallery => 'Выбрать из галереи';

  @override
  String get takePhoto => 'Сделать фото';

  @override
  String get setAsCover => 'Установить как обложку';

  @override
  String get deletePhoto => 'Удалить фото';

  @override
  String get cancelRequestAction => 'Отменить запрос';

  @override
  String get cancelRequestContent =>
      'Вы уверены, что хотите отменить этот запрос? Это действие нельзя отменить.';

  @override
  String get newRequest => 'Новый запрос';

  @override
  String get deliveryLocation => 'Адрес доставки';

  @override
  String get equipmentSpecs => 'Характеристики техники';

  @override
  String get selectDate => 'Выбрать дату';

  @override
  String get selectTime => 'Выбрать время';

  @override
  String get requiredHint => '* Обязательно';

  @override
  String get requestCreated => 'Запрос создан';

  @override
  String get noRequestsAtMoment => 'Запросов пока нет';

  @override
  String get viewBooking => 'Посмотреть бронирование';

  @override
  String get viewOffer => 'Посмотреть предложение';

  @override
  String get sendOffer => 'Отправить предложение';

  @override
  String get offerUpdated => 'Предложение обновлено';

  @override
  String get selectEquipment => 'Выберите технику';

  @override
  String get startDate => 'Дата начала';

  @override
  String get startTime => 'Время начала';

  @override
  String get optionalNotesHint => 'Необязательные заметки или условия...';

  @override
  String get pastRequests => 'ПРОШЛЫЕ ЗАПРОСЫ';

  @override
  String get requestsHistory => 'История запросов';

  @override
  String get activeRequestsTooltip => 'Активные запросы';

  @override
  String get noHistoryFound => 'История не найдена';

  @override
  String get viewedBadge => 'ПРОСМОТРЕНО';

  @override
  String get acceptedBadge => 'ПРИНЯТО';

  @override
  String get hiddenBadge => 'СКРЫТО';

  @override
  String get requestLabel => 'Запрос';

  @override
  String get addLocation => 'Добавить локацию';

  @override
  String get addAddress => 'Добавить адрес';

  @override
  String get addressCreated => 'Адрес создан';

  @override
  String get selectAddress => 'ВЫБРАТЬ АДРЕС';

  @override
  String get noRecentAddresses => 'Нет недавних адресов';

  @override
  String get chooseOnMap => 'ВЫБРАТЬ НА КАРТЕ';

  @override
  String get hardwareRestriction => 'ОГРАНИЧЕНИЕ УСТРОЙСТВА';

  @override
  String get mapMobileOnly => 'Карта доступна только на мобильных устройствах.';

  @override
  String get viewEquipmentList => 'Смотреть список техники';

  @override
  String get saveAddress => 'Сохранить адрес';

  @override
  String get back => 'Назад';

  @override
  String get backToEquipment => 'Назад к технике';

  @override
  String get selectCapacityModel => 'ВЫБРАТЬ ОБЪЁМ / МОДЕЛЬ';

  @override
  String get pricingRates => 'ТАРИФЫ';

  @override
  String get startBooking => 'ЗАБРОНИРОВАТЬ';

  @override
  String get addDisplayName => 'Добавить имя';

  @override
  String get helpSupportSubtitle =>
      'Получить помощь или связаться с поддержкой';

  @override
  String get ownerDashboardSubtitle => 'Управляйте активами и доходами';

  @override
  String get becomeOwnerSubtitle => 'Начните зарабатывать, размещая технику';

  @override
  String get requestStatus => 'Запрос';

  @override
  String get submittedOn => 'Отправлено';

  @override
  String get nameUpdated => 'Имя обновлено';

  @override
  String get failedSaveName => 'Не удалось сохранить имя';

  @override
  String get usernameCannotBeChanged =>
      'Имя пользователя нельзя изменить после установки.';

  @override
  String get chooseUsername =>
      'Выберите имя пользователя. Изменить его будет невозможно.';

  @override
  String get logoutFailed => 'Ошибка выхода';

  @override
  String get activeOrders => 'Активные заказы';

  @override
  String get noOrdersYet => 'Заказов пока нет';

  @override
  String get enterName => 'Введите имя';

  @override
  String get zeroOrders => '0 заказов';

  @override
  String get newOrderCount => 'новый заказ';

  @override
  String get confirmedOrderCount => 'подтверждённый заказ';

  @override
  String get paymentHistory => 'История платежей';

  @override
  String get billingTiers => 'Тарифные уровни';

  @override
  String get runningLow => 'Заканчиваются минуты?';

  @override
  String get topUpViaKaspi => 'Пополните минуты через Kaspi';

  @override
  String get usageTrend => 'Тренд использования';

  @override
  String get last7Days => 'Последние 7 дней';

  @override
  String get verifiedOwner => 'Подтверждённый владелец';

  @override
  String get appSettingsSubtitle => 'Уведомления, Конфиденциальность, Тема';

  @override
  String get helpFaqsSubtitle => 'Часто задаваемые вопросы, связь с поддержкой';

  @override
  String get fullyVerified => 'Аккаунт';

  @override
  String get activeEquipment => 'Активная техника';

  @override
  String get dailyCost => 'Дневная стоимость';

  @override
  String get ownerProfile => 'Профиль владельца';

  @override
  String get selectPackage => 'Выбрать пакет';

  @override
  String get recentPayments => 'Последние платежи';

  @override
  String get completeRegistration => 'Завершите регистрацию';

  @override
  String get submitDocumentsHint =>
      'Отправьте необходимые документы для начала размещения техники.';

  @override
  String get verificationInProgress => 'Верификация в процессе';

  @override
  String get reviewingDocuments => 'Мы проверяем ваши документы.';

  @override
  String get youAreVerified => 'Вы верифицированы!';

  @override
  String get canListEquipment =>
      'Теперь вы можете размещать технику для аренды.';

  @override
  String get verificationFailed => 'Верификация не пройдена';

  @override
  String get updateDocumentsHint => 'Обновите документы и повторите попытку.';

  @override
  String get submitForVerification => 'Отправить на верификацию';

  @override
  String get underReview => 'На проверке';

  @override
  String get viewListings => 'Посмотреть объявления';

  @override
  String get resubmitDocuments => 'Повторно отправить документы';

  @override
  String get uploaded => 'Загружено';

  @override
  String get requiredDoc => 'Обязательно';

  @override
  String get becomeServiceProvider => 'Стать поставщиком услуг';

  @override
  String get joinTeamHint =>
      'Присоединяйтесь к нашей команде и предлагайте своё оборудование или услуги клиентам.';

  @override
  String get requestReviewedHint =>
      'Ваш запрос будет рассмотрен администратором для дальнейшей обработки.';

  @override
  String get enterValidEmail => 'Введите действительный email';

  @override
  String get messageHint =>
      'Кратко опишите услугу или оборудование, которое вы можете предоставить.';

  @override
  String get firstNameRequired => 'Имя обязательно';

  @override
  String get lastNameRequired => 'Фамилия обязательна';

  @override
  String get phoneNumberRequired => 'Номер телефона обязателен';

  @override
  String get ownerContactPhoneHint =>
      'Этот номер увидят администратор и клиенты. По нему должны дозвониться.';

  @override
  String get cityRequired => 'Город обязателен';

  @override
  String get messageRequired => 'Пожалуйста, добавьте короткое сообщение';

  @override
  String get submitRequest => 'Отправить заявку';

  @override
  String get resubmitRequest => 'Повторно отправить заявку';

  @override
  String get updateRequest => 'Обновить заявку';

  @override
  String get statusAccepted => 'Принято';

  @override
  String get statusAcceptedSubtitle =>
      'Вы теперь одобрены как поставщик услуг.';

  @override
  String get statusRejected => 'Отклонено';

  @override
  String get statusRejectedSubtitle =>
      'Пожалуйста, просмотрите комментарий администратора и обновите свой запрос.';

  @override
  String get statusUnderReview => 'На рассмотрении';

  @override
  String get statusUnderReviewSubtitle =>
      'Ваш запрос был отправлен и находится на рассмотрении.';

  @override
  String get adminComment => 'Комментарий администратора';

  @override
  String get requestAcceptedInfo =>
      'Ваш запрос был принят. Если вам нужно изменить данные, свяжитесь с поддержкой.';

  @override
  String get noteDescribeHint =>
      'Примечание: кратко опишите свою услугу/оборудование, чтобы мы могли рассмотреть ваш запрос быстрее.';

  @override
  String get requestSubmitted => 'Заявка отправлена';

  @override
  String get requestUpdated => 'Заявка обновлена';

  @override
  String get notifications => 'Уведомления';

  @override
  String get newBookingRequests => 'Новые запросы на бронирование';

  @override
  String get messages => 'Сообщения';

  @override
  String get reminders => 'Напоминания';

  @override
  String get safetyAndRules => 'Безопасность и правила';

  @override
  String get cancellationPolicy => 'Политика отмены';

  @override
  String get moderate => 'Умеренная';

  @override
  String get damagePolicy => 'Политика повреждений';

  @override
  String get standardCoverage => 'Стандартное покрытие';

  @override
  String get deactivateAccount => 'Деактивировать аккаунт';

  @override
  String get clientRequests => 'Запросы клиентов';

  @override
  String get noNewRequests => 'Нет новых запросов';

  @override
  String get newRequestSingular => 'новый запрос';

  @override
  String get newRequestsPlural => 'новых запросов';

  @override
  String get noOrders => 'Нет заказов';

  @override
  String get orderUnit => 'Заказ';

  @override
  String get ordersUnit => 'Заказов';

  @override
  String get myFleet => 'Моя техника';

  @override
  String get equipmentItemSingular => 'Единица';

  @override
  String get equipmentItemsPlural => 'Единицы';

  @override
  String get noItemsTapToAdd => 'Нет техники • Нажмите для добавления';

  @override
  String get noEquipmentFound => 'Техника не найдена';

  @override
  String get onlineStatus => 'В сети';

  @override
  String get offlineStatus => 'Не в сети';

  @override
  String get minutesBalance => 'Баланс минут';

  @override
  String get minutesUnit => 'Мин';

  @override
  String get burnRate => 'Скорость расхода';

  @override
  String get hello => 'Привет!';

  @override
  String get reviews => 'отзывов';

  @override
  String get rentAnEquipment => 'Арендовать технику';

  @override
  String get findAndRent => 'Найти и арендовать';

  @override
  String get browseHeavyEquipment => 'Тяжёлая техника рядом с вами';

  @override
  String get poa => 'ПОЗ';

  @override
  String get loginToAddFavorites =>
      'Войдите, чтобы добавлять и просматривать избранное';

  @override
  String get noSavedMachinery => 'НЕТ СОХРАНЁННОЙ ТЕХНИКИ';

  @override
  String get exploreFleet => 'ПРОСМОТРЕТЬ ТЕХНИКУ';

  @override
  String get unknownLocation => 'Неизвестное место';

  @override
  String get noPrice => 'Без цены';

  @override
  String get myFavorites => 'Мои избранные';

  @override
  String get favoritesEmptyHint => 'Здесь появятся отмеченные вами объекты';

  @override
  String get frequentlyAskedQuestions => 'Часто задаваемые вопросы';

  @override
  String get needMoreHelp => 'Нужна дополнительная помощь?';

  @override
  String get contactSupport => 'Связаться с поддержкой';

  @override
  String get emailSupport => 'Поддержка по email';

  @override
  String get usingProkat => 'Использование Прокат';

  @override
  String get learnHowPlatformWorks => 'Узнайте, как работает платформа';

  @override
  String get paymentsAndPricing => 'Платежи и цены';

  @override
  String get feesPayoutsBilling => 'Комиссии, выплаты и счета';

  @override
  String get safetyAndTrust => 'Безопасность и доверие';

  @override
  String get guidelinesAndPolicies => 'Руководства и политики';

  @override
  String get accountHelp => 'Помощь с аккаунтом';

  @override
  String get loginProfileSettings => 'Вход, профиль и настройки';

  @override
  String get liveChat => 'Живой чат';

  @override
  String get callUs => 'Позвоните нам';

  @override
  String get faq1Q => 'Как арендовать технику?';

  @override
  String get faq1A =>
      'Просмотрите доступную технику, выберите даты и отправьте запрос на бронирование владельцу.';

  @override
  String get faq2Q => 'Как разместить свою технику?';

  @override
  String get faq2A =>
      'Перейдите в профиль и нажмите «Добавить технику». Заполните детали, цены и местоположение.';

  @override
  String get faq3Q => 'Как работают платежи?';

  @override
  String get faq3A =>
      'Платежи обрабатываются безопасно через платформу. Итоговая сумма будет показана перед подтверждением.';

  @override
  String get faq4Q => 'Могу ли я отменить бронирование?';

  @override
  String get faq4A =>
      'Да, в зависимости от политики отмены владельца, указанной на странице техники.';

  @override
  String get faq5Q => 'Что если техника повреждена?';

  @override
  String get faq5A =>
      'Немедленно сообщите о проблеме через приложение. Наша служба поддержки вам поможет.';

  @override
  String get helpUsGrow => 'Помогите нам расти';

  @override
  String get theSimpleStuff => 'Простые действия';

  @override
  String get rateOnStore => 'Оцените нас в магазине';

  @override
  String get starReviewsHint =>
      '5-звёздочные отзывы помогают другим нас найти.';

  @override
  String get rateNow => 'Оценить';

  @override
  String get spreadTheWord => 'Расскажите другим';

  @override
  String get shareAppHint =>
      'Поделитесь приложением с другом, которому нужна техника.';

  @override
  String get shareApp => 'Поделиться';

  @override
  String get contributeToApp => 'Внесите вклад в приложение';

  @override
  String get betaTestFeedback => 'Бета-тест и обратная связь';

  @override
  String get reportBugsHint =>
      'Сообщайте об ошибках или предлагайте новые функции.';

  @override
  String get submitIdeas => 'Предложить идеи';

  @override
  String get joinOurTeam => 'Присоединитесь к нашей команде';

  @override
  String get lookingForDevelopers =>
      'Мы ищем разработчиков и операционных специалистов.';

  @override
  String get viewCareers => 'Посмотреть вакансии';

  @override
  String get fuelTheMission => 'Поддержите миссию';

  @override
  String get buyDevsACoffee => 'Купите разработчикам кофе';

  @override
  String get tipToKeepServersHint =>
      'Небольшой вклад для поддержания работы серверов.';

  @override
  String get donate => 'Пожертвовать';

  @override
  String get buildingTogether => 'Мы строим это вместе';

  @override
  String get missionStatement =>
      'Наша миссия — сделать технику доступной для всех. Вот как вы можете нам помочь.';

  @override
  String get legalStuff => 'Юридическая информация';

  @override
  String get lastUpdated => 'Последнее обновление: май 2026 г.';

  @override
  String get rentalEligibilityTitle => '1. Право аренды';

  @override
  String get rentalEligibilitySummary =>
      'Вам должно быть 18+ лет и иметь действительное удостоверение личности.';

  @override
  String get rentalEligibilityContent =>
      'Используя это приложение, вы подтверждаете, что вам не менее 18 лет и вы имеете право заключить это соглашение. Для некоторой дорогостоящей техники может потребоваться дополнительная проверка или специализированные лицензии.';

  @override
  String get damageLiabilityTitle => '2. Ущерб и ответственность';

  @override
  String get damageLiabilitySummary =>
      'Вы несёте ответственность за технику, пока она у вас.';

  @override
  String get damageLiabilityContent =>
      'Техника должна быть возвращена в том состоянии, в котором была получена. Вы принимаете полную ответственность за любой ущерб, потерю или кражу. Обычный износ принимается, но халатность не покрывается.';

  @override
  String get lateReturnsTitle => '3. Задержка возврата и штрафы';

  @override
  String get lateReturnsSummary =>
      'Верните вовремя, иначе применяются дополнительные суточные ставки.';

  @override
  String get lateReturnsContent =>
      'Задержка возврата нарушает работу других пользователей. Если техника не возвращена в срок, с вас будет взиматься суточная ставка аренды за каждые 24 часа до возврата.';

  @override
  String get cancellationsTitle => '4. Отмены';

  @override
  String get cancellationsSummary => 'Полный возврат при отмене за 24 часа.';

  @override
  String get cancellationsContent =>
      'Отмены в течение 24 часов до начала аренды могут облагаться комиссией 50%. Неявка будет оплачена полностью.';

  @override
  String get termsAcceptanceNotice =>
      'Продолжая использовать приложение, вы подтверждаете, что прочитали и согласны с этими условиями.';

  @override
  String get couldNotLoadChats => 'Не удалось загрузить чаты';

  @override
  String get youHaveNoChats => 'У вас нет чатов';

  @override
  String get error => 'Ошибка';

  @override
  String get price => 'Цена';

  @override
  String get book => 'Забронировать';

  @override
  String get viewRequests => 'Просмотреть заявки';

  @override
  String get couldNotLoadOrders => 'Не удалось загрузить заказы';

  @override
  String get currentOrdersWillAppearHere =>
      'Здесь появятся ваши текущие заказы';

  @override
  String get requestedBy => 'Запросил';

  @override
  String get sendCounterOffer => 'Отправить встречное предложение';

  @override
  String get newPrice => 'Новая цена';

  @override
  String get noEquipmentAvailable => 'Техника не найдена';

  @override
  String get searchEquipment => 'Найти технику...';

  @override
  String get couldNotLoadEquipment => 'Не удалось загрузить технику';

  @override
  String get selectEquipmentLocation => 'Выбрать местоположение техники';

  @override
  String get noEquipmentMatchingCategory =>
      'По данной категории техника не найдена.';

  @override
  String get cancelOrderConfirmation =>
      'Вы уверены, что хотите отменить этот заказ?';

  @override
  String get loadEquipmentErrorHint =>
      'Произошла ошибка при загрузке списка. Попробуйте снова.';

  @override
  String get createBooking => 'Создать бронирование';

  @override
  String get loginToBook => 'Войдите, чтобы забронировать';

  @override
  String get equipmentNotFound => 'Техника не найдена';

  @override
  String get servicePlan => 'Тарифный план';

  @override
  String get addressAndSchedule => 'Адрес и расписание';

  @override
  String get date => 'Дата';

  @override
  String get time => 'Время';

  @override
  String get noteToOperator => 'Примечание оператору';

  @override
  String get siteAccessHint => 'Детали доступа к объекту, условия...';

  @override
  String get clientBookingDetails => 'Детали брони клиента';

  @override
  String get logoutConfirmation => 'Вы уверены, что хотите выйти?';

  @override
  String get reserveNow => 'Забронировать';

  @override
  String get postWhatAndGetOffers =>
      'Опубликуйте что нужно и получите предложения';

  @override
  String get bookingRequestLabel => 'ЗАПРОС БРОНИРОВАНИЯ';

  @override
  String get newOrder => 'Новый заказ';

  @override
  String get statusDraft => 'Черновик';

  @override
  String get statusConfirmed => 'Подтверждено';

  @override
  String get statusCanceled => 'Отменено';

  @override
  String get statusFailed => 'Сбой';

  @override
  String get statusCompleted => 'Завершено';

  @override
  String get statusReviewed => 'Оценено';

  @override
  String get statusRequestSent => 'Заявка отправлена';

  @override
  String get statusOffersReceived => 'Предложения получены';

  @override
  String get statusBookingCreated => 'Бронирование создано';

  @override
  String get statusExpired => 'Истёк';

  @override
  String get unknownRenter => 'Неизвестный арендатор';

  @override
  String get nameNotSpecified => 'Имя не указано';

  @override
  String get pendingDate => 'Дата не указана';

  @override
  String get overdue => 'Просрочено';

  @override
  String get details => 'Подробнее';

  @override
  String get demandSurveyCardTitle => 'Другая техника?';

  @override
  String get demandSurveyCardSubtitle => 'Расскажите, что вам нужно';

  @override
  String get demandSurveyQuestionTitle => 'Какая техника вам нужна?';

  @override
  String get demandSurveyQuestionSubtitle =>
      'Выберите варианты или опишите другую технику.';

  @override
  String get demandSurveyCityLabel => 'Город';

  @override
  String get demandSurveySelectCity => 'Выберите город';

  @override
  String get demandSurveyOtherOption => 'Другая техника';

  @override
  String get demandSurveyOtherHint => 'Опишите нужную технику';

  @override
  String get demandSurveySubmit => 'Отправить';

  @override
  String get demandSurveyThankYou => 'Спасибо. Ваш ответ сохранён.';

  @override
  String get demandSurveyLoadError => 'Опрос сейчас недоступен.';

  @override
  String get demandSurveySubmitError => 'Проверьте форму и попробуйте снова.';

  @override
  String get demandSurveyAlreadySubmitted => 'Вы уже ответили на этот опрос.';

  @override
  String get demandSurveyInactive => 'Этот опрос больше не активен.';

  @override
  String get aboutProkat => 'О Prokat';

  @override
  String get aboutProkatEyebrow => 'АРЕНДА ТЕХНИКИ — ПРОСТО';

  @override
  String get aboutProkatIntro =>
      'Prokat соединяет тех, кому нужна техника, с проверенными владельцами и сервисными компаниями рядом. Ищите, сравнивайте и общайтесь напрямую на одной платформе.';

  @override
  String get aboutFeatureSearchTitle => 'Простой поиск техники';

  @override
  String get aboutFeatureSearchDescription =>
      'Находите подходящую технику и проверенных местных исполнителей.';

  @override
  String get aboutFeatureTrustedTitle => 'Проверенные исполнители';

  @override
  String get aboutFeatureTrustedDescription =>
      'Владельцы техники и сервисные компании проходят проверку перед публикацией.';

  @override
  String get aboutFeatureRatingsTitle => 'Двусторонние отзывы';

  @override
  String get aboutFeatureRatingsDescription =>
      'Клиенты и владельцы укрепляют доверие через прозрачные оценки.';

  @override
  String get newToProkat => 'ВПЕРВЫЕ В PROKAT?';

  @override
  String get exploreHowItWorks => 'Как это работает';

  @override
  String get aboutProkatBannerSubtitle =>
      'Находите или сдавайте технику и проверенных исполнителей в один шаг.';

  @override
  String get userConsent => 'Согласие пользователя';

  @override
  String get privacyPolicySubtitle =>
      'Как мы собираем и используем ваши данные';

  @override
  String get userAgreementSubtitle => 'Правила пользования платформой';

  @override
  String get personalDataSharingSubtitle => 'Передача персональных данных';

  @override
  String get legalDocuments => 'Юридические документы';

  @override
  String get legalDocumentsSubtitle =>
      'Политики, соглашения, условия использования';

  @override
  String get applicationTheme => 'Тема приложения';

  @override
  String get themeChooseHint =>
      'Выберите, как Prokat будет выглядеть на этом устройстве.';

  @override
  String get themeSystemDefault => 'Как в системе';

  @override
  String get themeSystemDefaultSubtitle => 'Совпадает с оформлением устройства';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeLightSubtitle => 'Всегда светлое оформление';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get themeDarkSubtitle => 'Всегда тёмное оформление';

  @override
  String get serviceAndSafetyNotices => 'Сервисные и важные уведомления';

  @override
  String get serviceAndSafetyNoticesSubtitle =>
      'Аккаунт, безопасность и важные оповещения платформы';

  @override
  String get ownerServiceAndSafetyNoticesSubtitle =>
      'Безопасность, ограничения аккаунта и срочные уведомления';

  @override
  String get requiredNoticesAlwaysAvailable =>
      'Эти уведомления всегда доступны в приложении.';

  @override
  String get checkingPermission => 'Проверка разрешения';

  @override
  String get pushEnabled => 'Включены';

  @override
  String get pushEnabledQuietly => 'Включены без звука';

  @override
  String get pushBlocked => 'Заблокированы';

  @override
  String get pushNotEnabled => 'Не включены';

  @override
  String get pushUnavailable => 'Недоступны';

  @override
  String get pushEnabledInDeviceSettings => 'Включены в настройках устройства';

  @override
  String get pushBlockedInDeviceSettings =>
      'Заблокированы в настройках устройства';

  @override
  String get pushPermissionNotRequested => 'Разрешение не запрошено';

  @override
  String get pushPermissionUnavailable => 'Разрешение недоступно';

  @override
  String get failedToSaveNotificationPreferences =>
      'Не удалось сохранить настройки уведомлений.';

  @override
  String get notifRentalRequestsAndOffers => 'Запросы и предложения';

  @override
  String get notifRentalRequestsAndOffersSubtitle =>
      'Новые предложения, встречные цены и обновления запросов';

  @override
  String get notifOrderUpdates => 'Обновления заказов';

  @override
  String get notifOrderUpdatesSubtitle =>
      'Подтверждения, отмены и смена статуса';

  @override
  String get notifWorkProgress => 'Ход работ';

  @override
  String get notifWorkProgressSubtitle =>
      'Владелец в пути, на объекте, начал или завершил работу';

  @override
  String get notifMessagesSubtitle => 'Новые сообщения в чате и переговорах';

  @override
  String get notifRemindersAndReviews => 'Напоминания и отзывы';

  @override
  String get notifRemindersAndReviewsSubtitle =>
      'Предстоящая аренда и напоминания оставить отзыв';

  @override
  String get notifRequestsAndOffers => 'Запросы и предложения';

  @override
  String get notifRequestsAndOffersSubtitle =>
      'Новые запросы на аренду, решения по предложениям и переговоры';

  @override
  String get notifOrdersAndWorkProgress => 'Заказы и ход работ';

  @override
  String get notifOrdersAndWorkProgressSubtitle =>
      'Подтверждения, отмены и изменения статуса работ';

  @override
  String get notifOwnerMessagesSubtitle =>
      'Новые сообщения от клиентов и переговоры';

  @override
  String get notifEquipmentAndVerification => 'Техника и верификация';

  @override
  String get notifEquipmentAndVerificationSubtitle =>
      'Модерация техники, документы и статус профиля';

  @override
  String get notifBalanceAlerts => 'Баланс';

  @override
  String get notifBalanceAlertsSubtitle =>
      'Низкий баланс, пополнение и статус платежей';

  @override
  String get noAddressSelected => 'Адрес не выбран';

  @override
  String get selectedAddress => 'Выбранный адрес';

  @override
  String get youHaveNoSavedAddresses => 'У вас нет сохранённых адресов.';

  @override
  String get manageMyAddresses => 'Управлять адресами';

  @override
  String get addressPrivacy => 'Конфиденциальность адреса';

  @override
  String get addressPrivacyBody =>
      'Выбранный адрес передаётся владельцу техники только во время активного заказа, когда он нужен для аренды. Он не показывается публично и не передаётся другим пользователям.';

  @override
  String get morePrivacyOptionsContactSupport =>
      'Нужны другие настройки приватности? Напишите в поддержку';

  @override
  String get businessPreferences => 'Бизнес-настройки';

  @override
  String get businessProfile => 'Бизнес-профиль';

  @override
  String get manageMyEquipment => 'Управлять техникой';

  @override
  String get noEquipmentAdded => 'Техника не добавлена';

  @override
  String fleetItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count единиц в парке',
      many: '$count единиц в парке',
      few: '$count единицы в парке',
      one: '$count единица в парке',
    );
    return '$_temp0';
  }

  @override
  String get organization => 'Организация';

  @override
  String get individualOwner => 'Частный владелец';

  @override
  String get chatSection => 'Чат';

  @override
  String get chatContext => 'Контекст';

  @override
  String get participant => 'Участник';

  @override
  String get chatId => 'ID чата';

  @override
  String get booking => 'Заказ';

  @override
  String get notLinked => 'Не привязан';

  @override
  String get clientRole => 'Клиент';

  @override
  String get priceOfferReceived => 'Получено предложение цены';

  @override
  String get waitingClientResponse => 'Ожидание ответа клиента';

  @override
  String get didntReceiveCodeResend => 'Не получили код? Отправить снова';

  @override
  String get youHaveNoActiveOrders => 'У вас нет активных заказов';

  @override
  String get youHaveNoNotifications => 'У вас нет уведомлений';

  @override
  String get unitCubicMeters => 'м³';

  @override
  String get currencyKzt => '₸';

  @override
  String get negotiationIdMissing => 'Не указан идентификатор переговоров';

  @override
  String get actionFailed => 'Не удалось выполнить действие';

  @override
  String get pleaseSelectYourCity => 'Выберите город';

  @override
  String get saveChanges => 'Сохранить';

  @override
  String get saving => 'Сохранение...';

  @override
  String get fieldRequired => 'Обязательное поле';

  @override
  String get justNow => 'Только что';

  @override
  String minutesAgo(int count) {
    return '$count мин назад';
  }

  @override
  String hoursAgo(int count) {
    return '$count ч назад';
  }

  @override
  String durationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня',
      many: '$count дней',
      few: '$count дня',
      one: '1 день',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count часа',
      many: '$count часов',
      few: '$count часа',
      one: '1 час',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count мин',
      many: '$count мин',
      few: '$count мин',
      one: '1 мин',
    );
    return '$_temp0';
  }

  @override
  String durationSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сек',
      many: '$count сек',
      few: '$count сек',
      one: '1 сек',
    );
    return '$_temp0';
  }

  @override
  String get invalidSecondsValue => 'Некорректное значение секунд';

  @override
  String get newOffer => 'Новое предложение';

  @override
  String get offerStatusViewed => 'Просмотрено';

  @override
  String get offerStatusCancelled => 'Отменено';

  @override
  String get offerStatusAccepted => 'Принято';

  @override
  String get offerStatusRejected => 'Отклонено';

  @override
  String get offerStatusExpired => 'Истекло';

  @override
  String get offerStatusClosed => 'Закрыто';

  @override
  String get dataProcessingTitle => 'Обработка данных';

  @override
  String get pleaseCompleteRequiredFields =>
      'Заполните обязательные данные перед отправкой на проверку';

  @override
  String get youAreOnline => 'Вы онлайн';

  @override
  String get youAreOffline => 'Вы офлайн';

  @override
  String get readyToAcceptOrders => 'Готовы принимать заказы';

  @override
  String get notAcceptingOrders => 'Не принимаете заказы';

  @override
  String get youAreNowOnline => 'Вы теперь онлайн';

  @override
  String get youAreNowOffline => 'Вы теперь офлайн';

  @override
  String get failedToggleStatus => 'Не удалось обновить статус';

  @override
  String get countryKazakhstan => 'Казахстан';

  @override
  String get modelStandard => 'Стандарт';

  @override
  String get modelHeavyDuty => 'Тяжёлый';

  @override
  String get modelIndustrial => 'Промышленный';

  @override
  String capacityKub(String capacity) {
    return '$capacity м³';
  }

  @override
  String get unitMeters => 'м';

  @override
  String get hoseLengthHint => 'шланг 15 м';

  @override
  String get priceKztHint => '10 000 ₸';

  @override
  String get ownerType => 'Тип владельца';

  @override
  String get companyInformation => 'Данные компании';

  @override
  String get companyName => 'Название компании';

  @override
  String get enterCompanyName => 'Введите название компании';

  @override
  String get legalEntityName => 'Юридическое название';

  @override
  String get legalEntityNameHint => 'Как в официальных документах';

  @override
  String get personalContactDetails => 'Контактные данные';

  @override
  String get enterFirstName => 'Введите имя';

  @override
  String get enterLastName => 'Введите фамилию';

  @override
  String get enterValidPhoneNumber => 'Введите корректный номер телефона';

  @override
  String get serviceDetails => 'Описание услуг';

  @override
  String get serviceDetailsHint =>
      'Опишите товары, аренду или технику, которую вы предоставляете...';

  @override
  String get updateProfile => 'Обновить профиль';

  @override
  String get profileUpdatedSuccessfully => 'Профиль успешно обновлён';

  @override
  String get failedToUpdateProfile => 'Не удалось обновить профиль';

  @override
  String ordersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count заказа',
      many: '$count заказов',
      few: '$count заказа',
      one: '$count заказ',
    );
    return '$_temp0';
  }

  @override
  String get ratePerTrip => 'За рейс';

  @override
  String get ratePerCubicMeter => 'За м³';

  @override
  String get ratePerDay => 'За сутки';

  @override
  String get ratePerHour => 'За час';

  @override
  String get connectionTimedOut =>
      'Время ожидания истекло. Сервер может запускаться — попробуйте ещё раз.';

  @override
  String get noConnectionCheckNetwork =>
      'Нет соединения. Проверьте сеть и попробуйте снова.';

  @override
  String get networkErrorTryAgain => 'Ошибка сети. Попробуйте ещё раз.';

  @override
  String get somethingWentWrongTryAgain =>
      'Что-то пошло не так. Попробуйте ещё раз.';
}
