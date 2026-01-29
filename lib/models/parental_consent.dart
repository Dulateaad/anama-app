/// Модель родительского согласия (GDPR compliance)
/// Согласно требованиям: доказуемый факт согласия
class ParentalConsent {
  final String id;
  final String parentId;      // ID родителя, давшего согласие
  final String childId;       // ID ребёнка
  final String consentVersion; // Версия условий (Terms v1.0)
  final DateTime consentDate;  // Дата и время согласия
  final String consentMethod;  // Способ согласия (app, sms, email_otp)
  final String? ipAddress;     // IP при согласии (опционально)
  final String? deviceInfo;    // Информация об устройстве
  final bool isActive;         // Активно ли согласие
  final DateTime? revokedAt;   // Дата отзыва (если отозвано)
  // Новые поля для подтверждения возраста и ответственности
  final int childAge;         // Возраст ребенка (указанный ребенком)
  final bool ageConfirmed;    // Подтвердил ли родитель возраст ребенка
  final bool responsibilityAccepted; // Принял ли родитель ответственность
  final String parentEmail;   // Email родителя для подтверждения
  final String parentPhone;   // Телефон родителя

  ParentalConsent({
    required this.id,
    required this.parentId,
    required this.childId,
    required this.consentVersion,
    required this.consentDate,
    required this.consentMethod,
    this.ipAddress,
    this.deviceInfo,
    this.isActive = true,
    this.revokedAt,
    required this.childAge,
    this.ageConfirmed = false,
    this.responsibilityAccepted = false,
    required this.parentEmail,
    required this.parentPhone,
  });

  factory ParentalConsent.fromMap(Map<String, dynamic> map, String id) {
    return ParentalConsent(
      id: id,
      parentId: map['parentId'] ?? '',
      childId: map['childId'] ?? '',
      consentVersion: map['consentVersion'] ?? '1.0',
      consentDate: map['consentDate']?.toDate() ?? DateTime.now(),
      consentMethod: map['consentMethod'] ?? 'email_otp',
      ipAddress: map['ipAddress'],
      deviceInfo: map['deviceInfo'],
      isActive: map['isActive'] ?? true,
      revokedAt: map['revokedAt']?.toDate(),
      childAge: map['childAge'] ?? 0,
      ageConfirmed: map['ageConfirmed'] ?? false,
      responsibilityAccepted: map['responsibilityAccepted'] ?? false,
      parentEmail: map['parentEmail'] ?? '',
      parentPhone: map['parentPhone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'parentId': parentId,
      'childId': childId,
      'consentVersion': consentVersion,
      'consentDate': consentDate,
      'consentMethod': consentMethod,
      'ipAddress': ipAddress,
      'deviceInfo': deviceInfo,
      'isActive': isActive,
      'revokedAt': revokedAt,
      'childAge': childAge,
      'ageConfirmed': ageConfirmed,
      'responsibilityAccepted': responsibilityAccepted,
      'parentEmail': parentEmail,
      'parentPhone': parentPhone,
    };
  }
}

/// Типы согласий для реестра
enum ConsentType {
  dataProcessing,   // Обработка персональных данных
  aiAnalysis,       // Анализ через AI
  pushNotifications,// Push-уведомления
  analytics,        // Аналитика
  thirdPartySharing,// Передача третьим лицам
}

/// Запись в реестре согласий
class ConsentRecord {
  final String id;
  final String visitorId;      // Анонимный ID
  final ConsentType type;
  final bool granted;
  final String version;
  final DateTime timestamp;

  ConsentRecord({
    required this.id,
    required this.visitorId,
    required this.type,
    required this.granted,
    required this.version,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'visitorId': visitorId,
      'type': type.name,
      'granted': granted,
      'version': version,
      'timestamp': timestamp,
    };
  }
}

