import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/psychologist_model.dart';
import '../../services/auth_service.dart';
import '../../l10n/app_localizations.dart';
import 'psychologist_chat_screen.dart';

/// Экран списка чатов пользователя с психологами
class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isKazakh = l10n.locale.languageCode == 'kk';
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.uid;

    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isKazakh ? 'Чаттар' : 'Чаты'),
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
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUserId)
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
                      ? 'Психологтермен бастау үшін психологтер тізіміне өтіңіз'
                      : 'Перейдите к списку психологов, чтобы начать чат',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/psychologists'),
                    icon: const Icon(Icons.psychology),
                    label: Text(isKazakh ? 'Психологтерді табу' : 'Найти психолога'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
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
              final psychologistId = chatData['psychologistId'] as String?;
              final psychologistName = chatData['psychologistName'] as String? ?? 'Психолог';
              final lastMessage = chatData['lastMessage'] as String?;
              final lastMessageTime = chatData['lastMessageTime'] as Timestamp?;
              final unreadCount = chatData['unreadCount'] as int? ?? 0;
              final lastMessageSenderId = chatData['lastMessageSenderId'] as String?;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('psychologists')
                    .doc(psychologistId)
                    .get(),
                builder: (context, psychologistSnapshot) {
                  Psychologist? psychologist;
                  if (psychologistSnapshot.hasData && psychologistSnapshot.data!.exists) {
                    psychologist = Psychologist.fromMap(
                      psychologistSnapshot.data!.data() as Map<String, dynamic>,
                      psychologistId!,
                    );
                  }

                  return _buildChatCard(
                    context,
                    chatId: chatId,
                    psychologist: psychologist,
                    psychologistName: psychologistName,
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
    Psychologist? psychologist,
    required String psychologistName,
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
          if (psychologist != null) {
            context.push(
              '/psychologist-chat',
              extra: psychologist,
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Аватар
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.purple[100],
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: psychologist?.photoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image.network(
                              psychologist!.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.psychology,
                                  color: Colors.purple[700],
                                  size: 28,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.psychology,
                            color: Colors.purple[700],
                            size: 28,
                          ),
                  ),
                  if (psychologist?.isVerified == true)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.verified,
                          size: 16,
                          color: Colors.blue[700],
                        ),
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
                            psychologistName,
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

