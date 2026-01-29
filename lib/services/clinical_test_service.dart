import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/phq9_question.dart';
import '../models/gad7_question.dart';
import 'gemini_service.dart';

/// Сервис для работы с клиническими тестами PHQ-9 и GAD-7
class ClinicalTestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GeminiService _geminiService = GeminiService();

  /// Получить вопросы PHQ-9
  List<Phq9Question> getPhq9Questions() {
    return Phq9Questions.questions;
  }

  /// Получить вопросы GAD-7
  List<Gad7Question> getGad7Questions() {
    return Gad7Questions.questions;
  }

  /// Сохранить ответы PHQ-9 и рассчитать результат
  Future<Phq9Result> submitPhq9Test({
    required String userId,
    required Map<String, Phq9Response> answers, // questionId -> ответ
  }) async {
    // Подсчитываем баллы
    final questionScores = <String, int>{};
    int totalScore = 0;

    for (final entry in answers.entries) {
      final score = entry.value.score;
      questionScores[entry.key] = score;
      totalScore += score;
    }

    // Определяем уровень тяжести
    final severity = Phq9Severity.fromScore(totalScore);

    // Создаем результат
    final result = Phq9Result(
      totalScore: totalScore,
      questionScores: questionScores,
      severity: severity,
      completedAt: DateTime.now(),
    );

    // Сохраняем в Firestore
    await _firestore.collection('phq9_results').add({
      'userId': userId,
      ...result.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Анализируем через Gemini AI с учетом стандартной шкалы
    try {
      final aiAnalysis = await _geminiService.analyzePhq9Result(
        totalScore: totalScore,
        severity: severity,
        questionScores: questionScores,
      );

      // Сохраняем AI анализ
      final resultDoc = await _firestore.collection('phq9_results')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      
      if (resultDoc.docs.isNotEmpty) {
        await resultDoc.docs.first.reference.update({
          'aiAnalysis': aiAnalysis,
        });
        
        // Отправляем результат и рекомендации родителю
        await _notifyParent(userId, 'PHQ-9', result, aiAnalysis);
      }
    } catch (e) {
      print('Ошибка AI анализа PHQ-9: $e');
    }

    // Проверяем на критические маркеры
    if (severity == Phq9Severity.severe || 
        severity == Phq9Severity.moderatelySevere ||
        (questionScores['phq9_9'] ?? 0) > 0) { // Вопрос о суицидальных мыслях
      await _handleCrisisAlert(userId, 'PHQ-9', result);
    }

    return result;
  }

  /// Сохранить ответы GAD-7 и рассчитать результат
  Future<Gad7Result> submitGad7Test({
    required String userId,
    required Map<String, Gad7Response> answers, // questionId -> ответ
  }) async {
    // Подсчитываем баллы
    final questionScores = <String, int>{};
    int totalScore = 0;

    for (final entry in answers.entries) {
      final score = entry.value.score;
      questionScores[entry.key] = score;
      totalScore += score;
    }

    // Определяем уровень тяжести
    final severity = Gad7Severity.fromScore(totalScore);

    // Создаем результат
    final result = Gad7Result(
      totalScore: totalScore,
      questionScores: questionScores,
      severity: severity,
      completedAt: DateTime.now(),
    );

    // Сохраняем в Firestore
    await _firestore.collection('gad7_results').add({
      'userId': userId,
      ...result.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Анализируем через Gemini AI с учетом стандартной шкалы
    try {
      final aiAnalysis = await _geminiService.analyzeGad7Result(
        totalScore: totalScore,
        severity: severity,
        questionScores: questionScores,
      );

      // Сохраняем AI анализ
      final resultDoc = await _firestore.collection('gad7_results')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      
      if (resultDoc.docs.isNotEmpty) {
        await resultDoc.docs.first.reference.update({
          'aiAnalysis': aiAnalysis,
        });
        
        // Отправляем результат и рекомендации родителю
        await _notifyParent(userId, 'GAD-7', result, aiAnalysis);
      }
    } catch (e) {
      print('Ошибка AI анализа GAD-7: $e');
    }

    // Проверяем на критические маркеры
    if (severity == Gad7Severity.severe || severity == Gad7Severity.moderate) {
      await _handleCrisisAlert(userId, 'GAD-7', result);
    }

    return result;
  }

  /// Получить последний результат PHQ-9
  Future<Phq9Result?> getLatestPhq9Result(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('phq9_results')
          .where('userId', isEqualTo: userId)
          .orderBy('completedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final data = snapshot.docs.first.data();
      return Phq9Result.fromMap(data);
    } catch (e) {
      print('Ошибка получения PHQ-9 результата: $e');
      return null;
    }
  }

  /// Получить последний результат GAD-7
  Future<Gad7Result?> getLatestGad7Result(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('gad7_results')
          .where('userId', isEqualTo: userId)
          .orderBy('completedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final data = snapshot.docs.first.data();
      return Gad7Result.fromMap(data);
    } catch (e) {
      print('Ошибка получения GAD-7 результата: $e');
      return null;
    }
  }

  /// Получить историю результатов PHQ-9
  Future<List<Phq9Result>> getPhq9History(String userId, {int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('phq9_results')
          .where('userId', isEqualTo: userId)
          .orderBy('completedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => Phq9Result.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Ошибка получения истории PHQ-9: $e');
      return [];
    }
  }

  /// Получить историю результатов GAD-7
  Future<List<Gad7Result>> getGad7History(String userId, {int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('gad7_results')
          .where('userId', isEqualTo: userId)
          .orderBy('completedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => Gad7Result.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Ошибка получения истории GAD-7: $e');
      return [];
    }
  }

  /// Отправка результата и рекомендаций родителю
  Future<void> _notifyParent(
    String userId,
    String testType,
    dynamic result,
    Map<String, dynamic> aiAnalysis,
  ) async {
    try {
      // Получаем данные пользователя
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final parentId = userData['linkedUserId'] as String?;

      if (parentId == null) return;

      // Создаем уведомление для родителя с результатом и рекомендациями
      // ВАЖНО: НЕ включаем questionScores - родитель видит только агрегированные данные
      await _firestore.collection('clinical_test_notifications').add({
        'parentId': parentId,
        'teenId': userId,
        'testType': testType,
        'result': {
          'totalScore': result.totalScore,
          'severity': result.severity.name,
          'completedAt': result.completedAt,
          // НЕ включаем questionScores - только агрегированные данные
        },
        'aiAnalysis': aiAnalysis, // Полный AI анализ с рекомендациями
        'severity': result.severity.name,
        'totalScore': result.totalScore,
        'completedAt': result.completedAt,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      print('✅ Результат $testType отправлен родителю $parentId');
    } catch (e) {
      print('Ошибка отправки результата родителю: $e');
    }
  }

  /// Обработка кризисного алерта
  Future<void> _handleCrisisAlert(String userId, String testType, dynamic result) async {
    try {
      // Получаем данные пользователя
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final parentId = userData['linkedUserId'] as String?;

      if (parentId == null) return;

      // Создаем кризисный алерт
      await _firestore.collection('crisis_alerts').add({
        'userId': userId,
        'parentId': parentId,
        'testType': testType,
        'result': result.toMap(),
        'severity': result.severity.name,
        'createdAt': FieldValue.serverTimestamp(),
        'isResolved': false,
      });

      // Отправляем уведомление родителю (если настроено)
      // TODO: Интеграция с NotificationService
    } catch (e) {
      print('Ошибка создания кризисного алерта: $e');
    }
  }
}

