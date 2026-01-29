import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/accessible_text.dart';

class TeenForgotPasswordScreen extends StatefulWidget {
  const TeenForgotPasswordScreen({super.key});

  @override
  State<TeenForgotPasswordScreen> createState() => _TeenForgotPasswordScreenState();
}

class _TeenForgotPasswordScreenState extends State<TeenForgotPasswordScreen> {
  final _nicknameFormKey = GlobalKey<FormState>();
  final _codeFormKey = GlobalKey<FormState>();
  
  final _nicknameController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _maskedParentEmail;
  
  // Шаги: 1 - ввод никнейма, 2 - ввод кода и нового пароля, 3 - успех
  int _step = 1;

  @override
  void dispose() {
    _nicknameController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!_nicknameFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = context.read<AuthService>();
      final maskedEmail = await authService.requestTeenPasswordReset(
        _nicknameController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _maskedParentEmail = maskedEmail;
          _step = 2;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    if (!_codeFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = context.read<AuthService>();
      await authService.resetTeenPassword(
        nickname: _nicknameController.text.trim(),
        code: _codeController.text.trim(),
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        setState(() {
          _step = 3;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step > 1 && _step < 3) {
              setState(() {
                _step = 1;
                _errorMessage = null;
              });
            } else {
              context.go('/login');
            }
          },
        ),
        title: const Text('Сброс пароля'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _buildCurrentStep(),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 1:
        return _buildNicknameStep();
      case 2:
        return _buildCodeStep();
      case 3:
        return _buildSuccessStep();
      default:
        return _buildNicknameStep();
    }
  }

  Widget _buildNicknameStep() {
    return Form(
      key: _nicknameFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          
          // Иконка
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.family_restroom,
              size: 40,
              color: Theme.of(context).primaryColor,
            ),
          ),
          
          const SizedBox(height: 24),
          
          Semantics(
            header: true,
            child: AccessibleText(
              'Забыл пароль? 🤔',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 12),
          
          AccessibleText(
            'Не переживай! Мы отправим код твоему родителю, и он поможет тебе восстановить доступ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // Ошибка
          if (_errorMessage != null) _buildErrorMessage(),
          
          // Поле никнейма
          Semantics(
            textField: true,
            label: 'Никнейм',
            hint: 'Введи свой никнейм',
            child: TextFormField(
              controller: _nicknameController,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _requestCode(),
              decoration: InputDecoration(
                labelText: 'Твой никнейм',
                hintText: 'Как тебя зовут в приложении?',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введи свой никнейм';
                }
                if (value.length < 3) {
                  return 'Минимум 3 символа';
                }
                return null;
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Кнопка
          Semantics(
            button: true,
            label: 'Отправить код родителю',
            enabled: !_isLoading,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _requestCode,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(0, 52),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Отправить код родителю',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          TextButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Вернуться ко входу'),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeStep() {
    return Form(
      key: _codeFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          
          // Иконка
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mark_email_read_outlined,
              size: 40,
              color: Colors.green[600],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Semantics(
            header: true,
            child: AccessibleText(
              'Код отправлен! 📧',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 12),
          
          AccessibleText(
            'Попроси родителя посмотреть почту $_maskedParentEmail и сказать тебе код',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // Ошибка
          if (_errorMessage != null) _buildErrorMessage(),
          
          // Поле кода
          Semantics(
            textField: true,
            label: 'Код от родителя',
            hint: 'Введи 6-значный код',
            child: TextFormField(
              controller: _codeController,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: InputDecoration(
                labelText: 'Код от родителя',
                hintText: '123456',
                prefixIcon: const Icon(Icons.pin_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введи код';
                }
                if (value.length != 6) {
                  return 'Код должен быть из 6 цифр';
                }
                return null;
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Новый пароль
          Semantics(
            textField: true,
            label: 'Новый пароль',
            hint: 'Придумай новый пароль',
            child: TextFormField(
              controller: _newPasswordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Новый пароль',
                hintText: 'Придумай новый пароль',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введи новый пароль';
                }
                if (value.length < 6) {
                  return 'Минимум 6 символов';
                }
                return null;
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Подтверждение пароля
          Semantics(
            textField: true,
            label: 'Повтори пароль',
            hint: 'Введи пароль ещё раз',
            child: TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _resetPassword(),
              decoration: InputDecoration(
                labelText: 'Повтори пароль',
                hintText: 'Введи пароль ещё раз',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Повтори пароль';
                }
                if (value != _newPasswordController.text) {
                  return 'Пароли не совпадают';
                }
                return null;
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Кнопка
          Semantics(
            button: true,
            label: 'Сменить пароль',
            enabled: !_isLoading,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _resetPassword,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(0, 52),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Сменить пароль',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Повторная отправка
          TextButton(
            onPressed: _isLoading ? null : _requestCode,
            child: const Text('Отправить код ещё раз'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 48),
        
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.green[50],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_outline,
            size: 60,
            color: Colors.green[600],
          ),
        ),
        
        const SizedBox(height: 32),
        
        Semantics(
          header: true,
          child: AccessibleText(
            'Пароль изменён! 🎉',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        const SizedBox(height: 16),
        
        AccessibleText(
          'Теперь ты можешь войти с новым паролем',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 32),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Перейти ко входу',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Semantics(
      liveRegion: true,
      label: 'Ошибка: $_errorMessage',
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!, width: 2),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700]),
            const SizedBox(width: 8),
            Expanded(
              child: AccessibleText(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

