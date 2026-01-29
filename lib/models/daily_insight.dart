import 'survey_response.dart';

/// Ежедневный инсайт для родителя
class DailyInsight {
  final String id;
  final String teenId;
  final String parentId;
  final DateTime date;
  final RiskLevel overallRisk;
  final String aiSummary; // "Что это значит"
  final String aiAdvice;  // "Что сказать сегодня"
  final List<String> suggestedPhrases; // Конкретные фразы для разговора
  final bool isRead;
  final DateTime createdAt;

  DailyInsight({
    required this.id,
    required this.teenId,
    required this.parentId,
    required this.date,
    required this.overallRisk,
    required this.aiSummary,
    required this.aiAdvice,
    required this.suggestedPhrases,
    this.isRead = false,
    required this.createdAt,
  });

  factory DailyInsight.fromMap(Map<String, dynamic> map, String id) {
    return DailyInsight(
      id: id,
      teenId: map['teenId'] ?? '',
      parentId: map['parentId'] ?? '',
      date: map['date']?.toDate() ?? DateTime.now(),
      overallRisk: RiskLevel.values.firstWhere(
        (e) => e.name == map['overallRisk'],
        orElse: () => RiskLevel.green,
      ),
      aiSummary: map['aiSummary'] ?? '',
      aiAdvice: map['aiAdvice'] ?? '',
      suggestedPhrases: List<String>.from(map['suggestedPhrases'] ?? []),
      isRead: map['isRead'] ?? false,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teenId': teenId,
      'parentId': parentId,
      'date': date,
      'overallRisk': overallRisk.name,
      'aiSummary': aiSummary,
      'aiAdvice': aiAdvice,
      'suggestedPhrases': suggestedPhrases,
      'isRead': isRead,
      'createdAt': createdAt,
    };
  }
}

