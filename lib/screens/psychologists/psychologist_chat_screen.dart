import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/psychologist_model.dart';
import '../../services/auth_service.dart';


import '../../services/notification_service.dart';
import '../../l10n/app_localizations.dart';

/// Экран чата с психологом
class PsychologistChatScreen extends StatefulWidget {
  final Psychologist psychologist;

  const PsychologistChatScreen({
    super.key,
    required this.psychologist,
  });

  @override
  State<PsychologistChatScreen> createState() => _PsychologistChatScreenState();
}

class _PsychologistChatScreenState extends State<PsychologistChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _getChatId() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.uid;
    if (currentUserId == null) return '';
    
    // Создаем уникальный ID чата (сортируем ID для консистентности)
    final ids = [currentUserId, widget.psychologist.uid]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      debugPrint('❌ Сообщение пустое');
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      debugPrint('❌ Пользователь не авторизован');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка: пользователь не авторизован')),
        );
      }
      return;
    }

    final chatId = _getChatId();
    if (chatId.isEmpty) {
      debugPrint('❌ Не удалось создать ID чата');
      return;
    }
    
    debugPrint('✅ Отправляем сообщение в чат $chatId');

    try {
      final currentUserName = authService.currentAnamaUserCached?.displayName ?? 
                             authService.currentAnamaUserCached?.email ?? 
                             'Пользователь';

      // Сохраняем сообщение
      final messageRef = await _firestore.collection('chats').doc(chatId).collection('messages').add({
        'senderId': currentUser.uid,
        'senderName': currentUserName,
        'text': message,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Обновляем последнее сообщение в чате
      await _firestore.collection('chats').doc(chatId).set({
        'participants': [currentUser.uid, widget.psychologist.uid],
        'psychologistId': widget.psychologist.uid,
        'psychologistName': widget.psychologist.fullName,
        'userId': currentUser.uid,
        'userName': currentUserName,
        'lastMessage': message,
        'lastMessageSenderId': currentUser.uid,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Уведомление будет отправлено через Cloud Function onChatMessageCreated
      // Также сохраняем для локального уведомления через NotificationService
      try {
        final notificationService = NotificationService();
        await notificationService.sendChatNotification(
          recipientId: widget.psychologist.uid,
          senderName: currentUserName,
          message: message,
          chatId: chatId,
        );
      } catch (e) {
        print('Ошибка отправки локального уведомления: $e');
      }

      _messageController.clear();
      
      // Прокрутка вниз
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка отправки сообщения: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Отправить уведомление о новом сообщении
  Future<void> _sendChatNotification({
    required String recipientId,
    required String senderName,
    required String message,
    required String chatId,
  }) async {
    try {
      // Получаем данные получателя
      final recipientDoc = await _firestore.collection('users').doc(recipientId).get();
      if (!recipientDoc.exists) {
        // Если это психолог, проверяем коллекцию psychologists
        final psychologistDoc = await _firestore.collection('psychologists').doc(recipientId).get();
        if (!psychologistDoc.exists) return;
      }

      // Сохраняем уведомление для отправки через Cloud Function
      await _firestore.collection('chat_notifications').add({
        'recipientId': recipientId,
        'senderName': senderName,
        'message': message.length > 100 ? '${message.substring(0, 100)}...' : message,
        'chatId': chatId,
        'type': 'new_message',
        'createdAt': FieldValue.serverTimestamp(),
        'sent': false,
      });
    } catch (e) {
      print('Ошибка отправки уведомления о чате: $e');
    }
  }

  /// Отметить сообщения как прочитанные
  Future<void> _markMessagesAsRead(String chatId, String currentUserId) async {
    try {
      // Получаем непрочитанные сообщения от другого участника
      final unreadMessages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUserId)
          .where('read', isEqualTo: false)
          .get();

      // Отмечаем как прочитанные
      final batch = _firestore.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();

      // Сбрасываем счетчик непрочитанных
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount': 0,
      });
    } catch (e) {
      print('Ошибка отметки сообщений как прочитанных: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    // Отмечаем сообщения как прочитанные при открытии чата
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUserId = authService.currentUser?.uid;
      if (currentUserId != null) {
        final chatId = _getChatId();
        if (chatId.isNotEmpty) {
          _markMessagesAsRead(chatId, currentUserId);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isKazakh = l10n.locale.languageCode == 'kk';
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.uid;
    final chatId = _getChatId();

    if (currentUserId == null || chatId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isKazakh ? 'Чат' : 'Чат'),
        ),
        body: const Center(
          child: Text('Ошибка: пользователь не авторизован'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.psychologist.fullName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.psychologist.specialization,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Список сообщений
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint('❌ Ошибка загрузки сообщений: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Ошибка загрузки: ${snapshot.error}',
                          style: TextStyle(color: Colors.red[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          isKazakh 
                            ? 'Чат бастаңыз'
                            : 'Начните чат',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!.docs.reversed.toList();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                      final messageData = messages[index].data() as Map<String, dynamic>;
                      final isMe = messageData['senderId'] == currentUserId;
                      final isRead = messageData['read'] as bool? ?? false;

                      // Отмечаем сообщения как прочитанные при просмотре
                      if (!isMe && !isRead) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _markMessagesAsRead(chatId, currentUserId);
                        });
                      }

                      return _buildMessageBubble(
                        context,
                        messageData['text'] as String,
                        messageData['senderName'] as String? ?? 'Пользователь',
                        messageData['timestamp'] as Timestamp?,
                        isMe,
                        isRead: isRead,
                      );
                  },
                );
              },
            ),
          ),

          // Поле ввода
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: isKazakh ? 'Хабарлама жаз...' : 'Написать сообщение...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: Colors.purple,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    String text,
    String senderName,
    Timestamp? timestamp,
    bool isMe, {
    bool isRead = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.purple[100],
              child: Icon(Icons.psychology, size: 18, color: Colors.purple[700]),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? Colors.purple[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomRight: isMe ? const Radius.circular(4) : null,
                  bottomLeft: !isMe ? const Radius.circular(4) : null,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe) ...[
                    Text(
                      senderName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.purple[900],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    text,
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (timestamp != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(timestamp.toDate()),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            isRead ? Icons.done_all : Icons.done,
                            size: 12,
                            color: isRead ? Colors.blue[700] : Colors.grey[600],
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[100],
              child: Icon(Icons.person, size: 18, color: Colors.blue[700]),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Вчера ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
    }
  }
}

