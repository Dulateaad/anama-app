/// Модель вопроса для опросника
class SurveyQuestion {
  final String id;
  final String text;
  final QuestionCategory category;
  final List<String>? options; // Варианты ответа (если есть)
  final bool isOpenEnded; // Открытый вопрос (свободный ответ)
  final int order;

  SurveyQuestion({
    required this.id,
    required this.text,
    required this.category,
    this.options,
    this.isOpenEnded = false,
    required this.order,
  });

  factory SurveyQuestion.fromMap(Map<String, dynamic> map, String id) {
    return SurveyQuestion(
      id: id,
      text: map['text'] ?? '',
      category: QuestionCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => QuestionCategory.general,
      ),
      options: map['options'] != null ? List<String>.from(map['options']) : null,
      isOpenEnded: map['isOpenEnded'] ?? false,
      order: map['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'category': category.name,
      'options': options,
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
      text: 'Как ты себя чувствуешь сегодня?',
      category: QuestionCategory.general,
      options: ['Отлично 😊', 'Нормально 😐', 'Не очень 😔', 'Плохо 😢'],
      order: 1,
    ),
    SurveyQuestion(
      id: 'q2',
      text: 'Было ли сегодня что-то, что тебя порадовало?',
      category: QuestionCategory.general,
      isOpenEnded: true,
      order: 2,
    ),
    SurveyQuestion(
      id: 'q3',
      text: 'Чувствуешь ли ты, что тебя понимают близкие?',
      category: QuestionCategory.loneliness,
      options: ['Да, полностью', 'Иногда', 'Редко', 'Нет, совсем не понимают'],
      order: 3,
    ),
    SurveyQuestion(
      id: 'q4',
      text: 'Есть ли у тебя цели или мечты, к которым ты стремишься?',
      category: QuestionCategory.meaningOfLife,
      options: ['Да, много!', 'Есть несколько', 'Не уверен(а)', 'Нет, не вижу смысла'],
      order: 4,
    ),
    SurveyQuestion(
      id: 'q5',
      text: 'Что бы ты хотел(а) изменить в своей жизни прямо сейчас?',
      category: QuestionCategory.selfIdentity,
      isOpenEnded: true,
      order: 5,
    ),
    SurveyQuestion(
      id: 'q6',
      text: 'Как ты оцениваешь свои отношения с друзьями?',
      category: QuestionCategory.relationships,
      options: ['Отличные', 'Хорошие', 'Сложные', 'У меня нет друзей'],
      order: 6,
    ),
    SurveyQuestion(
      id: 'q7',
      text: 'Если бы ты мог(ла) сказать что-то важное, что бы это было?',
      category: QuestionCategory.general,
      isOpenEnded: true,
      order: 7,
    ),
  ];
}

