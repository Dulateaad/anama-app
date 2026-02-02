import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/parental_consent.dart';

/// Сервис для работы с родительскими согласиями
class ParentalConsentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Отправка OTP на email родителя
  Future<bool> sendOtpToEmail(String email) async {
    try {
      // Генерируем 6-значный код
      final otp = _generateOtp();
      final normalizedEmail = email.toLowerCase().trim();
      
      // Сохраняем OTP во временную коллекцию (с TTL)
      await _firestore
          .collection('parental_consent_otps')
          .doc(normalizedEmail)
          .set({
        'otp': otp,
        'email': normalizedEmail,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 10)),
        ),
      });

      // Отправляем email через коллекцию mail (триггер Cloud Function)
      await _firestore.collection('mail').add({
        'to': normalizedEmail,
        'message': {
          'subject': 'Anama: Код подтверждения родителя',
          'html': '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, sans-serif; background-color: #FDF8F9;">
  <table width="100%" cellpadding="0" cellspacing="0" style="max-width: 600px; margin: 0 auto; padding: 20px;">
    <tr>
      <td style="background: linear-gradient(135deg, #F3C6CF 0%, #E8A5B3 100%); border-radius: 16px 16px 0 0; padding: 40px 20px; text-align: center;">
        <h1 style="color: white; margin: 0; font-size: 32px; font-weight: bold;">🕊️ Anama</h1>
        <p style="color: rgba(255,255,255,0.9); margin: 10px 0 0 0; font-size: 16px;">Эмоциональная безопасность</p>
      </td>
    </tr>
    <tr>
      <td style="background-color: white; padding: 40px 30px; border-radius: 0 0 16px 16px; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
        <h2 style="color: #5D2A3B; margin: 0 0 20px 0; font-size: 24px;">Подтверждение родительского согласия</h2>
        
        <p style="color: #666; font-size: 16px; line-height: 1.6; margin-bottom: 20px;">
          Ваш ребенок регистрируется в приложении Anama. Для подтверждения родительского согласия введите код ниже:
        </p>
        
        <div style="background: linear-gradient(135deg, #F3C6CF 0%, #E8A5B3 100%); border-radius: 12px; padding: 30px; text-align: center; margin: 30px 0;">
          <p style="color: white; font-size: 14px; margin: 0 0 10px 0; text-transform: uppercase; letter-spacing: 1px;">Ваш код подтверждения</p>
          <p style="color: white; font-size: 42px; font-weight: bold; margin: 0; letter-spacing: 8px; font-family: monospace;">$otp</p>
        </div>
        
        <div style="background-color: #FFF5F7; border-left: 4px solid #E8A5B3; padding: 15px; margin: 20px 0; border-radius: 0 8px 8px 0;">
          <p style="color: #5D2A3B; font-size: 14px; margin: 0;">
            <strong>⚠️ Важно:</strong> Код действителен 10 минут. Никому не сообщайте этот код.
          </p>
        </div>
        
        <p style="color: #999; font-size: 14px; line-height: 1.6;">
          Если вы не запрашивали этот код, просто проигнорируйте это письмо.
        </p>
        
        <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
        
        <p style="color: #999; font-size: 12px; text-align: center; margin: 0;">
          © ${DateTime.now().year} Anama. Эмоциональная безопасность вашего ребенка.
        </p>
      </td>
    </tr>
  </table>
</body>
</html>
          ''',
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ OTP email отправлен на $normalizedEmail');
      return true;
    } catch (e) {
      print('❌ Ошибка отправки OTP: $e');
      return false;
    }
  }

  /// Проверка OTP
  Future<bool> verifyOtp(String email, String otp) async {
    try {
      final normalizedEmail = email.toLowerCase().trim();
      
      final doc = await _firestore
          .collection('parental_consent_otps')
          .doc(normalizedEmail)
          .get();

      if (!doc.exists) {
        print('❌ OTP документ не найден для $normalizedEmail');
        return false;
      }

      final data = doc.data()!;
      final storedOtp = data['otp'] as String;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();

      // Проверяем срок действия
      if (DateTime.now().isAfter(expiresAt)) {
        await doc.reference.delete();
        print('❌ OTP истёк');
        return false;
      }

      // Проверяем код
      if (storedOtp == otp) {
        // Удаляем использованный OTP
        await doc.reference.delete();
        print('✅ OTP подтверждён для $normalizedEmail');
        return true;
      }

      print('❌ Неверный OTP');
      return false;
    } catch (e) {
      print('❌ Ошибка проверки OTP: $e');
      return false;
    }
  }

  /// Создание родительского согласия
  Future<ParentalConsent?> createParentalConsent({
    required String childId,
    required String parentEmail,
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
          .where('email', isEqualTo: parentEmail.toLowerCase())
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
        parentEmail: parentEmail.toLowerCase(),
        parentPhone: '', // Телефон больше не используется
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
        'parentEmail': parentEmail.toLowerCase(),
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

