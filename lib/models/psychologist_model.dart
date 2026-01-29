import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель психолога
class Psychologist {
  final String uid; // ID пользователя
  final String fullName; // Полное имя
  final String? email;
  final String? phone;
  final String qualification; // Квалификация (диплом, сертификаты)
  final String specialization; // Специализация (например: "Работа с подростками", "Семейная терапия")
  final List<String> certificates; // Список сертификатов (ссылки или названия)
  final String? bio; // Краткая биография
  final String? photoUrl; // Фото психолога
  final int experienceYears; // Опыт работы (лет)
  final bool isVerified; // Верифицирован ли психолог (администратором)
  final DateTime createdAt;
  final DateTime updatedAt;

  Psychologist({
    required this.uid,
    required this.fullName,
    this.email,
    this.phone,
    required this.qualification,
    required this.specialization,
    this.certificates = const [],
    this.bio,
    this.photoUrl,
    this.experienceYears = 0,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Psychologist.fromMap(Map<String, dynamic> map, String uid) {
    return Psychologist(
      uid: uid,
      fullName: map['fullName'] ?? '',
      email: map['email'],
      phone: map['phone'],
      qualification: map['qualification'] ?? '',
      specialization: map['specialization'] ?? '',
      certificates: List<String>.from(map['certificates'] ?? []),
      bio: map['bio'],
      photoUrl: map['photoUrl'],
      experienceYears: map['experienceYears'] ?? 0,
      isVerified: map['isVerified'] ?? false,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'qualification': qualification,
      'specialization': specialization,
      'certificates': certificates,
      'bio': bio,
      'photoUrl': photoUrl,
      'experienceYears': experienceYears,
      'isVerified': isVerified,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Psychologist copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? phone,
    String? qualification,
    String? specialization,
    List<String>? certificates,
    String? bio,
    String? photoUrl,
    int? experienceYears,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Psychologist(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      qualification: qualification ?? this.qualification,
      specialization: specialization ?? this.specialization,
      certificates: certificates ?? this.certificates,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      experienceYears: experienceYears ?? this.experienceYears,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

