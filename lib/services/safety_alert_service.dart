import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/survey_response.dart';
import 'notification_service.dart';

/// Сервис Safety Alert — критические уведомления и экстренная связь
class SafetyAlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  /// Экстренные номера Казахстана
  static const Map<String, String> emergencyNumbers = {
    'crisis_hotline': '111',      // Телефон доверия
    'emergency': '112',           // Единая служба спасения  
    'police': '102',              // Полиция
    'child_rights': '150',        // Защита прав детей
  };

  /// Карточки поддержки по уровням риска
  static Map<RiskLevel, SupportCard> getSupportCards(String languageCode) {
    final isKazakh = languageCode == 'kk';
    
    return {
      RiskLevel.green: SupportCard(
        level: RiskLevel.green,
        emoji: '🟢',
        title: isKazakh ? 'Бәрі жақсы!' : 'Всё хорошо!',
        aiAnalysis: isKazakh 
          ? 'Бала тұрақты сезінеді. Ол өзін естілген және қолдау көрген сезінеді.'
          : 'Все стабильно. Ребенок чувствует себя услышанным и поддержанным.',
        actionTitle: isKazakh ? 'Қазір не істеу керек' : 'Что делать сейчас',
        actionText: isKazakh
          ? 'Бірге хобби жасауға тамаша уақыт! Бүгін оның сүйікті ойыны туралы сұраңыз.'
          : 'Отличный момент для совместного хобби! Спросите сегодня про его любимую игру.',
        suggestedPhrases: isKazakh
          ? [
              '«Бүгін мектепте/үйде не қызықты болды?»',
              '«Сенің ойынша не істесек қызық болар еді?»',
              '«Мен сенімен мақтанамын!»',
            ]
          : [
              '«Что интересного было сегодня в школе/дома?»',
              '«Как думаешь, чем нам вместе заняться?»',
              '«Я горжусь тобой!»',
            ],
        showPsychologistButton: false,
        showEmergencyNumbers: false,
      ),
      
      RiskLevel.yellow: SupportCard(
        level: RiskLevel.yellow,
        emoji: '🟡',
        title: isKazakh ? 'Назар аударыңыз' : 'Обратите внимание',
        aiAnalysis: isKazakh
          ? 'Алаңдаушылық немесе жасырын агрессия белгілері пайда болды. Бала қиындық сезінуі мүмкін.'
          : 'Появились маркеры тревоги или скрытой агрессии. Ребенок может испытывать трудности.',
        actionTitle: isKazakh ? 'Белсенді тыңдау техникасы' : 'Техника активного слушания',
        actionText: isKazakh
          ? 'Баланы қысымсыз әңгімеге шығарыңыз. Мына сөз тіркестерін қолданыңыз:'
          : 'Выведите ребенка на разговор без давления. Используйте эти фразы-помощники:',
        suggestedPhrases: isKazakh
          ? [
              '«Мен байқадым, сен бүгін басқаша. Бір нәрсе мазалайды ма?»',
              '«Егер бір нәрсе болса, маған айта аласың. Мен тыңдаймын, сынамаймын».',
              '«Кейде маған да қиын болады. Бірге ойлайық?»',
            ]
          : [
              '«Я заметил(а), что ты сегодня какой-то другой. Что-то беспокоит?»',
              '«Если что-то случилось, ты можешь мне рассказать. Я выслушаю, не буду осуждать».',
              '«Мне тоже иногда бывает трудно. Давай подумаем вместе?»',
            ],
        showPsychologistButton: true,
        showEmergencyNumbers: false,
      ),
      
      RiskLevel.red: SupportCard(
        level: RiskLevel.red,
        emoji: '🔴',
        title: isKazakh ? 'Шұғыл назар аудару!' : 'Требуется срочное внимание!',
        aiAnalysis: isKazakh
          ? 'Критикалық тәуекел. Жоғары стресс деңгейі немесе деструктивті ойлар анықталды.'
          : 'Критический риск. Высокий уровень стресса или деструктивные мысли.',
        actionTitle: isKazakh ? 'Алғашқы психологиялық көмек' : 'Первая психологическая помощь',
        actionText: isKazakh
          ? 'Дереу әрекет етіңіз:'
          : 'Действуйте немедленно:',
        suggestedPhrases: isKazakh
          ? [
              '1. Баланы жалғыз қалдырмаңыз',
              '2. Айтыңыз: «Мен жаныңдамын, біз бірге жеңеміз»',
              '3. Маманмен байланыс түймесін басыңыз',
            ]
          : [
              '1. Не оставляйте ребенка одного',
              '2. Скажите: «Я рядом, мы справимся вместе»',
              '3. Нажмите кнопку связи со специалистом',
            ],
        showPsychologistButton: true,
        showEmergencyNumbers: true,
        urgentMessage: isKazakh
          ? '⚠️ Егер бала өзіне зиян келтіру туралы айтса, ДЕРЕУ 111 немесе 112 қоңырау шалыңыз!'
          : '⚠️ Если ребенок говорит о причинении себе вреда, НЕМЕДЛЕННО звоните 111 или 112!',
      ),
    };
  }

  /// Отправить Safety Alert при обнаружении критического уровня
  Future<void> triggerSafetyAlert({
    required String parentId,
    required String childName,
    required RiskLevel riskLevel,
    required String analysisText,
    String? specificConcern, // Конкретная проблема, выявленная ИИ
  }) async {
    if (riskLevel != RiskLevel.red) return;

    final alert = SafetyAlert(
      parentId: parentId,
      childName: childName,
      riskLevel: riskLevel,
      analysisText: analysisText,
      specificConcern: specificConcern,
      createdAt: DateTime.now(),
    );

    // Сохраняем алерт в Firestore
    await _firestore.collection('safety_alerts').add(alert.toMap());

    // Отправляем пуш-уведомление
    await _notificationService.sendCrisisAlert(
      parentId: parentId,
      message: specificConcern ?? 
        'Обнаружен критический уровень тревоги у $childName. Откройте приложение немедленно.',
    );
  }

  /// Создать предзаполненную заявку на психолога
  Future<String> createUrgentPsychologistRequest({
    required String parentId,
    required String childName,
    required String psychologistId,
    String? concern,
  }) async {
    final request = await _firestore.collection('psychologist_requests').add({
      'parentId': parentId,
      'childName': childName,
      'psychologistId': psychologistId,
      'message': 'Мне нужна срочная консультация для ребенка. ${concern ?? ""}',
      'isUrgent': true,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return request.id;
  }

  /// Получить дежурного психолога
  Future<Map<String, dynamic>?> getOnDutyPsychologist() async {
    // Ищем психолога, который отмечен как дежурный или с наименьшим временем ответа
    final snapshot = await _firestore
        .collection('psychologists')
        .where('isVerified', isEqualTo: true)
        .orderBy('lastActiveAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      // Возвращаем любого верифицированного психолога
      final anyPsychologist = await _firestore
          .collection('psychologists')
          .where('isVerified', isEqualTo: true)
          .limit(1)
          .get();
      
      if (anyPsychologist.docs.isNotEmpty) {
        return {
          'id': anyPsychologist.docs.first.id,
          ...anyPsychologist.docs.first.data(),
        };
      }
      return null;
    }

    return {
      'id': snapshot.docs.first.id,
      ...snapshot.docs.first.data(),
    };
  }

  /// Записать в историю прогресса
  Future<void> logProgressEvent({
    required String childId,
    required String parentId,
    required RiskLevel previousLevel,
    required RiskLevel currentLevel,
    String? note,
  }) async {
    await _firestore.collection('progress_history').add({
      'childId': childId,
      'parentId': parentId,
      'previousLevel': previousLevel.name,
      'currentLevel': currentLevel.name,
      'improved': currentLevel.index < previousLevel.index,
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Получить историю прогресса для генерации инсайтов
  Future<List<Map<String, dynamic>>> getProgressHistory(String childId, {int limit = 7}) async {
    final snapshot = await _firestore
        .collection('progress_history')
        .where('childId', isEqualTo: childId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}

/// Модель карточки поддержки
class SupportCard {
  final RiskLevel level;
  final String emoji;
  final String title;
  final String aiAnalysis;
  final String actionTitle;
  final String actionText;
  final List<String> suggestedPhrases;
  final bool showPsychologistButton;
  final bool showEmergencyNumbers;
  final String? urgentMessage;

  const SupportCard({
    required this.level,
    required this.emoji,
    required this.title,
    required this.aiAnalysis,
    required this.actionTitle,
    required this.actionText,
    required this.suggestedPhrases,
    required this.showPsychologistButton,
    required this.showEmergencyNumbers,
    this.urgentMessage,
  });
}

/// Модель Safety Alert
class SafetyAlert {
  final String parentId;
  final String childName;
  final RiskLevel riskLevel;
  final String analysisText;
  final String? specificConcern;
  final DateTime createdAt;

  SafetyAlert({
    required this.parentId,
    required this.childName,
    required this.riskLevel,
    required this.analysisText,
    this.specificConcern,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'parentId': parentId,
      'childName': childName,
      'riskLevel': riskLevel.name,
      'analysisText': analysisText,
      'specificConcern': specificConcern,
      'createdAt': Timestamp.fromDate(createdAt),
      'acknowledged': false,
    };
  }
}

