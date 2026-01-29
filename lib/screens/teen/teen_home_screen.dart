import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/survey_service.dart';
import '../../models/question.dart';
import '../../widgets/accessible_text.dart';
import 'survey_screen.dart';

class TeenHomeScreen extends StatefulWidget {
  const TeenHomeScreen({super.key});

  @override
  State<TeenHomeScreen> createState() => _TeenHomeScreenState();
}

class _TeenHomeScreenState extends State<TeenHomeScreen> {
  final SurveyService _surveyService = SurveyService();
  bool _hasCompletedToday = false;
  bool _isLoading = true;
  String? _uniqueCode;
  int? _userAge; // Возраст пользователя для проверки доступа к тесту "Светофор"

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final authService = context.read<AuthService>();
      final user = await authService.getCurrentAnamaUser();
      
      if (user != null) {
        bool completed = false;
        try {
          completed = await _surveyService.hasCompletedTodaySurvey(user.uid);
        } catch (e) {
          print('Error checking survey: $e');
        }
        
        // Вычисляем возраст пользователя
        int? age;
        if (user.birthDate != null) {
          final now = DateTime.now();
          age = now.year - user.birthDate!.year;
          if (now.month < user.birthDate!.month ||
              (now.month == user.birthDate!.month && now.day < user.birthDate!.day)) {
            age--;
          }
        }
        
        if (mounted) {
          setState(() {
            _hasCompletedToday = completed;
            _uniqueCode = user.uniqueCode;
            _userAge = age;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startSurvey() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SurveyScreen(),
      ),
    ).then((_) => _loadUserData());
  }

  Future<void> _signOut() async {
    final authService = context.read<AuthService>();
    await authService.signOut();
    if (mounted) {
      context.go('/login');
    }
  }

  void _callHotline(String number) async {
    final uri = Uri.parse('tel:$number');
    try {
      await launchUrl(uri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Позвони по номеру: $number')),
        );
      }
    }
  }

  void _showCrisisChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Куда обратиться',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildHelpOption(
                    icon: Icons.phone,
                    title: 'Телефон доверия',
                    subtitle: '150 — бесплатно, анонимно, 24/7',
                    onTap: () => _callHotline('150'),
                  ),
                  _buildHelpOption(
                    icon: Icons.phone,
                    title: 'Экстренная помощь',
                    subtitle: '111 — скорая психологическая помощь',
                    onTap: () => _callHotline('111'),
                  ),
                  _buildHelpOption(
                    icon: Icons.chat_bubble_outline,
                    title: 'Онлайн-чат',
                    subtitle: 'pomoschryadom.kz — напиши психологу',
                    onTap: () async {
                      final uri = Uri.parse('https://pomoschryadom.kz');
                      try {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } catch (e) {
                        // ignore
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ты не один(а). Всё можно решить. Поговори с кем-то.',
                            style: TextStyle(color: Colors.blue[900]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.red[700]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final currentUserId = authService.currentUser?.uid;
    
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
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
                                    'Привет! 👋',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getGreeting(),
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.logout),
                                onPressed: _signOut,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Код для связки
                  if (_uniqueCode != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Card(
                          color: Colors.blue[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.link, color: Colors.blue[700]),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Твой код для родителя:',
                                        style: TextStyle(color: Colors.blue[700]),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _uniqueCode!,
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[900],
                                          letterSpacing: 4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: _uniqueCode!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Код скопирован ✓')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  
                  // Главная карточка
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _hasCompletedToday
                          ? _buildCompletedCard()
                          : _buildSurveyCard(),
                    ),
                  ),
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  
                  // Клинические тесты
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: AccessibleText(
                              'Клинические тесты',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Тест "Светофор" (только для 13-17 лет)
                          if (_userAge != null && _userAge! >= 13 && _userAge! <= 17) ...[
                            Semantics(
                              button: true,
                              label: 'Пройти тест "Светофор" для оценки эмоционального состояния',
                              child: Card(
                                color: Colors.green[50],
                                child: InkWell(
                                  onTap: () => context.push('/traffic-light-test'),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Icon(Icons.traffic, color: Colors.green[700], size: 32),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              AccessibleText(
                                                'Светофор',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              AccessibleText(
                                                'Тест эмоционального состояния',
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.chevron_right, color: Colors.grey[400]),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          
                          Row(
                            children: [
                              Expanded(
                                child: Semantics(
                                  button: true,
                                  label: 'Пройти тест PHQ-9 для оценки депрессии',
                                  child: Card(
                                    child: InkWell(
                                      onTap: () => context.push('/phq9-test'),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.psychology, color: Colors.blue[700]),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: AccessibleText(
                                                    'PHQ-9',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            AccessibleText(
                                              'Тест на депрессию',
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Semantics(
                                  button: true,
                                  label: 'Пройти тест GAD-7 для оценки тревожности',
                                  child: Card(
                                    child: InkWell(
                                      onTap: () => context.push('/gad7-test'),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.psychology_outlined, color: Colors.orange[700]),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: AccessibleText(
                                                    'GAD-7',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            AccessibleText(
                                              'Тест на тревожность',
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  
                  // SOS-кнопка
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Card(
                        color: Colors.red[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.favorite, color: Colors.red[700]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Нужна помощь?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Если тебе сейчас плохо — позвони. Мы поможем тебе. Ты не один(а), и всё можно решить вместе.',
                                style: TextStyle(
                                  color: Colors.red[900],
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _callHotline('150'),
                                      icon: const Icon(Icons.phone),
                                      label: const Text('150'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _showCrisisChat(),
                                      icon: const Icon(Icons.chat),
                                      label: const Text('Чат'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red[700],
                                        side: BorderSide(color: Colors.red[300]!),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  
                  // Мои чаты (если есть активные чаты)
                  if (currentUserId != null)
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('chats')
                          .where('participants', arrayContains: currentUserId)
                          .where('lastMessageTime', isNotEqualTo: null)
                          .orderBy('lastMessageTime', descending: true)
                          .limit(1)
                          .snapshots(),
                      builder: (context, chatsSnapshot) {
                        final hasChats = chatsSnapshot.hasData && 
                                       chatsSnapshot.data != null &&
                                       chatsSnapshot.data!.docs.isNotEmpty;
                        
                        if (!hasChats) {
                          return const SliverToBoxAdapter(child: SizedBox.shrink());
                        }
                      
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Card(
                            elevation: 2,
                            child: InkWell(
                              onTap: () => context.push('/chats'),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.purple[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.chat, color: Colors.purple[700], size: 32),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Мои чаты',
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Перейти к чатам с психологами',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right, color: Colors.grey[400]),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  
                  // Психологи
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Card(
                        elevation: 2,
                        child: InkWell(
                          onTap: () => context.push('/psychologists'),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.purple[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.psychology, color: Colors.purple[700], size: 32),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Психологи',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Найди специалиста для беседы',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: Colors.grey[400]),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  
                  // Информация о приватности
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.shield, color: Colors.green[700]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Твоя приватность',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildPrivacyItem(
                                '🔒',
                                'Твои ответы анонимны',
                                'Родители не видят дословные ответы',
                              ),
                              _buildPrivacyItem(
                                '🤖',
                                'AI анализирует настроение',
                                'Не содержание, а общее состояние',
                              ),
                              _buildPrivacyItem(
                                '💚',
                                'Цель — помочь',
                                'Чтобы близкие понимали тебя лучше',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
      ),
    );
  }

  Widget _buildSurveyCard() {
    // Получаем тему из контекста для определения пола
    final isMale = Theme.of(context).scaffoldBackgroundColor == const Color(0xFFF9FAFB);
    final gradientColors = isMale
        ? [
            const Color(0xFF6B7280),
            const Color(0xFF4B5563),
          ]
        : [
            const Color(0xFFF3C6CF),
            const Color(0xFFE8A5B3),
          ];
    
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _startSurvey,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.edit_note,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Исповедь дня',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ответь на ${DefaultQuestions.dailyQuestions.length} вопросов. Это займет пару минут.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _startSurvey,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFD4899A),
                  elevation: 0,
                ),
                child: const Text('Начать'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 48,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Готово на сегодня! 🎉',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ты молодец! Приходи завтра.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyItem(String emoji, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Доброе утро!';
    if (hour < 18) return 'Добрый день!';
    return 'Добрый вечер!';
  }
}

