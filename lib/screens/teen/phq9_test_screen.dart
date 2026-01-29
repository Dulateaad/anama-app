import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../../models/phq9_question.dart';
import '../../services/clinical_test_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/accessible_text.dart';
import '../../l10n/app_localizations.dart';
import 'phq9_result_screen.dart';

/// Экран для прохождения теста PHQ-9
class Phq9TestScreen extends StatefulWidget {
  const Phq9TestScreen({super.key});

  @override
  State<Phq9TestScreen> createState() => _Phq9TestScreenState();
}

class _Phq9TestScreenState extends State<Phq9TestScreen> {
  final ClinicalTestService _testService = ClinicalTestService();
  final AuthService _authService = AuthService();
  
  late List<Phq9Question> _questions;
  final Map<String, Phq9Response?> _answers = {};
  int _currentQuestionIndex = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _questions = _testService.getPhq9Questions();
  }

  void _selectAnswer(Phq9Response response) {
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
    // Проверяем, что все вопросы отвечены
    if (_answers.length != _questions.length) {
      final l10n = AppLocalizations.of(context);
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
        final l10n = AppLocalizations.of(context);
        throw Exception(l10n.get('error'));
      }

      // Преобразуем ответы
      final answers = _answers.map((key, value) => MapEntry(key, value!));

      // Отправляем тест
      final result = await _testService.submitPhq9Test(
        userId: userId,
        answers: answers,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => Phq9ResultScreen(result: result),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
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
    final question = _questions[_currentQuestionIndex];
    final currentAnswer = _answers[question.id];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          label: '${l10n.get('phq9Title')}. ${l10n.get('next')} ${_currentQuestionIndex + 1} ${_questions.length}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.get('phq9Title')),
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
                          fontSize: 20, // Крупный текст для лучшей читаемости
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Варианты ответа
                    ...Phq9Response.values.map((response) {
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
                                      fontSize: 18, // Увеличенный размер для доступности
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500, // Более жирный для контраста
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
                            side: const BorderSide(width: 2), // Увеличенная толщина для видимости
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
                          padding: const EdgeInsets.symmetric(vertical: 18), // Увеличенный padding
                          minimumSize: const Size(0, 56), // Минимальная высота для доступности
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

