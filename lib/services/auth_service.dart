import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'dart:math';

/// Сервис авторизации
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  AnamaUser? _currentAnamaUser;
  AnamaUser? get currentAnamaUserCached => _currentAnamaUser;

  /// Текущий пользователь Firebase
  User? get currentUser => _auth.currentUser;

  /// Стрим состояния авторизации
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Регистрация нового пользователя
  Future<AnamaUser> signUp({
    required String email,
    required String password,
    required UserRole role,
    String? displayName,
  }) async {
    try {
      // Создаем аккаунт в Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Ошибка создания пользователя');
      }

      // Генерируем уникальный код для связки (только для подростков)
      String? uniqueCode;
      if (role == UserRole.teen) {
        uniqueCode = _generateUniqueCode();
      }

      // Создаем профиль в Firestore
      final user = AnamaUser(
        uid: credential.user!.uid,
        email: email,
        displayName: displayName,
        role: role,
        uniqueCode: uniqueCode,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(user.toMap());

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Вход родителя по email
  Future<AnamaUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Ошибка входа');
      }

      // Получаем профиль из Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('Профиль пользователя не найден');
      }

      final user = AnamaUser.fromMap(userDoc.data()!, userDoc.id);
      _currentAnamaUser = user;
      notifyListeners();
      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Регистрация подростка по никнейму
  Future<AnamaUser> signUpTeen({
    required String nickname,
    required String password,
    int? age,
    String? parentEmail,
    Gender? gender,
  }) async {
    try {
      // Создаём fake email из никнейма (Firebase проверит уникальность)
      final fakeEmail = '${nickname.toLowerCase()}@anama.teen';
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: fakeEmail,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Ошибка создания аккаунта');
      }

      // Генерируем уникальный код для связки с родителем
      final uniqueCode = _generateUniqueCode();

      final user = AnamaUser(
        uid: credential.user!.uid,
        email: null,
        displayName: nickname,
        role: UserRole.teen,
        uniqueCode: uniqueCode,
        isAnonymous: false,
        gender: gender,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Сохраняем с никнеймом для поиска
      final userData = user.toMap();
      userData['nickname'] = nickname.toLowerCase();
      userData['fakeEmail'] = fakeEmail;
      
      // Сохраняем возраст и email родителя (если есть)
      if (age != null) {
        userData['age'] = age;
      }
      if (parentEmail != null) {
        userData['parentEmail'] = parentEmail.toLowerCase();
      }

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(userData);

      _currentAnamaUser = user;
      notifyListeners();
      return user;
    } on FirebaseAuthException catch (e) {
      // Если email уже используется = никнейм занят
      if (e.code == 'email-already-in-use') {
        throw Exception('Этот никнейм уже занят');
      }
      throw _handleAuthException(e);
    }
  }

  /// Вход подростка по никнейму
  Future<AnamaUser> signInTeen({
    required String nickname,
    required String password,
  }) async {
    try {
      // Создаём fake email из никнейма
      final fakeEmail = '${nickname.toLowerCase()}@anama.teen';
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: fakeEmail,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Ошибка входа');
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('Профиль не найден');
      }

      final user = AnamaUser.fromMap(userDoc.data()!, userDoc.id);
      _currentAnamaUser = user;
      notifyListeners();
      return user;
    } on FirebaseAuthException catch (e) {
      // Более понятные сообщения для подростков
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        throw Exception('Неверный никнейм или пароль');
      }
      throw _handleAuthException(e);
    }
  }

  /// Анонимный вход для подростков (без email)
  Future<AnamaUser> signInAnonymouslyAsTeen({
    String? displayName,
  }) async {
    try {
      // Создаем анонимный аккаунт
      final credential = await _auth.signInAnonymously();

      if (credential.user == null) {
        throw Exception('Ошибка создания аккаунта');
      }

      // Генерируем уникальный код для связки с родителем
      final uniqueCode = _generateUniqueCode();

      // Создаем профиль в Firestore
      final user = AnamaUser(
        uid: credential.user!.uid,
        email: null, // У подростка нет email
        displayName: displayName ?? 'Подросток',
        role: UserRole.teen,
        uniqueCode: uniqueCode,
        isAnonymous: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(user.toMap());

      _currentAnamaUser = user;
      notifyListeners();
      
      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Вход подростка по уникальному коду (если уже был создан аккаунт)
  Future<AnamaUser?> signInTeenByCode(String code) async {
    try {
      // Ищем пользователя по коду
      final querySnapshot = await _firestore
          .collection('users')
          .where('uniqueCode', isEqualTo: code.toUpperCase())
          .where('role', isEqualTo: 'teen')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Код не найден');
      }

      // Если пользователь анонимный, создаём новый анонимный аккаунт
      // и связываем с существующим профилем
      final existingUser = AnamaUser.fromMap(
        querySnapshot.docs.first.data(),
        querySnapshot.docs.first.id,
      );

      // Для простоты: создаём новый анонимный аккаунт 
      // и обновляем uid в существующем профиле
      final credential = await _auth.signInAnonymously();
      
      if (credential.user == null) {
        throw Exception('Ошибка входа');
      }

      // Обновляем uid в профиле
      await _firestore.collection('users').doc(existingUser.uid).delete();
      
      final updatedUser = AnamaUser(
        uid: credential.user!.uid,
        email: existingUser.email,
        displayName: existingUser.displayName,
        role: existingUser.role,
        uniqueCode: existingUser.uniqueCode,
        linkedUserId: existingUser.linkedUserId,
        isAnonymous: true,
        createdAt: existingUser.createdAt,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(updatedUser.toMap());

      _currentAnamaUser = updatedUser;
      notifyListeners();
      
      return updatedUser;
    } catch (e) {
      print('Error signing in teen by code: $e');
      rethrow;
    }
  }

  /// Сброс пароля по email
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Запрос сброса пароля подростка (отправляет код родителю)
  /// Возвращает замаскированный email родителя
  Future<String> requestTeenPasswordReset(String nickname) async {
    try {
      // Ищем подростка по никнейму
      final querySnapshot = await _firestore
          .collection('users')
          .where('nickname', isEqualTo: nickname.toLowerCase())
          .where('role', isEqualTo: 'teen')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Пользователь с таким никнеймом не найден');
      }

      final teenDoc = querySnapshot.docs.first;
      final teenData = teenDoc.data();
      final teenId = teenDoc.id;

      // Ищем email родителя
      String? parentEmail;
      
      // Сначала проверяем связанного родителя
      final linkedParentId = teenData['linkedUserId'] as String?;
      if (linkedParentId != null) {
        final parentDoc = await _firestore.collection('users').doc(linkedParentId).get();
        if (parentDoc.exists) {
          parentEmail = parentDoc.data()?['email'] as String?;
        }
      }
      
      // Если нет связанного родителя, берём email из регистрации
      parentEmail ??= teenData['parentEmail'] as String?;

      if (parentEmail == null || parentEmail.isEmpty) {
        throw Exception('Email родителя не найден. Обратитесь в поддержку');
      }

      // Генерируем 6-значный код
      final resetCode = _generateResetCode();
      final expiresAt = DateTime.now().add(const Duration(hours: 1));

      // Сохраняем код в Firestore
      await _firestore.collection('password_reset_codes').doc(teenId).set({
        'code': resetCode,
        'teenId': teenId,
        'nickname': nickname.toLowerCase(),
        'parentEmail': parentEmail,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': expiresAt,
        'used': false,
      });

      // Отправляем email родителю через Firebase Extension или Cloud Function
      await _firestore.collection('mail').add({
        'to': parentEmail,
        'message': {
          'subject': 'Anama: Код для сброса пароля ребёнка',
          'html': '''
            <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto;">
              <h2 style="color: #E8A5B3;">Anama</h2>
              <p>Здравствуйте!</p>
              <p>Ваш ребёнок (<b>$nickname</b>) запросил сброс пароля в приложении Anama.</p>
              <p style="font-size: 24px; background: #f5f5f5; padding: 20px; text-align: center; border-radius: 8px;">
                <b>$resetCode</b>
              </p>
              <p>Этот код действителен в течение 1 часа.</p>
              <p>Если вы не запрашивали сброс пароля, просто проигнорируйте это письмо.</p>
              <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
              <p style="color: #888; font-size: 12px;">Anama — эмоциональная безопасность для подростков</p>
            </div>
          ''',
        },
      });

      // Маскируем email для отображения
      return _maskEmail(parentEmail);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Ошибка при запросе сброса пароля');
    }
  }

  /// Сброс пароля подростка по коду
  Future<void> resetTeenPassword({
    required String nickname,
    required String code,
    required String newPassword,
  }) async {
    try {
      // Ищем код в базе
      final querySnapshot = await _firestore
          .collection('password_reset_codes')
          .where('nickname', isEqualTo: nickname.toLowerCase())
          .where('code', isEqualTo: code)
          .where('used', isEqualTo: false)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Неверный или устаревший код');
      }

      final codeDoc = querySnapshot.docs.first;
      final codeData = codeDoc.data();
      
      // Проверяем срок действия
      final expiresAt = (codeData['expiresAt'] as dynamic).toDate() as DateTime;
      if (DateTime.now().isAfter(expiresAt)) {
        throw Exception('Код истёк. Запросите новый код');
      }

      final teenId = codeData['teenId'] as String;

      // Получаем fakeEmail подростка для обновления пароля
      final teenDoc = await _firestore.collection('users').doc(teenId).get();
      if (!teenDoc.exists) {
        throw Exception('Аккаунт не найден');
      }
      
      final fakeEmail = teenDoc.data()?['fakeEmail'] as String?;
      if (fakeEmail == null) {
        throw Exception('Ошибка: аккаунт повреждён');
      }

      // Создаём запрос на сброс пароля (обрабатывается Cloud Function)
      await _firestore.collection('password_reset_requests').add({
        'teenId': teenId,
        'fakeEmail': fakeEmail,
        'newPassword': newPassword,
        'createdAt': FieldValue.serverTimestamp(),
        'processed': false,
      });

      // Помечаем код как использованный
      await codeDoc.reference.update({'used': true});

      // Cloud Function processPasswordResetRequests автоматически:
      // 1. Читает этот запрос
      // 2. Обновляет пароль через Admin SDK
      // 3. Удаляет пароль из документа (безопасность)
      
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Ошибка при сбросе пароля');
    }
  }

  /// Генерация 6-значного кода для сброса
  String _generateResetCode() {
    final random = Random();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

  /// Маскирование email (example@mail.com -> e***e@m***.com)
  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return '***@***.***';
    
    final name = parts[0];
    final domain = parts[1];
    
    String maskedName;
    if (name.length <= 2) {
      maskedName = '${name[0]}***';
    } else {
      maskedName = '${name[0]}***${name[name.length - 1]}';
    }
    
    final domainParts = domain.split('.');
    String maskedDomain;
    if (domainParts.isNotEmpty && domainParts[0].length > 1) {
      maskedDomain = '${domainParts[0][0]}***';
      if (domainParts.length > 1) {
        maskedDomain += '.${domainParts.sublist(1).join('.')}';
      }
    } else {
      maskedDomain = domain;
    }
    
    return '$maskedName@$maskedDomain';
  }

  /// Выход
  Future<void> signOut() async {
    await _auth.signOut();
    _currentAnamaUser = null;
    notifyListeners();
  }

  /// Получить текущего пользователя Anama
  Future<AnamaUser?> getCurrentAnamaUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) return null;

    return AnamaUser.fromMap(userDoc.data()!, userDoc.id);
  }

  /// Связка аккаунтов родитель <-> подросток
  Future<void> linkAccounts({
    required String parentId,
    required String teenCode,
  }) async {
    // Находим подростка по уникальному коду
    final teenQuery = await _firestore
        .collection('users')
        .where('uniqueCode', isEqualTo: teenCode)
        .where('role', isEqualTo: UserRole.teen.name)
        .limit(1)
        .get();

    if (teenQuery.docs.isEmpty) {
      throw Exception('Пользователь с таким кодом не найден');
    }

    final teenDoc = teenQuery.docs.first;
    final teenId = teenDoc.id;

    // Проверяем, не связан ли уже подросток
    final teenData = teenDoc.data();
    if (teenData['linkedUserId'] != null) {
      throw Exception('Этот аккаунт уже связан с другим родителем');
    }

    // Связываем аккаунты
    final batch = _firestore.batch();

    // Обновляем подростка
    batch.update(_firestore.collection('users').doc(teenId), {
      'linkedUserId': parentId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Обновляем родителя
    batch.update(_firestore.collection('users').doc(parentId), {
      'linkedUserId': teenId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Генерация уникального 6-значного кода
  String _generateUniqueCode() {
    final random = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Обработка ошибок Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Этот email уже используется';
      case 'invalid-email':
        return 'Неверный формат email';
      case 'weak-password':
        return 'Слишком слабый пароль';
      case 'user-not-found':
        return 'Пользователь не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'too-many-requests':
        return 'Слишком много попыток. Попробуйте позже';
      default:
        return e.message ?? 'Ошибка авторизации';
    }
  }

  /// GDPR: Полное удаление данных пользователя
  /// Удаляет все данные по категориям с возможностью доказательства
  Future<Map<String, int>> deleteUserData(String userId) async {
    final deletedCounts = <String, int>{};
    
    try {
      // 1. Удаляем ответы на опросы
      final responses = await _firestore
          .collection('survey_responses')
          .where('userId', isEqualTo: userId)
          .get();
      for (final doc in responses.docs) {
        await doc.reference.delete();
      }
      deletedCounts['survey_responses'] = responses.docs.length;

      // 2. Удаляем инсайты
      final insights = await _firestore
          .collection('daily_insights')
          .where('teenId', isEqualTo: userId)
          .get();
      for (final doc in insights.docs) {
        await doc.reference.delete();
      }
      deletedCounts['daily_insights'] = insights.docs.length;

      // 3. Удаляем кризисные алерты
      final alerts = await _firestore
          .collection('crisis_alerts')
          .where('teenId', isEqualTo: userId)
          .get();
      for (final doc in alerts.docs) {
        await doc.reference.delete();
      }
      deletedCounts['crisis_alerts'] = alerts.docs.length;

      // 4. Удаляем согласия
      final consents = await _firestore
          .collection('parental_consents')
          .where('childId', isEqualTo: userId)
          .get();
      for (final doc in consents.docs) {
        await doc.reference.delete();
      }
      deletedCounts['parental_consents'] = consents.docs.length;

      // 5. Удаляем результаты клинических тестов
      // PHQ-9
      final phq9Results = await _firestore
          .collection('phq9_results')
          .where('userId', isEqualTo: userId)
          .get();
      for (final doc in phq9Results.docs) {
        await doc.reference.delete();
      }
      deletedCounts['phq9_results'] = phq9Results.docs.length;

      // GAD-7
      final gad7Results = await _firestore
          .collection('gad7_results')
          .where('userId', isEqualTo: userId)
          .get();
      for (final doc in gad7Results.docs) {
        await doc.reference.delete();
      }
      deletedCounts['gad7_results'] = gad7Results.docs.length;

      // Traffic Light
      final trafficLightResults = await _firestore
          .collection('traffic_light_results')
          .where('userId', isEqualTo: userId)
          .get();
      for (final doc in trafficLightResults.docs) {
        await doc.reference.delete();
      }
      deletedCounts['traffic_light_results'] = trafficLightResults.docs.length;

      // Уведомления о тестах
      final testNotifications = await _firestore
          .collection('clinical_test_notifications')
          .where('teenId', isEqualTo: userId)
          .get();
      for (final doc in testNotifications.docs) {
        await doc.reference.delete();
      }
      deletedCounts['clinical_test_notifications'] = testNotifications.docs.length;

      // 6. Логируем удаление (для доказательства)
      await _firestore.collection('deletion_logs').add({
        'userId': userId,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedCounts': deletedCounts,
        'requestedBy': _auth.currentUser?.uid,
      });

      // 7. Удаляем профиль пользователя
      await _firestore.collection('users').doc(userId).delete();
      deletedCounts['user_profile'] = 1;

      // 8. Удаляем аккаунт Firebase Auth (если это текущий пользователь)
      if (_auth.currentUser?.uid == userId) {
        await _auth.currentUser?.delete();
      }

      return deletedCounts;
    } catch (e) {
      print('Error deleting user data: $e');
      rethrow;
    }
  }

  /// GDPR: Анонимизация данных (оставляем метаданные, убираем личность)
  Future<void> anonymizeUserData(String userId) async {
    try {
      // Анонимизируем профиль
      await _firestore.collection('users').doc(userId).update({
        'email': null,
        'displayName': 'Удалённый пользователь',
        'isAnonymized': true,
        'anonymizedAt': FieldValue.serverTimestamp(),
      });

      // Логируем анонимизацию
      await _firestore.collection('audit_log').add({
        'action': 'anonymize_user',
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error anonymizing user data: $e');
      rethrow;
    }
  }
}

