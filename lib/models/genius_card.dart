import 'package:flutter/material.dart';
import '../models/survey_response.dart';
import '../l10n/app_localizations.dart';

/// Модель карточки "Гении в зоне риска" с поддержкой 3 языков
class GeniusCard {
  final String nameRu;
  final String nameKk;
  final String nameEn;
  final String achievementRu;
  final String achievementKk;
  final String achievementEn;
  final String emoji;
  final String imageUrl;
  final String storyRu;
  final String storyKk;
  final String storyEn;
  final String messageRu;
  final String messageKk;
  final String messageEn;
  final RiskLevel riskLevel;
  final int? minAge;
  final int? maxAge;

  const GeniusCard({
    required this.nameRu,
    required this.nameKk,
    required this.nameEn,
    required this.achievementRu,
    required this.achievementKk,
    required this.achievementEn,
    required this.emoji,
    required this.imageUrl,
    required this.storyRu,
    required this.storyKk,
    required this.storyEn,
    required this.messageRu,
    required this.messageKk,
    required this.messageEn,
    required this.riskLevel,
    this.minAge,
    this.maxAge,
  });

  /// Получить имя на текущем языке
  String getName(BuildContext context) {
    final langCode = AppLocalizations.of(context).locale.languageCode;
    if (langCode == 'kk') return nameKk;
    if (langCode == 'en') return nameEn;
    return nameRu;
  }

  /// Получить достижение на текущем языке
  String getAchievement(BuildContext context) {
    final langCode = AppLocalizations.of(context).locale.languageCode;
    if (langCode == 'kk') return achievementKk;
    if (langCode == 'en') return achievementEn;
    return achievementRu;
  }

  /// Получить историю на текущем языке
  String getStory(BuildContext context) {
    final langCode = AppLocalizations.of(context).locale.languageCode;
    if (langCode == 'kk') return storyKk;
    if (langCode == 'en') return storyEn;
    return storyRu;
  }

  /// Получить сообщение на текущем языке
  String getMessage(BuildContext context) {
    final langCode = AppLocalizations.of(context).locale.languageCode;
    if (langCode == 'kk') return messageKk;
    if (langCode == 'en') return messageEn;
    return messageRu;
  }
}

/// База данных карточек гениев
class GeniusCardsDatabase {
  
  /// Получить proxy URL для изображения (обход CORS)
  static String getProxyImageUrl(String originalUrl) {
    if (originalUrl.isEmpty) return originalUrl;
    final encodedUrl = Uri.encodeComponent(originalUrl);
    return 'https://us-central1-anama-app.cloudfunctions.net/proxyImage?url=$encodedUrl';
  }

  // ═══════════════════════════════════════════════════════════════
  // ЖЕЛТАЯ ЗОНА — Истории преодоления
  // ═══════════════════════════════════════════════════════════════
  
  static List<GeniusCard> yellowZoneCards = [
    GeniusCard(
      nameRu: 'Илон Маск',
      nameKk: 'Илон Маск',
      nameEn: 'Elon Musk',
      achievementRu: 'Tesla, SpaceX',
      achievementKk: 'Tesla, SpaceX',
      achievementEn: 'Tesla, SpaceX',
      emoji: '🚀',
      imageUrl: getProxyImageUrl('https://upload.wikimedia.org/wikipedia/commons/3/34/Elon_Musk_Royal_Society_%28crop2%29.jpg'),
      storyRu: 'В детстве Илон был самым маленьким и «умничающим» ребенком в классе. Его жестко буллили: однажды сверстники столкнули его с лестницы и избивали.',
      storyKk: 'Балалық шағында Илон сыныптағы ең кішкентай және «ақылды» бала болған. Оны қатты буллингтеген: бір күні құрдастары оны баспалдақтан итеріп, соққыға жықты.',
      storyEn: 'As a child, Elon was the smallest and "nerdy" kid in class. He was severely bullied: once his peers pushed him down the stairs and beat him up.',
      messageRu: 'Твоя желтая зона сейчас — это тренировка устойчивости. Илон Маск тоже проходил через это, считая себя "эмоционально слабее". Он научился превращать боль в энергию для полетов на Марс. Ты тоже сейчас строишь свой внутренний двигатель. Продолжаем взлет до зеленого уровня! 🚀',
      messageKk: 'Сенің сары аймағың қазір — тұрақтылық жаттығуы. Илон Маск та осыдан өтті, өзін "эмоционалды әлсіз" деп санады. Ол ауырсынуды Марсқа ұшу энергиясына айналдыруды үйренді. Сен де қазір өзіңнің ішкі қозғалтқышыңды құрып жатырсың. Жасыл деңгейге ұшуды жалғастырамыз! 🚀',
      messageEn: 'Your yellow zone right now is resilience training. Elon Musk went through this too, considering himself "emotionally weaker." He learned to turn pain into energy for flights to Mars. You are also building your inner engine right now. Let\'s continue the takeoff to the green level! 🚀',
      riskLevel: RiskLevel.yellow,
    ),
    GeniusCard(
      nameRu: 'Маркус Перссон',
      nameKk: 'Маркус Перссон',
      nameEn: 'Markus Persson',
      achievementRu: 'Создатель Minecraft',
      achievementKk: 'Minecraft жасаушысы',
      achievementEn: 'Creator of Minecraft',
      emoji: '⛏️',
      imageUrl: getProxyImageUrl('https://cdn.prod.elseone.nl/uploads/2016/02/2668363-1.jpg'),
      storyRu: 'Notch рос очень замкнутым и начал программировать в 7 лет, потому что ему было сложно найти друзей в реальности. Виртуальные миры стали его убежищем.',
      storyKk: 'Notch өте тұйық өсті және 7 жасында программалауды бастады, өйткені шынайы өмірде дос табу оған қиын болды. Виртуалды әлемдер оның баспанасына айналды.',
      storyEn: 'Notch grew up very introverted and started programming at 7 because it was hard for him to find friends in real life. Virtual worlds became his refuge.',
      messageRu: 'Твоя зона одиночества — это пространство для творчества. Notch создал Minecraft, потому что искал свой идеальный мир. Давай построим твой зеленый уровень по блокам! ⛏️',
      messageKk: 'Сенің жалғыздық аймағың — шығармашылық кеңістігі. Notch Minecraft-ты жасады, өйткені өзінің идеалды әлемін іздеді. Сенің жасыл деңгейіңді блоктармен құрайық! ⛏️',
      messageEn: 'Your zone of solitude is a space for creativity. Notch created Minecraft because he was looking for his ideal world. Let\'s build your green level block by block! ⛏️',
      riskLevel: RiskLevel.yellow,
    ),
    GeniusCard(
      nameRu: 'Джефф Безос',
      nameKk: 'Джефф Безос',
      nameEn: 'Jeff Bezos',
      achievementRu: 'Основатель Amazon',
      achievementKk: 'Amazon негізін қалаушы',
      achievementEn: 'Founder of Amazon',
      emoji: '📦',
      imageUrl: getProxyImageUrl('https://www.investopedia.com/thmb/mOMPU9PnQeNMFccggP-sEgrP8C8=/750x0/filters:no_upscale():max_bytes(150000):strip_icc():format(webp)/GettyImages-2244887767-95eee21ef2d64775b5740f57d5117ca1.jpg'),
      storyRu: 'В детстве Джефф пытался превратить гараж родителей в научную лабораторию, но его часто не понимали и считали странным одиночкой.',
      storyKk: 'Балалық шағында Джефф ата-анасының гаражын ғылыми зертханаға айналдыруға тырысты, бірақ оны жиі түсінбеді және біртүрлі жалғыз деп санады.',
      storyEn: 'As a child, Jeff tried to turn his parents\' garage into a science lab, but he was often misunderstood and considered a strange loner.',
      messageRu: 'Чувствуешь, что твои идеи не находят места в этом мире? Безос тоже начинал с сомнений в гараже. Твой желтый свет — это просто этап подготовки к запуску твоей империи. Продолжаем подниматься до зеленого света! 📦',
      messageKk: 'Сенің идеяларың бұл әлемде орын таппайтынын сезінесің бе? Безос та гаражда күмәнданудан бастады. Сенің сары шамың — бұл империяңды іске қосуға дайындық кезеңі. Жасыл шамға көтерілуді жалғастырамыз! 📦',
      messageEn: 'Feel like your ideas don\'t fit in this world? Bezos also started with doubts in a garage. Your yellow light is just a preparation stage for launching your empire. Let\'s keep rising to the green light! 📦',
      riskLevel: RiskLevel.yellow,
    ),
    GeniusCard(
      nameRu: 'Билли Айлиш',
      nameKk: 'Билли Айлиш',
      nameEn: 'Billie Eilish',
      achievementRu: 'Музыкант, 7 Грэмми',
      achievementKk: 'Музыкант, 7 Грэмми',
      achievementEn: 'Musician, 7 Grammy Awards',
      emoji: '🎵',
      imageUrl: getProxyImageUrl('https://bridgetv.ru/s/uploads/ca3bf400b1e4cb1d7d01fb5fbab50c2a-1608294730.jpg'),
      storyRu: 'Билли страдала от депрессии и синдрома Туретта. Она открыто говорит о своих темных периодах и о том, как музыка помогла ей выбраться.',
      storyKk: 'Билли депрессия мен Туретт синдромынан зардап шекті. Ол өзінің қараңғы кезеңдері туралы және музыка оған қалай шығуға көмектескені туралы ашық айтады.',
      storyEn: 'Billie suffered from depression and Tourette syndrome. She openly talks about her dark periods and how music helped her get through.',
      messageRu: 'Твои эмоции — это не слабость, а суперсила. Билли Айлиш превратила свою боль в музыку, которую слушают миллионы. Твой внутренний мир — это твой уникальный звук. Поднимаемся на зеленый! 🎵',
      messageKk: 'Сенің эмоцияларың — бұл әлсіздік емес, суперкүш. Билли Айлиш өз ауырсынуын миллиондар тыңдайтын музыкаға айналдырды. Сенің ішкі әлемің — бұл сенің бірегей дыбысың. Жасылға көтерілеміз! 🎵',
      messageEn: 'Your emotions are not weakness, but superpower. Billie Eilish turned her pain into music that millions listen to. Your inner world is your unique sound. Let\'s rise to green! 🎵',
      riskLevel: RiskLevel.yellow,
    ),
    GeniusCard(
      nameRu: 'MrBeast',
      nameKk: 'MrBeast',
      nameEn: 'MrBeast',
      achievementRu: 'YouTube, 200M+ подписчиков',
      achievementKk: 'YouTube, 200M+ жазылушы',
      achievementEn: 'YouTube, 200M+ subscribers',
      emoji: '🎬',
      imageUrl: getProxyImageUrl('https://www.netinfluencer.com/wp-content/uploads/2025/08/MrBeast-Raises-2.3M-For-Clean-Water-On-Kick-Stream-As-Part-Of-40M-TeamWater-Initiative.png'),
      storyRu: 'Джимми заикался и страдал от болезни Крона. Годами выкладывал видео без просмотров. Его считали "странным парнем с камерой".',
      storyKk: 'Джимми кекештеніп, Крон ауруынан зардап шекті. Жылдар бойы көрілімсіз бейнелер жариялады. Оны "камералы біртүрлі жігіт" деп санады.',
      storyEn: 'Jimmy stuttered and suffered from Crohn\'s disease. For years he uploaded videos with no views. He was considered "a weird guy with a camera."',
      messageRu: 'Чувствуешь, что твои усилия никто не замечает? MrBeast 6 лет снимал видео без результата. Упорство + желтая зона = будущий успех. Ты на правильном пути к зеленому! 🎬',
      messageKk: 'Сенің күш-жігеріңді ешкім байқамайтынын сезінесің бе? MrBeast 6 жыл нәтижесіз бейне түсірді. Табандылық + сары аймақ = болашақ табыс. Сен жасылға дұрыс жолдасың! 🎬',
      messageEn: 'Feel like no one notices your efforts? MrBeast filmed videos for 6 years without results. Persistence + yellow zone = future success. You\'re on the right path to green! 🎬',
      riskLevel: RiskLevel.yellow,
    ),
  ];

  // ═══════════════════════════════════════════════════════════════
  // КРАСНАЯ ЗОНА — Серьезные истории преодоления
  // ═══════════════════════════════════════════════════════════════
  
  static List<GeniusCard> redZoneCards = [
    GeniusCard(
      nameRu: 'Деми Ловато',
      nameKk: 'Деми Ловато',
      nameEn: 'Demi Lovato',
      achievementRu: 'Певица, актриса',
      achievementKk: 'Әнші, актриса',
      achievementEn: 'Singer, actress',
      emoji: '💜',
      imageUrl: getProxyImageUrl('https://sefon.pro/img/artist_photos/demi-lovato.jpg'),
      storyRu: 'Деми прошла через тяжелейшие периоды: самоповреждение, расстройства пищевого поведения, зависимости. Сейчас она помогает миллионам говорить о ментальном здоровье.',
      storyKk: 'Деми ең ауыр кезеңдерден өтті: өзіне зиян келтіру, тамақтану бұзылыстары, тәуелділік. Қазір ол миллиондарға психикалық денсаулық туралы айтуға көмектесуде.',
      storyEn: 'Demi went through the hardest periods: self-harm, eating disorders, addictions. Now she helps millions speak about mental health.',
      messageRu: 'Красная зона — это сигнал, что тебе нужна поддержка. И это нормально. Деми Ловато прошла через самое дно и стала голосом надежды для миллионов. Ты не один(а). Давай вместе двигаться к свету. 💜',
      messageKk: 'Қызыл аймақ — бұл саған қолдау керек екенінің белгісі. Және бұл қалыпты. Деми Ловато ең түбінен өтіп, миллиондар үшін үміт дауысына айналды. Сен жалғыз емессің. Бірге жарыққа қарай жүрейік. 💜',
      messageEn: 'Red zone is a signal that you need support. And that\'s okay. Demi Lovato went through rock bottom and became a voice of hope for millions. You\'re not alone. Let\'s move towards the light together. 💜',
      riskLevel: RiskLevel.red,
    ),
    GeniusCard(
      nameRu: 'Леди Гага',
      nameKk: 'Леди Гага',
      nameEn: 'Lady Gaga',
      achievementRu: 'Певица, актриса, 13 Грэмми',
      achievementKk: 'Әнші, актриса, 13 Грэмми',
      achievementEn: 'Singer, actress, 13 Grammy Awards',
      emoji: '⭐',
      imageUrl: getProxyImageUrl('https://icdn.lenta.ru/images/2024/07/29/12/20240729123941796/wide_4_3_ce4837469a066d364ddf5c19ab07289d.jpg'),
      storyRu: 'Стефани пережила серьезную травму в 19 лет и долго боролась с ПТСР и хронической болью. Она основала фонд Born This Way для помощи молодежи.',
      storyKk: 'Стефани 19 жасында ауыр жарақат алып, ПТСР және созылмалы ауырсынумен ұзақ күресті. Ол жастарға көмек көрсету үшін Born This Way қорын құрды.',
      storyEn: 'Stephanie experienced serious trauma at 19 and struggled with PTSD and chronic pain for a long time. She founded the Born This Way Foundation to help youth.',
      messageRu: 'То, через что ты проходишь — это не конец истории. Леди Гага прошла через настоящий ад и стала иконой силы. Твоя красная зона — это начало твоего возрождения. Мы рядом. ⭐',
      messageKk: 'Сен басынан өткізіп жатқан нәрсе — бұл оқиғаның соңы емес. Леди Гага шынайы тозақтан өтіп, күш белгісіне айналды. Сенің қызыл аймағың — бұл сенің қайта туылуыңның басы. Біз жаныңдамыз. ⭐',
      messageEn: 'What you\'re going through is not the end of the story. Lady Gaga went through real hell and became an icon of strength. Your red zone is the beginning of your rebirth. We\'re here for you. ⭐',
      riskLevel: RiskLevel.red,
    ),
    GeniusCard(
      nameRu: 'Логан Пол',
      nameKk: 'Логан Пол',
      nameEn: 'Logan Paul',
      achievementRu: 'YouTube, WWE, Prime',
      achievementKk: 'YouTube, WWE, Prime',
      achievementEn: 'YouTube, WWE, Prime',
      emoji: '🥊',
      imageUrl: getProxyImageUrl('https://static.wikia.nocookie.net/theultimatesidemen/images/e/ee/LoganPaulHD.jpg/revision/latest/thumbnail/width/360/height/450?cb=20220808100338'),
      storyRu: 'Логан пережил публичное падение и серьезную депрессию. Он открыто говорит о том, как терапия и поддержка помогли ему вернуться.',
      storyKk: 'Логан көпшілік алдында құлдырау мен ауыр депрессияны басынан өткерді. Ол терапия мен қолдау оған қалай оралуға көмектескені туралы ашық айтады.',
      storyEn: 'Logan experienced a public downfall and serious depression. He openly talks about how therapy and support helped him come back.',
      messageRu: 'Даже когда кажется, что весь мир против тебя — это можно изменить. Логан упал на глазах миллионов и поднялся. Твоя красная зона — это не приговор, а поворотный момент. 🥊',
      messageKk: 'Бүкіл әлем саған қарсы сияқты көрінгенде де — мұны өзгертуге болады. Логан миллиондардың көз алдында құлады және көтерілді. Сенің қызыл аймағың — бұл үкім емес, бетбұрыс сәті. 🥊',
      messageEn: 'Even when it seems like the whole world is against you — this can be changed. Logan fell in front of millions and got back up. Your red zone is not a verdict, but a turning point. 🥊',
      riskLevel: RiskLevel.red,
    ),
  ];

  // ═══════════════════════════════════════════════════════════════
  // ЗЕЛЕНАЯ ЗОНА — По возрастам
  // ═══════════════════════════════════════════════════════════════
  
  static List<GeniusCard> greenZoneCards = [
    // Сектор 1: 10-14 лет — «Уровень Мстителей»
    GeniusCard(
      nameRu: 'Режим Супергероя',
      nameKk: 'Супергерой режимі',
      nameEn: 'Superhero Mode',
      achievementRu: 'Уровень Мстителей',
      achievementKk: 'Қасқырлар деңгейі',
      achievementEn: 'Avengers Level',
      emoji: '⚡',
      imageUrl: '',
      storyRu: 'Твой мозг сейчас работает на уровне суперкомпьютера Тони Старка!',
      storyKk: 'Сенің миың қазір Тони Старктың суперкомпьютері деңгейінде жұмыс істеп жатыр!',
      storyEn: 'Your brain is now working at Tony Stark\'s supercomputer level!',
      messageRu: 'Зеленый свет! У тебя максимальный фокус и чистая энергия. Чтобы закрепить этот "супергеройский режим", попробуй упражнение "Чутье Человека-Паука": замри на 30 секунд и попытайся услышать 3 самых тихих звука в комнате. Это прокачивает твою внимательность до максимума. Ты сегодня настоящий лидер своей команды! 🔥',
      messageKk: 'Жасыл шам! Сенде максималды фокус және таза энергия бар. Бұл "супергерой режимін" бекіту үшін "Өрмекші-адамның сезімі" жаттығуын көр: 30 секунд қозғалмай тұр және бөлмедегі 3 ең тыныш дыбысты естуге тырыс. Бұл сенің зейінділігіңді максимумға дейін арттырады. Сен бүгін өз командаңның шынайы көшбасшысысың! 🔥',
      messageEn: 'Green light! You have maximum focus and pure energy. To lock in this "superhero mode", try the "Spider-Man Sense" exercise: freeze for 30 seconds and try to hear the 3 quietest sounds in the room. This boosts your attention to the max. You\'re a true leader of your team today! 🔥',
      riskLevel: RiskLevel.green,
      minAge: 10,
      maxAge: 14,
    ),
    // Сектор 2: 15-16 лет — «Взлом и Чит-коды»
    GeniusCard(
      nameRu: 'Чистый Поток',
      nameKk: 'Таза Ағым',
      nameEn: 'Pure Flow',
      achievementRu: 'Взлом и Чит-коды',
      achievementKk: 'Бұзу және Чит-кодтар',
      achievementEn: 'Hacking & Cheat Codes',
      emoji: '🌊',
      imageUrl: '',
      storyRu: 'Твой вайб сейчас — чистый поток. Это состояние, в котором залетают лучшие идеи.',
      storyKk: 'Сенің вайбың қазір — таза ағым. Бұл ең жақсы идеялар келетін күй.',
      storyEn: 'Your vibe right now is pure flow. This is the state where the best ideas come.',
      messageRu: 'Зеленый свет! Чтобы зафиксировать этот момент в нейронках, лови лайфхак "Квадратное дыхание": вдохни на 4 счета, задержи на 4, выдохни на 4. Это твой личный сейв-поинт (save point), чтобы оставаться в ресурсе. Красава, так держать! 🤜🤛',
      messageKk: 'Жасыл шам! Бұл сәтті нейрондарда бекіту үшін "Төртбұрышты тыныс алу" лайфхакын ұста: 4 санаққа дем ал, 4-ке ұста, 4-ке шығар. Бұл сенің жеке сейв-поинтің (save point), ресурста қалу үшін. Жарайсың, осылай жалғастыр! 🤜🤛',
      messageEn: 'Green light! To lock this moment in your neurons, catch this "Square Breathing" lifehack: inhale for 4 counts, hold for 4, exhale for 4. This is your personal save point to stay resourceful. Great job, keep it up! 🤜🤛',
      riskLevel: RiskLevel.green,
      minAge: 15,
      maxAge: 16,
    ),
    // Сектор 3: 17-18 лет — «High Performance»
    GeniusCard(
      nameRu: 'High Performance',
      nameKk: 'Жоғары Өнімділік',
      nameEn: 'High Performance',
      achievementRu: 'Режим Лидера',
      achievementKk: 'Көшбасшы режимі',
      achievementEn: 'Leader Mode',
      emoji: '🧠',
      imageUrl: '',
      storyRu: 'Твоя когнитивная система сейчас в идеальном балансе. Это состояние "High Performance" — база для личной эффективности.',
      storyKk: 'Сенің когнитивті жүйең қазір идеалды теңгерімде. Бұл "Жоғары Өнімділік" күйі — жеке тиімділіктің негізі.',
      storyEn: 'Your cognitive system is now in perfect balance. This "High Performance" state is the foundation for personal effectiveness.',
      messageRu: 'Зеленая зона. Просто осознай, в какой части тела ты сейчас чувствуешь эту уверенность? Запомни это ощущение — это твой внутренний центр силы. Ты уже на голову выше большинства, потому что инвестируешь в свой ментальный капитал. Только вперед! 🏆',
      messageKk: 'Жасыл аймақ. Жай ғана сезін, дененің қай бөлігінде қазір бұл сенімділікті сезінесің? Бұл сезімді есте сақта — бұл сенің ішкі күш орталығың. Сен көпшіліктен бір бас жоғарысың, өйткені өзіңнің ментальды капиталыңа инвестиция салудасың. Тек алға! 🏆',
      messageEn: 'Green zone. Just notice, in which part of your body do you feel this confidence right now? Remember this feeling — it\'s your inner center of power. You\'re already a step above most because you\'re investing in your mental capital. Only forward! 🏆',
      riskLevel: RiskLevel.green,
      minAge: 17,
      maxAge: 18,
    ),
  ];

  /// Получить случайную карточку для уровня риска
  static GeniusCard getCardForRisk(RiskLevel risk, {int? age}) {
    switch (risk) {
      case RiskLevel.green:
        if (age != null) {
          // Находим карточку по возрасту
          final ageCard = greenZoneCards.where((c) => 
            c.minAge != null && c.maxAge != null &&
            age >= c.minAge! && age <= c.maxAge!
          ).toList();
          if (ageCard.isNotEmpty) return ageCard.first;
        }
        // По умолчанию для 15-16
        return greenZoneCards[1];
      case RiskLevel.yellow:
        final cards = List<GeniusCard>.from(yellowZoneCards)..shuffle();
        return cards.first;
      case RiskLevel.red:
        final cards = List<GeniusCard>.from(redZoneCards)..shuffle();
        return cards.first;
    }
  }
}
