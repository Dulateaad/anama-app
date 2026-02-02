import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../l10n/app_localizations.dart';

/// Тип ребёнка по возрасту
enum ChildAgeGroup {
  baby,      // 0-5 лет
  teenager,  // 13-18 лет
}

/// Экран выбора возрастной группы ребёнка
/// Показывается после входа родителя
class ChildAgeSelectionScreen extends StatefulWidget {
  const ChildAgeSelectionScreen({super.key});

  @override
  State<ChildAgeSelectionScreen> createState() => _ChildAgeSelectionScreenState();
}

class _ChildAgeSelectionScreenState extends State<ChildAgeSelectionScreen> {
  bool _isLoading = false;

  Future<void> _selectAgeGroup(ChildAgeGroup ageGroup) async {
    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final userId = authService.currentUser?.uid;

      if (userId != null) {
        // Сохраняем выбор в профиле родителя
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'childAgeGroup': ageGroup == ChildAgeGroup.baby ? 'baby' : 'teenager',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        // Переходим на соответствующий экран
        if (ageGroup == ChildAgeGroup.baby) {
          context.go('/parent-baby');
        } else {
          context.go('/parent');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.pink.shade50,
              Colors.purple.shade50,
              Colors.blue.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                
                // Заголовок
                Text(
                  l10n.get('selectChildAge'),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.get('selectChildAgeDescription'),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 48),
                
                // Карточка: Малыш 0-5 лет
                _AgeGroupCard(
                  emoji: '👶',
                  title: l10n.get('babyAgeGroup'),
                  subtitle: l10n.get('babyAgeGroupDescription'),
                  color: Colors.pink.shade400,
                  features: [
                    l10n.get('serveAndReturnFeature'),
                    l10n.get('brainDevelopmentFeature'),
                    l10n.get('gamesAndActivitiesFeature'),
                  ],
                  isLoading: _isLoading,
                  onTap: () => _selectAgeGroup(ChildAgeGroup.baby),
                ),
                
                const SizedBox(height: 20),
                
                // Карточка: Подросток 13-18 лет
                _AgeGroupCard(
                  emoji: '🧑‍🎓',
                  title: l10n.get('teenagerAgeGroup'),
                  subtitle: l10n.get('teenagerAgeGroupDescription'),
                  color: Colors.indigo.shade400,
                  features: [
                    l10n.get('trafficLightFeature'),
                    l10n.get('stateAnalyticsFeature'),
                    l10n.get('psychologistFeature'),
                  ],
                  isLoading: _isLoading,
                  onTap: () => _selectAgeGroup(ChildAgeGroup.teenager),
                ),
                
                const Spacer(),
                
                // Подсказка
                Text(
                  l10n.get('canChangeLayerInSettings'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Карточка выбора возрастной группы
class _AgeGroupCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final List<String> features;
  final bool isLoading;
  final VoidCallback onTap;

  const _AgeGroupCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.features,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              // Эмодзи
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Текст
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Фичи
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: features.map((f) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ),
              
              // Стрелка
              Icon(
                Icons.arrow_forward_ios,
                color: color.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

