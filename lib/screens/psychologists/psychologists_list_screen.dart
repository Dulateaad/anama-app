import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../models/psychologist_model.dart';
import '../../l10n/app_localizations.dart';

/// Экран списка психологов
class PsychologistsListScreen extends StatelessWidget {
  const PsychologistsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isKazakh = l10n.locale.languageCode == 'kk';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isKazakh ? 'Психологтер' : 'Психологи',
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('psychologists')
            .where('isVerified', isEqualTo: true) // Только проверенные психологи
            .orderBy('createdAt', descending: true)
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
                  Icon(Icons.psychology_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    isKazakh 
                      ? 'Психологтер жоқ'
                      : 'Психологи не найдены',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final psychologists = snapshot.data!.docs.map((doc) {
            return Psychologist.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: psychologists.length,
            itemBuilder: (context, index) {
              final psychologist = psychologists[index];
              return _buildPsychologistCard(context, psychologist, isKazakh);
            },
          );
        },
      ),
    );
  }

  Widget _buildPsychologistCard(
    BuildContext context,
    Psychologist psychologist,
    bool isKazakh,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Переход к чату с психологом
          context.push(
            '/psychologist-chat',
            extra: psychologist,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Аватар
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.purple[100],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: psychologist.photoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Image.network(
                              psychologist.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.psychology,
                                  color: Colors.purple[700],
                                  size: 30,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.psychology,
                            color: Colors.purple[700],
                            size: 30,
                          ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Информация
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Имя и верификация
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                psychologist.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            if (psychologist.isVerified)
                              Icon(
                                Icons.verified,
                                color: Colors.blue[700],
                                size: 20,
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Специализация
                        Text(
                          psychologist.specialization,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Опыт
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              isKazakh
                                ? '${psychologist.experienceYears} жыл тәжірибе'
                                : 'Опыт: ${psychologist.experienceYears} лет',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Биография (если есть)
              if (psychologist.bio != null && psychologist.bio!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  psychologist.bio!,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Кнопка начать чат
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push(
                      '/psychologist-chat',
                      extra: psychologist,
                    );
                  },
                  icon: const Icon(Icons.chat, size: 18),
                  label: Text(
                    isKazakh ? 'Чат бастау' : 'Начать чат',
                    style: const TextStyle(fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

