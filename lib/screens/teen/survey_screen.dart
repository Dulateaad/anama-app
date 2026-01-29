import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/survey_service.dart';
import '../../models/question.dart';
import '../../models/survey_response.dart';
import '../../models/user_model.dart';
import '../../l10n/app_localizations.dart';
import 'genius_card_screen.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final SurveyService _surveyService = SurveyService();
  final PageController _pageController = PageController();
  final TextEditingController _textController = TextEditingController();
  
  late List<SurveyQuestion> _questions;
  int _currentIndex = 0;
  String? _selectedOption;
  bool _isSubmitting = false;
  String? _userId;
  String? _parentId;
  int? _userAge;
  
  // Отслеживаем уровни риска для каждого ответа
  List<RiskLevel> _riskLevels = [];

  @override
  void initState() {
    super.initState();
    _questions = _surveyService.getTodayQuestions();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authService = context.read<AuthService>();
    final user = await authService.getCurrentAnamaUser();
    if (user != null) {
      setState(() {
        _userId = user.uid;
        _parentId = user.linkedUserId;
        // Вычисляем возраст из даты рождения
        if (user.birthDate != null) {
          final now = DateTime.now();
          _userAge = now.year - user.birthDate!.year;
          if (now.month < user.birthDate!.month ||
              (now.month == user.birthDate!.month && now.day < user.birthDate!.day)) {
            _userAge = _userAge! - 1;
          }
        }
      });
    }
  }
  
  /// Вычисляем общий уровень риска (берем худший)
  RiskLevel _calculateOverallRisk() {
    if (_riskLevels.isEmpty) return RiskLevel.green;
    
    // Если есть хоть один красный — красный
    if (_riskLevels.contains(RiskLevel.red)) return RiskLevel.red;
    // Если есть желтый — желтый
    if (_riskLevels.contains(RiskLevel.yellow)) return RiskLevel.yellow;
    // Иначе зеленый
    return RiskLevel.green;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submitAnswer() async {
    if (_userId == null) return;
    
    final l10n = AppLocalizations.of(context);
    final question = _questions[_currentIndex];
    String answer;
    
    if (question.isOpenEnded) {
      answer = _textController.text.trim();
      if (answer.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.get('writeHere'))),
        );
        return;
      }
    } else {
      if (_selectedOption == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.get('selectOption'))),
        );
        return;
      }
      answer = _selectedOption!;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await _surveyService.submitAnswer(
        userId: _userId!,
        question: question,
        answer: answer,
      );
      
      // Сохраняем уровень риска от AI
      if (response.aiRiskLevel != null) {
        _riskLevels.add(response.aiRiskLevel!);
        print('📊 Added risk level: ${response.aiRiskLevel} | Total: $_riskLevels');
      }

      // Переходим к следующему вопросу или завершаем
      if (_currentIndex < _questions.length - 1) {
        setState(() {
          _currentIndex++;
          _selectedOption = null;
          _textController.clear();
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        // Опрос завершен — показываем карточку гения
        if (mounted) {
          _showGeniusCard();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.get('error')}: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  /// Показываем карточку "Гении в зоне риска"
  void _showGeniusCard() {
    final overallRisk = _calculateOverallRisk();
    print('🎯 FINAL RISK: $overallRisk | All risks: $_riskLevels');
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GeniusCardScreen(
          riskLevel: overallRisk,
          userAge: _userAge,
          parentId: _parentId,
          teenId: _userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('confession')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Прогресс
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _questions.length,
            backgroundColor: Colors.grey[200],
          ),
          
          // Счетчик вопросов
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${l10n.get('questionNumber')} ${_currentIndex + 1} ${l10n.get('of')} ${_questions.length}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          
          // Вопросы
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final question = _questions[index];
                return _buildQuestionPage(question);
              },
            ),
          ),
          
          // Кнопка
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitAnswer,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_currentIndex < _questions.length - 1 ? l10n.get('next') : l10n.get('done')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPage(SurveyQuestion question) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Вопрос
          Text(
            question.getText(context),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Варианты ответа или поле ввода
          if (question.isOpenEnded)
            _buildOpenEndedInput()
          else
            _buildOptions(question.getOptions(context) ?? []),
        ],
      ),
    );
  }

  Widget _buildOptions(List<String> options) {
    return Column(
      children: options.map((option) {
        final isSelected = _selectedOption == option;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => setState(() => _selectedOption = option),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary 
                      : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary 
                            : Colors.grey[400]!,
                        width: 2,
                      ),
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary 
                          : null,
                    ),
                    child: isSelected 
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOpenEndedInput() {
    final l10n = AppLocalizations.of(context);
    return TextField(
      controller: _textController,
      maxLines: 5,
      decoration: InputDecoration(
        hintText: l10n.get('writeHereHint'),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

