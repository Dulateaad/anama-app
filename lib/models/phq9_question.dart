import 'package:flutter/material.dart';
import 'survey_response.dart';
import '../l10n/app_localizations.dart';

/// Модель вопроса PHQ-9 (Patient Health Questionnaire-9)
/// Международный стандарт для оценки депрессии
class Phq9Question {
  final String id;
  final String textRu;
  final String textKk;
  final int order;
  
  Phq9Question({
    required this.id,
    required this.textRu,
    required this.textKk,
    required this.order,
  });
  
  String getText(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final langCode = l10n.locale.languageCode;
    return langCode == 'kk' ? textKk : textRu;
  }
  
  factory Phq9Question.fromMap(Map<String, dynamic> map, String id) {
    return Phq9Question(
      id: id,
      textRu: map['textRu'] ?? map['text'] ?? '',
      textKk: map['textKk'] ?? map['text'] ?? '',
      order: map['order'] ?? 0,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'textRu': textRu,
      'textKk': textKk,
      'order': order,
    };
  }
}

/// Варианты ответа для PHQ-9 (стандартная шкала)
enum Phq9Response {
  notAtAll(0),
  severalDays(1),
  moreThanHalf(2),
  nearlyEveryDay(3);
  
  final int score;
  
  const Phq9Response(this.score);
  
  String getLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case Phq9Response.notAtAll:
        return l10n.get('phq9ResponseNotAtAll');
      case Phq9Response.severalDays:
        return l10n.get('phq9ResponseSeveralDays');
      case Phq9Response.moreThanHalf:
        return l10n.get('phq9ResponseMoreThanHalf');
      case Phq9Response.nearlyEveryDay:
        return l10n.get('phq9ResponseNearlyEveryDay');
    }
  }
}

/// Стандартные вопросы PHQ-9
class Phq9Questions {
  static List<Phq9Question> get questions => [
    Phq9Question(
      id: 'phq9_1',
      textRu: 'За последние 2 недели, как часто тебя беспокоило плохое настроение, подавленность или безнадежность?',
      textKk: 'Соңғы 2 аптада, сізді қаншалықты жиі нашар көңіл-күй, басып кету немесе үмітсіздік алаңдатады?',
      order: 1,
    ),
    Phq9Question(
      id: 'phq9_2',
      textRu: 'За последние 2 недели, как часто тебя беспокоило отсутствие интереса или удовольствия от того, чем ты обычно занимаешься?',
      textKk: 'Соңғы 2 аптада, сізді қаншалықты жиі әдеттегі іс-әрекеттеріңізге қызығушылық немесе қуаныш жоқтығы алаңдатады?',
      order: 2,
    ),
    Phq9Question(
      id: 'phq9_3',
      textRu: 'За последние 2 недели, как часто у тебя были проблемы с засыпанием или сном (слишком долгий сон или беспокойный сон)?',
      textKk: 'Соңғы 2 аптада, сізді қаншалықты жиі ұйықтауда немесе ұйқыда (тым ұзақ ұйықтау немесе тынышсыз ұйқы) мәселелер алаңдатады?',
      order: 3,
    ),
    Phq9Question(
      id: 'phq9_4',
      textRu: 'За последние 2 недели, как часто ты чувствовал(а) усталость или нехватку энергии?',
      textKk: 'Соңғы 2 аптада, сізді қаншалықты жиі шаршау немесе энергия жетіспеушілігі сезімі алаңдатады?',
      order: 4,
    ),
    Phq9Question(
      id: 'phq9_5',
      textRu: 'За последние 2 недели, как часто у тебя был плохой аппетит или ты переедал(а)?',
      textKk: 'Соңғы 2 аптада, сізді қаншалықты жиі нашар тамақтану немесе асыра тамақтану алаңдатады?',
      order: 5,
    ),
    Phq9Question(
      id: 'phq9_6',
      textRu: 'За последние 2 недели, как часто ты чувствовал(а) себя плохо из-за того, что ты плохой человек, или что ты подвел(а) себя или свою семью?',
      textKk: 'Соңғы 2 аптада, сізді қаншалықты жиі өзіңізді нашар адам деп сезіну немесе өзіңізді немесе отбасыңызды алдағаныңыз сезімі алаңдатады?',
      order: 6,
    ),
    Phq9Question(
      id: 'phq9_7',
      textRu: 'За последние 2 недели, как часто у тебя были проблемы с концентрацией внимания (например, при чтении или просмотре телевизора)?',
      textKk: 'Соңғы 2 аптада, сізді қаншалықты жиі назар аудару мәселелері (мысалы, оқу немесе теледидар көру кезінде) алаңдатады?',
      order: 7,
    ),
    Phq9Question(
      id: 'phq9_8',
      textRu: 'За последние 2 недели, двигался ли ты или говорил так медленно, что другие могли это заметить? Или наоборот — был настолько беспокойным или суетливым, что двигался намного больше обычного?',
      textKk: 'Соңғы 2 аптада, сіз басқалар байқауы мүмкін дегендей баяу қозғалдыңыз немесе сөйледіңіз бе? Немесе керісінше — сіз әдеттегіден әлдеқайда көп қозғалатын қиналған немесе алаңдаушы болдыңыз ба?',
      order: 8,
    ),
    Phq9Question(
      id: 'phq9_9',
      textRu: 'За последние 2 недели, возникали ли у тебя мысли о том, что лучше было бы умереть, или о причинении себе вреда?',
      textKk: 'Соңғы 2 аптада, сізде өлу немесе өзіңізге зиян келтіру туралы ойлар пайда болды ма?',
      order: 9,
    ),
  ];
}

/// Результат теста PHQ-9
class Phq9Result {
  final int totalScore; // 0-27
  final Map<String, int> questionScores; // id вопроса -> балл
  final Phq9Severity severity;
  final DateTime completedAt;
  
  Phq9Result({
    required this.totalScore,
    required this.questionScores,
    required this.severity,
    required this.completedAt,
  });
  
  factory Phq9Result.fromMap(Map<String, dynamic> map) {
    return Phq9Result(
      totalScore: map['totalScore'] ?? 0,
      questionScores: Map<String, int>.from(map['questionScores'] ?? {}),
      severity: Phq9Severity.fromScore(map['totalScore'] ?? 0),
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

/// Уровень тяжести депрессии по PHQ-9
enum Phq9Severity {
  minimal(0, 4, '🟢'),
  mild(5, 9, '🟡'),
  moderate(10, 14, '🟠'),
  moderatelySevere(15, 19, '🟠'),
  severe(20, 27, '🔴');
  
  final int minScore;
  final int maxScore;
  final String emoji;
  
  const Phq9Severity(this.minScore, this.maxScore, this.emoji);
  
  static Phq9Severity fromScore(int score) {
    if (score <= 4) return minimal;
    if (score <= 9) return mild;
    if (score <= 14) return moderate;
    if (score <= 19) return moderatelySevere;
    return severe;
  }
  
  String getLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case Phq9Severity.minimal:
        return l10n.get('phq9SeverityMinimal');
      case Phq9Severity.mild:
        return l10n.get('phq9SeverityMild');
      case Phq9Severity.moderate:
        return l10n.get('phq9SeverityModerate');
      case Phq9Severity.moderatelySevere:
        return l10n.get('phq9SeverityModeratelySevere');
      case Phq9Severity.severe:
        return l10n.get('phq9SeveritySevere');
    }
  }
  
  String getDescription(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final langCode = l10n.locale.languageCode;
    switch (this) {
      case Phq9Severity.minimal:
        return langCode == 'kk' 
          ? 'Депрессия белгілері жоқ немесе минималды.'
          : 'Симптомы депрессии отсутствуют или минимальны.';
      case Phq9Severity.mild:
        return langCode == 'kk'
          ? 'Жеңіл депрессия белгілері. Бақылау және қолдау ұсынылады.'
          : 'Легкие симптомы депрессии. Рекомендуется наблюдение и поддержка.';
      case Phq9Severity.moderate:
        return langCode == 'kk'
          ? 'Орташа депрессия белгілері. Мамандық кеңесі ұсынылады.'
          : 'Умеренные симптомы депрессии. Рекомендуется консультация специалиста.';
      case Phq9Severity.moderatelySevere:
        return langCode == 'kk'
          ? 'Орташа-ауыр депрессия белгілері. Мамандық кеңесі қажет.'
          : 'Умеренно-тяжелые симптомы депрессии. Необходима консультация специалиста.';
      case Phq9Severity.severe:
        return langCode == 'kk'
          ? 'Ауыр депрессия белгілері. Дереу мамандық кеңесі қажет.'
          : 'Тяжелые симптомы депрессии. Требуется немедленная консультация специалиста.';
    }
  }
  
  RiskLevel get riskLevel {
    switch (this) {
      case Phq9Severity.minimal:
        return RiskLevel.green;
      case Phq9Severity.mild:
        return RiskLevel.yellow;
      case Phq9Severity.moderate:
      case Phq9Severity.moderatelySevere:
      case Phq9Severity.severe:
        return RiskLevel.red;
    }
  }
}

