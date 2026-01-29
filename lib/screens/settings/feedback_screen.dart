import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../l10n/app_localizations.dart';

/// Экран обратной связи
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  
  String _selectedCategory = 'general';
  bool _isSubmitting = false;
  bool _submitted = false;

  final List<Map<String, String>> _categories = [
    {'id': 'general', 'labelRu': 'Общий вопрос', 'labelKk': 'Жалпы сұрақ'},
    {'id': 'bug', 'labelRu': 'Сообщить об ошибке', 'labelKk': 'Қате туралы хабарлау'},
    {'id': 'feature', 'labelRu': 'Предложить функцию', 'labelKk': 'Функция ұсыну'},
    {'id': 'complaint', 'labelRu': 'Жалоба', 'labelKk': 'Шағым'},
    {'id': 'data', 'labelRu': 'Вопрос о данных', 'labelKk': 'Деректер туралы сұрақ'},
    {'id': 'other', 'labelRu': 'Другое', 'labelKk': 'Басқа'},
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final authService = context.read<AuthService>();
      final user = authService.currentUser;
      final anamaUser = authService.currentAnamaUserCached;

      // Сохраняем в Firestore (Cloud Function отправит email)
      await FirebaseFirestore.instance.collection('feedback').add({
        'userId': user?.uid,
        'userEmail': user?.email ?? anamaUser?.email,
        'userName': anamaUser?.displayName ?? 'Пользователь',
        'category': _selectedCategory,
        'subject': _subjectController.text.trim(),
        'message': _messageController.text.trim(),
        'status': 'new',
        'createdAt': FieldValue.serverTimestamp(),
        'platform': 'web',
      });

      setState(() {
        _submitted = true;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isKazakh = l10n.locale.languageCode == 'kk';

    if (_submitted) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isKazakh ? 'Кері байланыс' : 'Обратная связь'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 60,
                    color: Colors.green[700],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isKazakh ? 'Рахмет!' : 'Спасибо!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isKazakh 
                    ? 'Сіздің хабарламаңыз жіберілді. Біз жақын арада жауап береміз.'
                    : 'Ваше сообщение отправлено. Мы ответим вам в ближайшее время.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(isKazakh ? 'Жабу' : 'Закрыть'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isKazakh ? 'Кері байланыс' : 'Обратная связь'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Информационный блок
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isKazakh 
                          ? 'Сіздің пікіріңіз біз үшін маңызды! Біз барлық хабарламаларды оқимыз.'
                          : 'Ваше мнение важно для нас! Мы читаем все сообщения.',
                        style: TextStyle(color: Colors.blue[800]),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),

              // Категория
              Text(
                isKazakh ? 'Санат' : 'Категория',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat['id'],
                    child: Text(isKazakh ? cat['labelKk']! : cat['labelRu']!),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),

              const SizedBox(height: 20),

              // Тема
              Text(
                isKazakh ? 'Тақырып' : 'Тема',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  hintText: isKazakh 
                    ? 'Хабарламаңыздың тақырыбы'
                    : 'Тема вашего сообщения',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.subject),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return isKazakh 
                      ? 'Тақырыпты енгізіңіз'
                      : 'Введите тему';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Сообщение
              Text(
                isKazakh ? 'Хабарлама' : 'Сообщение',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: isKazakh 
                    ? 'Хабарламаңызды жазыңыз...'
                    : 'Напишите ваше сообщение...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return isKazakh 
                      ? 'Хабарламаны енгізіңіз'
                      : 'Введите сообщение';
                  }
                  if (value.trim().length < 10) {
                    return isKazakh 
                      ? 'Хабарлама тым қысқа'
                      : 'Сообщение слишком короткое';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Кнопка отправки
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isSubmitting 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send),
                  label: Text(
                    _isSubmitting 
                      ? (isKazakh ? 'Жіберілуде...' : 'Отправка...')
                      : (isKazakh ? 'Жіберу' : 'Отправить'),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Контакт
              Center(
                child: Text(
                  isKazakh 
                    ? 'Немесе тікелей жазыңыз: theanama.inc@gmail.com'
                    : 'Или напишите напрямую: theanama.inc@gmail.com',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
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

