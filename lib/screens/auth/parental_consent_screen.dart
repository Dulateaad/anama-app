import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/parental_consent_service.dart';
import '../../services/auth_service.dart';
import '../../models/teen_registration_data.dart';

/// Экран родительского согласия (Verifiable Parental Consent)
/// Требуется для несовершеннолетних пользователей согласно COPPA, GDPR и казахстанскому законодательству
class ParentalConsentScreen extends StatefulWidget {
  final TeenRegistrationData? registrationData; // Данные регистрации подростка
  
  const ParentalConsentScreen({super.key, this.registrationData});
  
  // Геттер для возраста из данных регистрации
  int? get childAge => registrationData?.age;

  @override
  State<ParentalConsentScreen> createState() => _ParentalConsentScreenState();
}

class _ParentalConsentScreenState extends State<ParentalConsentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _parentPhoneController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _isLoading = false;
  bool _isOtpSent = false;
  bool _isOtpVerified = false;
  bool _ageConfirmed = false;
  bool _responsibilityAccepted = false;
  String? _otpError;

  final _consentService = ParentalConsentService();

  @override
  void dispose() {
    _parentPhoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final childAge = widget.registrationData?.age ?? 0;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Согласие родителя'),
        centerTitle: true,
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
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.family_restroom, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Требуется согласие родителя',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Для использования приложения несовершеннолетним пользователем требуется подтвержденное согласие родителя или законного представителя.',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Поле для ввода телефона родителя
                TextFormField(
                  controller: _parentPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Телефон родителя',
                    hintText: '+7 (XXX) XXX-XX-XX',
                    prefixIcon: Icon(Icons.phone),
                    helperText: 'На этот номер будет отправлен код подтверждения',
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите телефон родителя';
                    }
                    if (value.length < 10) {
                      return 'Введите корректный номер телефона';
                    }
                    return null;
                  },
                ),

                // Поле для OTP
                if (_isOtpSent) ...[
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _otpController,
                    decoration: InputDecoration(
                      labelText: 'Код подтверждения',
                      hintText: 'XXXXXX',
                      prefixIcon: const Icon(Icons.lock),
                      errorText: _otpError,
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите код подтверждения';
                      }
                      if (value.length != 6) {
                        return 'Код должен состоять из 6 цифр';
                      }
                      return null;
                    },
                  ),
                ],

                // Показываем возраст ребенка после подтверждения OTP
                if (_isOtpVerified) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.child_care, color: Colors.blue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Возраст ребенка',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ребенок указал свой возраст: $childAge ${_getAgeWord(childAge)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Чекбокс подтверждения возраста
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _ageConfirmed,
                          onChanged: (value) {
                            setState(() {
                              _ageConfirmed = value ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _ageConfirmed = !_ageConfirmed;
                              });
                            },
                            child: Text(
                              'Я подтверждаю, что возраст моего ребенка указан правильно: $childAge ${_getAgeWord(childAge)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Чекбокс принятия ответственности
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _responsibilityAccepted,
                          onChanged: (value) {
                            setState(() {
                              _responsibilityAccepted = value ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _responsibilityAccepted = !_responsibilityAccepted;
                              });
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Я принимаю на себя ответственность',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Я подтверждаю, что являюсь родителем или законным представителем и беру на себя полную ответственность за использование приложения моим ребенком.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Кнопки действий
                SizedBox(
                  width: double.infinity,
                  child: _isOtpSent && !_isOtpVerified
                      ? ElevatedButton(
                          onPressed: _isLoading ? null : _verifyOtp,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Подтвердить код'),
                        )
                      : _isOtpVerified && (!_ageConfirmed || !_responsibilityAccepted)
                          ? ElevatedButton(
                              onPressed: null,
                              child: const Text('Подтвердите возраст и ответственность'),
                            )
                          : ElevatedButton(
                              onPressed: _isLoading ? null : (_isOtpSent ? _submitConsent : _sendOtp),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(_isOtpSent ? 'Подтвердить согласие' : 'Отправить код подтверждения'),
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

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _otpError = null;
    });

    try {
      final phone = _parentPhoneController.text.trim();
      final success = await _consentService.sendOtpToPhone(phone);

      if (success) {
        setState(() {
          _isOtpSent = true;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Код подтверждения отправлен на номер $phone'),
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
          _otpError = 'Ошибка отправки кода';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _otpError = 'Ошибка: $e';
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _otpError = null;
    });

    try {
      final phone = _parentPhoneController.text.trim();
      final success = await _consentService.verifyOtp(
        phone,
        _otpController.text.trim(),
      );

      if (success) {
        setState(() {
          _isOtpVerified = true;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Код подтвержден. Пожалуйста, подтвердите возраст ребенка и примите ответственность.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
          _otpError = 'Неверный код подтверждения';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _otpError = 'Ошибка: $e';
      });
    }
  }

  Future<void> _submitConsent() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isOtpVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, подтвердите код'),
        ),
      );
      return;
    }

    if (!_ageConfirmed || !_responsibilityAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, подтвердите возраст ребенка и примите ответственность'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final registrationData = widget.registrationData;
    if (registrationData == null || registrationData.age == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Данные регистрации потеряны'),
          backgroundColor: Colors.red,
        ),
      );
      context.go('/register');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = context.read<AuthService>();
      
      final parentPhone = _parentPhoneController.text.trim();
      
      // Сначала регистрируем подростка
      await authService.signUpTeen(
        nickname: registrationData.nickname,
        password: registrationData.password,
        age: registrationData.age,
        parentEmail: null, // Email больше не используется
        parentPhone: parentPhone,
        gender: registrationData.gender,
      );

      // Затем создаём запись о родительском согласии
      final consent = await _consentService.createParentalConsent(
        childId: authService.currentUser?.uid ?? '',
        parentEmail: null, // Email больше не используется
        parentPhone: parentPhone,
        consentMethod: 'phone_otp', // Используем телефон для OTP
        childAge: registrationData.age!,
        ageConfirmed: _ageConfirmed,
        responsibilityAccepted: _responsibilityAccepted,
        metadata: {
          'userAgent': 'web_app',
          'timestamp': DateTime.now().toIso8601String(),
          'nickname': registrationData.nickname,
        },
      );

      if (consent != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Регистрация завершена! Добро пожаловать в Anama!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        if (mounted) {
          context.go('/teen');
        }
      } else {
        throw Exception('Не удалось создать согласие');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

