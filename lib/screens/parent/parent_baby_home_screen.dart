import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../l10n/app_localizations.dart';

/// Главный экран для родителей малышей (0-5 лет)
/// Содержит: Serve & Return задания, развитие мозга, игры и активности
class ParentBabyHomeScreen extends StatefulWidget {
  const ParentBabyHomeScreen({super.key});

  @override
  State<ParentBabyHomeScreen> createState() => _ParentBabyHomeScreenState();
}

class _ParentBabyHomeScreenState extends State<ParentBabyHomeScreen> {
  int _babyAgeMonths = 12; // Возраст малыша в месяцах (по умолчанию)
  Map<String, dynamic>? _todayTask;
  bool _isLoadingTask = true;

  @override
  void initState() {
    super.initState();
    _loadBabyAge();
    _loadTodayTask();
  }

  Future<void> _loadBabyAge() async {
    try {
      final authService = context.read<AuthService>();
      final userId = authService.currentUser?.uid;
      if (userId != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        if (doc.exists && doc.data()?['babyAgeMonths'] != null) {
          setState(() {
            _babyAgeMonths = doc.data()!['babyAgeMonths'] as int;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading baby age: $e');
    }
  }

  Future<void> _loadTodayTask() async {
    setState(() => _isLoadingTask = true);
    try {
      // Загружаем Serve & Return карточку по возрасту
      final snapshot = await FirebaseFirestore.instance
          .collection('serve_and_return_cards')
          .where('ageRange.min', isLessThanOrEqualTo: _babyAgeMonths)
          .where('ageRange.max', isGreaterThanOrEqualTo: _babyAgeMonths)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _todayTask = snapshot.docs.first.data();
        });
      }
    } catch (e) {
      debugPrint('Error loading task: $e');
    } finally {
      setState(() => _isLoadingTask = false);
    }
  }

  String _getLocalizedText(Map<String, dynamic>? textMap, String defaultText) {
    if (textMap == null) return defaultText;
    final l10n = AppLocalizations.of(context);
    final langCode = l10n.locale.languageCode;
    return textMap[langCode] ?? textMap['ru'] ?? defaultText;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.pink.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Заголовок
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.getGreeting(),
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.get('babyDevelopmentJourney'),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          // Настройка возраста малыша
                          GestureDetector(
                            onTap: _showAgeSelector,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.pink.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Text('👶', style: TextStyle(fontSize: 18)),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatAge(_babyAgeMonths),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.pink.shade700,
                                    ),
                                  ),
                                  Icon(
                                    Icons.edit,
                                    size: 14,
                                    color: Colors.pink.shade700,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Serve & Return карточка дня
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildServeAndReturnCard(l10n),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Раздел "Развитие мозга"
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSectionTitle(
                    l10n.get('brainDevelopment'),
                    '🧠',
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Карточки развития
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 140,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildDevelopmentCard(
                        emoji: '👀',
                        title: l10n.get('eyeContact'),
                        subtitle: l10n.get('eyeContactDesc'),
                        color: Colors.blue.shade400,
                      ),
                      _buildDevelopmentCard(
                        emoji: '🗣️',
                        title: l10n.get('talking'),
                        subtitle: l10n.get('talkingDesc'),
                        color: Colors.green.shade400,
                      ),
                      _buildDevelopmentCard(
                        emoji: '🤗',
                        title: l10n.get('physicalTouch'),
                        subtitle: l10n.get('physicalTouchDesc'),
                        color: Colors.orange.shade400,
                      ),
                      _buildDevelopmentCard(
                        emoji: '🎵',
                        title: l10n.get('musicAndSounds'),
                        subtitle: l10n.get('musicAndSoundsDesc'),
                        color: Colors.purple.shade400,
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Раздел "Игры и активности"
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSectionTitle(
                    l10n.get('gamesAndActivities'),
                    '🎮',
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Игры по возрасту
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildActivityTile(
                      emoji: '🎭',
                      title: l10n.get('peekaboo'),
                      subtitle: l10n.get('peekabooDesc'),
                      ageRange: '0-12',
                    ),
                    _buildActivityTile(
                      emoji: '📚',
                      title: l10n.get('readingTogether'),
                      subtitle: l10n.get('readingTogetherDesc'),
                      ageRange: '6-60',
                    ),
                    _buildActivityTile(
                      emoji: '🎨',
                      title: l10n.get('fingerPainting'),
                      subtitle: l10n.get('fingerPaintingDesc'),
                      ageRange: '18-60',
                    ),
                    _buildActivityTile(
                      emoji: '🧩',
                      title: l10n.get('simplePuzzles'),
                      subtitle: l10n.get('simplePuzzlesDesc'),
                      ageRange: '24-60',
                    ),
                  ]),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Кнопка "Поменять на подростка"
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/parent-age-selection'),
                    icon: const Icon(Icons.swap_horiz),
                    label: Text(l10n.get('switchToTeenMode')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServeAndReturnCard(AppLocalizations l10n) {
    if (_isLoadingTask) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final title = _getLocalizedText(
      _todayTask?['title'] as Map<String, dynamic>?,
      l10n.get('serveAndReturnTask'),
    );
    final description = _getLocalizedText(
      _todayTask?['description'] as Map<String, dynamic>?,
      l10n.get('serveAndReturnDefault'),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.pink.shade400,
            Colors.pink.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('🎯', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.get('todayTask'),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Serve & Return',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _loadTodayTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.pink.shade600,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(l10n.get('anotherTask')),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {
                  // TODO: Mark task as done
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.get('taskCompleted')),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_outline),
                color: Colors.white,
                iconSize: 32,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String emoji) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildDevelopmentCard({
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile({
    required String emoji,
    required String title,
    required String subtitle,
    required String ageRange,
  }) {
    final l10n = AppLocalizations.of(context);
    final isAvailable = _isActivityAvailable(ageRange);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAvailable ? Colors.green.shade100 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isAvailable ? Colors.grey[800] : Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isAvailable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.get('recommended'),
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _isActivityAvailable(String ageRange) {
    final parts = ageRange.split('-');
    final min = int.parse(parts[0]);
    final max = int.parse(parts[1]);
    return _babyAgeMonths >= min && _babyAgeMonths <= max;
  }

  String _formatAge(int months) {
    final l10n = AppLocalizations.of(context);
    if (months < 12) {
      return '$months ${l10n.get('months')}';
    } else {
      final years = months ~/ 12;
      final remainingMonths = months % 12;
      if (remainingMonths == 0) {
        return '$years ${l10n.get('years')}';
      }
      return '$years ${l10n.get('years')} $remainingMonths ${l10n.get('months')}';
    }
  }

  void _showAgeSelector() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.get('selectBabyAge'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: 60, // 0-60 месяцев
                itemBuilder: (context, index) {
                  final months = index + 1;
                  final isSelected = months == _babyAgeMonths;
                  return ListTile(
                    title: Text(_formatAge(months)),
                    trailing: isSelected
                        ? Icon(Icons.check, color: Colors.pink.shade600)
                        : null,
                    selected: isSelected,
                    selectedTileColor: Colors.pink.shade50,
                    onTap: () async {
                      setState(() => _babyAgeMonths = months);
                      Navigator.pop(context);
                      
                      // Сохраняем в Firestore
                      final authService = context.read<AuthService>();
                      final userId = authService.currentUser?.uid;
                      if (userId != null) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .update({'babyAgeMonths': months});
                      }
                      
                      _loadTodayTask();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

