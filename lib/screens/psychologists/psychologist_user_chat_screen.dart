import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../l10n/app_localizations.dart';

/// Экран чата психолога с пользователем
class PsychologistUserChatScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String chatId;

  const PsychologistUserChatScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.chatId,
  });

  @override
  State<PsychologistUserChatScreen> createState() => _PsychologistUserChatScreenState();
}

class _PsychologistUserChatScreenState extends State<PsychologistUserChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUserId = authService.currentUser?.uid;
      if (currentUserId != null) {
        _markMessagesAsRead(widget.chatId, currentUserId);
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    if (currentUser == null) return;

    try {
      final psychologistDoc = await _firestore
          .collection('psychologists')
          .doc(currentUser.uid)
          .get();
      
      final psychologistName = psychologistDoc.exists
          ? (psychologistDoc.data()?['fullName'] as String? ?? 'Психолог')
          : 'Психолог';

      // Сохраняем сообщение
      await _firestore
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'senderId': currentUser.uid,
        'senderName': psychologistName,
        'text': message,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Обновляем последнее сообщение в чате
      await _firestore.collection('chats').doc(widget.chatId).set({
        'participants': [currentUser.uid, widget.userId],
        'psychologistId': currentUser.uid,
        'psychologistName': psychologistName,
        'userId': widget.userId,
        'userName': widget.userName,
        'lastMessage': message,
        'lastMessageSenderId': currentUser.uid,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _messageController.clear();
      
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

  Future<void> _markMessagesAsRead(String chatId, String currentUserId) async {
    try {
      final unreadMessages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUserId)
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();

      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount': 0,
      });
    } catch (e) {
      debugPrint('Ошибка отметки сообщений как прочитанных: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isKazakh = l10n.locale.languageCode == 'kk';
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.uid;

    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(isKazakh ? 'Чат' : 'Чат')),
        body: const Center(child: Text('Ошибка: пользователь не авторизован')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.userName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              isKazakh ? 'Пайдаланушы' : 'Пользователь',
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
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
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
                          isKazakh ? 'Чат бастаңыз' : 'Начните чат',
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

                    if (!isMe && !isRead) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _markMessagesAsRead(widget.chatId, currentUserId);
                      });
                    }

                    return _buildMessageBubble(
                      context,
                      messageData['text'] as String,
                      messageData['senderName'] as String? ?? 'Пользователь',
                      messageData['timestamp'] as Timestamp?,
                      isMe,
                      isRead,
                    );
                  },
                );
              },
            ),
          ),

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
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
    bool isMe,
    bool isRead,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[100],
              child: Icon(Icons.person, size: 18, color: Colors.blue[700]),
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
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(text, style: const TextStyle(fontSize: 14)),
                  if (timestamp != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(timestamp.toDate()),
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            isRead ? Icons.done_all : Icons.done,
                            size: 12,
                            color: isRead ? Colors.blue : Colors.grey[600],
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
              backgroundColor: Colors.purple[100],
              child: Icon(Icons.psychology, size: 18, color: Colors.purple[700]),
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
      return 'Вчера';
    } else {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
    }
  }
}

