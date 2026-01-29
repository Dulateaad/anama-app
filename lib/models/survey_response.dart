/// Модель ответа на вопрос опросника
class SurveyResponse {
  final String id;
  final String userId; // ID подростка
  final String questionId;
  final String questionText;
  final String answer;
  final DateTime answeredAt;
  final RiskLevel? aiRiskLevel; // Уровень риска, определенный AI
  final String? aiAnalysis; // Анализ от AI

  SurveyResponse({
    required this.id,
    required this.userId,
    required this.questionId,
    required this.questionText,
    required this.answer,
    required this.answeredAt,
    this.aiRiskLevel,
    this.aiAnalysis,
  });

  factory SurveyResponse.fromMap(Map<String, dynamic> map, String id) {
    return SurveyResponse(
      id: id,
      userId: map['userId'] ?? '',
      questionId: map['questionId'] ?? '',
      questionText: map['questionText'] ?? '',
      answer: map['answer'] ?? '',
      answeredAt: map['answeredAt']?.toDate() ?? DateTime.now(),
      aiRiskLevel: map['aiRiskLevel'] != null
          ? RiskLevel.values.firstWhere(
              (e) => e.name == map['aiRiskLevel'],
              orElse: () => RiskLevel.green,
            )
          : null,
      aiAnalysis: map['aiAnalysis'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'questionId': questionId,
      'questionText': questionText,
      'answer': answer,
      'answeredAt': answeredAt,
      'aiRiskLevel': aiRiskLevel?.name,
      'aiAnalysis': aiAnalysis,
    };
  }
}

/// Уровень риска (система светофора)
enum RiskLevel {
  green,  // 🟢 Всё стабильно
  yellow, // 🟡 Маркеры тревоги
  red,    // 🔴 Критический риск
}

/// Расширение для RiskLevel
extension RiskLevelExtension on RiskLevel {
  String get emoji {
    switch (this) {
      case RiskLevel.green:
        return '🟢';
      case RiskLevel.yellow:
        return '🟡';
      case RiskLevel.red:
        return '🔴';
    }
  }

  String get title {
    switch (this) {
      case RiskLevel.green:
        return 'Всё хорошо';
      case RiskLevel.yellow:
        return 'Требует внимания';
      case RiskLevel.red:
        return 'Критический уровень';
    }
  }

  String get description {
    switch (this) {
      case RiskLevel.green:
        return 'Ребенок чувствует себя услышанным и стабильным.';
      case RiskLevel.yellow:
        return 'Появились маркеры тревоги или скрытой агрессии.';
      case RiskLevel.red:
        return 'Критический риск. Высокий уровень стресса или деструктивных мыслей.';
    }
  }
}
