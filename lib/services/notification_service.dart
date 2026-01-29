import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/survey_response.dart'; // Для RiskLevel

/// Сервис уведомлений
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Инициализация сервиса
  Future<void> initialize() async {
    // Запрашиваем разрешения
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true, // Для критических уведомлений
    );

    // Настраиваем локальные уведомления
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Обработка фоновых сообщений
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Обработка сообщений в приложении
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Получаем и сохраняем FCM токен
    final token = await _messaging.getToken();
    print('FCM Token: $token');
  }

  /// Сохранить FCM токен пользователя
  Future<void> saveUserToken(String userId) async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
    }

    // Обновляем токен при его изменении
    _messaging.onTokenRefresh.listen((newToken) async {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': newToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Отправить критический алерт родителю
  Future<void> sendCrisisAlert({
    required String parentId,
    required String message,
  }) async {
    // Получаем FCM токен родителя
    final parentDoc = await _firestore.collection('users').doc(parentId).get();
    final fcmToken = parentDoc.data()?['fcmToken'];

    if (fcmToken != null) {
      // Сохраняем уведомление для отправки через Cloud Functions
      await _firestore.collection('notifications_queue').add({
        'type': 'crisis_alert',
        'recipientId': parentId,
        'fcmToken': fcmToken,
        'title': '🔴 Требуется ваше внимание',
        'body': message,
        'data': {
          'type': 'crisis',
          'action': 'open_dashboard',
        },
        'priority': 'high',
        'createdAt': FieldValue.serverTimestamp(),
        'sent': false,
      });
    }

    // Также показываем локальное уведомление если родитель в приложении
    await _showLocalNotification(
      title: '🔴 Требуется ваше внимание',
      body: message,
      channelId: 'crisis_alerts',
      channelName: 'Критические уведомления',
      importance: Importance.max,
      priority: Priority.max,
    );
  }

  /// Отправить алерт родителю о статусе ребенка
  Future<void> sendAlertToParent({
    required String parentId,
    required String title,
    required String body,
    required RiskLevel riskLevel,
  }) async {
    // Получаем FCM токен родителя
    final parentDoc = await _firestore.collection('users').doc(parentId).get();
    final fcmToken = parentDoc.data()?['fcmToken'];

    final channelId = riskLevel == RiskLevel.red ? 'crisis_alerts' : 'status_alerts';
    final channelName = riskLevel == RiskLevel.red ? 'Критические уведомления' : 'Статус ребенка';
    final importance = riskLevel == RiskLevel.red ? Importance.max : Importance.high;
    final priority = riskLevel == RiskLevel.red ? Priority.max : Priority.high;

    if (fcmToken != null) {
      // Сохраняем уведомление для отправки через Cloud Functions
      await _firestore.collection('notifications_queue').add({
        'type': riskLevel == RiskLevel.red ? 'crisis_alert' : 'status_alert',
        'recipientId': parentId,
        'fcmToken': fcmToken,
        'title': title,
        'body': body,
        'data': {
          'type': 'status',
          'riskLevel': riskLevel.name,
          'action': 'open_dashboard',
        },
        'priority': riskLevel == RiskLevel.red ? 'high' : 'normal',
        'createdAt': FieldValue.serverTimestamp(),
        'sent': false,
      });
    }

    // Показываем локальное уведомление
    await _showLocalNotification(
      title: title,
      body: body,
      channelId: channelId,
      channelName: channelName,
      importance: importance,
      priority: priority,
    );
  }

  /// Отправить напоминание о заполнении опросника
  Future<void> sendSurveyReminder(String userId) async {
    await _showLocalNotification(
      title: '📝 Время для исповеди',
      body: 'Ответь на несколько вопросов. Это займет пару минут.',
      channelId: 'survey_reminders',
      channelName: 'Напоминания',
    );
  }

  /// Отправить уведомление о новом сообщении в чате
  Future<void> sendChatNotification({
    required String recipientId,
    required String senderName,
    required String message,
    required String chatId,
  }) async {
    // Получаем FCM токен получателя
    var recipientDoc = await _firestore.collection('users').doc(recipientId).get();
    
    // Если не найден в users, проверяем psychologists
    if (!recipientDoc.exists) {
      recipientDoc = await _firestore.collection('psychologists').doc(recipientId).get();
    }
    
    final fcmToken = recipientDoc.data()?['fcmToken'];

    if (fcmToken != null) {
      // Сохраняем уведомление для отправки через Cloud Functions
      await _firestore.collection('chat_notifications').add({
        'type': 'chat_message',
        'recipientId': recipientId,
        'fcmToken': fcmToken,
        'senderName': senderName,
        'message': message.length > 100 ? '${message.substring(0, 100)}...' : message,
        'chatId': chatId,
        'title': '💬 Новое сообщение',
        'body': '$senderName: ${message.length > 50 ? "${message.substring(0, 50)}..." : message}',
        'data': {
          'type': 'chat',
          'chatId': chatId,
          'senderId': recipientId, // Для навигации
          'action': 'open_chat',
        },
        'priority': 'high',
        'createdAt': FieldValue.serverTimestamp(),
        'sent': false,
      });
    }

    // Показываем локальное уведомление если пользователь в приложении
    await _showLocalNotification(
      title: '💬 Новое сообщение от $senderName',
      body: message.length > 100 ? '${message.substring(0, 100)}...' : message,
      channelId: 'chat_messages',
      channelName: 'Сообщения в чате',
      importance: Importance.high,
      priority: Priority.high,
    );
  }

  /// Отправить уведомление о новом инсайте родителю
  Future<void> sendInsightNotification({
    required String parentId,
    required String riskLevel,
  }) async {
    String emoji;
    String message;

    switch (riskLevel) {
      case 'green':
        emoji = '🟢';
        message = 'Всё хорошо! Посмотрите сегодняшний отчет.';
        break;
      case 'yellow':
        emoji = '🟡';
        message = 'Есть на что обратить внимание. Откройте приложение.';
        break;
      case 'red':
        emoji = '🔴';
        message = 'Требуется ваше внимание!';
        break;
      default:
        emoji = '📊';
        message = 'Готов новый отчет о состоянии ребенка.';
    }

    await _showLocalNotification(
      title: '$emoji Новый инсайт',
      body: message,
      channelId: 'daily_insights',
      channelName: 'Ежедневные отчеты',
    );
  }

  /// Показать локальное уведомление
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    Importance importance = Importance.defaultImportance,
    Priority priority = Priority.defaultPriority,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: importance,
      priority: priority,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  /// Обработка нажатия на уведомление
  void _onNotificationTap(NotificationResponse response) {
    // Обработка нажатия на уведомление
    // Навигация будет обрабатываться в UI слое
    print('Notification tapped: ${response.payload}');
  }

  /// Обработка сообщения в foreground
  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message: ${message.notification?.title}');
    
    if (message.notification != null) {
      _showLocalNotification(
        title: message.notification!.title ?? 'Anama',
        body: message.notification!.body ?? '',
        channelId: 'general',
        channelName: 'Общие уведомления',
      );
    }
  }
}

/// Background message handler (должен быть top-level функцией)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.notification?.title}');
}

