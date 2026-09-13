import 'package:prokat/features/support/models/faq_model.dart';

final faqs = [
  const FaqModel(
    id: 'find_equipment',
    category: 'BOOKINGS',
    order: 1,
    isPublished: true,
    translations: [
      FaqTranslation(
        locale: 'en',
        question: 'How do I find the right equipment?',
        answer:
            'Open Equipment, choose a suitable machine, and send a request to the owner. If needed, discuss the details in chat first.',
      ),
      FaqTranslation(
        locale: 'ru',
        question: 'Как найти нужную технику?',
        answer:
            'Откройте раздел «Техника», выберите подходящую машину и отправьте запрос владельцу. При необходимости сначала обсудите детали в чате.',
      ),
      FaqTranslation(
        locale: 'kk',
        question: 'Қажетті техниканы қалай табуға болады?',
        answer:
            '«Техника» бөлімін ашып, қолайлы машинаны таңдап, иесіне сұраныс жіберіңіз. Қажет болса, алдымен чатта мәліметтерді талқылаңыз.',
      ),
    ],
  ),
  const FaqModel(
    id: 'no_matching_equipment',
    category: 'REQUESTS',
    order: 2,
    isPublished: true,
    translations: [
      FaqTranslation(
        locale: 'en',
        question: 'What if I cannot find suitable equipment?',
        answer:
            'Create a request in Requests. Owners will see it and can offer suitable options.',
      ),
      FaqTranslation(
        locale: 'ru',
        question: 'Что делать, если подходящей техники нет?',
        answer:
            'Создайте заявку в разделе «Заявки». Владельцы увидят её и смогут предложить подходящие варианты.',
      ),
      FaqTranslation(
        locale: 'kk',
        question: 'Қажетті техника жоқ болса не істеу керек?',
        answer:
            '«Өтінімдер» бөлімінде өтінім жасаңыз. Иелер оны көріп, қолайлы нұсқаларды ұсына алады.',
      ),
    ],
  ),
  const FaqModel(
    id: 'contact_owner',
    category: 'CHAT',
    order: 3,
    isPublished: true,
    translations: [
      FaqTranslation(
        locale: 'en',
        question: 'How do I contact the owner?',
        answer:
            'Open chat after sending a request or receiving an offer. There you can discuss price, time, address, and other details.',
      ),
      FaqTranslation(
        locale: 'ru',
        question: 'Как связаться с владельцем?',
        answer:
            'Перейдите в чат после отправки запроса или получения предложения. Там можно обсудить цену, время, адрес и другие детали.',
      ),
      FaqTranslation(
        locale: 'kk',
        question: 'Иесімен қалай байланысуға болады?',
        answer:
            'Сұраныс жібергеннен немесе ұсыныс алғаннан кейін чатқа өтіңіз. Онда баға, уақыт, мекенжай және басқа мәліметтерді талқылауға болады.',
      ),
    ],
  ),
  const FaqModel(
    id: 'cancel_order',
    category: 'BOOKINGS',
    order: 4,
    isPublished: true,
    translations: [
      FaqTranslation(
        locale: 'en',
        question: 'Can I cancel an order?',
        answer:
            'If the order can still be cancelled, the button will be available on its card.',
      ),
      FaqTranslation(
        locale: 'ru',
        question: 'Можно ли отменить заказ?',
        answer:
            'Если заказ ещё можно отменить, соответствующая кнопка будет доступна в его карточке.',
      ),
      FaqTranslation(
        locale: 'kk',
        question: 'Тапсырысты болдырмауға бола ма?',
        answer:
            'Тапсырысты әлі болдырмауға болса, тиісті түйме оның картасында болады.',
      ),
    ],
  ),
  const FaqModel(
    id: 'owner_no_reply',
    category: 'CHAT',
    order: 5,
    isPublished: true,
    translations: [
      FaqTranslation(
        locale: 'en',
        question: 'What if the owner does not reply?',
        answer:
            'Try another machine or create an open request to get offers from other owners.',
      ),
      FaqTranslation(
        locale: 'ru',
        question: 'Что делать, если владелец не отвечает?',
        answer:
            'Попробуйте выбрать другую технику или создайте открытую заявку, чтобы получить предложения от других владельцев.',
      ),
      FaqTranslation(
        locale: 'kk',
        question: 'Иесі жауап бермесе не істеу керек?',
        answer:
            'Басқа техниканы таңдап көріңіз немесе ашық өтінім жасап, басқа иелерден ұсыныс алыңыз.',
      ),
    ],
  ),
  const FaqModel(
    id: 'start_listing',
    category: 'EQUIPMENT',
    order: 6,
    isPublished: true,
    translations: [
      FaqTranslation(
        locale: 'en',
        question: 'How do I start listing my equipment?',
        answer:
            'Register as an owner, add equipment, and send it for review. After approval, turn on Online to accept orders.',
      ),
      FaqTranslation(
        locale: 'ru',
        question: 'Как начать сдавать свою технику?',
        answer:
            'Зарегистрируйтесь как владелец, добавьте технику и отправьте её на проверку. После одобрения включите статус «Онлайн» для принятия заказов.',
      ),
      FaqTranslation(
        locale: 'kk',
        question: 'Өз техникамды қалай жалға бере бастауға болады?',
        answer:
            'Иесі ретінде тіркеліп, техника қосып, тексеруге жіберіңіз. Мақұлданғаннан кейін тапсырыс қабылдау үшін «Онлайн» күйін қосыңыз.',
      ),
    ],
  ),
  const FaqModel(
    id: 'equipment_not_shown',
    category: 'EQUIPMENT',
    order: 7,
    isPublished: true,
    translations: [
      FaqTranslation(
        locale: 'en',
        question: 'Why is my equipment not shown to clients?',
        answer:
            'Make sure the equipment has passed review. It can still appear while you are offline if you set the listing to visible.',
      ),
      FaqTranslation(
        locale: 'ru',
        question: 'Почему моя техника не показывается клиентам?',
        answer:
            'Убедитесь, что техника прошла проверку. Ваша техника показывается даже когда вы офлайн, если вы выставили статус «показывается» для Вашей техники.',
      ),
      FaqTranslation(
        locale: 'kk',
        question: 'Техникам неге клиенттерге көрсетілмейді?',
        answer:
            'Техника тексеруден өткенін тексеріңіз. Сіз офлайн болсаңыз да, техника «көрсетіледі» күйінде болса, ол көрінеді.',
      ),
    ],
  ),
  const FaqModel(
    id: 'minutes_burn',
    category: 'BILLING',
    order: 8,
    isPublished: true,
    translations: [
      FaqTranslation(
        locale: 'en',
        question: 'When are minutes deducted?',
        answer:
            'Minutes are used only while the owner is online. Offline, the balance is kept.',
      ),
      FaqTranslation(
        locale: 'ru',
        question: 'Когда списываются минуты?',
        answer:
            'Минуты расходуются только когда владелец находится онлайн. В офлайн-режиме баланс сохраняется.',
      ),
      FaqTranslation(
        locale: 'kk',
        question: 'Минуттар қашан шегеріледі?',
        answer:
            'Минуттар тек иесі онлайн болғанда жұмсалады. Офлайн режимде баланс сақталады.',
      ),
    ],
  ),
  const FaqModel(
    id: 'contact_support',
    category: 'GENERAL',
    order: 9,
    isPublished: true,
    translations: [
      FaqTranslation(
        locale: 'en',
        question: 'How do I contact support?',
        answer:
            'Open Help and tap Contact Support. Briefly describe the question or problem.',
      ),
      FaqTranslation(
        locale: 'ru',
        question: 'Как связаться с поддержкой?',
        answer:
            'Откройте раздел «Помощь» и выберите «Связаться с поддержкой». Кратко опишите вопрос или проблему.',
      ),
      FaqTranslation(
        locale: 'kk',
        question: 'Қолдаумен қалай байланысуға болады?',
        answer:
            '«Көмек» бөлімін ашып, «Қолдауға хабарласу» таңдаңыз. Сұрақ немесе мәселені қысқаша жазыңыз.',
      ),
    ],
  ),
];
