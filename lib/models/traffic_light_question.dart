import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'survey_response.dart';

/// Модель вопроса теста "Светофор" (13-17 лет)
/// Основан на PHQ-9, GAD-7 и методиках Yale/Harvard
class TrafficLightQuestion {
  final String id;
  final String textRu;
  final String textKk;
  final int order;
  final TrafficLightBlock block; // Блок вопроса (A, B, или C)

  TrafficLightQuestion({
    required this.id,
    required this.textRu,
    required this.textKk,
    required this.order,
    required this.block,
  });

  String getText(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final langCode = l10n.locale.languageCode;
    return langCode == 'kk' ? textKk : textRu;
  }

  factory TrafficLightQuestion.fromMap(Map<String, dynamic> map, String id) {
    return TrafficLightQuestion(
      id: id,
      textRu: map['textRu'] ?? map['text'] ?? '',
      textKk: map['textKk'] ?? map['text'] ?? '',
      order: map['order'] ?? 0,
      block: TrafficLightBlock.values.firstWhere(
        (e) => e.name == map['block'],
        orElse: () => TrafficLightBlock.energy,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'textRu': textRu,
      'textKk': textKk,
      'order': order,
      'block': block.name,
    };
  }
}

/// Блоки вопросов теста "Светофор"
enum TrafficLightBlock {
  energy,    // Блок А: Энергия и Смысл (PHQ-9)
  anxiety,   // Блок Б: Тревога и Навязчивые мысли (GAD-7)
  social,    // Блок В: Социальный статус и Будущее (Yale/Harvard)
}

/// Варианты ответа для теста "Светофор" (0-3 балла)
enum TrafficLightResponse {
  zero(0),
  one(1),
  two(2),
  three(3);

  final int score;

  const TrafficLightResponse(this.score);

  String getLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case TrafficLightResponse.zero:
        return l10n.get('trafficLightResponse0');
      case TrafficLightResponse.one:
        return l10n.get('trafficLightResponse1');
      case TrafficLightResponse.two:
        return l10n.get('trafficLightResponse2');
      case TrafficLightResponse.three:
        return l10n.get('trafficLightResponse3');
    }
  }
}

/// Стандартные вопросы теста "Светофор"
class TrafficLightQuestions {
  static List<TrafficLightQuestion> get questions => [
    // Блок А: Энергия и Смысл (База PHQ-9)
    TrafficLightQuestion(
      id: 'tl_a1',
      textRu: 'Твои батарейки: Как часто за последнюю неделю ты чувствовал, что у тебя совсем нет сил, даже если ты не перетруждался?',
      textKk: 'Сенің батареяларың: Соңғы аптада қаншалықты жиі сіз күш жетіспеушілігін сездіңіз, тіпті егер сіз асыра жұмыс істемеген болсаңыз?',
      order: 1,
      block: TrafficLightBlock.energy,
    ),
    TrafficLightQuestion(
      id: 'tl_a2',
      textRu: 'Интерес к «движу»: Было ли такое, что вещи, которые ты раньше обожал (игры, хобби, прогулки), вдруг стали казаться скучными или бессмысленными?',
      textKk: '«Қозғалысқа» қызығушылық: Бұрын сүйген нәрселеріңіз (ойындар, хобби, серуендер) кенеттен жалықтыратын немесе мағынасыз болып көрінді ме?',
      order: 2,
      block: TrafficLightBlock.energy,
    ),
    TrafficLightQuestion(
      id: 'tl_a3',
      textRu: 'Ощущение «невидимки»: Как часто тебе кажется, что тебя никто по-настоящему не понимает, даже если ты в компании?',
      textKk: '«Көрінбейтін» сезімі: Қаншалықты жиі сізге өзіңізді ешкім шынайы түсінбейді деп көрінеді, тіпті егер сіз компанияда болсаңыз?',
      order: 3,
      block: TrafficLightBlock.energy,
    ),

    // Блок Б: Тревога и «Навязчивые мысли» (База GAD-7)
    TrafficLightQuestion(
      id: 'tl_b1',
      textRu: 'Режим «Overthinking»: Часто ли ты ловишь себя на том, что мозг по кругу крутит плохие мысли, которые ты не можешь остановить?',
      textKk: '«Overthinking» режимі: Қаншалықты жиі сіз миыңыздың нашар ойларды тоқтата алмайтындығын байқайсыз?',
      order: 4,
      block: TrafficLightBlock.anxiety,
    ),
    TrafficLightQuestion(
      id: 'tl_b2',
      textRu: 'Ожидание подвоха: Чувствуешь ли ты внезапную тревогу, будто вот-вот случится что-то плохое, хотя причин для этого нет?',
      textKk: 'Айла-шарғы күту: Сіз кенеттен мазасыздық сезінесіз бе, сізге нашар нәрсе болатын сияқты, дегенмен бұл үшін себептер жоқ?',
      order: 5,
      block: TrafficLightBlock.anxiety,
    ),

    // Блок В: Социальный статус и Будущее (Методики Yale/Harvard)
    TrafficLightQuestion(
      id: 'tl_c1',
      textRu: 'Взгляд в «завтра»: Что ты чувствуешь, когда думаешь о своем будущем (школа, экзамены, жизнь)?',
      textKk: '«Ертеңге» қарау: Сіз өзіңіздің болашағыңыз туралы ойланғанда (мектеп, емтихандар, өмір) не сезінесіз?',
      order: 6,
      block: TrafficLightBlock.social,
    ),
    TrafficLightQuestion(
      id: 'tl_c2',
      textRu: 'Давление извне: Кажется ли тебе, что от тебя все постоянно чего-то требуют, и ты не справляешься с этим давлением?',
      textKk: 'Сырттан қысым: Сізге барлығы сізден үнемі бір нәрсені талап етіп, сіз бұл қысымға төзбейтініңіз көрінеді ме?',
      order: 7,
      block: TrafficLightBlock.social,
    ),
  ];
}

/// Результат теста "Светофор"
class TrafficLightResult {
  final int totalScore; // 0-21
  final Map<String, int> questionScores; // id вопроса -> балл
  final int blockAScore; // Блок А (энергия) - 0-9
  final int blockBScore; // Блок Б (тревога) - 0-6
  final int blockCScore; // Блок В (социальный) - 0-6
  final RiskLevel riskLevel;
  final DateTime completedAt;

  TrafficLightResult({
    required this.totalScore,
    required this.questionScores,
    required this.blockAScore,
    required this.blockBScore,
    required this.blockCScore,
    required this.riskLevel,
    required this.completedAt,
  });

  factory TrafficLightResult.fromMap(Map<String, dynamic> map) {
    return TrafficLightResult(
      totalScore: map['totalScore'] ?? 0,
      questionScores: Map<String, int>.from(map['questionScores'] ?? {}),
      blockAScore: map['blockAScore'] ?? 0,
      blockBScore: map['blockBScore'] ?? 0,
      blockCScore: map['blockCScore'] ?? 0,
      riskLevel: RiskLevel.values.firstWhere(
        (e) => e.name == map['riskLevel'],
        orElse: () => RiskLevel.green,
      ),
      completedAt: map['completedAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalScore': totalScore,
      'questionScores': questionScores,
      'blockAScore': blockAScore,
      'blockBScore': blockBScore,
      'blockCScore': blockCScore,
      'riskLevel': riskLevel.name,
      'completedAt': completedAt,
    };
  }

  /// Определить уровень риска по общему баллу
  static RiskLevel calculateRiskLevel(int totalScore) {
    if (totalScore <= 5) return RiskLevel.green;
    if (totalScore <= 12) return RiskLevel.yellow;
    return RiskLevel.red;
  }
}

