import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/parental_consent.dart';

/// Сервис для работы с родительскими согласиями
class ParentalConsentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Отправка OTP на телефон родителя
  Future<bool> sendOtpToPhone(String phone) async {
    try {
      // Генерируем 6-значный код
      final otp = _generateOtp();
      
      // Нормализуем номер телефона (убираем все кроме цифр)
      final normalizedPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
      
      // Сохраняем OTP во временную коллекцию (с TTL)
      await _firestore
          .collection('parental_consent_otps')
          .doc(normalizedPhone)
          .set({
        'otp': otp,
        'phone': normalizedPhone,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 10)),
        ),
      });

      // Отправляем SMS через Firebase Function
      try {
        final functionUrl = 'https://us-central1-anama-app.cloudfunctions.net/sendParentalConsentOtp';
        
        final response = await http.post(
          Uri.parse(functionUrl),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'phone': normalizedPhone,
            'otp': otp,
            'language': 'ru', // Можно определить язык из настроек пользователя
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          print('✅ OTP SMS отправлен на $normalizedPhone');
          return true;
        } else {
          print('❌ Ошибка отправки SMS: ${response.statusCode}');
          print('Response: ${response.body}');
          // Не возвращаем false, так как OTP сохранен в Firestore
          return true; // OTP сохранен, SMS может быть отправлен позже
        }
      } catch (e) {
        print('⚠️ Ошибка отправки SMS через Firebase Function: $e');
        // OTP сохранен в Firestore, можно попробовать отправить позже
        return true;
      }
    } catch (e) {
      print('❌ Ошибка отправки OTP: $e');
      return false;
    }
  }

  /// Отправка OTP на email родителя (deprecated - используйте sendOtpToPhone)
  @Deprecated('Используйте sendOtpToPhone')
  Future<bool> sendOtpToEmail(String email) async {
    try {
      // Генерируем 6-значный код
      final otp = _generateOtp();
      
      // Сохраняем OTP во временную коллекцию (с TTL)
      await _firestore
          .collection('parental_consent_otps')
          .doc(email)
          .set({
        'otp': otp,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 10)),
        ),
      });

      // Отправляем email через Firebase Function
      try {
        final functionUrl = 'https://us-central1-anama-app.cloudfunctions.net/sendParentalConsentOtp';
        
        final response = await http.post(
          Uri.parse(functionUrl),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'email': email,
            'otp': otp,
            'language': 'ru', // Можно определить язык из настроек пользователя
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          print('✅ OTP email отправлен на $email');
          return true;
        } else {
          print('❌ Ошибка отправки email: ${response.statusCode}');
          print('Response: ${response.body}');
          // Не возвращаем false, так как OTP сохранен в Firestore
          return true; // OTP сохранен, email может быть отправлен позже
        }
      } catch (e) {
        print('⚠️ Ошибка отправки email через Firebase Function: $e');
        // OTP сохранен в Firestore, можно попробовать отправить позже
        return true;
      }
    } catch (e) {
      print('❌ Ошибка отправки OTP: $e');
      return false;
    }
  }

  /// Проверка OTP (работает с телефоном или email для обратной совместимости)
  Future<bool> verifyOtp(String phoneOrEmail, String otp) async {
    try {
      // Нормализуем номер телефона (убираем все кроме цифр)
      final normalized = phoneOrEmail.replaceAll(RegExp(r'[^\d]'), '');
      
      final doc = await _firestore
          .collection('parental_consent_otps')
          .doc(normalized)
          .get();

      if (!doc.exists) {
        return false;
      }

      final data = doc.data()!;
      final storedOtp = data['otp'] as String;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();

      // Проверяем срок действия
      if (DateTime.now().isAfter(expiresAt)) {
        await doc.reference.delete();
        return false;
      }

      // Проверяем код
      if (storedOtp == otp) {
        // Удаляем использованный OTP
        await doc.reference.delete();
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Ошибка проверки OTP: $e');
      return false;
    }
  }

  /// Создание родительского согласия
  Future<ParentalConsent?> createParentalConsent({
    required String childId,
    String? parentEmail, // Опционально, так как теперь используем только телефон
    required String parentPhone,
    required String consentMethod,
    required int childAge,
    required bool ageConfirmed,
    required bool responsibilityAccepted,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Находим родителя по email (или создаем временный ID)
      String parentId = 'temp_parent_${DateTime.now().millisecondsSinceEpoch}';
      
      // Пытаемся найти родителя по email
      final parentQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: parentEmail)
          .where('role', isEqualTo: 'parent')
          .limit(1)
          .get();
      
      if (parentQuery.docs.isNotEmpty) {
        parentId = parentQuery.docs.first.id;
      }

      final consentId = _firestore.collection('parental_consents').doc().id;

      final consent = ParentalConsent(
        id: consentId,
        parentId: parentId,
        childId: childId,
        consentVersion: '1.0',
        consentDate: DateTime.now(),
        consentMethod: consentMethod,
        childAge: childAge,
        ageConfirmed: ageConfirmed,
        responsibilityAccepted: responsibilityAccepted,
        parentEmail: parentEmail ?? '', // Может быть пустым, так как используем телефон
        parentPhone: parentPhone,
        ipAddress: metadata?['ip'],
        deviceInfo: metadata?['userAgent'],
        isActive: true,
      );

      await _firestore
          .collection('parental_consents')
          .doc(consentId)
          .set(consent.toMap());

      // Обновляем профиль ребенка - отмечаем, что согласие дано
      await _firestore.collection('users').doc(childId).update({
        'parentalConsentGiven': true,
        'parentalConsentDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Родительское согласие создано: $consentId');
      return consent;
    } catch (e) {
      print('❌ Ошибка создания согласия: $e');
      return null;
    }
  }

  /// Получение активного согласия для пользователя
  Future<ParentalConsent?> getActiveConsent(String childId) async {
    try {
      final querySnapshot = await _firestore
          .collection('parental_consents')
          .where('childId', isEqualTo: childId)
          .where('isActive', isEqualTo: true)
          .orderBy('consentDate', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return ParentalConsent.fromMap(
        querySnapshot.docs.first.data(),
        querySnapshot.docs.first.id,
      );
    } catch (e) {
      print('❌ Ошибка получения согласия: $e');
      return null;
    }
  }

  /// Отзыв согласия
  Future<bool> revokeConsent(String consentId) async {
    try {
      await _firestore
          .collection('parental_consents')
          .doc(consentId)
          .update({
        'isActive': false,
        'revokedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Согласие отозвано: $consentId');
      return true;
    } catch (e) {
      print('❌ Ошибка отзыва согласия: $e');
      return false;
    }
  }

  /// Генерация 6-значного OTP
  String _generateOtp() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return (random % 1000000).toString().padLeft(6, '0');
  }
}

