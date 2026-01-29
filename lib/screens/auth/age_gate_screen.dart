import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/teen_registration_data.dart';

/// Экран проверки возраста (Age Gate)
/// Требуется для соответствия COPPA, GDPR и казахстанскому законодательству
class AgeGateScreen extends StatefulWidget {
  final TeenRegistrationData? registrationData; // Данные регистрации
  
  const AgeGateScreen({super.key, this.registrationData});

  @override
  State<AgeGateScreen> createState() => _AgeGateScreenState();
}

class _AgeGateScreenState extends State<AgeGateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  int? _enteredAge;
  bool _isLoading = false;

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Укажите ваш возраст'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Информационный блок
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Для использования приложения необходимо указать ваш возраст. Если вам меньше 18 лет, потребуется согласие родителя.',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Заголовок
                Text(
                  'Сколько вам лет?',
                  style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Укажите ваш возраст в годах',
                  style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 24),

                // Поле ввода возраста
                TextFormField(
                  controller: _ageController,
                  decoration: InputDecoration(
                    labelText: 'Возраст',
                    hintText: 'Например: 15',
                    prefixIcon: const Icon(Icons.cake),
                    suffixText: 'лет',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, укажите ваш возраст';
                    }
                    final age = int.tryParse(value);
                    if (age == null) {
                      return 'Введите корректный возраст';
                    }
                    if (age < 1 || age > 120) {
                      return 'Возраст должен быть от 1 до 120 лет';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    final age = int.tryParse(value);
                    setState(() {
                      _enteredAge = age;
                    });
                  },
                ),

                // Показываем информацию о возрасте
                if (_enteredAge != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isMinor()
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isMinor()
                            ? Colors.orange
                            : Colors.green,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isMinor() ? Icons.warning_amber : Icons.check_circle,
                          color: _isMinor() ? Colors.orange : Colors.green,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ваш возраст: $_enteredAge ${_getAgeWord(_enteredAge!)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isMinor()
                                    ? 'Для использования приложения требуется согласие родителя. Родитель подтвердит ваш возраст и возьмет на себя ответственность.'
                                    : 'Вы можете продолжить регистрацию',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                // Кнопка продолжения
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleContinue,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(_enteredAge != null && !_isMinor()
                            ? 'Продолжить'
                            : 'Далее'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getAgeWord(int age) {
    final lastDigit = age % 10;
    final lastTwoDigits = age % 100;
    
    if (lastTwoDigits >= 11 && lastTwoDigits <= 14) {
      return 'лет';
    }
    
    if (lastDigit == 1) {
      return 'год';
    } else if (lastDigit >= 2 && lastDigit <= 4) {
      return 'года';
    } else {
      return 'лет';
    }
  }

  bool _isMinor() {
    if (_enteredAge == null) return false;
    // В Казахстане совершеннолетие наступает в 18 лет
    return _enteredAge! < 18;
  }

  void _handleContinue() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_enteredAge == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, укажите ваш возраст'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Переходим к следующему шагу
    if (_isMinor()) {
      // Переход к экрану родительского согласия с данными регистрации
      final dataWithAge = widget.registrationData?.copyWithAge(_enteredAge!);
      context.go('/parental-consent', extra: dataWithAge);
    } else {
      // Пользователь совершеннолетний, продолжаем регистрацию
      _continueRegistration();
    }
  }

  Future<void> _continueRegistration() async {
    // Для совершеннолетних пользователей (18+) создаем аккаунт сразу
    if (widget.registrationData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка: данные регистрации потеряны'),
          backgroundColor: Colors.red,
        ),
      );
      context.go('/register');
      return;
    }

    try {
      final authService = context.read<AuthService>();
      await authService.signUpTeen(
        nickname: widget.registrationData!.nickname,
        password: widget.registrationData!.password,
        age: _enteredAge,
        gender: widget.registrationData!.gender,
      );

    if (mounted) {
      context.go('/teen');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка регистрации: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

