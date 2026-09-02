import 'package:prokat/features/support/models/faq_model.dart';

final faqs = [
  const FaqModel(
    id: 'rent_equipment',
    category: 'BOOKINGS',
    order: 1,
    isPublished: true,
    translations: [
      FaqTranslation(
        locale: 'en',
        question: 'How do I rent equipment?',
        answer: 'Browse available equipment, choose your rental dates, and send a booking request. The owner will review your request and respond.',
      ),
      FaqTranslation(
        locale: 'ru',
        question: 'Как арендовать оборудование?',
        answer: 'Просмотрите доступную технику, выберите даты аренды и отправьте запрос. Владелец рассмотрит его и ответит.',
      ),
      FaqTranslation(
        locale: 'kk',
        question: 'Жабдықты қалай жалға аламын?',
        answer: 'Қолжетімді техниканы қарап, жалға алу күндерін таңдап, сұраныс жіберіңіз. Иесі оны қарап, жауап береді.',
      ),
    ],
  ),

  const FaqModel(
    id: 'list_equipment',
    category: 'EQUIPMENT',
    order: 2,
    isPublished: true,
    translations: [
      FaqTranslation(
        locale: 'en',
        question: 'How do I list my equipment?',
        answer: 'Go to the owner section, add your equipment details, upload photos, set pricing, and publish your listing.',
      ),
      FaqTranslation(
        locale: 'ru',
        question: 'Как разместить своё оборудование?',
        answer: 'Перейдите в раздел владельца, добавьте данные техники, загрузите фото, укажите цены и опубликуйте объявление.',
      ),
      FaqTranslation(
        locale: 'kk',
        question: 'Жабдығымды қалай жариялаймын?',
        answer: 'Иесі бөліміне өтіп, техника деректерін қосыңыз, фото жүктеңіз, бағаны көрсетіңіз және жариялаңыз.',
      ),
    ],
  ),

  const FaqModel(
    id: 'cancel_booking',
    category: 'BOOKINGS',
    order: 3,
    isPublished: true,
    translations: [
      FaqTranslation(
        locale: 'en',
        question: 'Can I cancel a booking?',
        answer: 'Yes. Cancellation depends on the current booking status and the agreement between you and the equipment owner.',
      ),
      FaqTranslation(
        locale: 'ru',
        question: 'Можно ли отменить бронирование?',
        answer: 'Да. Условия отмены зависят от текущего статуса заказа и договорённости с владельцем техники.',
      ),
      FaqTranslation(
        locale: 'kk',
        question: 'Брондаудан бас тарта аламын ба?',
        answer: 'Иә. Бас тарту шарттары тапсырыстың ағымдағы мәртебесіне және техника иесімен келісімге байланысты.',
      ),
    ],
  ),

  const FaqModel(
    id: 'payments',
    category: 'PAYMENTS',
    order: 4,
    isPublished: true,
    translations: [
      FaqTranslation(
        locale: 'en',
        question: 'How do payments work?',
        answer: 'Rental prices are set by equipment owners. Any additional charges will be displayed before confirming the booking.',
      ),
      FaqTranslation(
        locale: 'ru',
        question: 'Как работают платежи?',
        answer: 'Цены на аренду устанавливают владельцы техники. Дополнительные сборы отображаются до подтверждения заказа.',
      ),
      FaqTranslation(
        locale: 'kk',
        question: 'Төлемдер қалай жүзеге асады?',
        answer: 'Жалға алу бағасын техника иелері белгілейді. Қосымша төлемдер тапсырысты растамас бұрын көрсетіледі.',
      ),
    ],
  ),

  const FaqModel(
    id: 'contact_support',
    category: 'GENERAL',
    order: 5,
    isPublished: true,
    translations: [
      FaqTranslation(
        locale: 'en',
        question: 'How can I contact Prokat support?',
        answer: 'Open the Help & Support screen and select Contact Support to send us your question or report an issue.',
      ),
      FaqTranslation(
        locale: 'ru',
        question: 'Как связаться со службой поддержки?',
        answer: 'Откройте экран «Помощь и поддержка» и выберите «Связаться с поддержкой», чтобы задать вопрос или сообщить о проблеме.',
      ),
      FaqTranslation(
        locale: 'kk',
        question: 'Қолдау қызметіне қалай хабарласуға болады?',
        answer: '«Көмек және қолдау» экранын ашып, сұрақ қою немесе мәселені хабарлау үшін «Қолдаумен байланысу» тармағын таңдаңыз.',
      ),
    ],
  ),
];
