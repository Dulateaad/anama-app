import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/survey_service.dart';
import '../../services/gemini_service.dart';
import '../../services/clinical_test_service.dart';
import '../../services/analytics_service.dart';
import '../../models/daily_insight.dart';
import '../../models/survey_response.dart';
import '../../models/phq9_question.dart';
import '../../models/gad7_question.dart';
import '../../models/future_insight.dart';
import '../../widgets/future_insight_widget.dart';
import '../../widgets/brain_visualization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  final SurveyService _surveyService = SurveyService();
  final GeminiService _geminiService = GeminiService();
  final ClinicalTestService _clinicalTestService = ClinicalTestService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  DailyInsight? _todayInsight;
  List<DailyInsight> _insightHistory = [];
  String? _linkedTeenId;
  Map<String, dynamic>? _serveAndReturnTask;
  bool _isLoadingTask = false;
  int _childAgeMonths = 36; // Default 3 года, можно сделать настраиваемым
  List<Map<String, dynamic>> _clinicalTestResults = []; // Результаты PHQ-9 и GAD-7
  Phq9Result? _latestPhq9Result; // Последний результат PHQ-9
  Gad7Result? _latestGad7Result; // Последний результат GAD-7
  Map<String, dynamic>? _latestSurveyResult; // Последний результат опросника
  BrainZone? _newlyActivatedZone; // Новая активированная зона мозга

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final authService = context.read<AuthService>();
      final user = await authService.getCurrentAnamaUser();
      
      if (user != null && user.linkedUserId != null) {
        _linkedTeenId = user.linkedUserId;
        
        DailyInsight? insight;
        List<DailyInsight> history = [];
        
        try {
          // Генерируем или получаем сегодняшний инсайт
          insight = await _surveyService.generateDailyInsightForParent(
            teenId: user.linkedUserId!,
            parentId: user.uid,
          );
        } catch (e) {
          print('Error generating insight: $e');
        }
        
        try {
          // Получаем историю
          history = await _surveyService.getInsightHistory(user.uid);
        } catch (e) {
          print('Error getting history: $e');
        }
        
        // Загружаем результаты клинических тестов (уведомления)
        List<Map<String, dynamic>> testResults = [];
        try {
          testResults = await _loadClinicalTestResults(user.uid);
        } catch (e) {
          print('Error loading test results: $e');
        }
        
        // Загружаем последние результаты всех трех тестов
        Phq9Result? phq9Result;
        Gad7Result? gad7Result;
        Map<String, dynamic>? surveyResult;
        
        if (user.linkedUserId != null) {
          try {
            phq9Result = await _clinicalTestService.getLatestPhq9Result(user.linkedUserId!);
          } catch (e) {
            print('Error loading PHQ-9: $e');
          }
          
          try {
            gad7Result = await _clinicalTestService.getLatestGad7Result(user.linkedUserId!);
          } catch (e) {
            print('Error loading GAD-7: $e');
          }
          
          try {
            surveyResult = await _loadLatestSurveyResult(user.linkedUserId!);
          } catch (e) {
            print('Error loading survey result: $e');
          }
        }
        
        if (mounted) {
          setState(() {
            _todayInsight = insight;
            _insightHistory = history;
            _clinicalTestResults = testResults;
            _latestPhq9Result = phq9Result;
            _latestGad7Result = gad7Result;
            _latestSurveyResult = surveyResult;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Загрузить результаты клинических тестов для родителя (уведомления)
  Future<List<Map<String, dynamic>>> _loadClinicalTestResults(String parentId) async {
    try {
      final snapshot = await _firestore
          .collection('clinical_test_notifications')
          .where('parentId', isEqualTo: parentId)
          .where('isRead', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Ошибка загрузки результатов тестов: $e');
      return [];
    }
  }

  /// Загрузить последний результат опросника
  Future<Map<String, dynamic>?> _loadLatestSurveyResult(String teenId) async {
    try {
      // Получаем последний инсайт, который содержит анализ опросника
      final insight = await _surveyService.generateDailyInsightForParent(
        teenId: teenId,
        parentId: context.read<AuthService>().currentUser?.uid ?? '',
      );
      
      if (insight == null) return null;
      
      // Получаем последние ответы на опросник
      final responsesSnapshot = await _firestore
          .collection('survey_responses')
          .where('userId', isEqualTo: teenId)
          .orderBy('answeredAt', descending: true)
          .limit(1)
          .get();
      
      if (responsesSnapshot.docs.isEmpty) return null;
      
      final response = responsesSnapshot.docs.first.data();
      
      return {
        'insight': insight,
        'lastResponse': response,
        'overallRisk': insight.overallRisk.name,
        'summary': insight.aiSummary,
        'advice': insight.aiAdvice,
        'date': insight.date,
      };
    } catch (e) {
      print('Ошибка загрузки результата опросника: $e');
      return null;
    }
  }

  Future<void> _signOut() async {
    final authService = context.read<AuthService>();
    await authService.signOut();
    if (mounted) {
      context.go('/login');
    }
  }

  void _callEmergency(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// Получить задание Serve and Return от Gemini
  Future<void> _getServeAndReturnTask({bool showModal = true}) async {
    // Предотвращаем множественные вызовы
    if (_isLoadingTask) {
      print('⚠️ Запрос уже выполняется, пропускаем');
      return;
    }
    
    print('🔄 Начинаем загрузку нового задания...');
    setState(() => _isLoadingTask = true);
    
    try {
      // Получаем язык пользователя
      final locale = Localizations.localeOf(context);
      final languageCode = locale.languageCode; // kk или ru
      
      final task = await _geminiService.generateServeAndReturnTask(
        childAgeMonths: _childAgeMonths,
        languageCode: languageCode,
      );
      
      // Логирование события аналитики
      await AnalyticsService().logServeAndReturnTask(
        childAgeMonths: _childAgeMonths,
        languageCode: languageCode,
      );
      
      print('✅ Получено новое задание: ${task['taskTitle']}');
      print('📋 Задание: ${task.toString()}');
      
      if (mounted) {
        setState(() {
          _serveAndReturnTask = task;
          _isLoadingTask = false;
        });
        
        // Показываем задание в модальном окне только если нужно
        if (showModal) {
          print('📱 Показываем модальное окно с новым заданием');
        _showTaskModal(task);
        }
      }
    } catch (e) {
      print('❌ Error getting task: $e');
      if (mounted) {
        setState(() => _isLoadingTask = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка получения задания: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showTaskModal(Map<String, dynamic> task) {
    print('🎯 Открываем модальное окно с заданием: ${task['taskTitle']}');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Заголовок
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF3C6CF), Color(0xFFE8A5B3)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.auto_awesome, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task['taskTitle'] ?? 'Задание Serve & Return',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                task['duration'] ?? '5-10 минут',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Зона мозга
                    if (task['brainZone'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3C6CF).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '🧠 ${task['brainZone']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFD4899A),
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // Шаги
                    Text(
                      'Как выполнить:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    if (task['steps'] != null)
                      ...List.generate(
                        (task['steps'] as List).length,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3C6CF),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  task['steps'][index],
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // Почему это работает
                    if (task['whyItWorks'] != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lightbulb, color: Colors.blue[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Почему это работает',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(task['whyItWorks']),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Признаки успеха
                    if (task['signs_of_success'] != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Признак успеха',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(task['signs_of_success']),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Кнопки
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isLoadingTask ? null : () async {
                              // Сохраняем контекст перед закрытием модального окна
                              final navigatorContext = Navigator.of(context);
                              
                              // Закрываем текущее модальное окно
                              navigatorContext.pop();
                              
                              // Ждем, чтобы анимация закрытия завершилась
                              await Future.delayed(const Duration(milliseconds: 400));
                              
                              // Проверяем, что виджет еще смонтирован
                              if (!mounted) return;
                              
                              // Получаем новое задание и показываем его в новом модальном окне
                              await _getServeAndReturnTask();
                            },
                            icon: _isLoadingTask 
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh),
                            label: Semantics(
                              label: _isLoadingTask ? 'Загрузка задания' : 'Другое задание',
                              hint: 'Получить новое задание для развития ребенка',
                              child: Text(_isLoadingTask ? 'Загрузка...' : 'Другое задание'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Semantics(
                            button: true,
                            label: 'Я выполнила задание',
                            hint: 'Нажмите после выполнения задания чтобы получить научный инсайт',
                          child: ElevatedButton.icon(
                              onPressed: () async {
                                // Закрываем модальное окно
                                Navigator.pop(context);
                                
                                // Определяем зону мозга для задания
                                final brainZone = BrainZoneMapper.getZoneForTask(task);
                                
                                // Активируем зону мозга
                                if (brainZone != null) {
                                  setState(() {
                                    _newlyActivatedZone = brainZone;
                                  });
                                  
                                  // Сохраняем прогресс в Firestore
                                  final authService = context.read<AuthService>();
                                  final userId = authService.currentUser?.uid;
                                  if (userId != null) {
                                    final progressDoc = FirebaseFirestore.instance
                                        .collection('brain_progress')
                                        .doc(userId);
                                    
                                    final doc = await progressDoc.get();
                                    Set<String> zones = {};
                                    if (doc.exists) {
                                      zones = Set<String>.from(doc.data()?['activatedZones'] ?? []);
                                    }
                                    zones.add(brainZone.name);
                                    
                                    await progressDoc.set({
                                      'activatedZones': zones.toList(),
                                      'lastUpdated': FieldValue.serverTimestamp(),
                                      'totalZones': zones.length,
                                      'completedTasks': FieldValue.increment(1),
                                    }, SetOptions(merge: true));
                                  }
                                }
                                
                                // Получаем инсайт на основе задания
                                final taskText = '${task['taskTitle'] ?? ''} ${task['steps']?.join(' ') ?? ''}';
                                final insight = FutureInsightsDatabase.getInsightForTask(
                                  taskText,
                                  _childAgeMonths,
                                  Localizations.localeOf(context).languageCode,
                                );
                                
                                // Показываем инсайт
                                if (mounted) {
                                  showFutureInsightDialog(context, insight);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple[700],
                                foregroundColor: Colors.white,
                              ),
                              icon: const Text('🧠', style: TextStyle(fontSize: 18)),
                              label: const Text('Я выполнила!'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: CustomScrollView(
                  slivers: [
                    // Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Аналитика души',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getDateString(),
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
                      ),
                    ),
                    
                    // Сегодняшний инсайт или заглушка
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _todayInsight != null
                            ? _buildInsightCard(_todayInsight!)
                            : _buildNoDataCard(),
                      ),
                    ),
                    
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    
                    // Результаты всех трех тестов
                    if (_latestPhq9Result != null || _latestGad7Result != null || _latestSurveyResult != null) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Результаты тестов',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 12)),
                      
                      // PHQ-9
                      if (_latestPhq9Result != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            child: _buildTestResultCard(
                              title: 'PHQ-9',
                              subtitle: 'Тест на депрессию',
                              icon: Icons.psychology,
                              color: Colors.blue,
                              score: _latestPhq9Result!.totalScore,
                              maxScore: 27,
                              severity: _latestPhq9Result!.severity,
                              date: _latestPhq9Result!.completedAt,
                              onTap: () => _showPhq9Details(_latestPhq9Result!),
                            ),
                          ),
                        ),
                      
                      // GAD-7
                      if (_latestGad7Result != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            child: _buildTestResultCard(
                              title: 'GAD-7',
                              subtitle: 'Тест на тревожность',
                              icon: Icons.psychology_outlined,
                              color: Colors.orange,
                              score: _latestGad7Result!.totalScore,
                              maxScore: 21,
                              severity: _latestGad7Result!.severity,
                              date: _latestGad7Result!.completedAt,
                              onTap: () => _showGad7Details(_latestGad7Result!),
                            ),
                          ),
                        ),
                      
                      // Опросник (Исповедь дня)
                      if (_latestSurveyResult != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            child: _buildSurveyResultCard(_latestSurveyResult!),
                          ),
                        ),
                      
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                    
                    // Новые уведомления о тестах
                    if (_clinicalTestResults.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Новые результаты',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 12)),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final testResult = _clinicalTestResults[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 8,
                              ),
                              child: _buildClinicalTestCard(testResult),
                            );
                          },
                          childCount: _clinicalTestResults.length,
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                    
                    // Gemini AI — Serve and Return (для родителей с детьми 0-5 лет)
                    // Этот блок предназначен для родителей с маленькими детьми
                    // Можно показывать всем родителям, так как у одного родителя может быть и маленький ребенок, и подросток
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildGeminiCard(),
                      ),
                    ),
                    
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    
                    // Визуализация развития мозга
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Builder(
                          builder: (context) {
                            final authService = context.read<AuthService>();
                            final userId = authService.currentUser?.uid;
                            if (userId == null) return const SizedBox.shrink();
                            return BrainProgressCard(
                              parentId: userId,
                              newlyActivatedZone: _newlyActivatedZone,
                            );
                          },
                        ),
                      ),
                    ),
                    
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    
                    // Экстренные кнопки
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildEmergencyButtons(),
                      ),
                    ),
                    
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    
                    // История
                    if (_insightHistory.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'История',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 12)),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final insight = _insightHistory[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                              child: _buildHistoryItem(insight),
                            );
                          },
                          childCount: _insightHistory.length,
                        ),
                      ),
                    ],
                    
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInsightCard(DailyInsight insight) {
    final riskColor = _getRiskColor(insight.overallRisk);
    final isCritical = insight.overallRisk == RiskLevel.red;
    
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header с уровнем риска
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: riskColor.withOpacity(0.1),
            child: Row(
              children: [
                Text(
                  insight.overallRisk.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.overallRisk.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: riskColor,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        insight.overallRisk.description,
                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Что это значит
                Text(
                  'Что это значит',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(insight.aiSummary),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                // Что делать
                Text(
                  'Что делать',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(insight.aiAdvice),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                // Фразы для разговора
                Text(
                  'Что сказать сегодня',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...insight.suggestedPhrases.map((phrase) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💬 '),
                      Expanded(
                        child: Text(
                          '"$phrase"',
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                )),
                
                // Кнопка связи с психологом (при критическом уровне)
                if (isCritical) ...[
                  const SizedBox(height: 24),
                  
                  // Срочное предупреждение
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '⚠️ Если ребенок говорит о причинении себе вреда, НЕМЕДЛЕННО звоните 111 или 112!',
                            style: TextStyle(
                              color: Colors.red[900],
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Кнопка связи с психологом
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/psychologists'),
                      icon: const Icon(Icons.psychology),
                      label: const Text('🧠 Связаться с психологом сейчас'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Экстренные номера
                  _buildEmergencyButtons(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.hourglass_empty, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Ожидаем данные',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ребенок пока не заполнил сегодняшний опросник. Инсайт появится после заполнения.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyButtons() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emergency, color: Colors.red[700], size: 18),
              const SizedBox(width: 8),
              Text(
                'Экстренные службы',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildEmergencyNumberButton(
                  number: '111',
                  label: 'Телефон доверия',
                  icon: Icons.phone_in_talk,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildEmergencyNumberButton(
                  number: '112',
                  label: 'Экстренная помощь',
                  icon: Icons.emergency,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildEmergencyNumberButton(
                  number: '150',
                  label: 'Защита детей',
                  icon: Icons.child_care,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildEmergencyNumberButton(
                  number: '102',
                  label: 'Полиция',
                  icon: Icons.local_police,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyNumberButton({
    required String number,
    required String label,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () => _callEmergency(number),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.red[700]),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  number,
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.red[400],
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Карточка Gemini AI — Serve and Return
  Widget _buildGeminiCard() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _isLoadingTask ? null : _getServeAndReturnTask,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF3C6CF),
                Color(0xFFE8A5B3),
              ],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _isLoadingTask
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.auto_awesome,
                        size: 28,
                        color: Colors.white,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '✨ Gemini AI',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Harvard',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Получить задание Serve & Return',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(DailyInsight insight) {
    final riskColor = _getRiskColor(insight.overallRisk);
    
    return Card(
      child: ListTile(
        leading: Text(
          insight.overallRisk.emoji,
          style: const TextStyle(fontSize: 24),
        ),
        title: Text(
          _formatDate(insight.date),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          insight.aiSummary,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: () {
          // TODO: Открыть детальный просмотр
        },
      ),
    );
  }

  Color _getRiskColor(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.green:
        return Colors.green;
      case RiskLevel.yellow:
        return Colors.orange;
      case RiskLevel.red:
        return Colors.red;
    }
  }

  String _getDateString() {
    final now = DateTime.now();
    final months = ['янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  String _formatDate(DateTime date) {
    final months = ['янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
    return '${date.day} ${months[date.month - 1]}';
  }

  /// Карточка результата клинического теста
  Widget _buildClinicalTestCard(Map<String, dynamic> testResult) {
    final testType = testResult['testType'] as String;
    final totalScore = testResult['totalScore'] as int;
    final severity = testResult['severity'] as String;
    final aiAnalysis = testResult['aiAnalysis'] as Map<String, dynamic>?;
    final completedAt = (testResult['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    
    final isPhq9 = testType == 'PHQ-9';
    final maxScore = isPhq9 ? 27 : 21;
    final testName = isPhq9 ? 'PHQ-9 (Депрессия)' : 'GAD-7 (Тревожность)';
    final icon = isPhq9 ? Icons.psychology : Icons.psychology_outlined;
    final color = isPhq9 ? Colors.blue : Colors.orange;
    
    // Определяем цвет по уровню тяжести
    Color severityColor;
    if (severity.contains('minimal') || severity.contains('Минимальная')) {
      severityColor = Colors.green;
    } else if (severity.contains('mild') || severity.contains('Легкая')) {
      severityColor = Colors.orange;
    } else if (severity.contains('moderate') || severity.contains('Умеренная')) {
      severityColor = Colors.deepOrange;
    } else {
      severityColor = Colors.red;
    }
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _showTestResultDetails(testResult),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          testName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _formatDate(completedAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: severityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: severityColor, width: 1.5),
                    ),
                    child: Text(
                      '$totalScore/$maxScore',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: severityColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              if (aiAnalysis != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Рекомендации',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        aiAnalysis['recommendations'] ?? aiAnalysis['summary'] ?? 'Рекомендации доступны',
                        style: TextStyle(
                          color: Colors.blue[900],
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Показать детали результата теста
  void _showTestResultDetails(Map<String, dynamic> testResult) {
    final testType = testResult['testType'] as String;
    final totalScore = testResult['totalScore'] as int;
    final severity = testResult['severity'] as String;
    final aiAnalysis = testResult['aiAnalysis'] as Map<String, dynamic>?;
    final result = testResult['result'] as Map<String, dynamic>?;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      testType == 'PHQ-9' ? 'Результат теста PHQ-9' : 'Результат теста GAD-7',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Балл
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$totalScore',
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                          Text(
                            ' / ${testType == 'PHQ-9' ? 27 : 21}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // AI анализ и рекомендации
                    if (aiAnalysis != null) ...[
                      if (aiAnalysis['summary'] != null) ...[
                        Text(
                          'Анализ',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          aiAnalysis['summary'],
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      if (aiAnalysis['recommendations'] != null) ...[
                        Text(
                          'Рекомендации',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            aiAnalysis['recommendations'],
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      if (aiAnalysis['professionalHelp'] != null) ...[
                        Text(
                          'Нужна ли консультация специалиста?',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          aiAnalysis['professionalHelp'],
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      if (aiAnalysis['immediateActions'] != null) ...[
                        Text(
                          'Немедленные действия',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...(aiAnalysis['immediateActions'] as List).map((action) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 20, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  action.toString(),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        )),
                        const SizedBox(height: 24),
                      ],
                      
                      if (aiAnalysis['supportPhrases'] != null) ...[
                        Text(
                          'Фразы поддержки',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...(aiAnalysis['supportPhrases'] as List).map((phrase) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              phrase.toString(),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        )),
                      ],
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Кнопка закрыть
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Помечаем как прочитанное
                          _markAsRead(testResult['id']);
                          Navigator.pop(context);
                        },
                        child: const Text('Понятно'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Универсальная карточка результата теста
  Widget _buildTestResultCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int score,
    required int maxScore,
    required dynamic severity,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    // Определяем цвет по уровню тяжести
    Color severityColor;
    String severityLabel;
    String severityEmoji;
    
    if (severity.toString().contains('minimal') || severity.toString().contains('Минимальная')) {
      severityColor = Colors.green;
      severityLabel = severity.toString().contains('Phq9') ? 'Минимальная депрессия' : 'Минимальная тревожность';
      severityEmoji = '🟢';
    } else if (severity.toString().contains('mild') || severity.toString().contains('Легкая')) {
      severityColor = Colors.orange;
      severityLabel = severity.toString().contains('Phq9') ? 'Легкая депрессия' : 'Легкая тревожность';
      severityEmoji = '🟡';
    } else if (severity.toString().contains('moderate') || severity.toString().contains('Умеренная')) {
      severityColor = Colors.deepOrange;
      severityLabel = severity.toString().contains('Phq9') ? 'Умеренная депрессия' : 'Умеренная тревожность';
      severityEmoji = '🟠';
    } else {
      severityColor = Colors.red;
      severityLabel = severity.toString().contains('Phq9') ? 'Тяжелая депрессия' : 'Тяжелая тревожность';
      severityEmoji = '🔴';
    }
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          severityEmoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          severityLabel,
                          style: TextStyle(
                            color: severityColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$score',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: severityColor,
                    ),
                  ),
                  Text(
                    '/ $maxScore',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(date),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Карточка результата опросника (Исповедь дня)
  Widget _buildSurveyResultCard(Map<String, dynamic> surveyResult) {
    final insight = surveyResult['insight'] as DailyInsight?;
    final overallRisk = insight?.overallRisk ?? RiskLevel.green;
    final riskColor = _getRiskColor(overallRisk);
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _showSurveyDetails(surveyResult),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3C6CF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.chat_bubble_outline, color: Color(0xFFD4899A), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Исповедь дня',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ежедневный опросник',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          overallRisk.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          overallRisk.title,
                          style: TextStyle(
                            color: riskColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    Icons.insights,
                    color: riskColor,
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(insight?.date ?? DateTime.now()),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Показать детали PHQ-9
  void _showPhq9Details(Phq9Result result) async {
    // Загружаем AI анализ из Firestore
    try {
      final snapshot = await _firestore
          .collection('phq9_results')
          .where('userId', isEqualTo: _linkedTeenId)
          .orderBy('completedAt', descending: true)
          .limit(1)
          .get();
      
      Map<String, dynamic>? aiAnalysis;
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        aiAnalysis = data['aiAnalysis'] as Map<String, dynamic>?;
      }
      
      _showTestResultModal(
        testType: 'PHQ-9',
        totalScore: result.totalScore,
        maxScore: 27,
        severity: result.severity.name,
        aiAnalysis: aiAnalysis,
        result: result.toMap(),
      );
    } catch (e) {
      print('Ошибка загрузки деталей PHQ-9: $e');
      _showTestResultModal(
        testType: 'PHQ-9',
        totalScore: result.totalScore,
        maxScore: 27,
        severity: result.severity.name,
        aiAnalysis: null,
        result: result.toMap(),
      );
    }
  }

  /// Показать детали GAD-7
  void _showGad7Details(Gad7Result result) async {
    // Загружаем AI анализ из Firestore
    try {
      final snapshot = await _firestore
          .collection('gad7_results')
          .where('userId', isEqualTo: _linkedTeenId)
          .orderBy('completedAt', descending: true)
          .limit(1)
          .get();
      
      Map<String, dynamic>? aiAnalysis;
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        aiAnalysis = data['aiAnalysis'] as Map<String, dynamic>?;
      }
      
      _showTestResultModal(
        testType: 'GAD-7',
        totalScore: result.totalScore,
        maxScore: 21,
        severity: result.severity.name,
        aiAnalysis: aiAnalysis,
        result: result.toMap(),
      );
    } catch (e) {
      print('Ошибка загрузки деталей GAD-7: $e');
      _showTestResultModal(
        testType: 'GAD-7',
        totalScore: result.totalScore,
        maxScore: 21,
        severity: result.severity.name,
        aiAnalysis: null,
        result: result.toMap(),
      );
    }
  }

  /// Показать детали опросника
  void _showSurveyDetails(Map<String, dynamic> surveyResult) {
    final insight = surveyResult['insight'] as DailyInsight?;
    if (insight == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Результат опросника "Исповедь дня"',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Уровень риска
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _getRiskColor(insight.overallRisk).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getRiskColor(insight.overallRisk),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            insight.overallRisk.emoji,
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            insight.overallRisk.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _getRiskColor(insight.overallRisk),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Анализ
                    if (insight.aiSummary.isNotEmpty) ...[
                      Text(
                        'Анализ',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        insight.aiSummary,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Рекомендации
                    if (insight.aiAdvice.isNotEmpty) ...[
                      Text(
                        'Рекомендации',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          insight.aiAdvice,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Фразы поддержки
                    if (insight.suggestedPhrases.isNotEmpty) ...[
                      Text(
                        'Фразы поддержки',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...insight.suggestedPhrases.map((phrase) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            phrase,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      )),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Кнопка закрыть
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Понятно'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Универсальный модальный экран для результатов тестов
  void _showTestResultModal({
    required String testType,
    required int totalScore,
    required int maxScore,
    required String severity,
    Map<String, dynamic>? aiAnalysis,
    Map<String, dynamic>? result,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      testType == 'PHQ-9' ? 'Результат теста PHQ-9' : 'Результат теста GAD-7',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Балл
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$totalScore',
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                          Text(
                            ' / $maxScore',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // AI анализ и рекомендации
                    if (aiAnalysis != null) ...[
                      if (aiAnalysis['summary'] != null) ...[
                        Text(
                          'Анализ',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          aiAnalysis['summary'],
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      if (aiAnalysis['recommendations'] != null) ...[
                        Text(
                          'Рекомендации',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            aiAnalysis['recommendations'],
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      if (aiAnalysis['professionalHelp'] != null) ...[
                        Text(
                          'Нужна ли консультация специалиста?',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          aiAnalysis['professionalHelp'],
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      if (aiAnalysis['immediateActions'] != null) ...[
                        Text(
                          'Немедленные действия',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...(aiAnalysis['immediateActions'] as List).map((action) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 20, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  action.toString(),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        )),
                        const SizedBox(height: 24),
                      ],
                      
                      if (aiAnalysis['supportPhrases'] != null) ...[
                        Text(
                          'Фразы поддержки',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...(aiAnalysis['supportPhrases'] as List).map((phrase) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              phrase.toString(),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        )),
                      ],
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Кнопка закрыть
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Понятно'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Пометить результат теста как прочитанный
  Future<void> _markAsRead(String notificationId) async {
    try {
      await _firestore.collection('clinical_test_notifications').doc(notificationId).update({
        'isRead': true,
      });
      // Обновляем список
      final authService = context.read<AuthService>();
      final user = await authService.getCurrentAnamaUser();
      if (user != null) {
        final updatedResults = await _loadClinicalTestResults(user.uid);
        if (mounted) {
          setState(() {
            _clinicalTestResults = updatedResults;
          });
        }
      }
    } catch (e) {
      print('Ошибка пометки как прочитанного: $e');
    }
  }
}

