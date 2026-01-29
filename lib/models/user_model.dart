import 'dart:math';

/// Модель пользователя Anama
class AnamaUser {
  final String uid;
  final String visitorId; // Псевдоним для AI (не передаём uid в Gemini)
  final String? email; // Nullable для анонимных подростков
  final String? displayName;
  final UserRole role;
  final DateTime? birthDate; // Дата рождения для определения возраста
  final AgeCategory ageCategory; // Категория возраста
  final String? linkedUserId; // ID связанного пользователя (ребенок <-> родитель)
  final String? uniqueCode; // Уникальный код для связки аккаунтов
  final bool isAnonymous; // Анонимный вход (для подростков без email)
  final bool parentalConsentGiven; // Дано ли родительское согласие
  final DateTime? parentalConsentDate; // Дата согласия
  final Gender? gender; // Пол пользователя (для подростков - выбор темы)
  final DateTime createdAt;
  final DateTime updatedAt;

  AnamaUser({
    required this.uid,
    String? visitorId,
    this.email,
    this.displayName,
    required this.role,
    this.birthDate,
    this.ageCategory = AgeCategory.unknown,
    this.linkedUserId,
    this.uniqueCode,
    this.isAnonymous = false,
    this.parentalConsentGiven = false,
    this.parentalConsentDate,
    this.gender,
    required this.createdAt,
    required this.updatedAt,
  }) : visitorId = visitorId ?? _generateVisitorId();

  /// Генерация анонимного ID для AI
  static String _generateVisitorId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return 'V${List.generate(8, (_) => chars[random.nextInt(chars.length)]).join()}';
  }

  factory AnamaUser.fromMap(Map<String, dynamic> map, String uid) {
    return AnamaUser(
      uid: uid,
      visitorId: map['visitorId'] ?? _generateVisitorId(),
      email: map['email'],
      displayName: map['displayName'],
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.teen,
      ),
      birthDate: map['birthDate']?.toDate(),
      ageCategory: AgeCategory.values.firstWhere(
        (e) => e.name == map['ageCategory'],
        orElse: () => AgeCategory.unknown,
      ),
      linkedUserId: map['linkedUserId'],
      uniqueCode: map['uniqueCode'],
      isAnonymous: map['isAnonymous'] ?? false,
      parentalConsentGiven: map['parentalConsentGiven'] ?? false,
      parentalConsentDate: map['parentalConsentDate']?.toDate(),
      gender: map['gender'] != null 
          ? Gender.values.firstWhere(
              (e) => e.name == map['gender'],
              orElse: () => Gender.other,
            )
          : null,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'visitorId': visitorId,
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'birthDate': birthDate,
      'ageCategory': ageCategory.name,
      'linkedUserId': linkedUserId,
      'uniqueCode': uniqueCode,
      'isAnonymous': isAnonymous,
      'parentalConsentGiven': parentalConsentGiven,
      'parentalConsentDate': parentalConsentDate,
      'gender': gender?.name,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  AnamaUser copyWith({
    String? uid,
    String? visitorId,
    String? email,
    String? displayName,
    UserRole? role,
    DateTime? birthDate,
    AgeCategory? ageCategory,
    String? linkedUserId,
    String? uniqueCode,
    bool? isAnonymous,
    bool? parentalConsentGiven,
    DateTime? parentalConsentDate,
    Gender? gender,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AnamaUser(
      uid: uid ?? this.uid,
      visitorId: visitorId ?? this.visitorId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      birthDate: birthDate ?? this.birthDate,
      ageCategory: ageCategory ?? this.ageCategory,
      linkedUserId: linkedUserId ?? this.linkedUserId,
      uniqueCode: uniqueCode ?? this.uniqueCode,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      parentalConsentGiven: parentalConsentGiven ?? this.parentalConsentGiven,
      parentalConsentDate: parentalConsentDate ?? this.parentalConsentDate,
      gender: gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Роль пользователя
enum UserRole {
  teen,        // Подросток
  parent,      // Родитель
  psychologist, // Психолог
}

/// Категория возраста (для GDPR/compliance)
enum AgeCategory {
  child,    // До 13 лет
  teen,     // 13-17 лет
  adult,    // 18+ лет
  unknown,  // Возраст неизвестен
}

/// Пол пользователя (для выбора темы)
enum Gender {
  male,     // Мальчик
  female,   // Девочка
  other,    // Другое
}
