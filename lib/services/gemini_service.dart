import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/survey_response.dart';
import '../models/phq9_question.dart';
import '../models/gad7_question.dart';

/// Сервис для работы с Google Gemini AI
/// Системный промпт: Гарвардский эксперт по развитию ребенка
class GeminiService {
  late final GenerativeModel _model;
  late final GenerativeModel _crisisModel; // Отдельная модель для кризисного анализа
  late final GenerativeModel _earlyChildhoodModel; // Модель для блока 0-5 лет
  
  // API ключ Gemini
  static const String _apiKey = 'AIzaSyDoKA3-fWjCFX_LwbfxgQzm0I44flZTnOU';

  /// Системная инструкция: Гарвардский эксперт
  static const String _harvardExpertSystemPrompt = '''
Ты — ведущий эксперт Центра развития ребенка Гарвардского университета (Center on the Developing Child) и специалист по нейробиологии раннего развития. Твоя цель — помогать матерям строить здоровый мозг ребенка и минимизировать последствия токсического стресса.

Твои ключевые компетенции:

1. Методика 'Serve and Return' (Подача и возврат): Генерируй задания, которые стимулируют двустороннее взаимодействие мамы и малыша.

2. Борьба с токсическим стрессом: Распознавай признаки перегрузки нервной системы и предлагай техники регуляции кортизола.

3. Раннее развитие (0-6 лет): Давай советы по формированию когнитивных и социальных навыков.

4. Права ребенка и инклюзия: Твои ответы должны базироваться на уважении личности ребенка и поддержке инклюзивности.

5. Культурный контекст: Учитывай казахстанские культурные особенности и семейные традиции.

Структура ответа (Карточка поддержки):
1. Анализ: Коротко объясни, какая зона мозга сейчас развивается (согласно 7 зонам).
2. Инструкция (Actionable Insight): Конкретная фраза или упражнение на сегодня. Никакой "воды".
3. Триггер прогресса: Укажи, какую зону нужно развивать.

7 зон развития мозга:
- #СиняяЗона_Эмоции — эмоциональная регуляция, лимбическая система
- #ЗеленаяЗона_Речь — языковое развитие, зона Брока и Вернике
- #ОранжеваяЗона_Моторика — двигательные навыки, мозжечок
- #ФиолетоваяЗона_Логика — критическое мышление, префронтальная кора
- #КраснаяЗона_Социум — социальные навыки, зеркальные нейроны
- #ЖелтаяЗона_Творчество — креативность, правое полушарие
- #БирюзоваяЗона_Память — гиппокамп, долгосрочная память
''';

  /// Системная инструкция для кризисного анализа (неизменная)
  static const String _crisisSystemPrompt = '''
Ты — AI-специалист по предотвращению суицидов и кризисной помощи подросткам.
Твоя задача — выявлять критические маркеры эмоционального состояния.

КРИТИЧЕСКИЕ МАРКЕРЫ (требуют немедленного внимания):
- Упоминание суицида, самоповреждения
- Потеря смысла жизни, ощущение безнадежности
- Желание "исчезнуть", "чтобы всё закончилось"
- Прощание с близкими без видимой причины
- Раздача личных вещей
- Описание плана действий
- Ощущение, что "всем будет лучше без меня"

При обнаружении маркеров — немедленно сигнализируй.
''';

  /// Системная инструкция для блока 0-5 лет
  static const String _earlyChildhoodSystemPrompt = '''
Ты — экспертный ассистент по раннему развитию, опирающийся на методики Гарвардского центра развития ребенка. Твоя цель — давать максимально эффективные упражнения для развития речи и нейронных связей.

Твои обязательные правила:

1. Язык: Всегда отвечай на том языке, на котором говорит пользователь (KZ/RU).

2. Структура: Каждое задание должно содержать:
   - Короткое эффективное упражнение (например, игры на развитие речи, ходьба босиком для сенсорики).
   - Напоминание о бытовых мелочах: проверить влажность (норма 40-60%) и температуру (18-22°C), важность прогулок на свежем воздухе.
   ⚠️ Главное: не давать это как «медицинский диагноз», а именно как рекомендации по уходу.

3. Поддержка мамы: Обязательно начни или закончи сообщение словами поддержки:
   - 'Вы большая молодец!'
   - 'Спасибо, что уделяете такое внимание развитию малыша'
   - 'Не забудьте позаботиться о себе'
   - 'Вы делаете важную работу'
   - 'Ваша забота — это основа здорового развития'
   ⚠️ Важно: слова каждый день должны быть разные, как и во всех блоках в светофоре и карточках.

4. Научность: Обосновывай, какую зону мозга развивает игра (через теги для интерактивного мозга).

5. Serve and Return: Все упражнения должны быть основаны на методике "Serve and Return" (стимул-ответ). Например: когда ребенок указывает на предмет, мама должна его назвать и описать — это база для развития речи в Гарвардской методике.

7 зон развития мозга:
- #СиняяЗона_Эмоции — эмоциональная регуляция, лимбическая система
- #ЗеленаяЗона_Речь — языковое развитие, зона Брока и Вернике
- #ОранжеваяЗона_Моторика — двигательные навыки, мозжечок
- #ФиолетоваяЗона_Логика — критическое мышление, префронтальная кора
- #КраснаяЗона_Социум — социальные навыки, зеркальные нейроны
- #ЖелтаяЗона_Творчество — креативность, правое полушарие
- #БирюзоваяЗона_Память — гиппокамп, долгосрочная память
''';

  GeminiService() {
    // Основная модель с Гарвардским экспертом
    _model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: _apiKey,
      systemInstruction: Content.text(_harvardExpertSystemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.9, // Высокая температура для разнообразия
      ),
    );
    
    // Модель для кризисного анализа (низкая температура для точности)
    _crisisModel = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: _apiKey,
      systemInstruction: Content.text(_crisisSystemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.3, // Низкая температура для точности
      ),
    );
    
    // Модель для блока 0-5 лет (высокая температура для креативности)
    _earlyChildhoodModel = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: _apiKey,
      systemInstruction: Content.text(_earlyChildhoodSystemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.9, // Высокая температура для разнообразия заданий
      ),
    );
  }

  /// Анализ ответа и создание Карточки поддержки
  /// Использует методику Serve and Return
  Future<Map<String, dynamic>> analyzeResponse({
    required String questionText,
    required String answer,
    required List<SurveyResponse> previousResponses,
    String? visitorId,
    int? childAgeMonths, // Возраст ребенка в месяцах для персонализации
  }) async {
    // Сначала проверяем на кризисные маркеры
    final isCrisis = await checkForCrisisMarkers(answer);
    if (isCrisis) {
      return {
        'riskLevel': 'red',
        'analysis': 'Обнаружены критические маркеры. Требуется немедленное внимание.',
        'brainZone': '#СиняяЗона_Эмоции',
        'actionableInsight': 'Сейчас важно быть рядом. Обнимите ребенка и скажите: "Я рядом, мы справимся вместе".',
        'concerns': ['Критические маркеры эмоционального состояния'],
        'isUrgent': true,
        'serveAndReturn': 'Просто будьте рядом. Ваше присутствие — главная поддержка.',
      };
    }

    final ageContext = childAgeMonths != null 
        ? 'Возраст ребенка: ${_formatAge(childAgeMonths)}.' 
        : '';

    final prompt = '''
Проанализируй ответ мамы/ребенка и создай Карточку поддержки.

$ageContext

Вопрос: "$questionText"
Ответ: "$answer"

${previousResponses.isNotEmpty ? '''
Контекст предыдущих ответов:
${previousResponses.take(3).map((r) => '- "${r.questionText}": "${r.answer}"').join('\n')}
''' : ''}

Создай Карточку поддержки в формате JSON:
{
  "riskLevel": "green|yellow|red",
  "brainZone": "#Название_Зона (одна из 7 зон)",
  "brainZoneDescription": "Краткое объяснение, почему эта зона актуальна",
  "analysis": "Анализ состояния (2-3 предложения)",
  "actionableInsight": "Конкретная фраза или упражнение на сегодня",
  "serveAndReturn": "Задание по методике Serve and Return — конкретное взаимодействие мама-ребенок",
  "stressRegulation": "Техника регуляции стресса, если нужна (или null)",
  "concerns": ["Маркеры для внимания, если есть"],
  "isUrgent": false,
  "progressTrigger": "Какой навык развивается при выполнении"
}
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '{}';
      
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch != null) {
        return _parseJsonSafely(jsonMatch.group(0)!);
      }
      
      return _getDefaultCard();
    } catch (e) {
      print('Ошибка Gemini API: $e');
      return _getDefaultCard();
    }
  }

  /// Генерация ежедневного инсайта для родителя (Карточка дня)
  Future<Map<String, dynamic>> generateDailyInsight({
    required List<SurveyResponse> todayResponses,
    required RiskLevel overallRisk,
    int? childAgeMonths,
  }) async {
    final riskText = overallRisk == RiskLevel.green ? 'зелёный (стабильно)' 
        : overallRisk == RiskLevel.yellow ? 'жёлтый (требует внимания)' 
        : 'красный (критический)';

    final ageContext = childAgeMonths != null 
        ? 'Возраст ребенка: ${_formatAge(childAgeMonths)}.' 
        : '';

    final prompt = '''
Создай Карточку дня для мамы на основе ответов.

$ageContext
Общий уровень: $riskText

Ответы сегодня:
${todayResponses.map((r) => '- "${r.questionText}": "${r.answer}"').join('\n')}

${overallRisk == RiskLevel.red ? '''
⚠️ КРИТИЧЕСКИЙ УРОВЕНЬ! Обязательно включи:
1. Инструкцию "Не оставляйте ребенка одного"
2. Конкретную технику регуляции кортизола
3. Напоминание о кнопке связи со специалистом
''' : ''}

Создай Карточку дня в формате JSON:
{
  "summary": "Что происходит сегодня (2-3 предложения о состоянии)",
  "brainZone": "#Название_Зона — главная зона для развития сегодня",
  "brainZoneExplanation": "Почему именно эта зона важна сейчас",
  "advice": "Что делать маме (конкретные действия)",
  "serveAndReturnTask": "Конкретное задание Serve and Return на сегодня",
  "stressReduction": "Техника снижения токсического стресса (дыхание, объятия и т.д.)",
  "phrases": [
    "Конкретная фраза 1 для ребенка",
    "Конкретная фраза 2",
    "Конкретная фраза 3"
  ],
  "activitySuggestion": "Совместная активность на 10-15 минут",
  "progressIndicator": "Какой навык развивается при выполнении заданий"
}
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '{}';
      
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch != null) {
        return _parseJsonSafely(jsonMatch.group(0)!);
      }
      
      return _getDefaultInsight(overallRisk);
    } catch (e) {
      print('Ошибка Gemini API: $e');
      return _getDefaultInsight(overallRisk);
    }
  }

  /// Генерация задания Serve and Return
  Future<Map<String, dynamic>> generateServeAndReturnTask({
    required int childAgeMonths,
    String? focusZone,
    String? languageCode, // Код языка (kk, ru)
  }) async {
    // Для детей 0-5 лет используем специальную модель
    final isEarlyChildhood = childAgeMonths <= 60;
    final model = isEarlyChildhood ? _earlyChildhoodModel : _model;
    
    // Генерируем случайный элемент для разнообразия
    final randomVariation = DateTime.now().millisecondsSinceEpoch % 10;
    final variationHints = [
      'создай новое, совершенно другое задание',
      'придумай уникальное упражнение, которое еще не предлагалось',
      'сгенерируй оригинальное задание, отличное от предыдущих',
      'создай свежее задание с новым подходом',
      'придумай необычное упражнение, которое будет отличаться',
      'сгенерируй креативное задание, не похожее на другие',
      'создай интересное упражнение с новым форматом',
      'придумай уникальное задание с оригинальной идеей',
      'сгенерируй разнообразное упражнение',
      'создай новое задание с неожиданным поворотом',
    ];
    
    // Добавляем временную метку для уникальности запроса
    final timestamp = DateTime.now().toIso8601String();
    final uniqueId = DateTime.now().millisecondsSinceEpoch;
    
    // Определяем язык для промпта
    final lang = languageCode ?? 'ru';
    final isKazakh = lang == 'kk';
    
    final prompt = isKazakh ? '''
Serve and Return әдісі бойынша ана мен балаға арналған тапсырма жаса.

⚠️ ӨТЕ МАҢЫЗДЫ: ${variationHints[randomVariation]}. Бұл жаңа, бірегей нұсқа болуы керек, алдыңғы барлық тапсырмалардан ерекшеленуі керек! Алдыңғы тапсырмаларды қайталама!

Сұрау уақыты: $timestamp (ID: $uniqueId)

Баланың жасы: ${_formatAge(childAgeMonths)}
${focusZone != null ? 'Аймаққа назар: $focusZone' : ''}

Тапсырма талаптары:
1. 5-10 минут алуы керек
2. Арнайы жабдықсыз
3. Үйге жарамды
4. Екіжақты өзара әрекеттесуді ынталандырады
5. Міндетті түрде БІРЕГЕЙ болуы керек және алдыңғы тапсырмалардан ерекшеленуі керек
${isEarlyChildhood ? '''
6. Міндетті түрде тұрмыстық кішкене нәрселер туралы еске салу қос:
   - Ылғалдылықты тексеру (норма 40-60%)
   - Температураны тексеру (18-22°C)
   - Таза ауада серуендеудің маңыздылығы
   ⚠️ Мұны күту ұсыныстары ретінде бер, емдеу диагнозы емес
7. Міндетті түрде анаға қолдау сөздерімен баста немесе аяқта (әр уақытта әртүрлі!)
''' : ''}

JSON форматында жауап бер:
{
  "taskTitle": "Тапсырма атауы (қуанышты, түсінікті)",
  "brainZone": "#Аймақ_Атауы",
  "duration": "5-10 минут",
  "steps": [
    "1-қадам: ана не істейді",
    "2-қадам: баланың күтілетін реакциясы",
    "3-қадам: ана қалай жауап береді (return)",
    "4-қадам: өзара әрекеттесуді жалғастыру"
  ],
  "whyItWorks": "Миға пайдасын түсіндіру (1 сөйлем)",
  "variations": ["Әртүрлілік үшін вариация"],
  "signs_of_success": "Тапсырма жұмыс істейтінін қалай түсінуге болады"${isEarlyChildhood ? ''',
  "careReminders": "Ылғалдылық, температура, серуендеу туралы еске салу (күту ұсыныстары ретінде)",
  "momSupport": "Анаға қолдау сөздері (әр уақытта әртүрлі!)"''' : ''}
}
''' : '''
Создай задание по методике Serve and Return для мамы и ребенка.

⚠️ КРИТИЧЕСКИ ВАЖНО: ${variationHints[randomVariation]}. Это должен быть НОВЫЙ, УНИКАЛЬНЫЙ вариант, который ОТЛИЧАЕТСЯ от всех предыдущих заданий! Не повторяй предыдущие задания!

Время запроса: $timestamp (ID: $uniqueId)

Возраст ребенка: ${_formatAge(childAgeMonths)}
${focusZone != null ? 'Фокус на зоне: $focusZone' : ''}

Требования к заданию:
1. Должно занимать 5-10 минут
2. Без специального оборудования
3. Подходит для дома
4. Стимулирует двустороннее взаимодействие
5. ОБЯЗАТЕЛЬНО должно быть УНИКАЛЬНЫМ и отличаться от предыдущих заданий
${isEarlyChildhood ? '''
6. ОБЯЗАТЕЛЬНО включи напоминание о бытовых мелочах:
   - Проверить влажность (норма 40-60%)
   - Проверить температуру (18-22°C)
   - Важность прогулок на свежем воздухе
   ⚠️ Подавай это как рекомендации по уходу, НЕ как медицинский диагноз
7. ОБЯЗАТЕЛЬНО начни или закончи словами поддержки мамы (каждый раз разные!)
''' : ''}

Ответь в формате JSON:
{
  "taskTitle": "Название задания (весёлое, понятное)",
  "brainZone": "#Название_Зона",
  "duration": "5-10 минут",
  "steps": [
    "Шаг 1: что делает мама",
    "Шаг 2: ожидаемая реакция ребенка",
    "Шаг 3: как мама отвечает (return)",
    "Шаг 4: продолжение взаимодействия"
  ],
  "whyItWorks": "Объяснение пользы для мозга (1 предложение)",
  "variations": ["Вариация для разнообразия"],
  "signs_of_success": "Как понять, что задание работает"${isEarlyChildhood ? ''',
  "careReminders": "Напоминание о влажности, температуре, прогулках (как рекомендации по уходу)",
  "momSupport": "Слова поддержки для мамы (каждый раз разные!)"''' : ''}
}
''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '{}';
      
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch != null) {
        return _parseJsonSafely(jsonMatch.group(0)!);
      }
      
      return _getDefaultServeAndReturnTask(childAgeMonths);
    } catch (e) {
      print('Ошибка Gemini API: $e');
      return _getDefaultServeAndReturnTask(childAgeMonths);
    }
  }

  /// Проверка на критические маркеры (кризисная модель)
  Future<bool> checkForCrisisMarkers(String text) async {
    final prompt = '''
Проанализируй текст на наличие КРИТИЧЕСКИХ маркеров:
- Упоминание суицида или самоповреждения
- Потеря смысла жизни
- Желание исчезнуть или "чтобы всё закончилось"
- Прощание с близкими
- Раздача вещей
- Чувство, что "всем будет лучше без меня"

Текст: "$text"

Ответь ТОЛЬКО: true (есть критические маркеры) или false (нет критических маркеров)
''';

    try {
      final response = await _crisisModel.generateContent([Content.text(prompt)]);
      final result = response.text?.toLowerCase().trim() ?? 'false';
      return result.contains('true');
    } catch (e) {
      return false;
    }
  }

  /// Форматирование возраста
  String _formatAge(int months) {
    if (months < 12) {
      return '$months месяцев';
    } else if (months < 24) {
      final years = months ~/ 12;
      final remainingMonths = months % 12;
      if (remainingMonths == 0) {
        return '$years год';
      }
      return '$years год $remainingMonths месяцев';
    } else {
      final years = months ~/ 12;
      final remainingMonths = months % 12;
      if (remainingMonths == 0) {
        return '$years года';
      }
      return '$years года $remainingMonths месяцев';
    }
  }

  Map<String, dynamic> _parseJsonSafely(String jsonString) {
    try {
      jsonString = jsonString.trim();
      if (jsonString.startsWith('{') && jsonString.endsWith('}')) {
        final result = <String, dynamic>{};
        
        // Парсинг основных полей
        final patterns = {
          'riskLevel': r'"riskLevel"\s*:\s*"(\w+)"',
          'analysis': r'"analysis"\s*:\s*"([^"]*)"',
          'summary': r'"summary"\s*:\s*"([^"]*)"',
          'advice': r'"advice"\s*:\s*"([^"]*)"',
          'brainZone': r'"brainZone"\s*:\s*"([^"]*)"',
          'brainZoneDescription': r'"brainZoneDescription"\s*:\s*"([^"]*)"',
          'brainZoneExplanation': r'"brainZoneExplanation"\s*:\s*"([^"]*)"',
          'actionableInsight': r'"actionableInsight"\s*:\s*"([^"]*)"',
          'serveAndReturn': r'"serveAndReturn"\s*:\s*"([^"]*)"',
          'serveAndReturnTask': r'"serveAndReturnTask"\s*:\s*"([^"]*)"',
          'stressRegulation': r'"stressRegulation"\s*:\s*"([^"]*)"',
          'stressReduction': r'"stressReduction"\s*:\s*"([^"]*)"',
          'activitySuggestion': r'"activitySuggestion"\s*:\s*"([^"]*)"',
          'progressTrigger': r'"progressTrigger"\s*:\s*"([^"]*)"',
          'progressIndicator': r'"progressIndicator"\s*:\s*"([^"]*)"',
          'taskTitle': r'"taskTitle"\s*:\s*"([^"]*)"',
          'duration': r'"duration"\s*:\s*"([^"]*)"',
          'whyItWorks': r'"whyItWorks"\s*:\s*"([^"]*)"',
          'signs_of_success': r'"signs_of_success"\s*:\s*"([^"]*)"',
        };
        
        for (var entry in patterns.entries) {
          final match = RegExp(entry.value).firstMatch(jsonString);
          if (match != null) {
            result[entry.key] = match.group(1) ?? '';
          }
        }
        
        // isUrgent
        result['isUrgent'] = jsonString.contains('"isUrgent": true') || 
                            jsonString.contains('"isUrgent":true');
        
        // Парсинг массивов
        final arrayPatterns = {
          'phrases': r'"phrases"\s*:\s*\[([\s\S]*?)\]',
          'concerns': r'"concerns"\s*:\s*\[([\s\S]*?)\]',
          'steps': r'"steps"\s*:\s*\[([\s\S]*?)\]',
          'variations': r'"variations"\s*:\s*\[([\s\S]*?)\]',
        };
        
        for (var entry in arrayPatterns.entries) {
          final match = RegExp(entry.value).firstMatch(jsonString);
          if (match != null) {
            final arrayStr = match.group(1) ?? '';
            result[entry.key] = RegExp(r'"([^"]*)"')
                .allMatches(arrayStr)
                .map((m) => m.group(1) ?? '')
                .where((s) => s.isNotEmpty)
                .toList();
          } else {
            result[entry.key] = [];
          }
        }
        
        return result;
      }
    } catch (e) {
      print('Ошибка парсинга JSON: $e');
    }
    return {};
  }

  Map<String, dynamic> _getDefaultCard() {
    return {
      'riskLevel': 'green',
      'brainZone': '#СиняяЗона_Эмоции',
      'brainZoneDescription': 'Эмоциональная регуляция и безопасная привязанность',
      'analysis': 'Стабильное состояние. Продолжайте тёплое взаимодействие.',
      'actionableInsight': 'Обнимите ребенка и скажите: "Я люблю тебя именно таким/такой".',
      'serveAndReturn': 'Когда ребенок что-то покажет или скажет — отреагируйте с интересом и задайте вопрос.',
      'concerns': [],
      'isUrgent': false,
      'progressTrigger': 'Укрепление эмоциональной связи',
    };
  }

  Map<String, dynamic> _getDefaultInsight(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.green:
        return {
          'summary': 'Сегодня у ребенка стабильное эмоциональное состояние. Отличный день для развивающих игр!',
          'brainZone': '#ЖелтаяЗона_Творчество',
          'brainZoneExplanation': 'В спокойном состоянии мозг открыт для творческого развития.',
          'advice': 'Используйте момент для совместного творчества — это укрепит связь и разовьет правое полушарие.',
          'serveAndReturnTask': 'Предложите ребенку нарисовать что-то вместе. Рисуйте по очереди: вы — линию, ребенок — линию.',
          'stressReduction': 'Сегодня специальные техники не нужны. Просто будьте рядом.',
          'phrases': [
            'Вау, как интересно ты это придумал!',
            'Расскажи мне больше про свой рисунок.',
            'Мне нравится творить вместе с тобой.',
          ],
          'activitySuggestion': 'Совместное рисование или лепка из пластилина (10-15 минут)',
          'progressIndicator': 'Развитие креативности и эмоциональной связи',
        };
      case RiskLevel.yellow:
        return {
          'summary': 'Заметны признаки напряжения. Нервная система ребенка нуждается в регуляции.',
          'brainZone': '#СиняяЗона_Эмоции',
          'brainZoneExplanation': 'При стрессе лимбическая система перегружена. Нужна помощь в регуляции.',
          'advice': 'Снизьте темп, говорите тихим голосом, предложите спокойную активность.',
          'serveAndReturnTask': 'Сядьте рядом и предложите: "Давай подышим вместе, как воздушный шарик — надуваемся и сдуваемся".',
          'stressReduction': 'Техника "5-4-3-2-1": назовите 5 вещей, которые видите, 4 — слышите, 3 — чувствуете.',
          'phrases': [
            'Я вижу, что тебе сейчас непросто. Я рядом.',
            'Давай вместе подышим глубоко.',
            'Твои чувства важны. Я слушаю тебя.',
          ],
          'activitySuggestion': 'Спокойное чтение или объятия под пледом (15 минут)',
          'progressIndicator': 'Восстановление эмоционального баланса',
        };
      case RiskLevel.red:
        return {
          'summary': 'Критический уровень стресса. Нервная система ребенка перегружена.',
          'brainZone': '#СиняяЗона_Эмоции',
          'brainZoneExplanation': 'При токсическом стрессе кортизол повреждает развивающийся мозг. Нужна немедленная регуляция.',
          'advice': '1. НЕ оставляйте ребенка одного. 2. Обнимите крепко. 3. Свяжитесь со специалистом через приложение.',
          'serveAndReturnTask': 'Сейчас не время для заданий. Просто будьте рядом, обнимайте, говорите тихим голосом.',
          'stressReduction': 'Крепкие объятия (20+ секунд) снижают уровень кортизола. Дышите вместе медленно.',
          'phrases': [
            'Я здесь. Я никуда не уйду.',
            'Мы справимся вместе. Ты не один/одна.',
            'Моя любовь к тебе не изменится никогда.',
          ],
          'activitySuggestion': 'Оставайтесь рядом. Тишина и присутствие важнее слов.',
          'progressIndicator': 'Восстановление чувства безопасности',
        };
    }
  }

  Map<String, dynamic> _getDefaultServeAndReturnTask(int ageMonths) {
    // Добавляем случайность для разнообразия дефолтных заданий
    final randomIndex = DateTime.now().millisecondsSinceEpoch % 3;
    
    if (ageMonths < 12) {
      final tasks = [
        {
        'taskTitle': 'Зеркало улыбок',
        'brainZone': '#КраснаяЗона_Социум',
        'duration': '5 минут',
        'steps': [
          'Сядьте лицом к лицу с малышом на расстоянии 30 см',
          'Улыбнитесь и подождите — малыш улыбнется в ответ',
          'Повторите его мимику, добавьте звук "агу"',
          'Продолжайте "разговор" улыбками и звуками',
        ],
        'whyItWorks': 'Активирует зеркальные нейроны и укрепляет социальные связи мозга.',
        'variations': ['Попробуйте высунуть язык — малыш может повторить!'],
        'signs_of_success': 'Малыш следит за вашим лицом и пытается повторять',
        },
        {
          'taskTitle': 'Прятки с голосом',
          'brainZone': '#ЗеленаяЗона_Речь',
          'duration': '5 минут',
          'steps': [
            'Накройте лицо платком и спросите: "Где мама?"',
            'Снимите платок и скажите: "Вот мама!"',
            'Повторите несколько раз с разными интонациями',
            'Когда малыш засмеется — это ваш "return"!',
          ],
          'whyItWorks': 'Развивает понимание постоянства объекта и вызывает радость от взаимодействия.',
          'variations': ['Используйте игрушку вместо лица'],
          'signs_of_success': 'Малыш смеется и следит за вашими действиями',
        },
        {
          'taskTitle': 'Танец ручек',
          'brainZone': '#ОранжеваяЗона_Моторика',
          'duration': '5 минут',
          'steps': [
            'Возьмите ручки малыша в свои',
            'Плавно двигайте ими вверх-вниз, напевая простую мелодию',
            'Остановитесь и подождите реакции малыша',
            'Продолжайте, когда малыш начнет двигаться сам',
          ],
          'whyItWorks': 'Развивает крупную моторику и чувство ритма.',
          'variations': ['Добавьте движения ножками'],
          'signs_of_success': 'Малыш активно двигается и улыбается',
        },
      ];
      return tasks[randomIndex];
    } else if (ageMonths < 36) {
      final tasks = [
        {
        'taskTitle': 'Башня вместе',
        'brainZone': '#ОранжеваяЗона_Моторика',
        'duration': '10 минут',
        'steps': [
          'Возьмите кубики или стаканчики',
          'Положите первый кубик и скажите "Твоя очередь!"',
          'Похвалите попытку, даже если башня упала',
          'Стройте по очереди, комментируя: "Мой кубик, твой кубик"',
        ],
        'whyItWorks': 'Развивает моторику, очередность и понимание причинно-следственных связей.',
        'variations': ['Постройте башню для мишки или куклы'],
        'signs_of_success': 'Ребенок ждет своей очереди и радуется процессу',
        },
        {
          'taskTitle': 'Назови и покажи',
          'brainZone': '#ЗеленаяЗона_Речь',
          'duration': '10 минут',
          'steps': [
            'Покажите предмет и четко назовите: "Это мячик"',
            'Спросите: "Где мячик?" и помогите показать',
            'Повторите с разными предметами',
            'Хвалите каждую попытку назвать или показать',
          ],
          'whyItWorks': 'Расширяет словарный запас и развивает понимание речи.',
          'variations': ['Используйте картинки в книжке'],
          'signs_of_success': 'Ребенок пытается повторить слова или показывает предметы',
        },
        {
          'taskTitle': 'Прятки с игрушкой',
          'brainZone': '#БирюзоваяЗона_Память',
          'duration': '10 минут',
          'steps': [
            'Покажите игрушку и назовите её',
            'Накройте платком и спросите: "Где игрушка?"',
            'Откройте и радостно скажите: "Вот она!"',
            'Повторите, меняя игрушки',
          ],
          'whyItWorks': 'Развивает память и понимание постоянства объекта.',
          'variations': ['Спрячьте игрушку под подушку'],
          'signs_of_success': 'Ребенок ищет игрушку и радуется, когда находит',
        },
      ];
      return tasks[randomIndex];
    } else {
      final tasks = [
        {
        'taskTitle': 'Придумай историю',
        'brainZone': '#ЖелтаяЗона_Творчество',
        'duration': '10 минут',
        'steps': [
          'Начните: "Жил-был маленький зайчик..."',
          'Спросите: "Что он делал?"',
          'Продолжите историю по очереди',
          'Закончите вместе счастливым концом',
        ],
        'whyItWorks': 'Развивает воображение, речь и навыки сотрудничества.',
        'variations': ['Используйте игрушки как персонажей', 'Нарисуйте историю'],
        'signs_of_success': 'Ребенок активно добавляет идеи и смеется',
        },
        {
          'taskTitle': 'Что изменилось?',
          'brainZone': '#ФиолетоваяЗона_Логика',
          'duration': '10 минут',
          'steps': [
            'Разложите 3-4 предмета перед ребенком',
            'Попросите закрыть глаза или отвернуться',
            'Уберите или добавьте один предмет',
            'Спросите: "Что изменилось?"',
          ],
          'whyItWorks': 'Развивает внимание, память и логическое мышление.',
          'variations': ['Поменяйте предметы местами'],
          'signs_of_success': 'Ребенок замечает изменения и радуется',
        },
        {
          'taskTitle': 'Помоги маме',
          'brainZone': '#КраснаяЗона_Социум',
          'duration': '10 минут',
          'steps': [
            'Попросите помочь: "Помоги маме убрать игрушки"',
            'Покажите, как это делать',
            'Хвалите каждое действие: "Молодец, ты помогаешь!"',
            'Делайте вместе, комментируя: "Я убираю, ты убираешь"',
          ],
          'whyItWorks': 'Развивает социальные навыки, эмпатию и чувство значимости.',
          'variations': ['Попросите помочь накрыть на стол', 'Помочь полить цветы'],
          'signs_of_success': 'Ребенок с удовольствием помогает и повторяет действия',
        },
      ];
      return tasks[randomIndex];
    }
  }

  /// Анализ результата PHQ-9 с учетом международных стандартов
  Future<Map<String, dynamic>> analyzePhq9Result({
    required int totalScore,
    required Phq9Severity severity,
    required Map<String, int> questionScores,
  }) async {
    final prompt = '''
Ты — клинический психолог, специализирующийся на работе с подростками. Проанализируй результат теста PHQ-9 (Patient Health Questionnaire-9) — международного стандарта для оценки депрессии.

Результаты теста:
- Общий балл: $totalScore из 27
- Уровень тяжести: ${severity.name} (${severity.emoji})
- Баллы по вопросам: $questionScores

Стандартная интерпретация PHQ-9:
- 0-4: Минимальная депрессия
- 5-9: Легкая депрессия
- 10-14: Умеренная депрессия
- 15-19: Умеренно-тяжелая депрессия
- 20-27: Тяжелая депрессия

⚠️ ОСОБОЕ ВНИМАНИЕ: Если на вопрос 9 (о суицидальных мыслях) балл > 0, это КРИТИЧЕСКИЙ маркер!

Создай анализ в формате JSON:
{
  "summary": "Краткое описание состояния (2-3 предложения)",
  "severityInterpretation": "Интерпретация уровня тяжести согласно международным стандартам",
  "keyConcerns": ["Основная проблема 1", "Основная проблема 2", "Основная проблема 3"],
  "recommendations": "Конкретные рекомендации для родителей (что делать прямо сейчас)",
  "professionalHelp": "Нужна ли консультация специалиста и почему",
  "immediateActions": ["Действие 1", "Действие 2", "Действие 3"],
  "supportPhrases": ["Фраза поддержки 1", "Фраза поддержки 2", "Фраза поддержки 3"],
  "isCrisis": ${severity == Phq9Severity.severe || (questionScores['phq9_9'] ?? 0) > 0}
}
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '{}';
      
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch != null) {
        return _parseJsonSafely(jsonMatch.group(0)!);
      }
      
      return _getDefaultPhq9Analysis(severity, questionScores);
    } catch (e) {
      print('Ошибка Gemini API при анализе PHQ-9: $e');
      return _getDefaultPhq9Analysis(severity, questionScores);
    }
  }

  /// Анализ результата GAD-7 с учетом международных стандартов
  Future<Map<String, dynamic>> analyzeGad7Result({
    required int totalScore,
    required Gad7Severity severity,
    required Map<String, int> questionScores,
  }) async {
    final prompt = '''
Ты — клинический психолог, специализирующийся на работе с подростками. Проанализируй результат теста GAD-7 (Generalized Anxiety Disorder-7) — международного стандарта для оценки тревожности.

Результаты теста:
- Общий балл: $totalScore из 21
- Уровень тяжести: ${severity.name} (${severity.emoji})
- Баллы по вопросам: $questionScores

Стандартная интерпретация GAD-7:
- 0-4: Минимальная тревожность
- 5-9: Легкая тревожность
- 10-14: Умеренная тревожность
- 15-21: Тяжелая тревожность

Создай анализ в формате JSON:
{
  "summary": "Краткое описание состояния (2-3 предложения)",
  "severityInterpretation": "Интерпретация уровня тяжести согласно международным стандартам",
  "keyConcerns": ["Основная проблема 1", "Основная проблема 2", "Основная проблема 3"],
  "recommendations": "Конкретные рекомендации для родителей (что делать прямо сейчас)",
  "professionalHelp": "Нужна ли консультация специалиста и почему",
  "immediateActions": ["Действие 1", "Действие 2", "Действие 3"],
  "supportPhrases": ["Фраза поддержки 1", "Фраза поддержки 2", "Фраза поддержки 3"],
  "relaxationTechniques": ["Техника релаксации 1", "Техника релаксации 2"],
  "isCrisis": ${severity == Gad7Severity.severe}
}
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '{}';
      
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch != null) {
        return _parseJsonSafely(jsonMatch.group(0)!);
      }
      
      return _getDefaultGad7Analysis(severity, questionScores);
    } catch (e) {
      print('Ошибка Gemini API при анализе GAD-7: $e');
      return _getDefaultGad7Analysis(severity, questionScores);
    }
  }

  Map<String, dynamic> _getDefaultPhq9Analysis(Phq9Severity severity, Map<String, int> scores) {
    final hasSuicidalThoughts = (scores['phq9_9'] ?? 0) > 0;
    
    return {
      'summary': 'Результат теста PHQ-9 показывает ${severity.name}.',
      'severityInterpretation': 'Интерпретация уровня тяжести согласно международным стандартам.',
      'keyConcerns': _getPhq9KeyConcerns(scores),
      'recommendations': _getPhq9Recommendations(severity, hasSuicidalThoughts),
      'professionalHelp': _getPhq9ProfessionalHelp(severity, hasSuicidalThoughts),
      'immediateActions': _getPhq9ImmediateActions(severity, hasSuicidalThoughts),
      'supportPhrases': [
        'Я вижу, что тебе сейчас непросто. Я рядом.',
        'Твои чувства важны. Я слушаю тебя.',
        'Мы справимся вместе. Ты не один(а).',
      ],
      'isCrisis': severity == Phq9Severity.severe || hasSuicidalThoughts,
    };
  }

  Map<String, dynamic> _getDefaultGad7Analysis(Gad7Severity severity, Map<String, int> scores) {
    return {
      'summary': 'Результат теста GAD-7 показывает ${severity.name}.',
      'severityInterpretation': 'Интерпретация уровня тяжести согласно международным стандартам.',
      'keyConcerns': _getGad7KeyConcerns(scores),
      'recommendations': _getGad7Recommendations(severity),
      'professionalHelp': _getGad7ProfessionalHelp(severity),
      'immediateActions': _getGad7ImmediateActions(severity),
      'supportPhrases': [
        'Я понимаю, что тревога может быть очень тяжелой. Я рядом.',
        'Ты не один(а) в этом. Мы справимся вместе.',
        'Твои чувства важны. Давай найдем способы помочь.',
      ],
      'relaxationTechniques': [
        'Дыхательное упражнение: вдох на 4 счета, выдох на 6 счетов',
        'Техника "5-4-3-2-1": назови 5 вещей, которые видишь, 4 — слышишь, 3 — чувствуешь',
        'Прогрессивная мышечная релаксация',
      ],
      'isCrisis': severity == Gad7Severity.severe,
    };
  }

  /// Анализ результата теста "Светофор" (13-17 лет)
  /// Основан на PHQ-9, GAD-7 и методиках Yale/Harvard
  Future<Map<String, dynamic>> analyzeTrafficLightResult({
    required int totalScore,
    required int blockAScore, // Энергия (PHQ-9 база)
    required int blockBScore, // Тревога (GAD-7 база)
    required int blockCScore, // Социальный (Yale/Harvard)
    required RiskLevel riskLevel,
    required Map<String, int> questionScores,
  }) async {
    final prompt = '''
Ты — клинический психолог, специализирующийся на работе с подростками 13-17 лет. Проанализируй результат теста "Светофор" — это адаптированная версия PHQ-9, GAD-7 и методик Yale/Harvard для подростков.

⚠️ КРИТИЧЕСКИ ВАЖНО: 
- Этот тест НЕ является медицинским диагнозом
- ИИ анализирует данные АНОНИМНО
- Выдавай только УРОВЕНЬ РИСКА, а не диагноз
- Не используй медицинские термины (депрессия, тревожное расстройство и т.д.)
- Используй понятный для подростков язык

Результаты теста:
- Общий балл: $totalScore из 21
- Блок А (Энергия и Смысл, база PHQ-9): $blockAScore из 9
- Блок Б (Тревога, база GAD-7): $blockBScore из 6
- Блок В (Социальный статус и Будущее, Yale/Harvard): $blockCScore из 6
- Уровень риска: ${riskLevel.name} (${riskLevel.emoji})
- Баллы по вопросам: $questionScores

Интерпретация уровней риска:
- 0-5 баллов: Зеленый свет (🟢) — всё стабильно
- 6-12 баллов: Желтая зона (🟡) — требует внимания
- 13-21 балл: Красная зона (🔴) — критический уровень

Создай анализ в формате JSON:
{
  "summary": "Краткое описание эмоционального состояния подростка (2-3 предложения, БЕЗ медицинских терминов)",
  "riskLevelInterpretation": "Интерпретация уровня риска простым языком для подростка",
  "keyConcerns": ["Основная проблема 1", "Основная проблема 2", "Основная проблема 3"],
  "recommendations": "Конкретные рекомендации для родителей (что делать прямо сейчас, БЕЗ медицинских терминов)",
  "supportPhrases": ["Фраза поддержки 1", "Фраза поддержки 2", "Фраза поддержки 3"],
  "isCrisis": ${riskLevel == RiskLevel.red}
}

Помни: НЕ используй медицинские диагнозы, только уровень риска и рекомендации!
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '{}';
      
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch != null) {
        final parsed = _parseJsonSafely(jsonMatch.group(0)!);
        return {
          ...parsed,
          'totalScore': totalScore,
          'blockAScore': blockAScore,
          'blockBScore': blockBScore,
          'blockCScore': blockCScore,
        };
      }
      
      return _getDefaultTrafficLightAnalysis(riskLevel, blockAScore, blockBScore, blockCScore);
    } catch (e) {
      print('Ошибка Gemini API при анализе теста "Светофор": $e');
      return _getDefaultTrafficLightAnalysis(riskLevel, blockAScore, blockBScore, blockCScore);
    }
  }

  Map<String, dynamic> _getDefaultTrafficLightAnalysis(
    RiskLevel riskLevel,
    int blockAScore,
    int blockBScore,
    int blockCScore,
  ) {
    String summary;
    String recommendations;

    switch (riskLevel) {
      case RiskLevel.green:
        summary = 'Твое эмоциональное состояние стабильно. Ты чувствуешь себя хорошо и готов(а) к новым вызовам.';
        recommendations = 'Продолжай заботиться о себе. Поддерживай здоровый режим сна, питания и физической активности.';
        break;
      case RiskLevel.yellow:
        summary = 'Твое эмоциональное состояние требует внимания. Есть некоторые признаки усталости или тревоги.';
        recommendations = 'Рекомендуем обратить внимание на режим дня, больше отдыхать и общаться с близкими. Если чувствуешь, что нужна поддержка — не стесняйся обратиться за помощью.';
        break;
      case RiskLevel.red:
        summary = 'Твое эмоциональное состояние требует немедленного внимания. Ты можешь чувствовать сильную усталость, тревогу или подавленность.';
        recommendations = '⚠️ КРИТИЧЕСКАЯ СИТУАЦИЯ: Немедленно обратитесь к специалисту. Не оставляйте ребенка одного. Обеспечьте безопасность и поддержку.';
        break;
    }

    return {
      'summary': summary,
      'riskLevelInterpretation': riskLevel.description,
      'keyConcerns': _getTrafficLightKeyConcerns(blockAScore, blockBScore, blockCScore),
      'recommendations': recommendations,
      'supportPhrases': [
        'Ты не один(а). Мы рядом и готовы помочь.',
        'Твои чувства важны и имеют значение.',
        'Вместе мы справимся с любыми трудностями.',
      ],
      'isCrisis': riskLevel == RiskLevel.red,
      'totalScore': blockAScore + blockBScore + blockCScore,
      'blockAScore': blockAScore,
      'blockBScore': blockBScore,
      'blockCScore': blockCScore,
    };
  }

  List<String> _getTrafficLightKeyConcerns(int blockA, int blockB, int blockC) {
    final concerns = <String>[];
    if (blockA >= 6) concerns.add('Низкий уровень энергии и потеря интереса');
    if (blockB >= 4) concerns.add('Высокий уровень тревоги и беспокойства');
    if (blockC >= 4) concerns.add('Трудности с социальными отношениями и будущим');
    return concerns.isEmpty ? ['Требуется наблюдение'] : concerns;
  }

  List<String> _getPhq9KeyConcerns(Map<String, int> scores) {
    final concerns = <String>[];
    if ((scores['phq9_1'] ?? 0) >= 2) concerns.add('Плохое настроение и подавленность');
    if ((scores['phq9_2'] ?? 0) >= 2) concerns.add('Потеря интереса к деятельности');
    if ((scores['phq9_3'] ?? 0) >= 2) concerns.add('Проблемы со сном');
    if ((scores['phq9_4'] ?? 0) >= 2) concerns.add('Усталость и нехватка энергии');
    if ((scores['phq9_9'] ?? 0) > 0) concerns.add('⚠️ КРИТИЧЕСКИ: Суицидальные мысли');
    return concerns.isEmpty ? ['Требуется наблюдение'] : concerns;
  }

  List<String> _getGad7KeyConcerns(Map<String, int> scores) {
    final concerns = <String>[];
    if ((scores['gad7_1'] ?? 0) >= 2) concerns.add('Нервозность и напряжение');
    if ((scores['gad7_2'] ?? 0) >= 2) concerns.add('Невозможность контролировать беспокойство');
    if ((scores['gad7_3'] ?? 0) >= 2) concerns.add('Чрезмерное беспокойство');
    if ((scores['gad7_4'] ?? 0) >= 2) concerns.add('Трудности с расслаблением');
    return concerns.isEmpty ? ['Требуется наблюдение'] : concerns;
  }

  String _getPhq9Recommendations(Phq9Severity severity, bool hasSuicidalThoughts) {
    if (hasSuicidalThoughts) {
      return '⚠️ КРИТИЧЕСКАЯ СИТУАЦИЯ: Немедленно обратитесь к специалисту. Не оставляйте ребенка одного.';
    }
    switch (severity) {
      case Phq9Severity.severe:
      case Phq9Severity.moderatelySevere:
        return 'Необходима консультация специалиста. Обеспечьте поддержку и наблюдение.';
      case Phq9Severity.moderate:
        return 'Рекомендуется консультация специалиста. Обеспечьте эмоциональную поддержку.';
      case Phq9Severity.mild:
        return 'Рекомендуется наблюдение и поддержка. Обратите внимание на изменения в поведении.';
      case Phq9Severity.minimal:
        return 'Продолжайте поддерживать ребенка. Регулярно проверяйте его состояние.';
    }
  }

  String _getGad7Recommendations(Gad7Severity severity) {
    switch (severity) {
      case Gad7Severity.severe:
        return 'Необходима консультация специалиста. Используйте техники релаксации.';
      case Gad7Severity.moderate:
        return 'Рекомендуется консультация специалиста. Практикуйте техники релаксации вместе.';
      case Gad7Severity.mild:
        return 'Рекомендуется наблюдение. Используйте техники релаксации и дыхательные упражнения.';
      case Gad7Severity.minimal:
        return 'Продолжайте поддерживать ребенка. Используйте профилактические техники релаксации.';
    }
  }

  String _getPhq9ProfessionalHelp(Phq9Severity severity, bool hasSuicidalThoughts) {
    if (hasSuicidalThoughts) {
      return 'ДА, НЕМЕДЛЕННО. Суицидальные мысли требуют немедленной профессиональной помощи.';
    }
    switch (severity) {
      case Phq9Severity.severe:
      case Phq9Severity.moderatelySevere:
        return 'ДА, обязательно. Тяжелые симптомы требуют профессиональной помощи.';
      case Phq9Severity.moderate:
        return 'ДА, рекомендуется. Умеренные симптомы лучше всего лечатся с помощью специалиста.';
      case Phq9Severity.mild:
        return 'Можно рассмотреть, если симптомы сохраняются или ухудшаются.';
      case Phq9Severity.minimal:
        return 'Не обязательно, но можно проконсультироваться для профилактики.';
    }
  }

  String _getGad7ProfessionalHelp(Gad7Severity severity) {
    switch (severity) {
      case Gad7Severity.severe:
        return 'ДА, обязательно. Тяжелая тревожность требует профессиональной помощи.';
      case Gad7Severity.moderate:
        return 'ДА, рекомендуется. Умеренная тревожность лучше всего лечится с помощью специалиста.';
      case Gad7Severity.mild:
        return 'Можно рассмотреть, если симптомы сохраняются или ухудшаются.';
      case Gad7Severity.minimal:
        return 'Не обязательно, но можно проконсультироваться для профилактики.';
    }
  }

  List<String> _getPhq9ImmediateActions(Phq9Severity severity, bool hasSuicidalThoughts) {
    if (hasSuicidalThoughts) {
      return [
        'НЕ ОСТАВЛЯЙТЕ РЕБЕНКА ОДНОГО',
        'Немедленно свяжитесь со специалистом или кризисной службой',
        'Обеспечьте безопасность (уберите потенциально опасные предметы)',
      ];
    }
    switch (severity) {
      case Phq9Severity.severe:
      case Phq9Severity.moderatelySevere:
        return [
          'Обеспечьте постоянное наблюдение',
          'Свяжитесь со специалистом в ближайшее время',
          'Создайте безопасное и поддерживающее окружение',
        ];
      case Phq9Severity.moderate:
        return [
          'Усильте эмоциональную поддержку',
          'Запишитесь на консультацию к специалисту',
          'Регулярно проверяйте состояние ребенка',
        ];
      case Phq9Severity.mild:
        return [
          'Обеспечьте эмоциональную поддержку',
          'Наблюдайте за изменениями',
          'Практикуйте совместные активности',
        ];
      case Phq9Severity.minimal:
        return [
          'Продолжайте поддерживать ребенка',
          'Регулярно общайтесь',
          'Следите за изменениями настроения',
        ];
    }
  }

  List<String> _getGad7ImmediateActions(Gad7Severity severity) {
    switch (severity) {
      case Gad7Severity.severe:
        return [
          'Обеспечьте спокойную обстановку',
          'Свяжитесь со специалистом в ближайшее время',
          'Практикуйте техники релаксации вместе',
        ];
      case Gad7Severity.moderate:
        return [
          'Используйте техники релаксации',
          'Запишитесь на консультацию к специалисту',
          'Создайте предсказуемый распорядок дня',
        ];
      case Gad7Severity.mild:
        return [
          'Практикуйте дыхательные упражнения',
          'Обеспечьте эмоциональную поддержку',
          'Создайте спокойную обстановку',
        ];
      case Gad7Severity.minimal:
        return [
          'Продолжайте поддерживать ребенка',
          'Используйте профилактические техники релаксации',
          'Следите за уровнем стресса',
        ];
    }
  }

  /// Генерация динамических вопросов для теста "Светофор" на основе истории
  /// Темы: смысл жизни, одиночество, самоидентификация
  Future<List<Map<String, dynamic>>> generateTrafficLightQuestions({
    required String userId,
    required List<Map<String, dynamic>> history,
  }) async {
    final historyText = history.isEmpty
        ? 'Истории ответов пока нет (первый раз прохождения теста).'
        : history.map((h) => 
            'Дата: ${h['date']}, Общий балл: ${h['totalScore']}, '
            'Блок А (Энергия): ${h['blockAScore']}, '
            'Блок Б (Тревога): ${h['blockBScore']}, '
            'Блок В (Социальный): ${h['blockCScore']}, '
            'Уровень риска: ${h['riskLevel']}'
          ).join('\n');

    final prompt = '''
Ты — клинический психолог, специализирующийся на работе с подростками 13-17 лет. Твоя задача — сгенерировать 7 уникальных вопросов для теста "Светофор", которые НЕ повторяют вопросы из предыдущих дней.

⚠️ КРИТИЧЕСКИ ВАЖНО:
- Каждый день вопросы должны быть РАЗНЫМИ
- Опирайся на три ключевые темы: смысл жизни, одиночество, самоидентификация
- Используй язык подростков (не формальный, понятный)
- Вопросы должны быть эмпатичными и поддерживающими
- Избегай медицинских терминов

История ответов за последние 3-5 дней:
$historyText

Структура вопросов (7 вопросов):
- Блок А (Энергия и Смысл, 3 вопроса): фокус на теме "смысл жизни"
- Блок Б (Тревога, 2 вопроса): фокус на теме "одиночество"
- Блок В (Социальный, 2 вопроса): фокус на теме "самоидентификация"

Каждый вопрос должен:
1. Быть уникальным (не повторять предыдущие)
2. Обращаться к подростку на "ты"
3. Быть конкретным и понятным
4. Касаться одной из трех тем

Верни JSON в формате:
{
  "questions": [
    {
      "id": "tl_a1",
      "textRu": "Текст вопроса на русском",
      "textKk": "Текст вопроса на казахском",
      "order": 1,
      "block": "energy"
    },
    {
      "id": "tl_a2",
      "textRu": "...",
      "textKk": "...",
      "order": 2,
      "block": "energy"
    },
    {
      "id": "tl_a3",
      "textRu": "...",
      "textKk": "...",
      "order": 3,
      "block": "energy"
    },
    {
      "id": "tl_b1",
      "textRu": "...",
      "textKk": "...",
      "order": 4,
      "block": "anxiety"
    },
    {
      "id": "tl_b2",
      "textRu": "...",
      "textKk": "...",
      "order": 5,
      "block": "anxiety"
    },
    {
      "id": "tl_c1",
      "textRu": "...",
      "textKk": "...",
      "order": 6,
      "block": "social"
    },
    {
      "id": "tl_c2",
      "textRu": "...",
      "textKk": "...",
      "order": 7,
      "block": "social"
    }
  ]
}

Примеры вопросов по темам:
- Смысл жизни: "Что придает смысл твоей жизни прямо сейчас?", "Есть ли что-то, ради чего ты готов вставать по утрам?"
- Одиночество: "Как часто ты чувствуешь, что тебя никто не понимает?", "Бывает ли так, что даже в компании ты чувствуешь себя одиноким?"
- Самоидентификация: "Кто ты на самом деле, когда никто не смотрит?", "Что делает тебя уникальным?"
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '{}';
      
      // Извлекаем JSON из ответа
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch != null) {
        final jsonData = _parseJsonSafely(jsonMatch.group(0)!);
        final questions = jsonData['questions'] as List<dynamic>?;
        
        if (questions != null && questions.length == 7) {
          return questions.cast<Map<String, dynamic>>();
        }
      }
      
      // Если не удалось распарсить, возвращаем стандартные вопросы
      print('⚠️ Не удалось сгенерировать вопросы через Gemini, используем стандартные');
      return _getDefaultTrafficLightQuestions();
    } catch (e) {
      print('Ошибка Gemini API при генерации вопросов: $e');
      return _getDefaultTrafficLightQuestions();
    }
  }

  /// Стандартные вопросы (fallback)
  List<Map<String, dynamic>> _getDefaultTrafficLightQuestions() {
    return [
      {
        'id': 'tl_a1',
        'textRu': 'Твои батарейки: Как часто за последнюю неделю ты чувствовал, что у тебя совсем нет сил, даже если ты не перетруждался?',
        'textKk': 'Сенің батареяларың: Соңғы аптада қаншалықты жиі сіз күш жетіспеушілігін сездіңіз, тіпті егер сіз асыра жұмыс істемеген болсаңыз?',
        'order': 1,
        'block': 'energy',
      },
      {
        'id': 'tl_a2',
        'textRu': 'Интерес к «движу»: Было ли такое, что вещи, которые ты раньше обожал (игры, хобби, прогулки), вдруг стали казаться скучными или бессмысленными?',
        'textKk': '«Қозғалысқа» қызығушылық: Бұрын сүйген нәрселеріңіз (ойындар, хобби, серуендер) кенеттен жалықтыратын немесе мағынасыз болып көрінді ме?',
        'order': 2,
        'block': 'energy',
      },
      {
        'id': 'tl_a3',
        'textRu': 'Ощущение «невидимки»: Как часто тебе кажется, что тебя никто по-настоящему не понимает, даже если ты в компании?',
        'textKk': '«Көрінбейтін» сезімі: Қаншалықты жиі сізге өзіңізді ешкім шынайы түсінбейді деп көрінеді, тіпті егер сіз компанияда болсаңыз?',
        'order': 3,
        'block': 'energy',
      },
      {
        'id': 'tl_b1',
        'textRu': 'Режим «Overthinking»: Часто ли ты ловишь себя на том, что мозг по кругу крутит плохие мысли, которые ты не можешь остановить?',
        'textKk': '«Overthinking» режимі: Қаншалықты жиі сіз миыңыздың нашар ойларды тоқтата алмайтындығын байқайсыз?',
        'order': 4,
        'block': 'anxiety',
      },
      {
        'id': 'tl_b2',
        'textRu': 'Ожидание подвоха: Чувствуешь ли ты внезапную тревогу, будто вот-вот случится что-то плохое, хотя причин для этого нет?',
        'textKk': 'Айла-шарғы күту: Сіз кенеттен мазасыздық сезінесіз бе, сізге нашар нәрсе болатын сияқты, дегенмен бұл үшін себептер жоқ?',
        'order': 5,
        'block': 'anxiety',
      },
      {
        'id': 'tl_c1',
        'textRu': 'Взгляд в «завтра»: Что ты чувствуешь, когда думаешь о своем будущем (школа, экзамены, жизнь)?',
        'textKk': '«Ертеңге» қарау: Сіз өзіңіздің болашағыңыз туралы ойланғанда (мектеп, емтихандар, өмір) не сезінесіз?',
        'order': 6,
        'block': 'social',
      },
      {
        'id': 'tl_c2',
        'textRu': 'Давление извне: Кажется ли тебе, что от тебя все постоянно чего-то требуют, и ты не справляешься с этим давлением?',
        'textKk': 'Сырттан қысым: Сізге барлығы сізден үнемі бір нәрсені талап етіп, сіз бұл қысымға төзбейтініңіз көрінеді ме?',
        'order': 7,
        'block': 'social',
      },
    ];
  }
}
