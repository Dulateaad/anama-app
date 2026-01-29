import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../../models/traffic_light_question.dart';
import '../../services/traffic_light_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/accessible_text.dart';
import '../../l10n/app_localizations.dart';
import 'traffic_light_result_screen.dart';

/// Экран для прохождения теста "Светофор" (13-17 лет)
class TrafficLightTestScreen extends StatefulWidget {
  const TrafficLightTestScreen({super.key});

  @override
  State<TrafficLightTestScreen> createState() => _TrafficLightTestScreenState();
}

class _TrafficLightTestScreenState extends State<TrafficLightTestScreen> {
  final TrafficLightService _testService = TrafficLightService();
  final AuthService _authService = AuthService();
  
  List<TrafficLightQuestion> _questions = [];
  final Map<String, TrafficLightResponse?> _answers = {};
  int _currentQuestionIndex = 0;
  bool _isSubmitting = false;
  bool _isLoadingQuestions = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoadingQuestions = true);
    
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        // Fallback на стандартные вопросы
        _questions = TrafficLightQuestions.questions;
        setState(() => _isLoadingQuestions = false);
        return;
      }

      // Загружаем динамические вопросы
      _questions = await _testService.getTrafficLightQuestions(userId);
      setState(() => _isLoadingQuestions = false);
    } catch (e) {
      // В случае ошибки используем стандартные вопросы
      _questions = TrafficLightQuestions.questions;
      setState(() => _isLoadingQuestions = false);
    }
  }

  void _selectAnswer(TrafficLightResponse response) {
    setState(() {
      _answers[_questions[_currentQuestionIndex].id] = response;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _submitTest();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  Future<void> _submitTest() async {
    final l10n = AppLocalizations.of(context);
    
    // Проверяем, что все вопросы отвечены
    if (_answers.length != _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.get('phq9PleaseAnswerAll')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception(l10n.get('error'));
      }

      // Преобразуем ответы
      final answers = _answers.map((key, value) => MapEntry(key, value!));

      // Отправляем тест
      final result = await _testService.submitTrafficLightTest(
        userId: userId,
        answers: answers,
        context: context,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => TrafficLightResultScreen(result: result),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.get('error')}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    // Показываем индикатор загрузки пока генерируются вопросы
    if (_isLoadingQuestions) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.get('trafficLightTitle')),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Генерируем вопросы для тебя...'),
            ],
          ),
        ),
      );
    }
    
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.get('trafficLightTitle')),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Не удалось загрузить вопросы'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadQuestions,
                child: const Text('Попробовать снова'),
              ),
            ],
          ),
        ),
      );
    }
    
    final question = _questions[_currentQuestionIndex];
    final currentAnswer = _answers[question.id];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          label: '${l10n.get('trafficLightTitle')}. ${l10n.get('next')} ${_currentQuestionIndex + 1} ${_questions.length}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.get('trafficLightTitle')),
              Text(
                '${l10n.get('next')} ${_currentQuestionIndex + 1} / ${_questions.length}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Дисклеймер
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.orange[50],
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.get('trafficLightDisclaimer'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[900],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Прогресс-бар
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF3C6CF)),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Вопрос
                    Semantics(
                      label: '${l10n.get('next')} ${_currentQuestionIndex + 1} / ${_questions.length}: ${question.getText(context)}',
                      header: true,
                      child: AccessibleText(
                        question.getText(context),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Варианты ответа
                    ...TrafficLightResponse.values.map((response) {
                      final isSelected = currentAnswer == response;
                      final responseLabel = response.getLabel(context);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Semantics(
                          button: true,
                          label: '$responseLabel. ${isSelected ? l10n.get('done') : l10n.get('cancel')}',
                          selected: isSelected,
                          child: InkWell(
                            onTap: () => _selectAnswer(response),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFF3C6CF)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFE8A5B3)
                                      : Colors.grey[300]!,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? const Color(0xFFE8A5B3)
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFFE8A5B3)
                                            : Colors.grey[400]!,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            size: 16,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: AccessibleText(
                                      responseLabel,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            
            // Кнопки навигации
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentQuestionIndex > 0)
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: l10n.get('back'),
                        child: OutlinedButton(
                          onPressed: _previousQuestion,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(width: 2),
                          ),
                          child: Text(
                            l10n.get('back'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  if (_currentQuestionIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Semantics(
                      button: true,
                      label: _currentQuestionIndex == _questions.length - 1
                          ? l10n.get('done')
                          : l10n.get('next'),
                      enabled: currentAnswer != null && !_isSubmitting,
                      child: ElevatedButton(
                        onPressed: currentAnswer != null && !_isSubmitting
                            ? _nextQuestion
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF3C6CF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          minimumSize: const Size(0, 56),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                _currentQuestionIndex == _questions.length - 1
                                    ? l10n.get('done')
                                    : l10n.get('next'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
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
}

