import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../models/traffic_light_question.dart';
import '../models/survey_response.dart';
import 'gemini_service.dart';
import 'notification_service.dart';

/// Сервис для работы с тестом "Светофор" (13-17 лет)
class TrafficLightService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GeminiService _geminiService = GeminiService();

  /// Получить вопросы теста "Светофор" (динамическая генерация через Gemini)
  Future<List<TrafficLightQuestion>> getTrafficLightQuestions(String userId) async {
    try {
      // Получаем историю ответов за последние 3-5 дней
      final history = await _getAnswerHistory(userId);
      
      // Генерируем вопросы через Gemini на основе истории
      final questionsData = await _geminiService.generateTrafficLightQuestions(
        userId: userId,
        history: history,
      );
      
      // Преобразуем данные в объекты TrafficLightQuestion
      return questionsData.map((q) {
        final block = q['block'] == 'energy'
            ? TrafficLightBlock.energy
            : q['block'] == 'anxiety'
                ? TrafficLightBlock.anxiety
                : TrafficLightBlock.social;
        
        return TrafficLightQuestion(
          id: q['id'] ?? '',
          textRu: q['textRu'] ?? '',
          textKk: q['textKk'] ?? '',
          textEn: q['textEn'] ?? q['textRu'] ?? '',
          order: q['order'] ?? 0,
          block: block,
        );
      }).toList();
    } catch (e) {
      print('Ошибка генерации вопросов, используем стандартные: $e');
      // В случае ошибки возвращаем стандартные вопросы
      return TrafficLightQuestions.questions;
    }
  }

  /// Получить историю ответов за последние 3-5 дней
  Future<List<Map<String, dynamic>>> _getAnswerHistory(String userId) async {
    try {
      final fiveDaysAgo = DateTime.now().subtract(const Duration(days: 5));
      
      final snapshot = await _firestore
          .collection('traffic_light_results')
          .where('userId', isEqualTo: userId)
          .where('completedAt', isGreaterThan: Timestamp.fromDate(fiveDaysAgo))
          .orderBy('completedAt', descending: true)
          .limit(5)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'date': data['completedAt']?.toDate().toString(),
          'totalScore': data['totalScore'] ?? 0,
          'blockAScore': data['blockAScore'] ?? 0,
          'blockBScore': data['blockBScore'] ?? 0,
          'blockCScore': data['blockCScore'] ?? 0,
          'riskLevel': data['riskLevel'] ?? 'green',
          'questionScores': data['questionScores'] ?? {},
        };
      }).toList();
    } catch (e) {
      print('Ошибка получения истории: $e');
      return [];
    }
  }

  /// Сохранить ответы и рассчитать результат
  Future<TrafficLightResult> submitTrafficLightTest({
    required String userId,
    required Map<String, TrafficLightResponse> answers, // questionId -> ответ
    required BuildContext context, // Для навигации
  }) async {
    // Подсчитываем баллы по блокам
    final questionScores = <String, int>{};
    int blockAScore = 0; // Энергия (вопросы 1-3)
    int blockBScore = 0; // Тревога (вопросы 4-5)
    int blockCScore = 0; // Социальный (вопросы 6-7)
    int totalScore = 0;

    final questions = TrafficLightQuestions.questions;

    for (final entry in answers.entries) {
      final questionId = entry.key;
      final score = entry.value.score;
      questionScores[questionId] = score;
      totalScore += score;

      // Находим вопрос и добавляем балл в соответствующий блок
      final question = questions.firstWhere((q) => q.id == questionId);
      switch (question.block) {
        case TrafficLightBlock.energy:
          blockAScore += score;
          break;
        case TrafficLightBlock.anxiety:
          blockBScore += score;
          break;
        case TrafficLightBlock.social:
          blockCScore += score;
          break;
      }
    }

    // Определяем уровень риска
    final riskLevel = TrafficLightResult.calculateRiskLevel(totalScore);

    // Создаем результат
    final result = TrafficLightResult(
      totalScore: totalScore,
      questionScores: questionScores,
      blockAScore: blockAScore,
      blockBScore: blockBScore,
      blockCScore: blockCScore,
      riskLevel: riskLevel,
      completedAt: DateTime.now(),
    );

    // Получаем AI анализ
    final aiAnalysis = await _geminiService.analyzeTrafficLightResult(
      totalScore: totalScore,
      blockAScore: blockAScore,
      blockBScore: blockBScore,
      blockCScore: blockCScore,
      riskLevel: riskLevel,
      questionScores: questionScores,
    );

    // Сохраняем в Firestore
    await _firestore.collection('traffic_light_results').add({
      'userId': userId,
      'totalScore': totalScore,
      'questionScores': questionScores,
      'blockAScore': blockAScore,
      'blockBScore': blockBScore,
      'blockCScore': blockCScore,
      'riskLevel': riskLevel.name,
      'completedAt': result.completedAt,
      'aiAnalysis': aiAnalysis,
    });

    // Отправляем уведомление родителю, если есть риск
    if (riskLevel != RiskLevel.green) {
      await _sendNotificationToParent(userId, riskLevel, aiAnalysis);
    }

    return result;
  }

  /// Отправить уведомление родителю
  Future<void> _sendNotificationToParent(
    String teenId,
    RiskLevel riskLevel,
    Map<String, dynamic> aiAnalysis,
  ) async {
    try {
      // Находим связанного родителя
      final userDoc = await _firestore.collection('users').doc(teenId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data();
      final parentId = userData?['parentId'] as String?;
      if (parentId == null) return;

      // Сохраняем уведомление для родителя
      await _firestore.collection('clinical_test_notifications').add({
        'parentId': parentId,
        'teenId': teenId,
        'testType': 'Traffic Light',
        'riskLevel': riskLevel.name,
        'totalScore': aiAnalysis['totalScore'],
        'summary': aiAnalysis['summary'],
        'recommendations': aiAnalysis['recommendations'],
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Отправляем push-уведомление
      final title = riskLevel == RiskLevel.red
          ? '🔴 Критический уровень'
          : '🟡 Требует внимания';
      
      final body = riskLevel == RiskLevel.red
          ? 'Ребенок прошел тест "Светофор". Требуется немедленное внимание.'
          : 'Ребенок прошел тест "Светофор". Рекомендуем обратить внимание.';

      await NotificationService().sendAlertToParent(
        parentId: parentId,
        title: title,
        body: body,
        riskLevel: riskLevel,
      );
    } catch (e) {
      print('Ошибка отправки уведомления родителю: $e');
    }
  }

  /// Получить последний результат теста "Светофор"
  Future<TrafficLightResult?> getLatestTrafficLightResult(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('traffic_light_results')
          .where('userId', isEqualTo: userId)
          .orderBy('completedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return TrafficLightResult.fromMap(snapshot.docs.first.data());
    } catch (e) {
      print('Ошибка загрузки результата теста "Светофор": $e');
      return null;
    }
  }
}

