import 'package:flutter/material.dart';
import 'survey_response.dart';
import '../l10n/app_localizations.dart';

/// Модель вопроса GAD-7 (Generalized Anxiety Disorder-7)
/// Международный стандарт для оценки тревожности
class Gad7Question {
  final String id;
  final String textRu;
  final String textKk;
  final String textEn;
  final int order;
  
  Gad7Question({
    required this.id,
    required this.textRu,
    required this.textKk,
    required this.textEn,
    required this.order,
  });
  
  String getText(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final langCode = l10n.locale.languageCode;
    switch (langCode) {
      case 'kk': return textKk;
      case 'en': return textEn;
      default: return textRu;
    }
  }
  
  factory Gad7Question.fromMap(Map<String, dynamic> map, String id) {
    return Gad7Question(
      id: id,
      textRu: map['textRu'] ?? map['text'] ?? '',
      textKk: map['textKk'] ?? map['text'] ?? '',
      textEn: map['textEn'] ?? map['text'] ?? '',
      order: map['order'] ?? 0,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'textRu': textRu,
      'textKk': textKk,
      'textEn': textEn,
      'order': order,
    };
  }
}

/// Варианты ответа для GAD-7 (стандартная шкала)
enum Gad7Response {
  notAtAll(0),
  severalDays(1),
  moreThanHalf(2),
  nearlyEveryDay(3);
  
  final int score;
  
  const Gad7Response(this.score);
  
  String getLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case Gad7Response.notAtAll:
        return l10n.get('gad7ResponseNotAtAll');
      case Gad7Response.severalDays:
        return l10n.get('gad7ResponseSeveralDays');
      case Gad7Response.moreThanHalf:
        return l10n.get('gad7ResponseMoreThanHalf');
      case Gad7Response.nearlyEveryDay:
        return l10n.get('gad7ResponseNearlyEveryDay');
    }
  }
}

/// Стандартные вопросы GAD-7
class Gad7Questions {
  static List<Gad7Question> get questions => [
    Gad7Question(
      id: 'gad7_1',
      textRu: 'За последние 2 недели, как часто тебя беспокоило чувство нервозности, тревоги или напряжения?',
      textKk: 'Соңғы 2 аптада, сізді қаншалықты жиі нервоздық, мазасыздық немесе кернеу сезімі алаңдатады?',
      textEn: 'Over the last 2 weeks, how often have you been bothered by feeling nervous, anxious, or on edge?',
      order: 1,
    ),
    Gad7Question(
      id: 'gad7_2',
      textRu: 'За последние 2 недели, как часто тебя беспокоило то, что ты не мог(ла) остановить или контролировать беспокойство?',
      textKk: 'Соңғы 2 аптада, сізді қаншалықты жиі мазасыздықты тоқтата алмау немесе басқара алмау алаңдатады?',
      textEn: 'Over the last 2 weeks, how often have you been bothered by not being able to stop or control worrying?',
      order: 2,
    ),
    Gad7Question(
      id: 'gad7_3',
      textRu: 'За последние 2 недели, как часто тебя беспокоило чрезмерное беспокойство о разных вещах?',
      textKk: 'Соңғы 2 аптада, сізді қаншалықты жиі әртүрлі нәрселер туралы асыра мазасыздану алаңдатады?',
      textEn: 'Over the last 2 weeks, how often have you been bothered by worrying too much about different things?',
      order: 3,
    ),
    Gad7Question(
      id: 'gad7_4',
      textRu: 'За последние 2 недели, как часто тебе было трудно расслабиться?',
      textKk: 'Соңғы 2 аптада, сізге қаншалықты жиі тыныштандыру қиын болды?',
      textEn: 'Over the last 2 weeks, how often have you had trouble relaxing?',
      order: 4,
    ),
    Gad7Question(
      id: 'gad7_5',
      textRu: 'За последние 2 недели, как часто ты был(а) настолько беспокойным(ой), что тебе было трудно усидеть на месте?',
      textKk: 'Соңғы 2 аптада, сіз қаншалықты жиі отыра алмайтын дегендей мазасыз болдыңыз ба?',
      textEn: 'Over the last 2 weeks, how often have you been so restless that it is hard to sit still?',
      order: 5,
    ),
    Gad7Question(
      id: 'gad7_6',
      textRu: 'За последние 2 недели, как часто тебя беспокоила раздражительность или легкость возникновения злости?',
      textKk: 'Соңғы 2 аптада, сізді қаншалықты жиі ашуланшақтық немесе ашу тез пайда болуы алаңдатады?',
      textEn: 'Over the last 2 weeks, how often have you been bothered by becoming easily annoyed or irritable?',
      order: 6,
    ),
    Gad7Question(
      id: 'gad7_7',
      textRu: 'За последние 2 недели, как часто тебя беспокоило чувство страха, как будто должно произойти что-то ужасное?',
      textKk: 'Соңғы 2 аптада, сізді қаншалықты жиі қорқыныш сезімі, сізге қорқынышты нәрсе болатын сияқты, алаңдатады?',
      textEn: 'Over the last 2 weeks, how often have you been bothered by feeling afraid, as if something awful might happen?',
      order: 7,
    ),
  ];
}

/// Результат теста GAD-7
class Gad7Result {
  final int totalScore; // 0-21
  final Map<String, int> questionScores; // id вопроса -> балл
  final Gad7Severity severity;
  final DateTime completedAt;
  
  Gad7Result({
    required this.totalScore,
    required this.questionScores,
    required this.severity,
    required this.completedAt,
  });
  
  factory Gad7Result.fromMap(Map<String, dynamic> map) {
    return Gad7Result(
      totalScore: map['totalScore'] ?? 0,
      questionScores: Map<String, int>.from(map['questionScores'] ?? {}),
      severity: Gad7Severity.fromScore(map['totalScore'] ?? 0),
      completedAt: map['completedAt']?.toDate() ?? DateTime.now(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'totalScore': totalScore,
      'questionScores': questionScores,
      'severity': severity.name,
      'completedAt': completedAt,
    };
  }
}

/// Уровень тяжести тревожности по GAD-7
enum Gad7Severity {
  minimal(0, 4, '🟢'),
  mild(5, 9, '🟡'),
  moderate(10, 14, '🟠'),
  severe(15, 21, '🔴');
  
  final int minScore;
  final int maxScore;
  final String emoji;
  
  const Gad7Severity(this.minScore, this.maxScore, this.emoji);
  
  static Gad7Severity fromScore(int score) {
    if (score <= 4) return minimal;
    if (score <= 9) return mild;
    if (score <= 14) return moderate;
    return severe;
  }
  
  String getLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case Gad7Severity.minimal:
        return l10n.get('gad7SeverityMinimal');
      case Gad7Severity.mild:
        return l10n.get('gad7SeverityMild');
      case Gad7Severity.moderate:
        return l10n.get('gad7SeverityModerate');
      case Gad7Severity.severe:
        return l10n.get('gad7SeveritySevere');
    }
  }
  
  String getDescription(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final langCode = l10n.locale.languageCode;
    switch (this) {
      case Gad7Severity.minimal:
        switch (langCode) {
          case 'kk': return 'Тревожность белгілері жоқ немесе минималды.';
          case 'en': return 'Anxiety symptoms are absent or minimal.';
          default: return 'Симптомы тревожности отсутствуют или минимальны.';
        }
      case Gad7Severity.mild:
        switch (langCode) {
          case 'kk': return 'Жеңіл тревожность белгілері. Бақылау және тыныштандыру әдістері ұсынылады.';
          case 'en': return 'Mild anxiety symptoms. Monitoring and relaxation techniques recommended.';
          default: return 'Легкие симптомы тревожности. Рекомендуется наблюдение и техники релаксации.';
        }
      case Gad7Severity.moderate:
        switch (langCode) {
          case 'kk': return 'Орташа тревожность белгілері. Мамандық кеңесі ұсынылады.';
          case 'en': return 'Moderate anxiety symptoms. Professional consultation recommended.';
          default: return 'Умеренные симптомы тревожности. Рекомендуется консультация специалиста.';
        }
      case Gad7Severity.severe:
        switch (langCode) {
          case 'kk': return 'Ауыр тревожность белгілері. Дереу мамандық кеңесі қажет.';
          case 'en': return 'Severe anxiety symptoms. Immediate professional consultation required.';
          default: return 'Тяжелые симптомы тревожности. Требуется немедленная консультация специалиста.';
        }
    }
  }
  
  RiskLevel get riskLevel {
    switch (this) {
      case Gad7Severity.minimal:
        return RiskLevel.green;
      case Gad7Severity.mild:
        return RiskLevel.yellow;
      case Gad7Severity.moderate:
      case Gad7Severity.severe:
        return RiskLevel.red;
    }
  }
}

