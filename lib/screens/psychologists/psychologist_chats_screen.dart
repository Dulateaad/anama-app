import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../l10n/app_localizations.dart';
import 'psychologist_chat_screen.dart';
import '../../models/psychologist_model.dart';

/// Экран списка чатов психолога с пользователями
class PsychologistChatsScreen extends StatelessWidget {
  const PsychologistChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isKazakh = l10n.locale.languageCode == 'kk';
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.uid;

    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isKazakh ? 'Чаттар' : 'Мои чаты'),
        ),
        body: const Center(
          child: Text('Ошибка: пользователь не авторизован'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isKazakh ? 'Чаттар' : 'Мои чаты'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            tooltip: isKazakh ? 'Шығу' : 'Выйти',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('psychologistId', isEqualTo: currentUserId)
            .where('lastMessageTime', isNotEqualTo: null)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    isKazakh 
                      ? 'Қате орын алды: ${snapshot.error}'
                      : 'Произошла ошибка: ${snapshot.error}',
                    style: TextStyle(color: Colors.red[700]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
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
                      ? 'Чаттар жоқ'
                      : 'У вас пока нет чатов',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isKazakh
                      ? 'Пайдаланушылар сізбен байланысқан кезде чаттар осы жерде пайда болады'
                      : 'Чаты появятся здесь, когда пользователи свяжутся с вами',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chatData = chats[index].data() as Map<String, dynamic>;
              final chatId = chats[index].id;
              final userId = chatData['userId'] as String?;
              final userName = chatData['userName'] as String? ?? 'Пользователь';
              final lastMessage = chatData['lastMessage'] as String?;
              final lastMessageTime = chatData['lastMessageTime'] as Timestamp?;
              final unreadCount = chatData['unreadCount'] as int? ?? 0;
              final lastMessageSenderId = chatData['lastMessageSenderId'] as String?;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .get(),
                builder: (context, userSnapshot) {
                  AnamaUser? user;
                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    user = AnamaUser.fromMap(
                      userSnapshot.data!.data() as Map<String, dynamic>,
                      userId!,
                    );
                  }

                  return _buildChatCard(
                    context,
                    chatId: chatId,
                    userId: userId,
                    user: user,
                    userName: userName,
                    lastMessage: lastMessage,
                    lastMessageTime: lastMessageTime,
                    unreadCount: unreadCount,
                    isMe: lastMessageSenderId == currentUserId,
                    isKazakh: isKazakh,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChatCard(
    BuildContext context, {
    required String chatId,
    required String? userId,
    AnamaUser? user,
    required String userName,
    String? lastMessage,
    Timestamp? lastMessageTime,
    required int unreadCount,
    required bool isMe,
    required bool isKazakh,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          if (userId == null) return;
          
          // Открываем чат с пользователем
          context.push(
            '/psychologist-user-chat',
            extra: {
              'userId': userId,
              'userName': userName,
              'chatId': chatId,
            },
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Аватар пользователя
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Icon(
                      Icons.person,
                      color: Colors.blue[700],
                      size: 28,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 16),
              
              // Информация о чате
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (lastMessage != null) ...[
                      Text(
                        isMe ? 'Вы: $lastMessage' : lastMessage,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else ...[
                      Text(
                        isKazakh ? 'Чат жоқ' : 'Нет сообщений',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    if (lastMessageTime != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(lastMessageTime.toDate()),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
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
    } else if (difference.inDays < 7) {
      final weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
      return weekdays[dateTime.weekday - 1];
    } else {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
    }
  }
}

