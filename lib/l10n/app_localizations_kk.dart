// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kazakh (`kk`).
class AppLocalizationsKk extends AppLocalizations {
  AppLocalizationsKk([String locale = 'kk']) : super(locale);

  @override
  String get appLanguage => 'Қолданба тілі';

  @override
  String offerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ұсыныс',
      one: '1 ұсыныс',
    );
    return '$_temp0';
  }

  @override
  String offersReceivedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ұсыныс алынды',
      one: '1 ұсыныс алынды',
    );
    return '$_temp0';
  }

  @override
  String get activeRequestAlreadyExists => 'Сізде белсенді сұрау бар.';

  @override
  String get supportTicketSubmitted =>
      'Қолдау қызметіне өтініш сәтті жіберілді!';

  @override
  String get failedToSubmitTicket => 'Өтінішті жіберу мүмкін болмады';

  @override
  String get getInTouch => 'Бізбен байланысу';

  @override
  String get createOrder => 'Тапсырыс жасау';

  @override
  String get myProfile => 'Менің профилім';

  @override
  String get mapSearch => 'Картадан іздеу';

  @override
  String get myAddresses => 'Менің мекенжайларым';

  @override
  String get rentalRequests => 'Жалдау сұраулары';

  @override
  String get registration => 'Тіркелу';

  @override
  String get equipmentDetails => 'Техника мәліметтері';

  @override
  String get createAddress => 'Мекенжай жасау';

  @override
  String get editAddress => 'Мекенжайды өзгерту';

  @override
  String get pinToMap => 'Картада белгілеу';

  @override
  String get addresses => 'Мекенжайлар';

  @override
  String get topUpBalance => 'Балансты толықтыру';

  @override
  String get payments => 'Төлемдер';

  @override
  String get offerCreated => 'Ұсыныс жасалды';

  @override
  String get offerCreateRequestNotFound => 'Өтінім табылмады немесе жойылған';

  @override
  String get offerReceived => 'Ұсыныс алынды';

  @override
  String get counterOfferSent => 'Қарсы ұсыныс жіберілді';

  @override
  String get respondToCounterOffer => 'Қарсы ұсынысқа жауап беріңіз';

  @override
  String get orderHasBeenCancelled => 'Тапсырыс болдырылмады';

  @override
  String get waitingOwnerResponse => 'Иесінің жауабы күтілуде';

  @override
  String get waitingClientConfirmation => 'Клиенттің растауы күтілуде';

  @override
  String get confirmWorkCompleted => 'Жұмыстың аяқталғанын растау';

  @override
  String get orderCompleted => 'Тапсырыс аяқталды';

  @override
  String get reviewSent => 'Пікір жіберілді';

  @override
  String get orderCreated => 'Тапсырыс жасалды';

  @override
  String get workCompleted => 'Жұмыс аяқталды';

  @override
  String get selectRegistrationMethod => 'Қалаған тіркелу әдісін таңдаңыз';

  @override
  String get couldNotLoadCategories => 'Санаттарды жүктеу мүмкін болмады';

  @override
  String get checkYourConnection => 'Интернет байланысын тексеріңіз.';

  @override
  String get noServicesAvailableYet => 'Қызметтер әзірге жоқ';

  @override
  String get checkBackLater => 'Жаңартуларды кейінірек тексеріңіз.';

  @override
  String get balanceUnavailable => 'Баланс қолжетімсіз';

  @override
  String get accountBalance => 'Аккаунт балансы';

  @override
  String get notVerified => 'Расталмаған';

  @override
  String get uploadProfileImage => 'Профиль суретін жүктеу';

  @override
  String get switchBackToClient => 'Клиент бөліміне оралу';

  @override
  String get vehicleName => 'Техника атауы';

  @override
  String get modelType => 'Модель';

  @override
  String get noLocationSet => 'Орналасқан жері көрсетілмеген';

  @override
  String get noPriceSet => 'Баға көрсетілмеген';

  @override
  String get hasPricesListed => 'Тарифтер көрсетілген';

  @override
  String get dateNotSet => 'Күн көрсетілмеген';

  @override
  String get balanceLoadError => 'Балансты жүктеу мүмкін болмады';

  @override
  String get priceEntryDeleted => 'Тариф жойылды';

  @override
  String get failedToDeletePriceEntry => 'Тарифті жою мүмкін болмады';

  @override
  String get systemError => 'ЖҮЙЕЛІК ҚАТЕ';

  @override
  String get equipmentDataNotLocated => 'ТЕХНИКА ДЕРЕКТЕРІ ТАБЫЛМАДЫ';

  @override
  String get backToFleet => 'ТЕХНИКАҒА ОРАЛУ';

  @override
  String get howCanWeHelp => 'Сізге қалай көмектесе аламыз?';

  @override
  String get supportFormDescription =>
      'Төмендегі нысанды толтырыңыз, біздің команда сізбен жақын арада байланысады.';

  @override
  String get contactInformation => 'Байланыс ақпараты';

  @override
  String get fullNameRequiredLabel => 'Толық аты-жөні *';

  @override
  String get fullNameValidation => 'Толық аты-жөніңізді енгізіңіз';

  @override
  String get emailOrPhoneRequired => 'Email немесе телефон нөмірін көрсетіңіз';

  @override
  String get phoneRequiredIfEmailEmpty =>
      'Телефон нөмірі көрсетілмесе, міндетті';

  @override
  String get invalidEmail => 'Дұрыс email енгізіңіз';

  @override
  String get inquiryDetails => 'Өтініш мәліметтері';

  @override
  String get inquiryTopicRequiredLabel => 'Өтініш тақырыбы *';

  @override
  String get yourMessageRequiredLabel => 'Хабарламаңыз *';

  @override
  String get messageValidation => 'Хабарламаны енгізіңіз';

  @override
  String get counterOffer => 'Қарсы ұсыныс';

  @override
  String get legalDocumentLoadError =>
      'Құжатты жүктеу мүмкін болмады. Кейінірек қайталап көріңіз.';

  @override
  String get termsLoadError =>
      'Пайдалану шарттарын жүктеу мүмкін болмады. Кейінірек қайталап көріңіз.';

  @override
  String get startupLoadingMode => 'Қолданба режимі жүктелуде...';

  @override
  String get startupRestoringSession => 'Сеанс қалпына келтірілуде...';

  @override
  String get startupRestoringOtp => 'OTP сеансы қалпына келтірілуде...';

  @override
  String get startupRefreshingSession => 'Сеанс жаңартылуда...';

  @override
  String get startupLoadingProfile => 'Профиль жүктелуде...';

  @override
  String get startupFinalizing => 'Аяқталуда...';

  @override
  String get done => 'Дайын';

  @override
  String get offerDetails => 'Ұсыныс мәліметтері';

  @override
  String get cancelOffer => 'Ұсынысты болдырмау';

  @override
  String get invalidOrExpiredOtp => 'Код қате немесе мерзімі өткен';

  @override
  String resendOtpIn(int seconds) {
    return 'Кодты $seconds секундтан кейін қайта жіберу';
  }

  @override
  String otpRetryIn(int seconds) {
    return 'Кодты $seconds секундтан кейін қайта сұратуға болады';
  }

  @override
  String get resendOtp => 'Кодты қайта жіберу';

  @override
  String get equipmentRenting => 'Техника жалдау';

  @override
  String get getStartedWithProkat => 'Prokat-пен бастаңыз';

  @override
  String get guestSignInDescription =>
      'Техниканы көру, иелерімен байланысу және тапсырыс беру үшін жүйеге кіріңіз.';

  @override
  String get equipmentSubmittedForReview => 'Техника тексеруге жіберілді';

  @override
  String get equipmentDeleted => 'Техника жойылды';

  @override
  String get failedToDeleteEquipment => 'Техниканы жою мүмкін болмады';

  @override
  String get moderatorReview => 'Модератор тексеруі';

  @override
  String get resubmit => 'Қайта жіберу';

  @override
  String get maintenance => 'Техникалық қызмет';

  @override
  String get owner => 'Иесі';

  @override
  String get specification => 'Сипаттама';

  @override
  String get pleaseProvideRequiredInformation =>
      'Міндетті ақпаратты көрсетіңіз';

  @override
  String failedToLoadMessage(String message) {
    return 'Жүктеу мүмкін болмады: $message';
  }

  @override
  String get selectValue => 'Таңдау';

  @override
  String noEquipmentForCategory(String category) {
    return 'Қазір «$category» санатында техника жоқ.';
  }

  @override
  String noEquipmentListedInCity(String category, String city) {
    return 'Қазір $city қаласында «$category» санатындағы техника жоқ.';
  }

  @override
  String equipmentIsNow(String status) {
    return 'Техника енді $status';
  }

  @override
  String failedToToggleEquipment(String status) {
    return 'Техниканы «$status» күйіне ауыстыру мүмкін болмады';
  }

  @override
  String get requestReceived => 'Сұрау алынды';

  @override
  String get legalNoticePrefix => 'Жалғастыру арқылы сіз ';

  @override
  String get userAgreement => 'Пайдаланушылық келісімді';

  @override
  String get legalNoticeAfterAgreement => ' қабылдайсыз, ';

  @override
  String get privacyPolicy => 'Құпиялылық саясатымен';

  @override
  String get legalNoticeAfterPrivacy => ' танысқаныңызды растайсыз және ';

  @override
  String get personalDataConsent =>
      'дербес деректерді жинауға және өңдеуге келісім';

  @override
  String get legalNoticeSuffix => ' бересіз.';

  @override
  String get ok => 'Жарайды';

  @override
  String get confirmDeletion => 'Жоюды растаңыз';

  @override
  String get initiateAccountDeletion => 'Аккаунтты жоюды бастау';

  @override
  String get failedToRequestAccountDeletion =>
      'Аккаунтты жою сұрауын жіберу мүмкін болмады. Қайталап көріңіз.';

  @override
  String get accountDeletionScheduledBody =>
      'Аккаунтыңыз жоюға жоспарланды.\n\nСіз жүйеден дереу шығасыз. 14 күндік күту кезеңінде аккаунтқа қайта кіру жою сұрауын болдырмайды.';

  @override
  String get accountDeletionConfirmationBody =>
      'Аккаунтыңыз дереу «Жойылуды күтуде» күйіне өтеді.\n\nДеректердің кездейсоқ жоғалуынан қорғау үшін олар 14 күндік күту кезеңінен кейін біржола жойылады.';

  @override
  String get permanentlyDeleteAccount => 'Аккаунтты біржола жою';

  @override
  String get accountDeletionHoldDescription =>
      '14 күндік күту кезеңі басталады. Ол аяқталғанға дейін қайта кіру арқылы жоюдан бас тарта аласыз.';

  @override
  String get failedToLoadVersion => 'Нұсқаны жүктеу мүмкін болмады';

  @override
  String versionLabel(String version, String buildNumber) {
    return 'Нұсқа: $version ($buildNumber)';
  }

  @override
  String get markCompletedQuestion => 'Аяқталды деп белгілеу керек пе?';

  @override
  String get markCompleted => 'Аяқталды деп белгілеу';

  @override
  String get clientConfirmCompletion => 'Клиент аяқталғанын растауы керек.';

  @override
  String get confirmCompletionQuestion => 'Аяқталғанын растау керек пе?';

  @override
  String get confirmCompletionPrompt => 'Жұмыстың аяқталғанын растаңыз.';

  @override
  String get notYet => 'Әзірге жоқ';

  @override
  String get errorLoadingBooking => 'Тапсырысты жүктеу қатесі';

  @override
  String get errorLoadingRequest => 'Сұрауды жүктеу қатесі';

  @override
  String get errorLoadingOffer => 'Ұсынысты жүктеу қатесі';

  @override
  String get failedToLoadNegotiation => 'Келіссөздерді жүктеу мүмкін болмады';

  @override
  String get failedToLoadChat => 'Чатты жүктеу мүмкін болмады';

  @override
  String get offer => 'Ұсыныс';

  @override
  String get support => 'Қолдау';

  @override
  String get service => 'Қызмет';

  @override
  String get deletePriceEntry => 'Тарифті жою';

  @override
  String get deletePriceEntryConfirmation => 'Бұл тарифті жойғыңыз келе ме?';

  @override
  String get loginRequired => 'Жүйеге кіру қажет';

  @override
  String get loginRequiredToViewEquipment =>
      'Мәліметтерді көру және техниканы брондау үшін жүйеге кіріңіз.';

  @override
  String get reviewOwner => 'Иесі туралы пікір';

  @override
  String get reviewClient => 'Клиент туралы пікір';

  @override
  String get requestAccepted => 'Сұрау қабылданды';

  @override
  String get requestRejected => 'Сұрау қабылданбады';

  @override
  String get requestPending => 'Сұрау күтілуде';

  @override
  String get estimatedExhaustion => 'Болжалды аяқталу';

  @override
  String get enterValidPrice => 'Дұрыс бағаны енгізіңіз';

  @override
  String get requiredIfEmailEmpty => 'Email көрсетілмесе, міндетті';

  @override
  String get submitInquiry => 'Өтінішті жіберу';

  @override
  String get couldNotLoadServices => 'Қызметтерді жүктеу мүмкін болмады';

  @override
  String get noServicesFound => 'Қызметтер табылмады';

  @override
  String get noServicesAvailable => 'Қазір тізімде қызметтер жоқ';

  @override
  String get applicationSettings => 'Қолданба баптаулары';

  @override
  String get userGuides => 'Пайдаланушы нұсқаулықтары';

  @override
  String get submitTopUpRequest => 'Толықтыру сұрауын жіберу';

  @override
  String get selectStars => 'Бағаны таңдаңыз';

  @override
  String get commentOptional => 'Пікір (міндетті емес)';

  @override
  String get completeWork => 'Жұмысты аяқтау';

  @override
  String get submitReview => 'Пікір жіберу';

  @override
  String get markAllAsRead => 'Барлығын оқылды деп белгілеу';

  @override
  String get notFound => 'Табылмады';

  @override
  String get placeOrder => 'Тапсырыс беру';

  @override
  String get notification => 'Хабарландыру';

  @override
  String get typeMessageHint => 'Хабарлама жазыңыз...';

  @override
  String get rejectPrice => 'Бағаны қабылдамау';

  @override
  String get acceptPrice => 'Бағаны қабылдау';

  @override
  String get cancelPrice => 'Бағаны болдырмау';

  @override
  String get hideRequest => 'Сұрауды жасыру';

  @override
  String get updateStatus => 'Күйді жаңарту';

  @override
  String get review => 'Пікір';

  @override
  String get saved => 'Сақталды';

  @override
  String get noNotificationsYet => 'Хабарландырулар әзірге жоқ';

  @override
  String get errorLoadingEquipment => 'Техниканы жүктеу қатесі';

  @override
  String get priceMustBePositive => 'Баға нөлден жоғары болуы керек';

  @override
  String get priceMaximumExceeded => 'Баға 100 000-нан аспауы керек';

  @override
  String get notSupportedYet => 'Әзірге қолдау көрсетілмейді';

  @override
  String get errorLoadingProfile => 'Профильді жүктеу мүмкін болмады';

  @override
  String get tapToRetry => 'Қайталау үшін басыңыз';

  @override
  String get announcements => 'Хабарландырулар';

  @override
  String get noMessagesYet => 'Хабарламалар әзірге жоқ';

  @override
  String get unknownEquipment => 'Белгісіз техника';

  @override
  String get pending => 'Күтілуде';

  @override
  String get orderConfirmed => 'Тапсырыс расталды';

  @override
  String get failedToConfirmOrder => 'Тапсырысты растау мүмкін болмады';

  @override
  String get chatLocked => 'Чат бұғатталған';

  @override
  String get priceOffer => 'Баға ұсынысы';

  @override
  String offeredPrice(String price) {
    return 'Ұсынылғаны: $price';
  }

  @override
  String get topUpAdded => 'Толықтыру қосылды';

  @override
  String get failedToCompleteTopUp => 'Толықтыруды аяқтау мүмкін болмады';

  @override
  String get remainingTime => 'Қалған уақыт';

  @override
  String get bestValue => 'ЕҢ ТИІМДІ';

  @override
  String activeRequestCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count белсенді сұрау',
      one: '1 белсенді сұрау',
    );
    return '$_temp0';
  }

  @override
  String minutesRead(int count) {
    return '$count мин оқу';
  }

  @override
  String get pleaseSelectCategory => 'Санатты таңдаңыз';

  @override
  String get pleaseSelectEquipment => 'Техниканы таңдаңыз';

  @override
  String get pleaseSelectPrice => 'Бағаны таңдаңыз';

  @override
  String get pleaseSelectLocation => 'Орналасқан жерді таңдаңыз';

  @override
  String get pleaseSelectDate => 'Күнді таңдаңыз';

  @override
  String get pleaseSelectTime => 'Уақытты таңдаңыз';

  @override
  String get noRequestHistory => 'Сұраулар тарихы әзірге бос';

  @override
  String get noOrderHistoryDescription => 'Тапсырыстар тарихы әзірге бос';

  @override
  String get reviewSubmitted => 'Пікір жіберілді';

  @override
  String get failedToSubmitReview => 'Пікірді жіберу мүмкін болмады';

  @override
  String get failedToCancelOrder => 'Тапсырысты болдырмау мүмкін болмады';

  @override
  String get failedToCancelRequest => 'Сұрауды болдырмау мүмкін болмады';

  @override
  String get saveFailed => 'Сақтау мүмкін болмады';

  @override
  String get heroPlatformTag => 'ҚАЗАҚСТАНДАҒЫ №1 ЖАЛДАУ ПЛАТФОРМАСЫ';

  @override
  String get heroTitle => 'Техниканы минуттар ішінде\nтауып, жалдаңыз';

  @override
  String get allLocations => 'Барлық қалалар';

  @override
  String get getStarted => 'Бастау';

  @override
  String get services => 'Қызметтер';

  @override
  String get seeAll => 'Барлығы';

  @override
  String get popularRents => 'Танымал жалдаулар';

  @override
  String get errorLoadingServices => 'Қызметтерді жүктеу қатесі';

  @override
  String get selectLanguage => 'Тілді таңдаңыз';

  @override
  String get topRated => 'Үздік';

  @override
  String get available => 'Қолжетімді';

  @override
  String get booked => 'Жалдауда';

  @override
  String get perDay => '/ күн';

  @override
  String get heavyEquipmentRentals => 'АУЫР ТЕХНИКА ЖАЛДАУ';

  @override
  String get initializingSystems => 'ЖҮЙЕ ІСКЕ ҚОСЫЛУДА...';

  @override
  String get serverWarmingUp => 'Сервер іске қосылуда, күте тұрыңыз...';

  @override
  String get save => 'Сақтау';

  @override
  String get cancel => 'Болдырмау';

  @override
  String get confirm => 'Растау';

  @override
  String get delete => 'Жою';

  @override
  String get edit => 'Өзгерту';

  @override
  String get retry => 'Қайталау';

  @override
  String get refresh => 'Жаңарту';

  @override
  String get close => 'Жабу';

  @override
  String get send => 'Жіберу';

  @override
  String get submit => 'Жіберу';

  @override
  String get upload => 'Жүктеу';

  @override
  String get create => 'Жасау';

  @override
  String get accept => 'Қабылдау';

  @override
  String get reject => 'Қабылдамау';

  @override
  String get manage => 'Басқару';

  @override
  String get viewAll => 'Барлығын көру';

  @override
  String get goBack => 'Артқа';

  @override
  String get search => 'Іздеу';

  @override
  String get repeat => 'Қайталау';

  @override
  String get crop => 'Қию';

  @override
  String get somethingWentWrong => 'Бірдеңе дұрыс болмады!';

  @override
  String get loading => 'Жүктелуде...';

  @override
  String get noCategories => 'Санаттар қолжетімді емес';

  @override
  String get phoneNumber => 'Телефон нөмірі';

  @override
  String get email => 'Email';

  @override
  String get password => 'Құпия сөз';

  @override
  String get username => 'Пайдаланушы аты';

  @override
  String get city => 'Қала';

  @override
  String get street => 'Көше';

  @override
  String get address => 'Мекен-жай';

  @override
  String get model => 'Модель';

  @override
  String get capacity => 'Сыйымдылық';

  @override
  String get comments => 'Пікірлер';

  @override
  String get message => 'Хабарлама';

  @override
  String get name => 'Аты';

  @override
  String get fullName => 'Толық аты-жөні';

  @override
  String get firstName => 'Аты';

  @override
  String get lastName => 'Тегі';

  @override
  String get offeredRate => 'Ұсынылған баға';

  @override
  String get location => 'Мекен-жай';

  @override
  String get dateAndTime => 'Күн мен уақыт';

  @override
  String get priceKZT => 'Баға (₸)';

  @override
  String get priceRateLabel => 'Тариф';

  @override
  String get privateOwner => 'ЖЕКЕ ИЕ';

  @override
  String get loginSubtitle => 'Тоқтаған жеріңізден жалғастырыңыз';

  @override
  String get signingIn => 'Кіру...';

  @override
  String get sendOtp => 'Код жіберу';

  @override
  String get verifying => 'Тексерілуде...';

  @override
  String get verifyOtp => 'Кодты растау';

  @override
  String get changePhoneNumber => 'Нөмірді өзгерту';

  @override
  String get registrationFailed => 'Тіркеу сәтсіз. Қайталаңыз.';

  @override
  String get otpSubtitle => 'Жіберілген 6 санды кодты енгізіңіз';

  @override
  String get creating => 'ЖАСАЛУДА...';

  @override
  String get sendCode => 'КОД ЖІБЕРУ';

  @override
  String get sending => 'ЖІБЕРІЛУДЕ...';

  @override
  String get pleaseEnterPhone => 'Телефон нөміріңізді енгізіңіз';

  @override
  String get validKazakhPhone => 'Қазақстан нөмірін енгізіңіз (+7XXXXXXXXXX)';

  @override
  String get failedSendOtp => 'Код жіберілмеді. Қайталап көріңіз.';

  @override
  String get pleaseEnterBothFields =>
      'Пайдаланушы аты мен құпия сөзді енгізіңіз';

  @override
  String get pleaseEnterOtp => 'Растау кодын енгізіңіз';

  @override
  String get otpMustBeSixDigits => 'Код 6 саннан тұруы керек';

  @override
  String get invalidExpiredOtp => 'Жарамсыз немесе мерзімі өткен код';

  @override
  String get createAccount => 'Тіркелу';

  @override
  String get joinCommunity => 'Бүгін Prokat-қа қосылыңыз';

  @override
  String get registerWithPhone => 'Телефон арқылы тіркелу';

  @override
  String get useEmailPassword => 'Email және құпия сөз пайдалану';

  @override
  String get alreadyRegistered => 'Тіркелген бе?';

  @override
  String get loginLink => 'Кіру';

  @override
  String get resetPassword => 'Құпия сөзді қалпына келтіру';

  @override
  String get checkYourEmail => 'Поштаңызды тексеріңіз';

  @override
  String get sendRecoveryLink => 'СІЛТЕМЕ ЖІБЕРУ';

  @override
  String get backToLogin => 'КІРУГЕ ҚАЙТУ';

  @override
  String get resendLink => 'Қайта жіберу';

  @override
  String get emailAddress => 'Электрондық пошта мекенжайы';

  @override
  String get pleaseEnterEmail => 'Электрондық поштаңызды енгізіңіз';

  @override
  String get pleaseEnterAllFields => 'Тіркеу өрістерін толтырыңыз';

  @override
  String get enterRegisteredEmail =>
      'Құпия сөзді қалпына келтіру сілтемесін алу үшін тіркелген email-ді енгізіңіз.';

  @override
  String recoverySentTo(String email) {
    return 'Қалпына келтіру сілтемесі $email мекенжайына жіберілді';
  }

  @override
  String get navHome => 'Басты бет';

  @override
  String get navMyFleet => 'Менің паркім';

  @override
  String get navOrders => 'Тапсырыстар';

  @override
  String get navChats => 'Чаттар';

  @override
  String get navSearch => 'Іздеу';

  @override
  String get navCreate => 'Жасау';

  @override
  String get navDashboard => 'Басқару тақтасы';

  @override
  String get navMap => 'Карта';

  @override
  String get navMyRequests => 'Менің сұраныстарым';

  @override
  String get navFavorites => 'Таңдаулылар';

  @override
  String get navMyOrders => 'Менің тапсырыстарым';

  @override
  String get navEquipment => 'Техника';

  @override
  String get navBookings => 'Брондаулар';

  @override
  String get navRequests => 'Сұраныстар';

  @override
  String get navProfile => 'Профиль';

  @override
  String get navSettings => 'Параметрлер';

  @override
  String get navLogin => 'Кіру';

  @override
  String get selectService => 'Қызметті таңдаңыз';

  @override
  String get myOrders => 'Менің тапсырыстарым';

  @override
  String get orderHistory => 'Тапсырыстар тарихы';

  @override
  String get loginToViewBookings => 'Брондауларды көру үшін кіріңіз';

  @override
  String get loadingOrders => 'Тапсырыстар жүктелуде...';

  @override
  String get errorLoadingOrders => 'Тапсырыстарды жүктеу қатесі';

  @override
  String get noBookingsFound => 'Брондаулар табылмады';

  @override
  String get updateWorkStatus => 'Жұмыс күйін жаңарту';

  @override
  String get statusUpdated => 'Күй жаңартылды';

  @override
  String get failedSaveStatus => 'Күйді сақтау сәтсіз аяқталды';

  @override
  String get confirmOrder => 'Тапсырысты растау';

  @override
  String get counter => 'Қарсы ұсыныс';

  @override
  String get acceptOrder => 'Тапсырысты қабылдау';

  @override
  String get startWork => 'Жұмысты бастау';

  @override
  String get orderCancelled => 'Тапсырыс жойылды';

  @override
  String get cancelBooking => 'Брондауды жою';

  @override
  String get confirmCancellation => 'Жоюды растау';

  @override
  String get yesCancel => 'Иә, жою';

  @override
  String get acceptOrderQuestion => 'Тапсырысты қабылдау?';

  @override
  String get openIn2GIS => '2GIS-те ашу';

  @override
  String get openInGoogleMaps => 'Google Maps-та ашу';

  @override
  String get deliveryAddress => 'Жеткізу мекен-жайы';

  @override
  String get noActiveOrders => 'Белсенді тапсырыс жоқ';

  @override
  String get draftIncomplete => 'ЖОБА АЯҚТАЛМАҒАН';

  @override
  String get finishBookingRequest => 'Брондау сұрауын аяқтаңыз';

  @override
  String get resume => 'ЖАЛҒАСТЫРУ';

  @override
  String get rejectOrder => 'Тапсырысты қабылдамау';

  @override
  String get rejectOrderQuestion =>
      'Бұл тапсырысты қабылдамауға сенімдісіз бе?';

  @override
  String get cancelOrderQuestion => 'Бұл тапсырысты жоюға сенімдісіз бе?';

  @override
  String get acceptOrderConfirmation =>
      'Бұл тапсырысты қабылдауға сенімдісіз бе?';

  @override
  String acceptBookingFor(String name) {
    return '$name үшін брондауды қабылдау?';
  }

  @override
  String get yesReject => 'Иә, қабылдамау';

  @override
  String get no => 'Жоқ';

  @override
  String get decline => 'Қабылдамау';

  @override
  String minutesLeft(int minutes) {
    return '$minutes мин қалды';
  }

  @override
  String get volume => 'Көлем';

  @override
  String get noOrderHistory => 'Тапсырыс тарихы жоқ';

  @override
  String get cancelReasonClientNotRespond => 'Клиент жауап бермеді';

  @override
  String get cancelReasonEquipUnavailable => 'Техника қолжетімсіз';

  @override
  String get cancelReasonPricingIssue => 'Баға мәселесі';

  @override
  String get cancelReasonSchedulingConflict => 'Кесте қайшылығы';

  @override
  String get cancelReasonDidNotShowUp => 'Келмеді';

  @override
  String get cancelReasonChangedMind => 'Ойын өзгертті';

  @override
  String get cancelReasonEquipNotSuitable => 'Техника сәйкес емес';

  @override
  String get cancelReasonOther => 'Басқа';

  @override
  String get workStatusPending => 'Күту';

  @override
  String get workStatusOnMyWay => 'Жолдамын';

  @override
  String get workStatusOnSite => 'Жерде';

  @override
  String get workStatusStartWork => 'Жұмысты бастау';

  @override
  String get workStatusPostpone => 'Кейінге қалдыру';

  @override
  String get workStatusStopWork => 'Жұмысты тоқтату';

  @override
  String get workStatusCompleteWork => 'Жұмысты аяқтау';

  @override
  String get workStatusCancelJob => 'Тапсырманы жою';

  @override
  String get myEquipment => 'Менің технікам';

  @override
  String get addEquipment => 'Техника қосу';

  @override
  String get noEquipmentListed => 'Техника әлі қосылмаған';

  @override
  String get online => 'ОНЛАЙН';

  @override
  String get offline => 'ОФЛАЙН';

  @override
  String get repair => 'ЖӨНДЕУ';

  @override
  String get couldNotAddEquipment => 'Техника қосу мүмкін болмады';

  @override
  String get equipmentNameLabel => 'ТЕХНИКА АТЫ';

  @override
  String get equipmentNameHint => 'мыс. Ассенизатор';

  @override
  String get modelLabel => 'МОДЕЛЬ';

  @override
  String get modelHint => 'мыс. КАМАЗ-65115';

  @override
  String get plateNumberLabel => 'МЕМЛЕКЕТТІК НӨМІР';

  @override
  String get plateNumberHint => 'мыс. 777 ABC 01';

  @override
  String get availableForRent => 'Жалдауға қолжетімді';

  @override
  String get operatingStatus => 'Жұмыс күйі';

  @override
  String get submitForReview => 'Тексеруге жіберу';

  @override
  String get submittedForReview => 'Техника тексеруге жіберілді';

  @override
  String get failedToSubmit => 'Жіберу сәтсіз аяқталды';

  @override
  String get equipmentUpdated => 'Техника жаңартылды';

  @override
  String get pleaseEnterValidValues => 'Дұрыс мәндерді енгізіңіз';

  @override
  String get equipmentUpdatedSuccessfully => 'Техника сәтті жаңартылды';

  @override
  String get failedToUpdateEquipment => 'Техниканы жаңарту сәтсіз аяқталды';

  @override
  String get editEquipment => 'Техниканы өзгерту';

  @override
  String get ownerComment => 'Иесінің пікірі';

  @override
  String get rentCondition => 'Жалдау шарттары';

  @override
  String get fullLoadOnly => 'Тек толық жүктеу...';

  @override
  String get commentNotes => 'Пікір / Ескертпе';

  @override
  String get cropEquipmentPhoto => 'Техника фотосын қию';

  @override
  String get deletePhotoQuestion => 'Фотоны жою?';

  @override
  String get deletePhotoConfirmation => 'Бұл әрекетті болдырмауға болмайды.';

  @override
  String get failedAddPriceEntry => 'Баға қосу сәтсіз аяқталды';

  @override
  String get failedUpdatePriceEntry => 'Бағаны жаңарту сәтсіз аяқталды';

  @override
  String get failedSavePriceEntry => 'Бағаны сақтау сәтсіз аяқталды';

  @override
  String get couldNotSaveEquipment => 'Техниканы сақтау мүмкін болмады';

  @override
  String get viewAllLocations => 'Барлық мекен-жайларды көру';

  @override
  String get addAddressManually => 'Мекен-жайды қолмен қосу';

  @override
  String get setOnMap => 'Картада белгілеу';

  @override
  String get noPricesListed => 'Бағалар жоқ';

  @override
  String get bookEquipment => 'Тапсырыс';

  @override
  String get requestEquipment => 'Сұраныс';

  @override
  String get perHour => '/ сағат';

  @override
  String get perTrip => '/ рейс';

  @override
  String get retryNow => 'Қайталау';

  @override
  String get selectCity => 'Қаланы таңдаңыз';

  @override
  String get required => 'МІНДЕТТІ';

  @override
  String get equipmentAdded => 'Техника қосылды';

  @override
  String get updateDetails => 'Деректерді жаңарту';

  @override
  String get status => 'Күй';

  @override
  String get perM3 => '/ м³';

  @override
  String get myRequests => 'Менің сұраныстарым';

  @override
  String get createRequest => 'Сұраныс жасау';

  @override
  String get loginToViewRequests => 'Сұраныстарды көру үшін кіріңіз';

  @override
  String get errorLoadingRequests => 'Сұраныстарды жүктеу қатесі';

  @override
  String get noActiveRequests => 'Белсенді сұраныстарыңыз жоқ';

  @override
  String get createNewRequest => 'Жаңа сұраныс жасау';

  @override
  String get requiredCapacity => 'Қажетті сыйымдылық';

  @override
  String get capacityHint => '10 M3';

  @override
  String get offeredRateHint => 'Төлеуге дайын бағаңыз';

  @override
  String get additionalDetails => 'Қосымша мәліметтер...';

  @override
  String get newRequestBadge => 'ЖАҢА СҰРАНЫС';

  @override
  String get offerSentBadge => 'ҰСЫНЫС ЖІБЕРІЛДІ';

  @override
  String get cancelRequest => 'Сұранысты жою?';

  @override
  String get requestCancelled => 'Сұраныс жойылды';

  @override
  String get noChats => 'Чаттар жоқ';

  @override
  String get chatsActiveTab => 'Белсенді';

  @override
  String get chatsArchiveTab => 'Мұрағат';

  @override
  String get noArchivedChats => 'Мұрағатталған чаттар жоқ';

  @override
  String get youHaveNoArchivedChats =>
      'Аяқталған және болдырылмаған чаттар осында пайда болады.';

  @override
  String get deliverTo => 'ЖЕТКІЗУ ОРНЫ';

  @override
  String get houseBuilding => 'Үй / Корпус / Кіреберіс';

  @override
  String get myHouseHint => 'Менің үйім';

  @override
  String get streetHint => 'Стапаева 123';

  @override
  String get cityHint => 'Атырау';

  @override
  String get saveLocation => 'Мекен-жайды сақтау';

  @override
  String get confirmLocation => 'Орналасуды растау';

  @override
  String get failedCreateAddress => 'Мекен-жай жасау мүмкін болмады';

  @override
  String get failedSaveAddress => 'Мекен-жайды сақтау сәтсіз аяқталды';

  @override
  String get noEquipmentLocations => 'Техника мекен-жайлары жоқ';

  @override
  String get equipmentLocations => 'Техника мекен-жайлары';

  @override
  String get searchAddress => 'Мекен-жай іздеу';

  @override
  String get setDeliveryAddress => 'Жеткізу мекен-жайын белгілеу';

  @override
  String get setEquipmentLocation => 'Техника орнын белгілеу';

  @override
  String get equipmentMap => 'Техника картасы';

  @override
  String get failedCreateLocation => 'Орынды жасау сәтсіз аяқталды';

  @override
  String get loginToViewFavorites => 'Таңдаулыларды көру үшін кіріңіз';

  @override
  String get displayName => 'Аты-жөні';

  @override
  String get supportUsTitle => 'Бізді қолдаңыз';

  @override
  String get donateOrHelp => 'Бізге өсуге көмектесіңіз';

  @override
  String get termsConditions => 'Пайдалану шарттары';

  @override
  String get helpSupportTitle => 'Анықтама және қолдау';

  @override
  String get preferences => 'ПАРАМЕТРЛЕР';

  @override
  String get pushNotifications => 'Push-хабарландырулар';

  @override
  String get bookingAlerts => 'Жаңа брондаулар туралы хабарландырулар';

  @override
  String get biometricLogin => 'Биометриялық кіру';

  @override
  String get secureAccess => 'FaceID/TouchID арқылы қауіпсіз кіру';

  @override
  String get supportSection => 'ҚОЛДАУ';

  @override
  String get helpCenter => 'Анықтама орталығы';

  @override
  String get termsOfService => 'Қызмет көрсету шарттары';

  @override
  String get accountSection => 'АККАУНТ';

  @override
  String get logout => 'Шығу';

  @override
  String get deleteAccount => 'Аккаунтты жою';

  @override
  String get editPhone => 'Телефонды өзгерту';

  @override
  String get editName => 'Атын өзгерту';

  @override
  String get setUsername => 'Пайдаланушы атын орнату';

  @override
  String get ownerDashboard => 'Иесінің тақтасы';

  @override
  String get becomeOwner => 'Иесіне айналу';

  @override
  String get registrationStatus => 'Тіркелу күйі';

  @override
  String get appSettings => 'Қолданба параметрлері';

  @override
  String get paymentsBalance => 'Төлемдер және баланс';

  @override
  String get totalBalance => 'Жалпы баланс';

  @override
  String get save15Percent => '15% үнемдеу';

  @override
  String get topUpMinutes => 'Минуттарды толтыру';

  @override
  String get payWithKaspi => 'Kaspi.kz арқылы төлеу';

  @override
  String get submitManualRequest => 'Қолмен сұраныс жіберу (офлайн төлем)';

  @override
  String get legalInformation => 'Заңды ақпарат';

  @override
  String get documents => 'Құжаттар';

  @override
  String get idPassport => 'Жеке куәлік / Паспорт';

  @override
  String get proofOfAddress => 'Мекен-жайды растау';

  @override
  String get businessLicense => 'Бизнес лицензиясы (міндетті емес)';

  @override
  String get firstNameHint => 'Атыңызды енгізіңіз';

  @override
  String get lastNameHint => 'Тегіңізді енгізіңіз';

  @override
  String get phoneHint => 'Телефон нөміріңізді енгізіңіз';

  @override
  String get emailHint => 'Email-іңізді енгізіңіз (міндетті емес)';

  @override
  String get cityInputHint => 'Қалаңызды енгізіңіз';

  @override
  String get camera => 'Камера';

  @override
  String get photoGallery => 'Галерея';

  @override
  String get cropProfilePicture => 'Профиль фотосын қию';

  @override
  String get initializationError => 'ИНИЦИАЛИЗАЦИЯ ҚАТЕСІ';

  @override
  String get initializationErrorMessage =>
      'Сессия жүктелмеді немесе байланыс үзілді. Желіні тексеріп, қайталаңыз.';

  @override
  String get retryConnection => 'ҚОСЫЛУДЫ ҚАЙТАЛАУ';

  @override
  String get reconnecting => 'ҚАЙТА ҚОСЫЛУДА...';

  @override
  String get information => 'Ақпарат';

  @override
  String get prices => 'Бағалар';

  @override
  String get allRatingOptionsListed => 'Барлық тарифтер қосылды';

  @override
  String get pleaseEnterValidPrice => 'Дұрыс баға енгізіңіз';

  @override
  String get priceEntryAdded => 'Тариф қосылды';

  @override
  String get priceEntrySaved => 'Тариф сақталды';

  @override
  String get editRate => 'Тарифті өзгерту';

  @override
  String get newRate => 'Жаңа тариф';

  @override
  String get add => 'Қосу';

  @override
  String get technicalSpecs => 'Техникалық сипаттамалар';

  @override
  String get pleaseFillMissingInfo => 'Барлық міндетті өрістерді толтырыңыз';

  @override
  String get noSpecsConfigured => 'Сипаттамалар әлі конфигурацияланбаған';

  @override
  String get invalidNumber => 'Жарамсыз сан';

  @override
  String get updateFailed => 'Жаңарту сәтсіз аяқталды';

  @override
  String get currentLocation => 'Ағымдағы орналасу';

  @override
  String get enterLocation => 'Орналасуды енгізіңіз';

  @override
  String get equipmentBaseLocation => 'Техниканың негізгі орны';

  @override
  String get dangerZone => 'ҚАУІПТІ АЙМАҚ';

  @override
  String get deleteEquipmentWarning =>
      'Техниканы жою оны инвентарьдан, барлық баға және тарих деректерімен бірге біржола өшіреді.';

  @override
  String get deleteEquipment => 'Техниканы жою';

  @override
  String get deleteEquipmentQuestion => 'Техниканы жою керек пе?';

  @override
  String get deleteEquipmentConfirmation =>
      'Бұл жарнаманы маркетплейстен жойып, барлық жалдау тарихын өшіреді.';

  @override
  String get failedToUploadPhoto => 'Фотоны жүктеу сәтсіз аяқталды';

  @override
  String get failedToDeletePhoto => 'Фотоны жою сәтсіз аяқталды';

  @override
  String get failedToSetCoverPhoto => 'Мұқабаны орнату сәтсіз аяқталды';

  @override
  String get maxPhotosReached => '5 фото шегіне жетті';

  @override
  String get noPhotosYet => 'Фото жоқ';

  @override
  String get selectLocation => 'Орынды таңдаңыз';

  @override
  String get noSavedLocations => 'Сақталған мекен-жайлар жоқ';

  @override
  String get createNewOnMap => 'Картада жаңа мекен-жай жасау';

  @override
  String get chooseFromGallery => 'Галереядан таңдау';

  @override
  String get takePhoto => 'Фото түсіру';

  @override
  String get setAsCover => 'Мұқаба ретінде орнату';

  @override
  String get deletePhoto => 'Фотоны жою';

  @override
  String get cancelRequestAction => 'Сұранысты болдырмау';

  @override
  String get cancelRequestContent =>
      'Бұл сұранысты болдырмағыңыз келе ме? Бұл әрекетті кері қайтару мүмкін емес.';

  @override
  String get newRequest => 'Жаңа сұраныс';

  @override
  String get deliveryLocation => 'Жеткізу орны';

  @override
  String get equipmentSpecs => 'Техника сипаттамалары';

  @override
  String get selectDate => 'Күнді таңдаңыз';

  @override
  String get selectTime => 'Уақытты таңдаңыз';

  @override
  String get requiredHint => '* Міндетті';

  @override
  String get requestCreated => 'Сұраныс жасалды';

  @override
  String get noRequestsAtMoment => 'Қазіргі уақытта сұраныстар жоқ';

  @override
  String get viewBooking => 'Брондауды қарау';

  @override
  String get viewOffer => 'Ұсынысты қарау';

  @override
  String get sendOffer => 'Ұсыныс жіберу';

  @override
  String get offerUpdated => 'Ұсыныс жаңартылды';

  @override
  String get selectEquipment => 'Техника таңдаңыз';

  @override
  String get startDate => 'Басталу күні';

  @override
  String get startTime => 'Басталу уақыты';

  @override
  String get optionalNotesHint => 'Қосымша ескертпелер немесе шарттар...';

  @override
  String get pastRequests => 'ӨТКЕН СҰРАНЫСТАР';

  @override
  String get requestsHistory => 'Сұраныстар тарихы';

  @override
  String get activeRequestsTooltip => 'Белсенді сұраныстар';

  @override
  String get noHistoryFound => 'Тарих табылмады';

  @override
  String get viewedBadge => 'ҚАРАЛДЫ';

  @override
  String get acceptedBadge => 'ҚАБЫЛДАНДЫ';

  @override
  String get hiddenBadge => 'ЖАСЫРЫЛҒАН';

  @override
  String get requestLabel => 'Сұраныс';

  @override
  String get addLocation => 'Орынды қосу';

  @override
  String get addAddress => 'Мекен-жай қосу';

  @override
  String get addressCreated => 'Мекен-жай жасалды';

  @override
  String get selectAddress => 'МЕКЕН-ЖАЙ ТАҢДАУ';

  @override
  String get noRecentAddresses => 'Жақында қолданылған мекен-жайлар жоқ';

  @override
  String get chooseOnMap => 'КАРТАДАН ТАҢДАУ';

  @override
  String get hardwareRestriction => 'ҚҰРЫЛҒЫ ШЕКТЕУІ';

  @override
  String get mapMobileOnly => 'Карта тек мобильді құрылғыларда қолжетімді.';

  @override
  String get viewEquipmentList => 'Техника тізімін қарау';

  @override
  String get saveAddress => 'Мекен-жайды сақтау';

  @override
  String get back => 'Артқа';

  @override
  String get backToEquipment => 'Техникаға оралу';

  @override
  String get selectCapacityModel => 'СЫЙЫМДЫЛЫҚ / МОДЕЛЬ ТАҢДАУ';

  @override
  String get pricingRates => 'БАҒАЛАР';

  @override
  String get startBooking => 'БРОНДАУ';

  @override
  String get addDisplayName => 'Атыңызды қосыңыз';

  @override
  String get helpSupportSubtitle =>
      'Көмек алу немесе қолдау қызметіне хабарласу';

  @override
  String get ownerDashboardSubtitle => 'Активтер мен кірісті басқарыңыз';

  @override
  String get becomeOwnerSubtitle => 'Техниканызды жалға беріп табыс табыңыз';

  @override
  String get requestStatus => 'Сұраныс';

  @override
  String get submittedOn => 'Жіберілді';

  @override
  String get nameUpdated => 'Аты жаңартылды';

  @override
  String get failedSaveName => 'Атты сақтау сәтсіз аяқталды';

  @override
  String get usernameCannotBeChanged =>
      'Пайдаланушы атын орнатқаннан кейін өзгерту мүмкін емес.';

  @override
  String get chooseUsername =>
      'Пайдаланушы атын таңдаңыз. Оны тек бір рет орнатуға болады.';

  @override
  String get logoutFailed => 'Шығу қатесі';

  @override
  String get activeOrders => 'Белсенді тапсырыстар';

  @override
  String get noOrdersYet => 'Тапсырыстар жоқ';

  @override
  String get enterName => 'Атыңызды енгізіңіз';

  @override
  String get zeroOrders => '0 тапсырыс';

  @override
  String get newOrderCount => 'жаңа тапсырыс';

  @override
  String get confirmedOrderCount => 'расталған тапсырыс';

  @override
  String get paymentHistory => 'Төлем тарихы';

  @override
  String get billingTiers => 'Тариф деңгейлері';

  @override
  String get runningLow => 'Минуттар азайып барады?';

  @override
  String get topUpViaKaspi => 'Kaspi арқылы минут толтыру';

  @override
  String get usageTrend => 'Пайдалану үрдісі';

  @override
  String get last7Days => 'Соңғы 7 күн';

  @override
  String get verifiedOwner => 'Тексерілген иесі';

  @override
  String get appSettingsSubtitle => 'Хабарландырулар, Құпиялылық, Тема';

  @override
  String get helpFaqsSubtitle =>
      'Жиі қойылатын сұрақтар, қолдау қызметімен байланыс';

  @override
  String get fullyVerified => 'Аккаунт';

  @override
  String get activeEquipment => 'Белсенді техника';

  @override
  String get dailyCost => 'Күнделікті шығын';

  @override
  String get ownerProfile => 'Иесінің профилі';

  @override
  String get selectPackage => 'Пакет таңдаңыз';

  @override
  String get recentPayments => 'Соңғы төлемдер';

  @override
  String get completeRegistration => 'Тіркелуді аяқтаңыз';

  @override
  String get submitDocumentsHint =>
      'Техниканы жалға беруді бастау үшін қажетті құжаттарды жіберіңіз.';

  @override
  String get verificationInProgress => 'Тексеру жүргізілуде';

  @override
  String get reviewingDocuments => 'Құжаттарыңызды тексеруде.';

  @override
  String get youAreVerified => 'Сіз тексерілдіңіз!';

  @override
  String get canListEquipment =>
      'Енді техниканы жалға беруге орналастыра аласыз.';

  @override
  String get verificationFailed => 'Тексеру сәтсіз аяқталды';

  @override
  String get updateDocumentsHint => 'Құжаттарыңызды жаңартып, қайта жіберіңіз.';

  @override
  String get submitForVerification => 'Тексеруге жіберу';

  @override
  String get underReview => 'Тексерілуде';

  @override
  String get viewListings => 'Жарнамаларды қарау';

  @override
  String get resubmitDocuments => 'Құжаттарды қайта жіберу';

  @override
  String get uploaded => 'Жүктелді';

  @override
  String get requiredDoc => 'Міндетті';

  @override
  String get becomeServiceProvider => 'Қызмет көрсетуші болу';

  @override
  String get joinTeamHint =>
      'Біздің командаға қосылып, жабдықтарыңызды немесе қызметтеріңізді клиенттерге ұсыныңыз.';

  @override
  String get requestReviewedHint =>
      'Сіздің өтінішіңіз одан әрі өңдеу үшін әкімші тарапынан қаралады.';

  @override
  String get enterValidEmail => 'Жарамды email енгізіңіз';

  @override
  String get messageHint =>
      'Ұсына алатын қызметіңізді немесе жабдығыңызды қысқаша сипаттаңыз.';

  @override
  String get firstNameRequired => 'Аты міндетті';

  @override
  String get lastNameRequired => 'Тегі міндетті';

  @override
  String get phoneNumberRequired => 'Телефон нөмірі міндетті';

  @override
  String get cityRequired => 'Қала міндетті';

  @override
  String get messageRequired => 'Қысқаша хабарлама қосыңыз';

  @override
  String get submitRequest => 'Өтінішті жіберу';

  @override
  String get resubmitRequest => 'Өтінішті қайта жіберу';

  @override
  String get updateRequest => 'Өтінішті жаңарту';

  @override
  String get statusAccepted => 'Қабылданды';

  @override
  String get statusAcceptedSubtitle =>
      'Сіз қазір қызмет көрсетуші ретінде бекітілдіңіз.';

  @override
  String get statusRejected => 'Қабылданбады';

  @override
  String get statusRejectedSubtitle =>
      'Әкімшінің пікірін қарап, өтінішіңізді жаңартыңыз.';

  @override
  String get statusUnderReview => 'Қаралуда';

  @override
  String get statusUnderReviewSubtitle =>
      'Сіздің өтінішіңіз жіберілді және қаралуда.';

  @override
  String get adminComment => 'Әкімші пікірі';

  @override
  String get requestAcceptedInfo =>
      'Сіздің өтінішіңіз қабылданды. Деректерді өзгерту қажет болса, қолдау қызметіне хабарласыңыз.';

  @override
  String get noteDescribeHint =>
      'Ескертпе: өтінішіңізді тезірек қарай алуымыз үшін қызметіңізді/жабдығыңызды қысқаша сипаттаңыз.';

  @override
  String get requestSubmitted => 'Өтініш жіберілді';

  @override
  String get requestUpdated => 'Өтініш жаңартылды';

  @override
  String get notifications => 'Хабарландырулар';

  @override
  String get newBookingRequests => 'Жаңа брондау сұраулары';

  @override
  String get messages => 'Хабарлар';

  @override
  String get reminders => 'Еске салулар';

  @override
  String get safetyAndRules => 'Қауіпсіздік және ережелер';

  @override
  String get cancellationPolicy => 'Бас тарту саясаты';

  @override
  String get moderate => 'Орташа';

  @override
  String get damagePolicy => 'Зиян саясаты';

  @override
  String get standardCoverage => 'Стандартты жабу';

  @override
  String get deactivateAccount => 'Аккаунтты өшіру';

  @override
  String get clientRequests => 'Клиент сұраулары';

  @override
  String get noNewRequests => 'Жаңа сұраулар жоқ';

  @override
  String get newRequestSingular => 'жаңа сұрау';

  @override
  String get newRequestsPlural => 'жаңа сұраулар';

  @override
  String get noOrders => 'Тапсырыстар жоқ';

  @override
  String get orderUnit => 'Тапсырыс';

  @override
  String get ordersUnit => 'Тапсырыс';

  @override
  String get myFleet => 'Менің техникам';

  @override
  String get equipmentItemSingular => 'Бірлік';

  @override
  String get equipmentItemsPlural => 'Бірліктер';

  @override
  String get noItemsTapToAdd => 'Техника жоқ • Қосу үшін басыңыз';

  @override
  String get noEquipmentFound => 'Техника табылмады';

  @override
  String get onlineStatus => 'Желіде';

  @override
  String get offlineStatus => 'Желіде емес';

  @override
  String get minutesBalance => 'Минут балансы';

  @override
  String get minutesUnit => 'Мин';

  @override
  String get burnRate => 'Жұмсалу жылдамдығы';

  @override
  String get hello => 'Сәлем!';

  @override
  String get reviews => 'пікір';

  @override
  String get rentAnEquipment => 'Техника жалдау';

  @override
  String get findAndRent => 'Тауып жалдау';

  @override
  String get browseHeavyEquipment => 'Жаныңыздағы ауыр техника';

  @override
  String get poa => 'СБ';

  @override
  String get loginToAddFavorites => 'Таңдаулыларды қосу үшін кіріңіз';

  @override
  String get noSavedMachinery => 'САҚТАЛҒАН ТЕХНИКА ЖОҚ';

  @override
  String get exploreFleet => 'ТЕХНИКАНЫ ҚАРАУ';

  @override
  String get unknownLocation => 'Белгісіз орын';

  @override
  String get noPrice => 'Бағасыз';

  @override
  String get myFavorites => 'Менің таңдаулыларым';

  @override
  String get favoritesEmptyHint =>
      'Таңдаулы деп белгілеген заттарыңыз осында пайда болады';

  @override
  String get frequentlyAskedQuestions => 'Жиі қойылатын сұрақтар';

  @override
  String get needMoreHelp => 'Қосымша көмек керек пе?';

  @override
  String get contactSupport => 'Қолдауға хабарласу';

  @override
  String get emailSupport => 'Email арқылы қолдау';

  @override
  String get usingProkat => 'Прокатты пайдалану';

  @override
  String get learnHowPlatformWorks => 'Платформаның жұмысын біліңіз';

  @override
  String get paymentsAndPricing => 'Төлемдер және бағалар';

  @override
  String get feesPayoutsBilling => 'Комиссиялар, төлемдер және шоттар';

  @override
  String get safetyAndTrust => 'Қауіпсіздік және сенім';

  @override
  String get guidelinesAndPolicies => 'Нұсқаулар мен саясаттар';

  @override
  String get accountHelp => 'Аккаунт көмегі';

  @override
  String get loginProfileSettings => 'Кіру, профиль және параметрлер';

  @override
  String get liveChat => 'Тікелей сөйлесу';

  @override
  String get callUs => 'Бізге қоңырау шалыңыз';

  @override
  String get faq1Q => 'Техниканы қалай жалдауға болады?';

  @override
  String get faq1A =>
      'Қолжетімді техниканы қараңыз, күндерді таңдаңыз және иесіне брондау сұрауын жіберіңіз.';

  @override
  String get faq2Q => 'Техникамды қалай орналастыруға болады?';

  @override
  String get faq2A =>
      'Профильге өтіп, «Техника қосу» батырмасын басыңыз. Мәліметтерді, бағаны және орынды толтырыңыз.';

  @override
  String get faq3Q => 'Төлемдер қалай жұмыс істейді?';

  @override
  String get faq3A =>
      'Төлемдер платформа арқылы қауіпсіз өңделеді. Растамас бұрын жалпы соманы көресіз.';

  @override
  String get faq4Q => 'Брондауды болдырмауға бола ма?';

  @override
  String get faq4A =>
      'Иә, техника бетінде көрсетілген иесінің болдырмау саясатына байланысты.';

  @override
  String get faq5Q => 'Техника зақымданса не істейміз?';

  @override
  String get faq5A =>
      'Мәселені дереу қосымша арқылы хабарлаңыз. Қолдау тобымыз сізге көмектеседі.';

  @override
  String get helpUsGrow => 'Бізге өсуге көмектесіңіз';

  @override
  String get theSimpleStuff => 'Қарапайым іс-әрекеттер';

  @override
  String get rateOnStore => 'Дүкенде бізге баға беріңіз';

  @override
  String get starReviewsHint =>
      '5 жұлдызды пікірлер басқаларға бізді табуға көмектеседі.';

  @override
  String get rateNow => 'Бағалау';

  @override
  String get spreadTheWord => 'Айтып тарату';

  @override
  String get shareAppHint => 'Техника қажет досыңызбен қосымшамен бөлісіңіз.';

  @override
  String get shareApp => 'Бөлісу';

  @override
  String get contributeToApp => 'Қосымшаға үлес қосу';

  @override
  String get betaTestFeedback => 'Бета-тест және пікір';

  @override
  String get reportBugsHint =>
      'Қателер туралы хабарлаңыз немесе жаңа мүмкіндіктер ұсыныңыз.';

  @override
  String get submitIdeas => 'Идея ұсыну';

  @override
  String get joinOurTeam => 'Біздің командаға қосылыңыз';

  @override
  String get lookingForDevelopers =>
      'Біз әзірлеушілер мен операциялық маман іздеп жатырмыз.';

  @override
  String get viewCareers => 'Вакансияларды қарау';

  @override
  String get fuelTheMission => 'Миссияны қолдау';

  @override
  String get buyDevsACoffee => 'Әзірлеушілерге кофе алыңыз';

  @override
  String get tipToKeepServersHint => 'Серверлерді іске асыруға шағын үлес.';

  @override
  String get donate => 'Демеу';

  @override
  String get buildingTogether => 'Біз мұны бірге құрып жатырмыз';

  @override
  String get missionStatement =>
      'Біздің миссиямыз — техниканы барлығына қолжетімді ету. Мына жолдармен бізге көмектесе аласыз.';

  @override
  String get legalStuff => 'Заңды ақпарат';

  @override
  String get lastUpdated => 'Соңғы жаңарту: 2026 жыл, мамыр';

  @override
  String get rentalEligibilityTitle => '1. Жалдау құқығы';

  @override
  String get rentalEligibilitySummary =>
      'Ауыр техниканы жалдау үшін 18+ жаста болуыңыз керек.';

  @override
  String get rentalEligibilityContent =>
      'Бұл қосымшаны пайдалана отырып, сіз кемінде 18 жаста екеніңізді және осы келісімге кіруге заңды құқығыңыз бар екенін растайсыз. Кейбір қымбат техника үшін қосымша тексеру немесе мамандандырылған лицензиялар қажет болуы мүмкін.';

  @override
  String get damageLiabilityTitle => '2. Зиян және жауапкершілік';

  @override
  String get damageLiabilitySummary =>
      'Техника сізде болған кезде сіз жауапкершілік аласыз.';

  @override
  String get damageLiabilityContent =>
      'Техника алынған күйінде қайтарылуы тиіс. Кез келген зиян, жоғалту немесе ұрлық үшін толық жауапкершілікті өз мойнына аласыз. Қалыпты тозу қабылданады, бірақ немқұрайлылық жабылмайды.';

  @override
  String get lateReturnsTitle => '3. Кеш қайтару және айыппұлдар';

  @override
  String get lateReturnsSummary =>
      'Уақытында қайтарыңыз, әйтпесе қосымша күндік мөлшерлемелер қолданылады.';

  @override
  String get lateReturnsContent =>
      'Кеш қайтару басқа пайдаланушыларға кедергі жасайды. Техника уақытында қайтарылмаса, қайтарылғанға дейін әр 24 сағат үшін күндік жалдау мөлшерлемесі алынады.';

  @override
  String get cancellationsTitle => '4. Болдырмау';

  @override
  String get cancellationsSummary =>
      '24 сағат бұрын болдырмаса толық қайтарылады.';

  @override
  String get cancellationsContent =>
      'Жалдау басталғанға дейін 24 сағат ішінде болдырмау 50% комиссиямен жабылуы мүмкін. Келмеген жағдайда толық сомасы алынады.';

  @override
  String get termsAcceptanceNotice =>
      'Қосымшаны пайдалануды жалғастыра отырып, сіз осы шарттарды оқып, олармен келіскеніңізді растайсыз.';

  @override
  String get couldNotLoadChats => 'Чаттарды жүктеу мүмкін болмады';

  @override
  String get youHaveNoChats => 'Сізде чаттар жоқ';

  @override
  String get error => 'Қате';

  @override
  String get price => 'Баға';

  @override
  String get book => 'Брондау';

  @override
  String get viewRequests => 'Сұраныстарды қарау';

  @override
  String get couldNotLoadOrders => 'Тапсырыстарды жүктеу мүмкін болмады';

  @override
  String get currentOrdersWillAppearHere =>
      'Ағымдағы тапсырыстарыңыз осында пайда болады';

  @override
  String get requestedBy => 'Сұраған';

  @override
  String get sendCounterOffer => 'Қарсы ұсыныс жіберу';

  @override
  String get newPrice => 'Жаңа баға';

  @override
  String get noEquipmentAvailable => 'Техника табылмады';

  @override
  String get searchEquipment => 'Техника іздеу...';

  @override
  String get couldNotLoadEquipment => 'Техниканы жүктеу мүмкін болмады';

  @override
  String get selectEquipmentLocation => 'Техника орнын таңдаңыз';

  @override
  String get noEquipmentMatchingCategory =>
      'Бұл санат бойынша техника табылмады.';

  @override
  String get cancelOrderConfirmation =>
      'Бұл тапсырысты болдырмауды қалайсыз ба?';

  @override
  String get loadEquipmentErrorHint =>
      'Тізімді жүктеу кезінде қате орын алды. Қайталаңыз.';

  @override
  String get createBooking => 'Брондау жасау';

  @override
  String get loginToBook => 'Брондау үшін жүйеге кіріңіз';

  @override
  String get equipmentNotFound => 'Техника табылмады';

  @override
  String get servicePlan => 'Қызмет жоспары';

  @override
  String get addressAndSchedule => 'Мекен-жай және кесте';

  @override
  String get date => 'Күн';

  @override
  String get time => 'Уақыт';

  @override
  String get noteToOperator => 'Операторға жазба';

  @override
  String get siteAccessHint => 'Нысанға кіру мәліметтері, шарттар...';

  @override
  String get clientBookingDetails => 'Клиент брондауының мәліметтері';

  @override
  String get logoutConfirmation => 'Жүйеден шыққыңыз келетіні сенімдісіз бе?';

  @override
  String get reserveNow => 'Брондау';

  @override
  String get postWhatAndGetOffers =>
      'Не қажет екенін жазыңыз және ұсыныстар алыңыз';

  @override
  String get bookingRequestLabel => 'БРОНДАУ СҰРАНЫМЫ';

  @override
  String get newOrder => 'Жаңа тапсырыс';

  @override
  String get statusDraft => 'Жоба';

  @override
  String get statusConfirmed => 'Расталды';

  @override
  String get statusCanceled => 'Болдырылмады';

  @override
  String get statusFailed => 'Сәтсіз';

  @override
  String get statusCompleted => 'Аяқталды';

  @override
  String get statusReviewed => 'Бағаланды';

  @override
  String get statusRequestSent => 'Сұраным жіберілді';

  @override
  String get statusOffersReceived => 'Ұсыныстар алынды';

  @override
  String get statusBookingCreated => 'Брондау жасалды';

  @override
  String get statusExpired => 'Мерзімі өтті';

  @override
  String get unknownRenter => 'Белгісіз жалға алушы';

  @override
  String get nameNotSpecified => 'Аты көрсетілмеген';

  @override
  String get pendingDate => 'Күні белгісіз';

  @override
  String get overdue => 'Мерзімі өткен';

  @override
  String get details => 'Толығырақ';

  @override
  String get demandSurveyCardTitle => 'Басқа техника?';

  @override
  String get demandSurveyCardSubtitle => 'Қандай техника керегін айтыңыз';

  @override
  String get demandSurveyQuestionTitle => 'Сізге қандай техника қажет?';

  @override
  String get demandSurveyQuestionSubtitle =>
      'Нұсқаларды таңдаңыз немесе басқа техниканы сипаттаңыз.';

  @override
  String get demandSurveyCityLabel => 'Қала';

  @override
  String get demandSurveySelectCity => 'Қаланы таңдаңыз';

  @override
  String get demandSurveyOtherOption => 'Басқа техника';

  @override
  String get demandSurveyOtherHint => 'Қажетті техниканы сипаттаңыз';

  @override
  String get demandSurveySubmit => 'Жіберу';

  @override
  String get demandSurveyThankYou => 'Рақмет. Жауабыңыз сақталды.';

  @override
  String get demandSurveyLoadError => 'Сауалнама қазір қолжетімсіз.';

  @override
  String get demandSurveySubmitError => 'Нысанды тексеріп, қайталап көріңіз.';

  @override
  String get demandSurveyAlreadySubmitted =>
      'Сіз бұл сауалнамаға жауап бердіңіз.';

  @override
  String get demandSurveyInactive => 'Бұл сауалнама енді белсенді емес.';

  @override
  String get aboutProkat => 'Prokat туралы';

  @override
  String get aboutProkatEyebrow => 'ТЕХНИКАНЫ ЖАЛҒА АЛУ — ОҢАЙ';

  @override
  String get aboutProkatIntro =>
      'Prokat техника іздеген адамдарды сенімді жергілікті иелермен және сервистік компаниялармен байланыстырады. Бір платформада іздеңіз, салыстырыңыз және тікелей сөйлесіңіз.';

  @override
  String get aboutFeatureSearchTitle => 'Техниканы оңай іздеу';

  @override
  String get aboutFeatureSearchDescription =>
      'Қажетті техника мен сенімді жергілікті орындаушыларды табыңыз.';

  @override
  String get aboutFeatureTrustedTitle => 'Сенімді орындаушылар';

  @override
  String get aboutFeatureTrustedDescription =>
      'Техника иелері мен сервистік компаниялар жарияланбай тұрып тексеріледі.';

  @override
  String get aboutFeatureRatingsTitle => 'Екі жақты бағалау';

  @override
  String get aboutFeatureRatingsDescription =>
      'Клиенттер мен иелер ашық пікірлер арқылы сенім орнатады.';

  @override
  String get newToProkat => 'PROKAT-ТА ЖАҢАСЫЗ БА?';

  @override
  String get exploreHowItWorks => 'Қалай жұмыс істейді';

  @override
  String get aboutProkatBannerSubtitle =>
      'Ауыр техника мен сенімді орындаушыларды бір қадамда табыңыз немесе жалға беріңіз.';

  @override
  String get userConsent => 'Пайдаланушы келісімі';

  @override
  String get privacyPolicySubtitle =>
      'Деректеріңізді қалай жинаймыз және қолданамыз';

  @override
  String get userAgreementSubtitle => 'Платформаны пайдалану ережелері';

  @override
  String get personalDataSharingSubtitle => 'Жеке деректерді бөлісу';

  @override
  String get legalDocuments => 'Заңды құжаттар';

  @override
  String get legalDocumentsSubtitle =>
      'Саясаттар, келісімдер, пайдалану шарттары';

  @override
  String get applicationTheme => 'Қолданба тақырыбы';

  @override
  String get themeChooseHint =>
      'Prokat осы құрылғыда қалай көрінетінін таңдаңыз.';

  @override
  String get themeSystemDefault => 'Жүйе бойынша';

  @override
  String get themeSystemDefaultSubtitle => 'Құрылғының сыртқы түріне сәйкес';

  @override
  String get themeLight => 'Жарық';

  @override
  String get themeLightSubtitle => 'Әрқашан жарық безендіру';

  @override
  String get themeDark => 'Қараңғы';

  @override
  String get themeDarkSubtitle => 'Әрқашан қараңғы безендіру';

  @override
  String get serviceAndSafetyNotices => 'Сервистік және маңызды хабарламалар';

  @override
  String get serviceAndSafetyNoticesSubtitle =>
      'Аккаунт, қауіпсіздік және платформаның маңызды ескертулері';

  @override
  String get ownerServiceAndSafetyNoticesSubtitle =>
      'Қауіпсіздік, аккаунт шектеулері және шұғыл хабарламалар';

  @override
  String get requiredNoticesAlwaysAvailable =>
      'Бұл хабарламалар қолданбада әрқашан қолжетімді.';

  @override
  String get checkingPermission => 'Рұқсат тексерілуде';

  @override
  String get pushEnabled => 'Қосулы';

  @override
  String get pushEnabledQuietly => 'Дыбыссыз қосулы';

  @override
  String get pushBlocked => 'Бұғатталған';

  @override
  String get pushNotEnabled => 'Қосылмаған';

  @override
  String get pushUnavailable => 'Қолжетімсіз';

  @override
  String get pushEnabledInDeviceSettings => 'Құрылғы параметрлерінде қосулы';

  @override
  String get pushBlockedInDeviceSettings =>
      'Құрылғы параметрлерінде бұғатталған';

  @override
  String get pushPermissionNotRequested => 'Рұқсат сұралмаған';

  @override
  String get pushPermissionUnavailable => 'Рұқсат қолжетімсіз';

  @override
  String get failedToSaveNotificationPreferences =>
      'Хабарландыру параметрлерін сақтау мүмкін болмады.';

  @override
  String get notifRentalRequestsAndOffers => 'Сұраныстар мен ұсыныстар';

  @override
  String get notifRentalRequestsAndOffersSubtitle =>
      'Жаңа ұсыныстар, қарсы бағалар және сұраныс жаңартулары';

  @override
  String get notifOrderUpdates => 'Тапсырыс жаңартулары';

  @override
  String get notifOrderUpdatesSubtitle =>
      'Растаулар, бас тартулар және мәртебе өзгерістері';

  @override
  String get notifWorkProgress => 'Жұмыс барысы';

  @override
  String get notifWorkProgressSubtitle =>
      'Иесі жолда, нысанда, жұмысты бастады немесе аяқтады';

  @override
  String get notifMessagesSubtitle =>
      'Чаттағы және келіссөздердегі жаңа хабарлар';

  @override
  String get notifRemindersAndReviews => 'Еске салғыштар мен пікірлер';

  @override
  String get notifRemindersAndReviewsSubtitle =>
      'Алдағы жалға алу және пікір қалдыру туралы еске салғыштар';

  @override
  String get notifRequestsAndOffers => 'Сұраныстар мен ұсыныстар';

  @override
  String get notifRequestsAndOffersSubtitle =>
      'Жаңа жалға алу сұраныстары, ұсыныс шешімдері және келіссөздер';

  @override
  String get notifOrdersAndWorkProgress => 'Тапсырыстар мен жұмыс барысы';

  @override
  String get notifOrdersAndWorkProgressSubtitle =>
      'Растаулар, бас тартулар және жұмыс мәртебесінің өзгерістері';

  @override
  String get notifOwnerMessagesSubtitle =>
      'Клиенттерден және келіссөздерден жаңа хабарлар';

  @override
  String get notifEquipmentAndVerification => 'Техника және верификация';

  @override
  String get notifEquipmentAndVerificationSubtitle =>
      'Техника модерациясы, құжаттар және профиль мәртебесі';

  @override
  String get notifBalanceAlerts => 'Баланс ескертулері';

  @override
  String get notifBalanceAlertsSubtitle =>
      'Төмен баланс, толықтыру және төлем мәртебесі';

  @override
  String get noAddressSelected => 'Мекенжай таңдалмаған';

  @override
  String get selectedAddress => 'Таңдалған мекенжай';

  @override
  String get youHaveNoSavedAddresses => 'Сақталған мекенжайларыңыз жоқ.';

  @override
  String get manageMyAddresses => 'Мекенжайларды басқару';

  @override
  String get addressPrivacy => 'Мекенжай құпиялылығы';

  @override
  String get addressPrivacyBody =>
      'Таңдалған мекенжай техника иесіне тек белсенді тапсырыс кезінде, жалға алу үшін қажет болғанда беріледі. Ол көпшілікке көрсетілмейді және басқа пайдаланушыларға берілмейді.';

  @override
  String get morePrivacyOptionsContactSupport =>
      'Басқа құпиялылық параметрлері керек пе? Қолдауға жазыңыз';

  @override
  String get businessPreferences => 'Бизнес параметрлері';

  @override
  String get businessProfile => 'Бизнес профилі';

  @override
  String get manageMyEquipment => 'Техниканы басқару';

  @override
  String get noEquipmentAdded => 'Техника қосылмаған';

  @override
  String fleetItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count бірлік паркте',
      one: '$count бірлік паркте',
    );
    return '$_temp0';
  }

  @override
  String get organization => 'Ұйым';

  @override
  String get individualOwner => 'Жеке иесі';

  @override
  String get chatSection => 'Чат';

  @override
  String get chatContext => 'Мәтінмән';

  @override
  String get participant => 'Қатысушы';

  @override
  String get chatId => 'Чат ID';

  @override
  String get booking => 'Тапсырыс';

  @override
  String get notLinked => 'Байланыстырылмаған';

  @override
  String get clientRole => 'Клиент';

  @override
  String get priceOfferReceived => 'Баға ұсынысы келді';

  @override
  String get waitingClientResponse => 'Клиенттің жауабы күтілуде';

  @override
  String get didntReceiveCodeResend => 'Код келмеді ме? Қайта жіберу';

  @override
  String get youHaveNoActiveOrders => 'Белсенді тапсырыстарыңыз жоқ';

  @override
  String get youHaveNoNotifications => 'Хабарландыруларыңыз жоқ';

  @override
  String get unitCubicMeters => 'м³';

  @override
  String get currencyKzt => '₸';

  @override
  String get negotiationIdMissing => 'Келіссөз идентификаторы жоқ';

  @override
  String get actionFailed => 'Әрекет орындалмады';

  @override
  String get pleaseSelectYourCity => 'Қаланы таңдаңыз';

  @override
  String get saveChanges => 'Сақтау';

  @override
  String get saving => 'Сақталуда...';

  @override
  String get fieldRequired => 'Міндетті өріс';

  @override
  String get justNow => 'Жаңа ғана';

  @override
  String minutesAgo(int count) {
    return '$count мин бұрын';
  }

  @override
  String hoursAgo(int count) {
    return '$count сағ бұрын';
  }

  @override
  String durationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count күн',
      one: '1 күн',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сағ',
      one: '1 сағ',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count мин',
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
      one: '1 сек',
    );
    return '$_temp0';
  }

  @override
  String get invalidSecondsValue => 'Секунд мәні жарамсыз';

  @override
  String get newOffer => 'Жаңа ұсыныс';

  @override
  String get offerStatusViewed => 'Қаралды';

  @override
  String get offerStatusCancelled => 'Бас тартылды';

  @override
  String get offerStatusAccepted => 'Қабылданды';

  @override
  String get offerStatusRejected => 'Қабылданбады';

  @override
  String get offerStatusExpired => 'Мерзімі өтті';

  @override
  String get offerStatusClosed => 'Жабық';

  @override
  String get dataProcessingTitle => 'Деректерді өңдеу';

  @override
  String get pleaseCompleteRequiredFields =>
      'Тексеруге жібермес бұрын міндетті деректерді толтырыңыз';

  @override
  String get youAreOnline => 'Сіз онлайнсыз';

  @override
  String get youAreOffline => 'Сіз офлайнсыз';

  @override
  String get readyToAcceptOrders => 'Тапсырыстарды қабылдауға дайынсыз';

  @override
  String get notAcceptingOrders => 'Тапсырыстар қабылданбайды';

  @override
  String get youAreNowOnline => 'Енді сіз онлайнсыз';

  @override
  String get youAreNowOffline => 'Енді сіз офлайнсыз';

  @override
  String get failedToggleStatus => 'Мәртебені жаңарту мүмкін болмады';

  @override
  String get countryKazakhstan => 'Қазақстан';

  @override
  String get modelStandard => 'Стандарт';

  @override
  String get modelHeavyDuty => 'Ауыр';

  @override
  String get modelIndustrial => 'Өнеркәсіптік';

  @override
  String capacityKub(String capacity) {
    return '$capacity м³';
  }

  @override
  String get unitMeters => 'м';

  @override
  String get hoseLengthHint => '15 м шланг';

  @override
  String get priceKztHint => '10 000 ₸';

  @override
  String get ownerType => 'Иесінің түрі';

  @override
  String get companyInformation => 'Компания деректері';

  @override
  String get companyName => 'Компания атауы';

  @override
  String get enterCompanyName => 'Компания атауын енгізіңіз';

  @override
  String get legalEntityName => 'Заңды атауы';

  @override
  String get legalEntityNameHint => 'Ресми құжаттардағыдай';

  @override
  String get personalContactDetails => 'Байланыс деректері';

  @override
  String get enterFirstName => 'Атын енгізіңіз';

  @override
  String get enterLastName => 'Тегін енгізіңіз';

  @override
  String get enterValidPhoneNumber => 'Жарамды телефон нөмірін енгізіңіз';

  @override
  String get serviceDetails => 'Қызмет сипаттамасы';

  @override
  String get serviceDetailsHint =>
      'Ұсынатын тауарлар, жалдау немесе техниканы сипаттаңыз...';

  @override
  String get updateProfile => 'Профильді жаңарту';

  @override
  String get profileUpdatedSuccessfully => 'Профиль сәтті жаңартылды';

  @override
  String get failedToUpdateProfile => 'Профильді жаңарту мүмкін болмады';

  @override
  String ordersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count тапсырыс',
      one: '$count тапсырыс',
    );
    return '$_temp0';
  }

  @override
  String get ratePerTrip => 'Рейске';

  @override
  String get ratePerCubicMeter => 'М³-ге';

  @override
  String get ratePerDay => 'Күніне';

  @override
  String get ratePerHour => 'Сағатына';

  @override
  String get cityNameAtyrau => 'Атырау';

  @override
  String get cityNameAlmaty => 'Алматы';

  @override
  String get cityNameAstana => 'Астана';

  @override
  String get cityNameShymkent => 'Шымкент';

  @override
  String get cityNameAktobe => 'Ақтөбе';

  @override
  String get cityNameKaraganda => 'Қарағанды';

  @override
  String get cityNameTaraz => 'Тараз';

  @override
  String get cityNamePavlodar => 'Павлодар';

  @override
  String get cityNameUstKamenogorsk => 'Өскемен';

  @override
  String get cityNameSemey => 'Семей';

  @override
  String get cityNameKostanay => 'Қостанай';

  @override
  String get cityNameKyzylorda => 'Қызылорда';

  @override
  String get cityNameUralsk => 'Орал';

  @override
  String get cityNamePetropavl => 'Петропавл';

  @override
  String get cityNameTurkistan => 'Түркістан';

  @override
  String get connectionTimedOut =>
      'Күту уақыты аяқталды. Сервер іске қосылып жатқан болуы мүмкін — қайталап көріңіз.';

  @override
  String get noConnectionCheckNetwork =>
      'Байланыс жоқ. Желіні тексеріп, қайталап көріңіз.';

  @override
  String get networkErrorTryAgain => 'Желі қатесі. Қайталап көріңіз.';

  @override
  String get somethingWentWrongTryAgain =>
      'Бірдеңе дұрыс болмады. Қайталап көріңіз.';
}
