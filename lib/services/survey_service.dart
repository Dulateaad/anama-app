import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/survey_response.dart';
import '../models/question.dart';
import '../models/daily_insight.dart';
import 'gemini_service.dart';

/// Сервис для работы с опросником
class SurveyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GeminiService _geminiService = GeminiService();

  /// Получить вопросы на сегодня
  List<SurveyQuestion> getTodayQuestions() {
    // В будущем можно выбирать вопросы динамически
    return DefaultQuestions.dailyQuestions;
  }

  /// Сохранить ответ и проанализировать его
  Future<SurveyResponse> submitAnswer({
    required String userId,
    required SurveyQuestion question,
    required String answer,
  }) async {
    RiskLevel riskLevel = RiskLevel.green;
    String aiAnalysis = 'Ответ записан';
    
    // Сначала делаем быстрый локальный анализ (работает всегда)
    final localAnalysis = _analyzeAnswerLocally(question, answer);
    riskLevel = localAnalysis['riskLevel'] as RiskLevel;
    aiAnalysis = localAnalysis['analysis'] as String;
    
    print('📊 Local analysis: $riskLevel - "$answer"');
    
    // Затем пробуем улучшить через Gemini AI
    try {
      final previousResponses = await _getPreviousResponses(userId, limit: 5);
      
      final analysis = await _geminiService.analyzeResponse(
        questionText: question.text,
        answer: answer,
        previousResponses: previousResponses,
      );
      
      final aiRisk = RiskLevel.values.firstWhere(
        (e) => e.name == analysis['riskLevel'],
        orElse: () => riskLevel, // Используем локальный результат как fallback
      );
      
      // Берем более высокий уровень риска
      if (_riskPriority(aiRisk) > _riskPriority(riskLevel)) {
        riskLevel = aiRisk;
        aiAnalysis = analysis['analysis'] ?? aiAnalysis;
      }
      
      // Проверяем на срочность
      if (analysis['isUrgent'] == true) {
        riskLevel = RiskLevel.red;
        aiAnalysis = 'Обнаружены критические маркеры';
      }
    } catch (e) {
      print('Gemini analysis error: $e');
      // Локальный анализ уже выполнен выше
    }

    // Создаем запись ответа
    final response = SurveyResponse(
      id: '',
      userId: userId,
      questionId: question.id,
      questionText: question.text,
      answer: answer,
      answeredAt: DateTime.now(),
      aiRiskLevel: riskLevel,
      aiAnalysis: aiAnalysis,
    );

    // Сохраняем в Firestore
    final docRef = await _firestore
        .collection('survey_responses')
        .add(response.toMap());

    // Проверяем на критические маркеры
    if (riskLevel == RiskLevel.red) {
      await _handleCrisisAlert(userId, response);
    }

    return SurveyResponse(
      id: docRef.id,
      userId: response.userId,
      questionId: response.questionId,
      questionText: response.questionText,
      answer: response.answer,
      answeredAt: response.answeredAt,
      aiRiskLevel: riskLevel,
      aiAnalysis: aiAnalysis,
    );
  }

  /// Приоритет уровня риска (для сравнения)
  int _riskPriority(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.green: return 0;
      case RiskLevel.yellow: return 1;
      case RiskLevel.red: return 2;
    }
  }

  /// Локальный анализ ответа (работает без AI)
  Map<String, dynamic> _analyzeAnswerLocally(SurveyQuestion question, String answer) {
    RiskLevel riskLevel = RiskLevel.green;
    String analysis = 'Ответ записан';
    final lowerAnswer = answer.toLowerCase();
    
    // ═══════════════════════════════════════════════════════════════
    // КРАСНЫЕ МАРКЕРЫ — критический уровень
    // ═══════════════════════════════════════════════════════════════
    final redWords = [
      'умереть', 'убить', 'суицид', 'самоубийство', 
      'конец', 'смысла нет', 'нет смысла', 'исчезнуть', 
      'хочу уйти', 'устал жить', 'зачем жить', 'лучше бы меня не было',
      'всем будет лучше без меня', 'ненавижу себя', 'хочу умереть',
      'резать себя', 'порезы', 'самоповреждение'
    ];
    
    for (final word in redWords) {
      if (lowerAnswer.contains(word)) {
        return {
          'riskLevel': RiskLevel.red,
          'analysis': 'Обнаружены критические маркеры. Требуется внимание.',
        };
      }
    }
    
    // ═══════════════════════════════════════════════════════════════
    // ЖЕЛТЫЕ МАРКЕРЫ — требует внимания
    // ═══════════════════════════════════════════════════════════════
    final yellowWords = [
      'грустно', 'одиноко', 'плохо', 'никто не понимает', 
      'устал', 'устала', 'надоело', 'бесит', 'злюсь', 'злость',
      'тоска', 'тревога', 'страх', 'боюсь', 'волнуюсь',
      'ненавижу', 'раздражает', 'достало', 'не хочу',
      'одинок', 'одинока', 'нет друзей', 'никому не нужен', 'никому не нужна',
      'не понимают', 'не слышат', 'игнорируют', 'буллинг', 'травят',
      'депрессия', 'тревожность', 'панические', 'паника'
    ];
    
    for (final word in yellowWords) {
      if (lowerAnswer.contains(word)) {
        riskLevel = RiskLevel.yellow;
        analysis = 'Заметны признаки беспокойства';
        break;
      }
    }
    
    // ═══════════════════════════════════════════════════════════════
    // АНАЛИЗ ВАРИАНТОВ ОТВЕТА (эмодзи-опции)
    // ═══════════════════════════════════════════════════════════════
    
    // Вопрос 1: "Как ты себя чувствуешь сегодня?"
    if (answer.contains('😢') || answer.contains('Плохо')) {
      riskLevel = RiskLevel.yellow;
      analysis = 'Подросток чувствует себя плохо';
    }
    if (answer.contains('😔') || answer.contains('Не очень')) {
      if (riskLevel == RiskLevel.green) {
        riskLevel = RiskLevel.yellow;
        analysis = 'Подросток чувствует себя не очень хорошо';
      }
    }
    
    // Вопрос 3: "Чувствуешь ли ты, что тебя понимают близкие?"
    if (answer.contains('совсем не понимают') || answer.contains('Нет,')) {
      if (_riskPriority(RiskLevel.yellow) > _riskPriority(riskLevel)) {
        riskLevel = RiskLevel.yellow;
        analysis = 'Подросток чувствует, что его не понимают';
      }
    }
    if (answer.contains('Редко')) {
      if (riskLevel == RiskLevel.green) {
        riskLevel = RiskLevel.yellow;
        analysis = 'Подросток редко чувствует понимание';
      }
    }
    
    // Вопрос 4: "Есть ли у тебя цели или мечты?"
    if (answer.contains('не вижу смысла') || answer.contains('Нет,')) {
      // Это серьезный маркер!
      riskLevel = RiskLevel.yellow;
      analysis = 'Подросток не видит смысла в целях';
    }
    if (answer.contains('Не уверен')) {
      if (riskLevel == RiskLevel.green) {
        riskLevel = RiskLevel.yellow;
        analysis = 'Подросток не уверен в своих целях';
      }
    }
    
    // Вопрос 6: "Отношения с друзьями"
    if (answer.contains('нет друзей') || answer.contains('У меня нет')) {
      if (_riskPriority(RiskLevel.yellow) > _riskPriority(riskLevel)) {
        riskLevel = RiskLevel.yellow;
        analysis = 'Подросток указывает на отсутствие друзей';
      }
    }
    if (answer.contains('Сложные')) {
      if (riskLevel == RiskLevel.green) {
        riskLevel = RiskLevel.yellow;
        analysis = 'У подростка сложные отношения с друзьями';
      }
    }
    
    return {
      'riskLevel': riskLevel,
      'analysis': analysis,
    };
  }

  /// Получить предыдущие ответы для контекста AI
  Future<List<SurveyResponse>> _getPreviousResponses(String userId, {int limit = 5}) async {
    try {
      final snapshot = await _firestore
          .collection('survey_responses')
          .where('userId', isEqualTo: userId)
          .orderBy('answeredAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => SurveyResponse.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting previous responses: $e');
      return [];
    }
  }

  /// Получить сегодняшние ответы подростка
  Future<List<SurveyResponse>> getTodayResponses(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    try {
      final snapshot = await _firestore
          .collection('survey_responses')
          .where('userId', isEqualTo: userId)
          .get();

      // Фильтруем по дате на клиенте (проще, чем создавать индексы)
      return snapshot.docs
          .map((doc) => SurveyResponse.fromMap(doc.data(), doc.id))
          .where((r) => r.answeredAt.isAfter(startOfDay))
          .toList();
    } catch (e) {
      print('Error getting today responses: $e');
      return [];
    }
  }

  /// Проверить, заполнен ли опросник сегодня
  Future<bool> hasCompletedTodaySurvey(String userId) async {
    final responses = await getTodayResponses(userId);
    final totalQuestions = getTodayQuestions().length;
    return responses.length >= totalQuestions;
  }

  /// Генерация ежедневного инсайта для родителя
  Future<DailyInsight?> generateDailyInsightForParent({
    required String teenId,
    required String parentId,
  }) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      // Проверяем, есть ли уже инсайт за сегодня
      final existingInsight = await _firestore
          .collection('daily_insights')
          .where('parentId', isEqualTo: parentId)
          .where('teenId', isEqualTo: teenId)
          .get();
      
      // Ищем инсайт за сегодня
      for (final doc in existingInsight.docs) {
        final data = doc.data();
        final insightDate = data['date']?.toDate();
        if (insightDate != null && insightDate.isAfter(startOfDay)) {
          // Уже есть инсайт за сегодня — возвращаем его
          return DailyInsight.fromMap(data, doc.id);
        }
      }
      
      // Получаем сегодняшние ответы
      final todayResponses = await getTodayResponses(teenId);
      if (todayResponses.isEmpty) return null;

      // Определяем общий уровень риска (берем максимальный)
      RiskLevel overallRisk = RiskLevel.green;
      for (final response in todayResponses) {
        if (response.aiRiskLevel == RiskLevel.red) {
          overallRisk = RiskLevel.red;
          break;
        } else if (response.aiRiskLevel == RiskLevel.yellow) {
          overallRisk = RiskLevel.yellow;
        }
      }

      // Генерируем инсайт через Gemini AI
      Map<String, dynamic> insightData;
      try {
        insightData = await _geminiService.generateDailyInsight(
          todayResponses: todayResponses,
          overallRisk: overallRisk,
        );
      } catch (e) {
        print('Gemini insight error: $e');
        insightData = _getDefaultInsight(overallRisk);
      }

      // Создаем и сохраняем инсайт
      final insight = DailyInsight(
        id: '',
        teenId: teenId,
        parentId: parentId,
        date: DateTime.now(),
        overallRisk: overallRisk,
        aiSummary: insightData['summary'] ?? '',
        aiAdvice: insightData['advice'] ?? '',
        suggestedPhrases: List<String>.from(insightData['phrases'] ?? []),
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('daily_insights')
          .add(insight.toMap());

      return DailyInsight(
        id: docRef.id,
        teenId: insight.teenId,
        parentId: insight.parentId,
        date: insight.date,
        overallRisk: insight.overallRisk,
        aiSummary: insight.aiSummary,
        aiAdvice: insight.aiAdvice,
        suggestedPhrases: insight.suggestedPhrases,
        createdAt: insight.createdAt,
      );
    } catch (e) {
      print('Error generating insight: $e');
      return null;
    }
  }

  Map<String, dynamic> _getDefaultInsight(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.green:
        return {
          'summary': 'Сегодня ребенок в стабильном состоянии.',
          'advice': 'Отличный момент для совместного времяпрепровождения.',
          'phrases': [
            'Как прошел твой день?',
            'Хочешь вместе посмотреть что-нибудь?',
            'Я рад(а), что ты рядом.',
          ],
        };
      case RiskLevel.yellow:
        return {
          'summary': 'Заметны признаки тревоги или беспокойства.',
          'advice': 'Попробуйте мягко поговорить, используя технику активного слушания.',
          'phrases': [
            'Я заметил(а), что ты немного задумчив(а). Хочешь поделиться?',
            'Я всегда готов(а) выслушать тебя без осуждения.',
            'Твои чувства важны для меня.',
          ],
        };
      case RiskLevel.red:
        return {
          'summary': 'Критический уровень. Требуется ваше внимание.',
          'advice': '1. Не оставляйте ребенка одного. 2. Скажите слова поддержки. 3. Свяжитесь со специалистом.',
          'phrases': [
            'Я рядом с тобой, и мы справимся вместе.',
            'Ничего не изменит моей любви к тебе.',
            'Давай поговорим. Я хочу понять, как тебе помочь.',
          ],
        };
    }
  }

  /// Получить историю инсайтов для родителя
  Future<List<DailyInsight>> getInsightHistory(String parentId, {int limit = 30}) async {
    final snapshot = await _firestore
        .collection('daily_insights')
        .where('parentId', isEqualTo: parentId)
        .orderBy('date', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => DailyInsight.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Обработка критического алерта
  Future<void> _handleCrisisAlert(String userId, SurveyResponse response) async {
    try {
      // Получаем информацию о связанном родителе
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final linkedParentId = userDoc.data()?['linkedUserId'];

      if (linkedParentId != null) {
        // Создаем срочный инсайт
        await _firestore.collection('crisis_alerts').add({
          'teenId': userId,
          'parentId': linkedParentId,
          'responseId': response.id,
          'createdAt': FieldValue.serverTimestamp(),
          'isHandled': false,
        });
        
        print('🚨 Crisis alert created for parent: $linkedParentId');
      }
    } catch (e) {
      print('Error handling crisis alert: $e');
    }
  }
}


