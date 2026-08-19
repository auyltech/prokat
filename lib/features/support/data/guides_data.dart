import 'package:prokat/features/support/models/guide_icon.dart';
import 'package:prokat/features/support/models/user_guide.dart';

final guides = [
  UserGuide(
    id: 'getting_started',
    slug: 'getting-started',
    category: 'GETTING_STARTED',
    icon: GuideIcon.gettingStarted,
    order: 1,
    isPublished: true,
    translations: [
      UserGuideTranslation(
        locale: 'en',
        title: 'Getting Started',
        summary: 'Learn the basics of using Prokat.',
        content: '''
# Getting Started

Welcome to **Prokat**, a marketplace where you can rent equipment from trusted owners or list your own equipment for others to rent.

## Create your account

Sign in using your phone number and complete your profile.

## Browse equipment

Explore categories or search for equipment that fits your needs.

## Send a booking request

Choose your rental period and submit a booking request.

## Stay informed

Enable notifications to receive updates about your bookings, requests, and messages.
''',
      ),
      UserGuideTranslation(
        locale: 'ru',
        title: 'С чего начать',
        summary: 'Основы работы с Prokat.',
        content: '''
# С чего начать

Добро пожаловать в **Prokat** — площадку, где можно арендовать технику у проверенных владельцев или разместить свою технику для аренды.

## Создайте аккаунт

Войдите по номеру телефона и заполните профиль.

## Найдите технику

Просматривайте категории или ищите технику под ваши задачи.

## Отправьте запрос на аренду

Выберите период аренды и отправьте запрос.

## Оставайтесь на связи

Включите уведомления, чтобы получать обновления по заказам, запросам и сообщениям.
''',
      ),
      UserGuideTranslation(
        locale: 'kk',
        title: 'Қайдан бастау керек',
        summary: 'Prokat-ты пайдалану негіздері.',
        content: '''
# Қайдан бастау керек

**Prokat**-қа қош келдіңіз — сенімді иелерден техника жалға алуға немесе өз техникаңызды жалға беруге арналған алаң.

## Аккаунт жасаңыз

Телефон нөмірі арқылы кіріп, профиліңізді толтырыңыз.

## Техниканы қараңыз

Санаттарды шолыңыз немесе қажетті техниканы іздеңіз.

## Жалға алу сұранысын жіберіңіз

Жалға алу мерзімін таңдап, сұраныс жіберіңіз.

## Хабардар болыңыз

Тапсырыстар, сұраныстар және хабарлар туралы жаңартулар алу үшін хабарландыруларды қосыңыз.
''',
      ),
    ],
  ),

  UserGuide(
    id: 'renting',
    slug: 'renting-equipment',
    category: 'RENTING',
    icon: GuideIcon.booking,
    order: 2,
    isPublished: true,
    translations: [
      UserGuideTranslation(
        locale: 'en',
        title: 'Renting Equipment',
        summary: 'Everything you need to know before renting.',
        content: '''
# Renting Equipment

Renting equipment through Prokat is quick and straightforward.

## Find equipment

Use search or browse categories to discover available equipment.

## Review the details

Read the description, rental conditions, pricing, and equipment location before sending a request.

## Send a request

Choose your rental dates and submit your booking request.

## Wait for the owner's response

The owner may approve, reject, or negotiate your request.

## Complete your rental

Inspect the equipment before use and return it in the agreed condition.
''',
      ),
      UserGuideTranslation(
        locale: 'ru',
        title: 'Аренда техники',
        summary: 'Что нужно знать перед арендой.',
        content: '''
# Аренда техники

Арендовать технику через Prokat просто и быстро.

## Найдите технику

Используйте поиск или категории, чтобы найти доступную технику.

## Проверьте детали

Перед запросом прочитайте описание, условия аренды, цены и местоположение.

## Отправьте запрос

Выберите даты аренды и отправьте запрос на бронирование.

## Дождитесь ответа владельца

Владелец может одобрить, отклонить запрос или предложить другие условия.

## Завершите аренду

Осмотрите технику перед использованием и верните её в согласованном состоянии.
''',
      ),
      UserGuideTranslation(
        locale: 'kk',
        title: 'Техниканы жалға алу',
        summary: 'Жалға алмас бұрын білу керек нәрселер.',
        content: '''
# Техниканы жалға алу

Prokat арқылы техниканы жалға алу жылдам әрі қарапайым.

## Техниканы табыңыз

Қолжетімді техниканы іздеу немесе санаттар арқылы қараңыз.

## Мәліметтерді тексеріңіз

Сұраныс жібермес бұрын сипаттаманы, жалға алу шарттарын, бағаны және орналасқан жерді оқыңыз.

## Сұраныс жіберіңіз

Жалға алу күндерін таңдап, брондау сұранысын жіберіңіз.

## Иесінің жауабын күтіңіз

Иесі сұранысты мақұлдауы, қабылдамауы немесе шарттарды келісуі мүмкін.

## Жалға алуды аяқтаңыз

Қолданар алдында техниканы тексеріп, келісілген күйде қайтарыңыз.
''',
      ),
    ],
  ),

  UserGuide(
    id: 'listing',
    slug: 'listing-equipment',
    category: 'LISTING',
    icon: GuideIcon.equipment,
    order: 3,
    isPublished: true,
    translations: [
      UserGuideTranslation(
        locale: 'en',
        title: 'Listing Your Equipment',
        summary: 'Start earning by renting out your equipment.',
        content: '''
# Listing Your Equipment

Anyone can become an equipment owner on Prokat.

## Add equipment

Provide accurate information, upload clear photos, and choose the correct category.

## Set your pricing

Configure rental prices that reflect your equipment and market conditions.

## Manage bookings

Review incoming requests and respond promptly.

## Keep your listings updated

Update availability, pricing, and equipment information whenever changes occur.
''',
      ),
      UserGuideTranslation(
        locale: 'ru',
        title: 'Размещение техники',
        summary: 'Начните зарабатывать, сдавая технику в аренду.',
        content: '''
# Размещение техники

На Prokat владельцем техники может стать любой пользователь.

## Добавьте технику

Укажите точные данные, загрузите понятные фото и выберите правильную категорию.

## Задайте цены

Настройте тарифы с учётом вашей техники и рынка.

## Управляйте заказами

Просматривайте входящие запросы и отвечайте вовремя.

## Держите объявления актуальными

Обновляйте доступность, цены и информацию о технике при любых изменениях.
''',
      ),
      UserGuideTranslation(
        locale: 'kk',
        title: 'Техниканы жариялау',
        summary: 'Техниканы жалға беріп табыс табыңыз.',
        content: '''
# Техниканы жариялау

Prokat-та кез келген пайдаланушы техника иесі бола алады.

## Техника қосыңыз

Дәл мәлімет беріңіз, анық фото жүктеңіз және дұрыс санатты таңдаңыз.

## Бағаны белгілеңіз

Техникаңыз бен нарыққа сәйкес жалға алу тарифтерін баптаңыз.

## Тапсырыстарды басқарыңыз

Кіріс сұраныстарды қарап, уақытында жауап беріңіз.

## Хабарландыруларды жаңартып отырыңыз

Қолжетімділік, баға және техника туралы ақпарат өзгерсе, жаңартыңыз.
''',
      ),
    ],
  ),

  UserGuide(
    id: 'payments',
    slug: 'payments-pricing',
    category: 'PAYMENTS',
    icon: GuideIcon.payments,
    order: 4,
    isPublished: true,
    translations: [
      UserGuideTranslation(
        locale: 'en',
        title: 'Payments & Pricing',
        summary: 'Understand rental prices and payments.',
        content: '''
# Payments & Pricing

Rental prices are determined by equipment owners.

## Rental price

Each equipment listing displays its available rental rates.

## Additional costs

Delivery fees or other charges may apply if agreed with the owner.

## Review before confirming

Always verify the total cost before submitting your booking request.
''',
      ),
      UserGuideTranslation(
        locale: 'ru',
        title: 'Платежи и цены',
        summary: 'Как устроены цены и оплата аренды.',
        content: '''
# Платежи и цены

Цены на аренду определяют владельцы техники.

## Стоимость аренды

В каждом объявлении указаны доступные тарифы.

## Дополнительные расходы

Доставка или другие сборы могут применяться по договорённости с владельцем.

## Проверьте перед подтверждением

Всегда сверяйте итоговую сумму до отправки запроса на бронирование.
''',
      ),
      UserGuideTranslation(
        locale: 'kk',
        title: 'Төлемдер мен бағалар',
        summary: 'Жалға алу бағасы мен төлемдер қалай жұмыс істейді.',
        content: '''
# Төлемдер мен бағалар

Жалға алу бағасын техника иелері анықтайды.

## Жалға алу құны

Әр хабарландыруда қолжетімді тарифтер көрсетіледі.

## Қосымша шығындар

Жеткізу немесе басқа төлемдер иесімен келісім бойынша қолданылуы мүмкін.

## Растамас бұрын тексеріңіз

Брондау сұранысын жібермес бұрын жалпы соманы әрқашан тексеріңіз.
''',
      ),
    ],
  ),

  UserGuide(
    id: 'safety',
    slug: 'safety-trust',
    category: 'SAFETY',
    icon: GuideIcon.safety,
    order: 5,
    isPublished: true,
    translations: [
      UserGuideTranslation(
        locale: 'en',
        title: 'Safety & Trust',
        summary: 'Best practices for safe rentals.',
        content: '''
# Safety & Trust

Following these recommendations helps ensure a positive rental experience.

## Inspect equipment

Check the equipment before accepting and before returning it.

## Report problems

Notify the owner immediately if you notice any issues.

## Respect agreements

Return equipment on time and in the same condition in which you received it.

## Stay within Prokat

Use Prokat's communication tools whenever possible for rental-related discussions.
''',
      ),
      UserGuideTranslation(
        locale: 'ru',
        title: 'Безопасность и доверие',
        summary: 'Как арендовать технику безопасно.',
        content: '''
# Безопасность и доверие

Эти рекомендации помогают сделать аренду спокойной и предсказуемой.

## Осмотрите технику

Проверьте её до приёмки и перед возвратом.

## Сообщайте о проблемах

Сразу напишите владельцу, если заметили неисправность.

## Соблюдайте договорённости

Верните технику вовремя и в том же состоянии, в котором получили.

## Оставайтесь в Prokat

По возможности ведите переписку по аренде через инструменты Prokat.
''',
      ),
      UserGuideTranslation(
        locale: 'kk',
        title: 'Қауіпсіздік пен сенім',
        summary: 'Қауіпсіз жалға алу бойынша ұсыныстар.',
        content: '''
# Қауіпсіздік пен сенім

Осы ұсыныстар жалға алуды қауіпсіз және түсінікті етеді.

## Техниканы тексеріңіз

Қабылдамас бұрын және қайтармас бұрын техниканы қараңыз.

## Мәселелерді хабарлаңыз

Ақау байқасаңыз, иесіне бірден хабарлаңыз.

## Келісімді сақтаңыз

Техниканы уақытында және алған күйінде қайтарыңыз.

## Prokat ішінде қалыңыз

Жалға алуға қатысты сөйлесуді мүмкіндігінше Prokat құралдары арқылы жүргізіңіз.
''',
      ),
    ],
  ),

  UserGuide(
    id: 'account',
    slug: 'account-settings',
    category: 'ACCOUNT',
    icon: GuideIcon.account,
    order: 6,
    isPublished: true,
    translations: [
      UserGuideTranslation(
        locale: 'en',
        title: 'Account & Settings',
        summary: 'Manage your profile and preferences.',
        content: '''
# Account & Settings

Your account allows you to manage your personal information and preferences.

## Profile

Keep your name and profile information up to date.

## Notifications

Enable notifications to stay informed about bookings, requests, and messages.

## Privacy

Review the Privacy Policy and Terms & Conditions from the Help & Support section.

## Need assistance?

If you have questions or encounter a problem, contact our support team through the Help & Support screen.
''',
      ),
      UserGuideTranslation(
        locale: 'ru',
        title: 'Аккаунт и настройки',
        summary: 'Управляйте профилем и предпочтениями.',
        content: '''
# Аккаунт и настройки

В аккаунте можно управлять личными данными и настройками.

## Профиль

Держите имя и данные профиля актуальными.

## Уведомления

Включите уведомления, чтобы не пропускать заказы, запросы и сообщения.

## Конфиденциальность

Политику конфиденциальности и условия использования можно открыть в разделе «Помощь и поддержка».

## Нужна помощь?

Если возникли вопросы или проблема, напишите в поддержку через экран «Помощь и поддержка».
''',
      ),
      UserGuideTranslation(
        locale: 'kk',
        title: 'Аккаунт және параметрлер',
        summary: 'Профиль мен баптауларды басқарыңыз.',
        content: '''
# Аккаунт және параметрлер

Аккаунтта жеке деректер мен баптауларды басқаруға болады.

## Профиль

Атыңызды және профиль мәліметтерін жаңартып отырыңыз.

## Хабарландырулар

Тапсырыстар, сұраныстар және хабарлар туралы білу үшін хабарландыруларды қосыңыз.

## Құпиялылық

Құпиялылық саясаты мен пайдалану шарттарын «Көмек және қолдау» бөлімінен қараңыз.

## Көмек керек пе?

Сұрақ немесе мәселе туындаса, «Көмек және қолдау» экраны арқылы қолдау қызметіне жазыңыз.
''',
      ),
    ],
  ),
];
