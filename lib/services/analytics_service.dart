import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

/// Сервис для аналитики приложения
/// Отслеживает события, метрики и точки выхода пользователей
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Логировать событие
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (kIsWeb) {
      // Для веба логируем в консоль для отладки
      debugPrint('📊 Analytics Event: $name');
      if (parameters != null) {
        debugPrint('   Parameters: $parameters');
      }
    }
    
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      debugPrint('❌ Analytics Error: $e');
    }
  }

  /// Отслеживание скачивания приложения
  Future<void> logAppInstall() async {
    await logEvent(name: 'app_install');
  }

  /// Отслеживание открытия приложения
  Future<void> logAppOpen() async {
    await logEvent(name: 'app_open');
  }

  /// Отслеживание регистрации
  Future<void> logSignUp({
    required String method,
    String? userId,
  }) async {
    await logEvent(
      name: 'sign_up',
      parameters: {
        'method': method,
        if (userId != null) 'user_id': userId,
      },
    );
  }

  /// Отслеживание входа
  Future<void> logLogin({
    required String method,
    String? userId,
  }) async {
    await logEvent(
      name: 'login',
      parameters: {
        'method': method,
        if (userId != null) 'user_id': userId,
      },
    );
  }

  /// Отслеживание начала теста
  Future<void> logTestStart({
    required String testName,
    String? userId,
  }) async {
    await logEvent(
      name: 'test_start',
      parameters: {
        'test_name': testName, // phq9, gad7, traffic_light
        if (userId != null) 'user_id': userId,
      },
    );
  }

  /// Отслеживание завершения теста
  Future<void> logTestComplete({
    required String testName,
    required int score,
    String? riskLevel,
    String? userId,
  }) async {
    await logEvent(
      name: 'test_complete',
      parameters: {
        'test_name': testName,
        'score': score,
        if (riskLevel != null) 'risk_level': riskLevel,
        if (userId != null) 'user_id': userId,
      },
    );
  }

  /// Отслеживание получения Serve & Return задания
  Future<void> logServeAndReturnTask({
    required int childAgeMonths,
    String? languageCode,
  }) async {
    await logEvent(
      name: 'serve_and_return_task',
      parameters: {
        'child_age_months': childAgeMonths,
        if (languageCode != null) 'language': languageCode,
      },
    );
  }

  /// Отслеживание генерации задания Gemini
  Future<void> logGeminiTask({
    required String taskType,
    String? userId,
  }) async {
    await logEvent(
      name: 'gemini_task',
      parameters: {
        'task_type': taskType,
        if (userId != null) 'user_id': userId,
      },
    );
  }

  /// Отслеживание просмотра экрана (точки выхода)
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    } catch (e) {
      debugPrint('❌ Analytics Screen View Error: $e');
    }
  }

  /// Отслеживание точки выхода (когда пользователь покидает экран)
  Future<void> logScreenExit({
    required String screenName,
    Duration? timeOnScreen,
  }) async {
    await logEvent(
      name: 'screen_exit',
      parameters: {
        'screen_name': screenName,
        if (timeOnScreen != null) 'time_on_screen_seconds': timeOnScreen.inSeconds,
      },
    );
  }

  /// Установка пользовательского свойства
  Future<void> setUserProperty({
    required String name,
    String? value,
  }) async {
    try {
      await _analytics.setUserProperty(
        name: name,
        value: value,
      );
    } catch (e) {
      debugPrint('❌ Analytics User Property Error: $e');
    }
  }

  /// Установка идентификатора пользователя
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      debugPrint('❌ Analytics User ID Error: $e');
    }
  }
}

