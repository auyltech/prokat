import 'package:prokat/features/support/models/guide_icon.dart';
import 'package:prokat/features/support/models/user_guide.dart';

final guides = [
  const UserGuide(
    id: 'find_and_order',
    slug: 'find-and-order',
    category: 'FIND_AND_ORDER',
    icon: GuideIcon.findEquipment,
    order: 1,
    isPublished: true,
    translations: [
      UserGuideTranslation(
        locale: 'en',
        title: 'Find and order equipment',
        summary:
            'Open Equipment, pick a machine, and send a request to the owner.',
        content: 'Open the Equipment section and choose a suitable option. Check specs, tariffs, and working conditions, then send a request to the owner. If needed, you can discuss details in chat before the order is confirmed.',
      ),
      UserGuideTranslation(
        locale: 'ru',
        title: 'Найти и заказать технику',
        summary: 'Откройте раздел «Техника» и выберите подходящий вариант.',
        content: 'Откройте раздел «Техника» и выберите подходящий вариант. Посмотрите характеристики, тарифы и условия работы, затем отправьте запрос владельцу. При необходимости детали можно обсудить в чате до подтверждения заказа.',
      ),
      UserGuideTranslation(
        locale: 'kk',
        title: 'Техниканы табу және тапсырыс беру',
        summary: '«Техника» бөлімін ашып, қолайлы нұсқаны таңдаңыз.',
        content: '«Техника» бөлімін ашып, қолайлы нұсқаны таңдаңыз. Сипаттамаларды, тарифтерді және жұмыс шарттарын қарап, иесіне сұраныс жіберіңіз. Қажет болса, тапсырыс расталғанға дейін мәліметтерді чатта талқылауға болады.',
      ),
    ],
  ),
  const UserGuide(
    id: 'create_request',
    slug: 'create-request',
    category: 'CREATE_REQUEST',
    icon: GuideIcon.createRequest,
    order: 2,
    isPublished: true,
    translations: [
      UserGuideTranslation(
        locale: 'en',
        title: 'Did not find the right equipment?',
        summary:
            'Create a request in Requests — owners can offer their options.',
        content: 'Create a request in the Requests section and describe the equipment or service you need. Owners will see the request and can offer their options. You can accept an offer, decline it, or discuss it in chat first.',
      ),
      UserGuideTranslation(
        locale: 'ru',
        title: 'Не нашли нужную технику?',
        summary: 'Создайте заявку в разделе «Заявки» и укажите, какая техника или услуга вам нужна.',
        content: 'Создайте заявку в разделе «Заявки» и укажите, какая техника или услуга вам нужна. Владельцы увидят запрос и смогут предложить свои варианты. Предложение можно принять, отклонить или сначала обсудить в чате.',
      ),
      UserGuideTranslation(
        locale: 'kk',
        title: 'Қажетті техниканы таппадыңыз ба?',
        summary: '«Өтінімдер» бөлімінде өтінім жасап, қандай техника немесе қызмет керек екенін жазыңыз.',
        content: '«Өтінімдер» бөлімінде өтінім жасап, қандай техника немесе қызмет керек екенін жазыңыз. Иелер сұранысты көріп, өз нұсқаларын ұсына алады. Ұсынысты қабылдауға, қабылдамауға немесе алдымен чатта талқылауға болады.',
      ),
    ],
  ),
  const UserGuide(
    id: 'list_equipment',
    slug: 'list-equipment',
    category: 'LISTING',
    icon: GuideIcon.listEquipment,
    order: 3,
    isPublished: true,
    translations: [
      UserGuideTranslation(
        locale: 'en',
        title: 'Rent out your equipment',
        summary:
            'Register as an owner, add your machine, and send it for review.',
        content: 'Register as an owner and add your equipment. Fill in the details, photos, tariffs, and specs, then send it for review. After approval, turn on Shown so clients can see the machine and you can receive orders.',
      ),
      UserGuideTranslation(
        locale: 'ru',
        title: 'Сдавать свою технику',
        summary: 'Зарегистрируйтесь как владелец и добавьте свою технику.',
        content: 'Зарегистрируйтесь как владелец и добавьте свою технику. Заполните информацию, фотографии, тарифы и характеристики, затем отправьте её на проверку. После одобрения включите статус «Показывается», чтобы техника была доступна клиентам и вы могли получать заказы.',
      ),
      UserGuideTranslation(
        locale: 'kk',
        title: 'Өз техникаңызды жалға беру',
        summary: 'Ие ретінде тіркеліп, техникаңызды қосыңыз.',
        content: 'Ие ретінде тіркеліп, техникаңызды қосыңыз. Ақпаратты, фотоларды, тарифтерді және сипаттамаларды толтырып, тексеруге жіберіңіз. Мақұлданғаннан кейін «Көрсетіледі» күйін қосыңыз — сонда техника клиенттерге көрінеді және тапсырыс ала аласыз.',
      ),
    ],
  ),
  const UserGuide(
    id: 'order_and_chat',
    slug: 'order-and-chat',
    category: 'ORDER_CHAT',
    icon: GuideIcon.orderChat,
    order: 4,
    isPublished: true,
    translations: [
      UserGuideTranslation(
        locale: 'en',
        title: 'Order and contact the owner',
        summary: 'Use chat to confirm price, time, and address, then accept the offer.',
        content: 'After you send a request or receive an offer, open chat to confirm the price, time, address, and other details. If the terms work, confirm the offer — the order will then appear in Orders.',
      ),
      UserGuideTranslation(
        locale: 'ru',
        title: 'Заказ и связь с владельцем',
        summary: 'После отправки запроса или получения предложения можно перейти в чат и уточнить детали.',
        content: 'После отправки запроса или получения предложения можно перейти в чат и уточнить цену, время, адрес и другие детали. Если условия подходят, подтвердите предложение — после этого заказ появится в разделе «Заказы».',
      ),
      UserGuideTranslation(
        locale: 'kk',
        title: 'Тапсырыс және иесімен байланыс',
        summary: 'Сұраныс жібергеннен немесе ұсыныс алғаннан кейін чатта бағаны, уақытты және мекенжайды нақтылауға болады.',
        content: 'Сұраныс жібергеннен немесе ұсыныс алғаннан кейін чатқа өтіп, бағаны, уақытты, мекенжайды және басқа мәліметтерді нақтылауға болады. Шарттар қолайлы болса, ұсынысты растаңыз — содан кейін тапсырыс «Тапсырыстар» бөлімінде пайда болады.',
      ),
    ],
  ),
  const UserGuide(
    id: 'safety_and_help',
    slug: 'safety-and-help',
    category: 'SAFETY',
    icon: GuideIcon.safetyHelp,
    order: 5,
    isPublished: true,
    translations: [
      UserGuideTranslation(
        locale: 'en',
        title: 'Safety and help',
        summary: 'Check the machine and terms before confirming. Use Help if something goes wrong.',
        content: 'Before confirming an order, carefully check the equipment, price, and working conditions. Discuss important details in PROKAT chat. If a question or problem appears, open Help — you can find an answer there or contact support.',
      ),
      UserGuideTranslation(
        locale: 'ru',
        title: 'Безопасность и помощь',
        summary: 'Перед подтверждением заказа проверьте технику, стоимость и условия работы.',
        content: 'Перед подтверждением заказа внимательно проверьте технику, стоимость и условия работы. Важные детали лучше обсуждать в чате PROKAT. Если возник вопрос или проблема, обратитесь в раздел «Помощь» — там можно найти ответ или связаться с поддержкой.',
      ),
      UserGuideTranslation(
        locale: 'kk',
        title: 'Қауіпсіздік және көмек',
        summary: 'Тапсырысты растамас бұрын техниканы, бағаны және жұмыс шарттарын тексеріңіз.',
        content: 'Тапсырысты растамас бұрын техниканы, құнын және жұмыс шарттарын мұқият тексеріңіз. Маңызды мәліметтерді PROKAT чатында талқылаған дұрыс. Сұрақ немесе мәселе туындаса, «Көмек» бөліміне өтіңіз — онда жауап табуға немесе қолдаумен байланысуға болады.',
      ),
    ],
  ),
];
