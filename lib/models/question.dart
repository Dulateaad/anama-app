import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Модель вопроса для опросника
class SurveyQuestion {
  final String id;
  final String textRu;
  final String textKk;
  final String textEn;
  final QuestionCategory category;
  final List<String>? optionsRu;
  final List<String>? optionsKk;
  final List<String>? optionsEn;
  final bool isOpenEnded;
  final int order;

  SurveyQuestion({
    required this.id,
    required this.textRu,
    required this.textKk,
    required this.textEn,
    required this.category,
    this.optionsRu,
    this.optionsKk,
    this.optionsEn,
    this.isOpenEnded = false,
    required this.order,
  });

  // Backwards compatibility getter
  String get text => textRu;
  List<String>? get options => optionsRu;

  String getText(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final langCode = l10n.locale.languageCode;
    switch (langCode) {
      case 'kk': return textKk;
      case 'en': return textEn;
      default: return textRu;
    }
  }

  List<String>? getOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final langCode = l10n.locale.languageCode;
    switch (langCode) {
      case 'kk': return optionsKk;
      case 'en': return optionsEn;
      default: return optionsRu;
    }
  }

  factory SurveyQuestion.fromMap(Map<String, dynamic> map, String id) {
    return SurveyQuestion(
      id: id,
      textRu: map['textRu'] ?? map['text'] ?? '',
      textKk: map['textKk'] ?? map['text'] ?? '',
      textEn: map['textEn'] ?? map['text'] ?? '',
      category: QuestionCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => QuestionCategory.general,
      ),
      optionsRu: map['optionsRu'] != null ? List<String>.from(map['optionsRu']) : (map['options'] != null ? List<String>.from(map['options']) : null),
      optionsKk: map['optionsKk'] != null ? List<String>.from(map['optionsKk']) : null,
      optionsEn: map['optionsEn'] != null ? List<String>.from(map['optionsEn']) : null,
      isOpenEnded: map['isOpenEnded'] ?? false,
      order: map['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'textRu': textRu,
      'textKk': textKk,
      'textEn': textEn,
      'category': category.name,
      'optionsRu': optionsRu,
      'optionsKk': optionsKk,
      'optionsEn': optionsEn,
      'isOpenEnded': isOpenEnded,
      'order': order,
    };
  }
}

/// Категории вопросов
enum QuestionCategory {
  general,        // Общее состояние
  meaningOfLife,  // Смысл жизни
  loneliness,     // Чувство одиночества
  selfIdentity,   // Самоидентификация
  relationships,  // Отношения
  future,         // Будущее
}

/// Предустановленные вопросы
class DefaultQuestions {
  static List<SurveyQuestion> get dailyQuestions => [
    SurveyQuestion(
      id: 'q1',
      textRu: 'Как ты себя чувствуешь сегодня?',
      textKk: 'Бүгін өзіңді қалай сезінесің?',
      textEn: 'How are you feeling today?',
      category: QuestionCategory.general,
      optionsRu: ['Отлично 😊', 'Нормально 😐', 'Не очень 😔', 'Плохо 😢'],
      optionsKk: ['Тамаша 😊', 'Қалыпты 😐', 'Жақсы емес 😔', 'Нашар 😢'],
      optionsEn: ['Great 😊', 'Normal 😐', 'Not great 😔', 'Bad 😢'],
      order: 1,
    ),
    SurveyQuestion(
      id: 'q2',
      textRu: 'Было ли сегодня что-то, что тебя порадовало?',
      textKk: 'Бүгін сені қуантқан нәрсе болды ма?',
      textEn: 'Was there anything that made you happy today?',
      category: QuestionCategory.general,
      isOpenEnded: true,
      order: 2,
    ),
    SurveyQuestion(
      id: 'q3',
      textRu: 'Чувствуешь ли ты, что тебя понимают близкие?',
      textKk: 'Жақындарың сені түсінеді деп сезінесің бе?',
      textEn: 'Do you feel understood by your loved ones?',
      category: QuestionCategory.loneliness,
      optionsRu: ['Да, полностью', 'Иногда', 'Редко', 'Нет, совсем не понимают'],
      optionsKk: ['Иә, толығымен', 'Кейде', 'Сирек', 'Жоқ, мүлдем түсінбейді'],
      optionsEn: ['Yes, completely', 'Sometimes', 'Rarely', 'No, not at all'],
      order: 3,
    ),
    SurveyQuestion(
      id: 'q4',
      textRu: 'Есть ли у тебя цели или мечты, к которым ты стремишься?',
      textKk: 'Сенің арманың немесе мақсаттарың бар ма?',
      textEn: 'Do you have goals or dreams you\'re working towards?',
      category: QuestionCategory.meaningOfLife,
      optionsRu: ['Да, много!', 'Есть несколько', 'Не уверен(а)', 'Нет, не вижу смысла'],
      optionsKk: ['Иә, көп!', 'Бірнеше бар', 'Сенімді емеспін', 'Жоқ, мәні жоқ'],
      optionsEn: ['Yes, many!', 'A few', 'Not sure', 'No, I don\'t see the point'],
      order: 4,
    ),
    SurveyQuestion(
      id: 'q5',
      textRu: 'Что бы ты хотел(а) изменить в своей жизни прямо сейчас?',
      textKk: 'Өміріңде қазір нені өзгерткің келеді?',
      textEn: 'What would you like to change in your life right now?',
      category: QuestionCategory.selfIdentity,
      isOpenEnded: true,
      order: 5,
    ),
    SurveyQuestion(
      id: 'q6',
      textRu: 'Как ты оцениваешь свои отношения с друзьями?',
      textKk: 'Достарыңмен қарым-қатынасыңды қалай бағалайсың?',
      textEn: 'How would you rate your relationships with friends?',
      category: QuestionCategory.relationships,
      optionsRu: ['Отличные', 'Хорошие', 'Сложные', 'У меня нет друзей'],
      optionsKk: ['Тамаша', 'Жақсы', 'Күрделі', 'Достарым жоқ'],
      optionsEn: ['Excellent', 'Good', 'Complicated', 'I have no friends'],
      order: 6,
    ),
    SurveyQuestion(
      id: 'q7',
      textRu: 'Если бы ты мог(ла) сказать что-то важное, что бы это было?',
      textKk: 'Маңызды нәрсе айтсаң, ол не болар еді?',
      textEn: 'If you could say something important, what would it be?',
      category: QuestionCategory.general,
      isOpenEnded: true,
      order: 7,
    ),
  ];
}

